<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageOutput;
use App\Insights\Application\Data\SelectInsightMessageVariantInput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use App\Insights\Domain\ValueObjects\InsightMessageValueObject;
use Normalizer;

use function array_key_exists;
use function count;

final readonly class ComposeInsightMessageUseCase
{
    private const array Categories = [
        'subscriptions' => 'Assinaturas', 'other' => 'Outros',
        'transport' => 'Transporte', 'education' => 'Educação',
        'taxes' => 'Impostos e taxas', 'insurance' => 'Seguros',
        'personal_care' => 'Cuidados pessoais', 'pets' => 'Pets',
        'financing' => 'Financiamentos', 'investments' => 'Investimentos',
        'food' => 'Alimentação', 'health' => 'Saúde', 'housing' => 'Moradia',
        'gifts_and_donations' => 'Presentes e doações', 'travel' => 'Viagens',
        'leisure' => 'Lazer', 'shopping' => 'Compras', 'services' => 'Serviços',
    ];

    public function __construct(
        private GetInsightMessageTemplatesUseCase $catalogUseCase,
        private SelectInsightMessageVariantUseCase $variantUseCase,
    ) {}

    public function execute(string $userId, InsightCandidateValueObject $candidate, string $referenceDate): InsightMessageOutput
    {
        $templates = $this->catalogUseCase->execute($candidate);
        $editorialKey = implode('|', [
            GetInsightMessageTemplatesUseCase::Version,
            $candidate->type->value,
            $candidate->mode->value,
            $candidate->category ?? '',
            $candidate->historyState?->value ?? '',
            substr($candidate->analysisPeriod->to(), 0, 7),
        ]);

        $variant = $this->variantUseCase->execute(new SelectInsightMessageVariantInput(
            userId: $userId,
            editorialKey: $editorialKey,
            referenceDate: $referenceDate,
            variantCount: count($templates),
        ));

        $template = $templates[$variant];
        $parameters = $this->parameters($candidate);
        foreach ($this->identities($candidate, $parameters) as $identity) {
            foreach ([$template, ...$template->alternatives] as $alternative) {
                $title = $this->interpolate($alternative->title, [...$parameters, '{identity}' => $identity]);
                $description = $this->interpolate($alternative->description, $parameters);

                try {
                    $message = new InsightMessageValueObject($title, $description);
                } catch (InvalidInsightAnalysisException) {
                    continue;
                }

                return new InsightMessageOutput(title: $message->title, description: $message->description);
            }
        }

        throw new InsightMessageCompositionException('O catálogo não oferece uma mensagem completa dentro dos limites editoriais.');
    }

    /** @return array<string, string> */
    private function parameters(InsightCandidateValueObject $candidate): array
    {
        $parameters = [
            '{month}' => $this->month($candidate->analysisPeriod->to(),
                $candidate->type === InsightTypeEnum::InsufficientHistory && $candidate->mode === InsightPeriodModeEnum::Closed),
            '{short_month}' => $this->shortMonth($candidate->analysisPeriod->to(), $candidate->mode === InsightPeriodModeEnum::Closed),
            '{previous_month}' => $candidate->comparisonPeriod !== null ? $this->month($candidate->comparisonPeriod->from()) : '',
        ];

        $amount = $candidate->selectedCategoryAmount ?? $candidate->ratio?->numerator;
        if ($amount !== null) {
            $parameters['{amount}'] = $this->brl($amount->amount());
        }

        if ($candidate->expenseOccurredOn !== null) {
            $parameters['{expense_date}'] = substr($candidate->expenseOccurredOn, 8, 2).'/'.substr($candidate->expenseOccurredOn, 5, 2);
        }

        if ($candidate->category !== null) {
            $parameters['{category}'] = self::Categories[$candidate->category]
                ?? throw new InsightMessageCompositionException('A categoria não possui um rótulo editorial aprovado.');
        }

        return $parameters;
    }

    /**
     * @param  array<string, string>  $parameters
     * @return non-empty-list<string>
     */
    private function identities(InsightCandidateValueObject $candidate, array $parameters): array
    {
        if ($candidate->type !== InsightTypeEnum::ExpenseConcentration) {
            return [''];
        }

        $identities = [];

        if ($candidate->expenseDescription !== null) {
            $normalized = preg_replace('/[\s\p{Z}]+/u', ' ', $candidate->expenseDescription);

            if ($normalized === null) {
                throw new InsightMessageCompositionException('A descrição do lançamento não é texto Unicode válido.');
            }

            $normalized = trim($normalized);

            if ($normalized !== '' && $this->isSafeIdentity($normalized)) {
                $identities[] = $normalized;
            }
        }

        $date = $candidate->expenseOccurredOn;
        $day = substr($date, 8, 2);
        $month = substr($date, 5, 2);
        $identities[] = "{$parameters['{category}']} · {$day}/{$month}";

        return $identities;
    }

    /** @param array<string, string> $parameters */
    private function interpolate(string $template, array $parameters): string
    {
        preg_match_all('/\{[^}]+\}/u', $template, $matches);

        foreach ($matches[0] as $placeholder) {
            if (! array_key_exists($placeholder, $parameters)) {
                throw new InsightMessageCompositionException('O catálogo exige um fato indisponível.');
            }
        }

        return strtr($template, $parameters);
    }

    private function isSafeIdentity(string $description): bool
    {
        $normalized = Normalizer::normalize($description, Normalizer::FORM_C);

        return preg_match('/\A(?:<b>)?(?:Aluguel|Mensalidade|Mercado|Supermercado|Internet|Energia|Água|Curso|Material escolar|Transporte|Consulta|Seguro|Assinatura)(?:<\/b>)?(?: \{month\})?\z/iu', $normalized) === 1;
    }

    private function brl(string $amount): string
    {
        $padded = str_pad($amount, 3, '0', STR_PAD_LEFT);
        $integer = preg_replace('/\B(?=(?:[0-9]{3})+(?![0-9]))/', '.', substr($padded, 0, -2));
        $cents = substr($padded, -2);

        return 'R$ '.$integer.($cents === '00' ? '' : ','.$cents);
    }

    private function month(string $date, bool $withYear = false): string
    {
        $months = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
        $month = $months[(int) substr($date, 5, 2) - 1];

        return $month.($withYear ? ' de '.substr($date, 0, 4) : '');
    }

    private function shortMonth(string $date, bool $withYear): string
    {
        $months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

        $month = $months[(int) substr($date, 5, 2) - 1];
        $year = substr($date, 0, 4);

        return $withYear ? "{$month}/{$year}" : $this->month($date);
    }
}
