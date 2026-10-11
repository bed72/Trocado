<?php

declare(strict_types=1);

namespace App\Expense\Application\Exceptions;

use RuntimeException;

final class InvalidExpenseCursorException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('O cursor da página é inválido ou incompatível com a consulta.');
    }
}
