<?php

declare(strict_types=1);

use Tests\Support\Core\Database\TestDatabaseRun;

it('authorizes only registered native tokens and distinguishes simultaneous invocations', function (): void {
    $first = TestDatabaseRun::create(2);
    $second = TestDatabaseRun::create(2);
    expect($first->forToken('1')->database)->toBe($first->database.'_test_1')
        ->and($first->forToken('2')->database)->not->toBe($first->forToken('1')->database)
        ->and($second->forToken('1')->database)->not->toBe($first->forToken('1')->database);
    expect(fn () => $first->forToken('3'))->toThrow(RuntimeException::class, 'Unregistered');
    expect(fn () => $first->forToken('1_test_2'))->toThrow(RuntimeException::class, 'Unregistered');
    expect(fn () => new TestDatabaseRun($first->id, $first->owner, ['0']))->toThrow(RuntimeException::class, 'Invalid parallel');
});
