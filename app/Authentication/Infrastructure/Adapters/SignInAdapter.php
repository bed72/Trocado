<?php

declare(strict_types=1);

namespace App\Authentication\Infrastructure\Adapters;

use App\Authentication\Application\Exceptions\InvalidCredentialsException;
use App\Authentication\Application\Ports\SignInPort;
use App\User\Domain\Exceptions\InvalidEmailException;
use App\User\Domain\ValueObjects\EmailValueObject;
use App\User\Infrastructure\Persistence\Models\UserModel;
use DateTimeImmutable;
use Illuminate\Auth\AuthManager;
use Illuminate\Contracts\Config\Repository;
use Illuminate\Support\Facades\Date;
use RuntimeException;
use SensitiveParameter;
use Throwable;

final readonly class SignInAdapter implements SignInPort
{
    public function __construct(
        private AuthManager $auth,
        private Repository $repository,
    ) {}

    public function issue(string $email, #[SensitiveParameter] string $password): array
    {
        try {
            $canonicalEmail = EmailValueObject::fromString(value: $email)->value();
        } catch (InvalidEmailException) {
            throw new InvalidCredentialsException;
        }

        $provider = $this->auth->createUserProvider(
            provider: $this->repository->get(key: 'auth.guards.web.provider'),
        );

        if ($provider === null) {
            throw new RuntimeException(message: 'O provider de autenticação não está configurado.');
        }

        try {
            $credentials = ['email' => $canonicalEmail, 'password' => $password];
            $user = $provider->retrieveByCredentials(credentials: $credentials);

            if (! $user instanceof UserModel || ! $provider->validateCredentials(user: $user, credentials: $credentials)) {
                throw new InvalidCredentialsException;
            }

            $provider->rehashPasswordIfRequired(user: $user, credentials: $credentials);

            $expiresAt = DateTimeImmutable::createFromInterface(
                object: Date::now()->addMinutes(
                    value: (int) $this->repository->get(key: 'sanctum.expiration', default: 120),
                ),
            );
            $accessToken = $user->createToken(name: 'api', abilities: [], expiresAt: $expiresAt);
        } catch (InvalidCredentialsException) {
            throw new InvalidCredentialsException;
        } catch (Throwable) {
            throw new RuntimeException(message: 'Não foi possível concluir a autenticação.');
        }

        return [
            'expiresAt' => $expiresAt,
            'userId' => (int) $user->getKey(),
            'plainTextToken' => $accessToken->plainTextToken,
            'id' => (int) $accessToken->accessToken->getKey(),
        ];
    }
}
