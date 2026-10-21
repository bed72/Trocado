<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\PasswordRecoveryNotification;
use Carbon\CarbonImmutable;
use Illuminate\Contracts\Notifications\Dispatcher;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['identity.password_recovery.url' => 'https://app.example.com/reset?locale=pt-BR', 'mail.default' => 'array']);
    Queue::fake();
    $this->payload = ['data' => ['type' => 'password-recovery-requests', 'attributes' => ['email' => 'maria@example.com']]];
    $this->accepted = ['meta' => ['message' => 'Se a conta estiver apta, enviaremos as instruções de recuperação.']];
    $this->observability = new ObservabilityPortSpy;
    app()->instance(ObservabilityPort::class, $this->observability);
});

it('accepts a public canonical request without changing the account or PATs or trusting Host', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($user, now()->addDays(30));
    $before = [DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all()];
    $this->payload['data']['attributes']['email'] = ' MARIA@EXAMPLE.COM ';

    $response = $this->withHeaders(['Host' => 'attacker.example', 'Authorization' => 'Bearer invalid'])
        ->postJson(route('authentication.api.forgot-password'), $this->payload)
        ->assertAccepted()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->accepted);

    Queue::assertPushed(SendQueuedNotifications::class, 1);
    $job = Queue::pushed(SendQueuedNotifications::class)->sole();
    expect($job->notification)->toBeInstanceOf(PasswordRecoveryNotification::class);
    $url = $job->notification->toMail($user)->actionUrl;
    parse_str(parse_url($url, PHP_URL_QUERY), $query);
    expect($url)->toStartWith('https://app.example.com/reset?locale=pt-BR&')
        ->and($query['email'])->toBe('maria@example.com')
        ->and(Hash::check($query['token'], DB::table('password_reset_tokens')->sole()->token))->toBeTrue()
        ->and($response->getContent())->not->toContain($query['token'], $url, $user->password)
        ->and([DB::table('users')->get()->all(), DB::table('personal_access_tokens')->get()->all()])->toEqual($before);
});

it('keeps the same public response for every ineligible or missing identity', function (?UserStatusEnum $status, bool $verified, bool $removed): void {
    if ($status !== null) {
        $user = IdentityFixture::create($status, $verified ? now() : null);
        if ($removed) {
            $user->delete();
        }
    }
    $before = DB::table('users')->get()->all();

    $this->postJson(route('authentication.api.forgot-password'), $this->payload)
        ->assertAccepted()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->accepted);

    Queue::assertNothingPushed();
    expect(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and(DB::table('users')->get()->all())->toEqual($before);
})->with([
    'active unverified' => [UserStatusEnum::Active, false, false],
    'pending verified' => [UserStatusEnum::Pending, true, false],
    'pending unverified' => [UserStatusEnum::Pending, false, false],
    'blocked verified' => [UserStatusEnum::Blocked, true, false],
    'blocked unverified' => [UserStatusEnum::Blocked, false, false],
    'missing' => [null, false, false],
    'removed' => [UserStatusEnum::Active, true, true],
]);

it('rejects invalid transport and unknown members with JSON API pointers before any issuance', function (string $path, mixed $value, string $pointer): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    $payload = $this->payload;
    data_set($payload, $path, $value);

    $response = $this->postJson(route('authentication.api.forgot-password'), $payload)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');

    expect(array_column(array_column($response->json('errors'), 'source'), 'pointer'))->toContain($pointer)
        ->and(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertNothingPushed();
})->with([
    'data null' => ['data', null, '/data'],
    'data scalar' => ['data', 'invalid', '/data'],
    'data list' => ['data', [['type' => 'password-recovery-requests']], '/data'],
    'attributes null' => ['data.attributes', null, '/data/attributes'],
    'attributes scalar' => ['data.attributes', 'invalid', '/data/attributes'],
    'type null' => ['data.type', null, '/data/type'],
    'wrong type' => ['data.type', 'password-resets', '/data/type'],
    'type array' => ['data.type', ['password-recovery-requests'], '/data/type'],
    'type integer' => ['data.type', 1, '/data/type'],
    'email null' => ['data.attributes.email', null, '/data/attributes/email'],
    'email empty' => ['data.attributes.email', '', '/data/attributes/email'],
    'email whitespace' => ['data.attributes.email', '   ', '/data/attributes/email'],
    'email array' => ['data.attributes.email', ['maria@example.com'], '/data/attributes/email'],
    'email integer' => ['data.attributes.email', 12, '/data/attributes/email'],
    'email boolean' => ['data.attributes.email', true, '/data/attributes/email'],
    'email malformed' => ['data.attributes.email', 'not-an-email', '/data/attributes/email'],
    'email incompatible with Identity' => ['data.attributes.email', 'mária@example.com', '/data/attributes/email'],
    'email too long' => ['data.attributes.email', str_repeat('a', 256).'@example.com', '/data/attributes/email'],
    'unknown attribute' => ['data.attributes.extra', 'private-value', '/data/attributes/extra'],
    'redirect injection' => ['data.attributes.return_url', 'https://attacker.example/reset', '/data/attributes/return_url'],
    'token injection' => ['data.attributes.token', 'private-token', '/data/attributes/token'],
    'password injection' => ['data.attributes.password', 'PrivatePassword9', '/data/attributes/password'],
    'unknown resource member' => ['data.id', 'private-id', '/data/id'],
    'relationship injection' => ['data.relationships', [], '/data/relationships'],
    'unknown document member' => ['extra', 'private-value', '/extra'],
]);

