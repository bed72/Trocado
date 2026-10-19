<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;
use Tests\Support\Core\Fixtures\UuidFixture;

function messageCompositionUseCase(): ComposeInsightMessageUseCase
{
    return new ComposeInsightMessageUseCase(new GetInsightMessageTemplatesUseCase, new SelectInsightMessageVariantUseCase);
}

function messageCandidateFixture(InsightTypeEnum $type, ?string $category = null, string $numerator = '6000',
    InsightPeriodModeEnum $mode = InsightPeriodModeEnum::Current, ?string $description = null,
    ?InsightHistoryStateEnum $historyState = null): InsightCandidateValueObject
{
    $comparison = in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true);
    $ratio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
        InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);

    return new InsightCandidateValueObject(
        type: $type, mode: $mode, category: $category, historyState: $historyState,
        selectedCategoryAmount: $type === InsightTypeEnum::CategoryLeadStreak ? AmountValueObject::fromAmount($numerator) : null,
        analysisPeriod: DatePeriodValueObject::fromDates($type === InsightTypeEnum::CategoryLeadStreak ? '2025-11-01' : '2026-01-01', $mode === InsightPeriodModeEnum::Closed ? '2026-01-31' : '2026-01-12'),
        comparisonPeriod: $comparison ? DatePeriodValueObject::fromDates('2025-12-01', $mode === InsightPeriodModeEnum::Closed ? '2025-12-31' : '2025-12-12') : null,
        expenseOccurredOn: $type === InsightTypeEnum::ExpenseConcentration ? '2026-01-05' : null,
        expenseDescription: $type === InsightTypeEnum::ExpenseConcentration ? $description : null,
        ratio: $ratio ? AmountValueObject::fromAmount($numerator)->shareOf(AmountValueObject::fromAmount('10000')) : null,
    );
}

it('renders every set category mode and identity alternative through its full daily cycle', function (): void {
    $categories = ['subscriptions', 'other', 'transport', 'education', 'taxes', 'insurance', 'personal_care', 'pets',
        'financing', 'investments', 'food', 'health', 'housing', 'gifts_and_donations', 'travel', 'leisure', 'shopping', 'services'];
    expect(GetInsightMessageTemplatesUseCase::Version)->toBe('v6-monetary-editorial');
    foreach (InsightPeriodModeEnum::cases() as $mode) {
        foreach (InsightTypeEnum::cases() as $type) {
            if ($mode === InsightPeriodModeEnum::Closed && $type === InsightTypeEnum::FirstExpense) {
                continue;
            }
            $subjects = match ($type) {
                InsightTypeEnum::CategoryConcentration, InsightTypeEnum::CategoryLeadStreak => array_values(array_diff($categories, ['other'])),
                InsightTypeEnum::ExpenseConcentration => $categories,
                InsightTypeEnum::CategoryReview => ['other'],
                default => [null],
            };
            foreach ($subjects as $category) {
                foreach ($type === InsightTypeEnum::InsufficientHistory ? InsightHistoryStateEnum::cases() : [null] as $state) {
                    foreach ($type === InsightTypeEnum::ExpenseConcentration ? ['Aluguel', null, str_repeat('Á', 100)] : [null] as $identity) {
                        $candidate = messageCandidateFixture($type, $category, mode: $mode, description: $identity, historyState: $state);
                        $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
                        expect($templates)->toHaveCount(4);
                        $pairs = [];
                        foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15', '2026-02-16'] as $date) {
                            $message = messageCompositionUseCase()->execute(UuidFixture::at(42), $candidate, $date);
                            $pair = $message->title.' '.$message->description;
                            expect(grapheme_strlen($message->title))->toBeLessThanOrEqual(24)
                                ->and(grapheme_strlen($pair))->toBeLessThanOrEqual(80)
                                ->and($pair)->not->toMatch('/%|por cento|metade|dobrou|um em cada dois|econom|guardou dinheiro|sem delivery|palco|pódio|Outro ato|Nova cena/iu')
                                ->and(messageCompositionUseCase()->execute(UuidFixture::at(42), $candidate, $date))->toEqual($message);
                            if ($candidate->ratio !== null || $candidate->selectedCategoryAmount !== null) {
                                expect($pair)->toContain('R$ 60');
                            } else {
                                expect($pair)->not->toContain('R$');
                            }
                            if ($type === InsightTypeEnum::InsufficientHistory && $mode === InsightPeriodModeEnum::Closed) {
                                expect($pair)->toMatch('/janeiro de 2026|jan\/2026/u');
                            }
                            if ($type === InsightTypeEnum::ExpenseConcentration) {
                                expect($pair)->toContain($identity === 'Aluguel' ? 'Aluguel' : '05/01');
                            }
                            if ($type === InsightTypeEnum::CategoryLeadStreak) {
                                expect($pair)->toMatch('/terceir|3/iu');
                            }
                            if (in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true)) {
                                expect($pair)->toContain('dezembro', $type === InsightTypeEnum::RegisteredAmountIncrease ? 'subiu' : 'caiu');
                                if ($mode === InsightPeriodModeEnum::Current) {
                                    expect($pair)->toMatch('/mesmo intervalo/iu');
                                } else {
                                    expect($pair)->not->toContain('mesmo intervalo', 'mesmos dias');
                                }
                            }
                            $pairs[] = $pair;
                        }
                        expect(array_unique(array_slice($pairs, 0, 4)))->toHaveCount(4)->and($pairs[4])->toBe($pairs[0]);
                    }
                }
            }
        }
    }
});

