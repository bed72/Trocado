<?php

declare(strict_types=1);

use Illuminate\Console\Scheduling\Schedule;

it('schedules daily pruning of expired Sanctum tokens', function (): void {
    $events = app(Schedule::class)->events();
    $pruneEvent = collect($events)->first(
        fn ($event): bool => str_contains($event->command ?? '', 'sanctum:prune-expired --hours=24'),
    );

    expect($pruneEvent)->not->toBeNull()
        ->and($pruneEvent->expression)->toBe('0 0 * * *');
});
