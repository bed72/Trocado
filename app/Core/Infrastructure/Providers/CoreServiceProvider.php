<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Providers;

use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Infrastructure\Adapters\Observability\ObservabilityAdapter;
use App\Core\Infrastructure\Adapters\TransactionAdapter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

final class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: TransactionPort::class, concrete: TransactionAdapter::class);
        $this->app->bind(abstract: ObservabilityPort::class, concrete: ObservabilityAdapter::class);
    }

    public function boot(ObservabilityPort $port): void
    {
        RateLimiter::for('api.authenticated', fn (Request $request): Limit => Limit::perMinute(60)
            ->by('api:authenticated:user:'.$request->user()->getAuthIdentifier()));

        Queue::after(function (JobProcessed $event) use ($port): void {
            if ($event->job->hasFailed() || $event->job->isReleased()) {
                return;
            }

            $port->emit('queue.job_processed', [
                'connection' => $event->connectionName,
                'queue' => $event->job->getQueue(),
                'job_id' => $event->job->getJobId(),
                'job' => $event->job->resolveName(),
                'attempts' => $event->job->attempts(),
            ]);
        });

        Queue::failing(fn (JobFailed $event) => $port->emit('queue.job_failed', [
            'connection' => $event->connectionName,
            'queue' => $event->job->getQueue(),
            'job_id' => $event->job->getJobId(),
            'job' => $event->job->resolveName(),
            'attempts' => $event->job->attempts(),
            'error_class' => $event->exception::class,
        ]));
    }
}
