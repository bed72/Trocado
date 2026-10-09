<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Insights\Application\Data\InsightOutput;
use App\Insights\Application\Ports\ExpenseAnalysisPort;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightsUseCase
{
    public function __construct(
        private UserPort $userPort,
        private ExpenseAnalysisPort $expenseAnalysisPort,
        private ComposeInsightMessageUseCase $messageCompositionUseCase,
        private SelectInsightCandidatesUseCase $candidateSelectionUseCase,
        private GenerateInsightCandidatesUseCase $candidateGenerationUseCase,
    ) {}

    /** @return list<InsightOutput> */
    public function execute(string $referenceDate): array
    {
        $userId = $this->userPort->id();
        $analysis = $this->expenseAnalysisPort->analyze(userId: $userId, referenceDate: $referenceDate);
        $candidates = $this->candidateGenerationUseCase->execute($analysis);
        $selected = $this->candidateSelectionUseCase->execute($candidates);
        $insights = [];

        foreach ($selected as $candidate) {
            $message = $this->messageCompositionUseCase->execute(
                userId: $userId,
                candidate: $candidate,
                referenceDate: $referenceDate,
            );
            $insights[] = new InsightOutput(
                type: $candidate->type,
                title: $message->title,
                period: $candidate->period(),
                group: $candidate->type->group(),
                description: $message->description,
                comparisonPeriod: $candidate->comparisonPeriod,
                id: $this->derivedId(userId: $userId, candidate: $candidate),
            );
        }

        return $insights;
    }

    private function derivedId(int $userId, InsightCandidateValueObject $candidate): string
    {
        return hash('sha256', implode('|', [
            (string) $userId,
            $candidate->type->value,
            $candidate->category ?? '',
            $candidate->historyState?->value ?? '',
            $candidate->analysisPeriod->from(),
            $candidate->analysisPeriod->to(),
            $candidate->comparisonPeriod?->from() ?? '',
            $candidate->comparisonPeriod?->to() ?? '',
        ]));
    }
}
