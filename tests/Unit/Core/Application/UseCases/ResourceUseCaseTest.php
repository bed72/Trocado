<?php

declare(strict_types=1);

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Exceptions\InvalidResourceException;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Exceptions\ResourceRaceException;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Core\Domain\Exceptions\InvalidUuidException;
use Tests\Support\Core\Fakes\TransactionPortFake;
use Tests\Support\Core\Fixtures\UuidFixture;

it('validates the owner even for an empty batch before opening a transaction', function (string $owner): void {
    $port = new TransactionPortFake;
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->never())->method('resolve');
    expect(fn () => (new ResourceUseCase($port, $repository))->execute(new ResourceInput($owner, [])))
        ->toThrow(InvalidUuidException::class);
    expect($port->commitCount)->toBe(0);
})->with(['', '1', '00000000-0000-4000-8000-000000000001', ' 00000000-0000-7000-8000-000000000001']);

it('returns an empty batch without persistence or transaction', function (): void {
    $port = new TransactionPortFake;
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->never())->method('resolve');
    $output = (new ResourceUseCase($port, $repository))->execute(new ResourceInput(UuidFixture::at(1), []));
    expect($output->identities)->toBe([])->and($port->commitCount)->toBe(0);
});

it('rejects an entire invalid batch before persistence including a later invalid item', function (array $identities): void {
    $port = new TransactionPortFake;
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->never())->method('resolve');
    expect(fn () => (new ResourceUseCase($port, $repository))->execute(new ResourceInput(UuidFixture::at(1), $identities)))
        ->toThrow(InvalidResourceException::class, 'Invalid resource identity batch.');
    expect($port->commitCount)->toBe(0);
})->with([
    'non list' => [[1 => new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: [])]],
    'wrong type' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: []), null]],
    'uppercase namespace' => [[new ResourceKeyInput(namespace: 'Invalid', identityVersion: 1, components: [])]],
    'empty namespace' => [[new ResourceKeyInput(namespace: '', identityVersion: 1, components: [])]],
    'numeric namespace' => [[new ResourceKeyInput(namespace: '1abc', identityVersion: 1, components: [])]],
    'trailing hyphen' => [[new ResourceKeyInput(namespace: 'abc-', identityVersion: 1, components: [])]],
    'repeated hyphen' => [[new ResourceKeyInput(namespace: 'a--b', identityVersion: 1, components: [])]],
    'namespace newline' => [[new ResourceKeyInput(namespace: "a\n", identityVersion: 1, components: [])]],
    'namespace overflow' => [[new ResourceKeyInput(namespace: str_repeat('a', 65), identityVersion: 1, components: [])]],
    'zero version' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 0, components: [])]],
    'negative version' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: -1, components: [])]],
    'smallint overflow' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 32768, components: [])]],
    'integer name' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: ['value'])]],
    'empty name' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: ['' => null])]],
    'float' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: ['key' => 1.0])]],
    'nested array' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: ['key' => []])]],
    'object' => [[new ResourceKeyInput(namespace: 'valid', identityVersion: 1, components: ['key' => new stdClass])]],
]);

it('canonicalizes owner deduplicates exact typed keys and restores original order without assuming SQL order', function (): void {
    $port = new TransactionPortFake;
    $first = new ResourceKeyInput(namespace: 'expense-metrics', identityVersion: 1, components: ['period' => '2026-10', 'mode' => null]);
    $same = new ResourceKeyInput(namespace: 'expense-metrics', identityVersion: 1, components: ['period' => '2026-10', 'mode' => null]);
    $second = new ResourceKeyInput(namespace: 'expense-metrics', identityVersion: 1, components: ['period' => '2026-10', 'mode' => '']);
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->once())->method('resolve')->with(UuidFixture::at(10), [$first, $second])
        ->willReturnCallback(function () use ($port, $first, $second): array {
            expect($port->isActive)->toBeTrue();

            return [new ResourceKeyOutput($second, UuidFixture::at(12)), new ResourceKeyOutput($first, strtoupper(UuidFixture::at(11)))];
        });
    $output = (new ResourceUseCase($port, $repository))->execute(new ResourceInput(strtoupper(UuidFixture::at(10)), [$first, $second, $same]));
    expect(array_column($output->identities, 'id'))->toBe([UuidFixture::at(11), UuidFixture::at(12), UuidFixture::at(11)])
        ->and($output->identities[2]->identity)->toBe($same)
        ->and($port->trace)->toBe(['begin', 'commit']);
});

