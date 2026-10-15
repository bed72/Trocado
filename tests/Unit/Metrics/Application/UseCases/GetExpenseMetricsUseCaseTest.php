<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Ports\UserPort;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Domain\Exceptions\InvalidAmountException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Application\Data\ExpenseCategoryTotalOutput;
use App\Metrics\Application\Data\ExpenseMetricsProjectionOutput;
use App\Metrics\Application\Data\GetExpenseMetricsInput;
use App\Metrics\Application\Exceptions\InvalidExpenseMetricsProjectionException;
use App\Metrics\Application\Repositories\ExpenseMetricsRepository;
use App\Metrics\Application\UseCases\GetExpenseMetricsUseCase;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;
use PHPUnit\Framework\MockObject\MockObject;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

function expenseMetricsInputFixture(
    ExpenseMetricsGroupingEnum $grouping = ExpenseMetricsGroupingEnum::Total,
    string $from = '2026-10-01',
    string $to = '2026-10-31',
): GetExpenseMetricsInput {
    return new GetExpenseMetricsInput(period: DatePeriodValueObject::fromDates($from, $to), grouping: $grouping);
}

/** @param array<string, string> $totals */
function expenseMetricsProjectionFixture(string $total, array $totals = []): ExpenseMetricsProjectionOutput
{
    $categories = [];

    foreach ($totals as $category => $amount) {
        $categories[] = new ExpenseCategoryTotalOutput(category: $category, totalAmount: $amount);
    }

    return new ExpenseMetricsProjectionOutput(totalAmount: $total, categories: $categories);
}

/** @return array{UserPort&MockObject, ExpenseMetricsRepository&MockObject, GetExpenseMetricsUseCase} */
function expenseMetricsUseCaseFixture(UserPort&MockObject $userPort, ExpenseMetricsRepository&MockObject $metricsPort, ?ResourceRepository $resources = null): array
{
    if ($resources === null) {
        $ids = [];
        $resources = test()->createStub(ResourceRepository::class);
        $resources->method('resolve')->willReturnCallback(static function (string $owner, array $keys) use (&$ids): array {
            $key = $keys[0];
            $index = serialize([$owner, $key]);
            $ids[$index] ??= UuidFixture::at(count($ids) + 100);

            return [new ResourceKeyOutput($key, $ids[$index])];
        });
    }

    return [$userPort, $metricsPort, new GetExpenseMetricsUseCase(
        port: $userPort,
        useCase: new ResourceUseCase(new TransactionPortFake, $resources),
        repository: $metricsPort,
    )];
}

it('reads the authenticated owner once and forwards the exact effective period and grouping', function (ExpenseMetricsGroupingEnum $grouping): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $input = expenseMetricsInputFixture($grouping);
    $userPort->expects($this->once())->method('id')->willReturn(UuidFixture::at(42));
    $userPort->expects($this->never())->method('status');
    $projection = expenseMetricsProjectionFixture('123456', $grouping === ExpenseMetricsGroupingEnum::Category ? ['other' => '123456'] : []);
    $metricsPort->expects($this->once())->method('summarize')
        ->with(UuidFixture::at(42), $this->identicalTo($input->period), $grouping)->willReturn($projection);

    $output = $useCase->execute($input);

    expect($output->id)->toBe(UuidFixture::at(100))
        ->and($output->period)->toBe($input->period)
        ->and($output->totalAmount)->toBe('123456');

    if ($grouping === ExpenseMetricsGroupingEnum::Total) {
        expect($output->categories)->toBeNull();
    } else {
        expect($output->categories)->toHaveCount(1)
            ->and($output->categories[0]->category)->toBe('other')
            ->and($output->categories[0]->percentage)->toBe('100.00');
    }
})->with(ExpenseMetricsGroupingEnum::cases());

