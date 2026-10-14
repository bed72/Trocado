<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
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

it('keeps financial and onboarding identities identical for default explicit and normalized monthly filters', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach (['2026-10', '2026-09', '0026-09'] as $month) {
        foreach ([['01', 5000, 'other'], ['02', 500, 'other'], ['03', 500, 'other'], ['04', 2000, 'food'], ['05', 2000, 'food']] as [$day, $amount, $category]) {
            DB::table('expenses')->insert([
                'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
                'occurred_on' => "{$month}-{$day}",
                'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
            ]);
        }
    }

    foreach ([
        ['', '?filter[year]=2026&filter[month]=10', '?filter%5Bmonth%5D=10&filter%5Byear%5D=2026'],
        ['?filter[year]=2026&filter[month]=9', '?filter[month]=09&filter[year]=2026'],
        ['?filter[year]=26&filter[month]=9', '?filter[month]=09&filter[year]=0026'],
    ] as $queries) {
        $responses = [];
        foreach ($queries as $query) {
            Auth::forgetGuards();
            $responses[] = $this->withToken($token)->getJson(route('insights.index').$query)->assertOk()
                ->assertJsonCount(2, 'data')
                ->assertJsonPath('data.0.attributes.type', 'expense_concentration')
                ->assertJsonPath('data.1.attributes.type', 'category_review')
                ->assertJsonPath('data.1.attributes.period', null)->json('data');
        }

        foreach ($responses as $data) {
            expect($data)->toBe($responses[0]);
            foreach ($data as $resource) {
                expect($resource['type'])->toBe('insights')
                    ->and($resource['id'])->toBeString()->toMatch('/\A[0-9a-f]{64}\z/');
            }
        }
    }
});

it('distinguishes onboarding months by their internal periods even when both public periods are null', function (bool $review): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    if ($review) {
        foreach (['2026-08', '2026-09'] as $month) {
            foreach (['other', 'other', 'other', 'food', 'food'] as $index => $category) {
                DB::table('expenses')->insert([
                    'user_id' => $user->getKey(), 'amount' => 2000, 'category' => $category,
                    'occurred_on' => "{$month}-0".($index + 1),
                    'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
                ]);
            }
        }
    }

    $ids = [];
    foreach (['8' => 'ago/2026', '9' => 'set/2026'] as $month => $label) {
        Auth::forgetGuards();
        $data = $this->withToken($token)->getJson(route('insights.index')."?filter[year]=2026&filter[month]={$month}")
            ->assertOk()->assertJsonCount($review ? 2 : 1, 'data')->json('data');
        $types = array_column(array_column($data, 'attributes'), 'type');
        expect($types)->toBe($review ? ['category_review', 'insufficient_history'] : ['insufficient_history']);

        foreach ($data as $resource) {
            expect($resource['attributes']['period'])->toBeNull()
                ->and($resource['attributes']['group'])->toBe('onboarding')
                ->and($resource['attributes']['title'])->toContain($label);
            $ids[$month][$resource['attributes']['type']] = $resource['id'];
        }
    }

    foreach ($ids[8] as $type => $id) {
        expect($ids[9][$type])->not->toBe($id);
    }
})->with(['empty history' => false, 'review and insufficient history together' => true]);

it('keeps historical IDs through value description and daily variant changes while distinguishing the owner and selected month', function (): void {
    $owner = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'identity-owner@example.com');
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'identity-other@example.com');
    $token = IdentityFixture::token($owner, expiresAt: now()->addDays(30));
    $otherToken = IdentityFixture::token($other, expiresAt: now()->addDays(30));
    $largestId = null;

    foreach ([$owner, $other] as $user) {
        foreach (['2026-08', '2026-09'] as $month) {
            foreach ([['01', 5000, 'other'], ['02', 500, 'other'], ['03', 500, 'other'], ['04', 2000, 'food'], ['05', 2000, 'food']] as [$day, $amount, $category]) {
                $id = DB::table('expenses')->insertGetId([
                    'user_id' => $user->getKey(), 'amount' => $amount, 'category' => $category,
                    'occurred_on' => "{$month}-{$day}", 'description' => $day === '01' ? 'Aluguel' : null,
                    'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
                ]);
                if ($user === $owner && $month === '2026-09' && $day === '01') {
                    $largestId = $id;
                }
            }
        }
    }

    $url = route('insights.index').'?filter[year]=2026&filter[month]=9';
    $first = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(2, 'data')->json('data');
    expect($first[0]['attributes']['description'])->toContain('Aluguel', '50%');

    DB::table('expenses')->where('id', $largestId)->update([
        'amount' => 5500, 'description' => 'Mensalidade', 'updated_at' => '2026-10-12 12:00:00',
    ]);
    Auth::forgetGuards();
    $updated = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(2, 'data')->json('data');
    expect($updated[0]['attributes']['description'])->toContain('Mensalidade', '52%')
        ->and($updated[1]['attributes']['description'])->toContain('62%');

    Date::setTestNow('2026-10-13 12:00:00 UTC');
    Auth::forgetGuards();
    $next = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(2, 'data')->json('data');

    Auth::forgetGuards();
    $anotherMonth = $this->withToken($token)->getJson(route('insights.index').'?filter[year]=2026&filter[month]=8')
        ->assertOk()->assertJsonCount(2, 'data')->json('data');
    Auth::forgetGuards();
    $anotherOwner = $this->withToken($otherToken)->getJson($url)->assertOk()->assertJsonCount(2, 'data')->json('data');

    foreach ([0 => 'expense_concentration', 1 => 'category_review'] as $index => $type) {
        expect($first[$index]['attributes']['type'])->toBe($type)
            ->and($updated[$index]['attributes']['type'])->toBe($type)
            ->and($next[$index]['attributes']['type'])->toBe($type)
            ->and($anotherMonth[$index]['attributes']['type'])->toBe($type)
            ->and($anotherOwner[$index]['attributes']['type'])->toBe($type)
            ->and($updated[$index]['id'])->toBe($first[$index]['id'])
            ->and($next[$index]['id'])->toBe($first[$index]['id'])
            ->and($next[$index]['attributes']['description'])->not->toBe($updated[$index]['attributes']['description'])
            ->and($anotherMonth[$index]['id'])->not->toBe($first[$index]['id'])
            ->and($anotherOwner[$index]['id'])->not->toBe($first[$index]['id']);
    }

    expect($first[0]['id'])->not->toBe($first[1]['id']);
});

it('distinguishes contextual onboarding states without changing the selected month or public null period', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $url = route('insights.index').'?filter[year]=2026&filter[month]=9';
    $first = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.period', null)->json('data.0');

    DB::table('expenses')->insert([
        'user_id' => $user->getKey(), 'amount' => 2000, 'category' => 'food', 'occurred_on' => '2026-09-01',
        'created_at' => '2026-10-12 12:00:00', 'updated_at' => '2026-10-12 12:00:00',
    ]);
    Auth::forgetGuards();
    $second = $this->withToken($token)->getJson($url)->assertOk()->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.attributes.type', 'insufficient_history')
        ->assertJsonPath('data.0.attributes.period', null)->json('data.0');
    expect($second['id'])->not->toBe($first['id']);
});
