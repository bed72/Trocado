<?php

declare(strict_types=1);

use App\Core\Infrastructure\Adapters\UserAdapter;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Auth\GenericUser;
use Illuminate\Contracts\Auth\Guard;

enum PrincipalStatusTestEnum: string
{
    case Active = 'active';
}

enum IntegerStatusTestEnum: int
{
    case Active = 1;
}

it('reads the integer identity from the Sanctum guard', function (): void {
    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())->method('id')->willReturn(42);
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    expect((new UserAdapter($manager))->id())->toBe(42);
});

it('fails authentication when the guard has no integer principal', function (int|string|null $id): void {
    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())->method('id')->willReturn($id);
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    (new UserAdapter($manager))->id();
})->with([null, '42'])->throws(AuthenticationException::class);

it('reads textual status exclusively from the Sanctum principal', function (string|PrincipalStatusTestEnum $status): void {
    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())->method('user')->willReturn(new GenericUser(['status' => $status]));
    $guard->expects($this->never())->method('id');
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    expect((new UserAdapter($manager))->status())->toBe('active');
})->with([
    'string' => 'active',
    'string backed enum' => PrincipalStatusTestEnum::Active,
]);

it('rejects an absent or nontextual Sanctum status', function (?array $attributes): void {
    $guard = $this->createMock(Guard::class);
    $guard->expects($this->once())->method('user')->willReturn($attributes === null ? null : new GenericUser($attributes));
    $manager = $this->createMock(AuthManager::class);
    $manager->expects($this->once())->method('guard')->with('sanctum')->willReturn($guard);

    (new UserAdapter($manager))->status();
})->with([
    'principal absent' => [null],
    'status null' => [['status' => null]],
    'integer' => [['status' => 1]],
    'boolean' => [['status' => true]],
    'array' => [['status' => ['active']]],
    'integer backed enum' => [['status' => IntegerStatusTestEnum::Active]],
])->throws(AuthenticationException::class);
