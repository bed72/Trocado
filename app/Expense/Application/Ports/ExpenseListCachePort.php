<?php

declare(strict_types=1);

namespace App\Expense\Application\Ports;

use App\Expense\Application\Data\ExpensePageOutput;
use Closure;

interface ExpenseListCachePort
{
    public function invalidate(int $userId): void;

    /** @param Closure(): ExpensePageOutput $load */
    public function load(int $userId, int $size, ?string $cursor, Closure $load): ExpensePageOutput;
}