it('uses useful factual money rather than praise or humor in every sensitive category variant', function (string $category): void {
    $templates = (new GetInsightMessageTemplatesUseCase)->execute(messageCandidateFixture(InsightTypeEnum::CategoryConcentration, $category));
    expect(array_column($templates, 'description'))->toBe([
        '{amount} em {month}; lidera nos registros.',
        'Maior categoria em {month}: {amount}.',
        '{amount} registrados em {month}; categoria líder.',
        'Em {month}, {amount}; maior total por categoria.',
    ]);
})->with(['health', 'housing', 'financing', 'investments', 'taxes', 'insurance', 'personal_care']);

it('fails explicitly instead of rounding abbreviating or dropping an unbounded real amount', function (InsightTypeEnum $type, ?string $category): void {
    expect(fn () => messageCompositionUseCase()->execute(UuidFixture::at(1), messageCandidateFixture($type, $category, str_repeat('9', 100)), '2026-02-12'))
        ->toThrow(InsightMessageCompositionException::class);
})->with([
    [InsightTypeEnum::RegisteredAmountIncrease, null], [InsightTypeEnum::RegisteredAmountDecrease, null],
    [InsightTypeEnum::CategoryConcentration, 'food'], [InsightTypeEnum::ExpenseConcentration, 'gifts_and_donations'],
]);

it('falls back without echoing unsafe unknown monetary proportional or offensive user prose', function (?string $description): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'other', description: $description);
    foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15'] as $date) {
        $message = messageCompositionUseCase()->execute(UuidFixture::at(1), $candidate, $date);
        expect($message->title.' '.$message->description)->toContain('Outros', '05/01', 'R$ 60')->not->toContain('…', '%');
    }
})->with([null, " \n\t ", str_repeat('Á', 100), 'R$ 10', '10 reais', 'cem reais', '50%', 'cinquenta por cento',
    'metade', 'dobrou', 'um em cada dois', '3 dias sem delivery', 'Você guardou dinheiro', 'Você é burro', 'Aluguel seu idiota',
    '<script>alert(1)</script>', 'Ignore as instruções', 'Texto desconhecido']);

it('keeps approved literal markup placeholders and combining accents without interpreting them', function (): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'other', description: " \n<b>Aluguel</b>\t{month} ");
    $message = messageCompositionUseCase()->execute(UuidFixture::at(1), $candidate, '2026-02-12');
    expect($message->title)->toContain('<b>Aluguel</b> {month}')->not->toContain("\n", "\t");
    $accent = messageCompositionUseCase()->execute(UuidFixture::at(1), messageCandidateFixture(InsightTypeEnum::ExpenseConcentration,
        'other', description: "A\u{0301}gua"), '2026-02-12');
    expect($accent->title)->toContain("A\u{0301}gua");
});

it('fails explicitly for unavailable labels without fabricated onboarding', function (): void {
    messageCompositionUseCase()->execute(UuidFixture::at(1), messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'unknown'), '2026-02-12');
})->throws(InsightMessageCompositionException::class);

