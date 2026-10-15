<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use App\Metrics\Application\Repositories\ExpenseMetricsRepository;
use App\Metrics\Infrastructure\Repositories\Persistence\EloquentExpenseMetricsRepository;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException as OperationalFailureException;
use Tests\FeatureTestCase;
use Tests\Support\Identity\Fixtures\IdentityFixture;

function insertHttpMetricsExpense(string $userId, int $amount, string $category = 'other', string $date = '2026-10-09'): void
{
    DB::table('expenses')->insert([
        'id' => (string) Str::uuid7(),
        'user_id' => $userId, 'amount' => $amount, 'category' => $category, 'occurred_on' => $date,
        'created_at' => '2026-11-01 12:00:00', 'updated_at' => '2026-11-01 12:00:00',
    ]);
}

it('exposes the bound adapter through a singular exact JSON API summary in both modes', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    insertHttpMetricsExpense($identity->getKey(), 60000, 'food');
    insertHttpMetricsExpense($identity->getKey(), 30000, 'transport');
    insertHttpMetricsExpense($identity->getKey(), 10000);
    expect(app(ExpenseMetricsRepository::class))->toBeInstanceOf(EloquentExpenseMetricsRepository::class);

    $simple = $this->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31')
        ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('data.type', 'expense-metrics')
        ->assertJsonPath('data.attributes', [
            'end_date' => '2026-10-31', 'total_amount' => '100000', 'start_date' => '2026-10-01',
        ]);
    $grouped = $this->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category')
        ->assertOk()->assertJsonPath('data.attributes.categories', [
            ['category' => 'food', 'percentage' => '60.00', 'total_amount' => '60000'],
            ['category' => 'transport', 'percentage' => '30.00', 'total_amount' => '30000'],
            ['category' => 'other', 'percentage' => '10.00', 'total_amount' => '10000'],
        ]);
    foreach ([$simple, $grouped] as $response) {
        expect($response->json('data.id'))->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/');
    }
    expect($simple->json('data.id'))->not->toBe($grouped->json('data.id'));
});

it('aggregates each new persisted identifier without translations or absent categories', function (string $category): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    insertHttpMetricsExpense($identity->getKey(), 10000, $category);
    $this->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category')
        ->assertOk()->assertJsonPath('data.attributes.total_amount', '10000')
        ->assertJsonPath('data.attributes.categories', [
            ['category' => $category, 'percentage' => '100.00', 'total_amount' => '10000'],
        ]);
})->with(['financing', 'investments', 'taxes', 'insurance', 'personal_care', 'pets', 'gifts_and_donations', 'travel']);

it('includes investments and financing in the same exact denominator while excluding other owners and periods', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    insertHttpMetricsExpense($identity->getKey(), 60000, 'investments', '2026-10-01');
    insertHttpMetricsExpense($identity->getKey(), 30000, 'financing', '2026-10-31');
    insertHttpMetricsExpense($identity->getKey(), 10000, 'food');
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-expanded-metrics@example.com');
    foreach (['investments', 'financing', 'food'] as $category) {
        insertHttpMetricsExpense($other->id, 90000, $category);
        insertHttpMetricsExpense($identity->getKey(), 90000, $category, '2026-09-30');
        insertHttpMetricsExpense($identity->getKey(), 90000, $category, '2026-11-01');
    }
    $url = '/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31';
    $this->getJson($url)->assertOk()->assertJsonPath('data.attributes', [
        'end_date' => '2026-10-31', 'total_amount' => '100000', 'start_date' => '2026-10-01',
    ]);
    $this->getJson($url.'&group_by=category')->assertOk()->assertJsonPath('data.attributes.total_amount', '100000')
        ->assertJsonPath('data.attributes.categories', [
            ['category' => 'investments', 'percentage' => '60.00', 'total_amount' => '60000'],
            ['category' => 'financing', 'percentage' => '30.00', 'total_amount' => '30000'],
            ['category' => 'food', 'percentage' => '10.00', 'total_amount' => '10000'],
        ]);
});

it('orders tied new categories alphabetically with independently rounded percentages', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    foreach (['travel', 'investments', 'financing'] as $category) {
        insertHttpMetricsExpense($identity->getKey(), 10000, $category);
    }
    $this->getJson('/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category')
        ->assertOk()->assertJsonPath('data.attributes.total_amount', '30000')
        ->assertJsonPath('data.attributes.categories', [
            ['category' => 'financing', 'percentage' => '33.33', 'total_amount' => '10000'],
            ['category' => 'investments', 'percentage' => '33.33', 'total_amount' => '10000'],
            ['category' => 'travel', 'percentage' => '33.33', 'total_amount' => '10000'],
        ]);
});

