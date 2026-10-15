<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Ports\UserPort;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Domain\Exceptions\InvalidAmountException;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Data\GetInsightsInput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\GetInsightsUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

function getInsightsAnalysisFixture(
    string $categoryAmount = '30000', string $category = 'food', string $to = '2026-10-12',
    InsightPeriodModeEnum $mode = InsightPeriodModeEnum::Current,
): ExpenseAnalysisOutput {
    $empty = static fn (string $from, string $to): ExpensePeriodAnalysisOutput => new ExpensePeriodAnalysisOutput(
        period: DatePeriodValueObject::fromDates($from, $to),
        expenseCount: 0, distinctDateCount: 0, totalAmount: '0',
        largestExpenseAmount: '0', largestExpenseCategory: null, categories: [],
    );

    $selectedMonth = DatePeriodValueObject::monthContaining($to);
    $previousMonth = $selectedMonth->previousMonth();
    $twoMonthsAgo = $previousMonth->previousMonth();

    return new ExpenseAnalysisOutput(
        mode: $mode,
        currentComparison: null,
        previousComparison: null,
        hasHistoricalExpenses: true,
        twoMonthsAgo: $empty($twoMonthsAgo->from(), $twoMonthsAgo->to()),
        previousMonth: $empty($previousMonth->from(), $previousMonth->to()),
        currentMonth: new ExpensePeriodAnalysisOutput(
            expenseCount: 5,
            distinctDateCount: 3,
            largestExpenseAmount: '10000',
            largestExpenseCategory: $category,
            largestExpenseOccurredOn: $selectedMonth->from(),
            period: DatePeriodValueObject::fromDates($selectedMonth->from(), $to),
            totalAmount: AmountValueObject::fromAmount($categoryAmount)->plus(AmountValueObject::fromAmount('20000'))->amount(),
            categories: [
                new ExpenseCategoryAnalysisOutput($category, $categoryAmount),
                new ExpenseCategoryAnalysisOutput('other', '20000'),
            ],
        ),
    );
}

function getInsightsFixtureUseCase(UserPort $userPort, ExpenseAnalysisRepository $analysisPort, ?ResourceRepository $resourceRepository = null): GetInsightsUseCase
{
    if ($resourceRepository === null) {
        $ids = [];
        $resourceRepository = test()->createStub(ResourceRepository::class);
        $resourceRepository->method('resolve')->willReturnCallback(static function (string $owner, array $keys) use (&$ids): array {
            return array_map(static function (ResourceKeyInput $key) use ($owner, &$ids): ResourceKeyOutput {
                $index = serialize([$owner, $key]);
                $ids[$index] ??= UuidFixture::at(count($ids) + 100);

                return new ResourceKeyOutput($key, $ids[$index]);
            }, $keys);
        });
    }

    return new GetInsightsUseCase(
        port: $userPort,
        repository: $analysisPort,
        candidateSelectionUseCase: new SelectInsightCandidatesUseCase,
        candidateGenerationUseCase: new GenerateInsightCandidatesUseCase,
        resourceUseCase: new ResourceUseCase(new TransactionPortFake, $resourceRepository),
        messageCompositionUseCase: new ComposeInsightMessageUseCase(new GetInsightMessageTemplatesUseCase, new SelectInsightMessageVariantUseCase),
    );
}

it('obtains the owner from its port and returns composed typed insights', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->expects($this->once())->method('id')->willReturn(UuidFixture::at(42));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->once())->method('analyze')->with(UuidFixture::at(42), new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')))->willReturn(getInsightsAnalysisFixture());

    $insights = getInsightsFixtureUseCase($userPort, $analysisPort)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));

    expect($insights)->toHaveCount(1)
        ->and($insights[0]->id)->toBe(UuidFixture::at(100))
        ->and($insights[0]->type)->toBe(InsightTypeEnum::CategoryConcentration)
        ->and($insights[0]->group)->toBe(InsightGroupEnum::Observation)
        ->and(str_contains($insights[0]->description, '60%'))->toBeTrue()
        ->and($insights[0]->period->to())->toBe('2026-10-12')
        ->and($insights[0]->comparisonPeriod)->toBeNull();
});

