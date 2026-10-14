<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

it('renders every affected regular and short variant with integral labels and factual periods within current Unicode budgets', function (
    string $category,
    string $label,
    InsightTypeEnum $type,
    InsightPeriodModeEnum $mode,
    string $month,
    string $firstMonth,
    string $periodLabel,
    string $firstLabel,
    string $previousLabel,
): void {
    $candidate = new InsightCandidateValueObject(
        type: $type,
        category: $category,
        mode: $mode,
        expenseOccurredOn: $type === InsightTypeEnum::ExpenseConcentration ? $month.'-31' : null,
        analysisPeriod: DatePeriodValueObject::fromDates(
            ($type === InsightTypeEnum::CategoryLeadStreak ? $firstMonth : $month).'-01', $month.'-31',
        ),
        ratio: $type === InsightTypeEnum::CategoryLeadStreak ? null : AmountValueObject::fromAmount('100')->shareOf(AmountValueObject::fromAmount('100')),
    );
    $catalog = new GetInsightMessageTemplatesUseCase;
    $useCase = new ComposeInsightMessageUseCase($catalog, new SelectInsightMessageVariantUseCase);
    $parameters = ['{category}' => $label, '{percent}' => '100', '{day}' => '31', '{month}' => $periodLabel, '{first_month}' => $firstLabel,
        '{previous_month}' => $previousLabel, '{identity}' => $label.' · 31/'.substr($month, 5, 2), '{amount}' => 'R$ 1,00'];
    $templates = $catalog->execute($candidate);
    expect($templates)->toHaveCount(4);
    $approvedPairs = [];

    foreach ($templates as $template) {
        $title = strtr($template->title, $parameters);
        foreach ([$template->description, $template->shortDescription] as $description) {
            $description = strtr($description, $parameters);
            expect(mb_strlen($title, 'UTF-8'))->toBeLessThanOrEqual(24)
                ->and(mb_strlen($description, 'UTF-8'))->toBeLessThanOrEqual(80)
                ->and($title.' '.$description)->not->toMatch('/\{[^}]+\}/u')
                ->and($description)->toMatch('/registrad|registros/u')
                ->not->toMatch('/consumo|prejuízo|rendimento|retorno|patrimônio|renda|destino|capacidade financeira/iu');
            expect($title.' '.$description)->toContain($label, $periodLabel);
            if ($mode === InsightPeriodModeEnum::Closed) {
                expect($title.' '.$description)->toContain($periodLabel);
                if ($type === InsightTypeEnum::CategoryLeadStreak) {
                    expect($description)->toContain($firstLabel, 'três meses completos');
                }
            }
            $approvedPairs[] = [$title, $description];
        }
    }

    $messages = [];
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = $useCase->execute(42, $candidate, $date);
        expect([$message->title, $message->description])->toBeIn($approvedPairs)
            ->and($useCase->execute(42, $candidate, $date))->toEqual($message);
        $messages[] = $message->title.'|'.$message->description;
    }
    expect(array_unique($messages))->toHaveCount(4);
})->with([
    'food' => ['food', 'Alimentação'],
    'health' => ['health', 'Saúde'],
    'housing' => ['housing', 'Moradia'],
    'leisure' => ['leisure', 'Lazer'],
    'shopping' => ['shopping', 'Compras'],
    'services' => ['services', 'Serviços'],
    'transport' => ['transport', 'Transporte'],
    'education' => ['education', 'Educação'],
    'subscriptions' => ['subscriptions', 'Assinaturas'],
    'financing' => ['financing', 'Financiamentos'],
    'investments' => ['investments', 'Investimentos'],
    'taxes' => ['taxes', 'Impostos e taxas'],
    'insurance' => ['insurance', 'Seguros'],
    'personal care' => ['personal_care', 'Cuidados pessoais'],
    'pets' => ['pets', 'Pets'],
    'gifts and donations' => ['gifts_and_donations', 'Presentes e doações'],
    'travel' => ['travel', 'Viagens'],
])->with([
    'category concentration' => InsightTypeEnum::CategoryConcentration,
    'expense concentration' => InsightTypeEnum::ExpenseConcentration,
    'recurring leadership' => InsightTypeEnum::CategoryLeadStreak,
])->with([
    'current' => InsightPeriodModeEnum::Current,
    'closed' => InsightPeriodModeEnum::Closed,
])->with([
    'first civil window' => ['0001-03', '0001-01', 'mar/0001', 'jan/0001', 'fev/0001'],
    'last civil window' => ['9999-12', '9999-10', 'dez/9999', 'out/9999', 'nov/9999'],
    'year transition' => ['2026-01', '2025-11', 'jan/2026', 'nov/2025', 'dez/2025'],
]);
