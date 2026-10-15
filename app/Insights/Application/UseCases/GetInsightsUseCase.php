<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Core\Application\Data\ResourceInput;
use App\Core\Application\Data\ResourceKeyInput;
use App\Core\Application\Ports\UserPort;
use App\Core\Application\UseCases\ResourceUseCase;
use App\Insights\Application\Data\GetInsightsInput;
use App\Insights\Application\Data\InsightOutput;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightsUseCase
{
    private const int IdentityVersion = 1;

    private const string ResourceNamespace = 'insights';

    public function __construct(
        private UserPort $port,
        private ResourceUseCase $resourceUseCase,
        private ComposeInsightMessageUseCase $messageCompositionUseCase,
        private SelectInsightCandidatesUseCase $candidateSelectionUseCase,
        private GenerateInsightCandidatesUseCase $candidateGenerationUseCase,
        private ExpenseAnalysisRepository $repository,
    ) {}

    /** @return list<InsightOutput> */
    public function execute(GetInsightsInput $input): array
    {
        $messages = [];
        $identities = [];

        $period = new InsightAnalysisPeriodValueObject($input->queryDate, $input->selectedMonth);
        $userId = $this->port->id();

        $analysis = $this->repository->analyze(userId: $userId, period: $period);
        $candidates = $this->candidateGenerationUseCase->execute($analysis);
        $selected = $this->candidateSelectionUseCase->execute($candidates);

        foreach ($selected as $candidate) {
            $messages[] = $this->messageCompositionUseCase->execute(
                userId: $userId,
                candidate: $candidate,
                referenceDate: $input->queryDate,
            );
            $identities[] = $this->identity($candidate);
        }

        $insights = [];
        $resources = $this->resourceUseCase->execute(new ResourceInput($userId, $identities));
        foreach ($selected as $index => $candidate) {
            $message = $messages[$index];
            $insights[] = new InsightOutput(
                type: $candidate->type,
                title: $message->title,
                period: $candidate->period(),
                group: $candidate->type->group(),
                description: $message->description,
                id: $resources->identities[$index]->id,
                comparisonPeriod: $candidate->comparisonPeriod,
            );
        }

        return $insights;
    }

    /** Component order is part of the persisted identity contract. */
    private function identity(InsightCandidateValueObject $candidate): ResourceKeyInput
    {
        return new ResourceKeyInput(namespace: self::ResourceNamespace, identityVersion: self::IdentityVersion, components: [
            'type' => $candidate->type->value,
            'subject' => $candidate->category,
            'history_state' => $candidate->historyState?->value,
            'analysis_from' => $candidate->analysisPeriod->from(),
            'analysis_to' => $candidate->analysisPeriod->to(),
            'comparison_from' => $candidate->comparisonPeriod?->from(),
            'comparison_to' => $candidate->comparisonPeriod?->to(),
        ]);
    }
}
