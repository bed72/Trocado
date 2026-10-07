<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Adapters;

use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Infrastructure\Queues\ClassifyExpenseQueue;
use Illuminate\Contracts\Bus\Dispatcher;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Throwable;

final readonly class ExpenseClassificationDispatchAdapter implements ExpenseClassificationDispatchPort
{
    public function __construct(
        private Dispatcher $dispatcher,
        private ExpenseCategorizationRepository $repository,
    ) {}

    public function dispatch(string $token, int $expenseId): void
    {
        DB::afterCommit(function () use ($expenseId, $token): void {
            if (Config::string('queue.default') === 'sync') {
                $this->repository->cancelClassification(expenseId: $expenseId, token: $token);

                return;
            }

            try {
                $job = new ClassifyExpenseQueue(
                    token: $token,
                    expenseId: $expenseId,
                    tries: max(1, Config::integer('expense.classification.tries')),
                    timeout: max(1, Config::integer('expense.classification.job_timeout')),
                );
                $job->onQueue(Config::string('expense.classification.queue'));

                $this->dispatcher->dispatch($job);
            } catch (Throwable $exception) {
                $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
                report($exception);
            }
        });
    }
}
