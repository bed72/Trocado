<?php

declare(strict_types=1);

namespace App\Authentication\Infrastructure\Adapters;

use App\Authentication\Application\Ports\AuthenticationWritePort;
use Illuminate\Support\Facades\DB;

final class AuthenticationWriteAdapter implements AuthenticationWritePort
{
    public function execute(callable $operation): mixed
    {
        return DB::transaction(callback: $operation, attempts: 3);
    }
}
