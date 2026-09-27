<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Notifications;

use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\Attributes\DeleteWhenMissingModels;

#[DeleteWhenMissingModels]
final class VerifyEmailNotification extends VerifyEmail implements ShouldQueue
{
    use Queueable;

    public function __construct(private readonly string $expectedEmail) {}

    public function shouldSend(object $notifiable, string $channel): bool
    {
        return $channel === 'mail'
            && $notifiable->getEmailForVerification() === $this->expectedEmail
            && ! $notifiable->hasVerifiedEmail();
    }
}