it('keeps associated IDs and variants stable when only numbers change', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->with(UuidFixture::at(42), new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')))
        ->willReturnOnConsecutiveCalls(getInsightsAnalysisFixture(), getInsightsAnalysisFixture('33000'));
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12'));
    $first = $useCase->execute($input)[0];
    $second = $useCase->execute($input)[0];

    expect($first->id)->toBe($second->id)
        ->and($first->title)->toBe($second->title)
        ->and(str_contains($first->description, '60%'))->toBeTrue()
        ->and(str_contains($second->description, '62%'))->toBeTrue()
        ->and(str_replace('60%', '62%', $first->description))->toBe($second->description);
});

it('rotates historical messages by the visit day while reading the same complete selected periods on every visit', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->exactly(6))->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(6))->method('analyze')->with(UuidFixture::at(42), $this->callback(
        static fn (InsightAnalysisPeriodValueObject $period): bool => $period->mode === InsightPeriodModeEnum::Closed
            && $period->currentMonth->from() === '2026-09-01' && $period->currentMonth->to() === '2026-09-30'
            && $period->previousMonth->from() === '2026-08-01' && $period->previousMonth->to() === '2026-08-31'
            && $period->twoMonthsAgo->from() === '2026-07-01' && $period->twoMonthsAgo->to() === '2026-07-31',
    ))->willReturn(getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed));
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $selected = DatePeriodValueObject::fromDates('2026-09-01', '2026-09-30');
    $input = new GetInsightsInput('2026-10-12', $selected);
    $first = $useCase->execute($input);

    expect($useCase->execute($input))->toEqual($first);
    $pairs = [$first[0]->title.'|'.$first[0]->description];

    foreach (['2026-10-13', '2026-10-14', '2026-10-15', '2026-10-16'] as $date) {
        $insights = $useCase->execute(new GetInsightsInput($date, $selected));
        expect($insights)->toHaveCount(1)
            ->and($insights[0]->type)->toBe(InsightTypeEnum::CategoryConcentration)
            ->and($insights[0]->group)->toBe(InsightGroupEnum::Observation)
            ->and($insights[0]->period)->toEqual($selected)
            ->and($insights[0]->id)->toBe($first[0]->id)
            ->and($insights[0]->description)->toContain('60%', 'set/2026');
        $pairs[] = $insights[0]->title.'|'.$insights[0]->description;
    }

    expect(array_unique(array_slice($pairs, 0, 4)))->toHaveCount(4)
        ->and($pairs[4])->toBe($pairs[0]);
});

it('recalculates historical values in the same visit day without changing the daily variant', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->expects($this->exactly(2))->method('id')->willReturn(UuidFixture::at(42));
    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::fromDates('2026-09-01', '2026-09-30'));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(2))->method('analyze')->with(UuidFixture::at(42), new InsightAnalysisPeriodValueObject($input->queryDate, $input->selectedMonth))
        ->willReturnOnConsecutiveCalls(
            getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed),
            getInsightsAnalysisFixture(categoryAmount: '33000', to: '2026-09-30', mode: InsightPeriodModeEnum::Closed),
        );
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $first = $useCase->execute($input)[0];
    $updated = $useCase->execute($input)[0];

    expect($first->description)->toContain('60%', 'set/2026')
        ->and($updated->description)->toContain('62%', 'set/2026')
        ->and($updated->title)->toBe($first->title)
        ->and($updated->id)->toBe($first->id)
        ->and($updated->description)->toBe(str_replace('60%', '62%', $first->description));
});

