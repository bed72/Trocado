<?php

declare(strict_types=1);

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Notifications\PasswordChangedNotification;
use Carbon\CarbonImmutable;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Contracts\Notifications\Dispatcher;
use Illuminate\Notifications\SendQueuedNotifications;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Queue;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config(['mail.default' => 'array', 'identity.password_recovery.url' => null]);
    Queue::fake();
    $this->observability = new ObservabilityPortSpy;
    app()->instance(ObservabilityPort::class, $this->observability);
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now());
    IdentityFixture::token($this->user, now()->addDays(30));
    $this->native = app(PasswordBrokerManager::class)->broker('users')->getRepository();
    $this->token = $this->native->create($this->user);
    $this->payload = ['data' => ['type' => 'password-resets', 'attributes' => [
        'email' => 'maria@example.com', 'token' => $this->token,
        'password' => 'Newpass1', 'password_confirmation' => 'Newpass1',
    ]]];
    $this->invalidLink = ['errors' => [[
        'title' => 'Link inválido',
        'detail' => 'Este link é inválido ou expirou. Solicite uma nova recuperação de senha.',
        'source' => ['pointer' => '/data/attributes/token'], 'status' => '422',
    ]]];
});

it('resets publicly with an empty 204 and no new session while preserving other owners and the profile', function (string $password): void {
    IdentityFixture::token($this->user, now()->addDays(30), 'second-device');
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    IdentityFixture::token($other, now()->addDays(30));
    $otherBefore = DB::table('personal_access_tokens')->where('tokenable_id', $other->getKey())->get()->all();
    $profile = $this->user->fresh()->getRawOriginal();
    $this->payload['data']['attributes']['email'] = ' MARIA@EXAMPLE.COM ';
    $this->payload['data']['attributes']['password'] = $password;
    $this->payload['data']['attributes']['password_confirmation'] = $password;

    $response = $this->withHeader('Authorization', 'Bearer invalid')
        ->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();

    expect($response->getContent())->toBe('')
        ->and($response->headers->has('Location'))->toBeFalse()
        ->and($response->headers->has('Set-Cookie'))->toBeFalse()
        ->and(Hash::check($password, $this->user->fresh()->password))->toBeTrue()
        ->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeFalse()
        ->and($this->user->tokens()->count())->toBe(0)
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and(DB::table('personal_access_tokens')->where('tokenable_id', $other->getKey())->get()->all())->toEqual($otherBefore);
    $after = $this->user->fresh()->getRawOriginal();
    unset($profile['password'], $profile['updated_at'], $after['password'], $after['updated_at']);
    expect($after)->toBe($profile);
    Queue::assertPushed(SendQueuedNotifications::class, 1);
    expect(Queue::pushed(SendQueuedNotifications::class)->sole()->notification)->toBeInstanceOf(PasswordChangedNotification::class);

    $this->postJson(route('authentication.api.reset-password'), $this->payload)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->invalidLink);
    expect(Hash::check($password, $this->user->fresh()->password))->toBeTrue();
    Queue::assertPushed(SendQueuedNotifications::class, 1);
})->with([
    'six characters' => 'Abcde1',
    '32 characters' => 'A1'.str_repeat('a', 30),
    'Unicode uppercase' => 'Ábcde1',
    '72 bytes' => 'Á1'.str_repeat('界', 23),
    'exact outer spaces' => ' Newpass1 ',
]);

