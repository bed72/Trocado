<?php

declare(strict_types=1);

use App\Identity\Presentation\Http\Controllers\DeleteUserController;
use App\Identity\Presentation\Http\Controllers\GetUserController;
use App\Identity\Presentation\Http\Controllers\RequestPasswordRecoveryController;
use App\Identity\Presentation\Http\Controllers\ResendEmailVerificationController;
use App\Identity\Presentation\Http\Controllers\ResetPasswordController;
use App\Identity\Presentation\Http\Controllers\SignInController;
use App\Identity\Presentation\Http\Controllers\SignOutController;
use App\Identity\Presentation\Http\Controllers\SignUpController;
use App\Identity\Presentation\Http\Controllers\UpdateUserController;
use App\Identity\Presentation\Http\Controllers\VerifyEmailController;
use Illuminate\Support\Facades\Route;

Route::get(uri: 'email-verification/{id}/{hash}', action: VerifyEmailController::class)
    ->middleware('signed')
    ->where('id', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}')
    ->name(name: 'verification.verify');

Route::prefix('users')->middleware(['auth:sanctum', 'request.authenticated', 'user.active', 'verified', 'throttle:api.authenticated', 'session.extend'])->name('users.')->group(function (): void {
    Route::get(uri: '{user}', action: GetUserController::class)->where('user', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}')->name(name: 'get');
    Route::patch(uri: '{user}', action: UpdateUserController::class)->where('user', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}')->name(name: 'update');
    Route::delete(uri: '{user}', action: DeleteUserController::class)->where('user', '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}')->name(name: 'delete');
});

Route::prefix('authentication')->name('authentication.api.')->group(function (): void {
    Route::post(uri: 'sign-up', action: SignUpController::class)->middleware('throttle:authentication.sign-up')->name(name: 'sign-up');
    Route::post(uri: 'sign-in', action: SignInController::class)->middleware('throttle:authentication.sign-in')->name(name: 'sign-in');
    Route::post(uri: 'forgot-password', action: RequestPasswordRecoveryController::class)
        ->middleware('throttle:authentication.forgot-password')
        ->name(name: 'forgot-password');
    Route::post(uri: 'reset-password', action: ResetPasswordController::class)
        ->middleware('throttle:authentication.reset-password')
        ->name(name: 'reset-password');
    Route::post(uri: 'email-verification/resend', action: ResendEmailVerificationController::class)
        ->middleware('throttle:authentication.email-verification')
        ->name(name: 'email-verification.resend');
    Route::delete(uri: 'sign-out', action: SignOutController::class)
        ->middleware(['auth:sanctum', 'request.authenticated', 'user.active'])
        ->name(name: 'sign-out');
});
