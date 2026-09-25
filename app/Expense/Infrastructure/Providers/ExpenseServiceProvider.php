<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Providers;

use App\Expense\Application\Ports\ExpenseClassificationDispatchPort;
use App\Expense\Application\Ports\ExpenseClassificationPort;
use App\Expense\Application\Ports\UserPort;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Infrastructure\Adapters\ExpenseClassificationAdapter;
use App\Expense\Infrastructure\Adapters\ExpenseClassificationDispatchAdapter;
use App\Expense\Infrastructure\Adapters\UserAdapter;
use App\Expense\Infrastructure\Repositories\Cache\CachedExpenseRepository;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use Illuminate\Cache\CacheManager;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\ServiceProvider;

final class ExpenseServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: EloquentExpenseRepository::class);
        $this->app->bind(abstract: UserPort::class, concrete: UserAdapter::class);
        $this->app->bind(abstract: ExpenseClassificationPort::class, concrete: ExpenseClassificationAdapter::class);
        $this->app->bind(abstract: ExpenseClassificationDispatchPort::class, concrete: ExpenseClassificationDispatchAdapter::class);
        $this->app->bind(abstract: ExpenseRepository::class, concrete: fn (): CachedExpenseRepository => new CachedExpenseRepository(
            cache: $this->app->make(CacheManager::class),
            repository: $this->app->make(EloquentExpenseRepository::class),
        ));
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->environment('production'));

        $apiKey = Config::get('expense.classification.api_key');

        if (is_string($apiKey) && $apiKey !== '') {
            $provider = Config::string('expense.classification.provider');

            Config::set("ai.providers.{$provider}.key", $apiKey);
        }
    }
}
