<?php

declare(strict_types=1);

use App\Notifications\Application\Exceptions\NotificationRegistrationConflictException;
use App\Notifications\Application\Exceptions\NotificationRegistrationNotFoundException;
use App\Notifications\Domain\Exceptions\InvalidNotificationRegistrationException;
use Illuminate\Contracts\Debug\ExceptionHandler;
use Illuminate\Support\Facades\Route;
use Throwable as ThrowableContract;

it('preserves the exact Notifications translation and report policy inside and outside the API', function (ThrowableContract $exception, int $status, string $title, string $detail, ?string $pointer, string $path): void {
    Route::get($path, static fn () => throw $exception);
    $error = ['title' => $title, 'detail' => $detail, 'status' => (string) $status];
    if ($pointer !== null) {
        $error['source'] = ['pointer' => $pointer];
    }

    $this->get($path, ['Accept' => 'text/html'])->assertStatus($status)
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['errors' => [$error]]);
    expect($this->app->make(ExceptionHandler::class)->shouldReport($exception))->toBeFalse();
})->with([
    'conflict' => [new NotificationRegistrationConflictException, 409, 'Conflito de registro push', 'A instalação ou o destino já possui um vínculo incompatível.', null],
    'missing' => [new NotificationRegistrationNotFoundException, 404, 'Registro push não encontrado', 'O registro push não foi encontrado.', null],
    'invalid installation' => [new InvalidNotificationRegistrationException('installation_id'), 422, 'Registro push inválido', 'O campo do registro push é inválido.', '/data/attributes/installation_id'],
    'invalid destination' => [new InvalidNotificationRegistrationException('registration_identifier'), 422, 'Registro push inválido', 'O campo do registro push é inválido.', '/data/attributes/registration_identifier'],
])->with(['api' => '/api/notification-error-probe', 'non-api' => '/notification-error-probe']);