it('keeps the resource ID independent of the rotating message for the same analyzed periods', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->exactly(2))->method('analyze')->willReturn(getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed));
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);
    $selected = DatePeriodValueObject::monthContaining('2026-09-01');
    $first = $useCase->execute(new GetInsightsInput('2026-10-12', $selected))[0];
    $second = $useCase->execute(new GetInsightsInput('2026-10-13', $selected))[0];

    expect($first->id)->toBe($second->id)
        ->and([$first->title, $first->description])->not->toBe([$second->title, $second->description])
        ->and($first->type)->toBe($second->type)
        ->and($first->group)->toBe($second->group);
});

it('distinguishes accounts subjects and analyzed periods in associated IDs', function (string $dimension): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturnOnConsecutiveCalls(UuidFixture::at(42), UuidFixture::at($dimension === 'account' ? 43 : 42));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $changed = match ($dimension) {
        'account' => getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed),
        'subject' => getInsightsAnalysisFixture(category: 'health', to: '2026-09-30', mode: InsightPeriodModeEnum::Closed),
        'period' => getInsightsAnalysisFixture(to: '2026-08-31', mode: InsightPeriodModeEnum::Closed),
    };
    $analysisPort->expects($this->exactly(2))->method('analyze')->willReturnOnConsecutiveCalls(
        getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed), $changed,
    );
    $useCase = getInsightsFixtureUseCase($userPort, $analysisPort);

    $first = $useCase->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01')))[0];
    $second = $useCase->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining($dimension === 'period' ? '2026-08-01' : '2026-09-01')))[0];
    expect($first->type)->toBe(InsightTypeEnum::CategoryConcentration)
        ->and($second->type)->toBe($first->type)
        ->and($second->id)->not->toBe($first->id);
})->with(['account', 'subject', 'period']);

it('distinguishes effective current cutoffs independently of the day used for editorial rotation', function (): void {
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(2))->method('analyze')->willReturnOnConsecutiveCalls(
        getInsightsAnalysisFixture(to: '2026-10-12'), getInsightsAnalysisFixture(to: '2026-10-13'),
    );
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $selected = DatePeriodValueObject::monthContaining('2026-10-01');
    $first = $useCase->execute(new GetInsightsInput('2026-10-12', $selected))[0];
    $second = $useCase->execute(new GetInsightsInput('2026-10-13', $selected))[0];

    expect($first->period->to())->toBe('2026-10-12')
        ->and($second->period->to())->toBe('2026-10-13')
        ->and($second->type)->toBe($first->type)
        ->and($second->id)->not->toBe($first->id);
});

it('distinguishes comparison types with the same owner subject and complete analyzed periods', function (): void {
    $base = getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed);
    $analyses = [];
    foreach ([['40000', '8000'], ['70000', '14000']] as [$total, $largest]) {
        $previous = new ExpensePeriodAnalysisOutput(
            period: DatePeriodValueObject::fromDates('2026-08-01', '2026-08-31'),
            expenseCount: 5, distinctDateCount: 3, totalAmount: $total,
            largestExpenseAmount: $largest, largestExpenseCategory: 'food', largestExpenseOccurredOn: '2026-08-01',
            categories: [new ExpenseCategoryAnalysisOutput('food', $total)],
        );
        $analyses[] = new ExpenseAnalysisOutput(
            mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: true,
            currentMonth: $base->currentMonth, previousMonth: $previous, twoMonthsAgo: $base->twoMonthsAgo,
            currentComparison: $base->currentMonth, previousComparison: $previous,
        );
    }
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(2))->method('analyze')->willReturnOnConsecutiveCalls(...$analyses);
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01'));
    $increase = $useCase->execute($input)[0];
    $decrease = $useCase->execute($input)[0];

    expect($increase->type)->toBe(InsightTypeEnum::RegisteredAmountIncrease)
        ->and($decrease->type)->toBe(InsightTypeEnum::RegisteredAmountDecrease)
        ->and($decrease->period)->toEqual($increase->period)
        ->and($decrease->comparisonPeriod)->toEqual($increase->comparisonPeriod)
        ->and($decrease->id)->not->toBe($increase->id);
});

