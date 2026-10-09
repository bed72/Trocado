<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageOutput;
use App\Insights\Application\Data\SelectInsightMessageVariantInput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

use function count;

final readonly class ComposeInsightMessageUseCase
{
    private const int MaximumTitleLength = 32;

    private const int MaximumDescriptionLength = 110;

    private const array CategoryLabels = [
        'food' => 'Alimentação', 'health' => 'Saúde', 'housing' => 'Moradia',
        'leisure' => 'Lazer', 'shopping' => 'Compras', 'services' => 'Serviços',
        'transport' => 'Transporte', 'education' => 'Educação',
        'subscriptions' => 'Assinaturas', 'other' => 'Outros',
    ];

    public function __construct(
        private GetInsightMessageTemplatesUseCase $catalogUseCase,
        private SelectInsightMessageVariantUseCase $variantUseCase,
    ) {}

    public function execute(int $userId, InsightCandidateValueObject $candidate, string $referenceDate): InsightMessageOutput
    {
        $templates = $this->catalogUseCase->execute($candidate);
        $editorialKey = implode('|', [
            GetInsightMessageTemplatesUseCase::Version,
            $candidate->type->value,
            $candidate->category ?? '',
            $candidate->historyState?->value ?? '',
            substr($referenceDate, 0, 7),
        ]);
        $variant = $this->variantUseCase->execute(new SelectInsightMessageVariantInput(
            userId: $userId,
            editorialKey: $editorialKey,
            referenceDate: $referenceDate,
            variantCount: count($templates),
        ));
        $template = $templates[$variant];
        $parameters = $this->parameters($candidate);
        $title = strtr($template->title, $parameters);
        $description = strtr($template->description, $parameters);

        if (mb_strlen($description, 'UTF-8') > self::MaximumDescriptionLength) {
            $description = strtr($template->shortDescription, $parameters);
        }

        if (mb_strlen($title, 'UTF-8') > self::MaximumTitleLength
            || mb_strlen($description, 'UTF-8') > self::MaximumDescriptionLength
            || preg_match('/\{[^}]+\}/u', "{$title} {$description}") === 1) {
            throw new InsightMessageCompositionException('O catálogo não oferece uma mensagem completa dentro dos limites editoriais.');
        }

        return new InsightMessageOutput(title: $title, description: $description);
    }

    /** @return array<string, string> */
    private function parameters(InsightCandidateValueObject $candidate): array
    {
        $parameters = ['{day}' => (string) (int) substr($candidate->analysisPeriod->to(), 8)];

        if ($candidate->category !== null) {
            $parameters['{category}'] = self::CategoryLabels[$candidate->category]
                ?? throw new InsightMessageCompositionException('A categoria não possui um rótulo editorial aprovado.');
        }

        if ($candidate->ratio !== null) {
            $parameters['{percent}'] = $candidate->ratio->roundedPercent();
        }

        return $parameters;
    }
}
