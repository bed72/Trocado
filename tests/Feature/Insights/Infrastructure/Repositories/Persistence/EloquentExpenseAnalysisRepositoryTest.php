<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\InsightMessageTemplateOutput;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use App\Insights\Infrastructure\Repositories\Persistence\EloquentExpenseAnalysisRepository;
use Illuminate\Support\Facades\DB;

function createInsightUser(): int
{
    return DB::table('users')->insertGetId([
        'name' => 'Maria', 'email' => 'insights@example.com', 'password' => 'unused',
    ]);
}

function insightExpenseAnalysisRepository(): ExpenseAnalysisRepository
{
    return app(ExpenseAnalysisRepository::class);
}

function insertInsightExpense(int $userId, string $date, int $amount, string $category = 'other', ?string $description = null): int
{
    return DB::table('expenses')->insertGetId([
        'updated_at' => '2026-10-12 12:00:00',
        'category' => $category, 'created_at' => '2026-10-12 12:00:00',
        'user_id' => $userId, 'occurred_on' => $date, 'amount' => $amount,
        'description' => $description,
    ]);
}

it('aggregates only the owner occurrence periods in one read without writes', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisRepository();
    $otherUserId = DB::table('users')->insertGetId([
        'name' => 'Pedro', 'email' => 'other-insights@example.com', 'password' => 'unused',
    ]);
    insertInsightExpense($userId, '2026-10-01', 20000, 'food');
    insertInsightExpense($userId, '2026-10-02', 30000, 'other', "  <b>Aluguel</b>\n mensal  ");
    insertInsightExpense($userId, '2026-10-12', 10000, 'food');
    insertInsightExpense($userId, '2026-10-13', 99999, 'other', 'Futuro');
    insertInsightExpense($userId, '2026-09-11', 15000, 'food');
    insertInsightExpense($userId, '2026-09-12', 25000, 'other');
    insertInsightExpense($userId, '2026-08-31', 5000);
    insertInsightExpense($otherUserId, '2026-10-01', 999999, 'health', 'Outra conta');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $output = $port->analyze($userId, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect($port)->toBeInstanceOf(EloquentExpenseAnalysisRepository::class)
        ->and($queries)->toHaveCount(1)
        ->and($queries[0]['query'])->toStartWith('WITH periods')
        ->and($output->hasHistoricalExpenses)->toBeTrue()
        ->and($output->currentMonth->totalAmount)->toBe('60000')
        ->and($output->currentMonth->expenseCount)->toBe(3)
        ->and($output->currentMonth->distinctDateCount)->toBe(3)
        ->and($output->currentMonth->largestExpenseAmount)->toBe('30000')
        ->and($output->currentMonth->largestExpenseCategory)->toBe('other')
        ->and($output->currentMonth->largestExpenseDescription)->toBe("  <b>Aluguel</b>\n mensal  ")
        ->and($output->currentMonth->largestExpenseOccurredOn)->toBe('2026-10-02')
        ->and($output->currentMonth->categories)->toHaveCount(2)
        ->and($output->currentMonth->categories[0]->totalAmount)->toBe('30000')
        ->and($output->currentMonth->categories[1]->category)->toBe('other')
        ->and($output->currentMonth->categories[1]->totalAmount)->toBe('30000')
        ->and($output->currentComparison->period->to())->toBe('2026-10-11')
        ->and($output->currentComparison->totalAmount)->toBe('50000')
        ->and($output->currentComparison->largestExpenseDescription)->toBe("  <b>Aluguel</b>\n mensal  ")
        ->and($output->currentComparison->largestExpenseOccurredOn)->toBe('2026-10-02')
        ->and($output->previousComparison->period->to())->toBe('2026-09-11')
        ->and($output->previousComparison->totalAmount)->toBe('15000')
        ->and($output->previousMonth->totalAmount)->toBe('40000')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('5000')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
});

it('caps equivalent windows by the shorter previous month', function (string $reference, string $currentEnd, string $previousEnd, int $days): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisRepository();
    $output = $port->analyze($userId, new InsightAnalysisPeriodValueObject($reference, DatePeriodValueObject::monthContaining($reference)));

    expect($output->currentComparison->period->to())->toBe($currentEnd)
        ->and($output->previousComparison->period->to())->toBe($previousEnd)
        ->and($output->currentComparison->period->days())->toBe($days)
        ->and($output->currentComparison->period->hasSameDurationAs($output->previousComparison->period))->toBeTrue()
        ->and($output->currentMonth->period->to())->toBe($reference);
})->with([
    ['2027-03-31', '2027-03-28', '2027-02-28', 28],
    ['2028-03-31', '2028-03-29', '2028-02-29', 29],
    ['2027-01-12', '2027-01-11', '2026-12-11', 11],
]);

