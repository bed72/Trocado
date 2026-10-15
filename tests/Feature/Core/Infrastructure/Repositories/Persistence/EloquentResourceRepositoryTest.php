<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Infrastructure\Repositories\Persistence\EloquentResourceRepository;
use App\Core\Infrastructure\Repositories\Persistence\Models\ResourceModel;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Database\Events\QueryExecuted;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('binds the repository and autowires the concrete use case with string nonincrementing model metadata', function (): void {
    expect(app(ResourceRepository::class))->toBeInstanceOf(EloquentResourceRepository::class)
        ->and(app(ResourceUseCase::class))->toBeInstanceOf(ResourceUseCase::class)
        ->and((new ResourceModel)->getIncrementing())->toBeFalse()
        ->and((new ResourceModel)->getKeyType())->toBe('string')
        ->and((new ResourceModel)->getUpdatedAtColumn())->toBeNull();
});

it('resolves misses mixed and hit batches with constant statements generating only missing IDs', function (int $size): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $identities = array_map(fn (int $i): ResourceKeyInput => new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['item' => $i]), range(1, $size));
    $input = new ResourceInput($owner->getKey(), $identities);
    $useCase = app(ResourceUseCase::class);
    $generated = 0;
    Str::createUuidsUsing(function () use (&$generated): string {
        return UuidFixture::at(1000 + ++$generated);
    });
    DB::enableQueryLog();
    try {
        DB::flushQueryLog();
        $miss = $useCase->execute($input);
        $missQueries = array_values(array_filter(DB::getQueryLog(), fn (array $query): bool => str_contains($query['query'], 'resource_identities')));
        expect(count($missQueries))->toBe(3)->and($generated)->toBe($size);
        $rows = DB::table('resource_identities')->orderBy('id')->get()->all();
        foreach ($miss->identities as $output) {
            expect(Str::isUuid($output->id, version: 7))->toBeTrue();
        }
        DB::flushQueryLog();
        $hit = $useCase->execute(new ResourceInput(strtoupper($owner->getKey()), array_reverse($identities)));
        $hitQueries = array_values(array_filter(DB::getQueryLog(), fn (array $query): bool => str_contains($query['query'], 'resource_identities')));
        expect(count($hitQueries))->toBe(1)->and(str_starts_with($hitQueries[0]['query'], 'select'))->toBeTrue()
            ->and(array_column($hit->identities, 'id'))->toBe(array_reverse(array_column($miss->identities, 'id')))
            ->and(DB::table('resource_identities')->orderBy('id')->get()->all())->toEqual($rows)
            ->and($generated)->toBe($size);
        $new = new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['item' => 'new']);
        DB::flushQueryLog();
        $mixed = $useCase->execute(new ResourceInput($owner->getKey(), [$identities[0], $new, $identities[0]]));
        $mixedQueries = array_values(array_filter(DB::getQueryLog(), fn (array $query): bool => str_contains($query['query'], 'resource_identities')));
        expect(count($mixedQueries))->toBe(3)->and($generated)->toBe($size + 1)
            ->and(array_column($mixed->identities, 'id'))->toBe([$miss->identities[0]->id, UuidFixture::at(1001 + $size), $miss->identities[0]->id]);
    } finally {
        Str::createUuidsNormally();
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
})->with([1, 5, 6]);

it('does no query and no UUID allocation for empty batches including a direct empty repository call', function (): void {
    Str::createUuidsUsing(fn () => throw new RuntimeException('Must not generate.'));
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        expect(app(ResourceUseCase::class)->execute(new ResourceInput(UuidFixture::at(1), []))->identities)->toBe([])
            ->and(app(ResourceRepository::class)->resolve(UuidFixture::at(1), []))->toBe([])
            ->and(DB::getQueryLog())->toBe([]);
    } finally {
        Str::createUuidsNormally();
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
});

it('persists only minimal associations and distinguishes typed component boundaries owner namespace and version', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    $components = [['a' => null], ['a' => ''], ['a' => false], ['a' => 0], ['a' => '0'], ['a' => 'ab', 'b' => 'c'], ['a' => 'a', 'b' => 'bc'], ['b' => 'bc', 'a' => 'a'], ['b' => '0'], ['a' => "\0\xff"]];
    $identities = array_map(fn (array $values): ResourceKeyInput => new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: $values), $components);
    $identities[] = new ResourceKeyInput(namespace: 'other', identityVersion: 1, components: ['a' => null]);
    $identities[] = new ResourceKeyInput(namespace: 'technical', identityVersion: 2, components: ['a' => null]);
    $useCase = app(ResourceUseCase::class);
    $outputs = $useCase->execute(new ResourceInput($owner->getKey(), $identities));
    $otherOutput = $useCase->execute(new ResourceInput($other->getKey(), [$identities[0]]));
    $ids = [...array_column($outputs->identities, 'id'), $otherOutput->identities[0]->id];
    expect(count(array_unique($ids)))->toBe(13)->and(DB::table('resource_identities')->count())->toBe(13);
    $row = (array) DB::table('resource_identities')->where('id', $ids[0])->first();
    expect(array_keys($row))->toBe(['id', 'user_id', 'namespace', 'identity_version', 'logical_fingerprint', 'created_at'])
        ->and($row['logical_fingerprint'])->toMatch('/\A[0-9a-f]{64}\z/')
        ->and($row['logical_fingerprint'])->not->toBe($row['id']);
    $owner->delete();
    expect(DB::table('resource_identities')->pluck('id')->all())->toBe([$otherOutput->identities[0]->id]);
});

