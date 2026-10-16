<?php

declare(strict_types=1);

use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;
use App\Expense\Application\Exceptions\InvalidExpenseSuggestionsProjectionException;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Exceptions;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Expense\Fixtures\ExpenseSuggestionHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-11 12:00:00 UTC');
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->token = IdentityFixture::token($this->owner, new DateTimeImmutable('2027-02-01'));
});

afterEach(function (): void {
    Auth::forgetGuards();
    Date::setTestNow();
});

it('retains identity through terms case amounts windows disappearance return and a new PAT in a child process', function (): void {
    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        for ($index = 0; $index < 100; $index++) {
            ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14001, $date, '2026-09-01 00:00:00');
        }
    }
    $first = $this->withToken($this->token)->getJson('/api/expenses/suggestions?query=Int')
        ->assertOk()->assertJsonPath('data.0.attributes.amount', 14001)->json('data.0.id');
    expect($first)->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/');
    $row = DB::table('resource_identities')->where('id', $first)->sole();
    expect(array_keys((array) $row))->toBe(['id', 'user_id', 'namespace', 'identity_version', 'logical_fingerprint', 'created_at'])
        ->and($row->user_id)->toBe($this->owner->id)
        ->and($row->namespace)->toBe('expense-suggestions')->and($row->identity_version)->toBe(1)
        ->and(DB::table('expenses')->where('id', $first)->exists())->toBeFalse();

    DB::table('expenses')->where('user_id', $this->owner->id)->update(['amount' => 15000]);
    $this->getJson('/api/expenses/suggestions?query=net')->assertOk()
        ->assertJsonPath('data.0.id', $first)->assertJsonPath('data.0.attributes.amount', 15000);
    ExpenseSuggestionHistoryFixture::create($this->owner->id, " \tINTERNET\n ", 15001, '2026-09-02', '2026-10-01 00:00:00');
    $this->getJson('/api/expenses/suggestions?query=iNt')->assertOk()->assertJsonPath('data.0.id', $first)
        ->assertJsonPath('data.0.attributes.description', 'INTERNET')->assertJsonMissingPath('data.0.attributes.amount');
    Date::setTestNow('2026-11-11 12:00:00 UTC');
    $this->getJson('/api/expenses/suggestions?query=Internet')->assertOk()->assertJsonPath('data.0.id', $first)
        ->assertJsonMissingPath('data.0.attributes.amount');
    DB::table('expenses')->where('user_id', $this->owner->id)->delete();
    $this->getJson('/api/expenses/suggestions?query=Int')->assertOk()->assertExactJson(['data' => []]);
    expect(DB::table('resource_identities')->sole())->toEqual($row);
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet nova', 100, '2026-10-01', '2026-11-01 00:00:00');
    $different = $this->getJson('/api/expenses/suggestions?query=Int')->assertOk()->json('data.0.id');
    expect($different)->not->toBe($first);
    DB::table('expenses')->where('user_id', $this->owner->id)->delete();
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'internet', 199, '2026-10-01', '2026-11-01 00:00:00');
    $this->owner->tokens()->delete();
    $newToken = IdentityFixture::token($this->owner, new DateTimeImmutable('2027-02-01'));
    $child = new ConcurrentDatabaseProcess(static function () use ($newToken, $first): void {
        Auth::forgetGuards();
        $kernel = app(Kernel::class);
        $request = Request::create('/api/expenses/suggestions?query=NET', 'GET', server: [
            'HTTP_AUTHORIZATION' => 'Bearer '.$newToken, 'HTTP_ACCEPT' => 'application/vnd.api+json',
        ]);
        $response = $kernel->handle($request);
        try {
            expect($response->getStatusCode())->toBe(200);
            $data = json_decode($response->getContent(), true, flags: JSON_THROW_ON_ERROR)['data'];
            expect($data)->toHaveCount(1)->and($data[0]['id'])->toBe($first)
                ->and($data[0]['attributes'])->toBe(['description' => 'internet']);
        } finally {
            $kernel->terminate($request, $response);
        }
    });
    try {
        $child->go();
        $child->done();
    } finally {
        $child->close();
    }
    Auth::forgetGuards();
    $this->withToken($this->token)->getJson('/api/expenses/suggestions?query=Int')->assertUnauthorized();
    Auth::forgetGuards();
    $this->withToken($newToken)->getJson('/api/expenses/suggestions?query=Int')->assertOk()->assertJsonPath('data.0.id', $first);
    expect(DB::table('resource_identities')->where('id', $first)->sole())->toEqual($row)
        ->and(DB::table('resource_identities')->count())->toBe(2);
});

