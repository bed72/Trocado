<?php

declare(strict_types=1);

namespace App\Notifications\Application\Exceptions;

use RuntimeException;

final class NotificationRegistrationRaceException extends RuntimeException {}
