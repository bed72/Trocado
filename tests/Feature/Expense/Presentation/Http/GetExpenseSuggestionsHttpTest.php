<?php

declare(strict_types=1);

use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Expense\Infrastructure\Agents\ExpenseClassificationAgent;
use App\Expense\Presentation\Http\Controllers\GetExpenseSuggestionsController;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Expense\Fixtures\ExpenseSuggestionHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Carbon::setTestNow(Carbon::parse('2026-10-11 12:00:00', 'UTC'));
    $this->originalAppTimezone = config('app.timezone');
    config()->set('app.timezone', 'UTC');
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->token = IdentityFixture::token($this->owner, new DateTimeImmutable('2026-11-10 12:00:00 UTC'));
});

afterEach(function (): void {
    config()->set('app.timezone', $this->originalAppTimezone);
    Carbon::setTestNow();
});

it('resolves the static route with the same protections as expense listing', function (): void {
    $route = app('router')->getRoutes()->getByName('expenses.suggestions');
    $listing = app('router')->getRoutes()->getByName('expenses.index');

    expect($route->uri())->toBe('api/expenses/suggestions')
        ->and($route->getActionName())->toBe(GetExpenseSuggestionsController::class)
        ->and($route->gatherMiddleware())->toBe($listing->gatherMiddleware());
    $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['data' => []]);
});

it('rejects absent invalid expired or revoked Bearer tokens without querying suggestions', function (string $state): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $this->app->instance(ExpenseSuggestionsRepository::class, $repository);

    if ($state === 'expired') {
        $this->owner->tokens()->update(['expires_at' => '2026-10-11 11:59:59']);
    } elseif ($state === 'revoked') {
        $this->owner->tokens()->delete();
    }

    if ($state !== 'absent') {
        $this->withToken($state === 'invalid' ? 'invalid-token' : $this->token);
    }

    $this->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '401')->assertJsonMissingPath('data');
})->with(['absent', 'invalid', 'expired', 'revoked']);

it('rejects inactive and unverified accounts before history reads', function (UserStatusEnum $status, bool $verified): void {
    $this->owner->forceFill(['status' => $status, 'email_verified_at' => $verified ? '2026-01-01 00:00:00' : null])->save();
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $this->app->instance(ExpenseSuggestionsRepository::class, $repository);

    $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '403')->assertJsonMissingPath('data');
})->with([
    'blocked' => [UserStatusEnum::Blocked, true],
    'pending' => [UserStatusEnum::Pending, true],
    'unverified' => [UserStatusEnum::Active, false],
]);

it('rejects invalid query strings before reading and associates JSON API errors with parameters', function (string $suffix, string $parameter): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $this->app->instance(ExpenseSuggestionsRepository::class, $repository);
    $suffix = str_replace('{owner}', (string) $this->owner->id, $suffix);

    $response = $this->withToken($this->token)->getJson(route('expenses.suggestions').$suffix)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect(array_column(array_column($response->json('errors'), 'source'), 'parameter'))->toContain($parameter);
    $response->assertJsonPath('errors.0.status', '422')->assertJsonMissingPath('data');
})->with([
    'missing' => ['', 'query'],
    'empty' => ['?query=', 'query'],
    'spaces' => ['?query=%20%09%0A', 'query'],
    'array' => ['?query%5B%5D=Int', 'query'],
    'nested' => ['?query%5Btext%5D=Int', 'query'],
    'duplicated' => ['?query=Int&query=net', 'query'],
    '65 Unicode characters' => ['?query='.rawurlencode(str_repeat('é', 65)), 'query'],
    'length before trim' => ['?query='.rawurlencode(' '.str_repeat('é', 64)), 'query'],
    'empty owner' => ['?query=Int&user_id=', 'user_id'],
    'bare owner' => ['?query=Int&user_id', 'user_id'],
    'own identifier' => ['?query=Int&user_id={owner}', 'user_id'],
    'foreign identifier' => ['?query=Int&user_id=999999', 'user_id'],
    'owner array' => ['?query=Int&user_id%5B%5D=1', 'user_id'],
]);

it('does not accept search input from a GET body', function (): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $this->app->instance(ExpenseSuggestionsRepository::class, $repository);

    $this->withToken($this->token)->json('GET', route('expenses.suggestions'), ['query' => 'Int'])
        ->assertUnprocessable()->assertJsonPath('errors.0.source.parameter', 'query');
});

it('returns an empty collection for absent unusable or nonmatching history', function (array $descriptions): void {
    foreach ($descriptions as $description) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2026-09-01', '2026-09-01 00:00:00');
    }

    $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertOk()->assertExactJson(['data' => []]);
})->with([
    'no history' => [[]],
    'no matches' => [['Mercado']],
    'unusable descriptions only' => [[null, '', " \t\r\n "]],
]);

it('accepts 64 Unicode characters and trims only external whitespace', function (): void {
    $description = str_repeat('é', 64);
    ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2020-01-01', '2026-01-01 00:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Plano  Internet', 100, '2020-01-01', '2026-01-01 00:00:00');

    $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => $description]))
        ->assertOk()->assertJsonPath('data.0.attributes.description', $description);
    $this->getJson(route('expenses.suggestions', ['query' => " \tPlano  Internet\n "]))
        ->assertOk()->assertJsonPath('data.0.attributes.description', 'Plano  Internet');
});

