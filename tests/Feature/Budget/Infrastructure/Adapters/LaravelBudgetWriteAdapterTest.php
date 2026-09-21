<?php

declare(strict_types=1);

use App\Budget\Infrastructure\Adapters\BudgetWriteAdapter;
use Illuminate\Support\Facades\DB;

it('fails without executing the operation when the database lock row is absent', function (): void {
    DB::table('budget_write_locks')->delete();
    $executed = false;

    expect(fn () => (new BudgetWriteAdapter)->execute(function () use (&$executed): void {
        $executed = true;
    }))->toThrow(RuntimeException::class, 'Não foi possível adquirir o lock de escrita de Budget.');

    expect($executed)->toBeFalse();
});