it('distinguishes absent grouping from an explicitly grouped empty result without dividing by zero', function (): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->expects($this->exactly(2))->method('summarize')->willReturn(expenseMetricsProjectionFixture('0'));

    $total = $useCase->execute(expenseMetricsInputFixture());
    $grouped = $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category));

    expect($total->totalAmount)->toBe('0')
        ->and($total->categories)->toBeNull()
        ->and($grouped->totalAmount)->toBe('0')
        ->and($grouped->categories)->toBe([])
        ->and($grouped->period->from())->toBe('2026-10-01')
        ->and($grouped->period->to())->toBe('2026-10-31')
        ->and($total->id)->not->toBe($grouped->id);
});

it('reconciles large totals and orders numerically with alphabetical tie breaking', function (): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->method('summarize')->willReturn(expenseMetricsProjectionFixture('12000000000000010900', [
        'transport' => '4000000000000000000',
        'health' => '900',
        'other' => '4000000000000000000',
        'housing' => '10000',
        'food' => '4000000000000000000',
    ]));

    $output = $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category));

    expect($output->totalAmount)->toBe('12000000000000010900')
        ->and(array_column($output->categories, 'category'))->toBe(['food', 'other', 'transport', 'housing', 'health'])
        ->and(array_column($output->categories, 'totalAmount'))->toBe([
            '4000000000000000000', '4000000000000000000', '4000000000000000000', '10000', '900',
        ])
        ->and(array_column($output->categories, 'percentage'))->toBe(['33.33', '33.33', '33.33', '0.00', '0.00']);
});

it('calculates percentages from the same exact total with independent final rounding', function (string $total, array $totals, array $percentages): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->expects($this->once())->method('summarize')->willReturn(expenseMetricsProjectionFixture($total, $totals));

    $output = $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category));

    expect(array_column($output->categories, 'percentage', 'category'))->toBe($percentages);
})->with([
    'simple distribution' => ['100000', ['other' => '10000', 'food' => '60000', 'transport' => '30000'], ['food' => '60.00', 'transport' => '30.00', 'other' => '10.00']],
    'investments and financing' => ['100000', ['food' => '10000', 'financing' => '30000', 'investments' => '60000'], ['investments' => '60.00', 'financing' => '30.00', 'food' => '10.00']],
    'new category ties' => ['30000', ['travel' => '10000', 'investments' => '10000', 'financing' => '10000'], ['financing' => '33.33', 'investments' => '33.33', 'travel' => '33.33']],
    '99.99 percent' => ['3', ['food' => '1', 'health' => '1', 'other' => '1'], ['food' => '33.33', 'health' => '33.33', 'other' => '33.33']],
    '100.01 percent' => ['100000', ['food' => '16665', 'health' => '16665', 'housing' => '16670', 'other' => '50000'], ['other' => '50.00', 'housing' => '16.67', 'food' => '16.67', 'health' => '16.67']],
    'minimum positive share' => ['1000000', ['food' => '1', 'other' => '999999'], ['other' => '100.00', 'food' => '0.00']],
    'minimum amount' => ['1', ['other' => '1'], ['other' => '100.00']],
]);

it('returns every supported category without pagination or artificial empty groups', function (): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $totals = array_fill_keys([
        'food', 'health', 'housing', 'leisure', 'shopping', 'services', 'transport', 'education', 'subscriptions',
        'financing', 'investments', 'taxes', 'insurance', 'personal_care', 'pets', 'gifts_and_donations', 'travel', 'other',
    ], '1');
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->expects($this->once())->method('summarize')->willReturn(expenseMetricsProjectionFixture('18', $totals));

    $output = $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category));

    expect($output->totalAmount)->toBe('18')
        ->and($output->categories)->toHaveCount(18)
        ->and(array_column($output->categories, 'category'))->toBe([
            'education', 'financing', 'food', 'gifts_and_donations', 'health', 'housing', 'insurance', 'investments',
            'leisure', 'other', 'personal_care', 'pets', 'services', 'shopping', 'subscriptions', 'taxes', 'transport', 'travel',
        ])
        ->and(array_unique(array_column($output->categories, 'percentage')))->toBe(['5.56']);
});