it('exposes only the owner suggestions with exact allowed attributes and omits inconsistent amounts', function (): void {
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14001, $date, '2026-09-01 00:00:00');
        ExpenseSuggestionHistoryFixture::create($other->id, 'Internet', 99000, $date, '2026-10-01 00:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Plano Internet', 100, '2026-09-01', '2026-09-01 00:00:00');
    ExpenseSuggestionHistoryFixture::create($other->id, 'Internet exclusivo', 100, '2026-09-01', '2026-10-01 00:00:00');
    $response = $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('data.0.type', 'expense-suggestions');

    expect($response->json('data.0.id'))->toBeString()->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/')
        ->and($response->json('data.0.attributes'))->toBe(['description' => 'Internet', 'amount' => 14001])
        ->and($response->json('data.1.attributes'))->toBe(['description' => 'Plano Internet']);
    $response->assertJsonMissingPath('links')->assertJsonMissingPath('meta');
});

it('keeps ids stable across terms and new spelling variants and distinct between accounts', function (): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 100, '2020-01-01', '2026-01-01 00:00:00');
    $first = $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))->assertOk()->json('data.0.id');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, ' INTERNET ', 100, '2020-01-01', '2026-10-01 00:00:00');
    $variant = $this->getJson(route('expenses.suggestions', ['query' => 'net']))->assertOk()->json('data.0.id');
    $other = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'), email: 'other@example.com');
    $token = IdentityFixture::token($other, new DateTimeImmutable('2026-11-10'));
    ExpenseSuggestionHistoryFixture::create($other->id, 'Internet', 100, '2020-01-01', '2026-01-01 00:00:00');
    $this->app['auth']->forgetGuards();
    $foreign = $this->withToken($token)->getJson(route('expenses.suggestions', ['query' => 'Int']))->assertOk()->json('data.0.id');

    expect($first)->toBe($variant)->not->toBe($foreign);
});

it('uses the configured civil timezone at a UTC month boundary', function (): void {
    config()->set('app.timezone', 'America/Sao_Paulo');
    Carbon::setTestNow(Carbon::parse('2026-11-01 01:00:00', 'UTC'));
    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, $date, '2026-09-01 00:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 15000, '2026-10-01', '2026-10-01 00:00:00');

    $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertOk()->assertJsonPath('data.0.attributes.amount', 14000);
});

it('allows the consumer to create an expense with a value different from the selected suggestion', function (): void {
    Queue::fake();
    ExpenseClassificationAgent::fake();

    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, $date, '2026-09-01 00:00:00');
    }

    $suggestion = $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))
        ->assertOk()->assertJsonPath('data.0.attributes.amount', 14000)->json('data.0');

    $response = $this->postJson(route('expenses.create'), [
        'data' => [
            'type' => 'expenses',
            'attributes' => ['description' => $suggestion['attributes']['description'], 'amount' => 15000, 'occurred_on' => '2026-10-11'],
        ],
    ])->assertCreated()
        ->assertJsonPath('data.attributes.description', 'Internet')
        ->assertJsonPath('data.attributes.amount', 15000)
        ->assertJsonPath('data.attributes.category', 'other');

    expect(DB::table('expenses')->where('id', $response->json('data.id'))->value('amount'))->toBe(15000);
    ExpenseClassificationAgent::assertNeverPrompted();
});

it('leaves expenses and classification attempts unchanged and never calls AI or dispatches jobs', function (bool $consistent): void {
    Queue::fake();
    Bus::fake();
    ExpenseClassificationAgent::fake();
    $classification = $this->createMock(ExpenseClassificationPort::class);
    $dispatch = $this->createMock(ExpenseClassificationDispatchPort::class);
    $classification->expects($this->never())->method('suggest');
    $dispatch->expects($this->never())->method('dispatch');
    $this->app->instance(ExpenseClassificationPort::class, $classification);
    $this->app->instance(ExpenseClassificationDispatchPort::class, $dispatch);
    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        $id = ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', $consistent || $date !== '2026-09-01' ? 14000 : 15000, $date, '2026-09-01 00:00:00');
        DB::table('expenses')->where('id', $id)->update([
            'classification_token' => substr(hash('sha256', $date), 0, 32), 'classification_expires_at' => '2026-10-12 00:00:00',
        ]);
    }
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $jobs = DB::table('jobs')->get()->all();
    $response = $this->withToken($this->token)->getJson(route('expenses.suggestions', ['query' => 'Int']))->assertOk();

    if ($consistent) {
        $response->assertJsonPath('data.0.attributes.amount', 14000);
    } else {
        $response->assertJsonMissingPath('data.0.attributes.amount');
    }
    expect(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before)
        ->and(DB::table('jobs')->get()->all())->toEqual($jobs);
    Queue::assertNothingPushed();
    Bus::assertNothingDispatched();
    ExpenseClassificationAgent::assertNeverPrompted();
})->with(['consistent' => true, 'inconsistent' => false]);
