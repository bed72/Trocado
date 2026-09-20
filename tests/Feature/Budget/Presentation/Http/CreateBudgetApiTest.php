<?php

declare(strict_types=1);

it('creates and returns a complete JSON API budget resource', function (): void {
    $response = $this->postJson(route('budgets.create'), validCreateBudgetApiPayload(), [
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/vnd.api+json',
    ]);

    $response->assertCreated()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonMissingPath('errors')
        ->assertJsonPath('data.type', 'budgets')
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');

    $id = $response->json('data.id');
    expect($id)->toBeString()
        ->and($response->json('data.attributes.created_at'))->toBeString()
        ->and($response->json('data.attributes.updated_at'))->toBeString();
    $response->assertHeader('Location', route('budgets.get', ['budget' => $id]))
        ->assertJsonPath('data.links.self', route('budgets.get', ['budget' => $id]));
    $this->assertDatabaseHas('budgets', [
        'id' => $id,
        'amount' => 12500,
        'start_date' => '2026-09-01 00:00:00',
        'end_date' => '2026-09-30 00:00:00',
    ]);
});

it('accepts a zero amount', function (): void {
    $payload = validCreateBudgetApiPayload();
    $payload['data']['attributes']['amount'] = 0;

    $this->postJson('/api/budgets', $payload)
        ->assertCreated()
        ->assertJsonPath('data.attributes.amount', 0);

    $this->assertDatabaseHas('budgets', ['amount' => 0]);
});

it('returns JSON API validation pointers without persisting invalid input', function (array $payload, string $pointer): void {
    $this->postJson('/api/budgets', $payload)
        ->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonFragment(['source' => ['pointer' => $pointer]]);

    $this->assertDatabaseCount('budgets', 0);
})->with(invalidCreateBudgetApiPayloads());

function validCreateBudgetApiPayload(): array
{
    return [
        'data' => [
            'type' => 'budgets',
            'attributes' => [
                'amount' => 12500,
                'start_date' => '2026-09-01',
                'end_date' => '2026-09-30',
            ],
        ],
    ];
}

function invalidCreateBudgetApiPayloads(): iterable
{
    yield 'missing document data' => [[], '/data/type'];

    $payload = validCreateBudgetApiPayload();
    unset($payload['data']['type']);
    yield 'missing type' => [$payload, '/data/type'];

    $payload = validCreateBudgetApiPayload();
    unset($payload['data']['attributes']);
    yield 'missing attributes' => [$payload, '/data/attributes/start_date'];

    $payload = validCreateBudgetApiPayload();
    unset($payload['data']['attributes']['amount']);
    yield 'missing amount' => [$payload, '/data/attributes/amount'];

    yield 'wrong type' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['type' => 'expenses']]),
        '/data/type',
    ];
    yield 'negative amount' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['amount' => -1]]]),
        '/data/attributes/amount',
    ];
    yield 'numeric string amount' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['amount' => '12500']]]),
        '/data/attributes/amount',
    ];
    yield 'float amount' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['amount' => 12.5]]]),
        '/data/attributes/amount',
    ];
    yield 'invalid start date' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['start_date' => '2026-02-30']]]),
        '/data/attributes/start_date',
    ];
    yield 'invalid end date' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['end_date' => '2026-02-30']]]),
        '/data/attributes/end_date',
    ];
    yield 'reversed range' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['end_date' => '2026-08-31']]]),
        '/data/attributes/end_date',
    ];
    yield 'unexpected attribute' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['attributes' => ['name' => 'extra']]]),
        '/data/attributes',
    ];
    yield 'unexpected document member' => [
        array_replace_recursive(validCreateBudgetApiPayload(), ['data' => ['meta' => []]]),
        '/data',
    ];
}
