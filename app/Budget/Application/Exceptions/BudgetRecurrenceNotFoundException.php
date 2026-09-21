<?php

declare(strict_types=1);

namespace App\Budget\Application\Exceptions;

use RuntimeException;

final class BudgetRecurrenceNotFoundException extends RuntimeException
{
    public function __construct(int $id)
    {
        parent::__construct(message: "Recorrência de Budget {$id} não encontrada.");
    }
}
