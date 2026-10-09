<?php

declare(strict_types=1);

use App\Insights\Presentation\Http\Controllers\GetInsightsController;
use Illuminate\Support\Facades\Route;

Route::get(uri: 'insights', action: GetInsightsController::class)
    ->middleware(['auth:sanctum', 'request.authenticated', 'user.active', 'verified', 'throttle:api.authenticated', 'session.extend'])
    ->name(name: 'insights.index');
