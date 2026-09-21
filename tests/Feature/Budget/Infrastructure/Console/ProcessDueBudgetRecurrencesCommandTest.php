<?php

declare(strict_types=1);

use App\Budget\Application\Data\CreateBudgetInput;
use App\Budget\Application\UseCases\CreateBudgetUseCase;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Support\Carbon;

it('processes due recurrences synchronously using the application date', function (): void {
    app(CreateBudgetUseCase::class)->execute(input: new CreateBudgetInput(
        amount: 1000,
        startDate: '2026-01-01',
        endDate: '2026-01-07',
        recurring: true,
    ));
    config()->set('app.timezone', 'America/Sao_Paulo');
    Carbon::setTestNow('2026-01-08 01:00:00+00:00');

    $this->artisan('budgets:process-recurrences')
        ->expectsOutput('0 ocorrência(s) gerada(s).')
        ->assertSuccessful();

    Carbon::setTestNow('2026-01-08 03:00:00+00:00');

    $this->artisan('budgets:process-recurrences')
        ->expectsOutput('1 ocorrência(s) gerada(s).')
        ->assertSuccessful();

    $this->assertDatabaseHas('budgets', [
        'start_date' => '2026-01-08 00:00:00',
        'end_date' => '2026-01-14 00:00:00',
    ]);

    Carbon::setTestNow();
});

it('registers daily recurrence processing with operational overlap protection', function (): void {
    $event = collect(app(Schedule::class)->events())
        ->first(fn ($event): bool => str_contains($event->command ?? '', 'budgets:process-recurrences'));

    expect($event)->not->toBeNull()
        ->and($event->expression)->toBe('0 0 * * *')
        ->and($event->withoutOverlapping)->toBeTrue()
        ->and($event->command)->toContain('budgets:process-recurrences');
});
