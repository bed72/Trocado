<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
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
