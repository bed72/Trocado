<?php

declare(strict_types=1);

use App\Budget\Presentation\Http\Controllers\CreateBudgetController;
use App\Budget\Presentation\Http\Controllers\DeleteBudgetController;
use App\Budget\Presentation\Http\Controllers\GetBudgetController;
use App\Budget\Presentation\Http\Controllers\ListBudgetsController;
use App\Budget\Presentation\Http\Controllers\UpdateBudgetController;
use Illuminate\Support\Facades\Route;

Route::get(uri: 'budgets', action: ListBudgetsController::class)->name(name: 'budgets.index');
Route::post(uri: 'budgets', action: CreateBudgetController::class)->name(name: 'budgets.store');
Route::get(uri: 'budgets/{budget}', action: GetBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'budgets.show');
Route::patch(uri: 'budgets/{budget}', action: UpdateBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'budgets.update');
Route::delete(uri: 'budgets/{budget}', action: DeleteBudgetController::class)->whereNumber(parameters: 'budget')->name(name: 'budgets.destroy');
