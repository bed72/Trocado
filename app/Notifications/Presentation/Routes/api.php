<?php

declare(strict_types=1);

use App\Notifications\Presentation\Http\Controllers\CreateNotificationController;
use App\Notifications\Presentation\Http\Controllers\DeleteNotificationController;
use Illuminate\Support\Facades\Route;

Route::prefix('push-registrations')->middleware([
    'auth:sanctum', 'request.authenticated', 'user.active', 'verified', 'throttle:api.authenticated',
])->group(function (): void {
    Route::post('/', CreateNotificationController::class)->name('notifications.api.push-registrations.register');
    Route::delete('{registration}', DeleteNotificationController::class)
        ->where('registration', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}')
        ->name('notifications.api.push-registrations.delete');
});
