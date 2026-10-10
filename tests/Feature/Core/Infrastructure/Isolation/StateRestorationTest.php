<?php

declare(strict_types=1);

use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;

it('changes scenario globals without leaking them to the next application', function (): void {
    $this->travelTo(CarbonImmutable::parse('2001-01-01'));
    date_default_timezone_set('Pacific/Honolulu');
    app()->instance('isolation.probe', new stdClass);
    Event::listen('isolation.probe', static fn () => throw new RuntimeException('listener sentinel'));
    DB::enableQueryLog();
    DB::selectOne('select 1');
    expect(Carbon::hasTestNow())->toBeTrue()
        ->and(Event::hasListeners('isolation.probe'))->toBeTrue()
        ->and(DB::getQueryLog())->not->toBeEmpty();
});

it('starts with clean clocks bindings listeners query logs guards and log configuration', function (): void {
    expect(Carbon::hasTestNow())->toBeFalse()
        ->and(CarbonImmutable::hasTestNow())->toBeFalse()
        ->and(date_default_timezone_get())->toBe(config('app.timezone'))
        ->and(app()->bound('isolation.probe'))->toBeFalse()
        ->and(Event::hasListeners('isolation.probe'))->toBeFalse()
        ->and(DB::getQueryLog())->toBe([])
        ->and(app('auth')->guard('sanctum')->user())->toBeNull()
        ->and(config('logging.channels.single.path'))->toBe($this->resources->log);
});
