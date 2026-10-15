<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Ports\UserPort;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\ExpenseSuggestionHistoryOutput;
use App\Expense\Application\Data\ExpenseSuggestionOutput;
use App\Expense\Application\Exceptions\InvalidExpenseSuggestionsProjectionException;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Expense\Application\UseCases\GetExpenseSuggestionsUseCase;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Core\Stubs\UserPortStub;
use Tests\Support\Expense\Fakes\SuggestionResourceRepositoryFake;

function expenseSuggestionsUseCaseFixture(UserPort $port, ExpenseSuggestionsRepository $repository, ?ResourceRepository $resources = null): GetExpenseSuggestionsUseCase
{
    return new GetExpenseSuggestionsUseCase($port, new ResourceUseCase(new TransactionPortFake, $resources ?? new SuggestionResourceRepositoryFake), $repository);
}

it('reads the authenticated owner once and forwards the query and complete previous months in one read', function (string $referenceDate, string $from, string $to): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $port->expects($this->once())->method('id')->willReturn(UuidFixture::at(42));
    $port->expects($this->never())->method('status');
    $repository->expects($this->once())->method('search')->with(
        UuidFixture::at(42),
        'iNt%_\\',
        $this->callback(static fn (DatePeriodValueObject $period): bool => $period->from() === $from && $period->to() === $to),
    )->willReturn([]);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture($port, $repository, $resources);

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
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository);

    $output = $useCase->execute(query: 'Int', referenceDate: '2026-10-11');

    expect($output)->toHaveCount(1)
        ->and($output[0])->toBeInstanceOf(ExpenseSuggestionOutput::class)
        ->and($output[0]->description)->toBe('Internet')
        ->and($output[0]->amount)->toBe($expected)
        ->and($output[0]->id)->toBe(UuidFixture::at(100));
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
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository);

    $output = $useCase->execute(query: 'Int', referenceDate: '2026-10-11');

    expect(array_column($output, 'description'))->toBe(['Plano  Internet', 'INTERNET'])
        ->and(array_column($output, 'amount'))->toBe([null, 14000])
        ->and($output[0]->id)->not->toBe($output[1]->id);
});

it('keeps identity stable across searches, dates, spelling and values but distinguishes owners and keys', function (): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $port->expects($this->exactly(4))->method('id')->willReturnOnConsecutiveCalls(UuidFixture::at(42), UuidFixture::at(42), UuidFixture::at(43), UuidFixture::at(42));
    $repository->expects($this->exactly(4))->method('search')->willReturnOnConsecutiveCalls(
        [new ExpenseSuggestionHistoryOutput('internet', 'Internet', 3, 14000, 14000)],
        [new ExpenseSuggestionHistoryOutput('internet', 'INTERNET', 2, 15000, 15000)],
        [new ExpenseSuggestionHistoryOutput('internet', 'Internet', 3, 14000, 14000)],
        [new ExpenseSuggestionHistoryOutput('plano internet', 'Plano Internet', 3, 14000, 14000)],
    );
    $useCase = expenseSuggestionsUseCaseFixture($port, $repository);

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
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository, $resources);

    expect(fn () => $useCase->execute(query: 'Int', referenceDate: $referenceDate))->toThrow(InvalidDatePeriodException::class);
})->with(['2026-02-30', '2026-10-11T00:00:00Z', '2026-1-01']);

it('does not read history when authenticated identity resolution fails', function (): void {
    $port = $this->createMock(UserPort::class);
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $failure = new RuntimeException('No authenticated owner');
    $port->expects($this->once())->method('id')->willThrowException($failure);
    $repository->expects($this->never())->method('search');
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture($port, $repository, $resources);

    try {
        $useCase->execute(query: 'Int', referenceDate: '2026-10-11');
        $this->fail('Expected the identity failure.');
    } catch (RuntimeException $exception) {
        expect($exception)->toBe($failure);
    }
});

