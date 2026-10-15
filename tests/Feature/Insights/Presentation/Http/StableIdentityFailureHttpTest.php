<?php

declare(strict_types=1);

use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Exceptions;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('fails without data or associations on financial read or confirmed registry insert failure', function (bool $registry): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    $sentinel = new RuntimeException('Financial read sentinel');
    $written = 0;
    $active = $registry;
    if (! $registry) {
        $repository = $this->createMock(ExpenseAnalysisRepository::class);
        $repository->expects($this->once())->method('analyze')->willThrowException($sentinel);
        $this->app->instance(ExpenseAnalysisRepository::class, $repository);
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
        $this->withToken($token)->getJson(route('insights.index'))
            ->assertStatus(500)->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
                'status' => '500', 'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.',
            ]]])->assertJsonMissingPath('data');
        $queries = DB::getQueryLog();
        if ($registry) {
            Exceptions::assertReported(static fn (ResourcePersistenceException $exception): bool => $exception->getPrevious() === null
                && $exception->getMessage() === 'Resource identities could not be resolved.');
            expect(array_filter($queries, static fn (array $query): bool => str_starts_with($query['query'], 'WITH periods')))->toHaveCount(1);
        } else {
            Exceptions::assertReported(static fn (RuntimeException $exception): bool => $exception === $sentinel);
            expect(array_filter($queries, static fn (array $query): bool => str_contains($query['query'], 'resource_identities')))->toBe([]);
        }
        Exceptions::assertReportedCount(1);
        expect($written)->toBe($registry ? 1 : 0)
            ->and(DB::table('resource_identities')->count())->toBe(0)
            ->and(DB::connection()->transactionLevel())->toBe(0);
    } finally {
        $active = false;
        DB::disableQueryLog();
        DB::flushQueryLog();
        Exceptions::swap($handler);
        Date::setTestNow();
    }
})->with(['financial source' => false, 'registry rollback after INSERT' => true]);
