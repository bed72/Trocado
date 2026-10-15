<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Insights\Application\Data\GetInsightsInput;
use App\Insights\Application\Data\InsightOutput;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightsUseCase
{
    public function __construct(
        private UserPort $port,
        private ComposeInsightMessageUseCase $messageCompositionUseCase,
        private SelectInsightCandidatesUseCase $candidateSelectionUseCase,
        private GenerateInsightCandidatesUseCase $candidateGenerationUseCase,
        private ExpenseAnalysisRepository $repository,
    ) {}

    /** @return list<InsightOutput> */
    public function execute(GetInsightsInput $input): array
    {
        $period = new InsightAnalysisPeriodValueObject($input->queryDate, $input->selectedMonth);
        $userId = $this->port->id();
        $analysis = $this->repository->analyze(userId: $userId, period: $period);
        $candidates = $this->candidateGenerationUseCase->execute($analysis);
        $selected = $this->candidateSelectionUseCase->execute($candidates);
        $insights = [];

        foreach ($selected as $candidate) {
            $message = $this->messageCompositionUseCase->execute(
                userId: $userId,
                candidate: $candidate,
                referenceDate: $input->queryDate,
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

    private function derivedId(string $userId, InsightCandidateValueObject $candidate): string
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
