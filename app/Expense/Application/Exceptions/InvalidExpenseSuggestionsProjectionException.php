<?php

declare(strict_types=1);

namespace App\Expense\Application\Exceptions;

use RuntimeException;

final class InvalidExpenseSuggestionsProjectionException extends RuntimeException
{
    public function __construct()
    {
        parent::__construct('The expense suggestions projection is invalid.');
    }
}
