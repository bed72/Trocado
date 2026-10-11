<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence;

use App\Identity\Application\Data\EmailVerificationOutput;
use App\Identity\Application\Repositories\EmailVerificationRepository;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;

final class EloquentEmailVerificationRepository implements EmailVerificationRepository
{
    public function verify(int $userId, string $hash): EmailVerificationOutput
    {
        $user = UserModel::query()->lockForUpdate()->find(id: $userId);

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
