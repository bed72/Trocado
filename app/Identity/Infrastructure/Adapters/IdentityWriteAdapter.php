<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\IdentityWritePort;
use Illuminate\Support\Facades\DB;

final class IdentityWriteAdapter implements IdentityWritePort
{
    public function execute(callable $operation): mixed
    {
        return DB::transaction(callback: $operation, attempts: 3);
    }
}
