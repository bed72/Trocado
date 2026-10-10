<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\VerifyEmailNotification;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;

it('creates an unverified pending account and requests one queued verification', function (): void {
    Notification::fake();
    $response = $this->postJson(route('authentication.api.sign-up'), [
        'data' => ['type' => 'sign-ups', 'attributes' => [
            'name' => ' Maria  Silva ', 'email' => ' MARIA@EXAMPLE.COM ',
            'password' => 'Correct1', 'password_confirmation' => 'Correct1',
        ]],
    ])->assertCreated()->assertHeader('Content-Type', 'application/vnd.api+json');
    $user = UserModel::query()->findOrFail($response->json('data.relationships.user.data.id'));
    $response->assertHeader('Location', route('users.get', ['user' => $user->getKey()]))
        ->assertJsonPath('data.type', 'sign-ups')->assertJsonPath('data.id', (string) $user->getKey())
        ->assertJsonPath('data.relationships.user.data.type', 'users');

    expect($user->status)->toBe(UserStatusEnum::Pending)
        ->and($user->name)->toBe('Maria Silva')->and($user->email)->toBe('maria@example.com')
        ->and($user->email_verified_at)->toBeNull()->and($user->tokens()->count())->toBe(0)
        ->and(Hash::check('Correct1', $user->password))->toBeTrue()
        ->and($response->getContent())->not->toContain('Correct1', $user->password, 'password', 'token');
    Notification::assertSentTo($user, VerifyEmailNotification::class, 1);
});

it('rejects a named invalid registration document without persistence or verification', function (array $override, string $pointer): void {
    Notification::fake();
    $payload = array_replace_recursive(['data' => ['type' => 'sign-ups', 'attributes' => [
        'name' => 'Maria', 'email' => 'maria@example.com', 'password' => 'Correct1', 'password_confirmation' => 'Correct1',
    ]]], $override);

    $response = $this->postJson(route('authentication.api.sign-up'), $payload)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect(array_column(array_column($response->json('errors'), 'source'), 'pointer'))->toContain($pointer)
        ->and(UserModel::query()->count())->toBe(0)
        ->and(DB::table('personal_access_tokens')->count())->toBe(0);
    Notification::assertNothingSent();
})->with([
    'confirmation mismatch' => [['data' => ['attributes' => ['password_confirmation' => 'Other123']]], '/data/attributes/password_confirmation'],
    'five characters' => [['data' => ['attributes' => ['password' => 'Abc12', 'password_confirmation' => 'Abc12']]], '/data/attributes/password'],
    '33 characters' => [['data' => ['attributes' => ['password' => 'A1'.str_repeat('a', 31), 'password_confirmation' => 'A1'.str_repeat('a', 31)]]], '/data/attributes/password'],
    'more than 72 bytes within character limit' => [['data' => ['attributes' => ['password' => 'A1'.str_repeat('界', 24), 'password_confirmation' => 'A1'.str_repeat('界', 24)]]], '/data/attributes/password'],
    'no uppercase' => [['data' => ['attributes' => ['password' => 'correct1', 'password_confirmation' => 'correct1']]], '/data/attributes/password'],
    'no number' => [['data' => ['attributes' => ['password' => 'CorrectA', 'password_confirmation' => 'CorrectA']]], '/data/attributes/password'],
    'short name' => [['data' => ['attributes' => ['name' => 'M']]], '/data/attributes/name'],
    'long name' => [['data' => ['attributes' => ['name' => str_repeat('a', 33)]]], '/data/attributes/name'],
    'invalid name characters' => [['data' => ['attributes' => ['name' => 'Maria1']]], '/data/attributes/name'],
    'invalid email' => [['data' => ['attributes' => ['email' => 'invalid']]], '/data/attributes/email'],
    'unexpected attribute' => [['data' => ['attributes' => ['status' => 'active']]], '/data/attributes'],
    'wrong resource type' => [['data' => ['type' => 'users']], '/data/type'],
]);

it('accepts inclusive password and name limits without issuing an implicit token', function (string $name, string $password): void {
    Notification::fake();
    $response = $this->postJson(route('authentication.api.sign-up'), [
        'data' => ['type' => 'sign-ups', 'attributes' => [
            'name' => $name, 'email' => 'maria@example.com', 'password' => $password, 'password_confirmation' => $password,
        ]],
    ])->assertCreated();
    $user = UserModel::query()->findOrFail($response->json('data.id'));

    expect(Hash::check($password, $user->password))->toBeTrue()->and($user->tokens()->count())->toBe(0);
})->with([
    'minimum limits' => ['Ma', 'Abc123'],
    'maximum character limits' => [str_repeat('a', 32), 'A1'.str_repeat('a', 30)],
    'maximum bcrypt byte limit' => ['Maria', 'A1a'.str_repeat('界', 23)],
]);

it('preserves password spaces through registration hashing and real login', function (): void {
    Notification::fake();
    $password = ' Correct1 ';
    $response = $this->postJson(route('authentication.api.sign-up'), [
        'data' => ['type' => 'sign-ups', 'attributes' => [
            'name' => 'Maria', 'email' => 'maria@example.com', 'password' => $password, 'password_confirmation' => $password,
        ]],
    ])->assertCreated();
    $user = UserModel::query()->findOrFail($response->json('data.id'));
    expect(Hash::check($password, $user->password))->toBeTrue()
        ->and(Hash::check(trim($password), $user->password))->toBeFalse();
    $user->forceFill(['status' => UserStatusEnum::Active, 'email_verified_at' => now()])->save();

    foreach ([trim($password) => 401, $password => 200] as $submitted => $status) {
        $this->postJson(route('authentication.api.sign-in'), [
            'data' => ['type' => 'access-tokens', 'attributes' => ['email' => $user->email, 'password' => $submitted]],
        ])->assertStatus($status);
    }

    expect($user->tokens()->count())->toBe(1);
});
