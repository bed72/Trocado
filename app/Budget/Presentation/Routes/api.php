<?php

declare(strict_types=1);

use App\Budget\Presentation\Http\Controllers\CreateBudgetController;
use App\Budget\Presentation\Http\Controllers\DeleteBudgetController;
use App\Budget\Presentation\Http\Controllers\GetAllBudgetsController;
use App\Budget\Presentation\Http\Controllers\GetBudgetController;
use App\Budget\Presentation\Http\Controllers\UpdateBudgetController;
use Illuminate\Support\Facades\Route;

Route::prefix('budgets')->name('budgets.')->group(function (): void {
    Route::post(uri: '/', action: CreateBudgetController::class)->name(name: 'create');
    Route::get(uri: '/', action: GetAllBudgetsController::class)->name(name: 'get-all');
    Route::get(uri: '{budget}', action: GetBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'get');
    Route::patch(uri: '{budget}', action: UpdateBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'update');
    Route::delete(uri: '{budget}', action: DeleteBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'delete');
});
