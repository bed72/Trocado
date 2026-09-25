<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence;

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use DateTimeImmutable;

final class EloquentExpenseCategorizationRepository implements ExpenseCategorizationRepository
{
    public function beginClassificationAttempt(int $expenseId, string $token, DateTimeImmutable $expiresAt): bool
    {
        return ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('category', ExpenseCategoryEnum::Other->value)
            ->update([
                'classification_token' => $token,
                'classification_expires_at' => $expiresAt,
            ]) === 1;
    }

    public function findClassificationAttempt(int $expenseId, string $token): ?ExpenseClassificationOutput
    {
        $model = ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('classification_token', $token)
            ->first();

        if ($model === null) {
            return null;
        }

        if ($model->classification_expires_at === null || $model->classification_expires_at <= new DateTimeImmutable) {
            $this->cancelClassification(expenseId: $expenseId, token: $token);

            return null;
        }

        if ($model->category !== ExpenseCategoryEnum::Other->value || $model->description === null) {
            return null;
        }

        return new ExpenseClassificationOutput(description: $model->description);
    }

    public function applyClassificationAttempt(ApplyExpenseClassificationInput $input): ?int
    {
        $model = ExpenseModel::query()
            ->whereKey($input->expenseId)
            ->where('classification_token', $input->token)
            ->where('classification_expires_at', '>', new DateTimeImmutable)
            ->where('category', ExpenseCategoryEnum::Other->value)
            ->where('description', $input->description)
            ->first(['id', 'user_id']);

        if ($model === null) {
            return null;
        }

        $updated = ExpenseModel::query()
            ->whereKey($input->expenseId)
            ->where('classification_token', $input->token)
            ->where('classification_expires_at', '>', new DateTimeImmutable)
            ->where('category', ExpenseCategoryEnum::Other->value)
            ->where('description', $input->description)
            ->update([
                'category' => $input->category->value,
                'classification_token' => null,
                'classification_expires_at' => null,
            ]);

        return $updated === 1 ? $model->user_id : null;
    }

    public function cancelClassification(int $expenseId, string $token): void
    {
        ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('classification_token', $token)
            ->update([
                'classification_token' => null,
                'classification_expires_at' => null,
            ]);
    }
}
