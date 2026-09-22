<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Support\Facades\Hash;

it('creates a sign up resource without authenticating implicitly', function (): void {
    $response = $this->postJson(route('authentication.api.sign-up'), authenticationSignUpPayload(), [
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/vnd.api+json',
    ]);

    $response->assertCreated()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.type', 'sign-ups');

    $userId = $response->json('data.id');
    expect($userId)->toBeString();
    $response->assertHeader('Location', route('users.get', ['user' => $userId]))
        ->assertJsonPath('data.relationships.user.data.type', 'users')
        ->assertJsonPath('data.relationships.user.data.id', $userId)
        ->assertJsonMissingPath('data.attributes.password')
        ->assertJsonMissingPath('data.attributes.password_confirmation')
        ->assertJsonMissingPath('data.attributes.token');

    $user = UserModel::query()->findOrFail($userId);
    expect($user->name)->toBe('Maria Silva')
        ->and($user->email)->toBe('maria.silva@example.com')
        ->and(Hash::check(' Abc123 ', $user->getAuthPassword()))->toBeTrue();
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('rejects invalid sign up input with a JSON API pointer', function (array $payload, string $pointer): void {
    $this->postJson(route('authentication.api.sign-up'), $payload)
        ->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseCount('users', 0);
    $this->assertDatabaseCount('personal_access_tokens', 0);
})->with(authenticationInvalidSignUpPayloads());

it('returns the same conflict for a canonical email already in use without changing it', function (): void {
    $existingId = signUpIdentityByApi($this, password: 'Original1');
    $existing = UserModel::query()->findOrFail($existingId);
    $originalHash = $existing->getAuthPassword();

    $this->postJson(route('authentication.api.sign-up'), authenticationSignUpPayload([
        'email' => ' MARIA@EXAMPLE.COM ',
        'password' => 'Outra123',
        'password_confirmation' => 'Outra123',
    ]))->assertConflict()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '409',
            'title' => 'E-mail já utilizado',
            'detail' => 'Não foi possível utilizar o e-mail informado.',
            'source' => ['pointer' => '/data/attributes/email'],
        ]]]);

    expect($existing->fresh()->getAuthPassword())->toBe($originalHash);
    $this->assertDatabaseCount('users', 1);
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

function authenticationSignUpPayload(array $attributes = []): array
{
    return [
        'data' => [
            'type' => 'sign-ups',
            'attributes' => array_replace([
                'name' => '  Maria Silva  ',
                'email' => '  Maria.Silva@Example.COM  ',
                'password' => ' Abc123 ',
                'password_confirmation' => ' Abc123 ',
            ], $attributes),
        ],
    ];
}

function authenticationInvalidSignUpPayloads(): iterable
{
    yield 'name below letter minimum' => [
        authenticationSignUpPayload(['name' => 'A']),
        '/data/attributes/name',
    ];
    yield 'name above letter maximum' => [
        authenticationSignUpPayload(['name' => str_repeat('a', 13)]),
        '/data/attributes/name',
    ];
    yield 'name with invalid characters' => [
        authenticationSignUpPayload(['name' => 'Maria2']),
        '/data/attributes/name',
    ];
    yield 'password below character minimum' => [
        authenticationSignUpPayload(['password' => 'Abc12', 'password_confirmation' => 'Abc12']),
        '/data/attributes/password',
    ];
    yield 'password above character maximum' => [
        authenticationSignUpPayload(['password' => 'Password12345', 'password_confirmation' => 'Password12345']),
        '/data/attributes/password',
    ];
    yield 'password without uppercase letter' => [
        authenticationSignUpPayload(['password' => 'password1', 'password_confirmation' => 'password1']),
        '/data/attributes/password',
    ];
    yield 'password without number' => [
        authenticationSignUpPayload(['password' => 'Password', 'password_confirmation' => 'Password']),
        '/data/attributes/password',
    ];
    yield 'different confirmation' => [
        authenticationSignUpPayload(['password_confirmation' => 'Outra123']),
        '/data/attributes/password_confirmation',
    ];
    yield 'wrong resource type' => [
        array_replace_recursive(authenticationSignUpPayload(), ['data' => ['type' => 'users']]),
        '/data/type',
    ];
    yield 'unknown attribute' => [
        authenticationSignUpPayload(['unknown' => 'value']),
        '/data/attributes',
    ];
}
