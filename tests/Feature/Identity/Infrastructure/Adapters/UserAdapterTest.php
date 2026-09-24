<?php

declare(strict_types=1);

use App\Identity\Application\Ports\UserPort;
use App\Identity\Infrastructure\Adapters\UserAdapter;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Guard;

it('reads the authenticated user identifier from the sanctum guard', function (): void {
    $id = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->getJson("/api/users/{$id}")->assertOk();

    expect(app(UserPort::class)->id())->toBe($id);
});

it('does not fall back to the default guard when sanctum has no principal', function (): void {
    $guard = $this->createStub(Guard::class);
    $guard->method('user')->willReturn(null);
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    (new UserAdapter($manager))->id();
})->throws(AuthenticationException::class);

it('rejects a non UserModel principal from sanctum', function (): void {
    $guard = $this->createStub(Guard::class);
    $guard->method('user')->willReturn($this->createStub(Authenticatable::class));
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    (new UserAdapter($manager))->id();
})->throws(AuthenticationException::class);
