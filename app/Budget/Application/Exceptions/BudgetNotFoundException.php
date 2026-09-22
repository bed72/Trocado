<?php

declare(strict_types=1);

namespace App\Budget\Application\Exceptions;

use RuntimeException;

final class BudgetNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'Budget não encontrado.');
    }
}
