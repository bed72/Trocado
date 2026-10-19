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
use Tests\Support\Core\Fixtures\UuidFixture;

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
        selectedCategoryAmount: $type === InsightTypeEnum::CategoryLeadStreak ? AmountValueObject::fromAmount('100') : null,
        mode: $mode,
        expenseOccurredOn: $type === InsightTypeEnum::ExpenseConcentration ? $month.'-31' : null,
        analysisPeriod: DatePeriodValueObject::fromDates(
            ($type === InsightTypeEnum::CategoryLeadStreak ? $firstMonth : $month).'-01', $month.'-31',
        ),
        ratio: $type === InsightTypeEnum::CategoryLeadStreak ? null : AmountValueObject::fromAmount('100')->shareOf(AmountValueObject::fromAmount('100')),
    );
    $catalog = new GetInsightMessageTemplatesUseCase;
    $useCase = new ComposeInsightMessageUseCase($catalog, new SelectInsightMessageVariantUseCase);
    $monthName = match (substr($month, 5)) {
        '03' => 'março', '12' => 'dezembro', '01' => 'janeiro'
    };
    $parameters = ['{category}' => $label, '{month}' => $monthName,
        '{identity}' => $label.' · 31/'.substr($month, 5, 2), '{expense_date}' => '31/'.substr($month, 5, 2), '{amount}' => 'R$ 1'];
    $templates = $catalog->execute($candidate);
    expect($templates)->toHaveCount(4);
    $approvedPairs = [];

    foreach ($templates as $template) {
        $validPairs = [];
        foreach ([$template, ...$template->alternatives] as $alternative) {
            $title = strtr($alternative->title, $parameters);
            $description = strtr($alternative->description, $parameters);
            expect($title.' '.$description)->toContain($label, 'R$ 1')
                ->and($title.' '.$description)->not->toMatch('/\{[^}]+\}/u')
                ->and($description)->not->toMatch('/%/u')
                ->not->toMatch('/consumo|prejuízo|rendimento|retorno|patrimônio|renda|destino|capacidade financeira/iu');
            if (grapheme_strlen($title) <= 24 && grapheme_strlen($title.' '.$description) <= 80) {
                $validPairs[] = [$title, $description];
            }
        }
        expect($validPairs)->not->toBeEmpty();
        $approvedPairs = [...$approvedPairs, ...$validPairs];
    }

    $messages = [];
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = $useCase->execute(UuidFixture::at(42), $candidate, $date);
        expect([$message->title, $message->description])->toBeIn($approvedPairs)
            ->and(grapheme_strlen($message->title.' '.$message->description))->toBeLessThanOrEqual(80)
            ->and($useCase->execute(UuidFixture::at(42), $candidate, $date))->toEqual($message);
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
