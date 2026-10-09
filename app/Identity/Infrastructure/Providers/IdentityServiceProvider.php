<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Providers;

use App\Identity\Application\Ports\EmailVerificationPort;
use App\Identity\Application\Ports\SessionExtensionPort;
use App\Identity\Application\Ports\SignInPort;
use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Infrastructure\Adapters\EmailVerificationAdapter;
use App\Identity\Infrastructure\Adapters\SessionExtensionAdapter;
use App\Identity\Infrastructure\Adapters\SignInAdapter;
use App\Identity\Infrastructure\Adapters\SignOutAdapter;
use App\Identity\Infrastructure\Repositories\Persistence\EloquentUserRepository;
use DateTimeImmutable;
use DateTimeInterface;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;

use function is_string;

final class IdentityServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(abstract: SignInPort::class, concrete: SignInAdapter::class);
        $this->app->bind(abstract: SignOutPort::class, concrete: SignOutAdapter::class);
        $this->app->bind(abstract: UserRepository::class, concrete: EloquentUserRepository::class);
        $this->app->bind(abstract: SessionExtensionPort::class, concrete: SessionExtensionAdapter::class);
        $this->app->bind(abstract: EmailVerificationPort::class, concrete: EmailVerificationAdapter::class);
    }

    public function boot(): void
    {
        Model::preventLazyLoading(! $this->app->environment('production'));

        Sanctum::authenticateAccessTokensUsing(function (PersonalAccessToken $token, bool $isValid): bool {
            $expiresAt = $token->getAttribute('expires_at');
            $createdAt = $token->getAttribute('created_at');

            if (! $isValid || ! $expiresAt instanceof DateTimeInterface || ! $createdAt instanceof DateTimeInterface) {
                return false;
            }

            $now = DateTimeImmutable::createFromInterface(Date::now());

            return $expiresAt > $now
                && DateTimeImmutable::createFromInterface($createdAt)->modify('+90 days') > $now;
        });

        RateLimiter::for('authentication.sign-up', fn (Request $request): Limit => Limit::perHour(
            Config::integer('identity.sign_up.per_hour'),
        )
            ->by('sign-up:ip:'.$request->ip()));

        RateLimiter::for('authentication.sign-in', function (Request $request): array {
            $ip = $request->ip();
            $email = $request->input('data.attributes.email');
            $canonicalEmail = is_string($email) ? strtolower(trim($email)) : '';
            $identifier = hash('sha256', "$ip|$canonicalEmail");

            return [
                Limit::perMinute(30)->by("sign-in:ip:$ip"),
                Limit::perMinute(5)->by("sign-in:email:$identifier"),
            ];
        });

        RateLimiter::for('authentication.email-verification', function (Request $request): array {
            $ip = $request->ip();
            $email = $request->input('data.attributes.email');
            $canonicalEmail = is_string($email) ? strtolower(trim($email)) : '';
            $identifier = hash('sha256', "$ip|$canonicalEmail");

            return [
                Limit::perHour(5)->by("email-verification:ip:$ip"),
                Limit::perHour(2)->by("email-verification:email:$identifier"),
            ];
        });
    }
}
