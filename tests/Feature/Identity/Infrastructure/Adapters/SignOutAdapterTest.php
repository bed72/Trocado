<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Adapters\SignOutAdapter;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Auth\Guard;
use Laravel\Sanctum\PersonalAccessToken;

it('revokes only the access token attached to the authenticated user', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Abc123',
    ]);
    $currentToken = $user->createToken(name: 'current')->accessToken;
    $otherToken = $user->createToken(name: 'other')->accessToken;
    $user->withAccessToken(accessToken: $currentToken);

    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())
        ->method('user')
        ->willReturn($user);
    $auth = $this->createMock(AuthManager::class);
    $auth->expects($this->once())
        ->method('guard')
        ->with('sanctum')
        ->willReturn($guard);

    (new SignOutAdapter(manager: $auth))->revokeToken();

    expect(PersonalAccessToken::query()->find($currentToken->getKey()))->toBeNull()
        ->and(PersonalAccessToken::query()->find($otherToken->getKey()))->not->toBeNull();
});

it('rejects revocation when the authenticated user has no persisted current token', function (): void {
    $user = UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => 'Abc123',
    ]);
    $guard = $this->createStub(Guard::class);
    $guard->method('user')->willReturn($user);
    $auth = $this->createStub(AuthManager::class);
    $auth->method('guard')->willReturn($guard);

    expect(fn () => (new SignOutAdapter(manager: $auth))->revokeToken())
        ->toThrow(AuthenticationException::class);
});