it('distinguishes empty history from old history and excludes future history', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisRepository();
    insertInsightExpense($userId, '2026-10-02', 10000);
    $period = new InsightAnalysisPeriodValueObject('2026-10-01', DatePeriodValueObject::monthContaining('2026-10-01'));
    $output = $port->analyze($userId, $period);

    expect($output->hasHistoricalExpenses)->toBeFalse()
        ->and($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->currentMonth->expenseCount)->toBe(0)
        ->and($output->currentMonth->distinctDateCount)->toBe(0)
        ->and($output->currentMonth->largestExpenseAmount)->toBe('0')
        ->and($output->currentMonth->largestExpenseCategory)->toBeNull()
        ->and($output->currentMonth->largestExpenseDescription)->toBeNull()
        ->and($output->currentMonth->largestExpenseOccurredOn)->toBeNull()
        ->and($output->currentMonth->categories)->toBe([])
        ->and($output->currentComparison)->toBeNull()
        ->and($output->previousComparison)->toBeNull();

    insertInsightExpense($userId, '2020-01-01', 10000);
    $output = $port->analyze($userId, $period);

    expect($output->hasHistoricalExpenses)->toBeTrue()
        ->and($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('0');
});

it('preserves totals above machine integer limits and breaks largest expense ties deterministically', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisRepository();
    insertInsightExpense($userId, '2026-10-01', PHP_INT_MAX, 'other', 'Categoria posterior');
    insertInsightExpense($userId, '2026-10-03', PHP_INT_MAX, 'food', 'Escolhido por ID');
    insertInsightExpense($userId, '2026-10-02', PHP_INT_MAX, 'food', 'ID posterior');
    $output = $port->analyze($userId, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));

    expect($output->currentMonth->totalAmount)->toBe('27670116110564327421')
        ->and($output->currentMonth->distinctDateCount)->toBe(3)
        ->and($output->currentMonth->categories[0]->totalAmount)->toBe('18446744073709551614')
        ->and($output->currentMonth->largestExpenseAmount)->toBe((string) PHP_INT_MAX)
        ->and($output->currentMonth->largestExpenseCategory)->toBe('food')
        ->and($output->currentMonth->largestExpenseDescription)->toBe('Escolhido por ID')
        ->and($output->currentMonth->largestExpenseOccurredOn)->toBe('2026-10-03');
});

it('reads confirmed edits recategorizations and deletions without cached facts', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisRepository();
    $id = insertInsightExpense($userId, '2026-10-01', 10000);
    $period = new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12'));
    expect($port->analyze($userId, $period)->currentMonth->categories[0]->category)->toBe('other');

    DB::table('expenses')->where('id', $id)->update(['amount' => 20000, 'category' => 'food']);
    $output = $port->analyze($userId, $period);
    expect($output->currentMonth->totalAmount)->toBe('20000')
        ->and($output->currentMonth->categories[0]->category)->toBe('food');

    DB::table('expenses')->where('id', $id)->update(['occurred_on' => '2026-09-01']);
    $output = $port->analyze($userId, $period);
    expect($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->previousMonth->totalAmount)->toBe('20000');

    DB::table('expenses')->where('id', $id)->delete();
    expect($port->analyze($userId, $period)->hasHistoricalExpenses)->toBeFalse();
});

