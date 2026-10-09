<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\CentsValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Ports\ExpenseAnalysisPort;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\GetInsightsUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;

function getInsightsAnalysisFixture(string $categoryAmount = '30000', string $category = 'food', string $to = '2026-10-12'): ExpenseAnalysisOutput
{
    $empty = static fn (string $from, string $to): ExpensePeriodAnalysisOutput => new ExpensePeriodAnalysisOutput(
        period: DatePeriodValueObject::fromDates($from, $to),
        expenseCount: 0, distinctDateCount: 0, totalAmount: '0',
        largestExpenseAmount: '0', largestExpenseCategory: null, categories: [],
    );

    return new ExpenseAnalysisOutput(
        hasHistoricalExpenses: true,
        currentMonth: new ExpensePeriodAnalysisOutput(
            expenseCount: 5,
            distinctDateCount: 3,
            largestExpenseAmount: '10000',
            largestExpenseCategory: $category,
            period: DatePeriodValueObject::fromDates('2026-10-01', $to),
            totalAmount: CentsValueObject::fromCents($categoryAmount)->plus(CentsValueObject::fromCents('20000'))->cents(),
            categories: [
                new ExpenseCategoryAnalysisOutput($category, $categoryAmount),
                new ExpenseCategoryAnalysisOutput('other', '20000'),
            ],
        ),
        twoMonthsAgo: $empty('2026-08-01', '2026-08-31'),
        previousMonth: $empty('2026-09-01', '2026-09-30'),
        currentComparison: null,
        previousComparison: null,
    );
}

function getInsightsFixtureUseCase(UserPort $userPort, ExpenseAnalysisPort $analysisPort): GetInsightsUseCase
{
    return new GetInsightsUseCase(
        userPort: $userPort,
        expenseAnalysisPort: $analysisPort,
        candidateGenerationUseCase: new GenerateInsightCandidatesUseCase,
        candidateSelectionUseCase: new SelectInsightCandidatesUseCase,
        messageCompositionUseCase: new ComposeInsightMessageUseCase(new GetInsightMessageTemplatesUseCase, new SelectInsightMessageVariantUseCase),
    );
}

it('obtains the owner from its port and returns composed typed insights', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->expects($this->once())->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $analysisPort->expects($this->once())->method('analyze')->with(42, '2026-10-12')->willReturn(getInsightsAnalysisFixture());

    $insights = getInsightsFixtureUseCase($userPort, $analysisPort)->execute('2026-10-12');

    expect($insights)->toHaveCount(1)
        ->and($insights[0]->id)->toMatch('/\A[0-9a-f]{64}\z/')
        ->and($insights[0]->type)->toBe(InsightTypeEnum::CategoryConcentration)
        ->and($insights[0]->group)->toBe(InsightGroupEnum::Observation)
        ->and(str_contains($insights[0]->description, '60%'))->toBeTrue()
        ->and($insights[0]->period->to())->toBe('2026-10-12')
        ->and($insights[0]->comparisonPeriod)->toBeNull();
});

it('keeps derived IDs and variants stable when only numbers change', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->with(42, '2026-10-12')
        ->willReturnOnConsecutiveCalls(getInsightsAnalysisFixture(), getInsightsAnalysisFixture('33000'));
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $first = $useCase->execute('2026-10-12')[0];
    $second = $useCase->execute('2026-10-12')[0];

    expect($first->id)->toBe($second->id)
        ->and($first->title)->toBe($second->title)
        ->and(str_contains($first->description, '60%'))->toBeTrue()
        ->and(str_contains($second->description, '62%'))->toBeTrue();
});

it('keeps the resource ID independent of the rotating message for the same analyzed periods', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->willReturn(getInsightsAnalysisFixture());
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $first = $useCase->execute('2026-10-12')[0];
    $second = $useCase->execute('2026-10-13')[0];

    expect($first->id)->toBe($second->id)
        ->and($first->title === $second->title)->toBeFalse()
        ->and($first->type)->toBe($second->type)
        ->and($first->group)->toBe($second->group);
});

it('distinguishes accounts subjects and analyzed periods in derived IDs', function (string $dimension): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturnOnConsecutiveCalls(42, $dimension === 'account' ? 43 : 42);
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $changed = match ($dimension) {
        'account' => getInsightsAnalysisFixture(),
        'subject' => getInsightsAnalysisFixture(category: 'health'),
        'period' => getInsightsAnalysisFixture(to: '2026-10-11'),
    };
    $analysisPort->method('analyze')->willReturnOnConsecutiveCalls(getInsightsAnalysisFixture(), $changed);
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);

    expect($useCase->execute('2026-10-12')[0]->id === $useCase->execute('2026-10-12')[0]->id)->toBeFalse();
})->with(['account', 'subject', 'period']);

it('does not read analytical data when the identity port fails', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willThrowException(new RuntimeException('Identity unavailable'));
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $analysisPort->expects($this->never())->method('analyze');

    getInsightsFixtureUseCase($userPort, $analysisPort)->execute('2026-10-12');
})->throws(RuntimeException::class, 'Identity unavailable');

it('propagates analytical failures instead of producing fabricated onboarding', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisPort::class);
    $analysisPort->method('analyze')->willThrowException(new RuntimeException('Analysis unavailable'));

    getInsightsFixtureUseCase($userPort, $analysisPort)->execute('2026-10-12');
})->throws(RuntimeException::class, 'Analysis unavailable');
