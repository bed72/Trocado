<?php

declare(strict_types=1);

use App\Core\Application\Ports\TransactionPort;
use App\Core\Infrastructure\Adapters\DatabaseTransactionAdapter;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Adapters\SignOutAdapter;
use App\Identity\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;
use Illuminate\Database\Eloquent\Model;

it('binds identity dependencies and resolves the shared transaction port', function (): void {
    expect(app(UserRepository::class))->toBeInstanceOf(EloquentUserRepository::class)
        ->and(app(TransactionPort::class))->toBeInstanceOf(DatabaseTransactionAdapter::class)
        ->and(app(SignInPort::class))->toBeInstanceOf(SignInAdapter::class)
        ->and(app(SignOutPort::class))->toBeInstanceOf(SignOutAdapter::class)
        ->and(config('sanctum.guard'))->toBe([])
        ->and(config('sanctum.expiration'))->toBe(120)
        ->and(config('sanctum.routes'))->toBeFalse();
});

it('prevents lazy loading outside production independently of other contexts', function (): void {
    Model::preventLazyLoading(false);

    (new IdentityServiceProvider(app: app()))->boot();

    expect(Model::preventsLazyLoading())->toBeTrue();
});
