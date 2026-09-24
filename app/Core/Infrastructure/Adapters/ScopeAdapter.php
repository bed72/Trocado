<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Ports\ScopePort;
use Illuminate\Support\Facades\DB;
use LogicException;

final class ScopeAdapter implements ScopePort
{
    public function execute(int $userId, callable $operation): mixed
    {
        $connection = DB::connection();

        if ($connection->getDriverName() !== 'pgsql' || $connection->transactionLevel() !== 0 || $userId < 1) {
            throw new LogicException('O escopo requer uma transação PostgreSQL própria e um principal válido.');
        }

        return $connection->transaction(function () use ($connection, $userId, $operation): mixed {
            $connection->select('select set_config(?, ?, true)', ['app.user_id', (string) $userId]);

            return $operation();
        }, 3);
    }
}
