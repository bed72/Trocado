<?php

declare(strict_types=1);

use App\Identity\Presentation\Http\Controllers\DeleteUserController;
use App\Identity\Presentation\Http\Controllers\GetAllUsersController;
use App\Identity\Presentation\Http\Controllers\GetUserController;
use App\Identity\Presentation\Http\Controllers\SignInController;
use App\Identity\Presentation\Http\Controllers\SignOutController;
use App\Identity\Presentation\Http\Controllers\SignUpController;
use App\Identity\Presentation\Http\Controllers\UpdateUserController;
use Illuminate\Support\Facades\Route;

Route::prefix('users')->middleware('auth:sanctum')->name('users.')->group(function (): void {
    Route::get(uri: '/', action: GetAllUsersController::class)->name(name: 'get-all');
    Route::get(uri: '{user}', action: GetUserController::class)->whereNumber(parameters: 'user')->name(name: 'get');
    Route::patch(uri: '{user}', action: UpdateUserController::class)->whereNumber(parameters: 'user')->name(name: 'update');
    Route::delete(uri: '{user}', action: DeleteUserController::class)->whereNumber(parameters: 'user')->name(name: 'delete');
});

Route::prefix('authentication')->name('authentication.api.')->group(function (): void {
    Route::post(uri: 'sign-up', action: SignUpController::class)->name(name: 'sign-up');
    Route::post(uri: 'sign-in', action: SignInController::class)->name(name: 'sign-in');
    Route::delete(uri: 'sign-out', action: SignOutController::class)
        ->middleware('auth:sanctum')
        ->name(name: 'sign-out');
});