it('keeps one financial read and bounded registry statements for empty single or five final suggestions', function (int $groups): void {
    for ($index = 1; $index <= $groups; $index++) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, "Internet {$index}", 100, '2026-09-01', '2026-09-01 00:00:00');
    }
    $expected = min($groups, 5);
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $rows = [];
    DB::enableQueryLog();
    try {
        foreach ([false, true] as $hit) {
            DB::flushQueryLog();
            $data = $this->withToken($this->token)->getJson('/api/expenses/suggestions?query=Int')->assertOk()->json('data');
            $queries = DB::getQueryLog();
            $financial = array_values(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"expenses"')));
            $registry = array_values(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"resource_identities"')));
            expect($data)->toHaveCount($expected)->and($financial)->toHaveCount(1)
                ->and($financial[0]['query'])->toStartWith('WITH owned AS NOT MATERIALIZED')
                ->and($registry)->toHaveCount($expected === 0 ? 0 : ($hit ? 1 : 3));
            if ($expected > 0) {
                expect($registry[0]['query'])->toStartWith('select ');
                if (! $hit) {
                    expect($registry[1]['query'])->toStartWith('insert into ')->and($registry[2]['query'])->toStartWith('select ');
                    $rows = DB::table('resource_identities')->orderBy('id')->get()->all();
                } else {
                    expect(DB::table('resource_identities')->orderBy('id')->get()->all())->toEqual($rows);
                }
                expect(array_column($data, 'id'))->toHaveCount(count(array_unique(array_column($data, 'id'))));
            }
        }
        expect(DB::table('resource_identities')->count())->toBe($expected)
            ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
})->with(['empty' => 0, 'one' => 1, 'five after SQL limit' => 6]);

it('resolves a mixed batch creating only absent SQL keys while retaining hits and ranking', function (): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet alfa', 100, '2026-09-01', '2026-09-01 00:00:00');
    $first = $this->withToken($this->token)->getJson('/api/expenses/suggestions?query=Int')->assertOk()->json('data.0.id');
    $row = DB::table('resource_identities')->sole();
    foreach (['beta', 'gamma', 'delta', 'epsilon'] as $suffix) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet '.$suffix, 100, '2026-09-01', '2026-09-01 00:00:00');
    }
    DB::enableQueryLog();
    try {
        DB::flushQueryLog();
        $data = $this->getJson('/api/expenses/suggestions?query=Int')->assertOk()->json('data');
        $registry = array_values(array_filter(DB::getQueryLog(), static fn (array $query): bool => str_contains($query['query'], '"resource_identities"')));
        expect($registry)->toHaveCount(3)->and($registry[1]['query'])->toStartWith('insert into ')
            ->and(array_column(array_column($data, 'attributes'), 'description'))->toBe([
                'Internet alfa', 'Internet beta', 'Internet delta', 'Internet epsilon', 'Internet gamma',
            ])->and($data[0]['id'])->toBe($first)
            ->and(DB::table('resource_identities')->count())->toBe(5)
            ->and(DB::table('resource_identities')->where('id', $first)->sole())->toEqual($row);
        $insertedIds = array_values(array_intersect($registry[1]['bindings'], array_column($data, 'id')));
        expect($insertedIds)->toHaveCount(4)->not->toContain($first);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
});