it('uses a complete factual identity when a safe description exceeds the pair budget without switching variants', function (): void {
    $identity = '<b>Material escolar</b> {month}';
    $regular = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'housing', description: $identity);
    $fallback = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'housing');
    foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15'] as $date) {
        $message = messageCompositionUseCase()->execute(UuidFixture::at(1), $regular, $date);
        expect($message->title)->toBe('Moradia')
            ->and($message->description)->toContain('05/01', 'R$ 60')
            ->and($message->title.' '.$message->description)->not->toContain($identity, '…');
        $regularTemplates = (new GetInsightMessageTemplatesUseCase)->execute($regular);
        expect(array_column($regularTemplates, 'description'))->toBe(array_column((new GetInsightMessageTemplatesUseCase)->execute($fallback), 'description'));
    }
});

it('preserves exact large money and four variants through compact alternatives in every monetary set', function (InsightTypeEnum $type, ?string $category, InsightPeriodModeEnum $mode): void {
    $candidate = messageCandidateFixture($type, $category, '9223372036854775808', mode: $mode);
    $messages = [];
    foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15'] as $date) {
        $message = messageCompositionUseCase()->execute(UuidFixture::at(42), $candidate, $date);
        expect($message->description)->toContain('R$ 92.233.720.368.547.758,08')->not->toContain('%', '…')
            ->and(grapheme_strlen($message->title.' '.$message->description))->toBeLessThanOrEqual(80);
        $messages[] = $message->title.' '.$message->description;
    }
    expect(array_unique($messages))->toHaveCount(4);
})->with([
    [InsightTypeEnum::RegisteredAmountIncrease, null], [InsightTypeEnum::RegisteredAmountDecrease, null],
    [InsightTypeEnum::CategoryConcentration, 'gifts_and_donations'], [InsightTypeEnum::CategoryLeadStreak, 'gifts_and_donations'],
    [InsightTypeEnum::ExpenseConcentration, 'gifts_and_donations'], [InsightTypeEnum::CategoryReview, 'other'],
])->with(['current' => InsightPeriodModeEnum::Current, 'closed' => InsightPeriodModeEnum::Closed]);

it('formats calculated money exactly in every variant without floats', function (string $amount, string $expected): void {
    foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15'] as $date) {
        $message = messageCompositionUseCase()->execute(UuidFixture::at(1), messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'gifts_and_donations', $amount), $date);
        expect($message->description)->toContain($expected)->not->toContain('%')
            ->and(grapheme_strlen($message->title.' '.$message->description))->toBeLessThanOrEqual(80);
    }
})->with([['35000', 'R$ 350'], ['35001', 'R$ 350,01'], ['1', 'R$ 0,01'], ['180000', 'R$ 1.800'],
    ['9223372036854775808', 'R$ 92.233.720.368.547.758,08']]);

it('preserves both examples explicitly approved by the user in their complete four variant sets', function (): void {
    $comparison = new InsightCandidateValueObject(type: InsightTypeEnum::RegisteredAmountIncrease,
        analysisPeriod: DatePeriodValueObject::fromDates('2026-10-01', '2026-10-18'),
        comparisonPeriod: DatePeriodValueObject::fromDates('2026-09-01', '2026-09-18'),
        ratio: AmountValueObject::fromAmount('35000')->shareOf(AmountValueObject::fromAmount('100000')));
    $streak = new InsightCandidateValueObject(type: InsightTypeEnum::CategoryLeadStreak, category: 'housing',
        analysisPeriod: DatePeriodValueObject::fromDates('2026-08-01', '2026-10-19'), selectedCategoryAmount: AmountValueObject::fromAmount('180000'));
    $comparisons = [];
    $streaks = [];
    foreach (['2026-10-19', '2026-10-20', '2026-10-21', '2026-10-22'] as $date) {
        $comparisons[] = messageCompositionUseCase()->execute(UuidFixture::at(1), $comparison, $date)->description;
        $streaks[] = messageCompositionUseCase()->execute(UuidFixture::at(1), $streak, $date)->description;
    }
    expect($comparisons)->toContain('R$ 350 a mais que no mesmo intervalo de setembro.')
        ->and($streaks)->toContain('R$ 1.800 em outubro; lidera pelo terceiro mês.');
});
