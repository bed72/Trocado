<?php

declare(strict_types=1);

use App\Identity\Application\Ports\SignInPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Auth\UserProvider;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;

it('requires both active status and a verified email before issuing a token', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: null);
    $payload = ['data' => ['type' => 'access-tokens', 'attributes' => ['email' => $user->email, 'password' => 'Correct1']]];

    $this->postJson(route('authentication.api.sign-in'), $payload)
        ->assertForbidden()->assertJsonPath('errors.0.title', 'E-mail não confirmado');
    expect($user->tokens()->count())->toBe(0);

    $user->markEmailAsVerified();
    $this->postJson(route('authentication.api.sign-in'), $payload)->assertOk();
});

it('rejects an existing token on protected routes after verification is cleared but allows selective sign-out', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $journey = new IdentityHttpJourney($this);
    $token = $journey->signIn();
    $otherToken = $journey->signIn();
    $userId = (int) $user->getKey();
    UserModel::query()->whereKey($userId)->update(['email_verified_at' => null]);

    foreach (['users.get' => ['user' => $userId], 'expenses.index' => []] as $route => $parameters) {
        Auth::forgetGuards();
        $this->withToken($token)->getJson(route($route, $parameters))
            ->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json');
    }

    Auth::forgetGuards();
    $this->withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    expect(PersonalAccessToken::findToken($token))->toBeNull()
        ->and(PersonalAccessToken::findToken($otherToken))->not->toBeNull()
        ->and($user->tokens()->count())->toBe(1);
});

it('issues distinct real tokens for canonical equivalent logins with safe JSON API responses', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-10 12:00:00 UTC'));
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $tokens = [];

    foreach ([' MARIA@EXAMPLE.COM ', 'maria@example.com'] as $email) {
        Auth::forgetGuards();
        $response = $this->postJson(route('authentication.api.sign-in'), [
            'data' => ['type' => 'access-tokens', 'attributes' => ['email' => $email, 'password' => 'Correct1']],
        ])->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->assertHeader('Pragma', 'no-cache')
            ->assertJsonPath('data.type', 'access-tokens')
            ->assertJsonPath('data.attributes.token_type', 'Bearer')
            ->assertJsonPath('data.relationships.user.data.type', 'users')
            ->assertJsonPath('data.relationships.user.data.id', (string) $user->getKey());
        $token = $response->json('data.attributes.token');
        $record = PersonalAccessToken::findToken($token);

        expect($response->headers->get('Cache-Control'))->toContain('no-store')
            ->and($response->json('data.id'))->toBe((string) $record->getKey())
            ->and($response->json('data.attributes'))->not->toHaveKeys(['password', 'password_confirmation', 'hash'])
            ->and($response->getContent())->not->toContain($user->password, $record->token, 'Correct1')
            ->and($record->token)->toBe(hash('sha256', explode('|', $token, 2)[1]))
            ->and($record->tokenable_id)->toBe($user->getKey())
            ->and($record->tokenable_type)->toBe($user->getMorphClass())
            ->and($record->expires_at->equalTo(now()->addDays(30)))->toBeTrue()
            ->and($response->json('data.attributes.expires_at'))->toBe($record->expires_at->format(DATE_ATOM));
        $tokens[] = $token;
    }

    expect($tokens[0])->not->toBe($tokens[1])
        ->and($user->tokens()->count())->toBe(2)
        ->and(UserModel::query()->count())->toBe(1);

    foreach ($tokens as $token) {
        Auth::forgetGuards();
        $this->withToken($token)->getJson(route('users.get', ['user' => $user->getKey()]))->assertOk();
    }
});

it('returns the same safe credential error without issuing tokens', function (string $failure): void {
    $user = IdentityFixture::create(
        status: UserStatusEnum::Active,
        verifiedAt: now(),
        password: $failure === 'unknown adaptive password' ? 'Unrecoverable1' : 'Correct1',
    );

    if ($failure === 'unusable hash') {
        DB::table('users')->where('id', $user->getKey())->update(['password' => 'not-an-authenticatable-hash']);
        expect(DB::table('users')->where('id', $user->getKey())->value('password'))->toBe('not-an-authenticatable-hash');
    }

    $email = match ($failure) {
        'invalid email' => 'invalid-email',
        'missing identity' => 'unknown@example.com',
        default => 'maria@example.com',
    };

    $response = $this->postJson(route('authentication.api.sign-in'), [
        'data' => ['type' => 'access-tokens', 'attributes' => [
            'email' => $email,
            'password' => $failure === 'wrong password' ? 'Incorrect1' : 'Correct1',
        ]],
    ]);

    expect($user->tokens()->count())->toBe(0)
        ->and(DB::table('personal_access_tokens')->count())->toBe(0);
    $response->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'title' => 'Credenciais inválidas',
            'detail' => 'As credenciais informadas são inválidas.',
            'status' => '401',
        ]]]);
})->with(['invalid email', 'missing identity', 'wrong password', 'unknown adaptive password', 'unusable hash']);

it('does not issue tokens to correctly authenticated inactive accounts', function (UserStatusEnum $status): void {
    $user = IdentityFixture::create(status: $status, verifiedAt: now());

    $this->postJson(route('authentication.api.sign-in'), [
        'data' => ['type' => 'access-tokens', 'attributes' => ['email' => $user->email, 'password' => 'Correct1']],
    ])->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect($user->tokens()->count())->toBe(0);
})->with([UserStatusEnum::Pending, UserStatusEnum::Blocked]);

it('preserves operational authentication failures as safe server errors without tokens', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $provider = $this->createMock(UserProvider::class);
    $provider->expects($this->once())->method('retrieveByCredentials')
        ->with(['email' => 'maria@example.com', 'password' => 'Correct1'])
        ->willThrowException(new RuntimeException('sensitive database failure'));
    $provider->expects($this->never())->method('validateCredentials');
    $auth = $this->createMock(AuthManager::class);
    $auth->expects($this->once())->method('createUserProvider')->with(config('auth.guards.web.provider'))->willReturn($provider);
    $this->app->instance(SignInPort::class, new SignInAdapter($auth, config()));

    $this->postJson(route('authentication.api.sign-in'), [
        'data' => ['type' => 'access-tokens', 'attributes' => ['email' => $user->email, 'password' => 'Correct1']],
    ])->assertInternalServerError()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertDontSee('sensitive database failure')->assertDontSee('Correct1');

    expect($user->tokens()->count())->toBe(0);
});
