<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('returns the committed winner after a synchronized first-association conflict in a fresh process', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $identities = [new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['key' => 'same'])];
    $input = new ResourceInput($owner->getKey(), $identities);
    $winnerIds = [UuidFixture::at(3000)];
    $child = new ConcurrentDatabaseProcess(static function () use ($input, $winnerIds): void {
        $generated = 0;
        $queries = [];
        Str::createUuidsUsing(function () use (&$generated): string {
            return UuidFixture::at(4000 + ++$generated);
        });
        DB::listen(function (QueryExecuted $event) use (&$queries): void {
            if (str_contains($event->sql, 'resource_identities')) {
                $queries[] = $event->sql;
            }
        });
        try {
            $output = app(ResourceUseCase::class)->execute($input);
            expect(array_column($output->identities, 'id'))->toBe($winnerIds)
                ->and($generated)->toBe(1)->and(count($queries))->toBe(3)
                ->and(DB::table('resource_identities')->count())->toBe(1);
        } finally {
            Str::createUuidsNormally();
        }
    });

    try {
        Str::createUuidsUsingSequence($winnerIds);
        $output = DB::transaction(function () use ($child, $input): array {
            $ids = array_column(app(ResourceUseCase::class)->execute($input)->identities, 'id');
            $child->go();
            $child->awaitLock();

            return $ids;
        });
        $child->done();
        expect($output)->toBe($winnerIds)->and(DB::table('resource_identities')->count())->toBe(1);
        DB::disconnect();
        expect(array_column(app(ResourceUseCase::class)->execute($input)->identities, 'id'))->toBe($winnerIds);
    } finally {
        Str::createUuidsNormally();
        $child->close();
    }
})->group('concurrency', 'integration');

it('serializes owner deletion with first allocation without orphaning or affecting another owner', function (bool $deleteFirst): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    $identities = [new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['key' => 'same'])];
    $input = new ResourceInput($owner->getKey(), $identities);
    $otherId = app(ResourceUseCase::class)->execute(new ResourceInput($other->getKey(), $identities))->identities[0]->id;
    $child = new ConcurrentDatabaseProcess(static function () use ($input, $deleteFirst): void {
        if ($deleteFirst) {
            expect(fn () => app(ResourceUseCase::class)->execute($input))->toThrow(ResourcePersistenceException::class);
        } else {
            expect(DB::table('users')->where('id', $input->userId)->delete())->toBe(1);
        }
    });
    try {
        DB::transaction(function () use ($input, $deleteFirst, $child): void {
            if ($deleteFirst) {
                expect(DB::table('users')->where('id', $input->userId)->delete())->toBe(1);
            } else {
                expect(count(app(ResourceUseCase::class)->execute($input)->identities))->toBe(1);
            }
            $child->go();
            $child->awaitLock();
        });
        $child->done();
        expect(DB::table('users')->where('id', $input->userId)->exists())->toBeFalse()
            ->and(DB::table('resource_identities')->pluck('id')->all())->toBe([$otherId]);
    } finally {
        $child->close();
    }
})->with(['delete first' => true, 'allocate first' => false])->group('concurrency', 'integration');
