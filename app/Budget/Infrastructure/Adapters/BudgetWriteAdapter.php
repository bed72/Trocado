<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Adapters;

use App\Budget\Application\Ports\BudgetWritePort;
use Illuminate\Support\Facades\DB;
use RuntimeException;

final class BudgetWriteAdapter implements BudgetWritePort
{
    public function execute(callable $operation): mixed
    {
        return DB::transaction(callback: function () use ($operation): mixed {
            $locked = DB::table(table: 'budget_write_locks')
                ->where(column: 'id', operator: 1)
                ->update(['version' => DB::raw(value: 'version + 1')]);

            if ($locked !== 1) {
                throw new RuntimeException(message: 'Não foi possível adquirir o lock de escrita de Budget.');
            }

            return $operation();
        }, attempts: 3);
    }
}
