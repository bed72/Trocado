<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\Support\Core\Fixtures\ObservabilityLogFixture;
use Tests\Support\Identity\Helpers\IdentityHttpJourney;
use Tests\Support\Notifications\Fixtures\NotificationRegistrationFixture;

beforeEach(function (): void {
    $this->travelTo(CarbonImmutable::parse('2026-10-12 12:00:00 UTC'));
    $this->observabilityLog = new ObservabilityLogFixture;
});

afterEach(function (): void {
    $this->observabilityLog->close();
});

it('preserves UUID resources across real sessions and cascades account owned state only at its lifecycle boundary', function (): void {
    Notification::fake();
    $uuidPattern = '/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/';
    $journey = new IdentityHttpJourney($this);
    $userId = $journey->signUp();
    $user = UserModel::query()->findOrFail($userId);
    expect($userId)->toMatch($uuidPattern)
        ->and($user->status)->toBe(UserStatusEnum::Pending)
        ->and($user->email_verified_at)->toBeNull();
    $journey->verifyEmail($user, expiresAt: now()->addHour());
    expect($user->fresh()->status)->toBe(UserStatusEnum::Pending);
    $user->update(['status' => UserStatusEnum::Active]);
    $token = $journey->signIn();
    $sessionId = explode('|', $token, 2)[0];
    expect($sessionId)->toMatch($uuidPattern)->not->toBe($userId)
        ->and(PersonalAccessTokenModel::findToken($token)->tokenable_id)->toBe($userId);
    $this->withToken($token)->getJson(route('users.get', ['user' => strtoupper($userId)]))
        ->assertOk()->assertJsonPath('data.type', 'users')->assertJsonPath('data.id', $userId);

    $expenseIds = [];
    foreach (['2026-07-01', '2026-08-01', '2026-09-01', '2026-09-10', '2026-09-20'] as $index => $date) {
        $response = $this->withToken($token)->postJson(route('expenses.create'), [
            'data' => ['type' => 'expenses', 'attributes' => [
                'amount' => $index === 4 ? 6000 : 1500, 'category' => 'food',
                'description' => 'Private Internet', 'occurred_on' => $date,
            ]],
        ])->assertCreated()->assertHeader('Content-Type', 'application/vnd.api+json');
        $expenseIds[] = $response->json('data.id');
        expect($response->json('data.id'))->toMatch($uuidPattern);
    }
    $this->getJson(route('expenses.show', ['expense' => strtoupper($expenseIds[0])]))->assertOk()
        ->assertJsonPath('data.id', $expenseIds[0]);
    $this->getJson(route('expenses.index'))->assertOk()->assertJsonCount(5, 'data');

    $projectionPaths = [
        'insights' => '/api/insights?filter[year]=2026&filter[month]=9',
        'expense-metrics' => '/api/metrics/expenses?start_date=2026-09-01&end_date=2026-09-30',
        'expense-suggestions' => '/api/expenses/suggestions?query=Internet',
    ];
    $projectionIds = [];
    foreach ($projectionPaths as $type => $path) {
        $data = $this->getJson($path)->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->json('data');
        $resources = $type === 'expense-metrics' ? [$data] : $data;
        $projectionIds[$type] = array_column($resources, 'id');
        foreach ($resources as $resource) {
            expect($resource['id'])->toMatch($uuidPattern)
                ->and($resource['type'])->toBe($type)
                ->and(array_keys($resource))->toEqualCanonicalizing(['type', 'id', 'attributes'])
                ->and(DB::table('resource_identities')->where('id', $resource['id'])->value('user_id'))->toBe($userId);
        }
    }
    expect($projectionIds['expense-suggestions'])->toHaveCount(1);
    $registry = DB::table('resource_identities')->orderBy('id')->get()->all();
    expect(array_unique(array_column($registry, 'namespace')))->toContain('insights', 'expense-metrics', 'expense-suggestions');

    $registration = $this->postJson(route('notifications.api.push-registrations.register'), NotificationRegistrationFixture::payload())
        ->assertCreated()->json('data.id');
    expect($registration)->toMatch($uuidPattern)->not->toBe(NotificationRegistrationFixture::Installation)
        ->and(DB::table('notifications')->where('id', $registration)->sole())->toMatchObject([
            'user_id' => $userId, 'session_id' => $sessionId,
        ]);
    $fingerprints = array_column($registry, 'logical_fingerprint');
    $fingerprints[] = DB::table('notifications')->where('id', $registration)->value('identifier_fingerprint');
    $passwordHash = $user->password;
    $tokenHash = PersonalAccessTokenModel::findToken($token)->token;
    $newToken = $journey->signIn();
    Auth::forgetGuards();
    $this->withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    expect(PersonalAccessTokenModel::findToken($token))->toBeNull()
        ->and(PersonalAccessTokenModel::findToken($newToken))->not->toBeNull()
        ->and(DB::table('notifications')->where('id', $registration)->exists())->toBeFalse()
        ->and(DB::table('resource_identities')->orderBy('id')->get()->all())->toEqual($registry)
        ->and(DB::table('expenses')->where('user_id', $userId)->count())->toBe(5);
    Auth::forgetGuards();
    $this->withToken($token)->getJson(route('expenses.index'))->assertUnauthorized();
    Auth::forgetGuards();
    foreach ($projectionPaths as $type => $path) {
        $data = $this->withToken($newToken)->getJson($path)->assertOk()->json('data');
        expect(array_column($type === 'expense-metrics' ? [$data] : $data, 'id'))->toBe($projectionIds[$type]);
    }
    $newRegistration = $this->postJson(route('notifications.api.push-registrations.register'), NotificationRegistrationFixture::payload())
        ->assertCreated()->json('data.id');
    expect($newRegistration)->toMatch($uuidPattern)->not->toBe($registration)
        ->and(DB::table('notifications')->where('id', $newRegistration)->value('session_id'))->toBe(explode('|', $newToken, 2)[0]);
    $this->withToken($newToken)->deleteJson(route('users.delete', ['user' => $userId]))->assertNoContent();
    foreach (['users' => 'id', 'personal_access_tokens' => 'tokenable_id', 'expenses' => 'user_id', 'notifications' => 'user_id', 'resource_identities' => 'user_id'] as $table => $ownerColumn) {
        expect(DB::table($table)->where($ownerColumn, $userId)->exists())->toBeFalse();
    }
    Auth::forgetGuards();
    $this->withToken($newToken)->getJson(route('users.get', ['user' => $userId]))->assertUnauthorized();

    $eventAttributes = [
        'user.registered' => ['user_id'], 'identity.signed_in' => ['user_id'],
        'expense.created' => ['expense_id', 'user_id'], 'identity.signed_out' => ['user_id'],
        'push.registration.created' => ['user_id', 'registration_id', 'platform', 'generation'],
        'user.deleted' => ['user_id'],
    ];
    $records = $this->observabilityLog->records();
    expect(array_values(array_unique(array_column($records, 'event'))))->toEqualCanonicalizing(array_keys($eventAttributes));
    foreach ($records as $record) {
        $allowed = array_values(array_unique(['event', 'level', 'timestamp', 'trace_id', 'ip', 'http_method', 'path', ...$eventAttributes[$record['event']]]));
        expect(array_keys($record))->toEqualCanonicalizing($allowed)
            ->and($record['trace_id'])->toMatch($uuidPattern)
            ->and($record['user_id'])->toBe($userId);
        foreach (['expense_id', 'registration_id'] as $field) {
            if (isset($record[$field])) {
                expect($record[$field])->toMatch($uuidPattern);
            }
        }
    }
    expect(json_encode($records, JSON_THROW_ON_ERROR))->not->toContain(
        'Private Internet', 'Correct1', $passwordHash, $token, $newToken, $tokenHash,
        'FakeFcmToken:AbC_123', NotificationRegistrationFixture::Installation, ...$fingerprints,
    );
});