it('keeps identity stable when values and category order change while performing a fresh read each time', function (): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $userPort->expects($this->exactly(2))->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->expects($this->exactly(2))->method('summarize')->willReturnOnConsecutiveCalls(
        expenseMetricsProjectionFixture('10000', ['other' => '4000', 'food' => '6000']),
        expenseMetricsProjectionFixture('12500', ['food' => '8500', 'other' => '4000']),
    );
    $input = expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category);

    $first = $useCase->execute($input);
    $second = $useCase->execute($input);

    expect($first->id)->toBe($second->id)
        ->and($first->totalAmount)->toBe('10000')
        ->and($second->totalAmount)->toBe('12500')
        ->and($first->categories[0]->percentage)->toBe('60.00')
        ->and($second->categories[0]->percentage)->toBe('68.00');
});

it('gives equivalent default and explicit months the same identity and read parameters', function (): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $period = DatePeriodValueObject::monthContaining('2026-10-09');
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->expects($this->exactly(2))->method('summarize')
        ->with(UuidFixture::at(42), $period, ExpenseMetricsGroupingEnum::Total)->willReturn(expenseMetricsProjectionFixture('0'));

    $default = $useCase->execute(new GetExpenseMetricsInput(period: $period));
    $explicit = $useCase->execute(expenseMetricsInputFixture());

    expect($default->id)->toBe($explicit->id)
        ->and($default->period->to())->toBe('2026-10-31');
});

it('distinguishes the account both period endpoints and grouping in opaque identity', function (string $dimension): void {
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class));
    $userPort->method('id')->willReturnOnConsecutiveCalls(UuidFixture::at(42), UuidFixture::at($dimension === 'account' ? 43 : 42));
    $metricsPort->method('summarize')->willReturn(expenseMetricsProjectionFixture('0'));
    $changed = match ($dimension) {
        'account' => expenseMetricsInputFixture(),
        'start' => expenseMetricsInputFixture(from: '2026-10-02'),
        'end' => expenseMetricsInputFixture(to: '2026-10-30'),
        'grouping' => expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category),
    };

    expect($useCase->execute(expenseMetricsInputFixture())->id)->not->toBe($useCase->execute($changed)->id);
})->with(['account', 'start', 'end', 'grouping']);

it('does not read metrics when authenticated identity fails', function (): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $userPort->method('id')->willThrowException(new RuntimeException('Identity unavailable'));
    $metricsPort->expects($this->never())->method('summarize');

    $useCase->execute(expenseMetricsInputFixture());
})->throws(RuntimeException::class, 'Identity unavailable');

it('propagates analytical failures instead of returning total zero', function (): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->method('summarize')->willThrowException(new RuntimeException('Metrics unavailable'));

    $useCase->execute(expenseMetricsInputFixture());
})->throws(RuntimeException::class, 'Metrics unavailable');

it('rejects malformed category projections instead of silently repairing or omitting facts', function (ExpenseMetricsProjectionOutput $projection): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->method('summarize')->willReturn($projection);

    $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category));
})->with([
    'missing categories for positive total' => [new ExpenseMetricsProjectionOutput('1')],
    'groups do not reconcile' => [expenseMetricsProjectionFixture('100', ['food' => '99'])],
    'category exceeds total' => [expenseMetricsProjectionFixture('100', ['food' => '101'])],
    'positive groups with zero total' => [expenseMetricsProjectionFixture('0', ['food' => '1'])],
    'empty category identifier' => [expenseMetricsProjectionFixture('1', ['' => '1'])],
    'unknown category identifier' => [expenseMetricsProjectionFixture('1', ['unknown' => '1'])],
    'zero category' => [expenseMetricsProjectionFixture('1', ['food' => '1', 'health' => '0'])],
    'duplicated category' => [new ExpenseMetricsProjectionOutput('2', [new ExpenseCategoryTotalOutput('food', '1'), new ExpenseCategoryTotalOutput('food', '1')])],
    'untyped category item' => [new ExpenseMetricsProjectionOutput('1', ['food'])],
    'non list categories' => [new ExpenseMetricsProjectionOutput('1', ['food' => new ExpenseCategoryTotalOutput('food', '1')])],
])->throws(InvalidExpenseMetricsProjectionException::class);