it('rejects malformed documents and policies without consuming the link and permits a corrected attempt', function (string $path, mixed $value, string $pointer): void {
    $payload = $this->payload;
    data_set($payload, $path, $value);
    $before = [DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()];

    $response = $this->postJson(route('authentication.api.reset-password'), $payload)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');
    expect(array_column(array_column($response->json('errors'), 'source'), 'pointer'))->toContain($pointer)
        ->and([DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()])->toEqual($before);
    Queue::assertNothingPushed();
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();
})->with([
    'data null' => ['data', null, '/data'],
    'data scalar' => ['data', 'invalid', '/data'],
    'data list' => ['data', [['type' => 'password-resets']], '/data'],
    'attributes null' => ['data.attributes', null, '/data/attributes'],
    'attributes scalar' => ['data.attributes', 'invalid', '/data/attributes'],
    'attributes list' => ['data.attributes', ['invalid'], '/data/attributes'],
    'type null' => ['data.type', null, '/data/type'],
    'type array' => ['data.type', ['password-resets'], '/data/type'],
    'type integer' => ['data.type', 1, '/data/type'],
    'wrong type' => ['data.type', 'password-recovery-requests', '/data/type'],
    'unknown attribute' => ['data.attributes.extra', 'private', '/data/attributes/extra'],
    'redirect injection' => ['data.attributes.return_url', 'https://attacker.example', '/data/attributes/return_url'],
    'unknown resource member' => ['data.id', 'private', '/data/id'],
    'relationships' => ['data.relationships', [], '/data/relationships'],
    'unknown document member' => ['extra', 'private', '/extra'],
    'email null' => ['data.attributes.email', null, '/data/attributes/email'],
    'email array' => ['data.attributes.email', ['maria@example.com'], '/data/attributes/email'],
    'email integer' => ['data.attributes.email', 12, '/data/attributes/email'],
    'email boolean' => ['data.attributes.email', true, '/data/attributes/email'],
    'email empty' => ['data.attributes.email', '', '/data/attributes/email'],
    'email malformed' => ['data.attributes.email', 'invalid', '/data/attributes/email'],
    'email incompatible' => ['data.attributes.email', 'mária@example.com', '/data/attributes/email'],
    'email too long' => ['data.attributes.email', str_repeat('a', 256).'@example.com', '/data/attributes/email'],
    'token null' => ['data.attributes.token', null, '/data/attributes/token'],
    'token empty' => ['data.attributes.token', '', '/data/attributes/token'],
    'token array' => ['data.attributes.token', ['private'], '/data/attributes/token'],
    'token integer' => ['data.attributes.token', 12, '/data/attributes/token'],
    'token boolean' => ['data.attributes.token', true, '/data/attributes/token'],
    'password null' => ['data.attributes.password', null, '/data/attributes/password'],
    'password empty' => ['data.attributes.password', '', '/data/attributes/password'],
    'password array' => ['data.attributes.password', ['Newpass1'], '/data/attributes/password'],
    'password integer' => ['data.attributes.password', 123456, '/data/attributes/password'],
    'password boolean' => ['data.attributes.password', true, '/data/attributes/password'],
    'five characters' => ['data.attributes.password', 'Abcd1', '/data/attributes/password'],
    '33 characters' => ['data.attributes.password', 'A1'.str_repeat('a', 31), '/data/attributes/password'],
    '73 bytes' => ['data.attributes.password', 'A1'.str_repeat('界', 23).'é', '/data/attributes/password'],
    'no uppercase' => ['data.attributes.password', 'abcdef1', '/data/attributes/password'],
    'no digit' => ['data.attributes.password', 'Abcdef', '/data/attributes/password'],
    'non ASCII digit' => ['data.attributes.password', 'Abcde١', '/data/attributes/password'],
    'confirmation null' => ['data.attributes.password_confirmation', null, '/data/attributes/password_confirmation'],
    'confirmation empty' => ['data.attributes.password_confirmation', '', '/data/attributes/password_confirmation'],
    'confirmation array' => ['data.attributes.password_confirmation', ['Newpass1'], '/data/attributes/password_confirmation'],
    'confirmation integer' => ['data.attributes.password_confirmation', 123456, '/data/attributes/password_confirmation'],
    'confirmation boolean' => ['data.attributes.password_confirmation', true, '/data/attributes/password_confirmation'],
    'confirmation mismatch' => ['data.attributes.password_confirmation', 'Different1', '/data/attributes/password_confirmation'],
    'confirmation is not trimmed' => ['data.attributes.password_confirmation', ' Newpass1 ', '/data/attributes/password_confirmation'],
]);

it('requires every member in the JSON body and ignores query and form replacements', function (string $member): void {
    $payload = $this->payload;
    data_forget($payload, $member);
    $url = route('authentication.api.reset-password').'?'.http_build_query($this->payload);
    $response = $this->postJson($url, $payload)->assertUnprocessable();
    expect(array_column(array_column($response->json('errors'), 'source'), 'pointer'))->toContain('/'.str_replace('.', '/', $member));
    $this->post(route('authentication.api.reset-password'), $this->payload)->assertUnprocessable();
    expect($this->native->exists($this->user, $this->token))->toBeTrue()
        ->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue()->and($this->user->tokens()->count())->toBe(1);
    Queue::assertNothingPushed();
})->with(['data', 'data.type', 'data.attributes', 'data.attributes.email', 'data.attributes.token', 'data.attributes.password', 'data.attributes.password_confirmation']);

