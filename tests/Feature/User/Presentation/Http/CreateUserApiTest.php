<?php

declare(strict_types=1);

use App\User\Infrastructure\Persistence\Models\UserModel;
use Laravel\Sanctum\Sanctum;

beforeEach(function (): void {
    Sanctum::actingAs(new UserModel);
});

it('creates and returns a canonical JSON API user resource', function (): void {
    $response = $this->postJson(route('users.create'), validCreateUserApiPayload(), [
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/vnd.api+json',
    ]);

    $response->assertCreated()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonMissingPath('errors')
        ->assertJsonPath('data.type', 'users')
        ->assertJsonPath('data.attributes.name', 'Maria Silva')
        ->assertJsonPath('data.attributes.email', 'maria.silva@example.com');

    $id = $response->json('data.id');
    expect($id)->toBeString()
        ->and($response->json('data.attributes.created_at'))->toBeString()
        ->and($response->json('data.attributes.updated_at'))->toBeString();
    $response->assertHeader('Location', route('users.get', ['user' => $id]))
        ->assertJsonPath('data.links.self', route('users.get', ['user' => $id]));
    $this->assertDatabaseHas('users', [
        'id' => $id,
        'name' => 'Maria Silva',
        'email' => 'maria.silva@example.com',
    ]);
});

it('returns JSON API validation pointers without persisting invalid input', function (array $payload, string $pointer): void {
    $this->postJson('/api/users', $payload)
        ->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseCount('users', 0);
})->with(invalidCreateUserApiPayloads());

it('returns a JSON API conflict for an email already in use', function (): void {
    UserModel::query()->create(['name' => 'Maria', 'email' => 'maria@example.com']);

    $this->postJson('/api/users', [
        'data' => [
            'type' => 'users',
            'attributes' => ['name' => 'Outra Maria', 'email' => ' MARIA@EXAMPLE.COM '],
        ],
    ])->assertConflict()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '409',
            'title' => 'E-mail já utilizado',
            'detail' => 'Não foi possível utilizar o e-mail informado.',
        ]]]);

    $this->assertDatabaseCount('users', 1);
});

function validCreateUserApiPayload(): array
{
    return [
        'data' => [
            'type' => 'users',
            'attributes' => [
                'name' => '  Maria Silva  ',
                'email' => '  Maria.Silva@Example.COM  ',
            ],
        ],
    ];
}

function invalidCreateUserApiPayloads(): iterable
{
    yield 'missing document data' => [[], '/data'];

    $payload = validCreateUserApiPayload();
    unset($payload['data']['type']);
    yield 'missing type' => [$payload, '/data/type'];

    $payload = validCreateUserApiPayload();
    unset($payload['data']['attributes']);
    yield 'missing attributes' => [$payload, '/data/attributes'];

    $payload = validCreateUserApiPayload();
    unset($payload['data']['attributes']['name']);
    yield 'missing name' => [$payload, '/data/attributes/name'];

    $payload = validCreateUserApiPayload();
    unset($payload['data']['attributes']['email']);
    yield 'missing email' => [$payload, '/data/attributes/email'];

    yield 'wrong type' => [
        array_replace_recursive(validCreateUserApiPayload(), ['data' => ['type' => 'budgets']]),
        '/data/type',
    ];
    yield 'invalid email' => [
        array_replace_recursive(validCreateUserApiPayload(), ['data' => ['attributes' => ['email' => 'invalid']]]),
        '/data/attributes/email',
    ];
    yield 'too long name' => [
        array_replace_recursive(validCreateUserApiPayload(), ['data' => ['attributes' => ['name' => str_repeat('a', 256)]]]),
        '/data/attributes/name',
    ];
    yield 'unexpected attribute' => [
        array_replace_recursive(validCreateUserApiPayload(), ['data' => ['attributes' => ['password' => 'secret']]]),
        '/data/attributes',
    ];
    yield 'unexpected document member' => [
        array_replace_recursive(validCreateUserApiPayload(), ['data' => ['meta' => []]]),
        '/data',
    ];
}
