<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Repositories\Cache;

use App\Expense\Application\Data\ExpensePageOutput;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use DateTimeImmutable;
use Illuminate\Cache\CacheManager;

final readonly class CachedExpenseRepository implements ExpenseRepository
{
    public function __construct(
        private CacheManager $cache,
        private ExpenseRepository $repository,
    ) {}

    public function create(ExpenseEntity $expense): ExpenseEntity
    {
        $created = $this->repository->create($expense);

        $this->cache->tags($this->tag($created->userId))->flush();

        return $created;
    }

    public function listByUser(int $userId, int $size, ?string $cursor): ExpensePageOutput
    {
        $cursorKey = $cursor === null ? 'none' : "cursor:{$cursor}";
        $key = "expense:pages:v1:{$userId}:{$size}:".hash('sha256', $cursorKey);
        $tagged = $this->cache->tags($this->tag($userId));

        /** @var array{items: list<array{id: ?int, userId: int, amount: int, occurredOn: string, category: string, description: ?string, createdAt: ?string}>, nextCursor: ?string, previousCursor: ?string} $page */
        $page = $tagged->remember($key, 60, function () use ($userId, $size, $cursor): array {
            $output = $this->repository->listByUser(userId: $userId, size: $size, cursor: $cursor);

            return [
                'items' => array_map(static fn (ExpenseEntity $item): array => [
                    'id' => $item->id,
                    'userId' => $item->userId,
                    'amount' => $item->amount,
                    'occurredOn' => $item->occurredOn,
                    'description' => $item->description,
                    'category' => $item->category->value,
                    'createdAt' => $item->createdAt?->format('Y-m-d\TH:i:s.uP'),
                ], $output->items),
                'nextCursor' => $output->nextCursor,
                'previousCursor' => $output->previousCursor,
            ];
        });

        return new ExpensePageOutput(
            items: array_map(static fn (array $item): ExpenseEntity => new ExpenseEntity(
                id: $item['id'],
                userId: $item['userId'],
                amount: $item['amount'],
                category: $item['category'],
                occurredOn: $item['occurredOn'],
                description: $item['description'],
                createdAt: $item['createdAt'] === null ? null : new DateTimeImmutable($item['createdAt']),
            ), $page['items']),
            nextCursor: $page['nextCursor'],
            previousCursor: $page['previousCursor'],
        );
    }

    private function tag(int $userId): string
    {
        return "expense:pages:owner:{$userId}";
    }
}
