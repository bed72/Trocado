<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Carbon\CarbonImmutable;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['identity.password_recovery.url' => 'https://app.example.com/reset', 'mail.default' => 'array']);
    Queue::fake();
    $this->payload = ['data' => ['type' => 'password-recovery-requests', 'attributes' => ['email' => 'maria@example.com']]];
    $this->accepted = ['meta' => ['message' => 'Se a conta estiver apta, enviaremos as instruções de recuperação.']];
});

it('counts accepted and invalid requests before validation and refuses the seventh request without issuance', function (): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    $url = route('authentication.api.forgot-password');
    $missing = $this->payload;
    $missing['data']['attributes']['email'] = 'missing@example.com';
    for ($attempt = 0; $attempt < 3; $attempt++) {
        $this->postJson($url, $missing)->assertAccepted()->assertExactJson($this->accepted);
        $this->postJson($url, [])->assertUnprocessable();
    }

    $this->postJson($url, $this->payload)->assertTooManyRequests()
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertHeader('Retry-After', '600')
        ->assertExactJson(['errors' => [[
            'title' => 'Muitas solicitações', 'detail' => 'O limite de solicitações foi excedido. Tente novamente mais tarde.', 'status' => '429',
        ]]]);
    $this->postJson($url, [])->assertTooManyRequests();
    expect(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertNothingPushed();
});

it('counts successful issuance and suppressed requests without rotating at the IP quota boundary', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $url = route('authentication.api.forgot-password');
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson($url, $this->payload)->assertAccepted()->assertExactJson($this->accepted);
    }
    $before = (array) DB::table('password_reset_tokens')->sole();
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $this->postJson($url, $this->payload)->assertTooManyRequests()->assertHeader('Retry-After', '540');
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($before)->and($user->tokens()->count())->toBe(0);
    Queue::assertPushed(SendQueuedNotifications::class, 1);
});

it('separates IPs and existing authentication quotas and reopens exactly after ten minutes', function (): void {
    $url = route('authentication.api.forgot-password');
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson($url, $this->payload)->assertAccepted();
    }
    $this->postJson($url, $this->payload)->assertTooManyRequests();
    $this->postJson(route('authentication.api.sign-in'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-up'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.email-verification.resend'), [])->assertUnprocessable();

    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.20'])->postJson($url, $this->payload)->assertAccepted();
    $this->withServerVariables(['REMOTE_ADDR' => '127.0.0.1']);
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:09:59 UTC'));
    $this->postJson($url, $this->payload)->assertTooManyRequests()->assertHeader('Retry-After', '1');
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:10:00 UTC'));
    $this->postJson($url, $this->payload)->assertAccepted()->assertExactJson($this->accepted);
    Queue::assertNothingPushed();
});

it('shares the canonical email suppression interval across different IPs without renewing the deadline', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $url = route('authentication.api.forgot-password');
    $this->postJson($url, $this->payload)->assertAccepted()->assertExactJson($this->accepted);
    $first = (array) DB::table('password_reset_tokens')->sole();
    $firstToken = Queue::pushed(SendQueuedNotifications::class)->sole()->notification->toMail($user)->actionUrl;
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:59 UTC'));
    $this->payload['data']['attributes']['email'] = ' MARIA@EXAMPLE.COM ';
    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.21'])->postJson($url, $this->payload)
        ->assertAccepted()->assertExactJson($this->accepted);
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($first);
    Queue::assertPushed(SendQueuedNotifications::class, 1);

    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.22'])->postJson($url, $this->payload)
        ->assertAccepted()->assertExactJson($this->accepted);
    Queue::assertPushed(SendQueuedNotifications::class, 2);
    $current = DB::table('password_reset_tokens')->sole();
    parse_str(parse_url($firstToken, PHP_URL_QUERY), $oldQuery);
    $newUrl = Queue::pushed(SendQueuedNotifications::class)->last()->notification->toMail($user)->actionUrl;
    parse_str(parse_url($newUrl, PHP_URL_QUERY), $newQuery);
    expect($current->created_at)->toBe('2026-10-21 12:01:00')
        ->and(Hash::check($oldQuery['token'], $current->token))->toBeFalse()
        ->and(Hash::check($newQuery['token'], $current->token))->toBeTrue();
});
