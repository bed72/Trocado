<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence;

use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use DateTimeImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Pagination\Cursor;

final class EloquentExpenseRepository implements ExpenseRepository
{
    public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput
    {
        $page = ExpenseModel::query()
            ->where('user_id', $userId)
            ->orderByDesc('occurred_on')
            ->orderByDesc('id')
            ->cursorPaginate(perPage: $size, cursor: $cursor === null ? null : Cursor::fromEncoded($cursor));

        $items = [];

        foreach ($page->items() as $model) {
            $items[] = new ExpenseEntity(
                id: (int) $model->getKey(),
                userId: $model->user_id,
                amount: $model->amount,
                category: $model->category,
                occurredOn: $model->occurred_on,
                description: $model->description,
                createdAt: DateTimeImmutable::createFromInterface($model->created_at),
            );
        }

        return new ExpensePageOutput(
            items: $items,
            nextCursor: $page->nextCursor()?->encode(),
            previousCursor: $page->previousCursor()?->encode(),
        );
    }

    public function create(ExpenseEntity $expense): ExpenseEntity
    {
        try {
            $model = ExpenseModel::query()->create(attributes: [
                'user_id' => $expense->userId,
                'amount' => $expense->amount,
                'occurred_on' => $expense->occurredOn,
                'description' => $expense->description,
                'category' => $expense->category->value,
            ]);
        } catch (QueryException $exception) {
            $sqlState = $exception->errorInfo[0] ?? null;
            $driverCode = $exception->errorInfo[1] ?? null;

            if ($sqlState === '23503' || $driverCode === 1452 || ($sqlState === '23000' && in_array(needle: $driverCode, haystack: [19, 787], strict: true))) {
                throw new ExpenseOwnerNotFoundException(previous: $exception);
            }

            throw $exception;
        }

        return new ExpenseEntity(
            id: (int) $model->getKey(),
            amount: $model->amount,
            userId: $model->user_id,
            category: $model->category,
            occurredOn: $model->occurred_on,
            description: $model->description,
            createdAt: DateTimeImmutable::createFromInterface(object: $model->created_at),
        );
    }

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
            $this->cancelClassificationAttempt(expenseId: $expenseId, token: $token);

            return null;
        }

        if ($model->category !== ExpenseCategoryEnum::Other->value || $model->description === null) {
            return null;
        }

        return new ExpenseClassificationOutput(description: $model->description);
    }

    public function applyClassificationAttempt(int $expenseId, string $token, string $description, ExpenseCategoryEnum $category): ?int
    {
        $model = ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('classification_token', $token)
            ->where('classification_expires_at', '>', new DateTimeImmutable)
            ->where('category', ExpenseCategoryEnum::Other->value)
            ->where('description', $description)
            ->first(['id', 'user_id']);

        if ($model === null) {
            return null;
        }

        $updated = ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('classification_token', $token)
            ->where('classification_expires_at', '>', new DateTimeImmutable)
            ->where('category', ExpenseCategoryEnum::Other->value)
            ->where('description', $description)
            ->update([
                'category' => $category->value,
                'classification_token' => null,
                'classification_expires_at' => null,
            ]);

        return $updated === 1 ? $model->user_id : null;
    }

    public function cancelClassificationAttempt(int $expenseId, string $token): void
    {
        ExpenseModel::query()
            ->whereKey($expenseId)
            ->where('classification_token', $token)
            ->update([
                'classification_token' => null,
                'classification_expires_at' => null,
            ]);
    }

    public function deleteByUser(int $id, int $userId): bool
    {
        return ExpenseModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->delete() === 1;
    }

    public function updateByUser(int $id, int $userId, UpdateExpenseInput $input): ?ExpenseEntity
    {
        $model = ExpenseModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->first();

        if ($model === null) {
            return null;
        }

        $expense = new ExpenseEntity(
            id: (int) $model->getKey(),
            userId: $model->user_id,
            amount: $input->hasAmount ? (int) $input->amount : $model->amount,
            category: $input->hasCategory ? $input->category : $model->category,
            createdAt: DateTimeImmutable::createFromInterface(object: $model->created_at),
            description: $input->hasDescription ? $input->description : $model->description,
            occurredOn: $input->hasOccurredOn ? (string) $input->occurredOn : $model->occurred_on,
        );

        $attributes = [
            'amount' => $expense->amount,
            'occurred_on' => $expense->occurredOn,
            'description' => $expense->description,
            'category' => $expense->category->value,
        ];

        if ($input->hasCategory || $input->hasDescription) {
            $attributes['classification_token'] = null;
            $attributes['classification_expires_at'] = null;
        }

        $model->fill($attributes)->save();

        return $expense;
    }
}
