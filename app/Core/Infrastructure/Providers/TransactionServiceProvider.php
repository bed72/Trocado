<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Providers;

use App\Core\Application\Ports\TransactionPort;
use App\Core\Infrastructure\Adapters\DatabaseTransactionAdapter;
use Illuminate\Support\ServiceProvider;

final class TransactionServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: TransactionPort::class, concrete: DatabaseTransactionAdapter::class);
    }
}
