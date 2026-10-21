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
use SensitiveParameter;

#[DeleteWhenMissingModels]
final class PasswordRecoveryNotification extends Notification implements ShouldBeEncrypted, ShouldQueue
{
    use Queueable;

    public function __construct(private readonly string $expectedEmail, #[SensitiveParameter] private readonly string $url)
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
            ->subject('Recuperação de senha do Trocado')
            ->action('Redefinir senha', $this->url)
            ->view(
                ['mail.identity.password-recovery', 'mail.identity.password-recovery-text'],
                ['recoveryUrl' => $this->url],
            );
    }
}
