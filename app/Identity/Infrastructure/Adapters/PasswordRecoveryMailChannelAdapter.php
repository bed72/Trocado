<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use Illuminate\Contracts\Config\Repository;
use Illuminate\Mail\MailManager;
use Illuminate\Mail\Transport\LogTransport;
use Illuminate\Notifications\Channels\MailChannel;
use Illuminate\Notifications\Notification;
use Illuminate\Support\ConfigurationUrlParser;
use RuntimeException;
use SensitiveParameter;
use Throwable;

use function in_array;

final readonly class PasswordRecoveryMailChannelAdapter
{
    public function __construct(private MailChannel $channel, private MailManager $manager, private Repository $repository) {}

    public function assertAvailable(): void
    {
        $name = $this->repository->get('mail.default');
        $config = $this->repository->get("mail.mailers.{$name}", []);
        $transport = $config['transport'] ?? null;

        if (isset($config['url'])) {
            $config = [...$config, ...(new ConfigurationUrlParser)->parseConfiguration($config)];
            $transport = $config['transport'] = $config['driver'] ?? null;
        }

        if (! in_array($transport, ['smtp', 'smtps', 'sendmail', 'ses', 'ses-v2', 'postmark', 'resend', 'mailgun', 'array'], true)
            || ($transport === 'array' && $this->repository->get('app.env') === 'production')) {
            throw new RuntimeException('O transporte de recuperação de senha não está disponível.');
        }

        $resolved = $this->manager->mailer()->getSymfonyTransport();
        $expected = $this->manager->createSymfonyTransport($config);

        if ($resolved instanceof LogTransport || $resolved::class !== $expected::class) {
            throw new RuntimeException('O transporte de recuperação de senha não está disponível.');
        }
    }

    public function send(#[SensitiveParameter] object $notifiable, #[SensitiveParameter] Notification $notification): mixed
    {
        try {
            $this->assertAvailable();

            return $this->channel->send($notifiable, $notification);
        } catch (Throwable) {
            throw new RuntimeException('Não foi possível entregar a notificação de recuperação de senha.');
        }
    }
}