it('rejects the original invalid query before reading expenses with and without records', function (string $query, string $parameter, bool $hasExpenses): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    if ($hasExpenses) {
        insertHttpMetricsExpense($identity->getKey(), 100);
    }

    $repository = $this->createMock(ExpenseMetricsRepository::class);
    $repository->expects($this->never())->method('summarize');
    $this->app->instance(ExpenseMetricsRepository::class, $repository);
    $response = $this->getJson('/api/metrics/expenses?'.$query)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json');
    $errors = $response->json('errors');
    expect(array_column(array_column($errors, 'source'), 'parameter'))->toContain($parameter)
        ->and($response->json())->not->toHaveKey('data')
        ->and(DB::table('resource_identities')->count())->toBe(0);

    foreach ($errors as $error) {
        expect($error['title'])->toBe('Parâmetro inválido')
            ->and($error['status'])->toBe('422')
            ->and($error['detail'])->toBeString()
            ->and($error['source'])->not->toHaveKey('pointer');
    }
})->with([
    ['start_date=2026-10-01', 'end_date'],
    ['end_date=2026-10-31', 'start_date'],
    ['start_date=&end_date=', 'start_date'],
    ['start_date&end_date=2026-10-31', 'start_date'],
    ['start_date=%20%20&end_date=2026-10-31', 'start_date'],
    ['start_date=2026-02-30&end_date=2026-10-31', 'start_date'],
    ['start_date=2027-02-29&end_date=2027-03-01', 'start_date'],
    ['start_date=01/10/2026&end_date=2026-10-31', 'start_date'],
    ['start_date=2026-1-1&end_date=2026-10-31', 'start_date'],
    ['start_date=today&end_date=2026-10-31', 'start_date'],
    ['start_date=2026-10-01T00:00:00Z&end_date=2026-10-31', 'start_date'],
    ['start_date=2026-10-31&end_date=2026-10-01', 'end_date'],
    ['group_by=', 'group_by'],
    ['group_by=%20%20', 'group_by'],
    ['group_by=Category', 'group_by'],
    ['group_by=month', 'group_by'],
    ['group_by=none', 'group_by'],
    ['group_by=category,month', 'group_by'],
    ['group_by=cate%20gory', 'group_by'],
    ['group_by=%7B%22value%22:%22category%22%7D', 'group_by'],
    ['foo=bar', 'foo'],
    ['user_id=1', 'user_id'],
    ['timezone=UTC', 'timezone'],
    ['currency=BRL', 'currency'],
    ['page[size]=10', 'page[size]'],
    ['start.date=2026-10-01', 'start.date'],
    ['start%20date=2026-10-01', 'start date'],
    ['group_by[]=category', 'group_by'],
    ['start_date[]=2026-10-01&end_date=2026-10-31', 'start_date'],
    ['end_date[value]=2026-10-31&start_date=2026-10-01', 'end_date'],
    ['group_by=category&group_by=category', 'group_by'],
    ['group_by[]=category&group_by=category', 'group_by'],
    ['start_date=2026-10-01&start_date=2026-11-01&end_date=2026-11-30', 'start_date'],
    ['start_date=2026-10-01&start%5Fdate=2026-10-01&end_date=2026-10-31', 'start_date'],
])->with([false, true]);

it('uses the whole civil month in the application timezone and keeps equivalent IDs', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    config(['app.timezone' => 'America/Sao_Paulo']);
    Carbon::setTestNow(Carbon::parse('2026-11-01 01:00:00', 'UTC'));
    insertHttpMetricsExpense($identity->getKey(), 123, 'other', '2026-10-31');
    $default = $this->getJson('/api/metrics/expenses?group_by=category')->assertOk();
    $explicit = $this->getJson('/api/metrics/expenses?group_by=%20category%20&end_date=2026-10-31&start_date=%202026-10-01%20')->assertOk();
    expect($default->json('data'))->toBe($explicit->json('data'))
        ->and($default->json('data.attributes.start_date'))->toBe('2026-10-01')
        ->and($default->json('data.attributes.total_amount'))->toBe('123');
});

