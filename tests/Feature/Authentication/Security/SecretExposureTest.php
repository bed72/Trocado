<?php

declare(strict_types=1);

use App\Authentication\Application\Exceptions\InvalidCredentialsException;
use App\Authentication\Application\Exceptions\SignUpEmailAlreadyUsedException;
use App\Authentication\Application\Ports\SignInPort;
use App\Authentication\Application\Ports\SignUpPort;
use App\Authentication\Application\UseCases\SignInUseCase;
use App\Authentication\Application\UseCases\SignUpUseCase;
use App\Authentication\Domain\Exceptions\InvalidPasswordException;
use App\Authentication\Infrastructure\Adapters\SignInAdapter;
use App\Authentication\Infrastructure\Adapters\SignUpAdapter;
use Illuminate\Foundation\Exceptions\Handler;

it('does not report expected authentication failures', function (): void {
    $handler = app(Handler::class);

    expect($handler->shouldReport(new InvalidCredentialsException))->toBeFalse()
        ->and($handler->shouldReport(new SignUpEmailAlreadyUsedException))->toBeFalse()
        ->and($handler->shouldReport(new InvalidPasswordException('Senha inválida.')))->toBeFalse();
});

it('marks every production password parameter as sensitive', function (string $class, string $method): void {
    $parameter = collect((new ReflectionMethod($class, $method))->getParameters())
        ->first(fn (ReflectionParameter $parameter): bool => $parameter->getName() === 'password');

    expect($parameter)->toBeInstanceOf(ReflectionParameter::class)
        ->and($parameter->getAttributes(SensitiveParameter::class))->toHaveCount(1);
})->with([
    [SignInPort::class, 'issue'],
    [SignUpPort::class, 'create'],
    [SignInUseCase::class, 'execute'],
    [SignUpUseCase::class, 'execute'],
    [SignInAdapter::class, 'issue'],
    [SignUpAdapter::class, 'create'],
]);
