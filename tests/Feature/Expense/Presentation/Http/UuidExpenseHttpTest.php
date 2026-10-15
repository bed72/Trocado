<?php

declare(strict_types=1);

use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->withToken(IdentityFixture::token($this->owner, expiresAt: now()->addDays(30)));
});

it('rejects malformed or legacy route identifiers before business lookup', function (string $id, string $method): void {
    $repository = $this->createMock(ExpenseRepository::class);
    foreach (['getById', 'update', 'delete'] as $operation) {
        $repository->expects($this->never())->method($operation);
    }
    $this->app->instance(ExpenseRepository::class, $repository);
    $this->json($method, '/api/expenses/'.$id, ['data' => ['type' => 'expenses', 'attributes' => ['amount' => 2000]]])
        ->assertNotFound()->assertHeader('Content-Type', 'application/vnd.api+json');
})->with([
    'numeric' => '42', 'text' => 'not-an-id', 'hash' => str_repeat('a', 64),
    'nil' => '00000000-0000-0000-0000-000000000000',
    'v4' => '017f22e2-79b0-4cc3-98c4-000000000001',
    'v6' => '017f22e2-79b0-6cc3-98c4-000000000001',
    'v8' => '017f22e2-79b0-8cc3-98c4-000000000001',
    'variant' => '017f22e2-79b0-7cc3-08c4-000000000001',
])->with(['GET', 'PATCH', 'DELETE']);

it('canonicalizes uppercase UUID routes and preserves the persisted identity through CRUD', function (): void {
    $created = $this->postJson(route('expenses.create'), ['data' => ['type' => 'expenses', 'attributes' => [
        'amount' => 9007199254740993, 'category' => 'food', 'occurred_on' => '2026-09-24', 'description' => null,
    ]]])->assertCreated();
    $id = $created->json('data.id');
    expect($id)->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/');
    $model = ExpenseModel::query()->findOrFail($id);
    expect($model->getIncrementing())->toBeFalse()->and($model->getKeyType())->toBe('string')
        ->and($model->user_id)->toBe($this->owner->id)->and($model->amount)->toBe(9007199254740993);

    $url = route('expenses.show', ['expense' => strtoupper($id)]);
    $this->getJson($url)->assertOk()->assertJsonPath('data.id', $id)->assertJsonPath('data.attributes.description', null);
    $this->patchJson($url, ['data' => ['type' => 'expenses', 'attributes' => ['amount' => 2000]]])
        ->assertOk()->assertJsonPath('data.id', $id)->assertJsonPath('data.attributes.amount', 2000);
    $this->deleteJson($url)->assertNoContent();
    expect(DB::table('expenses')->where('id', $id)->exists())->toBeFalse();
    $this->getJson($url)->assertNotFound();
});

it('gives the same not found response for absent deleted and foreign UUIDs', function (string $method): void {
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'foreign-uuid@example.com');
    $foreign = ExpenseQueryHistoryFixture::create($other->id, '2026-09-24', 1000, 'food');
    $deleted = ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-24', 1000, 'food');
    DB::table('expenses')->where('id', $deleted)->delete();
    $documents = [];
    foreach ([UuidFixture::at(999), $deleted, $foreign] as $id) {
        $documents[] = $this->json($method, route('expenses.show', ['expense' => $id]), ['data' => ['type' => 'expenses', 'attributes' => ['amount' => 2000]]])
            ->assertNotFound()->json();
    }
    expect($documents[0])->toBe($documents[1])->toBe($documents[2]);
    expect(ExpenseModel::query()->findOrFail($foreign)->amount)->toBe(1000);
})->with(['GET', 'PATCH', 'DELETE']);
