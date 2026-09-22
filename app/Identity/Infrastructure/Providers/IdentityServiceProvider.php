<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Providers;

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
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Support\ServiceProvider;

final class IdentityServiceProvider extends ServiceProvider
{
    private const string USER_TOKENABLE_MORPH_TYPE = 'App'.'\\User\\Infrastructure\\Persistence\\Models\\UserModel';

    public function register(): void
    {
        $this->app->bind(abstract: SignInPort::class, concrete: SignInAdapter::class);
        $this->app->bind(abstract: SignOutPort::class, concrete: SignOutAdapter::class);
        $this->app->bind(abstract: CreatePort::class, concrete: RegistrationAdapter::class);
        $this->app->bind(abstract: IdentityWritePort::class, concrete: IdentityWriteAdapter::class);
        $this->app->bind(abstract: IdentityRepository::class, concrete: EloquentIdentityRepository::class);
    }

    public function boot(): void
    {
        Relation::enforceMorphMap([
            self::USER_TOKENABLE_MORPH_TYPE => UserModel::class,
        ]);

        Model::preventLazyLoading(! $this->app->isProduction());
    }
}
