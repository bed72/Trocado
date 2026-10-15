<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('uses the configured UUIDv7 model and preserves official secret hash and owner morph', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $issued = $user->createToken('uuid-proof', ['read'], now()->addDays(30));
    $record = $issued->accessToken;
    [$id, $secret] = explode('|', $issued->plainTextToken, 2);

    expect(Sanctum::$personalAccessTokenModel)->toBe(PersonalAccessTokenModel::class)
        ->and($record)->toBeInstanceOf(PersonalAccessTokenModel::class)
        ->and($id)->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/')
        ->and($user->id)->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/')
        ->and($record->getKey())->toBe($id)->and($record->getIncrementing())->toBeFalse()
        ->and($record->getKeyType())->toBe('string')->and($record->tokenable_id)->toBe($user->id)
        ->and($record->tokenable_type)->toBe($user->getMorphClass())
        ->and($record->token)->toBe(hash('sha256', $secret))->and($record->abilities)->toBe(['read'])
        ->and($record->toArray())->not->toHaveKey('token')
        ->and(PersonalAccessTokenModel::findToken(strtoupper($id).'|'.$secret)?->getKey())->toBe($id)
        ->and(PersonalAccessTokenModel::findToken($secret)?->getKey())->toBe($id)
        ->and(PersonalAccessTokenModel::findToken($id.'|wrong'))->toBeNull()
        ->and(PersonalAccessTokenModel::findToken($id))->toBeNull();
    $this->withToken($secret)->getJson(route('users.get', ['user' => $user->id]))->assertOk()->assertDontSee($secret);
});

it('rejects an invalid bearer ID before any token lookup SQL and returns JSON API 401', function (string $id): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(30));
    $secret = explode('|', $token, 2)[1];
    Auth::forgetGuards();
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        expect(PersonalAccessTokenModel::findToken($id.'|'.$secret))->toBeNull()
            ->and(DB::getQueryLog())->toBe([]);
        $this->withToken($id.'|'.$secret)->getJson(route('users.get', ['user' => $user->id]))
            ->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertDontSee($secret)->assertDontSee('SQLSTATE');
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
    expect(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'personal_access_tokens')))->toBe([]);
})->with([
    'integer legacy' => '42', 'malformed' => 'invalid', 'empty' => '', 'hash' => str_repeat('a', 64),
    'v1' => '017f22e2-79b0-1cc3-98c4-000000000001', 'v4' => '017f22e2-79b0-4cc3-98c4-000000000001',
    'v6' => '017f22e2-79b0-6cc3-98c4-000000000001', 'v8' => '017f22e2-79b0-8cc3-98c4-000000000001',
    'variant' => '017f22e2-79b0-7cc3-c8c4-000000000001', 'nil' => '00000000-0000-0000-0000-000000000000',
    'whitespace' => ' 017f22e2-79b0-7cc3-98c4-000000000001 ',
]);
