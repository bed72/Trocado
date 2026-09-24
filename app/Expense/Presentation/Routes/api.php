<?php

declare(strict_types=1);

use App\Expense\Presentation\Http\Controllers\CreateExpenseController;
use App\Expense\Presentation\Http\Controllers\ListOwnedExpensesController;
use Illuminate\Support\Facades\Route;

Route::prefix('expenses')->middleware('auth:sanctum')->group(function (): void {
    Route::post(uri: '/', action: CreateExpenseController::class)
        ->name(name: 'expenses.create');

    Route::get(uri: '/', action: ListOwnedExpensesController::class)
        ->name(name: 'expenses.index');
});
