<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Persistence\Repositories;

use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Persistence\Models\ExpenseModel;
use DateTimeImmutable;
use Illuminate\Database\QueryException;

final class EloquentExpenseRepository implements ExpenseRepository
{
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
            userId: $model->user_id,
            amount: $model->amount,
            category: $model->category,
            occurredOn: $model->occurred_on,
            description: $model->description,
            createdAt: DateTimeImmutable::createFromInterface(object: $model->created_at),
        );
    }
}