it('retains identities across new instances and token deletion without returning stored resources for an empty selection', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $token = $owner->createToken('explicit-test', ['*'], now()->addDay());
    $input = new ResourceInput($owner->getKey(), [new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['a' => 'logical'])]);
    $first = app(ResourceUseCase::class)->execute($input)->identities[0]->id;
    $token->accessToken->delete();
    $this->travel(2)->days();
    expect(app(ResourceUseCase::class)->execute(new ResourceInput($owner->getKey(), []))->identities)->toBe([]);
    DB::disconnect();
    expect(app(ResourceUseCase::class)->execute($input)->identities[0]->id)->toBe($first)
        ->and(DB::table('resource_identities')->count())->toBe(1);
});

it('rolls back written attempts before retry and bounds real SQL failures without leaking sentinel details', function (string $state, int $failures): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $input = new ResourceInput($owner->getKey(), [new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['a' => 'private-description'])]);
    $written = 0;
    $active = true;
    $connection = DB::connection();
    DB::listen(function (QueryExecuted $event) use (&$written, &$active, $failures, $state): void {
        if (! $active || ! str_contains($event->sql, 'resource_identities')) {
            return;
        }
        if (str_starts_with($event->sql, 'select')) {
            // The initial read of every new attempt must see no row from aborted attempts.
            if ($written <= $failures) {
                $active = false;
                expect(DB::table('resource_identities')->count())->toBe(0);
                $active = true;
            }
        }
        if (str_starts_with($event->sql, 'insert')) {
            $written++;
            $active = false;
            expect(DB::table('resource_identities')->count())->toBe(1);
            $active = true;
            if ($written <= $failures) {
                DB::statement("DO $$ BEGIN RAISE EXCEPTION 'private-description SQL sentinel' USING ERRCODE = '{$state}'; END $$");
            }
        }
    });
    try {
        if ($failures === 2 && $state !== '23514') {
            $output = app(ResourceUseCase::class)->execute($input);
            expect(Str::isUuid($output->identities[0]->id, version: 7))->toBeTrue();
        } else {
            try {
                app(ResourceUseCase::class)->execute($input);
                $this->fail('Expected failure after a confirmed INSERT.');
            } catch (ResourcePersistenceException $exception) {
                expect($exception->getPrevious())->toBeNull()->and($exception->getMessage())->toBe('Resource identities could not be resolved.');
            }
        }
    } finally {
        $active = false;
    }
    expect($written)->toBe($state === '23514' ? 1 : 3)
        ->and($connection->transactionLevel())->toBe(0)
        ->and(DB::table('resource_identities')->count())->toBe($failures === 2 && $state !== '23514' ? 1 : 0);
})->with(['serialization recovered' => ['40001', 2], 'deadlock recovered' => ['40P01', 2], 'serialization exhausted' => ['40001', 3], 'permanent failure' => ['23514', 3]]);

it('sanitizes a missing or deleted owner without recreating it or allocating an orphan', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $owner->delete();
    expect(fn () => app(ResourceUseCase::class)->execute(new ResourceInput($owner->getKey(), [new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: [])])))
        ->toThrow(ResourcePersistenceException::class);
    expect(DB::table('resource_identities')->count())->toBe(0)->and(DB::table('users')->count())->toBe(0);
});

it('rolls back a partially inserted batch on candidate PK collision and retries only absent identities', function (bool $exhausted): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $existing = new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['key' => 'existing']);
    $first = app(ResourceUseCase::class)->execute(new ResourceInput($owner->getKey(), [$existing]))->identities[0]->id;
    $input = new ResourceInput($owner->getKey(), [
        $existing,
        new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['key' => 'new-one']),
        new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['key' => 'new-two']),
    ]);
    $generated = 0;
    Str::createUuidsUsing(function () use (&$generated, $first, $exhausted): string {
        $generated++;
        if ($generated === 1 || ($exhausted && $generated % 2 === 1)) {
            return $first;
        }
        // Previous attempts must have rolled back even the other successfully inserted row.
        if ($generated % 2 === 1) {
            expect(DB::table('resource_identities')->count())->toBe(1);
        }

        return UuidFixture::at(5000 + $generated);
    });
    try {
        if ($exhausted) {
            expect(fn () => app(ResourceUseCase::class)->execute($input))->toThrow(ResourcePersistenceException::class);
        } else {
            $output = app(ResourceUseCase::class)->execute($input);
            expect($output->identities[0]->id)->toBe($first)
                ->and(count(array_unique(array_column($output->identities, 'id'))))->toBe(3);
        }
    } finally {
        Str::createUuidsNormally();
    }
    expect($generated)->toBe($exhausted ? 6 : 4)
        ->and(DB::table('resource_identities')->count())->toBe($exhausted ? 1 : 3)
        ->and(DB::connection()->transactionLevel())->toBe(0);
})->with(['recovered' => false, 'exhausted' => true]);

it('keeps the owner-scoped logical unique index eligible for a six-key batch lookup', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, null);
    $input = new ResourceInput($owner->getKey(), array_map(
        fn (int $i): ResourceKeyInput => new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['item' => $i]), range(1, 6),
    ));
    app(ResourceUseCase::class)->execute($input);
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        app(ResourceUseCase::class)->execute($input);
        $query = array_values(array_filter(DB::getQueryLog(), fn (array $query): bool => str_contains($query['query'], 'resource_identities')))[0];
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
    DB::transaction(function () use ($query): void {
        // This proves index eligibility on the small fixture, not the planner choice at production cardinality.
        DB::statement('SET LOCAL enable_seqscan = off');
        $plan = DB::selectOne('EXPLAIN (FORMAT JSON) '.$query['query'], $query['bindings']);
        $decoded = json_decode($plan->{'QUERY PLAN'}, true, flags: JSON_THROW_ON_ERROR);
        expect(json_encode($decoded, JSON_THROW_ON_ERROR))->toContain('resource_identities_logical_key_unique', 'user_id');
    });
});