it('returns zero with omission or an empty category list and ignores a GET body', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    Carbon::setTestNow('2026-10-09');
    $this->json('GET', '/api/metrics/expenses', ['group_by' => 'invalid', 'start_date' => 'bad'])
        ->assertOk()->assertJsonPath('data.attributes', [
            'end_date' => '2026-10-31', 'total_amount' => '0', 'start_date' => '2026-10-01',
        ]);
    $this->getJson('/api/metrics/expenses?group_by=category')
        ->assertOk()->assertJsonPath('data.attributes.categories', []);
});

it('preserves huge totals and zero-rounded shares in JSON', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    insertHttpMetricsExpense($identity->getKey(), 4000000000000000000, 'food');
    insertHttpMetricsExpense($identity->getKey(), 4000000000000000000, 'food');
    insertHttpMetricsExpense($identity->getKey(), 4000000000000000000, 'food');
    insertHttpMetricsExpense($identity->getKey(), 1);
    $this->getJson('/api/metrics/expenses?start_date=2026-10-09&end_date=2026-10-09&group_by=category')
        ->assertOk()->assertJsonPath('data.attributes.total_amount', '12000000000000000001')
        ->assertJsonPath('data.attributes.categories.1', ['category' => 'other', 'percentage' => '0.00', 'total_amount' => '1']);
});

it('blocks unauthenticated inactive and unverified accounts before reading metrics', function (string $condition, int $status): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    $repository = $this->createMock(ExpenseMetricsRepository::class);
    $repository->expects($this->never())->method('summarize');
    $this->app->instance(ExpenseMetricsRepository::class, $repository);

    if ($condition === 'unauthenticated') {
        $this->withHeader('Authorization', 'Bearer invalid');
    } elseif ($condition === 'unverified') {
        UserModel::query()->whereKey($identity->getKey())->update(['email_verified_at' => null]);
    } else {
        UserModel::query()->whereKey($identity->getKey())->update(['status' => $condition]);
    }

    $this->getJson('/api/metrics/expenses')->assertStatus($status)
        ->assertHeader('Content-Type', 'application/vnd.api+json');
    expect(DB::table('resource_identities')->count())->toBe(0);
})->with([['unauthenticated', 401], ['blocked', 403], ['pending', 403], ['unverified', 403]]);

it('resolves leap and non leap default months including future recorded occurrences', function (string $reference, string $lastDay): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    Carbon::setTestNow($reference);
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    insertHttpMetricsExpense($identity->getKey(), 100, 'other', $lastDay);
    $this->getJson('/api/metrics/expenses')->assertOk()
        ->assertJsonPath('data.attributes.end_date', $lastDay)
        ->assertJsonPath('data.attributes.total_amount', '100');
})->with([['2027-02-09', '2027-02-28'], ['2028-02-09', '2028-02-29']]);

it('keeps identity stable after writes and excludes another account', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    $other = DB::table('users')->insertGetId(['id' => (string) Str::uuid7(), 'name' => 'Pedro', 'email' => 'other-http@example.com', 'password' => 'unused']);
    insertHttpMetricsExpense($other, 90000, 'food');
    $url = '/api/metrics/expenses?start_date=2026-10-01&end_date=2026-10-31&group_by=category';
    $empty = $this->getJson($url)->assertOk()->assertJsonPath('data.attributes.total_amount', '0');
    insertHttpMetricsExpense($identity->getKey(), 100, 'food');
    $updated = $this->getJson($url)->assertOk()->assertJsonPath('data.attributes.total_amount', '100');
    expect($updated->json('data.id'))->toBe($empty->json('data.id'));
});

it('returns an explicit sanitized operational error instead of zero', function (): void {
    /** @var FeatureTestCase $this */
    $identity = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($identity, expiresAt: now()->addDays(30)));
    $repository = $this->createMock(ExpenseMetricsRepository::class);
    $repository->expects($this->once())->method('summarize')
        ->willThrowException(new OperationalFailureException('private SQL and credentials'));
    $this->app->instance(ExpenseMetricsRepository::class, $repository);
    $response = $this->getJson('/api/metrics/expenses')->assertStatus(500)
        ->assertHeader('Content-Type', 'application/vnd.api+json');
    expect($response->json())->not->toHaveKey('data')
        ->and($response->getContent())->not->toContain('private SQL and credentials');
});

it('returns API authentication errors without requiring an Accept header', function (): void {
    /** @var FeatureTestCase $this */
    $this->withHeader('Authorization', 'Bearer invalid');
    $this->get('/api/metrics/expenses')->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json');
});
