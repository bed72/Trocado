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

    public function cancelClassification(string $expenseId, string $token): void
    {
        $this->repository->cancelClassification(expenseId: $expenseId, token: $token);
    }

    public function findClassificationAttempt(string $expenseId, string $token): ?ExpenseClassificationOutput
    {
        return $this->repository->findClassificationAttempt(expenseId: $expenseId, token: $token);
    }

    public function beginClassificationAttempt(string $expenseId, string $token, DateTimeImmutable $expiresAt): bool
    {
        return $this->repository->beginClassificationAttempt(expenseId: $expenseId, token: $token, expiresAt: $expiresAt);
    }

    public function applyClassificationAttempt(ApplyExpenseClassificationInput $input): ?string
    {
        $userId = $this->repository->applyClassificationAttempt(input: $input);

        if ($userId !== null) {
            DB::afterCommit(callback: $this->cache->tags("expense:pages:v3:owner:{$userId}")->flush(...));
        }

        return $userId;
    }
}
