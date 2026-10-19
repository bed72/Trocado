<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
    $this->owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $this->withToken(IdentityFixture::token($this->owner, expiresAt: now()->addDays(30)));
});

afterEach(function (): void {
    Date::setTestNow();
});

it('composes each expanded category at forty percent from isolated PostgreSQL facts in both monthly modes', function (string $category, string $label, bool $closed): void {
    $month = $closed ? '2026-09' : '2026-10';
    foreach ([$category, $category, 'food', 'health', 'transport'] as $index => $identifier) {
        ExpenseQueryHistoryFixture::create($this->owner->id, $month.'-0'.($index + 1), 20000, $identifier);
    }
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other-insight-category@example.com');
    ExpenseQueryHistoryFixture::create($other->id, $month.'-01', 900000, $category);
    ExpenseQueryHistoryFixture::create($this->owner->id, '2026-11-01', 900000, $category);
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $response = $this->getJson(route('insights.index', $closed ? ['filter' => ['year' => 2026, 'month' => 9]] : []))
        ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.type', 'insights')->assertJsonPath('data.0.attributes.type', 'category_concentration')
        ->assertJsonPath('data.0.attributes.group', 'observation')
        ->assertJsonPath('data.0.attributes.period.from', $month.'-01')
        ->assertJsonPath('data.0.attributes.period.to', $month.($closed ? '-30' : '-12'));
    $attributes = $response->json('data.0.attributes');
    expect($attributes['title'].' '.$attributes['description'])->toContain($label, 'R$ 400')->not->toContain('%')
        ->not->toMatch('/consumo|prejuízo|rendimento|retorno|patrimônio|renda|destino|capacidade financeira/iu')
        ->and(array_keys($attributes))->toEqualCanonicalizing(['group', 'type', 'title', 'description', 'period'])
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
})->with([
    ['financing', 'Financiamentos'], ['investments', 'Investimentos'], ['taxes', 'Impostos e taxas'],
    ['insurance', 'Seguros'], ['personal_care', 'Cuidados pessoais'], ['pets', 'Pets'],
    ['gifts_and_donations', 'Presentes e doações'], ['travel', 'Viagens'],
])->with(['current' => false, 'closed' => true]);

it('includes investment contributions in the denominator and deduplicates the matching largest expense', function (bool $closed): void {
    $month = $closed ? '2026-09' : '2026-10';
    foreach ([[60000, 'investments'], [10000, 'food'], [10000, 'health'], [10000, 'transport'], [10000, 'housing']] as $index => [$amount, $category]) {
        ExpenseQueryHistoryFixture::create($this->owner->id, $month.'-0'.($index + 1), $amount, $category);
    }
    $response = $this->getJson(route('insights.index', $closed ? ['filter' => ['year' => 2026, 'month' => 9]] : []))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.attributes.type', 'category_concentration');
    expect($response->json('data.0.attributes.title').' '.$response->json('data.0.attributes.description'))
        ->toContain('Investimentos', 'R$ 600')->not->toMatch('/%|consumo|prejuízo|rendimento|retorno|patrimônio|renda/iu');
})->with(['current' => false, 'closed' => true]);

it('preserves financing leadership across three eligible months and suppresses overlapping concentration cards', function (bool $closed): void {
    foreach ($closed ? ['2026-07', '2026-08', '2026-09'] : ['2026-08', '2026-09', '2026-10'] as $month) {
        for ($day = 1; $day <= 5; $day++) {
            ExpenseQueryHistoryFixture::create($this->owner->id, $month.'-0'.$day, 2000, 'financing');
        }
    }
    $response = $this->getJson(route('insights.index', $closed ? ['filter' => ['year' => 2026, 'month' => 9]] : []))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.attributes.group', 'comparison')
        ->assertJsonPath('data.0.attributes.type', 'category_lead_streak')
        ->assertJsonPath('data.0.attributes.period.from', $closed ? '2026-07-01' : '2026-08-01')
        ->assertJsonPath('data.0.attributes.period.to', $closed ? '2026-09-30' : '2026-10-12');
    expect($response->json('data.0.attributes.title').' '.$response->json('data.0.attributes.description'))->toContain('Financiamentos');
})->with(['current' => false, 'closed' => true]);
