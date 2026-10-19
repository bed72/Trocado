<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\InactiveUserException;
use App\Identity\Application\Exceptions\InvalidCredentialsException;
use App\Identity\Application\Exceptions\UnverifiedEmailException;
use App\Identity\Application\Exceptions\UserNotFoundException;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\Exceptions\InvalidAvatarException;
use App\Identity\Domain\Exceptions\InvalidEmailException;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use Illuminate\Contracts\Debug\ExceptionHandler;
use Illuminate\Support\Facades\Route;
use Throwable as ThrowableContract;

it('preserves the exact Identity translation and report policy inside and outside the API', function (ThrowableContract $exception, int $status, string $title, string $detail, ?string $pointer, bool $reported, string $path): void {
    Route::get($path, static fn () => throw $exception);

    $error = ['title' => $title, 'detail' => $detail, 'status' => (string) $status];
    if ($pointer !== null) {
        $error['source'] = ['pointer' => $pointer];
    }

    $this->get($path, ['Accept' => 'text/html'])->assertStatus($status)
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [$error]]);
    expect($this->app->make(ExceptionHandler::class)->shouldReport($exception))->toBe($reported);
})->with([
    'credentials' => [new InvalidCredentialsException, 401, 'Credenciais inválidas', 'As credenciais informadas são inválidas.', null, false],
    'verification' => [new UnverifiedEmailException, 403, 'E-mail não confirmado', 'O endereço de e-mail ainda não foi confirmado.', null, false],
    'pending' => [new InactiveUserException(UserStatusEnum::Pending), 403, 'Conta pendente', 'A conta aguarda ativação.', null, false],
    'blocked' => [new InactiveUserException(UserStatusEnum::Blocked), 403, 'Conta bloqueada', 'A conta está bloqueada.', null, false],
    'active branch' => [new InactiveUserException(UserStatusEnum::Active), 403, 'Acesso negado', 'A conta não está disponível.', null, false],
    'email conflict first renderer' => [new EmailAlreadyUsedException, 409, 'E-mail já utilizado', 'Não foi possível utilizar o e-mail informado.', '/data/attributes/email', false],
    'missing user' => [new UserNotFoundException, 404, 'User não encontrado', 'User não encontrado.', null, true],
    'password' => [new InvalidPasswordException('Senha de caracterização.'), 422, 'Dados inválidos', 'Senha de caracterização.', '/data/attributes/password', false],
    'email' => [new InvalidEmailException('E-mail de caracterização.'), 422, 'Dados inválidos', 'E-mail de caracterização.', null, true],
    'name' => [new InvalidNameException('Nome de caracterização.'), 422, 'Dados inválidos', 'Nome de caracterização.', null, true],
    'avatar' => [new InvalidAvatarException('Avatar de caracterização.'), 422, 'Dados inválidos', 'Avatar de caracterização.', '/data/attributes/avatar', true],
])->with(['api' => '/api/identity-error-probe', 'non-api' => '/identity-error-probe']);
