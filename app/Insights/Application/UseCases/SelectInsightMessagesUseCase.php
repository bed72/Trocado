<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageOutput;
use App\Insights\Domain\ValueObjects\InsightMessageValueObject;

final readonly class SelectInsightMessagesUseCase
{
    /**
     * Input order is the already selected deterministic priority order.
     *
     * @param  list<InsightMessageOutput>  $messages
     * @return list<int>
     */
    public function execute(array $messages): array
    {
        $seen = [];
        $selected = [];

        foreach ($messages as $index => $message) {
            $key = (new InsightMessageValueObject($message->title, $message->description))->comparisonKey();

            if (! isset($seen[$key])) {
                $seen[$key] = true;
                $selected[] = $index;
            }
        }

        return $selected;
    }
}
