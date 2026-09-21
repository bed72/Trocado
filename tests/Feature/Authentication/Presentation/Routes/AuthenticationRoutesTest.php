<?php

declare(strict_types=1);

use Illuminate\Routing\Route;

it('registers the authentication API contract and protects only sign out', function (): void {
    $signUp = app('router')->getRoutes()->getByName('authentication.api.sign-up');
    $signIn = app('router')->getRoutes()->getByName('authentication.api.sign-in');
    $signOut = app('router')->getRoutes()->getByName('authentication.api.sign-out');

    expect($signUp)->toBeInstanceOf(Route::class)
        ->and($signUp->methods())->toContain('POST')
        ->and($signUp->uri())->toBe('api/authentication/sign-up')
        ->and($signUp->gatherMiddleware())->not->toContain('auth:sanctum')
        ->and($signIn)->toBeInstanceOf(Route::class)
        ->and($signIn->methods())->toContain('POST')
        ->and($signIn->uri())->toBe('api/authentication/sign-in')
        ->and($signIn->gatherMiddleware())->not->toContain('auth:sanctum')
        ->and($signOut)->toBeInstanceOf(Route::class)
        ->and($signOut->methods())->toContain('DELETE')
        ->and($signOut->uri())->toBe('api/authentication/sign-out')
        ->and($signOut->gatherMiddleware())->toContain('auth:sanctum');
});

it('does not add generic authentication to current User or Budget routes', function (string $routeName): void {
    $route = app('router')->getRoutes()->getByName($routeName);

    expect($route)->toBeInstanceOf(Route::class)
        ->and($route->gatherMiddleware())->not->toContain('auth:sanctum');
})->with([
    'User creation' => ['users.create'],
    'User query' => ['users.get'],
    'Budget creation' => ['budgets.create'],
    'Budget query' => ['budgets.get'],
]);

it('does not expose the Sanctum SPA cookie endpoint', function (): void {
    expect(app('router')->getRoutes()->getByName('sanctum.csrf-cookie'))->toBeNull();
});
