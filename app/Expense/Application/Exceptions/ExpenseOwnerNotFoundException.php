<?php

declare(strict_types=1);

namespace App\Expense\Application\Exceptions;

use RuntimeException;
use Throwable;

final class ExpenseOwnerNotFoundException extends RuntimeException
{
    public function __construct(?Throwable $previous = null)
    {
        parent::__construct(message: 'A identidade proprietária da despesa não existe.', previous: $previous);
    }
}
