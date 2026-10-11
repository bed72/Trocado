<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\SessionPort;
use App\Identity\Domain\ValueObjects\SessionPolicyValueObject;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use DateTimeImmutable;
use DateTimeInterface;
use Illuminate\Auth\AuthManager;
use Illuminate\Support\Facades\Date;
use Laravel\Sanctum\PersonalAccessToken;

final readonly class SessionAdapter implements SessionPort
{
    public function __construct(private AuthManager $manager, private SessionPolicyValueObject $policy) {}

    public function extendCurrentToken(): void
    {
        $user = $this->manager->guard(name: 'sanctum')->user();
        $token = $user instanceof UserModel ? $user->currentAccessToken() : null;

        if (! $token instanceof PersonalAccessToken) {
            return;
        }

        $token->getConnection()->transaction(function () use ($token): void {
            $current = $token->newQuery()->whereKey($token->getKey())->lockForUpdate()->first();

            if (! $current instanceof PersonalAccessToken) {
                return;
            }

            $expiresAt = $current->getAttribute('expires_at');
            $createdAt = $current->getAttribute('created_at');

            if (! $expiresAt instanceof DateTimeInterface || ! $createdAt instanceof DateTimeInterface) {
                return;
            }

            $newExpiry = $this->policy->extendedExpiry(
                issuedAt: DateTimeImmutable::createFromInterface($createdAt),
                expiresAt: DateTimeImmutable::createFromInterface($expiresAt),
                reference: DateTimeImmutable::createFromInterface(Date::now()),
            );

            if ($newExpiry !== null) {
                $current->forceFill(['expires_at' => $newExpiry]);
                $current->save();
            }
        });
    }
}
