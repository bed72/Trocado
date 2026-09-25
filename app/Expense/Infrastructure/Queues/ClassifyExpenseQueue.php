<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Queues;

use App\Expense\Application\UseCases\ClassifyExpenseUseCase;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

final class ClassifyExpenseQueue implements ShouldQueue
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
}
