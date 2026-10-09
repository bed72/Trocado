<?php

declare(strict_types=1);

use App\Insights\Application\Ports\ExpenseAnalysisPort;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use App\Insights\Infrastructure\Adapters\ExpenseAnalysisAdapter;
use Illuminate\Support\Facades\DB;

function createInsightUser(): int
{
    return DB::table('users')->insertGetId([
        'name' => 'Maria', 'email' => 'insights@example.com', 'password' => 'unused',
    ]);
}

function insightExpenseAnalysisPort(): ExpenseAnalysisPort
{
    return app(ExpenseAnalysisPort::class);
}

function insertInsightExpense(int $userId, string $date, int $amount, string $category = 'other'): int
{
    return DB::table('expenses')->insertGetId([
        'updated_at' => '2026-10-12 12:00:00',
        'category' => $category, 'created_at' => '2026-10-12 12:00:00',
        'user_id' => $userId, 'occurred_on' => $date, 'amount' => $amount,
    ]);
}

it('aggregates only the owner occurrence periods in one read without writes', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisPort();
    $otherUserId = DB::table('users')->insertGetId([
        'name' => 'Pedro', 'email' => 'other-insights@example.com', 'password' => 'unused',
    ]);
    insertInsightExpense($userId, '2026-10-01', 20000, 'food');
    insertInsightExpense($userId, '2026-10-02', 30000, 'other');
    insertInsightExpense($userId, '2026-10-12', 10000, 'food');
    insertInsightExpense($userId, '2026-10-13', 99999);
    insertInsightExpense($userId, '2026-09-11', 15000, 'food');
    insertInsightExpense($userId, '2026-09-12', 25000, 'other');
    insertInsightExpense($userId, '2026-08-31', 5000);
    insertInsightExpense($otherUserId, '2026-10-01', 999999, 'health');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    $output = $port->analyze($userId, '2026-10-12');
    $queries = DB::getQueryLog();
    DB::disableQueryLog();

    expect($port)->toBeInstanceOf(ExpenseAnalysisAdapter::class)
        ->and($queries)->toHaveCount(1)
        ->and($queries[0]['query'])->toStartWith('WITH periods')
        ->and($output->hasHistoricalExpenses)->toBeTrue()
        ->and($output->currentMonth->totalAmount)->toBe('60000')
        ->and($output->currentMonth->expenseCount)->toBe(3)
        ->and($output->currentMonth->distinctDateCount)->toBe(3)
        ->and($output->currentMonth->largestExpenseAmount)->toBe('30000')
        ->and($output->currentMonth->largestExpenseCategory)->toBe('other')
        ->and($output->currentMonth->categories)->toHaveCount(2)
        ->and($output->currentMonth->categories[0]->totalAmount)->toBe('30000')
        ->and($output->currentMonth->categories[1]->category)->toBe('other')
        ->and($output->currentMonth->categories[1]->totalAmount)->toBe('30000')
        ->and($output->currentComparison->period->to())->toBe('2026-10-11')
        ->and($output->currentComparison->totalAmount)->toBe('50000')
        ->and($output->previousComparison->period->to())->toBe('2026-09-11')
        ->and($output->previousComparison->totalAmount)->toBe('15000')
        ->and($output->previousMonth->totalAmount)->toBe('40000')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('5000')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
});

it('caps equivalent windows by the shorter previous month', function (string $reference, string $currentEnd, string $previousEnd, int $days): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisPort();
    $output = $port->analyze($userId, $reference);

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
    $port = insightExpenseAnalysisPort();
    insertInsightExpense($userId, '2026-10-02', 10000);
    $output = $port->analyze($userId, '2026-10-01');

    expect($output->hasHistoricalExpenses)->toBeFalse()
        ->and($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->currentMonth->expenseCount)->toBe(0)
        ->and($output->currentMonth->distinctDateCount)->toBe(0)
        ->and($output->currentMonth->largestExpenseAmount)->toBe('0')
        ->and($output->currentMonth->largestExpenseCategory)->toBeNull()
        ->and($output->currentMonth->categories)->toBe([])
        ->and($output->currentComparison)->toBeNull()
        ->and($output->previousComparison)->toBeNull();

    insertInsightExpense($userId, '2020-01-01', 10000);
    $output = $port->analyze($userId, '2026-10-01');

    expect($output->hasHistoricalExpenses)->toBeTrue()
        ->and($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->twoMonthsAgo->totalAmount)->toBe('0');
});

it('preserves totals above machine integer limits and breaks largest expense ties deterministically', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisPort();
    insertInsightExpense($userId, '2026-10-01', PHP_INT_MAX, 'other');
    insertInsightExpense($userId, '2026-10-01', PHP_INT_MAX, 'food');
    insertInsightExpense($userId, '2026-10-02', PHP_INT_MAX, 'food');
    $output = $port->analyze($userId, '2026-10-12');

    expect($output->currentMonth->totalAmount)->toBe('27670116110564327421')
        ->and($output->currentMonth->distinctDateCount)->toBe(2)
        ->and($output->currentMonth->categories[0]->totalAmount)->toBe('18446744073709551614')
        ->and($output->currentMonth->largestExpenseAmount)->toBe((string) PHP_INT_MAX)
        ->and($output->currentMonth->largestExpenseCategory)->toBe('food');
});

it('reads confirmed edits recategorizations and deletions without cached facts', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisPort();
    $id = insertInsightExpense($userId, '2026-10-01', 10000);
    expect($port->analyze($userId, '2026-10-12')->currentMonth->categories[0]->category)->toBe('other');

    DB::table('expenses')->where('id', $id)->update(['amount' => 20000, 'category' => 'food']);
    $output = $port->analyze($userId, '2026-10-12');
    expect($output->currentMonth->totalAmount)->toBe('20000')
        ->and($output->currentMonth->categories[0]->category)->toBe('food');

    DB::table('expenses')->where('id', $id)->update(['occurred_on' => '2026-09-01']);
    $output = $port->analyze($userId, '2026-10-12');
    expect($output->currentMonth->totalAmount)->toBe('0')
        ->and($output->previousMonth->totalAmount)->toBe('20000');

    DB::table('expenses')->where('id', $id)->delete();
    expect($port->analyze($userId, '2026-10-12')->hasHistoricalExpenses)->toBeFalse();
});

it('generates candidates from the real analytical projection', function (): void {
    $userId = createInsightUser();
    $port = insightExpenseAnalysisPort();
    foreach (['2026-08', '2026-09', '2026-10'] as $month) {
        foreach (['01', '02', '03', '04', '05'] as $day) {
            insertInsightExpense($userId, "{$month}-{$day}", 2000, 'food');
        }
    }

    $analysis = $port->analyze($userId, '2026-10-12');
    $candidates = app(GenerateInsightCandidatesUseCase::class)->execute($analysis);
    $types = array_map(static fn (InsightCandidateValueObject $candidate): InsightTypeEnum => $candidate->type, $candidates);

    expect($types)->toBe([InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak])
        ->and($candidates[0]->ratio->roundedPercent())->toBe('100')
        ->and($candidates[1]->analysisPeriod->from())->toBe('2026-08-01');

    $selected = app(SelectInsightCandidatesUseCase::class)->execute($candidates);

    expect($selected)->toBe([$candidates[1]])
        ->and($selected[0]->type)->toBe(InsightTypeEnum::CategoryLeadStreak);
});
