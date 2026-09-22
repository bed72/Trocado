<?php

declare(strict_types=1);

use App\Identity\Application\Ports\CreatePort;
use App\Identity\Application\Ports\IdentityWritePort;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Application\Repositories\IdentityRepository;
use App\Identity\Infrastructure\Adapters\IdentityWriteAdapter;
use App\Identity\Infrastructure\Adapters\RegistrationAdapter;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Adapters\SignOutAdapter;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use App\Identity\Infrastructure\Persistence\Repositories\EloquentIdentityRepository;
use App\Identity\Infrastructure\Providers\IdentityServiceProvider;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\Relation;

it('binds the identity repository and four ports to their Laravel adapters', function (): void {
    expect(app(IdentityRepository::class))->toBeInstanceOf(EloquentIdentityRepository::class)
        ->and(app(IdentityWritePort::class))->toBeInstanceOf(IdentityWriteAdapter::class)
        ->and(app(CreatePort::class))->toBeInstanceOf(RegistrationAdapter::class)
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

it('keeps the persisted Sanctum tokenable type stable across the context consolidation', function (): void {
    $persistedType = 'App'.'\\User\\Infrastructure\\Persistence\\Models\\UserModel';

    expect((new UserModel)->getMorphClass())->toBe($persistedType)
        ->and(Relation::getMorphedModel($persistedType))->toBe(UserModel::class);
});