it('passes exact SQL keys in one final batch and maps reversed registry results back to ranking', function (): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->with(UuidFixture::at(42), 'net', $this->anything())->willReturn([
        new ExpenseSuggestionHistoryOutput('plano  café', 'Plano  CAFÉ', 0, null, null),
        new ExpenseSuggestionHistoryOutput('internet', 'INTERNET', 3, 14001, 14001),
    ]);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->once())->method('resolve')->with(UuidFixture::at(42), [
        new ResourceKeyInput(namespace: 'expense-suggestions', identityVersion: 1, components: ['description_key' => 'plano  café']),
        new ResourceKeyInput(namespace: 'expense-suggestions', identityVersion: 1, components: ['description_key' => 'internet']),
    ])->willReturnCallback(static fn (string $owner, array $keys): array => [
        new ResourceKeyOutput($keys[1], UuidFixture::at(101)),
        new ResourceKeyOutput($keys[0], UuidFixture::at(100)),
    ]);
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(strtoupper(UuidFixture::at(42))), $repository, $resources);

    $output = $useCase->execute('net', '2026-10-11');

    expect(array_column($output, 'id'))->toBe([UuidFixture::at(100), UuidFixture::at(101)])
        ->and(array_column($output, 'description'))->toBe(['Plano  CAFÉ', 'INTERNET'])
        ->and(array_column($output, 'amount'))->toBe([null, 14001]);
});

it('rejects an invalid final projection before allocating any identities', function (array $history): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->willReturn($history);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository, $resources);

    expect(fn () => $useCase->execute('Int', '2026-10-11'))->toThrow(InvalidExpenseSuggestionsProjectionException::class);
})->with([
    'invalid second item' => [[new ExpenseSuggestionHistoryOutput('internet', 'Internet', 0, null, null), new stdClass]],
    'empty second key' => [[new ExpenseSuggestionHistoryOutput('internet', 'Internet', 0, null, null), new ExpenseSuggestionHistoryOutput('', 'Other', 0, null, null)]],
    'empty description' => [[new ExpenseSuggestionHistoryOutput('internet', '', 0, null, null)]],
    'duplicate key' => [[new ExpenseSuggestionHistoryOutput('internet', 'Internet', 0, null, null), new ExpenseSuggestionHistoryOutput('internet', 'INTERNET', 0, null, null)]],
    'not a list' => [['key' => new ExpenseSuggestionHistoryOutput('internet', 'Internet', 0, null, null)]],
    'exceeds SQL limit' => [array_fill(0, 6, new ExpenseSuggestionHistoryOutput('internet', 'Internet', 0, null, null))],
]);

it('propagates source failure without resolving identities', function (): void {
    $failure = new RuntimeException('Source sentinel');
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->willThrowException($failure);
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository, $resources);

    expect(fn () => $useCase->execute('Int', '2026-10-11'))->toThrow($failure);
});

it('fails the complete batch when the registry fails or returns an incomplete result', function (bool $throws): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->once())->method('search')->willReturn([
        new ExpenseSuggestionHistoryOutput('internet', 'Internet', 3, 100, 100),
        new ExpenseSuggestionHistoryOutput('internal', 'Internal', 0, null, null),
    ]);
    $resources = $this->createMock(ResourceRepository::class);
    $resolve = $resources->expects($this->once())->method('resolve');
    if ($throws) {
        $resolve->willThrowException(new ResourcePersistenceException);
    } else {
        $resolve->willReturnCallback(static fn (string $owner, array $keys): array => [new ResourceKeyOutput($keys[0], UuidFixture::at(100))]);
    }
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub(UuidFixture::at(42)), $repository, $resources);

    expect(fn () => $useCase->execute('Int', '2026-10-11'))->toThrow(ResourcePersistenceException::class);
})->with([true, false]);

it('rejects an invalid owner before reading history or resolving resources', function (): void {
    $repository = $this->createMock(ExpenseSuggestionsRepository::class);
    $repository->expects($this->never())->method('search');
    $resources = $this->createMock(ResourceRepository::class);
    $resources->expects($this->never())->method('resolve');
    $useCase = expenseSuggestionsUseCaseFixture(new UserPortStub('42'), $repository, $resources);

    expect(fn () => $useCase->execute('Int', '2026-10-11'))->toThrow(InvalidUuidException::class);
});
