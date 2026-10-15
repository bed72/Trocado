<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Repositories\Persistence;

use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Exceptions\ResourcePersistenceException;
use App\Core\Application\Exceptions\ResourceRaceException;
use App\Core\Application\Repositories\ResourceRepository;
use App\Core\Infrastructure\Repositories\Persistence\Models\ResourceModel;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\QueryException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use SensitiveParameter;

final readonly class EloquentResourceRepository implements ResourceRepository
{
    public function resolve(string $userId, #[SensitiveParameter] array $identities): array
    {
        if ($identities === []) {
            return [];
        }

        try {
            $keys = [];
            foreach ($identities as $identity) {
                $keys[] = [$identity->namespace, $identity->identityVersion, hash('sha256', serialize($identity->components))];
            }
            $query = ResourceModel::query()->useWritePdo()->where('user_id', $userId)
                ->where(function (Builder $query) use ($keys): void {
                    foreach ($keys as [$namespace, $version, $fingerprint]) {
                        $query->orWhere(fn (Builder $query): Builder => $query->where('namespace', $namespace)
                            ->where('identity_version', $version)->where('logical_fingerprint', $fingerprint));
                    }
                });
            $existing = $this->read($query);
            $missing = array_values(array_filter($keys, fn (array $key): bool => ! isset($existing[serialize($key)])));
            if ($missing !== []) {
                sort($missing);
                $createdAt = Carbon::now();
                $rows = [];
                foreach ($missing as [$namespace, $version, $fingerprint]) {
                    $rows[] = [
                        'id' => (string) Str::uuid7(),
                        'user_id' => $userId,
                        'namespace' => $namespace,
                        'identity_version' => $version,
                        'logical_fingerprint' => $fingerprint,
                        'created_at' => $createdAt,
                    ];
                }
                ResourceModel::query()->insertOrIgnore($rows);
                // A separate statement sees the committed winner at READ COMMITTED, unlike a single CTE snapshot.
                $existing = $this->read($query);
            }

            $outputs = [];
            foreach ($keys as $index => $key) {
                $id = $existing[serialize($key)] ?? throw new ResourceRaceException;
                $outputs[] = new ResourceKeyOutput($identities[$index], $id);
            }

            return $outputs;
        } catch (QueryException $exception) {
            if (in_array($exception->errorInfo[0] ?? null, ['23505', '40001', '40P01'], true)) {
                throw new ResourceRaceException;
            }

            throw new ResourcePersistenceException;
        }
    }

    /** @return array<string, string> */
    private function read(Builder $query): array
    {
        $existing = [];
        foreach ((clone $query)->get(['id', 'namespace', 'identity_version', 'logical_fingerprint']) as $model) {
            $key = [$model->namespace, $model->identity_version, $model->logical_fingerprint];
            $existing[serialize($key)] = (string) $model->getKey();
        }

        return $existing;
    }
}
