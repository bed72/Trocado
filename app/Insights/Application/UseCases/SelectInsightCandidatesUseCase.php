<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

use function count;

final readonly class SelectInsightCandidatesUseCase
{
    private const int MaximumCandidates = 6;

    /**
     * @param  list<InsightCandidateValueObject>  $candidates
     * @return list<InsightCandidateValueObject>
     */
    public function execute(array $candidates): array
    {
        usort($candidates, $this->compareCandidates(...));
        $selected = [];

        foreach ($candidates as $candidate) {
            if ($this->isRedundant(candidate: $candidate, selected: $selected)) {
                continue;
            }

            $selected[] = $candidate;

            if (count($selected) === self::MaximumCandidates) {
                break;
            }
        }

        return $selected;
    }

    private function compareCandidates(InsightCandidateValueObject $left, InsightCandidateValueObject $right): int
    {
        $priority = $left->type->priority() <=> $right->type->priority();

        if ($priority !== 0) {
            return $priority;
        }

        $leftKey = $this->orderingKey($left);
        $rightKey = $this->orderingKey($right);

        foreach ($leftKey as $index => $value) {
            $comparison = strcmp($value, $rightKey[$index]);

            if ($comparison !== 0) {
                return $comparison;
            }
        }

        return 0;
    }

    /** @return list<string> */
    private function orderingKey(InsightCandidateValueObject $candidate): array
    {
        return [
            $candidate->type->value,
            $candidate->category ?? '',
            $candidate->analysisPeriod->to(),
            $candidate->analysisPeriod->from(),
            $candidate->historyState?->value ?? '',
            $candidate->comparisonPeriod?->to() ?? '',
            $candidate->comparisonPeriod?->from() ?? '',
        ];
    }

    /** @param list<InsightCandidateValueObject> $selected */
    private function isRedundant(InsightCandidateValueObject $candidate, array $selected): bool
    {
        foreach ($selected as $existing) {
            if ($existing->supersedes($candidate)) {
                return true;
            }
        }

        return false;
    }
}
