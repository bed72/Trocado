<?php

declare(strict_types=1);

use App\User\Application\Repositories\UserRepository;
use App\User\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use App\User\Infrastructure\Providers\UserServiceProvider;
use Illuminate\Database\Eloquent\Model;

it('binds the user repository contract to the Eloquent implementation', function (): void {
    expect(app(UserRepository::class))->toBeInstanceOf(EloquentUserRepository::class);
});

it('prevents lazy loading outside production to expose N plus one queries', function (): void {
    Model::preventLazyLoading(false);

    (new UserServiceProvider(app: app()))->boot();

    expect(Model::preventsLazyLoading())->toBeTrue();
});
