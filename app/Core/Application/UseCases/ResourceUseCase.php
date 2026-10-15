<?php

declare(strict_types=1);

namespace App\Core\Application\UseCases;

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Data\ResourceOutput;
use App\Core\Application\Exceptions\InvalidResourceException;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Exceptions\ResourceRaceException;
use App\Core\Application\Ports\TransactionPort;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Domain\ValueObjects\UuidValueObject;
use SensitiveParameter;
use Throwable;

use function count;
use function is_string;
use function strlen;

final readonly class ResourceUseCase
{
    public function __construct(private TransactionPort $port, private ResourceRepository $repository) {}

    public function execute(#[SensitiveParameter] ResourceInput $input): ResourceOutput
    {
        $userId = UuidValueObject::fromString($input->userId)->value();
        if (! array_is_list($input->identities)) {
            throw new InvalidResourceException;
        }

        $keys = [];
        $unique = [];
        foreach ($input->identities as $identity) {
            if (! $identity instanceof ResourceKeyInput) {
                throw new InvalidResourceException;
            }
            $this->validate($identity);
            $key = $this->key($identity);
            $keys[] = $key;
            $unique[$key] ??= $identity;
        }

        if ($unique === []) {
            return new ResourceOutput([]);
        }

        for ($attempt = 1; $attempt <= 3; $attempt++) {
            try {
                return $this->port->commit(function () use ($userId, $unique, $keys, $input): ResourceOutput {
                    $ids = [];
                    $byKey = [];
                    $resolved = $this->repository->resolve($userId, array_values($unique));
                    foreach ($resolved as $output) {
                        if (! $output instanceof ResourceKeyOutput) {
                            throw new ResourcePersistenceException;
                        }
                        $key = $this->key($output->identity);
                        $id = UuidValueObject::fromString($output->id)->value();
                        if (! isset($unique[$key]) || isset($byKey[$key]) || isset($ids[$id])) {
                            throw new ResourcePersistenceException;
                        }
                        $byKey[$key] = $id;
                        $ids[$id] = true;
                    }
                    if (count($byKey) !== count($unique)) {
                        throw new ResourcePersistenceException;
                    }

                    $outputs = [];
                    foreach ($keys as $index => $key) {
                        $outputs[] = new ResourceKeyOutput($input->identities[$index], $byKey[$key]);
                    }

                    return new ResourceOutput($outputs);
                });
            } catch (ResourceRaceException) {
                // The Port has rolled back this complete attempt before a new one begins.
                continue;
            } catch (Throwable) {
                throw new ResourcePersistenceException;
            }
        }

        throw new ResourcePersistenceException;
    }

    private function validate(#[SensitiveParameter] ResourceKeyInput $identity): void
    {
        if (strlen($identity->namespace) > 64
            || preg_match('/\A[a-z][a-z0-9]*(-[a-z0-9]+)*\z/', $identity->namespace) !== 1
            || $identity->identityVersion < 1 || $identity->identityVersion > 32767) {
            throw new InvalidResourceException;
        }
        foreach ($identity->components as $name => $value) {
            if (! is_string($name) || $name === ''
                || (! is_string($value) && ! is_int($value) && ! is_bool($value) && $value !== null)) {
                throw new InvalidResourceException;
            }
        }
    }

    private function key(#[SensitiveParameter] ResourceKeyInput $identity): string
    {
        return serialize([$identity->namespace, $identity->identityVersion, $identity->components]);
    }
}
