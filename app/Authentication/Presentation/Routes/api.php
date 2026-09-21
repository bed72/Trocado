<?php

declare(strict_types=1);

use App\Authentication\Presentation\Http\Controllers\SignInController;
use App\Authentication\Presentation\Http\Controllers\SignOutController;
use App\Authentication\Presentation\Http\Controllers\SignUpController;
use Illuminate\Support\Facades\Route;

Route::prefix('authentication')->name('authentication.api.')->group(function (): void {
    Route::post(uri: 'sign-up', action: SignUpController::class)->name(name: 'sign-up');
    Route::post(uri: 'sign-in', action: SignInController::class)->name(name: 'sign-in');
    Route::delete(uri: 'sign-out', action: SignOutController::class)
        ->middleware('auth:sanctum')
        ->name(name: 'sign-out');
});
