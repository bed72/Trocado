<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

final readonly class InsightMessageOutput
{
    public function __construct(public string $title, public string $description) {}
}
