<?php

declare(strict_types=1);

namespace App\User\Application\Exceptions;

use App\User\Domain\ValueObjects\EmailValueObject;
use RuntimeException;

final class EmailAlreadyUsedException extends RuntimeException
{
    public function __construct(EmailValueObject $email)
    {
        parent::__construct(message: "O e-mail {$email->value()} já está em uso.");
    }
}
