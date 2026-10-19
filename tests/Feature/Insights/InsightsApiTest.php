<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Core\Infrastructure\Adapters\UserAdapter;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Exceptions;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
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

function recordInsightsApiBase(string $userId, string $month, string $category = 'food', int $amount = 2000): void
{
    for ($day = 1; $day <= 5; $day++) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $userId, 'amount' => $amount, 'category' => $category,
            'occurred_on' => "{$month}-0{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }
}

it('returns isolated ordered JSON API insights with exact contract and one analytical query', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'insights@example.com');
    $userId = $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $otherUserId = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), name: 'Joana', email: 'other-insights@example.com')->getKey();
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
        ->and($response->json('data.0.attributes.title'))->toBe('Total registrado subiu')
        ->and($response->json('data.1.attributes.title'))->toBe('Alimentação')
        ->and(array_keys($response->json()))->toBe(['data'])
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($expensesBefore)
        ->and(app(UserPort::class))->toBeInstanceOf(UserAdapter::class);

    foreach ($response->json('data') as $resource) {
        expect($resource['type'])->toBe('insights')
            ->and($resource['id'])->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/')
            ->and(array_keys($resource))->toEqualCanonicalizing(['type', 'id', 'attributes'])
            ->and(array_keys($resource['attributes']))->toEqualCanonicalizing(['group', 'type', 'title', 'description', 'period'])
            ->and(grapheme_strlen($resource['attributes']['title']))->toBeLessThanOrEqual(24)
            ->and(grapheme_strlen($resource['attributes']['title'].' '.$resource['attributes']['description']))->toBeLessThanOrEqual(80)
            ->and($resource['attributes']['description'])->toContain($resource['attributes']['type'] === 'registered_amount_increase' ? 'R$ 100' : 'R$ 200')->not->toContain('%');
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

it('serializes the selected expense identification as literal text with no expense ID in either monthly mode', function (bool $closed, ?string $description, string $identity): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $month = $closed ? '2026-09' : '2026-10';
    DB::table('expenses')->insert([
        'id' => (string) Str::uuid7(),
        'user_id' => $user->getKey(), 'amount' => 120000, 'category' => 'other', 'occurred_on' => $month.'-05',
        'description' => $description, 'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
    ]);
    foreach (['food', 'health', 'transport', 'leisure'] as $index => $category) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => 25000, 'category' => $category, 'occurred_on' => $month.'-0'.($index + 1),
            'description' => 'Registro menor', 'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }
    $response = insightsApiRequest($token, $closed ? 'filter[year]=2026&filter[month]=9' : '')
        ->assertOk()->assertJsonPath('data.0.attributes.type', 'expense_concentration');
    $attributes = $response->json('data.0.attributes');
    $identity = str_replace('{date}', $closed ? '05/09' : '05/10', $identity);

    $monthName = $closed ? 'setembro' : 'outubro';
    expect($attributes['title'])->toBe($identity)
        ->and($attributes['description'])->toBeIn([
            'R$ 1.200 em '.$monthName.'; maior lançamento.',
            'Maior lançamento em '.$monthName.': R$ 1.200.',
            'Em '.$monthName.', R$ 1.200; maior lançamento.',
            'R$ 1.200; maior registro de '.$monthName.'.',
        ])
        ->and(array_keys($attributes))->toEqualCanonicalizing(['group', 'type', 'title', 'description', 'period'])
        ->and($attributes['period']['from'])->toBe($month.'-01')
        ->and($attributes['period']['to'])->toBe($closed ? '2026-09-30' : '2026-10-12');
})->with(['current' => false, 'closed' => true])->with([
    'literal description' => [" \n<b>Aluguel</b>\t{month} ", '<b>Aluguel</b> {month}'],
    'fallback without description' => [null, 'Outros · {date}'],
    'fallback with blank description' => [" \t\n ", 'Outros · {date}'],
    'fallback with a complete description beyond the editorial budget' => [str_repeat('x', 64), 'Outros · {date}'],
]);

it('rejects missing invalid expired and revoked tokens before analytical access', function (string $state, string $query): void {
    $token = 'invalid';
    if (in_array($state, ['expired', 'revoked'], true)) {
        $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
        $token = IdentityFixture::token($user, expiresAt: $state === 'expired' ? now()->subSecond() : now()->addDays(30));
        if ($state === 'revoked') {
            PersonalAccessToken::findToken($token)->delete();
        }
    }
    $port = $this->createMock(ExpenseAnalysisRepository::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisRepository::class, $port);
    $response = $state === 'missing'
        ? $this->getJson(route('insights.index').($query === '' ? '' : '?'.$query))
        : insightsApiRequest($token, $query);

    $response->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonMissingPath('data');
})->with(['missing', 'invalid', 'expired', 'revoked'])->with([
    'default' => '', 'explicit current' => 'filter[year]=2026&filter[month]=10', 'closed' => 'filter[year]=2026&filter[month]=9',
]);

it('blocks inactive or unverified accounts before analytical access', function (string $state, string $query): void {
    $user = IdentityFixture::create(
        status: $state === 'unverified' ? UserStatusEnum::Active : UserStatusEnum::from($state),
        verifiedAt: $state === 'unverified' ? null : now(),
    );
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $port = $this->createMock(ExpenseAnalysisRepository::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisRepository::class, $port);

    insightsApiRequest($token, $query)->assertForbidden()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonMissingPath('data');
})->with(['pending', 'blocked', 'unverified'])->with([
    'default' => '', 'explicit current' => 'filter[year]=2026&filter[month]=10', 'closed' => 'filter[year]=2026&filter[month]=9',
]);

