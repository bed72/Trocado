<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Infrastructure\Adapters\UserAdapter;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Insights\Application\Ports\ExpenseAnalysisPort;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\Support\Identity\Fixtures\IdentityFixture;

use function Pest\Laravel\withToken;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
});

afterEach(function (): void {
    Date::setTestNow();
});

function insightsApiRequest(string $token, string $query = ''): TestResponse
{
    Auth::forgetGuards();
    $url = route('insights.index');

    return withToken($token)->getJson($query === '' ? $url : "{$url}?{$query}");
}

function recordInsightsApiBase(int $userId, string $month, string $category = 'food', int $amount = 2000): void
{
    for ($day = 1; $day <= 5; $day++) {
        DB::table('expenses')->insert([
            'user_id' => $userId, 'amount' => $amount, 'category' => $category,
            'occurred_on' => "{$month}-0{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }
}

it('returns isolated ordered JSON API insights with exact contract and one analytical query', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'insights@example.com');
    $userId = (int) $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $otherUserId = (int) IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), name: 'Joana', email: 'other-insights@example.com')->getKey();
    recordInsightsApiBase($userId, '2026-08');
    recordInsightsApiBase($userId, '2026-09');
    recordInsightsApiBase($userId, '2026-10', amount: 4000);
    recordInsightsApiBase($otherUserId, '2026-10', 'health', 1000000);
    $expensesBefore = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    $response = insightsApiRequest($token)->assertOk()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.attributes.group', 'comparison')
        ->assertJsonPath('data.0.attributes.type', 'registered_amount_increase')
        ->assertJsonPath('data.0.attributes.period.from', '2026-10-01')
        ->assertJsonPath('data.0.attributes.period.to', '2026-10-11')
        ->assertJsonPath('data.0.attributes.period.comparison.from', '2026-09-01')
        ->assertJsonPath('data.0.attributes.period.comparison.to', '2026-09-11')
        ->assertJsonPath('data.1.attributes.type', 'category_lead_streak')
        ->assertJsonPath('data.1.attributes.period.from', '2026-08-01')
        ->assertJsonPath('data.1.attributes.period.to', '2026-10-12')
        ->assertJsonPath('data.1.attributes.period.comparison', null);
    $queries = DB::getQueryLog();
    DB::disableQueryLog();
    $analyticalQueries = array_values(array_filter($queries, static fn (array $query): bool => str_starts_with($query['query'], 'WITH periods')));

    expect($analyticalQueries)->toHaveCount(1)
        ->and(str_contains($response->json('data.0.attributes.description'), '100%'))->toBeTrue()
        ->and(str_contains($response->json('data.1.attributes.description'), 'Alimentação'))->toBeTrue()
        ->and(array_keys($response->json()))->toBe(['data'])
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($expensesBefore)
        ->and(app(UserPort::class))->toBeInstanceOf(UserAdapter::class);

    foreach ($response->json('data') as $resource) {
        expect($resource['type'])->toBe('insights')
            ->and($resource['id'])->toMatch('/\A[0-9a-f]{64}\z/')
            ->and(array_keys($resource))->toEqualCanonicalizing(['type', 'id', 'attributes'])
            ->and(array_keys($resource['attributes']))->toEqualCanonicalizing(['group', 'type', 'title', 'description', 'period'])
            ->and(mb_strlen($resource['attributes']['title'], 'UTF-8'))->toBeLessThanOrEqual(32)
            ->and(mb_strlen($resource['attributes']['description'], 'UTF-8'))->toBeLessThanOrEqual(110);
    }
});

it('returns first expense alone for an authenticated account without historical expenses', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    insightsApiRequest($token)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.type', 'insights')
        ->assertJsonPath('data.0.attributes.group', 'onboarding')
        ->assertJsonPath('data.0.attributes.type', 'first_expense')
        ->assertJsonPath('data.0.attributes.period', null);
});

it('rejects unauthenticated and invalid token requests before analytical access', function (bool $invalidToken): void {
    $port = $this->createMock(ExpenseAnalysisPort::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisPort::class, $port);
    $response = $invalidToken ? insightsApiRequest('invalid') : $this->getJson(route('insights.index'));

    $response->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonMissingPath('data');
})->with([false, true]);

it('blocks inactive or unverified accounts before analytical access', function (string $state): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = (int) $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    DB::table('users')->where('id', $userId)->update($state === 'unverified'
        ? ['email_verified_at' => null]
        : ['status' => $state]);
    $port = $this->createMock(ExpenseAnalysisPort::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisPort::class, $port);

    insightsApiRequest($token)->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonMissingPath('data');
})->with(['pending', 'blocked', 'unverified']);

