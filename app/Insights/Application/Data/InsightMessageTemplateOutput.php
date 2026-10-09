<?php

declare(strict_types=1);

namespace App\Insights\Application\Data;

final readonly class InsightMessageTemplateOutput
{
    public function __construct(
        public string $title,
        public string $description,
        public string $shortDescription,
    ) {}
}