it('rejects unsupported query parameters including empty values without analyzing expenses', function (string $query, string $parameter): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $port = $this->createMock(ExpenseAnalysisRepository::class);
    $port->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisRepository::class, $port);

    insightsApiRequest($token, $query)->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.status', '422')
        ->assertJsonPath('errors.0.source.parameter', $parameter)
        ->assertJsonMissingPath('data');
})->with([
    ['user_id=999', 'user_id'], ['period=2026-09', 'period'], ['family=1', 'family'],
    ['limit=6', 'limit'], ['page[size]=20', 'page[size]'], ['include=user', 'include'],
    ['filter[category]=food', 'filter[category]'], ['unknown=', 'unknown'], ['user_id=', 'user_id'],
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
    $userId = $user->getKey();
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

it('keeps IDs and wording while refreshing the real amount after a confirmed edit', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    recordInsightsApiBase($userId, '2026-10');
    DB::table('expenses')->where('user_id', $userId)->where('occurred_on', '>=', '2026-10-04')->update(['category' => 'other']);
    $first = insightsApiRequest($token)->assertOk()->json('data.0');
    DB::table('expenses')->where('user_id', $userId)->where('occurred_on', '2026-10-01')->update(['amount' => 3000]);
    $second = insightsApiRequest($token)->assertOk()->json('data.0');

    expect($first['id'])->toBe($second['id'])
        ->and($first['attributes']['title'])->toBe($second['attributes']['title'])
        ->and($first['attributes']['description'])->toContain('R$ 60')
        ->and($second['attributes']['description'])->toBe(str_replace('R$ 60', 'R$ 70', $first['attributes']['description']))->not->toContain('%');
});

it('resolves the reference date in app timezone and excludes only future historical records', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $userId = $user->getKey();
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    Date::setTestNow('2026-10-13 00:30:00 UTC');
    config()->set('app.timezone', 'America/Sao_Paulo');
    DB::table('expenses')->insert([
        'id' => (string) Str::uuid7(),
        'user_id' => $userId, 'amount' => 10000, 'category' => 'food', 'occurred_on' => '2026-10-13',
        'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
    ]);

    insightsApiRequest($token)->assertOk()->assertJsonPath('data.0.attributes.type', 'first_expense');
});

it('uses the authenticated throttle policy before analytical access', function (string $query): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $key = $this->resources->namespace.'insights-api-throttle';
    RateLimiter::for('api.authenticated', static fn (): Limit => Limit::perMinute(1)->by($key));
    $period = new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining(
        $query === 'filter[year]=2026&filter[month]=9' ? '2026-09-01' : '2026-10-01',
    ));
    $analysis = $this->app->make(ExpenseAnalysisRepository::class)->analyze($user->getKey(), $period);
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->once())->method('analyze')->with($user->getKey(), $period)->willReturn($analysis);
    $this->app->instance(ExpenseAnalysisRepository::class, $repository);
    insightsApiRequest($token, $query)->assertOk();
    insightsApiRequest($token, $query)->assertTooManyRequests()->assertHeader('Retry-After')
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonMissingPath('data');
})->with([
    'default' => '', 'explicit current' => 'filter[year]=2026&filter[month]=10', 'closed' => 'filter[year]=2026&filter[month]=9',
]);

it('extends the successful session and does not extend a rejected query', function (string $query): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $record = PersonalAccessToken::findToken($token);
    $originalExpiry = $record->expires_at;
    Date::setTestNow('2026-10-28 12:00:00 UTC');

    insightsApiRequest($token, ($query === '' ? '' : $query.'&').'limit=6')->assertUnprocessable();
    expect($record->fresh()->expires_at->equalTo($originalExpiry))->toBeTrue();
    insightsApiRequest($token, $query)->assertOk();
    expect($record->fresh()->expires_at->greaterThan($originalExpiry))->toBeTrue();
})->with([
    'default' => '', 'explicit current' => 'filter[year]=2026&filter[month]=10', 'closed' => 'filter[year]=2026&filter[month]=9',
]);

it('returns an explicit JSON API failure without extending the session when analytical reading fails', function (string $query): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $record = PersonalAccessToken::findToken($token);
    $originalExpiry = $record->expires_at;
    Date::setTestNow('2026-10-28 12:00:00 UTC');
    $failure = new RuntimeException('Analytical database unavailable');
    $port = $this->createMock(ExpenseAnalysisRepository::class);
    $port->expects($this->once())->method('analyze')->willThrowException($failure);
    $this->app->instance(ExpenseAnalysisRepository::class, $port);

    $handler = Exceptions::getFacadeRoot();
    Exceptions::fake();
    try {
        insightsApiRequest($token, $query)->assertStatus(500)->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
                'status' => '500', 'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.',
            ]]])->assertJsonMissingPath('data');
        Exceptions::assertReported(static fn (RuntimeException $exception): bool => $exception === $failure);
        Exceptions::assertReportedCount(1);
        expect($record->fresh()->expires_at->equalTo($originalExpiry))->toBeTrue();
    } finally {
        Exceptions::swap($handler);
    }
})->with([
    'default' => '', 'explicit current' => 'filter[year]=2026&filter[month]=10', 'closed' => 'filter[year]=2026&filter[month]=9',
]);

it('does not expose an individual endpoint for derived resource IDs', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $id = insightsApiRequest($token)->assertOk()->json('data.0.id');

    $this->getJson(route('insights.index')."/{$id}")->assertNotFound();
});