it('rejects every supplied query parameter including empty values without analyzing expenses', function (string $query, string $parameter): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $port = $this->createMock(ExpenseAnalysisPort::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisPort::class, $port);

    insightsApiRequest($token, $query)->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '422')
        ->assertJsonPath('errors.0.source.parameter', $parameter)
        ->assertJsonMissingPath('data');
})->with([
    ['user_id=999', 'user_id'], ['period=2026-09', 'period'], ['family=1', 'family'],
    ['limit=6', 'limit'], ['page[size]=20', 'page'], ['include=user', 'include'],
    ['filter[category]=food', 'filter'], ['unknown=', 'unknown'], ['user_id=', 'user_id'],
]);

it('identifies all rejected query parameters in the error document', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    insightsApiRequest($token, 'user_id=999&limit=6')->assertUnprocessable()->assertJsonCount(2, 'errors')
        ->assertJsonPath('errors.0.source.parameter', 'user_id')
        ->assertJsonPath('errors.1.source.parameter', 'limit');
});

it('reflects confirmed recategorization date edits and deletion on the next HTTP read', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = (int) $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    recordInsightsApiBase($userId, '2026-10', 'other');

    insightsApiRequest($token)->assertOk()->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.attributes.type', 'category_review')
        ->assertJsonPath('data.0.attributes.period', null)
        ->assertJsonPath('data.1.attributes.type', 'insufficient_history');

    DB::table('expenses')->where('user_id', $userId)->update(['category' => 'food']);
    insightsApiRequest($token)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'category_concentration');

    DB::table('expenses')->where('user_id', $userId)->update(['occurred_on' => '2026-09-26']);
    insightsApiRequest($token)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.period', null);

    DB::table('expenses')->where('user_id', $userId)->delete();
    insightsApiRequest($token)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'first_expense');
});

it('keeps IDs and the chosen title while a confirmed value edit refreshes the percentage', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = (int) $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    recordInsightsApiBase($userId, '2026-10');
    DB::table('expenses')->where('user_id', $userId)->where('occurred_on', '>=', '2026-10-04')->update(['category' => 'other']);
    $first = insightsApiRequest($token)->assertOk()->json('data.0');
    DB::table('expenses')->where('user_id', $userId)->where('occurred_on', '2026-10-01')->update(['amount' => 3000]);
    $second = insightsApiRequest($token)->assertOk()->json('data.0');

    expect($first['id'])->toBe($second['id'])
        ->and($first['attributes']['title'])->toBe($second['attributes']['title'])
        ->and(str_contains($first['attributes']['description'], '60%'))->toBeTrue()
        ->and(str_contains($second['attributes']['description'], '64%'))->toBeTrue();
});

it('resolves the reference date in app timezone and excludes only future historical records', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = (int) $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    Date::setTestNow('2026-10-13 00:30:00 UTC');
    config()->set('app.timezone', 'America/Sao_Paulo');
    DB::table('expenses')->insert([
        'user_id' => $userId, 'amount' => 10000, 'category' => 'food', 'occurred_on' => '2026-10-13',
        'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
    ]);

    insightsApiRequest($token)->assertOk()->assertJsonPath('data.0.attributes.type', 'first_expense');
});

it('uses the authenticated throttle policy', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    RateLimiter::for('api.authenticated', static fn (): Limit => Limit::perMinute(1)->by('insights-api-test'));

    insightsApiRequest($token)->assertOk();
    insightsApiRequest($token)->assertTooManyRequests()->assertHeader('Retry-After')
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonMissingPath('data');
});

it('extends the successful session and does not extend a rejected query', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $record = PersonalAccessToken::findToken($token);
    $originalExpiry = $record->expires_at;
    Date::setTestNow('2026-10-28 12:00:00 UTC');

    insightsApiRequest($token, 'limit=6')->assertUnprocessable();
    expect($record->fresh()->expires_at->equalTo($originalExpiry))->toBeTrue();
    insightsApiRequest($token)->assertOk();
    expect($record->fresh()->expires_at->greaterThan($originalExpiry))->toBeTrue();
});

it('returns an explicit JSON API failure when analytical reading fails', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $port = $this->createMock(ExpenseAnalysisPort::class);
    $port->method('analyze')->willThrowException(new RuntimeException('Analytical database unavailable'));
    $this->app->instance(ExpenseAnalysisPort::class, $port);

    insightsApiRequest($token)->assertStatus(500)->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '500')->assertJsonMissingPath('data');
});

it('does not expose an individual endpoint for derived resource IDs', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $id = insightsApiRequest($token)->assertOk()->json('data.0.id');

    $this->getJson(route('insights.index')."/{$id}")->assertNotFound();
});
