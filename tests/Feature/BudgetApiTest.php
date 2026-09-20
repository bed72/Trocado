<?php

declare(strict_types=1);

it('persists a budget and returns a JSON API resource', function (): void {
    $response = $this->postJson('/api/budgets', budgetApiPayload(amount: 12500));

    $response->assertCreated()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.type', 'budgets')
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');

    $id = $response->json('data.id');
    expect($id)->toBeString();
    expect($response->json('data.attributes.created_at'))->not->toBeNull();
    $response->assertHeader('Location', route('budgets.show', ['budget' => $id]));
    $response->assertJsonPath('data.links.self', route('budgets.show', ['budget' => $id]));
    $this->assertDatabaseHas('budgets', [
        'id' => $id,
        'amount' => 12500,
    ]);

    $this->getJson("/api/budgets/{$id}")
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');
});

it('lists budgets in ID order', function (): void {
    $firstId = createBudgetForApiTest(amount: 12500);
    $secondId = createBudgetForApiTest(amount: 25000);

    $this->getJson('/api/budgets')
        ->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.id', (string) $firstId)
        ->assertJsonPath('data.0.attributes.amount', 12500)
        ->assertJsonPath('data.1.id', (string) $secondId)
        ->assertJsonPath('data.1.attributes.amount', 25000);
});

it('shows the requested budget', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->getJson("/api/budgets/{$id}")
        ->assertOk()
        ->assertJsonPath('data.id', (string) $id)
        ->assertJsonPath('data.type', 'budgets')
        ->assertJsonPath('data.attributes.amount', 12500);
});

it('updates only supplied attributes including a zero amount', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->patchJson("/api/budgets/{$id}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $id,
            'attributes' => ['amount' => 0],
        ],
    ])->assertOk()
        ->assertJsonPath('data.attributes.amount', 0)
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');

    $this->assertDatabaseHas('budgets', [
        'id' => $id,
        'amount' => 0,
    ]);

    $this->getJson("/api/budgets/{$id}")
        ->assertJsonPath('data.attributes.start_date', '2026-09-01')
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');
});

it('changes the date range without changing the amount', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->patchJson("/api/budgets/{$id}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $id,
            'attributes' => [
                'start_date' => '2026-10-01',
                'end_date' => '2026-10-31',
            ],
        ],
    ])->assertOk()
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-10-01')
        ->assertJsonPath('data.attributes.end_date', '2026-10-31');

    $this->getJson("/api/budgets/{$id}")
        ->assertJsonPath('data.attributes.amount', 12500)
        ->assertJsonPath('data.attributes.start_date', '2026-10-01')
        ->assertJsonPath('data.attributes.end_date', '2026-10-31');
});

it('rejects a resulting invalid date range without saving', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->patchJson("/api/budgets/{$id}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $id,
            'attributes' => ['end_date' => '2026-08-31'],
        ],
    ])->assertUnprocessable()
        ->assertJsonPath('errors.0.status', '422')
        ->assertJsonPath('errors.0.title', 'Dados inválidos');

    $this->getJson("/api/budgets/{$id}")
        ->assertJsonPath('data.attributes.end_date', '2026-09-30');
});

it('deletes a budget and returns no content', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->deleteJson("/api/budgets/{$id}")->assertNoContent();

    $this->assertDatabaseMissing('budgets', ['id' => $id]);
});

it('returns JSON API not found errors for missing budgets', function (): void {
    $this->getJson('/api/budgets/99999')
        ->assertNotFound()
        ->assertJsonPath('errors.0.status', '404');

    $this->patchJson('/api/budgets/99999', [
        'data' => [
            'type' => 'budgets',
            'id' => '99999',
            'attributes' => ['amount' => 100],
        ],
    ])->assertNotFound()
        ->assertJsonPath('errors.0.status', '404');

    $this->deleteJson('/api/budgets/99999')
        ->assertNotFound()
        ->assertJsonPath('errors.0.status', '404');
});

it('returns a JSON API not found error for a non numeric budget ID', function (): void {
    $this->getJson('/api/budgets/not-a-number')
        ->assertNotFound()
        ->assertJsonPath('errors.0.status', '404')
        ->assertJsonPath('errors.0.title', 'Recurso não encontrado');
});

it('returns validation errors with JSON pointers when creating', function (array $payload, string $pointer): void {
    $this->postJson('/api/budgets', $payload)
        ->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '422')
        ->assertJsonPath('errors.0.source.pointer', $pointer);

    $this->assertDatabaseCount('budgets', 0);
})->with(budgetApiInvalidCreatePayloads());

it('rejects a mismatched resource ID when updating', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->patchJson("/api/budgets/{$id}", [
        'data' => [
            'type' => 'budgets',
            'id' => '99999',
            'attributes' => ['amount' => 100],
        ],
    ])->assertUnprocessable()
        ->assertJsonPath('errors.0.source.pointer', '/data/id');

    $this->assertDatabaseHas('budgets', ['id' => $id, 'amount' => 12500]);
});

it('requires at least one attribute when updating', function (): void {
    $id = createBudgetForApiTest(amount: 12500);

    $this->patchJson("/api/budgets/{$id}", [
        'data' => [
            'type' => 'budgets',
            'id' => (string) $id,
            'attributes' => [],
        ],
    ])->assertUnprocessable()
        ->assertJsonPath('errors.0.source.pointer', '/data/attributes');
});

function budgetApiPayload(int $amount): array
{
    return [
        'data' => [
            'type' => 'budgets',
            'attributes' => [
                'amount' => $amount,
                'start_date' => '2026-09-01',
                'end_date' => '2026-09-30',
            ],
        ],
    ];
}

function createBudgetForApiTest(int $amount): int
{
    $response = test()->postJson('/api/budgets', budgetApiPayload(amount: $amount))->assertCreated();

    return (int) $response->json('data.id');
}

function budgetApiInvalidCreatePayloads(): iterable
{
    $valid = budgetApiPayload(amount: 12500);

    yield 'wrong type' => [array_replace_recursive($valid, ['data' => ['type' => 'expenses']]), '/data/type'];
    yield 'negative amount' => [array_replace_recursive($valid, ['data' => ['attributes' => ['amount' => -1]]]), '/data/attributes/amount'];
    yield 'numeric string amount' => [array_replace_recursive($valid, ['data' => ['attributes' => ['amount' => '12500']]]), '/data/attributes/amount'];
    yield 'invalid calendar date' => [array_replace_recursive($valid, ['data' => ['attributes' => ['start_date' => '2026-02-30']]]), '/data/attributes/start_date'];
    yield 'reversed range' => [array_replace_recursive($valid, ['data' => ['attributes' => ['end_date' => '2026-08-31']]]), '/data/attributes/end_date'];
    yield 'unexpected attribute' => [array_replace_recursive($valid, ['data' => ['attributes' => ['name' => 'extra']]]), '/data/attributes'];
}
