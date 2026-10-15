<?php

declare(strict_types=1);

namespace Tests\Support\Expense\Fakes;

use App\Core\Application\Data\ResourceKeyOutput;
use App\Core\Application\Repositories\ResourceRepository;
use Tests\Support\Core\Fixtures\UuidFixture;

final class SuggestionResourceRepositoryFake implements ResourceRepository
{
    /** @var array<string, string> */
    private array $ids = [];

    public function resolve(string $userId, array $identities): array
    {
        $outputs = [];
        foreach ($identities as $identity) {
            $index = serialize([$userId, $identity]);
            $this->ids[$index] ??= UuidFixture::at(count($this->ids) + 100);
            $outputs[] = new ResourceKeyOutput($identity, $this->ids[$index]);
        }

        return $outputs;
    }
}
