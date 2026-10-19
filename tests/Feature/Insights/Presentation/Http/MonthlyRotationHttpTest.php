<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Auth;
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

it('keeps historical candidates ordered and stable within a day and rotates through a repeatable visit day cycle', function (array $dates): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach ([['01', 5000, 'other'], ['02', 500, 'other'], ['03', 500, 'other'], ['04', 2000, 'food'], ['30', 2000, 'food']] as [$day, $amount, $category]) {
        DB::table('expenses')->insert([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
            'occurred_on' => "2026-09-{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    $url = route('insights.index').'?filter[year]=2026&filter[month]=9';
    $responses = [];

    foreach ($dates as $date) {
        Date::setTestNow($date.' 12:00:00 UTC');
        Auth::forgetGuards();
        $response = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.attributes.type', 'expense_concentration')
            ->assertJsonPath('data.0.attributes.group', 'observation')
            ->assertJsonPath('data.0.attributes.period.from', '2026-09-01')
            ->assertJsonPath('data.0.attributes.period.to', '2026-09-30')
            ->assertJsonPath('data.1.attributes.type', 'category_review')
            ->assertJsonPath('data.1.attributes.group', 'onboarding')
            ->assertJsonPath('data.1.attributes.period', null);
        $data = $response->json('data');
        $responses[] = $data;

        expect($data[0]['attributes']['title'])->toBe('Outros · 01/09')
            ->and($data[0]['attributes']['description'])->toContain('R$ 50', 'setembro')->not->toContain('%')
            ->and($data[1]['attributes']['title'])->toContain('Outros')
            ->and($data[1]['attributes']['description'])->toContain('setembro', 'R$ 60')->not->toContain('%');

        Date::setTestNow($date.' 20:00:00 UTC');
        Auth::forgetGuards();
        expect($this->withToken($token)->getJson($url)->assertOk()->json('data'))->toBe($data);
    }

    foreach ([0, 1] as $index) {
        $descriptions = array_map(static fn (array $data): string => $data[$index]['attributes']['title'].' '.$data[$index]['attributes']['description'], $responses);
        expect(array_unique(array_slice($descriptions, 0, 4)))->toHaveCount(4)
            ->and($descriptions[1])->not->toBe($descriptions[0])
            ->and($descriptions[4])->toBe($descriptions[0]);
    }
})->with([
    'September visited on October 12 and following days' => [['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15', '2026-10-16']],
    'same selection visited across the query month boundary' => [['2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02', '2026-11-03']],
]);

it('updates values and eligibility immediately after confirmed same day expense changes', function (string $month, string $query, bool $insert): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $ids = [];

    foreach ([['01', 2000, 'food'], ['02', 1800, 'food'], ['03', 2200, 'housing'], ['04', 2100, 'transport'], ['05', 1900, 'other']] as [$day, $amount, $category]) {
        $ids[] = DB::table('expenses')->insertGetId([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
            'occurred_on' => "{$month}-{$day}",
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    $url = route('insights.index').$query;
    $first = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'category_concentration')->json('data.0.attributes');
    expect($first['description'])->toContain('R$ 38')->not->toContain('%');

    if ($insert) {
        $ids[] = DB::table('expenses')->insertGetId([
            'id' => (string) Str::uuid7(),
            'user_id' => $user->getKey(), 'amount' => 690, 'category' => 'food', 'occurred_on' => '2026-10-12',
            'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
        ]);
    } else {
        DB::table('expenses')->where('id', $ids[1])->update(['amount' => 2490, 'updated_at' => '2026-10-12 12:00:00']);
    }

    Auth::forgetGuards();
    $updated = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'category_concentration')->json('data.0.attributes');
    expect($updated['description'])->toContain('R$ 44,90')->not->toContain('%')
        ->and($updated['title'])->toBe($first['title'])
        ->and($updated['description'])->toBe(str_replace('R$ 38', 'R$ 44,90', $first['description']))
        ->and($updated['period'])->toBe($first['period']);

    $categories = ['food', 'housing', 'transport', 'other', 'leisure', 'education'];
    foreach ($ids as $index => $id) {
        DB::table('expenses')->where('id', $id)->update([
            'amount' => 2000, 'category' => $categories[$index], 'updated_at' => '2026-10-12 12:00:00',
        ]);
    }

    Auth::forgetGuards();
    $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.group', 'onboarding')
        ->assertJsonPath('data.0.attributes.period', null);
})->with([
    'new expense in the current day' => ['2026-10', '', true],
    'confirmed retroactive edit in September' => ['2026-09', '?filter[year]=2026&filter[month]=9', false],
]);

it('rotates historical text at the application civil midnight rather than UTC midnight', function (): void {
    config()->set('app.timezone', 'America/Sao_Paulo');
    Date::setTestNow('2026-10-12 02:30:00 UTC');
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $url = route('insights.index').'?filter[year]=2026&filter[month]=9';
    $first = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')->json('data.0.attributes');

    Date::setTestNow('2026-10-12 02:59:59 UTC');
    Auth::forgetGuards();
    expect($this->withToken($token)->getJson($url)->assertOk()->json('data.0.attributes'))->toBe($first);

    Date::setTestNow('2026-10-12 03:00:00 UTC');
    Auth::forgetGuards();
    $next = $this->withToken($token)->getJson($url)->assertOk()
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.period', null)->json('data.0.attributes');
    expect($next['title'].' '.$next['description'])->toContain('setembro de 2026')
        ->and([$next['title'], $next['description']])->not->toBe([$first['title'], $first['description']]);
});