it('generates candidates from the real analytical projection', function (?int $explicitUserId, int $previousAccounts): void {
    $previousUserId = 0;

    for ($index = 0; $index < $previousAccounts; $index++) {
        $previousUserId = createInsightUser();
        DB::table('users')->where('id', $previousUserId)->delete();
    }

    if ($explicitUserId === null) {
        $userId = createInsightUser();
        expect($userId)->toBeGreaterThan($previousUserId);
    } else {
        DB::table('users')->insert([
            'id' => $explicitUserId, 'name' => 'Maria', 'email' => 'insights@example.com', 'password' => 'unused',
        ]);
        $userId = $explicitUserId;
    }

    $port = insightExpenseAnalysisRepository();
    foreach (['2026-08', '2026-09', '2026-10'] as $month) {
        foreach (['01', '02', '03', '04', '05'] as $day) {
            insertInsightExpense($userId, "{$month}-{$day}", 2000, 'food');
        }
    }

    $analysis = $port->analyze($userId, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
    $candidates = app(GenerateInsightCandidatesUseCase::class)->execute($analysis);
    $types = array_map(static fn (InsightCandidateValueObject $candidate): InsightTypeEnum => $candidate->type, $candidates);

    expect($types)->toBe([InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak])
        ->and($candidates[0]->ratio->roundedPercent())->toBe('100')
        ->and($candidates[1]->analysisPeriod->from())->toBe('2026-08-01');

    $selected = app(SelectInsightCandidatesUseCase::class)->execute($candidates);

    expect($selected)->toBe([$candidates[1]])
        ->and($selected[0]->type)->toBe(InsightTypeEnum::CategoryLeadStreak)
        ->and($selected[0]->type->group())->toBe(InsightGroupEnum::Comparison)
        ->and($selected[0]->category)->toBe('food')
        ->and($selected[0]->analysisPeriod->from())->toBe('2026-08-01')
        ->and($selected[0]->analysisPeriod->to())->toBe('2026-10-12')
        ->and($selected[0]->ratio)->toBeNull()
        ->and($selected[0]->comparisonPeriod)->toBeNull();

    $message = app(ComposeInsightMessageUseCase::class)->execute($userId, $selected[0], '2026-10-12');
    $templates = app(GetInsightMessageTemplatesUseCase::class)->execute($selected[0]);
    $parameters = ['{category}' => 'Alimentação', '{month}' => 'out/2026', '{first_month}' => 'ago/2026', '{previous_month}' => 'set/2026', '{day}' => '12'];
    $approvedDescriptions = array_map(static fn (InsightMessageTemplateOutput $template): string => strtr($template->description, $parameters), $templates);

    expect($message->title)->toBe('Alimentação')
        ->and($message->description)->toBeIn($approvedDescriptions)
        ->and(str_contains($message->description, '{'))->toBeFalse()
        ->and(mb_strlen($message->title, 'UTF-8'))->toBeLessThanOrEqual(24)
        ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(80);
})->with([
    'explicit account 1' => [1, 0],
    'explicit account 2' => [2, 0],
    'explicit account 3' => [3, 0],
    'explicit account 4' => [4, 0],
    'explicit account 15' => [15, 0],
    'explicit account 1500' => [1500, 0],
    'generated account without prior accounts' => [null, 0],
    'generated account after seven removed accounts' => [null, 7],
    'generated account after thirty-one removed accounts' => [null, 31],
]);

it('reads inclusive complete historical months and excludes later occurrence and other owners in one statement', function (string $selected, string $lastDay, string $priorLastDay, string $nextMonth): void {
    $userId = createInsightUser();
    $period = new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining($selected));
    $otherUserId = DB::table('users')->insertGetId(['name' => 'Pedro', 'email' => 'other-history@example.com', 'password' => 'unused']);
    insertInsightExpense($userId, $period->currentMonth->from(), 10000, 'food', 'Primeiro dia');
    insertInsightExpense($userId, $lastDay, 20000, 'food', 'Último dia selecionado');
    insertInsightExpense($userId, $priorLastDay, 30000, 'other', 'Último dia anterior');
    insertInsightExpense($userId, $nextMonth, 999999, 'other', 'Mês posterior');
    insertInsightExpense($otherUserId, $lastDay, 999999, 'health', 'Despesa de outra conta');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $output = insightExpenseAnalysisRepository()->analyze($userId, $period);
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect($queries)->toHaveCount(1)
        ->and($queries[0]['query'])->toStartWith('WITH periods')
        ->and($output->mode)->toBe(InsightPeriodModeEnum::Closed)
        ->and($output->currentMonth->totalAmount)->toBe('30000')
        ->and($output->currentMonth->expenseCount)->toBe(2)
        ->and($output->currentMonth->distinctDateCount)->toBe(2)
        ->and($output->currentMonth->period->from())->toBe($selected)
        ->and($output->currentMonth->period->to())->toBe($lastDay)
        ->and($output->currentMonth->largestExpenseAmount)->toBe('20000')
        ->and($output->currentMonth->largestExpenseCategory)->toBe('food')
        ->and($output->currentMonth->largestExpenseDescription)->toBe('Último dia selecionado')
        ->and($output->currentMonth->largestExpenseOccurredOn)->toBe($lastDay)
        ->and($output->currentComparison->totalAmount)->toBe('30000')
        ->and($output->currentComparison->largestExpenseAmount)->toBe('20000')
        ->and($output->currentComparison->largestExpenseCategory)->toBe('food')
        ->and($output->currentComparison->largestExpenseDescription)->toBe('Último dia selecionado')
        ->and($output->currentComparison->largestExpenseOccurredOn)->toBe($lastDay)
        ->and($output->previousMonth->totalAmount)->toBe('30000')
        ->and($output->previousMonth->largestExpenseAmount)->toBe('30000')
        ->and($output->previousMonth->largestExpenseCategory)->toBe('other')
        ->and($output->previousMonth->largestExpenseDescription)->toBe('Último dia anterior')
        ->and($output->previousMonth->largestExpenseOccurredOn)->toBe($priorLastDay)
        ->and($output->previousComparison->totalAmount)->toBe('30000')
        ->and($output->previousComparison->largestExpenseDescription)->toBe('Último dia anterior')
        ->and($output->previousComparison->largestExpenseOccurredOn)->toBe($priorLastDay)
        ->and($output->previousComparison->period->to())->toBe($priorLastDay)
        ->and($output->hasHistoricalExpenses)->toBeTrue()
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
})->with([
    'September after a 31-day month' => ['2026-09-01', '2026-09-30', '2026-08-31', '2026-10-01'],
    'leap February' => ['2024-02-01', '2024-02-29', '2024-01-31', '2024-03-01'],
    'common February' => ['2025-02-01', '2025-02-28', '2025-01-31', '2025-03-01'],
    'January across the year boundary' => ['2026-01-01', '2026-01-31', '2025-12-31', '2026-02-01'],
]);

