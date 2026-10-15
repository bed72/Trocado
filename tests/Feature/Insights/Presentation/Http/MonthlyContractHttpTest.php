<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
});

afterEach(function (): void {
    Date::setTestNow();
});

it('serializes the owner only historical comparison maximum and review through one read with no expense identifiers or writes', function (): void {
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'monthly-contract-owner@example.com');
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'monthly-contract-other@example.com');
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    $ownerId = $owner->getKey();
    $otherId = $other->getKey();

    foreach (['2026-07', '2026-08', '2026-09', '2026-10'] as $month) {
        foreach (['01', '02', '03', '04', '05'] as $day) {
            ExpenseQueryHistoryFixture::create($otherId, "{$month}-{$day}", 9000000, 'health', 'Identificação privada de outra conta');
        }
    }
    foreach (['2026-07', '2026-08'] as $month) {
        foreach (['01', '02', '03', '04', '31'] as $day) {
            ExpenseQueryHistoryFixture::create($ownerId, "{$month}-{$day}", 20000, 'food');
        }
    }
    ExpenseQueryHistoryFixture::create($ownerId, '2026-09-30', 120000, 'other', " \n<b>Aluguel</b>\t{month} ");
    foreach (['food', 'health', 'transport', 'leisure'] as $index => $category) {
        ExpenseQueryHistoryFixture::create($ownerId, '2026-09-0'.($index + 1), 25000, $category);
    }
    ExpenseQueryHistoryFixture::create($ownerId, '2026-10-01', 9000000, 'housing', 'Despesa posterior ao mês selecionado');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $response = $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=9')
            ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.attributes.type', 'registered_amount_increase')
            ->assertJsonPath('data.0.attributes.group', 'comparison')
            ->assertJsonPath('data.0.attributes.period.from', '2026-09-01')
            ->assertJsonPath('data.0.attributes.period.to', '2026-09-30')
            ->assertJsonPath('data.0.attributes.period.comparison.from', '2026-08-01')
            ->assertJsonPath('data.0.attributes.period.comparison.to', '2026-08-31')
            ->assertJsonPath('data.1.attributes.type', 'expense_concentration')
            ->assertJsonPath('data.1.attributes.group', 'observation')
            ->assertJsonPath('data.1.attributes.period.from', '2026-09-01')
            ->assertJsonPath('data.1.attributes.period.to', '2026-09-30')
            ->assertJsonPath('data.1.attributes.period.comparison', null)
            ->assertJsonPath('data.2.attributes.type', 'category_review')
            ->assertJsonPath('data.2.attributes.group', 'onboarding')
            ->assertJsonPath('data.2.attributes.period', null);
        $analyticalQueries = array_values(array_filter(DB::getQueryLog(), static fn (array $query): bool => str_starts_with($query['query'], 'WITH periods')));
        expect($analyticalQueries)->toHaveCount(1);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }

    expect(array_keys($response->json()))->toBe(['data'])
        ->and($response->json('data.0.attributes.description'))->toContain('+120%', 'ago/2026')
        ->and($response->json('data.1.attributes.description'))->toBeString()->toContain('<b>Aluguel</b> {month}', '55%')
        ->and($response->json('data.2.attributes.description'))->toContain('55%')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);

    foreach ($response->json('data') as $resource) {
        expect(array_keys($resource))->toEqualCanonicalizing(['type', 'id', 'attributes'])
            ->and($resource['type'])->toBe('insights')
            ->and($resource['id'])->toBeString()->toMatch('/\A[0-9a-f]{64}\z/')
            ->and(array_keys($resource['attributes']))->toEqualCanonicalizing(['group', 'type', 'title', 'description', 'period'])
            ->and($resource['attributes']['title'])->toBeString()->toContain('set/2026')
            ->and($resource['attributes']['description'])->toBeString()
            ->not->toContain('Identificação privada de outra conta', 'Despesa posterior ao mês selecionado')
            ->and(mb_strlen($resource['attributes']['title'], 'UTF-8'))->toBeLessThanOrEqual(24)
            ->and(mb_strlen($resource['attributes']['description'], 'UTF-8'))->toBeLessThanOrEqual(80);
        $period = $resource['attributes']['period'];
        if ($period !== null) {
            expect(array_keys($period))->toEqualCanonicalizing(['from', 'to', 'comparison']);
            if ($period['comparison'] !== null) {
                expect(array_keys($period['comparison']))->toEqualCanonicalizing(['from', 'to']);
            }
        }
    }
});

it('does not use another account history to fabricate financial insights or suppress the first expense for an empty owner', function (): void {
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'empty-monthly-owner@example.com');
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'populated-monthly-owner@example.com');
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));

    foreach (['2026-01', '2026-07', '2026-08', '2026-09', '2026-10'] as $month) {
        foreach (['01', '02', '03', '04', '05'] as $day) {
            ExpenseQueryHistoryFixture::create($other->getKey(), "{$month}-{$day}", 9000000, 'other', 'Histórico de outra conta');
        }
    }
    ExpenseQueryHistoryFixture::create($owner->getKey(), '2026-10-13', 9000000, 'food');
    $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=10')
        ->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'first_expense')
        ->assertJsonPath('data.0.attributes.period', null);

    Auth::forgetGuards();
    $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=9')
        ->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.period', null);
});
