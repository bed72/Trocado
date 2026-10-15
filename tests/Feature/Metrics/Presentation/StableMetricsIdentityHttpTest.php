<?php

declare(strict_types=1);

use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Metrics\Application\Data\ExpenseCategoryTotalOutput;
use App\Metrics\Application\Data\ExpenseMetricsProjectionOutput;
use App\Metrics\Application\Repositories\ExpenseMetricsRepository;
use Illuminate\Contracts\Http\Kernel;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Exceptions;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Str;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('retains a singular UUID across zero creation editing recategorization occurrence deletion and replacement PAT in a child process', function (bool $grouped): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
    Queue::fake();
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-stable-metrics@example.com');
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    $url = '/api/metrics/expenses'.($grouped ? '?group_by=category' : '');
    $explicit = '/api/metrics/expenses?end_date=%202026-10-31%20&start_date=2026-10-01'.($grouped ? '&group_by=%20category%20' : '');
    try {
        $first = $this->withToken($token)->getJson($url)->assertOk()->assertJsonPath('data.attributes.total_amount', '0')->json('data');
        expect($first['id'])->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/');
        $row = DB::table('resource_identities')->where('id', $first['id'])->sole();
        expect($row->user_id)->toBe($owner->getKey())->and($row->namespace)->toBe('expense-metrics')->and($row->identity_version)->toBe(1);
        $this->getJson($explicit)->assertOk()->assertJsonPath('data', $first);
        $expenseId = (string) Str::uuid7();
        DB::table('expenses')->insert([
            'id' => $expenseId, 'user_id' => $owner->getKey(), 'amount' => 10000,
            'category' => 'other', 'occurred_on' => '2026-10-31', 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->getJson($explicit)->assertOk()->assertJsonPath('data.id', $first['id'])->assertJsonPath('data.attributes.total_amount', '10000');
        DB::table('expenses')->where('id', $expenseId)->update(['amount' => 12500, 'category' => 'food', 'description' => 'Changed facts']);
        $updated = $this->getJson($explicit)->assertOk()->assertJsonPath('data.id', $first['id'])->assertJsonPath('data.attributes.total_amount', '12500');
        if ($grouped) {
            $updated->assertJsonPath('data.attributes.categories', [['category' => 'food', 'percentage' => '100.00', 'total_amount' => '12500']]);
        } else {
            $updated->assertJsonMissingPath('data.attributes.categories');
        }
        DB::table('expenses')->where('id', $expenseId)->update(['occurred_on' => '2026-11-01']);
        $this->getJson($explicit)->assertOk()->assertJsonPath('data', $first);
        DB::table('expenses')->where('id', $expenseId)->update(['occurred_on' => '2026-10-31']);
        $owner->tokens()->delete();
        $newToken = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
        $child = new ConcurrentDatabaseProcess(static function () use ($explicit, $newToken, $first): void {
            Auth::forgetGuards();
            $kernel = app(Kernel::class);
            $request = Request::create($explicit, 'GET', server: [
                'HTTP_AUTHORIZATION' => 'Bearer '.$newToken, 'HTTP_ACCEPT' => 'application/vnd.api+json',
            ]);
            $response = $kernel->handle($request);
            try {
                expect($response->getStatusCode())->toBe(200);
                $data = json_decode($response->getContent(), true, flags: JSON_THROW_ON_ERROR)['data'];
                expect($data['id'])->toBe($first['id'])->and($data['attributes']['total_amount'])->toBe('12500');
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
        $this->withToken($token)->getJson($explicit)->assertUnauthorized();
        DB::table('expenses')->where('id', $expenseId)->delete();
        Auth::forgetGuards();
        $this->withToken($newToken)->getJson($explicit)->assertOk()->assertJsonPath('data', $first);
        Auth::forgetGuards();
        $otherToken = IdentityFixture::token($other, expiresAt: now()->addDays(30));
        $otherData = $this->withToken($otherToken)->getJson($explicit)->assertOk()->assertJsonPath('data.attributes.total_amount', '0')->json('data');
        expect($otherData['id'])->not->toBe($first['id']);
        Auth::forgetGuards();
        $opposite = $this->withToken($newToken)->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31'.($grouped ? '' : '&group_by=category'))->assertOk()->json('data.id');
        $period = $this->getJson('/api/metrics/expenses?start_date=2026-10-02&end_date=2026-10-31'.($grouped ? '&group_by=category' : ''))->assertOk()->json('data.id');
        expect(array_unique([$first['id'], $otherData['id'], $opposite, $period]))->toHaveCount(4)
            ->and(DB::table('resource_identities')->where('id', $first['id'])->sole())->toEqual($row)
            ->and(DB::table('resource_identities')->count())->toBe(4);
        Queue::assertNothingPushed();
    } finally {
        Auth::forgetGuards();
        Date::setTestNow();
    }
})->with(['total' => false, 'category' => true]);

it('uses one financial statement and three registry statements on miss or one read on hit independent of category count', function (int $categoryCount): void {
    Queue::fake();
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    foreach (array_slice(ExpenseCategoryEnum::cases(), 0, $categoryCount) as $category) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(), 'user_id' => $owner->getKey(), 'amount' => 100,
            'category' => $category->value, 'occurred_on' => '2026-10-01', 'created_at' => now(), 'updated_at' => now(),
        ]);
    }
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $url = '/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category';
    $row = null;
    DB::enableQueryLog();
    try {
        foreach ([false, true] as $hit) {
            DB::flushQueryLog();
            $data = $this->withToken($token)->getJson($url)->assertOk()->json('data');
            $queries = DB::getQueryLog();
            $financial = array_values(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"expenses"')));
            $registry = array_values(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], '"resource_identities"')));
            expect($financial)->toHaveCount(1)
                ->and($financial[0]['query'])->toStartWith('select ')
                ->and($registry)->toHaveCount($hit ? 1 : 3)
                ->and($data['attributes']['total_amount'])->toBe((string) ($categoryCount * 100))
                ->and($data['attributes']['categories'])->toHaveCount($categoryCount);
            foreach ($data['attributes']['categories'] as $category) {
                expect(array_keys($category))->toBe(['category', 'percentage', 'total_amount']);
            }
            expect($registry[0]['query'])->toStartWith('select ');
            if (! $hit) {
                expect($registry[1]['query'])->toStartWith('insert into ')->and($registry[2]['query'])->toStartWith('select ');
                $row = DB::table('resource_identities')->sole();
            } else {
                expect(DB::table('resource_identities')->sole())->toEqual($row);
            }
        }
        expect(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
        Queue::assertNothingPushed();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
})->with(['zero' => 0, 'one' => 1, 'all categories' => 18]);

it('fails without data or identities on source invalid projection or registry failure after a confirmed insert', function (string $failure): void {
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    $sentinel = new RuntimeException('Financial source sentinel');
    $active = $failure === 'registry';
    $written = 0;
    if (! $active) {
        $repository = $this->createMock(ExpenseMetricsRepository::class);
        $read = $repository->expects($this->once())->method('summarize');
        if ($failure === 'source') {
            $read->willThrowException($sentinel);
        } else {
            $read->willReturn($failure === 'precision'
                ? new ExpenseMetricsProjectionOutput('01')
                : new ExpenseMetricsProjectionOutput('100', [new ExpenseCategoryTotalOutput('food', '99')]));
        }
        $this->app->instance(ExpenseMetricsRepository::class, $repository);
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
    DB::flushQueryLog();
    try {
        $this->withToken($token)->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category')
            ->assertStatus(500)->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
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
            }
        }
        Exceptions::assertReportedCount(1);
        expect($written)->toBe($failure === 'registry' ? 1 : 0)
            ->and(DB::table('resource_identities')->count())->toBe(0)
            ->and(DB::connection()->transactionLevel())->toBe(0);
    } finally {
        $active = false;
        DB::disableQueryLog();
        DB::flushQueryLog();
        Exceptions::swap($handler);
    }
})->with(['source', 'precision', 'reconciliation', 'registry']);
