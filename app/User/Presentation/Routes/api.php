<?php

declare(strict_types=1);

use App\User\Presentation\Http\Controllers\CreateUserController;
use App\User\Presentation\Http\Controllers\DeleteUserController;
use App\User\Presentation\Http\Controllers\GetAllUsersController;
use App\User\Presentation\Http\Controllers\GetUserController;
use App\User\Presentation\Http\Controllers\UpdateUserController;
use Illuminate\Support\Facades\Route;

Route::prefix('users')->name('users.')->group(function (): void {
    Route::post(uri: '/', action: CreateUserController::class)->name(name: 'create');
    Route::get(uri: '/', action: GetAllUsersController::class)->name(name: 'get-all');
    Route::get(uri: '{user}', action: GetUserController::class)->whereNumber(parameters: 'user')->name(name: 'get');
    Route::patch(uri: '{user}', action: UpdateUserController::class)->whereNumber(parameters: 'user')->name(name: 'update');
    Route::delete(uri: '{user}', action: DeleteUserController::class)->whereNumber(parameters: 'user')->name(name: 'delete');
});
