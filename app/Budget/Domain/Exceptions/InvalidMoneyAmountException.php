<?php

declare(strict_types=1);

namespace App\Budget\Domain\Exceptions;

use InvalidArgumentException;

final class InvalidMoneyAmountException extends InvalidArgumentException {}