it('keeps types names byte boundaries ordering namespaces and versions distinct', function (): void {
    $components = [['a' => null], ['a' => ''], ['a' => false], ['a' => 0], ['a' => '0'], ['a' => true], ['a' => 1], ['a' => '1'],
        ['a' => 'ab', 'b' => 'c'], ['a' => 'a', 'b' => 'bc'], ['a' => 'x', 'b' => 'y'], ['b' => 'y', 'a' => 'x'], ['b' => '1'], ['a' => "\0\xff"], []];
    $identities = array_map(fn (array $values): ResourceKeyInput => new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: $values), $components);
    $identities[] = new ResourceKeyInput(namespace: 'technical-other', identityVersion: 1, components: ['a' => '1']);
    $identities[] = new ResourceKeyInput(namespace: 'technical', identityVersion: 32767, components: ['a' => '1']);
    $identities[] = new ResourceKeyInput(namespace: str_repeat('a', 64), identityVersion: 1, components: ['a' => '1']);
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->once())->method('resolve')->with(UuidFixture::at(1), $identities)
        ->willReturn(array_map(fn (ResourceKeyInput $identity, int $index): ResourceKeyOutput => new ResourceKeyOutput($identity, UuidFixture::at(100 + $index)), $identities, array_keys($identities)));
    $output = (new ResourceUseCase(new TransactionPortFake, $repository))->execute(new ResourceInput(UuidFixture::at(1), $identities));
    expect(count($output->identities))->toBe(count($identities));
});

it('aborts before retry and caps race retries at three without returning a partial batch', function (int $failures): void {
    $port = new TransactionPortFake;
    $identity = new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['a' => 'private']);
    $repository = $this->createMock(ResourceRepository::class);
    $calls = 0;
    $repository->expects($this->exactly(min($failures + 1, 3)))->method('resolve')
        ->willReturnCallback(function () use (&$calls, $failures, $identity): array {
            if (++$calls <= $failures) {
                throw new ResourceRaceException;
            }

            return [new ResourceKeyOutput($identity, UuidFixture::at(2))];
        });
    $operation = fn () => (new ResourceUseCase($port, $repository))->execute(new ResourceInput(UuidFixture::at(1), [$identity]));
    if ($failures >= 3) {
        expect($operation)->toThrow(ResourcePersistenceException::class);
    } else {
        expect($operation()->identities[0]->id)->toBe(UuidFixture::at(2));
    }
    expect($port->commitCount)->toBe(min($failures + 1, 3))
        ->and($port->trace)->toBe($failures >= 3 ? ['begin', 'abort', 'begin', 'abort', 'begin', 'abort'] : ['begin', 'abort', 'begin', 'abort', 'begin', 'commit']);
})->with(['eventual success' => 2, 'exhausted' => 3]);

it('sanitizes repository and commit failures without retrying permanent errors or chaining sensitive exceptions', function (bool $commitFailure): void {
    $repository = $this->createMock(ResourceRepository::class);
    $identity = new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['a' => 'private']);
    $sentinel = new RuntimeException('SQL bindings private fingerprint secret');
    $port = $this->createMock(TransactionPort::class);
    $port->expects($this->once())->method('commit')->willReturnCallback(function (callable $operation) use ($commitFailure, $sentinel): mixed {
        if (! $commitFailure) {
            return $operation();
        }
        throw $sentinel;
    });
    $repository->expects($commitFailure ? $this->never() : $this->once())->method('resolve')->willThrowException($sentinel);
    try {
        (new ResourceUseCase($port, $repository))->execute(new ResourceInput(UuidFixture::at(1), [$identity]));
        $this->fail('Expected sanitized failure.');
    } catch (ResourcePersistenceException $exception) {
        expect($exception->getMessage())->toBe('Resource identities could not be resolved.')->and($exception->getPrevious())->toBeNull();
    }
})->with([false, true]);

it('rejects incomplete duplicate foreign or invalid repository outputs inside the transaction', function (string $failure): void {
    $port = new TransactionPortFake;
    $identity = new ResourceKeyInput(namespace: 'technical', identityVersion: 1, components: ['a' => 1]);
    $valid = new ResourceKeyOutput($identity, UuidFixture::at(2));
    $outputs = match ($failure) {
        'missing' => [],
        'duplicate' => [$valid, $valid],
        'foreign' => [new ResourceKeyOutput(new ResourceKeyInput(namespace: 'other', identityVersion: 1, components: []), UuidFixture::at(3))],
        'invalid UUID' => [new ResourceKeyOutput($identity, 'private-invalid')],
        'wrong type' => [null],
    };
    $repository = $this->createMock(ResourceRepository::class);
    $repository->expects($this->once())->method('resolve')->willReturn($outputs);
    expect(fn () => (new ResourceUseCase($port, $repository))->execute(new ResourceInput(UuidFixture::at(1), [$identity])))
        ->toThrow(ResourcePersistenceException::class);
    expect($port->trace)->toBe(['begin', 'abort']);
})->with(['missing', 'duplicate', 'foreign', 'invalid UUID', 'wrong type']);
