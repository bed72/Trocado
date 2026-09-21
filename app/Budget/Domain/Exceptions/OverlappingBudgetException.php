<?php

declare(strict_types=1);

namespace App\Budget\Domain\Exceptions;

use DomainException;

final class OverlappingBudgetException extends DomainException
{
    public function __construct()
    {
        parent::__construct(message: 'O intervalo informado se sobrepõe a outro Budget.');
    }
}
