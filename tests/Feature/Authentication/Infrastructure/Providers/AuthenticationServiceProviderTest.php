<?php

declare(strict_types=1);

use App\Authentication\Application\Ports\AuthenticationWritePort;
use App\Authentication\Application\Ports\SignInPort;
use App\Authentication\Application\Ports\SignOutPort;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Infrastructure\Adapters\AuthenticationWriteAdapter;
use App\Authentication\Infrastructure\Adapters\SignInAdapter;
use App\Authentication\Infrastructure\Adapters\SignOutAdapter;
use App\Authentication\Infrastructure\Adapters\SignUpAdapter;
use App\Authentication\Infrastructure\Providers\AuthenticationServiceProvider;
use Illuminate\Database\Eloquent\Model;

it('binds authentication boundaries to their Laravel adapters', function (): void {
    expect(app(AuthenticationWritePort::class))->toBeInstanceOf(AuthenticationWriteAdapter::class)
        ->and(app(SignUpPort::class))->toBeInstanceOf(SignUpAdapter::class)
        ->and(app(SignInPort::class))->toBeInstanceOf(SignInAdapter::class)
        ->and(app(SignOutPort::class))->toBeInstanceOf(SignOutAdapter::class)
        ->and(config('sanctum.guard'))->toBe([])
        ->and(config('sanctum.expiration'))->toBe(120)
        ->and(config('sanctum.routes'))->toBeFalse();
});

it('prevents lazy loading outside production independently of other contexts', function (): void {
    Model::preventLazyLoading(false);

    (new AuthenticationServiceProvider(app: app()))->boot();

    expect(Model::preventsLazyLoading())->toBeTrue();
});
