<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Providers;

use App\Core\Application\Ports\ContextPort;
use App\Core\Application\Ports\ObservabilityPort;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Ports\UserPort;
use App\Core\Infrastructure\Adapters\ContextAdapter;
use App\Core\Infrastructure\Adapters\Observability\ObservabilityAdapter;
use App\Core\Infrastructure\Adapters\TransactionAdapter;
use App\Core\Infrastructure\Adapters\UserAdapter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Log\Context\Repository as ContextRepository;
use Illuminate\Queue\Events\JobFailed;
use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Routing\Events\RouteMatched;
use Illuminate\Support\Facades\Context;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Laravel\Nightwatch\Facades\Nightwatch;
use Laravel\Nightwatch\Records\Request as NightwatchRequest;

final class CoreServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: UserPort::class, concrete: UserAdapter::class);
        $this->app->bind(abstract: ContextPort::class, concrete: ContextAdapter::class);
        $this->app->bind(abstract: TransactionPort::class, concrete: TransactionAdapter::class);
        $this->app->bind(abstract: ObservabilityPort::class, concrete: ObservabilityAdapter::class);
    }

    public function boot(ObservabilityPort $port): void
    {
        Context::hydrated(static function (ContextRepository $context): void {
            $context->forget(['request_id', 'trace_id', 'http_method', 'path', 'ip', 'route', 'user_id']);
        });

        Event::listen(RouteMatched::class, function (RouteMatched $event): void {
            $this->app->make(ContextPort::class)->identifyRoute($event->route->uri());
        });

        Nightwatch::redactRequests(static function (NightwatchRequest $request): void {
            $url = explode('?', $request->url, 2)[0];
            $request->url = preg_replace('~(/api/email-verification/)[^/]+/[^/]+$~', '$1[redacted]/[redacted]', $url) ?? $url;
        });

        RateLimiter::for('api.authenticated', fn (Request $request): Limit => Limit::perMinute(60)
            ->by('api:authenticated:user:'.$this->app->make(UserPort::class)->id()));

        Queue::after(function (JobProcessed $event) use ($port): void {
            if ($event->job->hasFailed() || $event->job->isReleased()) {
                return;
            }

            $port->emit('queue.job_processed', [
                'duration_ms' => $event->duration,
                'queue' => $event->job->getQueue(),
                'job_id' => $event->job->getJobId(),
                'job' => $event->job->resolveName(),
                'attempts' => $event->job->attempts(),
                'connection' => $event->connectionName,
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