it('includes the internal selected month in onboarding IDs despite their null public periods', function (bool $review): void {
    $analyses = [];
    foreach (['2026-08-31', '2026-09-30'] as $to) {
        $base = getInsightsAnalysisFixture(to: $to, mode: InsightPeriodModeEnum::Closed);
        $current = new ExpensePeriodAnalysisOutput(
            period: $base->currentMonth->period, expenseCount: $review ? 5 : 0, distinctDateCount: $review ? 3 : 0,
            totalAmount: $review ? '10000' : '0', largestExpenseAmount: $review ? '2000' : '0',
            largestExpenseCategory: $review ? 'other' : null,
            largestExpenseOccurredOn: $review ? $base->currentMonth->period->from() : null,
            categories: $review ? [new ExpenseCategoryAnalysisOutput('other', '10000')] : [],
        );
        $analyses[] = new ExpenseAnalysisOutput(
            mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: $review,
            currentMonth: $current, previousMonth: $base->previousMonth, twoMonthsAgo: $base->twoMonthsAgo,
            currentComparison: null, previousComparison: null,
        );
    }
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(2))->method('analyze')->willReturnOnConsecutiveCalls(...$analyses);
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $august = $useCase->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-08-01')));
    $september = $useCase->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01')));

    expect($august)->toHaveCount($review ? 2 : 1)
        ->and($september)->toHaveCount($review ? 2 : 1);
    foreach ($august as $index => $insight) {
        expect($insight->group)->toBe(InsightGroupEnum::Onboarding)
            ->and($insight->period)->toBeNull()
            ->and($september[$index]->period)->toBeNull()
            ->and($september[$index]->type)->toBe($insight->type)
            ->and($september[$index]->id)->not->toBe($insight->id);
    }
})->with(['empty historical guidance' => false, 'review and guidance' => true]);

it('keeps expense and review IDs independent of expense description and interpolated amount', function (): void {
    $base = getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed);
    $analyses = [];
    foreach ([['5000', 'Aluguel'], ['5500', 'Mensalidade']] as [$largest, $description]) {
        $current = new ExpensePeriodAnalysisOutput(
            period: $base->currentMonth->period, expenseCount: 5, distinctDateCount: 3, totalAmount: '10000',
            largestExpenseAmount: $largest, largestExpenseCategory: 'other', largestExpenseOccurredOn: '2026-09-01',
            largestExpenseDescription: $description,
            categories: [new ExpenseCategoryAnalysisOutput('other', '6000'), new ExpenseCategoryAnalysisOutput('food', '4000')],
        );
        $analyses[] = new ExpenseAnalysisOutput(
            mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: true,
            currentMonth: $current, previousMonth: $base->previousMonth, twoMonthsAgo: $base->twoMonthsAgo,
            currentComparison: null, previousComparison: null,
        );
    }
    $port = $this->createMock(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->exactly(2))->method('analyze')->willReturnOnConsecutiveCalls(...$analyses);
    $useCase = getInsightsFixtureUseCase($port, $repository);
    $input = new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01'));
    $first = $useCase->execute($input);
    $updated = $useCase->execute($input);

    expect($first)->toHaveCount(2)
        ->and($updated)->toHaveCount(2)
        ->and($first[0]->type)->toBe(InsightTypeEnum::ExpenseConcentration)
        ->and($first[1]->type)->toBe(InsightTypeEnum::CategoryReview)
        ->and($first[0]->description)->toContain('Aluguel', '50%')
        ->and($updated[0]->description)->toContain('Mensalidade', '55%')
        ->and($updated[0]->id)->toBe($first[0]->id)
        ->and($updated[1]->id)->toBe($first[1]->id)
        ->and($first[1]->period)->toBeNull()
        ->and($first[0]->id)->not->toBe($first[1]->id);
});

