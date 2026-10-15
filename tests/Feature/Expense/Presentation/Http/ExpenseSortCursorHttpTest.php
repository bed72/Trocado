<?php

declare(strict_types=1);

use App\Expense\Application\Repositories\ExpenseRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Pagination\Cursor;
use Illuminate\Support\Carbon;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Expense\Fixtures\ExpenseCursorFixture;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Carbon::setTestNow('2026-10-11 12:00:00 UTC');
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->withToken(IdentityFixture::token($this->owner, new DateTimeImmutable('2026-11-10')));
});

it('orders and navigates stable pages in both directions without changing nullable descriptions', function (string $sort, array $expected, ?array $descriptions): void {
    $rows = $descriptions === null
        ? [['Água', 2000, '2026-09-15'], ['agua', 1000, '2026-09-15'], ['ÁGUA', 1000, '2026-09-15'], ['Aluguel', 9000, '2026-09-01'], ['Mercado', 5000, '2026-09-30']]
        : array_map(static fn (?string $description): array => [$description, 1000, '2026-09-15'], $descriptions);
    $ids = [];
    foreach (array_reverse(array_keys($rows)) as $index) {
        [$description, $amount, $date] = $rows[$index];
        $ids[$index] = ExpenseQueryHistoryFixture::create($this->owner->id, $date, $amount, 'food', $description, UuidFixture::at($index + 1));
    }
    $parameters = ['sort' => $sort, 'filter' => ['from' => '2026-09-01', 'to' => '2026-09-30', 'category' => 'food', 'amount_min' => 0], 'page' => ['size' => 1]];
    $url = route('expenses.index', $parameters);
    $pages = [];
    $allIds = [];
    $allDescriptions = [];

    do {
        $response = $this->getJson($url)->assertOk()->assertJsonCount(1, 'data');
        $pages[] = array_column($response->json('data'), 'id');
        $allIds[] = $response->json('data.0.id');
        $allDescriptions[] = $response->json('data.0.attributes.description');
        $response->assertJsonMissingPath('data.0.attributes.description_sort');
        $url = $response->json('links.next');
        if ($url !== null) {
            parse_str(parse_url($url, PHP_URL_QUERY), $query);
            expect($query['sort'])->toBe($sort)->and($query['filter'])->toBe(array_map(strval(...), $parameters['filter']))
                ->and($query['page']['size'])->toBe('1')->and(count($pages))->toBeLessThan(count($rows));
        }
    } while ($url !== null);

    expect($allIds)->toBe(array_map(static fn (int $index): string => $ids[$index], $expected))
        ->and($allDescriptions)->toBe(array_map(static fn (int $index): ?string => $rows[$index][0], $expected));
    for ($index = count($pages) - 2; $index >= 0; $index--) {
        $response = $this->getJson($response->json('links.prev'))->assertOk();
        expect(array_column($response->json('data'), 'id'))->toBe($pages[$index]);
    }
    $response->assertJsonPath('links.prev', null);
})->with([
    'date ascending' => ['occurred_on', [3, 2, 1, 0, 4], null],
    'date descending' => ['-occurred_on', [4, 2, 1, 0, 3], null],
    'amount ascending' => ['amount', [2, 1, 0, 4, 3], null],
    'amount descending' => ['-amount', [3, 4, 0, 2, 1], null],
    'description ascending' => ['description', [2, 1, 0, 3, 4], null],
    'description descending' => ['-description', [4, 3, 2, 1, 0], null],
    'date then amount' => ['-occurred_on,amount', [4, 2, 1, 0, 3], null],
    'date then descending amount' => ['-occurred_on,-amount', [4, 0, 2, 1, 3], null],
    'description then amount' => ['description,amount', [2, 1, 0, 3, 4], null],
    'descending description then amount' => ['-description,amount', [4, 3, 2, 1, 0], null],
    'description then descending amount' => ['description,-amount', [0, 2, 1, 3, 4], null],
    'three fields' => ['-amount,description,occurred_on', [3, 4, 0, 2, 1], null],
    'cedilla ascending' => ['description', [2, 1, 0, 3], ['Açaí', 'acai', 'ACAI', 'Banana']],
    'cedilla descending' => ['-description', [3, 2, 1, 0], ['Açaí', 'acai', 'ACAI', 'Banana']],
    'canonical Unicode' => ['description', [1, 0], ['Água', "A\u{0301}gua"]],
    'nullable ascending' => ['description', [1, 0, 2], [null, '', 'Água']],
    'nullable descending' => ['-description', [2, 1, 0], [null, '', 'Água']],
]);

it('rejects a cursor when normalized criteria direction or sort priority change before reading', function (array $original, array $changed): void {
    foreach (['2026-09-01', '2026-09-02', '2026-09-03'] as $date) {
        ExpenseQueryHistoryFixture::create($this->owner->id, $date, 1000, 'food', 'Água');
    }
    $cursor = $this->getJson(route('expenses.index', [...$original, 'page' => ['size' => 1]]))->assertOk()->json('links.next');
    parse_str(parse_url($cursor, PHP_URL_QUERY), $query);
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('getAll');
    $this->app->instance(ExpenseRepository::class, $repository);
    $this->getJson(route('expenses.index', [...$changed, 'page' => ['size' => 1, 'cursor' => $query['page']['cursor']]]))
        ->assertUnprocessable()->assertJsonFragment(['pointer' => '/page/cursor']);
})->with([
    'period' => [['filter' => ['year' => 2026, 'month' => 9]], ['filter' => ['year' => 2026, 'month' => 10]]],
    'direction' => [['sort' => 'amount'], ['sort' => '-amount']],
    'priority' => [['sort' => 'amount,occurred_on'], ['sort' => 'occurred_on,amount']],
    'categories' => [['filter' => ['category' => 'food']], ['filter' => ['category' => 'food,other']]],
    'amount boundary' => [['filter' => ['amount_min' => 0]], ['filter' => ['amount_min' => 1]]],
]);

