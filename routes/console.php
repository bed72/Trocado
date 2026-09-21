<?php

use App\Budget\Infrastructure\Console\Commands\ProcessDueBudgetRecurrencesCommand;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command(ProcessDueBudgetRecurrencesCommand::class)
    ->daily()
    ->withoutOverlapping();
