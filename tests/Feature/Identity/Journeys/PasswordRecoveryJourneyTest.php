<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel;
use Carbon\CarbonImmutable;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Route;
use Monolog\Formatter\JsonFormatter;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;
use Tests\Support\Identity\Fixtures\PasswordRecoveryWorkerFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:00:00 UTC'));
    config([
        'identity.password_recovery.url' => 'https://app.example.com/reset?locale=pt-BR',
        'mail.default' => 'array', 'queue.default' => 'redis', 'queue.connections.redis.block_for' => null,
        'logging.default' => 'single', 'logging.channels.single.formatter' => JsonFormatter::class,
    ]);
    Log::forgetChannel('single');
    $this->observabilityLog = new ObservabilityLogFixture;
    $this->queue = config('queue.connections.redis.queue');
    $this->connection = Queue::connection('redis');
    $this->transport = Mail::mailer('array')->getSymfonyTransport();
    $this->worker = new PasswordRecoveryWorkerFixture($this->queue);
    $this->journey = new IdentityHttpJourney($this);
    $this->user = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'maria+tag@example.com');
    $this->forgot = ['data' => ['type' => 'password-recovery-requests', 'attributes' => ['email' => ' MARIA+TAG@EXAMPLE.COM ']]];
    $this->accepted = ['meta' => ['message' => 'Se a conta estiver apta, enviaremos as instruções de recuperação.']];
    $this->invalidLink = ['errors' => [[
        'title' => 'Link inválido', 'detail' => 'Este link é inválido ou expirou. Solicite uma nova recuperação de senha.',
        'source' => ['pointer' => '/data/attributes/token'], 'status' => '422',
    ]]];
    $this->queries = [];
    DB::listen(function (QueryExecuted $query): void {
        $this->queries[] = ['sql' => $query->sql, 'connection' => $query->connectionName];
    });
});

afterEach(function (): void {
    Auth::forgetGuards();
    $this->observabilityLog->close();
});

it('recovers through public HTTP and a real Redis mail worker then requires a new explicit login', function (): void {
    $firstBearer = $this->journey->signIn(email: $this->user->email);
    $secondBearer = $this->journey->signIn(email: $this->user->email);
    $other = IdentityFixture::create(UserStatusEnum::Active, now(), email: 'other@example.com');
    $otherBearer = IdentityFixture::token($other, now()->addDays(30));
    $otherPat = PersonalAccessTokenModel::findToken($otherBearer)->getRawOriginal();
    $profile = $this->user->fresh()->getRawOriginal();
    $oldHash = $profile['password'];
    Auth::forgetGuards();
    $this->withToken($firstBearer)->getJson(route('users.get', ['user' => $this->user->getKey()]))->assertOk();
    $this->withoutToken();

    $accepted = $this->postJson(route('authentication.api.forgot-password'), $this->forgot)
        ->assertAccepted()->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson($this->accepted);
    $record = (array) DB::table('password_reset_tokens')->sole();
    expect(array_keys($record))->toEqualCanonicalizing(['email', 'token', 'created_at'])
        ->and($record['email'])->toBe('maria+tag@example.com')
        ->and($this->transport->messages())->toHaveCount(0)
        ->and($this->connection->size($this->queue))->toBe(1);
    $linkPayload = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    $this->worker->work();
    $message = $this->transport->messages()->sole();
    preg_match('~https://app\.example\.com/reset\?[^\s)]+~', $message->getOriginalMessage()->getTextBody(), $matches);
    $link = $matches[0];
    parse_str(parse_url($link, PHP_URL_QUERY), $query);
    expect($message->getEnvelope()->getRecipients()[0]->getAddress())->toBe($this->user->email)
        ->and($query['email'])->toBe('maria+tag@example.com')->and($query['locale'])->toBe('pt-BR')
        ->and(Hash::check($query['token'], $record['token']))->toBeTrue()
        ->and($record['token'])->not->toBe($query['token'])
        ->and(json_encode($linkPayload, JSON_THROW_ON_ERROR))->not->toContain($link, $query['token'], $record['token'], 'Correct1');

    $beforeOpen = [DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()];
    $this->getJson('/reset?'.http_build_query($query))->assertNotFound();
    $this->getJson('/api/authentication/reset-password?'.http_build_query($query))->assertStatus(405);
    expect([DB::table('users')->orderBy('id')->get()->all(), DB::table('personal_access_tokens')->orderBy('id')->get()->all(), DB::table('password_reset_tokens')->get()->all()])->toEqual($beforeOpen);
    foreach (['forgot-password', 'reset-password'] as $endpoint) {
        $route = Route::getRoutes()->getByName('authentication.api.'.$endpoint);
        expect($route->methods())->toBe(['POST']);
    }

    $password = ' Newpass1 ';
    $payload = ['data' => ['type' => 'password-resets', 'attributes' => [
        'email' => $query['email'], 'token' => $query['token'], 'password' => $password, 'password_confirmation' => $password,
    ]]];
    $reset = $this->postJson(route('authentication.api.reset-password'), $payload)->assertNoContent();
    expect($reset->headers->has('Location'))->toBeFalse()->and($reset->headers->has('Set-Cookie'))->toBeFalse()
        ->and($this->user->tokens()->count())->toBe(0)->and(DB::table('password_reset_tokens')->count())->toBe(0)
        ->and(PersonalAccessTokenModel::findToken($otherBearer)->getRawOriginal())->toBe($otherPat)
        ->and(Hash::check($password, $this->user->fresh()->password))->toBeTrue()
        ->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeFalse();
    $after = $this->user->fresh()->getRawOriginal();
    $newHash = $after['password'];
    unset($profile['password'], $profile['updated_at'], $after['password'], $after['updated_at']);
    expect($after)->toBe($profile);
    $noticePayload = json_decode($this->connection->getConnection()->lindex('queues:'.$this->queue, 0), true, flags: JSON_THROW_ON_ERROR);
    expect(Crypt::decrypt($noticePayload['data']['command']))->not->toContain($password, $query['token'], $oldHash, $newHash, $link);
    $this->worker->work();
    $notice = $this->transport->messages()->last()->getOriginalMessage();
    expect($notice->getSubject())->toBe('Sua senha foi alterada no Trocado')
        ->and($notice->getTextBody())->not->toContain($password, $query['token'], $oldHash, $newHash, $link);

    $reused = $this->postJson(route('authentication.api.reset-password'), $payload)->assertUnprocessable()->assertExactJson($this->invalidLink);
    foreach ([$firstBearer, $secondBearer] as $bearer) {
        Auth::forgetGuards();
        $this->withToken($bearer)->getJson(route('users.get', ['user' => $this->user->getKey()]))->assertUnauthorized();
    }
    Auth::forgetGuards();
    $this->withoutToken()->getJson(route('users.get', ['user' => $this->user->getKey()]))->assertUnauthorized();
    Auth::forgetGuards();
    $this->withToken($otherBearer)->getJson(route('users.get', ['user' => $other->getKey()]))->assertOk();
    $this->withoutToken();
    Auth::forgetGuards();
    $this->postJson(route('authentication.api.sign-in'), ['data' => ['type' => 'access-tokens', 'attributes' => [
        'email' => $this->user->email, 'password' => 'Correct1',
    ]]])->assertUnauthorized();
    $newBearer = $this->journey->signIn(email: $this->user->email, password: $password);
    Auth::forgetGuards();
    $this->withToken($newBearer)->getJson(route('users.get', ['user' => $this->user->getKey()]))->assertOk();
    expect($newBearer)->not->toBe($firstBearer, $secondBearer)
        ->and($this->user->tokens()->count())->toBe(1)->and($other->tokens()->count())->toBe(1)
        ->and($this->connection->size($this->queue))->toBe(0)->and(DB::table('failed_jobs')->count())->toBe(0);

    $secrets = [$password, 'Correct1', $query['token'], $record['token'], $oldHash, $newHash, $link, $firstBearer, $secondBearer, $newBearer];
    $records = $this->observabilityLog->records();
    expect($records)->not->toBeEmpty();
    foreach ($records as $entry) {
        $allowed = match ($entry['event']) {
            'identity.signed_in' => ['user_id'],
            'queue.job_processed' => ['duration_ms', 'queue', 'job_id', 'job', 'attempts', 'connection'],
        };
        expect(array_diff(array_keys($entry), ['event', 'level', 'timestamp', 'trace_id', 'http_method', 'path', 'ip', 'user_id', ...$allowed]))->toBe([]);
    }
    $appLogs = array_map(static fn (string $line): array => json_decode($line, true, flags: JSON_THROW_ON_ERROR), file($this->resources->log, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES));
    expect(json_encode(['events' => $records, 'logs' => $appLogs, 'sql' => $this->queries, 'queue' => [$linkPayload, $noticePayload]], JSON_THROW_ON_ERROR))->not->toContain(...$secrets)
        ->and($accepted->getContent().$reset->getContent().$reused->getContent())->not->toContain(...$secrets);
})->group('integration', 'redis', 'worker');

