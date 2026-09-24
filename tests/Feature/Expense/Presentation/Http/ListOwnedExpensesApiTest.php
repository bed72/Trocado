<?php

declare(strict_types=1);

use App\Core\Application\Ports\ScopePort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\UseCases\CreateExpenseUseCase;
use Illuminate\Pagination\Cursor;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

it('lists only active expenses of the authenticated owner in date and id order across both directions', function (): void {
    $owner = signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $other = signUpIdentityByApi($this, 'Pedro', 'Correct1', 'pedro@example.com');
    $otherToken = signInIdentityByApi($this, 'pedro@example.com');
    $create = app(CreateExpenseUseCase::class);

    $old = $create->execute(new CreateExpenseInput(userId: $owner, amount: 100, occurredOn: '2026-09-20'));
    $middle = $create->execute(new CreateExpenseInput(userId: $owner, amount: 200, occurredOn: '2026-09-21'));
    $new = $create->execute(new CreateExpenseInput(userId: $owner, amount: 300, occurredOn: '2026-09-21'));
    $deleted = $create->execute(new CreateExpenseInput(userId: $owner, amount: 400, occurredOn: '2026-09-22'));
    $create->execute(new CreateExpenseInput(userId: $other, amount: 500, occurredOn: '2026-09-23'));
    app(ScopePort::class)->execute($owner, fn () => DB::table('expenses')->where('id', $deleted->id)->update(['deleted_at' => now()]));

    $first = $this->withToken($token)->getJson('/api/expenses?page[size]=2')
        ->assertOk()->assertHeader('Content-Type', 'application/vnd.api+json');
    expect(array_column($first->json('data'), 'id'))->toBe([(string) $new->id, (string) $middle->id])
        ->and($first->json('links.prev'))->toBeNull()
        ->and($first->json('links.next'))->toContain('size%5D=2')
        ->and($first->json('meta.total'))->toBeNull();

    $last = $this->getJson($first->json('links.next'))->assertOk();
    expect(array_column($last->json('data'), 'id'))->toBe([(string) $old->id])
        ->and($last->json('links.next'))->toBeNull();

    $back = $this->getJson($last->json('links.prev'))->assertOk();
    expect(array_column($back->json('data'), 'id'))->toBe([(string) $new->id, (string) $middle->id]);

    $single = $this->getJson('/api/expenses?page[size]=1')->assertOk();
    expect(array_column($single->json('data'), 'id'))->toBe([(string) $new->id]);
    $second = $this->getJson($single->json('links.next'))->assertOk();
    expect(array_column($second->json('data'), 'id'))->toBe([(string) $middle->id]);
    $third = $this->getJson($second->json('links.next'))->assertOk();
    expect(array_column($third->json('data'), 'id'))->toBe([(string) $old->id])
        ->and($third->json('links.next'))->toBeNull();

    Auth::forgetGuards();
    $this->withToken($otherToken)->getJson('/api/expenses')->assertOk()->assertJsonPath('data.0.attributes.amount', 500);
    $otherPage = $this->getJson($first->json('links.next'))->assertOk();
    expect($otherPage->json('data'))->toBe([]);
});

it('returns an empty JSON API collection and rejects unauthenticated access', function (): void {
    $this->getJson('/api/expenses')->assertUnauthorized()->assertHeader('Content-Type', 'application/vnd.api+json');

    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);
    $response = $this->withToken($token)->getJson('/api/expenses')->assertOk();

    expect($response->json('data'))->toBe([])
        ->and($response->json('links.next'))->toBeNull()
        ->and($response->json('links.prev'))->toBeNull();
});

it('rejects invalid pagination and client supplied ownership', function (string $query, string $pointer): void {
    signUpIdentityByApi($this);
    $token = signInIdentityByApi($this);

    $this->withToken($token)->getJson('/api/expenses?'.$query)
        ->assertUnprocessable()->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonPath('errors.0.source.pointer', $pointer);
})->with([
    'owner' => ['user_id=123', '/user_id'],
    'zero size' => ['page[size]=0', '/page/size'],
    'large size' => ['page[size]=101', '/page/size'],
    'fraction size' => ['page[size]=1.5', '/page/size'],
    'invalid cursor' => ['page[cursor]=bad', '/page/cursor'],
    'missing cursor keys' => ['page[cursor]='.rawurlencode((new Cursor(['id' => 1]))->encode()), '/page/cursor'],
    'invalid cursor id' => ['page[cursor]='.rawurlencode((new Cursor(['occurred_on' => '2026-09-20', 'id' => 'not-an-id']))->encode()), '/page/cursor'],
    'invalid cursor date' => ['page[cursor]='.rawurlencode((new Cursor(['occurred_on' => '2026-02-30', 'id' => 1]))->encode()), '/page/cursor'],
]);
