<?php

declare(strict_types=1);

namespace App\Budget\Domain\Exceptions;

use DomainException;

final class InvalidRecurrenceTransitionException extends DomainException {}
