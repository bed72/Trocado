<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Queues;

use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\Interruptible;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Throwable;

final class ClassifyExpenseQueue implements Interruptible, ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;

    public function __construct(
        public readonly string $token,
        public readonly int $expenseId,
        public int $tries,
        public int $timeout,
    ) {}

    /** @return list<int> */
    public function backoff(): array
    {
        return [5, 30];
    }

    public function handle(ClassifyExpenseUseCase $useCase): void
    {
        $useCase->execute(expenseId: $this->expenseId, token: $this->token);
    }

    public function failed(): void
    {
        app(ClassifyExpenseUseCase::class)->fail(expenseId: $this->expenseId, token: $this->token);
    }

    public function interrupted(int $signal): void
    {
        try {
            Log::channel(Config::string('logging.observability_channel'))->info('expense.classification_interrupted', [
                'signal' => $signal,
                'queue' => $this->queue,
                'attempts' => $this->attempts(),
                'expense_id' => $this->expenseId,
                'event' => 'expense.classification_interrupted',
            ]);
        } catch (Throwable) {
            return;
        }
    }
}
