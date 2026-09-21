<?php

declare(strict_types=1);

use App\Budget\Presentation\Http\Controllers\CreateBudgetController;
use App\Budget\Presentation\Http\Controllers\DeleteBudgetController;
use App\Budget\Presentation\Http\Controllers\EndBudgetRecurrenceController;
use App\Budget\Presentation\Http\Controllers\GetAllBudgetsController;
use App\Budget\Presentation\Http\Controllers\GetBudgetController;
use App\Budget\Presentation\Http\Controllers\GetBudgetRecurrenceController;
use App\Budget\Presentation\Http\Controllers\ResumeBudgetRecurrenceController;
use App\Budget\Presentation\Http\Controllers\UpdateBudgetController;
use App\Budget\Presentation\Http\Controllers\UpdateBudgetRecurrenceController;
use Illuminate\Support\Facades\Route;

Route::prefix('budgets')->name('budgets.')->group(function (): void {
    Route::post(uri: '/', action: CreateBudgetController::class)->name(name: 'create');
    Route::get(uri: '/', action: GetAllBudgetsController::class)->name(name: 'get-all');
    Route::get(uri: '{budget}', action: GetBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'get');
    Route::patch(uri: '{budget}', action: UpdateBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'update');
    Route::delete(uri: '{budget}', action: DeleteBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'delete');
});

Route::prefix('budget-recurrences')->name('budget-recurrences.')->group(function (): void {
    Route::get(uri: '{recurrence}', action: GetBudgetRecurrenceController::class)->whereNumber(parameters: 'recurrence')->name(name: 'get');
    Route::post(uri: '{recurrence}/end', action: EndBudgetRecurrenceController::class)->whereNumber(parameters: 'recurrence')->name(name: 'end');
    Route::patch(uri: '{recurrence}', action: UpdateBudgetRecurrenceController::class)->whereNumber(parameters: 'recurrence')->name(name: 'update');
    Route::post(uri: '{recurrence}/resume', action: ResumeBudgetRecurrenceController::class)->whereNumber(parameters: 'recurrence')->name(name: 'resume');
});