it('does not read analytical data when the identity port fails', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willThrowException(new RuntimeException('Identity unavailable'));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->expects($this->never())->method('analyze');

    getInsightsFixtureUseCase($userPort, $analysisPort)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
})->throws(RuntimeException::class, 'Identity unavailable');

it('propagates analytical failures instead of producing fabricated onboarding', function (): void {
    $userPort = $this->createMock(UserPort::class);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $analysisPort = $this->createMock(ExpenseAnalysisRepository::class);
    $analysisPort->method('analyze')->willThrowException(new RuntimeException('Analysis unavailable'));
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');

    getInsightsFixtureUseCase($userPort, $analysisPort, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')));
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

it('resolves exactly the canonical final keys once without editorial financial or catalog components', function (): void {
    $port = $this->createStub(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->once())->method('analyze')->willReturn(getInsightsAnalysisFixture());
    $key = new ResourceKeyInput(namespace: 'insights', identityVersion: 1, components: [
        'type' => 'category_concentration', 'subject' => 'food', 'history_state' => null,
        'analysis_from' => '2026-10-01', 'analysis_to' => '2026-10-12',
        'comparison_from' => null, 'comparison_to' => null,
    ]);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->with(UuidFixture::at(42), [$key])
        ->willReturn([new ResourceKeyOutput($key, UuidFixture::at(900))]);

    $output = getInsightsFixtureUseCase($port, $repository, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-01')));
    expect($output)->toHaveCount(1)->and($output[0]->id)->toBe(UuidFixture::at(900));
});

it('does not allocate associations when projection validation or editorial composition fails', function (string $category): void {
    $port = $this->createStub(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createStub(ExpenseAnalysisRepository::class);
    $base = getInsightsAnalysisFixture(category: $category);
    $current = $base->currentMonth;
    $repository->method('analyze')->willReturn(new ExpenseAnalysisOutput(
        mode: $base->mode, hasHistoricalExpenses: true,
        previousMonth: $base->previousMonth, twoMonthsAgo: $base->twoMonthsAgo,
        currentComparison: null, previousComparison: null,
        currentMonth: new ExpensePeriodAnalysisOutput(
            period: $current->period, expenseCount: $current->expenseCount, distinctDateCount: $current->distinctDateCount,
            totalAmount: $category === 'food' ? 'invalid' : $current->totalAmount,
            largestExpenseAmount: $current->largestExpenseAmount, largestExpenseCategory: $category,
            largestExpenseOccurredOn: $current->largestExpenseOccurredOn, categories: $current->categories,
        ),
    ));
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');

    expect(fn () => getInsightsFixtureUseCase($port, $repository, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-01'))))
        ->toThrow($category === 'food' ? InvalidAmountException::class : InsightMessageCompositionException::class);
})->with(['invalid precision' => 'food', 'invalid editorial category' => 'unmapped']);

it('propagates Core failure instead of returning a transient or partial resource', function (): void {
    $port = $this->createStub(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createStub(ExpenseAnalysisRepository::class);
    $repository->method('analyze')->willReturn(getInsightsAnalysisFixture());
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->willThrowException(new RuntimeException('Registry sentinel'));

    expect(fn () => getInsightsFixtureUseCase($port, $repository, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-01'))))
        ->toThrow(ResourcePersistenceException::class, 'Resource identities could not be resolved.');
});

it('resolves comparison and observation together preserving final order and explicit comparison bounds', function (): void {
    $base = getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed);
    $previous = new ExpensePeriodAnalysisOutput(
        period: DatePeriodValueObject::fromDates('2026-08-01', '2026-08-31'),
        expenseCount: 5, distinctDateCount: 3, totalAmount: '40000',
        largestExpenseAmount: '8000', largestExpenseCategory: 'food', largestExpenseOccurredOn: '2026-08-01',
        categories: [new ExpenseCategoryAnalysisOutput('food', '40000')],
    );
    $analysis = new ExpenseAnalysisOutput(
        mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: true,
        currentMonth: $base->currentMonth, previousMonth: $previous, twoMonthsAgo: $base->twoMonthsAgo,
        currentComparison: $base->currentMonth, previousComparison: $previous,
    );
    $port = $this->createStub(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createStub(ExpenseAnalysisRepository::class);
    $repository->method('analyze')->willReturn($analysis);
    $comparison = new ResourceKeyInput(namespace: 'insights', identityVersion: 1, components: [
        'type' => 'registered_amount_increase', 'subject' => null, 'history_state' => null,
        'analysis_from' => '2026-09-01', 'analysis_to' => '2026-09-30',
        'comparison_from' => '2026-08-01', 'comparison_to' => '2026-08-31',
    ]);
    $observation = new ResourceKeyInput(namespace: 'insights', identityVersion: 1, components: [
        'type' => 'category_concentration', 'subject' => 'food', 'history_state' => null,
        'analysis_from' => '2026-09-01', 'analysis_to' => '2026-09-30',
        'comparison_from' => null, 'comparison_to' => null,
    ]);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->with(UuidFixture::at(42), [$comparison, $observation])
        ->willReturn([new ResourceKeyOutput($observation, UuidFixture::at(901)), new ResourceKeyOutput($comparison, UuidFixture::at(900))]);
    $outputs = getInsightsFixtureUseCase($port, $repository, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01')));
    expect(array_column($outputs, 'id'))->toBe([UuidFixture::at(900), UuidFixture::at(901)]);
});

it('passes internal onboarding periods and contextual state to Core despite null public periods', function (bool $hasExpenses): void {
    $base = getInsightsAnalysisFixture(to: '2026-09-30', mode: InsightPeriodModeEnum::Closed);
    $analysis = new ExpenseAnalysisOutput(
        mode: InsightPeriodModeEnum::Closed, hasHistoricalExpenses: $hasExpenses,
        previousMonth: $base->previousMonth, twoMonthsAgo: $base->twoMonthsAgo,
        currentComparison: null, previousComparison: null,
        currentMonth: new ExpensePeriodAnalysisOutput(
            period: $base->currentMonth->period, expenseCount: $hasExpenses ? 1 : 0, distinctDateCount: $hasExpenses ? 1 : 0,
            totalAmount: $hasExpenses ? '1000' : '0', largestExpenseAmount: $hasExpenses ? '1000' : '0',
            largestExpenseCategory: $hasExpenses ? 'food' : null,
            largestExpenseOccurredOn: $hasExpenses ? '2026-09-01' : null,
            categories: $hasExpenses ? [new ExpenseCategoryAnalysisOutput('food', '1000')] : [],
        ),
    );
    $port = $this->createStub(UserPort::class);
    $port->method('id')->willReturn(UuidFixture::at(42));
    $repository = $this->createStub(ExpenseAnalysisRepository::class);
    $repository->method('analyze')->willReturn($analysis);
    $key = new ResourceKeyInput(namespace: 'insights', identityVersion: 1, components: [
        'type' => 'insufficient_history', 'subject' => null,
        'history_state' => $hasExpenses ? 'current_expenses' : 'no_current_expenses',
        'analysis_from' => '2026-09-01', 'analysis_to' => '2026-09-30',
        'comparison_from' => null, 'comparison_to' => null,
    ]);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->with(UuidFixture::at(42), [$key])
        ->willReturn([new ResourceKeyOutput($key, UuidFixture::at(900))]);
    $outputs = getInsightsFixtureUseCase($port, $repository, $resources)->execute(new GetInsightsInput('2026-10-12', DatePeriodValueObject::monthContaining('2026-09-01')));
    expect($outputs)->toHaveCount(1)->and($outputs[0]->period)->toBeNull()->and($outputs[0]->id)->toBe(UuidFixture::at(900));
})->with(['no records in selected month' => false, 'some records in selected month' => true]);
