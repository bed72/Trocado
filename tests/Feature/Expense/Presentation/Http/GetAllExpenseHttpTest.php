<?php

declare(strict_types=1);

use App\Expense\Infrastructure\Repositories\Persistence\Models\ExpenseModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Tests\Support\Identity\Fixtures\IdentityFixture;

use function Pest\Laravel\withToken;

it('filters owned expenses by occurrence with inclusive civil bounds', function (array $filter, array $expected): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $other = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now(), email: 'other@example.com');
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach (['2025-12-31', '2026-01-01', '2026-09-30', '2026-10-01', '2026-10-11', '2026-10-31', '2026-11-01', '2026-12-31', '2027-01-01', '2024-02-29'] as $date) {
        ExpenseModel::query()->create([
            'user_id' => $user->getKey(), 'amount' => 1000, 'category' => 'food',
            'occurred_on' => $date, 'created_at' => '2026-10-11 12:00:00',
        ]);
    }

    ExpenseModel::query()->create([
        'user_id' => $other->getKey(), 'amount' => 1000, 'category' => 'food', 'occurred_on' => '2026-10-11',
    ]);

    $response = withToken($token)->getJson(route('expenses.index', $filter === [] ? [] : ['filter' => $filter]))->assertOk();

    expect(array_column(array_column($response->json('data'), 'attributes'), 'occurred_on'))->toBe($expected);
})->with([
    'no filters' => [[], ['2027-01-01', '2026-12-31', '2026-11-01', '2026-10-31', '2026-10-11', '2026-10-01', '2026-09-30', '2026-01-01', '2025-12-31', '2024-02-29']],
    'year' => [['year' => 2026], ['2026-12-31', '2026-11-01', '2026-10-31', '2026-10-11', '2026-10-01', '2026-09-30', '2026-01-01']],
    'month' => [['year' => 2026, 'month' => 10], ['2026-10-31', '2026-10-11', '2026-10-01']],
    'day' => [['year' => 2026, 'month' => 10, 'day' => 11], ['2026-10-11']],
    'leap day' => [['year' => 2024, 'month' => 2, 'day' => 29], ['2024-02-29']],
    'empty period' => [['year' => 2023], []],
    'first civil year' => [['year' => 1], []],
    'last civil month' => [['year' => 9999, 'month' => 12], []],
]);

it('rejects incomplete or invalid civil filters as JSON API validation errors', function (array $parameters, string $field): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    withToken($token)->getJson(route('expenses.index', $parameters))
        ->assertUnprocessable()->assertJsonStructure(['errors' => [['status', 'source']]])
        ->assertJsonFragment(['pointer' => '/'.str_replace(['[', ']'], ['/', ''], $field)]);
})->with([
    'month without year' => [['filter' => ['month' => 10]], 'filter[year]'],
    'day without year' => [['filter' => ['month' => 10, 'day' => 11]], 'filter[year]'],
    'day without month' => [['filter' => ['year' => 2026, 'day' => 11]], 'filter[month]'],
    'day alone' => [['filter' => ['day' => 11]], 'filter[year]'],
    'zero year' => [['filter' => ['year' => 0]], 'filter[year]'],
    'year above civil range' => [['filter' => ['year' => 10000]], 'filter[year]'],
    'fractional year' => [['filter' => ['year' => '2026.5']], 'filter[year]'],
    'empty year' => [['filter' => ['year' => '']], 'filter[year]'],
    'array year' => [['filter' => ['year' => [2026]]], 'filter[year]'],
    'zero month' => [['filter' => ['year' => 2026, 'month' => 0]], 'filter[month]'],
    'invalid month' => [['filter' => ['year' => 2026, 'month' => 13]], 'filter[month]'],
    'empty month' => [['filter' => ['year' => 2026, 'month' => '']], 'filter[month]'],
    'zero day' => [['filter' => ['year' => 2026, 'month' => 10, 'day' => 0]], 'filter[day]'],
    'invalid day' => [['filter' => ['year' => 2026, 'month' => 10, 'day' => 32]], 'filter[day]'],
    'February 31' => [['filter' => ['year' => 2026, 'month' => 2, 'day' => 31]], 'filter[day]'],
    'non leap February 29' => [['filter' => ['year' => 2026, 'month' => 2, 'day' => 29]], 'filter[day]'],
    'non leap century' => [['filter' => ['year' => 1900, 'month' => 2, 'day' => 29]], 'filter[day]'],
    'April 31' => [['filter' => ['year' => 2026, 'month' => 4, 'day' => 31]], 'filter[day]'],
    'empty day' => [['filter' => ['year' => 2026, 'month' => 10, 'day' => '']], 'filter[day]'],
    'scalar filter' => [['filter' => '2026'], 'filter'],
    'unknown filter' => [['filter' => ['year' => 2026, 'unknown' => 1]], 'filter'],
]);

