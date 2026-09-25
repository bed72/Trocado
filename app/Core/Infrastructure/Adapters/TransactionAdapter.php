<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Ports\TransactionPort;
use Illuminate\Support\Facades\DB;

final class TransactionAdapter implements TransactionPort
{
    public function execute(callable $operation): mixed
    {
        return DB::transaction(callback: $operation, attempts: 3);
    }
}
