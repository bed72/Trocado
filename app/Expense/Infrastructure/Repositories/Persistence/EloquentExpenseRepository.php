<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Persistence;

use App\Expense\Application\Data\ExpenseCursorOutput;
use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use DateTimeImmutable;
use Illuminate\Database\QueryException;
use Illuminate\Pagination\Cursor;

use function in_array;

final class EloquentExpenseRepository implements ExpenseRepository
{
    public function __construct(private readonly ExpenseQueryCursorPort $port) {}

    public function getById(string $id, string $userId): ?ExpenseEntity
    {
        $model = ExpenseModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->first();

        if ($model === null) {
            return null;
        }

        return new ExpenseEntity(
            id: $model->getKey(),
            userId: $model->user_id,
            amount: $model->amount,
            category: $model->category,
            occurredOn: $model->occurred_on,
            description: $model->description,
            createdAt: DateTimeImmutable::createFromInterface(object: $model->created_at),
        );
    }

    public function getAll(string $userId, GetAllExpenseInput $input): ExpensePageOutput
    {
        $cursor = $this->port->decode($input);
        $query = ExpenseModel::query()->where('user_id', $userId);

        foreach (['occurred_on' => [$input->from, $input->to], 'amount' => [$input->amountMin, $input->amountMax]] as $column => [$minimum, $maximum]) {
            if ($minimum !== null) {
                $query->where($column, '>=', $minimum);
            }
            if ($maximum !== null) {
                $query->where($column, '<=', $maximum);
            }
        }

        if ($input->categories !== []) {
            $query->whereIn('category', $input->categories);
        }

        $query->select('expenses.*');
        foreach ($input->sorts as $sort) {
            $field = ltrim($sort, '-');
            $column = match ($field) {
                'amount' => 'amount',
                'occurred_on' => 'occurred_on',
                'description' => 'description_sort',
            };
            if ($field === 'description') {
                $query->selectRaw('(COALESCE(description, \'\') COLLATE "expense_description_ci_ai") as description_sort');
            }
            $query->orderBy($column, str_starts_with($sort, '-') ? 'desc' : 'asc');
        }
        $query->orderByDesc('id');

        $parameters = [];
        foreach ($cursor?->position ?? [] as $field => $value) {
            $parameters[$field === 'description' ? 'description_sort' : $field] = $value;
        }
        $page = $query->cursorPaginate(perPage: $input->size, cursor: $cursor === null ? null : new Cursor($parameters, $cursor->forward));

        $items = [];

        foreach ($page->items() as $model) {
            $items[] = new ExpenseEntity(
                id: $model->getKey(),
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
            nextCursor: $this->encodeCursor($input, $page->nextCursor()),
            previousCursor: $this->encodeCursor($input, $page->previousCursor()),
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
            id: $model->getKey(),
            amount: $model->amount,
            userId: $model->user_id,
            category: $model->category,
            occurredOn: $model->occurred_on,
            description: $model->description,
            createdAt: DateTimeImmutable::createFromInterface(object: $model->created_at),
        );
    }

    public function delete(string $id, string $userId): bool
    {
        return ExpenseModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->delete() === 1;
    }

    public function update(string $id, string $userId, UpdateExpenseInput $input): ?ExpenseEntity
    {
        $model = ExpenseModel::query()
            ->whereKey($id)
            ->where('user_id', $userId)
            ->first();

        if ($model === null) {
            return null;
        }

        $expense = new ExpenseEntity(
            id: $model->getKey(),
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

    private function encodeCursor(GetAllExpenseInput $input, ?Cursor $cursor): ?string
    {
        if ($cursor === null) {
            return null;
        }
        $values = $cursor->toArray();
        unset($values['_pointsToNextItems']);
        $position = [];
        foreach ($values as $field => $value) {
            $position[$field === 'description_sort' ? 'description' : $field] = $value;
        }

        return $this->port->encode($input, new ExpenseCursorOutput($position, $cursor->pointsToNextItems()));
    }
}
