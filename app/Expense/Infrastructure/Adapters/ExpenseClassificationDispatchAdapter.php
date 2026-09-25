<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Adapters;

use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Infrastructure\Queues\ClassifyExpenseQueue;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

final readonly class ExpenseClassificationDispatchAdapter implements ExpenseClassificationDispatchPort
{
    public function __construct(private EloquentExpenseRepository $repository) {}

    public function dispatch(string $token, int $expenseId): void
    {
        DB::afterCommit(function () use ($expenseId, $token): void {
            if (Config::string('queue.default') === 'sync') {
                $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
                Log::warning('Expense classification was not dispatched because the sync queue driver is disabled for this flow.');

                return;
            }

            try {
                ClassifyExpenseQueue::dispatch(
                    token: $token,
                    expenseId: $expenseId,
                    tries: max(1, Config::integer('expense.classification.tries')),
                    timeout: max(1, Config::integer('expense.classification.timeout')),
                )->onQueue(Config::string('expense.classification.queue'));
            } catch (Throwable $exception) {
                $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
                report($exception);
            }
        });
    }
}
