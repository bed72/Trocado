<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Cache;

use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\ExpenseClassificationOutput;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use DateTimeImmutable;
use Illuminate\Cache\CacheManager;
use Illuminate\Support\Facades\DB;

final readonly class CachedExpenseCategorizationRepository implements ExpenseCategorizationRepository
{
    public function __construct(
        private CacheManager $cache,
        private ExpenseCategorizationRepository $repository,
    ) {}

    public function cancelClassification(int $expenseId, string $token): void
    {
        $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
    }

    public function findClassificationAttempt(int $expenseId, string $token): ?ExpenseClassificationOutput
    {
        return $this->repository->findClassificationAttempt(expenseId: $expenseId, token: $token);
    }

    public function beginClassificationAttempt(int $expenseId, string $token, DateTimeImmutable $expiresAt): bool
    {
        return $this->repository->beginClassificationAttempt(expenseId: $expenseId, token: $token, expiresAt: $expiresAt);
    }

    public function applyClassificationAttempt(ApplyExpenseClassificationInput $input): ?int
    {
        $userId = $this->repository->applyClassificationAttempt(input: $input);

        if ($userId !== null) {
            DB::afterCommit(callback: $this->cache->tags("expense:pages:owner:{$userId}")->flush(...));
        }

        return $userId;
    }
}
