<?php

declare(strict_types=1);

use App\Budget\Application\Repositories\BudgetRepository;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use App\Budget\Domain\Entities\BudgetEntity;
use App\Budget\Domain\Exceptions\InvalidBudgetDateRangeException;
use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('persists a valid domain entity and returns the repository result', function (): void {
    $persisted = new BudgetEntity(
        id: 10,
        endDate: '2026-09-30',
        startDate: '2026-09-01',
        amount: MoneyValueObject::fromCents(cents: 12500),
    );
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->once())
        ->method('save')
        ->with($this->callback(function (BudgetEntity $budget): bool {
            expect($budget->id)->toBeNull()
                ->and($budget->amount->cents())->toBe(12500)
                ->and($budget->startDate)->toBe('2026-09-01')
                ->and($budget->endDate)->toBe('2026-09-30');

            return true;
        }))
        ->willReturn($persisted);

    $result = (new CreateBudgetUseCase(repository: $repository))->execute(
        amount: 12500,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
    );

    expect($result)->toBe($persisted);
});

it('does not persist an invalid date range', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->never())->method('save');

    (new CreateBudgetUseCase(repository: $repository))->execute(
        amount: 100,
        startDate: '2026-09-30',
        endDate: '2026-09-01',
    );
})->throws(InvalidBudgetDateRangeException::class);

it('does not persist a negative amount', function (): void {
    $repository = $this->createMock(BudgetRepository::class);
    $repository->expects($this->never())->method('save');

    (new CreateBudgetUseCase(repository: $repository))->execute(
        amount: -1,
        startDate: '2026-09-01',
        endDate: '2026-09-30',
    );
})->throws(InvalidMoneyAmountException::class);
