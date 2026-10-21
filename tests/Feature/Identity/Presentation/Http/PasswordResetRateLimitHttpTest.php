<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['mail.default' => 'array']);
    Queue::fake();
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->user, now()->addDays(30));
    $this->native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    $this->token = $this->native->create($this->user);
    $this->payload = ['data' => ['type' => 'password-resets', 'attributes' => [
        'email' => 'maria@example.com', 'token' => $this->token,
        'password' => 'Newpass1', 'password_confirmation' => 'Newpass1',
    ]]];
});

it('counts link failures and malformed documents before validation and rejects a valid seventh request without effects', function (): void {
    $url = route('authentication.api.reset-password');
    $invalid = $this->payload;
    $invalid['data']['attributes']['token'] = 'wrong-token';
    for ($attempt = 0; $attempt < 3; $attempt++) {
        $this->postJson($url, $invalid)->assertUnprocessable();
        $this->postJson($url, [])->assertUnprocessable();
    }
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()];

    $this->postJson($url, $this->payload)->assertTooManyRequests()
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertHeader('Retry-After', '600')
        ->assertExactJson(['errors' => [[
            'title' => 'Muitas solicitações', 'detail' => 'O limite de solicitações foi excedido. Tente novamente mais tarde.', 'status' => '429',
        ]]]);
    $this->postJson($url, [])->assertTooManyRequests();
    expect([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($before);
    Queue::assertNothingPushed();
});

it('counts a successful reset toward the same IP quota', function (): void {
    $url = route('authentication.api.reset-password');
    $this->postJson($url, $this->payload)->assertNoContent();
    for ($attempt = 0; $attempt < 5; $attempt++) {
        $this->postJson($url, [])->assertUnprocessable();
    }
    $this->payload['data']['attributes']['token'] = $this->native->create($this->user->fresh());
    $this->payload['data']['attributes']['password'] = 'Another1';
    $this->payload['data']['attributes']['password_confirmation'] = 'Another1';
    $this->postJson($url, $this->payload)->assertTooManyRequests()->assertHeader('Retry-After', '600');

    expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and($this->native->exists($this->user, $this->payload['data']['attributes']['token']))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(0);
    Queue::assertPushed(SendQueuedNotifications::class, 1);
});

it('separates reset IPs and other endpoint quotas and reopens exactly at ten minutes', function (): void {
    $url = route('authentication.api.reset-password');
    for ($attempt = 0; $attempt < 6; $attempt++) {
        $this->postJson($url, [])->assertUnprocessable();
    }
    $this->postJson($url, $this->payload)->assertTooManyRequests();
    $this->postJson(route('authentication.api.forgot-password'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-in'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.sign-up'), [])->assertUnprocessable();
    $this->postJson(route('authentication.api.email-verification.resend'), [])->assertUnprocessable();
    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.20'])->postJson($url, [])->assertUnprocessable();
    $this->withServerVariables(['REMOTE_ADDR' => '127.0.0.1']);

    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:09:59 UTC'));
    $this->postJson($url, $this->payload)->assertTooManyRequests()->assertHeader('Retry-After', '1');
    expect(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue()
        ->and($this->native->exists($this->user, $this->token))->toBeTrue()->and($this->user->tokens()->count())->toBe(1);
    Queue::assertNothingPushed();

    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:10:00 UTC'));
    $this->postJson($url, $this->payload)->assertNoContent();
    expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertPushed(SendQueuedNotifications::class, 1);
});