it('rejects noncanonical exact amounts in the projection', function (string $amount, bool $categoryAmount): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $projection = $categoryAmount ? expenseMetricsProjectionFixture('1', ['food' => $amount]) : expenseMetricsProjectionFixture($amount);
    $metricsPort->method('summarize')->willReturn($projection);

    $useCase->execute(expenseMetricsInputFixture($categoryAmount ? ExpenseMetricsGroupingEnum::Category : ExpenseMetricsGroupingEnum::Total));
})->with(['-1', '01', '1.00', '1e3', ''])->with([false, true])->throws(InvalidAmountException::class);

it('rejects categories unexpectedly provided in total only mode', function (): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    [$userPort, $metricsPort, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $userPort->method('id')->willReturn(UuidFixture::at(42));
    $metricsPort->method('summarize')->willReturn(expenseMetricsProjectionFixture('1', ['food' => '1']));

    $useCase->execute(expenseMetricsInputFixture());
})->throws(InvalidExpenseMetricsProjectionException::class);

it('resolves one canonical key after the financial read including zero without calculated facts', function (ExpenseMetricsGroupingEnum $mode, string $amount): void {
    $read = false;
    $resolved = [];
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->with(UuidFixture::at(42), $this->anything())
        ->willReturnCallback(static function (string $owner, array $keys) use (&$resolved, &$read): array {
            $resolved = [$read, $keys];

            return [new ResourceKeyOutput($keys[0], UuidFixture::at(999))];
        });
    [$user, $metrics, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $user->method('id')->willReturn(strtoupper(UuidFixture::at(42)));
    $metrics->expects($this->once())->method('summarize')->with(UuidFixture::at(42), $this->anything(), $mode)
        ->willReturnCallback(static function () use (&$read, $mode, $amount): ExpenseMetricsProjectionOutput {
            $read = true;

            return expenseMetricsProjectionFixture($amount, $mode === ExpenseMetricsGroupingEnum::Category && $amount !== '0' ? ['food' => $amount] : []);
        });

    $output = $useCase->execute(expenseMetricsInputFixture($mode));
    expect($output->id)->toBe(UuidFixture::at(999))->and($output->totalAmount)->toBe($amount)
        ->and($resolved[0])->toBeTrue()
        ->and($resolved[1])->toEqual([new ResourceKeyInput(namespace: 'expense-metrics', identityVersion: 1, components: [
            'start_date' => '2026-10-01', 'end_date' => '2026-10-31', 'mode' => $mode->value,
        ])])
        ->and(array_keys($resolved[1][0]->components))->toBe(['start_date', 'end_date', 'mode']);
})->with(ExpenseMetricsGroupingEnum::cases())->with(['0', '12000000000000000000']);

it('fails explicitly when the registry fails or returns incomplete or invalid identities', function (string $failure): void {
    $resources = $this->createMock(ResourceRepository::class);
    $resolve = $resources->expects($this->once())->method('resolve');
    if ($failure === 'unavailable') {
        $resolve->willThrowException(new RuntimeException('private registry failure'));
    } else {
        $resolve->willReturnCallback(static fn (string $owner, array $keys): array => $failure === 'missing'
            ? [] : [new ResourceKeyOutput($keys[0], str_repeat('a', 64))]);
    }
    [$user, $metrics, $useCase] = expenseMetricsUseCaseFixture($this->createMock(UserPort::class), $this->createMock(ExpenseMetricsRepository::class), $resources);
    $user->method('id')->willReturn(UuidFixture::at(42));
    $metrics->expects($this->once())->method('summarize')->willReturn(expenseMetricsProjectionFixture('100', ['food' => '100']));

    expect(fn () => $useCase->execute(expenseMetricsInputFixture(ExpenseMetricsGroupingEnum::Category)))
        ->toThrow(ResourcePersistenceException::class, 'Resource identities could not be resolved.');
})->with(['unavailable', 'missing', 'hash']);
