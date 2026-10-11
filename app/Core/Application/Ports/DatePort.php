<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface DatePort
{
    /** Returns the current civil date in Y-m-d in the application timezone. */
    public function today(): string;
}
