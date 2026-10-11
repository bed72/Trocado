<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;
use App\Expense\Application\Data\ExpenseSuggestionOutput;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Expense\Application\UseCases\GetExpenseSuggestionsUseCase;
use Tests\Support\Core\Stubs\UserPortStub;

it('reads the authenticated owner once and forwards the query and complete previous months in one read', function (string $referenceDate, string $from, string $to): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $port->expects($this->once())->method('id')->willReturn(42);
    $port->expects($this->never())->method('status');
    $repository->expects($this->once())->method('search')->with(
        42,
        'iNt%_\\',
        $this->callback(static fn (DatePeriodValueObject $period): bool => $period->from() === $from && $period->to() === $to),
    )->willReturn([]);
    $useCase = new GetExpenseSuggestionsUseCase(port: $port, repository: $repository);

    expect($useCase->execute(query: 'iNt%_\\', referenceDate: $referenceDate))->toBe([]);
})->with([
    'October' => ['2026-10-11', '2026-07-01', '2026-09-30'],
    'year boundary on the 31st' => ['2027-01-31', '2026-10-01', '2026-12-31'],
    'month end without overflow' => ['2026-05-31', '2026-02-01', '2026-04-30'],
    'leap February' => ['2024-03-31', '2023-12-01', '2024-02-29'],
]);

it('suggests only an exact positive amount with three represented months and equal extrema', function (int $months, ?int $minimum, ?int $maximum, ?int $expected): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->willReturn([
        new ExpenseSuggestionHistoryOutput(
            key: 'internet', description: 'Internet', representedMonths: $months,
            minimumAmount: $minimum, maximumAmount: $maximum,
        ),
    ]);
    $useCase = new GetExpenseSuggestionsUseCase(port: new UserPortStub(42), repository: $repository);

    $output = $useCase->execute(query: 'Int', referenceDate: '2026-10-11');

    expect($output)->toHaveCount(1)
        ->and($output[0])->toBeInstanceOf(ExpenseSuggestionOutput::class)
        ->and($output[0]->description)->toBe('Internet')
        ->and($output[0]->amount)->toBe($expected)
        ->and($output[0]->id)->toMatch('/\A[0-9a-f]{64}\z/');
})->with([
    'equal values in all months' => [3, 14000, 14000, 14000],
    'different values between months' => [3, 10000, 12000, null],
    'three records in the same month' => [1, 14000, 14000, null],
    'missing middle month' => [2, 14000, 14000, null],
    'multiple consistent records across all months' => [3, 14000, 14000, 14000],
    'divergence within one month' => [3, 14000, 15000, null],
    'old history only' => [0, null, null, null],
    'single cent' => [3, 1, 1, 1],
    'fractional reais stay in cents' => [3, 14001, 14001, 14001],
    'above double precision' => [3, 9007199254740993, 9007199254740993, 9007199254740993],
    'one cent divergence above double precision' => [3, 9007199254740992, 9007199254740993, null],
    'maximum native integer' => [3, PHP_INT_MAX, PHP_INT_MAX, PHP_INT_MAX],
    'missing minimum' => [3, null, 14000, null],
    'missing maximum' => [3, 14000, null, null],
    'zero is not a valid expense amount' => [3, 0, 0, null],
]);

it('preserves repository ranking and representative descriptions without regrouping keys', function (): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->willReturn([
        new ExpenseSuggestionHistoryOutput('plano  internet', 'Plano  Internet', 0, null, null),
        new ExpenseSuggestionHistoryOutput('internet', 'INTERNET', 3, 14000, 14000),
    ]);
    $useCase = new GetExpenseSuggestionsUseCase(port: new UserPortStub(42), repository: $repository);

    $output = $useCase->execute(query: 'Int', referenceDate: '2026-10-11');

    expect(array_column($output, 'description'))->toBe(['Plano  Internet', 'INTERNET'])
        ->and(array_column($output, 'amount'))->toBe([null, 14000])
        ->and($output[0]->id)->not->toBe($output[1]->id);
});

it('keeps identity stable across searches, dates, spelling and values but distinguishes owners and keys', function (): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $port->expects($this->exactly(4))->method('id')->willReturnOnConsecutiveCalls(42, 42, 43, 42);
    $repository->expects($this->exactly(4))->method('search')->willReturnOnConsecutiveCalls(
        [new ExpenseSuggestionHistoryOutput('internet', 'Internet', 3, 14000, 14000)],
        [new ExpenseSuggestionHistoryOutput('internet', 'INTERNET', 2, 15000, 15000)],
        [new ExpenseSuggestionHistoryOutput('internet', 'Internet', 3, 14000, 14000)],
        [new ExpenseSuggestionHistoryOutput('plano internet', 'Plano Internet', 3, 14000, 14000)],
    );
    $useCase = new GetExpenseSuggestionsUseCase(port: $port, repository: $repository);

    $first = $useCase->execute(query: 'Int', referenceDate: '2026-10-11')[0];
    $variant = $useCase->execute(query: 'net', referenceDate: '2027-01-31')[0];
    $otherOwner = $useCase->execute(query: 'Int', referenceDate: '2026-10-11')[0];
    $otherKey = $useCase->execute(query: 'Int', referenceDate: '2026-10-11')[0];

    expect($first->id)->toBe($variant->id)
        ->and($variant->description)->toBe('INTERNET')
        ->and($variant->amount)->toBeNull()
        ->and($first->id)->not->toBe($otherOwner->id)
        ->and($first->id)->not->toBe($otherKey->id);
});

it('rejects invalid civil references before reading history', function (string $referenceDate): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $useCase = new GetExpenseSuggestionsUseCase(port: new UserPortStub(42), repository: $repository);

    expect(fn () => $useCase->execute(query: 'Int', referenceDate: $referenceDate))->toThrow(InvalidDatePeriodException::class);
})->with(['2026-02-30', '2026-10-11T00:00:00Z', '2026-1-01']);

it('does not read history when authenticated identity resolution fails', function (): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $failure = new RuntimeException('No authenticated owner');
    $port->expects($this->once())->method('id')->willThrowException($failure);
    $repository->expects($this->never())->method('search');
    $useCase = new GetExpenseSuggestionsUseCase(port: $port, repository: $repository);

    try {
        $useCase->execute(query: 'Int', referenceDate: '2026-10-11');
        $this->fail('Expected the identity failure.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
});
