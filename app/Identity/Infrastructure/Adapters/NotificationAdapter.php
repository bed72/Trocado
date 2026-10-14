<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Exceptions\InactiveUserException;
use App\Identity\Application\Exceptions\UnverifiedEmailException;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\SessionPolicyValueObject;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use App\Notifications\Application\Ports\NotificationPort;
use DateTimeImmutable;
use DateTimeInterface;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Laravel\Sanctum\PersonalAccessToken;

final readonly class NotificationAdapter implements NotificationPort
{
    public function __construct(private AuthManager $manager, private SessionPolicyValueObject $policy) {}

    public function lock(int $userId, DateTimeImmutable $reference): int
    {
        $principal = $this->manager->guard('sanctum')->user();
        $token = $principal instanceof UserModel ? $principal->currentAccessToken() : null;

        if (! $token instanceof PersonalAccessToken) {
            throw new AuthenticationException;
        }

        $session = $token->newQuery()->whereKey($token->getKey())->lockForUpdate()->first();
        $issuedAt = $session?->getAttribute('created_at');
        $expiresAt = $session?->getAttribute('expires_at');

        if (! $session instanceof PersonalAccessToken
            || (int) $session->getAttribute('tokenable_id') !== $userId
            || $session->getAttribute('tokenable_type') !== $principal->getMorphClass()
            || ! $issuedAt instanceof DateTimeInterface
            || ! $expiresAt instanceof DateTimeInterface
            || ! $this->policy->isValid(
                DateTimeImmutable::createFromInterface($issuedAt),
                DateTimeImmutable::createFromInterface($expiresAt),
                $reference,
            )) {
            throw new AuthenticationException;
        }

        $user = UserModel::query()->find($userId);

        if (! $user instanceof UserModel) {
            throw new AuthenticationException;
        }

        if ($user->status !== UserStatusEnum::Active) {
            throw new InactiveUserException($user->status);
        }

        if (! $user->hasVerifiedEmail()) {
            throw new UnverifiedEmailException;
        }

        return (int) $session->getKey();
    }
}
