<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence;

use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Application\Data\Output\EmailVerificationOutput;
use App\Identity\Application\Repositories\EmailVerificationRepository;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;

final class EloquentEmailVerificationRepository implements EmailVerificationRepository
{
    public function verify(string $userId, string $hash): EmailVerificationOutput
    {
        $id = UuidValueObject::fromString($userId)->value();
        $user = UserModel::query()->lockForUpdate()->find(id: $id);

        if ($user === null || ! hash_equals(sha1($user->getEmailForVerification()), $hash)) {
            return new EmailVerificationOutput(isValid: false, wasVerifiedNow: false);
        }

        if ($user->hasVerifiedEmail()) {
            return new EmailVerificationOutput(isValid: true, wasVerifiedNow: false);
        }

        $verified = $user->markEmailAsVerified();

        return new EmailVerificationOutput(isValid: $verified, wasVerifiedNow: $verified);
    }
}
