<?php

declare(strict_types=1);

use App\Expense\Presentation\Http\Controllers\CreateExpenseController;
use App\Expense\Presentation\Http\Controllers\DeleteExpenseController;
use App\Expense\Presentation\Http\Controllers\ListExpensesController;
use App\Expense\Presentation\Http\Controllers\UpdateExpenseController;
use Illuminate\Support\Facades\Route;

Route::prefix('expenses')->middleware(['auth:sanctum', 'user.active', 'throttle:api.authenticated'])->group(function (): void {
    Route::post(uri: '/', action: CreateExpenseController::class)
        ->name(name: 'expenses.create');

    Route::get(uri: '/', action: ListExpensesController::class)
        ->name(name: 'expenses.index');

    Route::patch(uri: '{expense}', action: UpdateExpenseController::class)
        ->whereNumber(parameters: 'expense')
        ->name(name: 'expenses.update');

    Route::delete(uri: '{expense}', action: DeleteExpenseController::class)
        ->whereNumber(parameters: 'expense')
        ->name(name: 'expenses.delete');
});
