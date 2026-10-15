<?php

declare(strict_types=1);

namespace App\Expense\Domain\Entities;

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use DateTimeImmutable;

final readonly class ExpenseEntity
{
    public ?string $id;

    public string $userId;

    public ExpenseCategoryEnum $category;

    public function __construct(
        ?string $id,
        string $userId,
        public int $amount,
        public string $occurredOn,
        ?string $category = null,
        public ?string $description = null,
        public ?DateTimeImmutable $createdAt = null,
    ) {
        $this->id = $id === null ? null : UuidValueObject::fromString($id)->value();
        $this->userId = UuidValueObject::fromString($userId)->value();
        if ($amount <= 0) {
            throw new InvalidExpenseException(message: 'O valor da despesa deve ser positivo.');
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

    public static function isDescriptionEligibleForClassification(?string $description): bool
    {
        if ($description === null || preg_match('/^\s*$/u', $description) === 1) {
            return false;
        }

        $value = trim($description);

        return preg_match('/^(?:[\'\"]\s*or\s*[\'\"]?1[\'\"]?\s*=\s*[\'\"]?1[\'\"]?|<script\b[^>]*>.*<\/script>)$/iu', $value) !== 1;
    }
}