it('accepts equivalent criteria and size changes with the same new cursor', function (): void {
    $ids = [];
    foreach (range(1, 4) as $day) {
        $ids[] = (string) ExpenseQueryHistoryFixture::create($this->owner->id, "2026-09-0{$day}", 1000, 'food');
    }
    $first = $this->getJson(route('expenses.index', ['filter' => ['year' => 2026, 'month' => 9, 'category' => 'food,transport,food'], 'page' => ['size' => 1]]))->assertOk();
    parse_str(parse_url($first->json('links.next'), PHP_URL_QUERY), $query);
    $this->getJson(route('expenses.index', ['filter' => ['from' => '2026-09-01', 'to' => '2026-09-30', 'category' => 'transport,food'], 'sort' => '-occurred_on', 'page' => ['size' => 2, 'cursor' => $query['page']['cursor']]]))
        ->assertOk()->assertJsonCount(2, 'data')->assertJsonPath('data.0.id', $ids[2])->assertJsonPath('data.1.id', $ids[1]);
});

it('rejects legacy cursors even for the previous unfiltered or civil query contract', function (array $parameters, bool $previouslyAccepted): void {
    $ids = [];
    foreach (range(1, 3) as $day) {
        $ids[] = ExpenseQueryHistoryFixture::create($this->owner->id, "2026-09-0{$day}", 1000, 'food');
    }
    $cursor = (new Cursor(['occurred_on' => '2026-09-03', 'id' => $ids[2]], true))->encode();
    $response = $this->getJson(route('expenses.index', [...$parameters, 'page' => ['size' => 1, 'cursor' => $cursor]]));
    $response->assertUnprocessable()->assertJsonFragment(['pointer' => '/page/cursor']);
})->with([
    'none' => [[], true],
    'year' => [['filter' => ['year' => 2026]], true],
    'month' => [['filter' => ['year' => 2026, 'month' => 9]], true],
    'day' => [['filter' => ['year' => 2026, 'month' => 9, 'day' => 3]], true],
    'explicit sort' => [['sort' => '-occurred_on'], false],
    'range' => [['filter' => ['from' => '2026-09-01']], false],
    'categories' => [['filter' => ['category' => 'food']], false],
    'minimum' => [['filter' => ['amount_min' => 0]], false],
    'maximum' => [['filter' => ['amount_max' => 2000]], false],
]);

it('rejects malformed cursor payloads before the repository or cache read', function (array $mutation): void {
    foreach (range(1, 2) as $day) {
        ExpenseQueryHistoryFixture::create($this->owner->id, "2026-09-0{$day}", 1000, 'food', 'Mercado');
    }
    $first = $this->getJson(route('expenses.index', ['sort' => 'description,amount,occurred_on', 'page' => ['size' => 1]]))->assertOk();
    parse_str(parse_url($first->json('links.next'), PHP_URL_QUERY), $query);
    $payload = ExpenseCursorFixture::payload($query['page']['cursor']);
    foreach ($mutation as $path => $value) {
        if (str_starts_with($path, 'position.')) {
            $payload['position'][substr($path, 9)] = $value;
        } else {
            $payload[$path] = $value;
        }
    }
    $repository = $this->createMock(ExpenseRepository::class);
    $repository->expects($this->never())->method('getAll');
    $this->app->instance(ExpenseRepository::class, $repository);
    $this->getJson(route('expenses.index', ['sort' => 'description,amount,occurred_on', 'page' => ['cursor' => ExpenseCursorFixture::encode($payload)]]))
        ->assertUnprocessable()->assertJsonFragment(['pointer' => '/page/cursor']);
})->with([
    'version' => [['v' => 1]], 'version type' => [['v' => '2']], 'wrong query' => [['query' => str_repeat('0', 64)]],
    'string direction' => [['forward' => 'true']], 'null direction' => [['forward' => null]],
    'zero id' => [['position.id' => 0]], 'string id' => [['position.id' => '1']],
    'null description' => [['position.description' => null]], 'long description' => [['position.description' => str_repeat('é', 65)]],
    'fractional amount' => [['position.amount' => 1.5]], 'negative amount' => [['position.amount' => -1]],
    'invalid date' => [['position.occurred_on' => '2026-02-29']],
    'arbitrary field' => [['position.user_id' => 999]], 'SQL alias' => [['position.description_sort' => 'Mercado']],
    'extra metadata' => [['unknown' => true]], 'non object position' => [['position' => 1]],
]);

it('keeps a compatible foreign cursor restricted to the currently authenticated owner', function (): void {
    ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-03', 1000, 'food');
    ExpenseQueryHistoryFixture::create($this->owner->id, '2026-09-02', 1000, 'food');
    $first = $this->getJson(route('expenses.index', ['page' => ['size' => 1]]))->assertOk();
    parse_str(parse_url($first->json('links.next'), PHP_URL_QUERY), $query);
    $other = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'), email: 'other@example.com');
    $id = ExpenseQueryHistoryFixture::create($other->id, '2026-09-01', 1500, 'transport');
    $this->app['auth']->forgetGuards();
    $this->withToken(IdentityFixture::token($other, new DateTimeImmutable('2026-11-10')));
    $this->getJson(route('expenses.index', ['page' => ['size' => 20, 'cursor' => $query['page']['cursor']]]))
        ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', (string) $id);
});