it('distinguishes accents and internal spaces using the SQL key while preserving uppercase equivalence', function (): void {
    foreach (['Café', 'Cafe', 'Plano  Internet', 'Plano Internet'] as $description) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2026-09-01', '2026-09-01 00:00:00');
    }
    $ids = [];
    foreach (['Café', 'Cafe', 'Plano  Internet', 'Plano Internet'] as $query) {
        $ids[] = $this->withToken($this->token)->getJson('/api/expenses/suggestions?query='.rawurlencode($query))
            ->assertOk()->assertJsonCount(1, 'data')->json('data.0.id');
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, " \tCAFÉ\n", 100, '2026-09-01', '2026-10-01 00:00:00');
    $this->getJson('/api/expenses/suggestions?query='.rawurlencode('FÉ'))->assertOk()
        ->assertJsonPath('data.0.id', $ids[0])->assertJsonPath('data.0.attributes.description', 'CAFÉ');
    expect(array_unique($ids))->toHaveCount(4)->and(DB::table('resource_identities')->count())->toBe(4);
});

it('fails without partial data or new identities on source projection or registry failure after an insert', function (string $failure): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet private', 14001, '2026-09-01', '2026-09-01 00:00:00');
    $before = DB::table('expenses')->get()->all();
    $sentinel = new RuntimeException('Source sentinel');
    $active = $failure === 'registry';
    $written = 0;
    if (! $active) {
        $repository = $this->createMock(ExpenseSuggestionsRepository::class);
        $search = $repository->expects($this->once())->method('search');
        if ($failure === 'source') {
            $search->willThrowException($sentinel);
        } else {
            $search->willReturn([
                new ExpenseSuggestionHistoryOutput('internet private', 'Internet private', 3, 14001, 14001),
                new ExpenseSuggestionHistoryOutput('', 'Invalid second candidate', 0, null, null),
            ]);
        }
        $this->app->instance(ExpenseSuggestionsRepository::class, $repository);
    }
    DB::listen(static function (QueryExecuted $event) use (&$active, &$written): void {
        if ($active && str_starts_with($event->sql, 'insert into "resource_identities"')) {
            $written++;
            expect(DB::table('resource_identities')->count())->toBe(1);
            DB::statement("DO $$ BEGIN RAISE EXCEPTION 'Registry SQL sentinel' USING ERRCODE = '23514'; END $$");
        }
    });
    $handler = Exceptions::getFacadeRoot();
    Exceptions::fake();
    DB::enableQueryLog();
    try {
        DB::flushQueryLog();
        $this->withToken($this->token)->getJson('/api/expenses/suggestions?query=Int')->assertStatus(500)
            ->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['errors' => [[
                'status' => '500', 'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.',
            ]]])->assertJsonMissingPath('data');
        $queries = DB::getQueryLog();
        if ($failure === 'registry') {
            Exceptions::assertReported(static fn (ResourcePersistenceException $exception): bool => $exception->getPrevious() === null
                && $exception->getMessage() === 'Resource identities could not be resolved.');
            expect(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"expenses"')))->toHaveCount(1);
        } else {
            expect(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'resource_identities')))->toBe([]);
            if ($failure === 'source') {
                Exceptions::assertReported(static fn (RuntimeException $exception): bool => $exception === $sentinel);
            } else {
                Exceptions::assertReported(InvalidExpenseSuggestionsProjectionException::class);
            }
        }
        Exceptions::assertReportedCount(1);
        expect($written)->toBe($failure === 'registry' ? 1 : 0)
            ->and(DB::table('resource_identities')->count())->toBe(0)
            ->and(DB::table('expenses')->get()->all())->toEqual($before)
            ->and(DB::connection()->transactionLevel())->toBe(0);
    } finally {
        $active = false;
        DB::disableQueryLog();
        DB::flushQueryLog();
        Exceptions::swap($handler);
    }
})->with(['source', 'projection', 'registry']);
