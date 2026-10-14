<?php

declare(strict_types=1);

use App\Core\Application\Ports\DatePort;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
});

afterEach(function (): void {
    Date::setTestNow();
});

it('rejects malformed incomplete future duplicate and unknown filters without analytical access', function (string $query, string $parameter): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisRepository::class, $repository);

    $response = $this->withToken($token)->getJson(route('insights.index').'?'.$query)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonMissingPath('data');

    expect(array_column(array_column($response->json('errors'), 'source'), 'parameter'))->toContain($parameter);
})->with([
    'year alone' => ['filter[year]=2026', 'filter[month]'],
    'month alone' => ['filter[month]=9', 'filter[year]'],
    'empty year' => ['filter[year]=&filter[month]=9', 'filter[year]'],
    'empty month' => ['filter[year]=2026&filter[month]=', 'filter[month]'],
    'zero year' => ['filter[year]=0&filter[month]=9', 'filter[year]'],
    'zero month' => ['filter[year]=2026&filter[month]=00', 'filter[month]'],
    'month thirteen' => ['filter[year]=2026&filter[month]=13', 'filter[month]'],
    'year too long' => ['filter[year]=10000&filter[month]=9', 'filter[year]'],
    'leading year whitespace' => ['filter[year]=%202026&filter[month]=9', 'filter[year]'],
    'trailing whitespace' => ['filter[year]=2026&filter[month]=9%20', 'filter[month]'],
    'newline' => ['filter[year]=2026&filter[month]=9%0A', 'filter[month]'],
    'plus year' => ['filter[year]=%2B2026&filter[month]=9', 'filter[year]'],
    'minus month' => ['filter[year]=2026&filter[month]=-9', 'filter[month]'],
    'fraction' => ['filter[year]=2026&filter[month]=9.0', 'filter[month]'],
    'exponent' => ['filter[year]=2e3&filter[month]=9', 'filter[year]'],
    'unicode digits' => ['filter[year]=2026&filter[month]=９', 'filter[month]'],
    'month too long' => ['filter[year]=2026&filter[month]=009', 'filter[month]'],
    'year array' => ['filter[year][]=2026&filter[month]=9', 'filter[year]'],
    'month object' => ['filter[year]=2026&filter[month][x]=9', 'filter[month]'],
    'scalar filter' => ['filter=2026-09', 'filter'],
    'unknown nested filter' => ['filter[year]=2026&filter[month]=9&filter[category]=food', 'filter[category]'],
    'unknown root' => ['month=9', 'month'],
    'duplicate same month' => ['filter[year]=2026&filter[month]=9&filter[month]=9', 'filter[month]'],
    'duplicate different month' => ['filter[year]=2026&filter[month]=9&filter[month]=10', 'filter[month]'],
    'duplicate year' => ['filter[year]=2026&filter[year]=2026&filter[month]=9', 'filter[year]'],
    'encoded duplicate name' => ['filter[year]=2026&filter[month]=9&filter%5Bmonth%5D=09', 'filter[month]'],
    'encoded root duplicate' => ['filter[year]=2026&filter[month]=9&%66ilter%5Bmonth%5D=9', 'filter[month]'],
    'one decode only name' => ['filter[year]=2026&filter%255Bmonth%255D=9', 'filter%5Bmonth%5D'],
    'one decode only value' => ['filter[year]=2026&filter[month]=%2539', 'filter[month]'],
    'future month same year' => ['filter[year]=2026&filter[month]=11', 'filter[month]'],
    'future next year' => ['filter[year]=2027&filter[month]=1', 'filter[month]'],
    'January lower bound' => ['filter[year]=1&filter[month]=1', 'filter[year]'],
    'February lower bound' => ['filter[year]=0001&filter[month]=02', 'filter[year]'],
]);

it('keeps default explicit current and leading zero representations identical', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $responses = [];

    foreach (['', '?filter[year]=2026&filter[month]=10', '?filter%5Byear%5D=2026&filter%5Bmonth%5D=10'] as $query) {
        Auth::forgetGuards();
        $responses[] = $this->withToken($token)->getJson(route('insights.index').$query)->assertOk()->json();
    }

    expect($responses[0])->toBe($responses[1])->toBe($responses[2]);

    Auth::forgetGuards();
    $plain = $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=9')->assertOk()->json();
    Auth::forgetGuards();
    $zero = $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=09')->assertOk()->json();

    expect($plain)->toBe($zero)
        ->and($plain['data'][0]['attributes']['type'])->toBe('insufficient_history')
        ->and($plain['data'][0]['attributes']['period'])->toBeNull()
        ->and($plain['data'][0]['attributes']['title'])->toContain('set/2026')
        ->and($plain['data'][0]['id'])->not->toBe($responses[0]['data'][0]['id']);
});

