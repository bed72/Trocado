<?php

declare(strict_types=1);

use App\Identity\Application\Exceptions\EmailAlreadyUsedException;
use App\Identity\Application\Exceptions\InvalidCredentialsException;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Application\UseCases\SignInUseCase;
use App\Identity\Application\UseCases\SignUpUseCase;
use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Persistence\Repositories\EloquentUserRepository;
use Illuminate\Foundation\Exceptions\Handler;

it('does not report expected authentication failures', function (): void {
    $handler = app(Handler::class);

    expect($handler->shouldReport(new InvalidCredentialsException))->toBeFalse()
        ->and($handler->shouldReport(new EmailAlreadyUsedException))->toBeFalse()
        ->and($handler->shouldReport(new InvalidPasswordException('Senha inválida.')))->toBeFalse();
});

it('marks every production password parameter as sensitive', function (string $class, string $method): void {
    $parameter = collect((new ReflectionMethod($class, $method))->getParameters())
        ->first(fn (ReflectionParameter $parameter): bool => $parameter->getName() === 'password');

    expect($parameter)->toBeInstanceOf(ReflectionParameter::class)
        ->and($parameter->getAttributes(SensitiveParameter::class))->toHaveCount(1);
})->with([
    [SignInPort::class, 'issue'],
    [UserRepository::class, 'create'],
    [SignInAdapter::class, 'issue'],
    [SignInUseCase::class, 'execute'],
    [SignUpUseCase::class, 'execute'],
    [EloquentUserRepository::class, 'create'],
]);