it('delivers rotated links through the real worker but only the new link can reset over HTTP', function (): void {
    $this->postJson(route('authentication.api.forgot-password'), $this->forgot)->assertAccepted()->assertExactJson($this->accepted);
    $this->worker->work();
    preg_match('~https://app\.example\.com/reset\?[^\s)]+~', $this->transport->messages()->sole()->getOriginalMessage()->getTextBody(), $firstLink);
    parse_str(parse_url($firstLink[0], PHP_URL_QUERY), $first);
    $this->travelTo(CarbonImmutable::parse('2026-10-21 12:01:00 UTC'));
    $this->postJson(route('authentication.api.forgot-password'), $this->forgot)->assertAccepted()->assertExactJson($this->accepted);
    $this->worker->work();
    preg_match('~https://app\.example\.com/reset\?[^\s)]+~', $this->transport->messages()->last()->getOriginalMessage()->getTextBody(), $secondLink);
    parse_str(parse_url($secondLink[0], PHP_URL_QUERY), $second);
    $payload = ['data' => ['type' => 'password-resets', 'attributes' => [
        'email' => $first['email'], 'token' => $first['token'], 'password' => 'Newpass1', 'password_confirmation' => 'Newpass1',
    ]]];
    $before = (array) DB::table('password_reset_tokens')->sole();
    $this->postJson(route('authentication.api.reset-password'), $payload)->assertUnprocessable()->assertExactJson($this->invalidLink);
    expect((array) DB::table('password_reset_tokens')->sole())->toBe($before)
        ->and(Hash::check('Correct1', $this->user->fresh()->password))->toBeTrue();
    $payload['data']['attributes']['token'] = $second['token'];
    $this->postJson(route('authentication.api.reset-password'), $payload)->assertNoContent();
    $this->worker->work();
    expect(Hash::check('Newpass1', $this->user->fresh()->password))->toBeTrue()
        ->and(DB::table('password_reset_tokens')->count())->toBe(0)->and($this->user->tokens()->count())->toBe(0)
        ->and($this->transport->messages())->toHaveCount(3)->and(DB::table('failed_jobs')->count())->toBe(0);
})->group('integration', 'redis', 'worker');
