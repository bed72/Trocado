<?php

declare(strict_types=1);

namespace App\Identity\Application\Repositories;

use App\Identity\Application\Data\Output\PasswordRecoveryEmissionOutput;
use App\Identity\Domain\ValueObjects\EmailValueObject;

interface PasswordRecoveryRepository
{
    /** An ineligible account returns null; a suppressed emission returns an output without a token. */
    public function issue(EmailValueObject $email): ?PasswordRecoveryEmissionOutput;
}
