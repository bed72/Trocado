<?php

declare(strict_types=1);

use App\Expense\Application\Repositories\ExpenseRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Carbon;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Carbon::setTestNow('2026-10-11 12:00:00 UTC');
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->withToken(IdentityFixture::token($this->owner, new DateTimeImmutable('2026-11-10')));
});

it('composes inclusive independent filters before pagination and isolates the owner', function (array $filter, array $expected): void {
    $rows = [
        'previous' => ['2026-08-31', 1000, 'food'],
        'minimum' => ['2026-09-01', 1000, 'food'],
        'maximum' => ['2026-09-30', 30000, 'transport'],
        'low' => ['2026-09-15', 999, 'food'],
        'high' => ['2026-09-15', 30001, 'food'],
        'category' => ['2026-09-15', 1500, 'health'],
        'next' => ['2026-10-01', 1500, 'transport'],
        'tiny' => ['2026-09-10', 1, 'other'],
    ];
    $ids = [];
    foreach ($rows as $key => [$date, $amount, $category]) {
        $ids[$key] = (string) ExpenseQueryHistoryFixture::create($this->owner->id, $date, $amount, $category);
    }
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    ExpenseQueryHistoryFixture::create($other->id, '2026-09-30', 30000, 'transport');

    $response = $this->getJson(route('expenses.index', $filter === [] ? [] : ['filter' => $filter]))->assertOk();
    expect(array_column($response->json('data'), 'id'))->toBe(array_map(static fn (string $key): string => $ids[$key], $expected));
})->with([
    'none' => [[], ['next', 'maximum', 'category', 'high', 'low', 'tiny', 'minimum', 'previous']],
    'independent start' => [['from' => '2026-09-01'], ['next', 'maximum', 'category', 'high', 'low', 'tiny', 'minimum']],
    'independent end' => [['to' => '2026-09-30'], ['maximum', 'category', 'high', 'low', 'tiny', 'minimum', 'previous']],
    'closed range' => [['from' => '2026-09-01', 'to' => '2026-09-30'], ['maximum', 'category', 'high', 'low', 'tiny', 'minimum']],
    'same date inclusive' => [['from' => '2026-09-15', 'to' => '2026-09-15'], ['category', 'high', 'low']],
    'category set' => [['category' => 'food,transport,food'], ['next', 'maximum', 'high', 'low', 'minimum', 'previous']],
    'single category' => [['category' => 'other'], ['tiny']],
    'minimum alone' => [['amount_min' => 30000], ['maximum', 'high']],
    'maximum alone' => [['amount_max' => 1000], ['low', 'tiny', 'minimum', 'previous']],
    'zero minimum' => [['amount_min' => 0], ['next', 'maximum', 'category', 'high', 'low', 'tiny', 'minimum', 'previous']],
    'zero maximum' => [['amount_max' => 0], []],
    'largest integer' => [['amount_max' => '9223372036854775807'], ['next', 'maximum', 'category', 'high', 'low', 'tiny', 'minimum', 'previous']],
    'all criteria' => [['from' => '2026-09-01', 'to' => '2026-09-30', 'category' => 'food,transport', 'amount_min' => 1000, 'amount_max' => 30000], ['maximum', 'minimum']],
    'civil and category/value' => [['year' => 2026, 'month' => 9, 'category' => 'food', 'amount_max' => 1000], ['low', 'minimum']],
    'no match' => [['from' => '9999-01-01'], []],
    'first civil year' => [['to' => '0001-12-31'], []],
]);

it('rejects invalid criteria before repository access with a JSON API field pointer', function (array $parameters, string $field): void {
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('getAll');
    $this->app->instance(ExpenseRepository::class, $repository);
    $this->getJson(route('expenses.index', $parameters))->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertJsonFragment(['pointer' => '/'.str_replace('.', '/', $field)]);
})->with([
    'start array' => [['filter' => ['from' => ['2026-09-01']]], 'filter.from'],
    'empty start' => [['filter' => ['from' => '']], 'filter.from'],
    'empty end' => [['filter' => ['to' => '']], 'filter.to'],
    'invalid leap day' => [['filter' => ['from' => '2026-02-29']], 'filter.from'],
    'timestamp' => [['filter' => ['to' => '2026-09-30T00:00:00']], 'filter.to'],
    'non canonical date' => [['filter' => ['from' => '2026-9-1']], 'filter.from'],
    'year zero' => [['filter' => ['from' => '0000-01-01']], 'filter.from'],
    'year overflow' => [['filter' => ['to' => '10000-01-01']], 'filter.to'],
    'inverted dates' => [['filter' => ['from' => '2026-10-01', 'to' => '2026-09-30']], 'filter.to'],
    'start and year' => [['filter' => ['from' => '2026-09-01', 'year' => 2026]], 'filter.from'],
    'end and civil day' => [['filter' => ['to' => '2026-09-30', 'year' => 2026, 'month' => 9, 'day' => 1]], 'filter.to'],
    'empty category' => [['filter' => ['category' => '']], 'filter.category'],
    'empty category token' => [['filter' => ['category' => 'food,,transport']], 'filter.category'],
    'trailing category comma' => [['filter' => ['category' => 'food,']], 'filter.category'],
    'unknown category' => [['filter' => ['category' => 'food,unknown']], 'filter.category'],
    'category array' => [['filter' => ['category' => ['food']]], 'filter.category'],
    'negative minimum' => [['filter' => ['amount_min' => -1]], 'filter.amount_min'],
    'fractional maximum' => [['filter' => ['amount_max' => '1.5']], 'filter.amount_max'],
    'integer overflow' => [['filter' => ['amount_max' => '9223372036854775808']], 'filter.amount_max'],
    'minimum array' => [['filter' => ['amount_min' => [0]]], 'filter.amount_min'],
    'empty minimum' => [['filter' => ['amount_min' => '']], 'filter.amount_min'],
    'inverted amounts' => [['filter' => ['amount_min' => 2, 'amount_max' => 1]], 'filter.amount_max'],
    'duplicate sort' => [['sort' => 'amount,-amount'], 'sort'],
    'sort array' => [['sort' => ['amount']], 'sort'],
    'unknown sort' => [['sort' => 'user_id'], 'sort'],
    'id sort' => [['sort' => '-id'], 'sort'],
    'empty sort' => [['sort' => ''], 'sort'],
    'sort trailing comma' => [['sort' => 'amount,'], 'sort'],
    'sort double prefix' => [['sort' => '--amount'], 'sort'],
    'four sorts' => [['sort' => 'amount,occurred_on,description,id'], 'sort'],
    'sort injection' => [['sort' => 'amount desc; drop table expenses'], 'sort'],
    'unknown filter' => [['filter' => ['user_id' => 1]], 'filter'],
    'malformed cursor' => [['page' => ['cursor' => 'abc']], 'page.cursor'],
    'cursor array' => [['page' => ['cursor' => [1]]], 'page.cursor'],
    'empty cursor' => [['page' => ['cursor' => '']], 'page.cursor'],
    'zero size' => [['page' => ['size' => 0]], 'page.size'],
    'oversized page' => [['page' => ['size' => 101]], 'page.size'],
]);
