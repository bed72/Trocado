<?php

declare(strict_types=1);

use App\Metrics\Presentation\Http\Controllers\GetExpenseMetricsController;
use Illuminate\Support\Facades\Route;

Route::get(uri: 'metrics/expenses', action: GetExpenseMetricsController::class)
    ->middleware(['auth:sanctum', 'request.authenticated', 'user.active', 'verified', 'throttle:api.authenticated', 'session.extend'])
    ->name(name: 'metrics.expenses');
