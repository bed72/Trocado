<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('coordinates the locked credential rehash and PAT creation in one transaction', function (bool $insertFailure): void {
    $this->travelTo(CarbonImmutable::parse('2026-01-17 12:00:00 UTC'));
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $before = $user->fresh()->getRawOriginal();
    $rounds = password_get_info($before['password'])['options']['cost'];
    Hash::driver()->setRounds($rounds + 1);
    $connection = DB::connection();
    $wasLogging = $connection->logging();
    $connection->enableQueryLog();
    $connection->flushQueryLog();
    $constraintAdded = false;
    try {
        if ($insertFailure) {
            DB::statement('ALTER TABLE personal_access_tokens ADD CONSTRAINT sign_in_test_reject CHECK (false) NOT VALID');
            $constraintAdded = true;
        }
        if ($insertFailure) {
            try {
                app(SignInAdapter::class)->issue('maria@example.com', 'Correct1');
                $this->fail('The PAT insertion must fail after the rehash.');
            } catch (RuntimeException $exception) {
                expect($exception->getMessage())->toBe('Não foi possível concluir a autenticação.')
                    ->and($exception->getPrevious())->toBeNull()
                    ->and((string) $exception)->not->toContain('Correct1', $before['password'], 'sign_in_test_reject');
            }
            expect($user->fresh()->getRawOriginal())->toBe($before)
                ->and($user->tokens()->count())->toBe(0);
        } else {
            $output = app(SignInAdapter::class)->issue(' MARIA@EXAMPLE.COM ', 'Correct1');
            $hash = $user->fresh()->password;
            $record = PersonalAccessTokenModel::findToken($output->token);
            expect(Hash::check('Correct1', $hash))->toBeTrue()
                ->and($hash)->not->toBe($before['password'])
                ->and(password_get_info($hash)['options']['cost'])->toBe($rounds + 1)
                ->and($record->getKey())->toBe($output->id)
                ->and($output->userId)->toBe($user->getKey())
                ->and($record->expires_at->equalTo(now()->addDays(30)))->toBeTrue()
                ->and($record->abilities)->toBe([])->and($user->tokens()->count())->toBe(1);
        }

        $queries = array_column($connection->getQueryLog(), 'query');
        $locks = array_values(array_filter($queries, fn (string $query): bool => str_contains($query, 'for update')));
        $rehashes = array_values(array_filter($queries, fn (string $query): bool => str_starts_with($query, 'update "users"')));
        expect($locks)->toHaveCount(1)->and($locks[0])->toContain('"users"')
            ->and($rehashes)->toHaveCount(1)->and($rehashes[0])->toContain('"password"')
            ->and($connection->transactionLevel())->toBe(0);
    } finally {
        try {
            if ($constraintAdded) {
                DB::statement('ALTER TABLE personal_access_tokens DROP CONSTRAINT sign_in_test_reject');
            }
        } finally {
            Hash::driver()->setRounds($rounds);
            $connection->flushQueryLog();
            if (! $wasLogging) {
                $connection->disableQueryLog();
            }
        }
    }
})->with(['successful admission' => false, 'PAT failure rolls back its preceding rehash' => true]);
