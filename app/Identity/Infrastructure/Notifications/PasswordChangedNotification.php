<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Notifications;

use App\Identity\Infrastructure\Adapters\PasswordRecoveryMailChannelAdapter;
use App\Identity\Infrastructure\Queues\Middleware\PasswordRecoveryNotificationMiddleware;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeEncrypted;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Queue\Attributes\DeleteWhenMissingModels;

#[DeleteWhenMissingModels]
final class PasswordChangedNotification extends Notification implements ShouldBeEncrypted, ShouldQueue
{
    use Queueable;

    public function __construct(private readonly string $expectedEmail)
    {
        $this->onConnection('redis');
        $this->afterCommit();
    }

    /** @return list<class-string> */
    public function via(object $notifiable): array
    {
        return [PasswordRecoveryMailChannelAdapter::class];
    }

    /** @return list<class-string> */
    public function middleware(object $notifiable, string $channel): array
    {
        return [PasswordRecoveryNotificationMiddleware::class];
    }

    public function shouldSend(object $notifiable, string $channel): bool
    {
        return $channel === PasswordRecoveryMailChannelAdapter::class
            && $notifiable->getEmailForPasswordReset() === $this->expectedEmail;
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Sua senha foi alterada no Trocado')
            ->view(['mail.identity.password-changed', 'mail.identity.password-changed-text']);
    }
}