it('resolves today once and ignores filters from the GET body', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $port = $this->createMock(DatePort::class);
    $port->expects($this->once())->method('today')->willReturn('2026-10-12');
    $this->app->instance(DatePort::class, $port);
    $analysis = $this->app->make(ExpenseAnalysisRepository::class)->analyze(
        (int) $user->getKey(), new InsightAnalysisPeriodValueObject('2026-10-12', DatePeriodValueObject::monthContaining('2026-10-12')),
    );
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->once())->method('analyze')->with((int) $user->getKey(), $this->callback(
        static fn (InsightAnalysisPeriodValueObject $period): bool => $period->currentMonth->from() === '2026-10-01'
            && $period->currentMonth->to() === '2026-10-12',
    ))->willReturn($analysis);
    $this->app->instance(ExpenseAnalysisRepository::class, $repository);

    $this->withToken($token)->json('GET', route('insights.index'), ['filter' => ['year' => '2025', 'month' => '2']])
        ->assertOk()->assertJsonPath('data.0.attributes.type', 'first_expense');
});

it('returns historical periods with inclusive February leap and year boundaries', function (string $year, string $month, string $from, string $to): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach (['01', '02', '03', '04', substr($to, 8)] as $day) {
        DB::table('expenses')->insert([
            'user_id' => $user->getKey(), 'amount' => 2000, 'category' => 'food',
            'occurred_on' => substr($from, 0, 8).$day,
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    $this->withToken($token)->getJson(route('insights.index')."?filter[year]={$year}&filter[month]={$month}")
        ->assertOk()->assertJsonPath('data.0.attributes.type', 'category_concentration')
        ->assertJsonPath('data.0.attributes.period.from', $from)
        ->assertJsonPath('data.0.attributes.period.to', $to)
        ->assertJsonPath('data.0.attributes.period.comparison', null);
})->with([
    ['2024', '02', '2024-02-01', '2024-02-29'],
    ['2025', '2', '2025-02-01', '2025-02-28'],
    ['2026', '1', '2026-01-01', '2026-01-31'],
    ['0001', '03', '0001-03-01', '0001-03-31'],
]);

it('uses the application civil month instead of UTC to reject future filters', function (): void {
    Date::setTestNow('2026-10-01 00:30:00 UTC');
    config()->set('app.timezone', 'America/Sao_Paulo');
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->never())->method('analyze');
    $this->app->instance(ExpenseAnalysisRepository::class, $repository);

    $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=10')
        ->assertUnprocessable()->assertJsonPath('errors.0.source.parameter', 'filter[month]');
});

it('compares full historical totals and confines recurring leadership to the three selected months', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-monthly-leader@example.com');

    foreach (['2026-07' => ['31', 8000], '2026-08' => ['31', 8000], '2026-09' => ['30', 10000], '2026-10' => ['05', 999999]] as $month => [$lastDay, $amount]) {
        foreach (['01', '02', '03', '04', $lastDay] as $day) {
            DB::table('expenses')->insert([
                'user_id' => $user->getKey(), 'amount' => $amount, 'category' => 'food',
                'occurred_on' => "{$month}-{$day}",
                'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
            ]);
            DB::table('expenses')->insert([
                'user_id' => $other->getKey(), 'amount' => 9000000, 'category' => 'health',
                'occurred_on' => "{$month}-{$day}",
                'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
            ]);
        }
    }

    $response = $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=9')
        ->assertOk()->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.attributes.type', 'registered_amount_increase')
        ->assertJsonPath('data.0.attributes.period.from', '2026-09-01')
        ->assertJsonPath('data.0.attributes.period.to', '2026-09-30')
        ->assertJsonPath('data.0.attributes.period.comparison.from', '2026-08-01')
        ->assertJsonPath('data.0.attributes.period.comparison.to', '2026-08-31')
        ->assertJsonPath('data.1.attributes.type', 'category_lead_streak')
        ->assertJsonPath('data.1.attributes.period.from', '2026-07-01')
        ->assertJsonPath('data.1.attributes.period.to', '2026-09-30')
        ->assertJsonPath('data.1.attributes.period.comparison', null);

    expect($response->json('data.0.attributes.description'))->toContain('+25%', 'ago/2026')
        ->and($response->json('data.0.attributes.title'))->toContain('set/2026')
        ->and($response->json('data.1.attributes.description'))->toContain('jul/2026', 'set/2026');
});
