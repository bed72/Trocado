<?php

declare(strict_types=1);

use App\Expense\Presentation\Http\Controllers\CreateExpenseController;
use App\Expense\Presentation\Http\Controllers\DeleteExpenseController;
use App\Expense\Presentation\Http\Controllers\GetAllExpenseController;
use App\Expense\Presentation\Http\Controllers\GetExpenseController;
use App\Expense\Presentation\Http\Controllers\UpdateExpenseController;
use Illuminate\Support\Facades\Route;

Route::prefix('expenses')->middleware(['auth:sanctum', 'request.authenticated', 'user.active', 'verified', 'throttle:api.authenticated', 'session.extend'])->group(function (): void {
    Route::post(uri: '/', action: CreateExpenseController::class)
        ->name(name: 'expenses.create');

    Route::get(uri: '/', action: GetAllExpenseController::class)
        ->name(name: 'expenses.index');

    Route::get(uri: '{expense}', action: GetExpenseController::class)
        ->whereNumber(parameters: 'expense')
        ->name(name: 'expenses.show');

    Route::patch(uri: '{expense}', action: UpdateExpenseController::class)
        ->whereNumber(parameters: 'expense')
        ->name(name: 'expenses.update');

    Route::delete(uri: '{expense}', action: DeleteExpenseController::class)
        ->whereNumber(parameters: 'expense')
        ->name(name: 'expenses.delete');
});