it('requires JSON document members instead of taking email or data from the query or form body', function (string $mode): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    $url = route('authentication.api.forgot-password');
    $response = match ($mode) {
        'query only' => $this->postJson($url.'?'.http_build_query($this->payload), []),
        'missing email' => $this->postJson($url.'?data[attributes][email]=maria@example.com', ['data' => ['type' => 'password-recovery-requests', 'attributes' => []]]),
        'form body' => $this->post($url, $this->payload),
        'missing type' => $this->postJson($url, ['data' => ['attributes' => ['email' => 'maria@example.com']]]),
    };
    $response->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');
    expect(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertNothingPushed();
})->with(['query only', 'missing email', 'form body', 'missing type']);

it('does not reveal account eligibility when delivery configuration is unavailable', function (?string $url): void {
    config(['identity.password_recovery.url' => $url]);
    IdentityFixture::create(UserStatusEnum::Active, now());

    foreach (['maria@example.com', 'missing@example.com'] as $email) {
        $this->payload['data']['attributes']['email'] = $email;
        $this->postJson(route('authentication.api.forgot-password'), $this->payload)
            ->assertAccepted()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->accepted);
    }
    expect(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and($this->observability->events)->toBe(array_fill(0, 2, [
            'event' => 'identity.password_recovery_unavailable', 'attributes' => ['exception_class' => RuntimeException::class],
        ]));
    Queue::assertNothingPushed();
})->with([null, 'not-a-url', 'https://app.example.com/reset?token=private']);

it('keeps the generic accepted response after the committed issuance cannot be enqueued', function (): void {
    $user = IdentityFixture::create(UserStatusEnum::Active, now());
    $before = $user->fresh()->getRawOriginal();
    $dispatcher = $this->createMock(Dispatcher::class);
    $dispatcher->expects($this->once())->method('send')->willReturnCallback(
        function (object $user, PasswordRecoveryNotification $notification): never {
            expect(DB::transactionLevel())->toBe(0);
            throw new RuntimeException('Private enqueue detail '.$notification->toMail($user)->actionUrl);
        },
    );
    app()->instance(Dispatcher::class, $dispatcher);

    $this->postJson(route('authentication.api.forgot-password'), $this->payload)
        ->assertAccepted()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->accepted);
    expect(DB::table('password_reset_tokens')->count())->toBe(1)
        ->and($user->fresh()->getRawOriginal())->toBe($before)
        ->and($this->observability->events)->toBe([[
            'event' => 'identity.password_recovery_queue_failed', 'attributes' => ['exception_class' => RuntimeException::class],
        ]]);
    Queue::assertNothingPushed();
});

it('reports a sanitized server failure instead of pretending a database error was a successful issuance', function (): void {
    IdentityFixture::create(UserStatusEnum::Active, now());
    DB::statement('ALTER TABLE password_reset_tokens ADD CONSTRAINT recovery_http_test_reject CHECK (false) NOT VALID');
    try {
        $this->postJson(route('authentication.api.forgot-password'), $this->payload)
            ->assertInternalServerError()->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
                'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.', 'status' => '500',
            ]]]);
        expect(DB::table('password_reset_tokens')->count())->toBe(0);
        Queue::assertNothingPushed();
    } finally {
        DB::statement('ALTER TABLE password_reset_tokens DROP CONSTRAINT recovery_http_test_reject');
    }
});

it('does not expose a GET recovery page', function (): void {
    $this->getJson('/api/authentication/forgot-password')->assertStatus(405)->assertHeader('Content-Type', 'application/vnd.api+json');
    expect(DB::table('password_reset_tokens')->count())->toBe(0);
    Queue::assertNothingPushed();
});
