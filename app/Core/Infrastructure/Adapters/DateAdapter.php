<?php

declare(strict_types=1);

namespace App\Core\Infrastructure\Adapters;

use App\Core\Application\Ports\DatePort;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Date;

final class DateAdapter implements DatePort
{
    public function today(): string
    {
        return Date::now(Config::string('app.timezone'))->toDateString();
    }
}
