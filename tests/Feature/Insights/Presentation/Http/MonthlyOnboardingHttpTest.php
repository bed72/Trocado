<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
});

afterEach(function (): void {
    Date::setTestNow();
});

it('returns only localized onboarding for absent or insufficient selected records', function (
    string $query, array $dates, string $type, string $month, string $meaning,
): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach ($dates as $date) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => 2000, 'category' => 'food', 'occurred_on' => $date,
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    $response = $this->withToken($token)->getJson(route('insights.index').$query)
        ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.type', 'insights')
        ->assertJsonPath('data.0.attributes.group', 'onboarding')
        ->assertJsonPath('data.0.attributes.type', $type)
        ->assertJsonPath('data.0.attributes.period', null);
    $attributes = $response->json('data.0.attributes');

    expect($attributes['title'].' '.$attributes['description'])->toContain($month)
        ->and($attributes['description'])->toMatch($meaning)
        ->and(mb_strlen($attributes['title'], 'UTF-8'))->toBeLessThanOrEqual(24)
        ->and(mb_strlen($attributes['description'], 'UTF-8'))->toBeLessThanOrEqual(80);

    if ($type === 'insufficient_history') {
        expect($attributes['description'])->not->toMatch('/primeira|econom|basta|garant/iu');
    }

    if ($month === 'set/2026') {
        expect($attributes['title'].' '.$attributes['description'])->not->toMatch('/out\/2026|até dia|neste mês/iu');
    }
})->with([
    'current without history' => ['', [], 'first_expense', 'out/2026', '/primeira/iu'],
    'current ignores future expenses' => ['', ['2026-10-13'], 'first_expense', 'out/2026', '/primeira/iu'],
    'old history outside the current analytical window' => ['', ['2026-01-01'], 'insufficient_history', 'out/2026', '/sem despesas|sem registros|nenhuma despesa|não há despesas/iu'],
    'few current records' => ['', ['2026-10-01', '2026-10-02'], 'insufficient_history', 'out/2026', '/não sustentam|insuficientes|sem observação|sem base/iu'],
    'historical without any history' => ['?filter[year]=2026&filter[month]=9', [], 'insufficient_history', 'set/2026', '/sem registros|nenhuma despesa|não tem despesas|não há despesas/iu'],
    'historical before the first record' => ['?filter[year]=2026&filter[month]=9', ['2026-10-01'], 'insufficient_history', 'set/2026', '/sem registros|nenhuma despesa|não tem despesas|não há despesas/iu'],
    'old history outside the selected analytical window' => ['?filter[year]=2026&filter[month]=9', ['2026-01-01'], 'insufficient_history', 'set/2026', '/sem registros|nenhuma despesa|não tem despesas|não há despesas/iu'],
    'two historical records including the last day' => ['?filter[year]=2026&filter[month]=9', ['2026-09-01', '2026-09-30', '2026-10-01'], 'insufficient_history', 'set/2026', '/não sustentam|insuficientes|sem observação|sem base/iu'],
]);

it('reviews other only with the selected material base and exact fifty percent threshold', function (
    array $expenses, bool $eligible, string $percent, string $month, string $query,
): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $prefix = $month === 'set/2026' ? '2026-09' : '2026-10';

    foreach ($expenses as [$day, $amount, $category]) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
            'occurred_on' => "{$prefix}-{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    DB::table('expenses')->insert([
        'id' => (string) Str::uuid7(),
        'user_id' => $user->getKey(), 'amount' => 999999, 'category' => 'other', 'occurred_on' => '2026-10-13',
        'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
    ]);

    $response = $this->withToken($token)->getJson(route('insights.index').$query)->assertOk();
    $attributes = array_column($response->json('data'), 'attributes');
    $reviews = array_values(array_filter($attributes, static fn (array $attribute): bool => $attribute['type'] === 'category_review'));

    expect($reviews)->toHaveCount($eligible ? 1 : 0)
        ->and(array_column($attributes, 'type'))->not->toContain('first_expense');

    if ($eligible) {
        expect($reviews[0]['group'])->toBe('onboarding')
            ->and($reviews[0]['period'])->toBeNull()
            ->and($reviews[0]['title'])->toBe('Outros · '.$month)
            ->and($reviews[0]['description'])->toContain($percent.'%', 'total registrado', 'categorias')
            ->not->toMatch('/incorret|pendente|econom|primeira/iu');

        if ($month === 'set/2026') {
            expect($reviews[0]['description'])->not->toMatch('/até dia|neste mês|out\/2026/iu');
        } else {
            expect($reviews[0]['description'])->toContain('dia 12');
        }

        $guidance = array_values(array_filter($attributes, static fn (array $attribute): bool => $attribute['type'] === 'insufficient_history'));
        expect($guidance)->toHaveCount(1);
    }
})->with([
    'sixty percent without financial observation' => [[['01', 2000, 'other'], ['02', 2000, 'other'], ['03', 2000, 'other'], ['04', 2000, 'food'], ['05', 2000, 'food']], true, '60'],
    'exact fifty percent' => [[['01', 2000, 'other'], ['02', 2000, 'other'], ['03', 1000, 'other'], ['04', 2500, 'food'], ['05', 2500, 'food']], true, '50'],
    'rounded fifty below threshold' => [[['01', 2000, 'other'], ['02', 2000, 'other'], ['03', 999, 'other'], ['04', 2500, 'food'], ['05', 2501, 'food']], false, '50'],
    'only four expenses' => [[['01', 2000, 'other'], ['02', 2000, 'other'], ['03', 2000, 'other'], ['04', 4000, 'food']], false, '60'],
    'only two dates' => [[['01', 2000, 'other'], ['01', 2000, 'other'], ['01', 2000, 'other'], ['02', 2000, 'food'], ['02', 2000, 'food']], false, '60'],
    'total below one hundred reais' => [[['01', 2000, 'other'], ['02', 2000, 'other'], ['03', 2000, 'other'], ['04', 2000, 'food'], ['05', 1999, 'food']], false, '60'],
])->with([
    'current' => ['out/2026', ''],
    'historical' => ['set/2026', '?filter[year]=2026&filter[month]=9'],
]);

it('keeps an eligible expense observation beside other review without insufficient history', function (string $month, string $query): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach ([['01', 5000, 'other'], ['02', 500, 'other'], ['03', 500, 'other'], ['04', 2000, 'food'], ['05', 2000, 'food']] as [$day, $amount, $category]) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
            'occurred_on' => "{$month}-{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    $response = $this->withToken($token)->getJson(route('insights.index').$query)
        ->assertOk()->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.attributes.type', 'expense_concentration')
        ->assertJsonPath('data.1.attributes.type', 'category_review')
        ->assertJsonPath('data.1.attributes.period', null);

    expect($response->json('data.0.attributes.description'))->toContain('50%')
        ->and($response->json('data.1.attributes.description'))->toContain('60%');
})->with([
    'current' => ['2026-10', ''],
    'historical' => ['2026-09', '?filter[year]=2026&filter[month]=9'],
]);
