<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Core\Fixtures\UuidSchemaFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('returns canonical User UUIDs and preserves identity across uppercase GET and PATCH', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(30));
    $upper = strtoupper($user->id);
    $this->withToken($token)->getJson(route('users.get', ['user' => $upper]))
        ->assertOk()->assertJsonPath('data.id', $user->id)->assertDontSee($token)->assertDontSee($user->password);
    Auth::forgetGuards();
    $this->withToken($token)->patchJson(route('users.update', ['user' => $upper]), [
        'data' => ['type' => 'users', 'id' => $upper, 'attributes' => ['name' => 'Maria Silva']],
    ])->assertOk()->assertJsonPath('data.id', $user->id)->assertJsonPath('data.attributes.name', 'Maria Silva');
    expect($user->refresh()->id)->toBe(strtolower($upper))->and($user->tokens()->count())->toBe(1);
});

it('rejects malformed or non-v7 User route IDs without querying a User', function (string $id): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(30));
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        $this->withToken($token)->getJson('/api/users/'.$id)->assertNotFound()->assertHeader('Content-Type', 'application/vnd.api+json');
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
    expect(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"users"')))->toBe([]);
})->with(['42', 'invalid', str_repeat('a', 64), '017f22e2-79b0-4cc3-98c4-000000000001', '017f22e2-79b0-7cc3-c8c4-000000000001']);

it('rejects malformed body IDs without trimming or editing the resource', function (mixed $id): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $token = IdentityFixture::token($user, now()->addDays(30));
    $id = $id === 'space' ? ' '.$user->id.' ' : $id;
    $this->withToken($token)->patchJson(route('users.update', ['user' => $user->id]), [
        'data' => ['type' => 'users', 'id' => $id, 'attributes' => ['name' => 'Ana Silva']],
    ])->assertUnprocessable()->assertJsonPath('errors.0.source.pointer', '/data/id');
    expect($user->refresh()->name)->toBe('Maria')->and($user->tokens()->count())->toBe(1);
})->with([42, '42', 'space', '017f22e2-79b0-4cc3-98c4-000000000001', UuidFixture::at(999)]);

it('returns identical missing and foreign owner errors for GET PATCH and DELETE', function (string $method): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $token = IdentityFixture::token($owner, now()->addDays(30));
    $responses = [];
    foreach ([$other->id, UuidFixture::at(999)] as $id) {
        Auth::forgetGuards();
        $payload = ['data' => ['type' => 'users', 'id' => $id, 'attributes' => ['name' => 'Ana Silva']]];
        $responses[] = $this->withToken($token)->json($method, route('users.get', ['user' => $id]), $method === 'PATCH' ? $payload : [])
            ->assertNotFound()->json();
    }
    expect($responses[0])->toBe($responses[1])->and($other->refresh()->name)->toBe('Maria')
        ->and(UserModel::query()->count())->toBe(2)->and($owner->tokens()->count())->toBe(1);
})->with(['GET', 'PATCH', 'DELETE']);

it('deletes the account and all its UUID lifecycle rows while preserving another account', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, now());
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $bearer = IdentityFixture::token($owner, now()->addDays(30));
    $ownerSession = $owner->tokens()->sole()->id;
    $otherSession = $other->createToken('other', ['*'], now()->addDays(30))->accessToken->id;
    foreach ([$owner, $other] as $index => $user) {
        foreach (['expenses', 'notifications', 'resource_identities'] as $table) {
            $row = UuidSchemaFixture::row($table);
            $row['user_id'] = $user->id;
            if ($index === 1) {
                $row['id'] = UuidFixture::at($table === 'expenses' ? 30 : ($table === 'notifications' ? 40 : 60));
            }
            if ($table === 'expenses') {
                $row['classification_token'] = 'fencing-'.$index;
            }
            if ($table === 'notifications') {
                $row['session_id'] = $index === 0 ? $ownerSession : $otherSession;
                $row['installation_id'] = UuidFixture::at(50 + $index);
                $row['identifier_fingerprint'] = str_repeat($index === 0 ? 'a' : 'b', 64);
            }
            DB::table($table)->insert($row);
        }
    }
    $this->withToken($bearer)->deleteJson(route('users.delete', ['user' => strtoupper($owner->id)]))->assertNoContent();
    expect(UserModel::query()->pluck('id')->all())->toBe([$other->id]);
    foreach (['expenses', 'notifications', 'resource_identities'] as $table) {
        expect(DB::table($table)->pluck('user_id')->all())->toBe([$other->id]);
    }
    expect(DB::table('personal_access_tokens')->pluck('id')->all())->toBe([$otherSession]);
    Auth::forgetGuards();
    $this->withToken($bearer)->getJson(route('users.get', ['user' => $owner->id]))->assertUnauthorized();
});
