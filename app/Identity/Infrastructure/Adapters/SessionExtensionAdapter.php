<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\SessionExtensionPort;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use DateTimeImmutable;
use DateTimeInterface;
use Illuminate\Auth\AuthManager;
use Illuminate\Support\Facades\Date;
use Laravel\Sanctum\PersonalAccessToken;

final readonly class SessionExtensionAdapter implements SessionExtensionPort
{
    public function __construct(private AuthManager $manager) {}

    public function extendCurrentToken(int $windowDays, int $validityDays, int $maximumAgeDays): void
    {
        $user = $this->manager->guard(name: 'sanctum')->user();
        $token = $user instanceof UserModel ? $user->currentAccessToken() : null;

        if (! $token instanceof PersonalAccessToken) {
            return;
        }

        $token->getConnection()->transaction(function () use ($token, $windowDays, $validityDays, $maximumAgeDays): void {
            $current = $token->newQuery()->whereKey($token->getKey())->lockForUpdate()->first();

            if (! $current instanceof PersonalAccessToken) {
                return;
            }

            $expiresAt = $current->getAttribute('expires_at');
            $createdAt = $current->getAttribute('created_at');

            if (! $expiresAt instanceof DateTimeInterface || ! $createdAt instanceof DateTimeInterface) {
                return;
            }

            $now = DateTimeImmutable::createFromInterface(Date::now());
            $absoluteExpiry = DateTimeImmutable::createFromInterface($createdAt)->modify('+'.min($maximumAgeDays, 90).' days');

            if ($expiresAt <= $now || $absoluteExpiry <= $now
                || $expiresAt > $now->modify("+$windowDays days")) {
                return;
            }

            $newExpiry = min($now->modify("+$validityDays days"), $absoluteExpiry);

            if ($newExpiry > $expiresAt) {
                $current->forceFill(['expires_at' => $newExpiry]);
                $current->save();
            }
        });
    }
}
