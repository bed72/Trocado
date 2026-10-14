<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Data\GetInsightsInput;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\GetInsightsUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;

function getInsightsAnalysisFixture(string $categoryAmount = '30000', string $category = 'food', string $to = '2026-10-12'): ExpenseAnalysisOutput
{
    $empty = static fn (string $from, string $to): ExpensePeriodAnalysisOutput => new ExpensePeriodAnalysisOutput(
        period: DatePeriodValueObject::fromDates($from, $to),
        expenseCount: 0, distinctDateCount: 0, totalAmount: '0',
        largestExpenseAmount: '0', largestExpenseCategory: null, categories: [],
    );

    return new ExpenseAnalysisOutput(
        currentComparison: null,
        previousComparison: null,
        hasHistoricalExpenses: true,
        twoMonthsAgo: $empty('2026-08-01', '2026-08-31'),
        previousMonth: $empty('2026-09-01', '2026-09-30'),
        currentMonth: new ExpensePeriodAnalysisOutput(
            expenseCount: 5,
            distinctDateCount: 3,
            largestExpenseAmount: '10000',
            largestExpenseCategory: $category,
            largestExpenseOccurredOn: '2026-10-01',
            period: DatePeriodValueObject::fromDates('2026-10-01', $to),
            totalAmount: AmountValueObject::fromAmount($categoryAmount)->plus(AmountValueObject::fromAmount('20000'))->amount(),
            categories: [
                new ExpenseCategoryAnalysisOutput($category, $categoryAmount),
                new ExpenseCategoryAnalysisOutput('other', '20000'),
            ],
        ),
    );
}

function getInsightsFixtureUseCase(UserPort $userPort, ExpenseAnalysisRepository $analysisPort): GetInsightsUseCase
{
    return new GetInsightsUseCase(
        port: $userPort,
        repository: $analysisPort,
        candidateSelectionUseCase: new SelectInsightCandidatesUseCase,
        candidateGenerationUseCase: new GenerateInsightCandidatesUseCase,
        messageCompositionUseCase: new ComposeInsightMessageUseCase(new GetInsightMessageTemplatesUseCase, new SelectInsightMessageVariantUseCase),
    );
}

it('obtains the owner from its port and returns composed typed insights', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->expects($this->once())->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->once())->method('analyze')->with(42, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')))->willReturn(getInsightsAnalysisFixture());

    $insights = getInsightsFixtureUseCase($userPort, $analysisPort)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));

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
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->with(42, new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')))
        ->willReturnOnConsecutiveCalls(getInsightsAnalysisFixture(), getInsightsAnalysisFixture('33000'));
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12'));
    $first = $useCase->execute($input)[0];
    $second = $useCase->execute($input)[0];

    expect($first->id)->toBe($second->id)
        ->and($first->title)->toBe($second->title)
        ->and(str_contains($first->description, '60%'))->toBeTrue()
        ->and(str_contains($second->description, '62%'))->toBeTrue();
});

it('keeps the resource ID independent of the rotating message for the same analyzed periods', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->willReturn(getInsightsAnalysisFixture());
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $first = $useCase->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')))[0];
    $second = $useCase->execute(new GetInsightsInput('2026-10-13', DatePeriodValueObject::monthContaining('2026-10-13')))[0];

    expect($first->id)->toBe($second->id)
        ->and([$first->title, $first->description])->not->toBe([$second->title, $second->description])
        ->and($first->type)->toBe($second->type)
        ->and($first->group)->toBe($second->group);
});

it('distinguishes accounts subjects and analyzed periods in derived IDs', function (string $dimension): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturnOnConsecutiveCalls(42, $dimension === 'account' ? 43 : 42);
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $changed = match ($dimension) {
        'account' => getInsightsAnalysisFixture(),
        'subject' => getInsightsAnalysisFixture(category: 'health'),
        'period' => getInsightsAnalysisFixture(to: '2026-10-11'),
    };
    $analysisPort->method('analyze')->willReturnOnConsecutiveCalls(getInsightsAnalysisFixture(), $changed);
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);

    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12'));
    expect($useCase->execute($input)[0]->id === $useCase->execute($input)[0]->id)->toBeFalse();
})->with(['account', 'subject', 'period']);

it('does not read analytical data when the identity port fails', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willThrowException(new RuntimeException('Identity unavailable'));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->never())->method('analyze');

    getInsightsFixtureUseCase($userPort, $analysisPort)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
})->throws(RuntimeException::class, 'Identity unavailable');

it('propagates analytical failures instead of producing fabricated onboarding', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(42);
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->method('analyze')->willThrowException(new RuntimeException('Analysis unavailable'));

    getInsightsFixtureUseCase($userPort, $analysisPort)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
})->throws(RuntimeException::class, 'Analysis unavailable');

it('rejects invalid non HTTP selections before resolving the owner or reading expenses', function (string $from, string $to): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->never())->method('id');
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->never())->method('analyze');

    getInsightsFixtureUseCase($port, $repository)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::fromDates($from, $to)));
})->with([
    ['2026-11-01', '2026-11-30'], ['2026-09-01', '2026-09-29'], ['0001-02-01', '0001-02-28'],
])->throws(InvalidInsightAnalysisException::class);
