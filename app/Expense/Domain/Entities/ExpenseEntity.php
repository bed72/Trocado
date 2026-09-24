<?php

declare(strict_types=1);

namespace App\Expense\Domain\Entities;

use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use DateTimeImmutable;

final readonly class ExpenseEntity
{
    public ExpenseCategoryEnum $category;

    public function __construct(
        public ?int $id,
        public int $userId,
        public int $amount,
        public string $occurredOn,
        ?string $category = null,
        public ?string $description = null,
        public ?DateTimeImmutable $createdAt = null,
    ) {
        if ($userId <= 0 || $amount <= 0) {
            throw new InvalidExpenseException(message: 'O proprietário e o valor da despesa devem ser positivos.');
        }

        $date = DateTimeImmutable::createFromFormat(format: '!Y-m-d', datetime: $occurredOn);

        if ($date === false || $date->format(format: 'Y-m-d') !== $occurredOn) {
            throw new InvalidExpenseException(message: 'A data da despesa deve ser uma data civil válida.');
        }

        if ($description !== null && mb_strlen(string: $description) > 64) {
            throw new InvalidExpenseException(message: 'A descrição da despesa deve ter no máximo 64 caracteres.');
        }

        if ($category !== null && strlen(string: $category) > 32) {
            throw new InvalidExpenseException(message: 'A categoria da despesa deve ter no máximo 32 caracteres.');
        }

        $this->category = $category === null
            ? ExpenseCategoryEnum::Other
            : (ExpenseCategoryEnum::tryFrom(value: $category)
                ?? throw new InvalidExpenseException(message: 'A categoria da despesa é inválida.'));
    }
}
