<?php

declare(strict_types=1);

use Illuminate\Routing\Route;

it('keeps sign up and sign in public while protecting sign out', function (): void {
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

it('protects private application routes with Sanctum', function (string $method, string $routeName, array $parameters): void {
    $route = app('router')->getRoutes()->getByName($routeName);

    expect($route)->toBeInstanceOf(Route::class)
        ->and($route->methods())->toContain($method)
        ->and($route->gatherMiddleware())->toContain('auth:sanctum');
})->with(privateApiRoutes());

it('returns the standard JSON API error for unauthenticated private requests', function (string $method, string $routeName, array $parameters): void {
    $this->json($method, route($routeName, $parameters))
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '401',
            'title' => 'Não autenticado',
            'detail' => 'É necessário autenticar-se para acessar este recurso.',
        ]]]);
})->with(privateApiRoutes());

it('does not expose the Sanctum SPA cookie endpoint', function (): void {
    expect(app('router')->getRoutes()->getByName('sanctum.csrf-cookie'))->toBeNull()
        ->and(app('router')->getRoutes()->getByName('users.get-all'))->toBeNull();
});

function privateApiRoutes(): iterable
{
    yield 'create Expense' => ['POST', 'expenses.create', []];
    yield 'get User' => ['GET', 'users.get', ['user' => 1]];
    yield 'update User' => ['PATCH', 'users.update', ['user' => 1]];
    yield 'delete User' => ['DELETE', 'users.delete', ['user' => 1]];
}