it('uses the identical invalid link document for every structurally valid recovery failure without effects', function (string $cause): void {
    match ($cause) {
        'pending verified' => $this->user->update(['status' => UserStatusEnum::Pending]),
        'pending unverified' => $this->user->forceFill(['status' => UserStatusEnum::Pending, 'email_verified_at' => null])->save(),
        'blocked verified' => $this->user->update(['status' => UserStatusEnum::Blocked]),
        'blocked unverified' => $this->user->forceFill(['status' => UserStatusEnum::Blocked, 'email_verified_at' => null])->save(),
        'active unverified' => $this->user->forceFill(['email_verified_at' => null])->save(),
        'removed' => $this->user->delete(),
        'changed email' => $this->user->update(['email' => 'new@example.com']),
        'missing account' => $this->payload['data']['attributes']['email'] = 'missing@example.com',
        'wrong token' => $this->payload['data']['attributes']['token'] = 'wrong-token',
        'token spaces' => $this->payload['data']['attributes']['token'] = ' '.$this->token.' ',
        'missing recovery' => $this->native->delete($this->user),
        'rotated' => $this->native->create($this->user),
        'expired exactly' => $this->travelTo(CarbonImmutable::parse('2026-10-21 12:30:00 UTC')),
        'expired later' => $this->travelTo(CarbonImmutable::parse('2026-10-21 12:30:01 UTC')),
    };
    $before = [DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()];

    $this->postJson(route('authentication.api.reset-password'), $this->payload)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->invalidLink);

    expect([DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()])->toEqual($before);
    Queue::assertNothingPushed();
})->with(['pending verified', 'pending unverified', 'blocked verified', 'blocked unverified', 'active unverified', 'removed', 'changed email', 'missing account', 'wrong token', 'token spaces', 'missing recovery', 'rotated', 'expired exactly', 'expired later']);

it('accepts a token immediately before expiry', function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:29:59.999999 UTC'));
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();
    expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue();
});

it('rejects the current password separately only after checking the token and keeps the link usable', function (): void {
    $this->payload['data']['attributes']['password'] = 'Correct1';
    $this->payload['data']['attributes']['password_confirmation'] = 'Correct1';
    $before = [DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()];
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['errors' => [[
            'title' => 'Dados inválidos', 'detail' => 'A nova senha deve ser diferente da atual.',
            'source' => ['pointer' => '/data/attributes/password'], 'status' => '422',
        ]]]);
    expect([DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()])->toEqual($before);
    Queue::assertNothingPushed();
    $this->payload['data']['attributes']['token'] = 'wrong-token';
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertUnprocessable()->assertExactJson($this->invalidLink);
    $this->payload['data']['attributes']['token'] = $this->token;
    $this->payload['data']['attributes']['password'] = 'Newpass1';
    $this->payload['data']['attributes']['password_confirmation'] = 'Newpass1';
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();
});

it('keeps 204 and committed reset state when enqueue fails after commit', function (): void {
    $dispatcher = $this->createMock(Dispatcher::class);
    $dispatcher->expects($this->once())->method('send')->willReturnCallback(function (object $user, PasswordChangedNotification $notification): never {
        expect(DB::transactionLevel())->toBe(0)->and(Hash::check('Newpass1', $user->password))->toBeTrue()
            ->and(DB::table('password_reset_tokens')->count())->toBe(0)->and($user->tokens()->count())->toBe(0);
        throw new RuntimeException('Private enqueue failure Newpass1 '.$this->token.' '.$user->password);
    });
    app()->instance(Dispatcher::class, $dispatcher);

    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();
    expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->user->tokens()->count())->toBe(0)
        ->and($this->observability->events)->toBe([[
            'event' => 'identity.password_reset_queue_failed', 'attributes' => ['exception_class' => RuntimeException::class],
        ]]);
    Queue::assertNothingPushed();
});

it('returns a generic technical 500 rather than invalid link and rolls back a real password write failure', function (): void {
    $before = [DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()];
    DB::statement('ALTER TABLE users ADD CONSTRAINT reset_http_test_reject CHECK (false) NOT VALID');
    try {
        $this->postJson(route('authentication.api.reset-password'), $this->payload)
            ->assertInternalServerError()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['errors' => [[
                'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.', 'status' => '500',
            ]]]);
        expect([DB::table('users')->get()->all(), DB::table('password_reset_tokens')->get()->all(), DB::table('personal_access_tokens')->get()->all()])->toEqual($before);
        Queue::assertNothingPushed();
    } finally {
        DB::statement('ALTER TABLE users DROP CONSTRAINT reset_http_test_reject');
    }
    $this->postJson(route('authentication.api.reset-password'), $this->payload)->assertNoContent();
});

it('does not expose GET consumption or a recovery form', function (): void {
    $this->getJson('/api/authentication/reset-password?'.http_build_query(['email' => 'maria@example.com', 'token' => $this->token]))
        ->assertStatus(405)->assertHeader('Content-Type', 'application/vnd.api+json');
    expect($this->native->exists($this->user, $this->token))->toBeTrue();
    Queue::assertNothingPushed();
});
