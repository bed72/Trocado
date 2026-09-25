<?php

declare(strict_types=1);

namespace App\Expense\Application\Exceptions;

use RuntimeException;

final class ExpenseNotFoundException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct(message: 'Despesa não encontrada.');
    }
}