it('preserves period and page size in forward and backward pagination', function (array $filter): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $ids = [];

    foreach (['2026-10-11', '2026-10-11', '2026-10-11', '2025-10-11', '2027-10-11'] as $date) {
        $model = ExpenseModel::query()->create([
            'user_id' => $user->getKey(), 'amount' => 1000, 'category' => 'food', 'occurred_on' => $date,
        ]);

        if ($date === '2026-10-11') {
            $ids[] = (string) $model->getKey();
        }
    }

    $first = withToken($token)->getJson(route('expenses.index', ['filter' => $filter, 'page' => ['size' => 1]]))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $ids[2])->assertJsonPath('links.prev', null);
    $next = $first->json('links.next');
    parse_str(parse_url($next, PHP_URL_QUERY), $query);
    expect($query['filter'])->toBe(array_map(strval(...), $filter))->and($query['page']['size'])->toBe('1');

    $second = withToken($token)->getJson($next)->assertOk()->assertJsonPath('data.0.id', $ids[1]);
    $previous = $second->json('links.prev');
    parse_str(parse_url($previous, PHP_URL_QUERY), $query);
    expect($query['filter'])->toBe(array_map(strval(...), $filter))->and($query['page']['size'])->toBe('1');
    withToken($token)->getJson($previous)->assertOk()->assertJsonPath('data.0.id', $ids[2]);
    withToken($token)->getJson($second->json('links.next'))
        ->assertOk()->assertJsonPath('data.0.id', $ids[0])->assertJsonPath('links.next', null);
})->with([
    'year' => [['year' => 2026]],
    'month' => [['year' => 2026, 'month' => 10]],
    'day' => [['year' => 2026, 'month' => 10, 'day' => 11]],
]);

it('returns the six most recent occurrences of a month rather than the latest registrations', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));

    foreach (['2026-09-30', '2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04', '2026-10-05', '2026-10-06', '2026-10-07', '2026-11-01'] as $date) {
        ExpenseModel::query()->create([
            'user_id' => $user->getKey(), 'amount' => 1000, 'category' => 'food', 'occurred_on' => $date,
            'created_at' => $date === '2026-10-01' ? '2026-12-01 12:00:00' : '2026-10-11 12:00:00',
        ]);
    }

    $response = withToken($token)->getJson(route('expenses.index', ['filter' => ['year' => 2026, 'month' => 10], 'page' => ['size' => 6]]))
        ->assertOk()->assertJsonCount(6, 'data');
    expect(array_column(array_column($response->json('data'), 'attributes'), 'occurred_on'))
        ->toBe(['2026-10-07', '2026-10-06', '2026-10-05', '2026-10-04', '2026-10-03', '2026-10-02']);
});

it('keeps default size and cursor navigation across years when filters are absent', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $ids = [];

    for ($year = 2000; $year <= 2020; $year++) {
        $ids[] = (string) ExpenseModel::query()->create([
            'user_id' => $user->getKey(), 'amount' => 1000, 'category' => 'food', 'occurred_on' => "$year-10-11",
        ])->getKey();
    }

    $first = withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonCount(20, 'data');
    expect(array_column($first->json('data'), 'id'))->toBe(array_reverse(array_slice($ids, 1)));
    parse_str(parse_url($first->json('links.next'), PHP_URL_QUERY), $query);
    expect($query)->not->toHaveKey('filter')->and($query['page']['size'])->toBe('20');
    $last = withToken($token)->getJson($first->json('links.next'))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $ids[0])->assertJsonPath('links.next', null);
    withToken($token)->getJson($last->json('links.prev'))->assertOk()->assertJsonCount(20, 'data');
});

it('refreshes cached old and new periods after the occurrence is edited', function (): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $expense = ExpenseModel::query()->create([
        'user_id' => $user->getKey(), 'amount' => 1000, 'category' => 'food', 'occurred_on' => '2026-10-11',
    ]);
    $oldPeriod = ['filter' => ['year' => 2026, 'month' => 10]];
    $newPeriod = ['filter' => ['year' => 2026, 'month' => 11]];

    withToken($token)->getJson(route('expenses.index', $oldPeriod))->assertOk()->assertJsonCount(1, 'data');
    withToken($token)->getJson(route('expenses.index', $newPeriod))->assertOk()->assertJsonCount(0, 'data');
    withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonPath('data.0.attributes.occurred_on', '2026-10-11');

    withToken($token)->patchJson(route('expenses.update', ['expense' => $expense->getKey()]), [
        'data' => ['type' => 'expenses', 'attributes' => ['occurred_on' => '2026-11-01']],
    ])->assertOk();

    withToken($token)->getJson(route('expenses.index', $oldPeriod))->assertOk()->assertJsonCount(0, 'data');
    withToken($token)->getJson(route('expenses.index', $newPeriod))->assertOk()
        ->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', (string) $expense->getKey());
    withToken($token)->getJson(route('expenses.index'))->assertOk()->assertJsonPath('data.0.attributes.occurred_on', '2026-11-01');
});
