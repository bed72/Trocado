<?php

declare(strict_types=1);

use App\Core\Infrastructure\Adapters\UserAdapter;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Auth\Guard;

it('reads the integer identity from the Sanctum guard', function (): void {
    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())->method('id')->willReturn(42);
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    expect((new UserAdapter($manager))->id())->toBe(42);
});

it('fails authentication when the guard has no integer principal', function (int|string|null $id): void {
    $guard = $this->createMock(Guard::class);
    $guard->method('id')->willReturn($id);
    $manager = $this->createMock(AuthManager::class);
    $manager->method('guard')->with('sanctum')->willReturn($guard);

    (new UserAdapter($manager))->id();
})->with([null, '42'])->throws(AuthenticationException::class);
