<?php

declare(strict_types=1);

namespace App\Identity\Application\Exceptions;

use App\Identity\Domain\Enums\UserStatusEnum;
use RuntimeException;

final class InactiveUserException extends RuntimeException
{
    public function __construct(public readonly UserStatusEnum $status)
    {
        parent::__construct(message: 'A conta não está ativa.');
    }
}
