<?php

declare(strict_types=1);

use App\Expense\Presentation\Http\Controllers\CreateExpenseController;
use Illuminate\Support\Facades\Route;

Route::post(uri: 'expenses', action: CreateExpenseController::class)
    ->middleware('auth:sanctum')
    ->name(name: 'expenses.create');
