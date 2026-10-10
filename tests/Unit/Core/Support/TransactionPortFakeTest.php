<?php

declare(strict_types=1);

use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Spies\ObservabilityPortSpy;
use Tests\Support\Core\Stubs\UserPortStub;

it('observes the active unit and releases ordered callbacks only after explicit confirmation', function (): void {
    $port = new TransactionPortFake;
    $effects = [];
    $result = $port->commit(function () use ($port, &$effects): int {
        expect($port->isActive)->toBeTrue();

        foreach (['event', 'email'] as $effect) {
            $port->afterCommit(function () use ($port, $effect, &$effects): void {
                expect($port->isActive)->toBeFalse()->and($port->committedResults)->toBe([42]);
                $effects[] = $effect;
            });
        }

        expect($effects)->toBe([]);

        return 42;
    });

    expect($result)->toBe(42)->and($port->isActive)->toBeFalse()
        ->and($port->commitCount)->toBe(1)->and($port->callbackCount)->toBe(2)
        ->and($port->trace)->toBe(['begin', 'register', 'register', 'commit'])
        ->and($effects)->toBe([]);
    $port->releaseAfterCommit();
    $port->releaseAfterCommit();
    expect($effects)->toBe(['event', 'email'])
        ->and($port->trace)->toBe(['begin', 'register', 'register', 'commit', 'callback', 'callback']);
});

it('discards aborted callbacks without pretending to roll back repository state or retry an operation', function (): void {
    $port = new TransactionPortFake;
    $failure = new RuntimeException('sentinel');
    $effects = [];
    $writes = [];

    expect(function () use ($port, $failure, &$effects, &$writes): void {
        $port->commit(function () use ($port, $failure, &$effects, &$writes): void {
            $writes[] = 'simulated repository write';
            $port->afterCommit(function () use (&$effects): void {
                $effects[] = 'aborted effect';
            });

            throw $failure;
        });
    })->toThrow($failure);

    $port->commit(function () use ($port, &$effects): string {
        $port->afterCommit(function () use (&$effects): void {
            $effects[] = 'confirmed effect';
        });

        return 'second attempt';
    });
    $port->releaseAfterCommit();

    expect($writes)->toBe(['simulated repository write'])
        ->and($port->commitCount)->toBe(2)->and($port->discardedCallbackCount)->toBe(1)
        ->and($port->abortedFailures)->toBe([$failure])
        ->and($port->committedResults)->toBe(['second attempt'])
        ->and($effects)->toBe(['confirmed effect']);
});

it('does not classify a callback failure as a rolled back operation or replay it', function (): void {
    $port = new TransactionPortFake;
    $failure = new RuntimeException('external callback failure');
    $executions = 0;
    $port->commit(function () use ($port, $failure, &$executions): string {
        $port->afterCommit(function () use ($failure, &$executions): void {
            $executions++;

            throw $failure;
        });

        return 'confirmed';
    });

    expect(fn () => $port->releaseAfterCommit())->toThrow($failure);
    $port->releaseAfterCommit();
    expect($port->committedResults)->toBe(['confirmed'])->and($port->abortedFailures)->toBe([])
        ->and($port->isActive)->toBeFalse()->and($executions)->toBe(1);
});

it('retains callbacks from a confirmed unit when a later unit aborts', function (): void {
    $port = new TransactionPortFake;
    $spy = new ObservabilityPortSpy;
    $port->commit(function () use ($port, $spy): string {
        $port->afterCommit(fn () => $spy->emit('confirmed', ['user_id' => 10]));

        return 'first unit';
    });

    expect(function () use ($port, $spy): void {
        $port->commit(function () use ($port, $spy): void {
            $port->afterCommit(fn () => $spy->emit('aborted', ['user_id' => 20]));

            throw new RuntimeException('second unit aborted');
        });
    })->toThrow(RuntimeException::class, 'second unit aborted');
    $port->releaseAfterCommit();

    expect($spy->events)->toBe([['event' => 'confirmed', 'attributes' => ['user_id' => 10]]])
        ->and($port->committedResults)->toBe(['first unit'])
        ->and($port->discardedCallbackCount)->toBe(1);
});

it('runs an outside-transaction callback immediately and refuses premature release or nested transactions', function (): void {
    $port = new TransactionPortFake;
    $spy = new ObservabilityPortSpy;
    $port->afterCommit(fn () => $spy->emit('outside', ['user_id' => 42]));
    expect($spy->events)->toBe([['event' => 'outside', 'attributes' => ['user_id' => 42]]]);

    $port->commit(function () use ($port): void {
        expect(fn () => $port->releaseAfterCommit())->toThrow(LogicException::class, 'before the simulated commit')
            ->and(fn () => $port->commit(fn (): int => 1))->toThrow(LogicException::class, 'Nested transactions');
    });
    expect($port->commitCount)->toBe(1)->and($port->abortedFailures)->toBe([]);
});

it('keeps authenticated values and observed event attributes explicit without framework bootstrap', function (): void {
    $userPort = new UserPortStub(identifier: 1500, accountStatus: 'blocked');
    $spy = new ObservabilityPortSpy;
    $spy->emit('first', ['user_id' => $userPort->id(), 'status' => $userPort->status(), 'flag' => true, 'optional' => null]);
    $spy->emit('second', ['value' => 1.5]);

    expect($spy->events)->toBe([
        ['event' => 'first', 'attributes' => ['user_id' => 1500, 'status' => 'blocked', 'flag' => true, 'optional' => null]],
        ['event' => 'second', 'attributes' => ['value' => 1.5]],
    ]);
});