it('reads newly registered backdated expenses by occurrence rather than registration date without writes', function (): void {
    $userId = createInsightUser();
    $repository = insightExpenseAnalysisRepository();
    $period = new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01'));
    insertInsightExpense($userId, '2026-10-01', 999999, 'health', 'Posterior ao mês selecionado');

    $initial = $repository->analyze($userId, $period);

    expect($initial->hasHistoricalExpenses)->toBeFalse()
        ->and($initial->currentMonth->expenseCount)->toBe(0)
        ->and($initial->currentMonth->largestExpenseDescription)->toBeNull()
        ->and($initial->currentMonth->largestExpenseOccurredOn)->toBeNull();

    insertInsightExpense($userId, '2026-09-01', 30000, 'housing', null);
    insertInsightExpense($userId, '2026-09-30', 20000, 'food', 'Mercado retroativo');
    $before = DB::table('expenses')->orderBy('id')->get()->all();

    expect($before[1]->created_at)->toBe('2026-10-12 12:00:00')
        ->and($before[2]->created_at)->toBe('2026-10-12 12:00:00');

    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $output = $repository->analyze($userId, $period);
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect($queries)->toHaveCount(1)
        ->and($queries[0]['query'])->toStartWith('WITH periods')
        ->and($output->hasHistoricalExpenses)->toBeTrue()
        ->and($output->currentMonth->expenseCount)->toBe(2)
        ->and($output->currentMonth->distinctDateCount)->toBe(2)
        ->and($output->currentMonth->totalAmount)->toBe('50000')
        ->and($output->currentMonth->largestExpenseAmount)->toBe('30000')
        ->and($output->currentMonth->largestExpenseCategory)->toBe('housing')
        ->and($output->currentMonth->largestExpenseDescription)->toBeNull()
        ->and($output->currentMonth->largestExpenseOccurredOn)->toBe('2026-09-01')
        ->and($output->currentComparison->totalAmount)->toBe('50000')
        ->and($output->currentComparison->largestExpenseOccurredOn)->toBe('2026-09-01')
        ->and($output->previousMonth->totalAmount)->toBe('0')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('0')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
});

it('does not borrow onboarding history from months after the historical selection', function (): void {
    $userId = createInsightUser();
    insertInsightExpense($userId, '2026-10-01', 10000);
    $output = insightExpenseAnalysisRepository()->analyze($userId, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01')));

    expect($output->hasHistoricalExpenses)->toBeFalse()
        ->and($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->previousMonth->totalAmount)->toBe('0')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('0');
});
