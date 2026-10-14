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

function messageCompositionUseCase(): ComposeInsightMessageUseCase
{
    return new ComposeInsightMessageUseCase(new GetInsightMessageTemplatesUseCase, new SelectInsightMessageVariantUseCase);
}

function messageCandidateFixture(
    InsightTypeEnum $type,
    ?string $category = null,
    string $numerator = '6000',
    string $denominator = '10000',
    ?InsightHistoryStateEnum $historyState = null,
    string $to = '2026-10-11',
    InsightPeriodModeEnum $mode = InsightPeriodModeEnum::Current,
    ?string $description = null,
    string $occurredOn = '2026-10-05',
): InsightCandidateValueObject {
    $comparison = in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true);
    $ratio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
        InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);

    return new InsightCandidateValueObject(
        type: $type,
        mode: $mode,
        category: $category,
        historyState: $historyState,
        expenseDescription: $type === InsightTypeEnum::ExpenseConcentration ? $description : null,
        expenseOccurredOn: $type === InsightTypeEnum::ExpenseConcentration ? $occurredOn : null,
        comparisonPeriod: $comparison ? ($mode === InsightPeriodModeEnum::Closed
            ? DatePeriodValueObject::monthContaining('2026-09-01')
            : DatePeriodValueObject::fromDates('2026-09-01', str_replace('2026-10', '2026-09', $to))) : null,
        ratio: $ratio ? AmountValueObject::fromAmount($numerator)->shareOf(AmountValueObject::fromAmount($denominator)) : null,
        analysisPeriod: DatePeriodValueObject::fromDates($type === InsightTypeEnum::CategoryLeadStreak ? '2026-08-01' : '2026-10-01', $to),
    );
}

it('keeps every approved catalog set with four complete regular compact and monetary variants', function (): void {
    $sets = [
        [InsightTypeEnum::CategoryConcentration, 'food', null],
        [InsightTypeEnum::CategoryConcentration, 'health', null],
        [InsightTypeEnum::ExpenseConcentration, 'other', null],
        [InsightTypeEnum::RegisteredAmountIncrease, null, null],
        [InsightTypeEnum::RegisteredAmountDecrease, null, null],
        [InsightTypeEnum::CategoryLeadStreak, 'food', null],
        [InsightTypeEnum::FirstExpense, null, null],
        [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::CurrentExpenses],
        [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::NoCurrentExpenses],
        [InsightTypeEnum::CategoryReview, 'other', null],
    ];
    $parameters = [
        '{category}' => 'Assinaturas', '{percent}' => '100', '{day}' => '31', '{sign}' => '+',
        '{month}' => 'out/9999', '{previous_month}' => 'set/9999', '{first_month}' => 'ago/9999',
        '{identity}' => 'Assinaturas · 31/10', '{amount}' => 'R$ 1.200,00', '{difference}' => 'R$ 92.233.720.368.547.758,08',
    ];

    expect(GetInsightMessageTemplatesUseCase::Version)->toBe('v4-monthly-editorial');

    foreach (InsightPeriodModeEnum::cases() as $mode) {
        foreach ($sets as [$type, $category, $state]) {
            if ($type === InsightTypeEnum::FirstExpense && $mode === InsightPeriodModeEnum::Closed) {
                continue;
            }

            $candidate = messageCandidateFixture($type, $category, historyState: $state, mode: $mode,
                to: $mode === InsightPeriodModeEnum::Current && in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true)
                    ? '2026-10-30' : '2026-10-31');
            $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
            expect($templates)->toHaveCount(4);
            $variants = [];

            foreach ($templates as $template) {
                $title = strtr($template->title, $parameters);
                expect(mb_strlen($title, 'UTF-8'))->toBeLessThanOrEqual(24);
                $variants[] = $template->description;

                foreach (array_filter([$template->description, $template->shortDescription, $template->monetaryDescription]) as $description) {
                    $description = strtr($description, $parameters);
                    expect(mb_strlen($description, 'UTF-8'))->toBeLessThanOrEqual(80)
                        ->and($description)->not->toMatch('/\{[^}]+\}/u')
                        ->and($description)->toEndWith('.')
                        ->and($title.' '.$description)->toContain('out/9999');
                }
            }

            expect(array_unique($variants))->toHaveCount(4);
        }
    }
});

it('renders every monthly catalog set with complete paired messages and daily variants within 24 80', function (
    InsightTypeEnum $type, ?string $category, ?InsightHistoryStateEnum $state, InsightPeriodModeEnum $mode,
): void {
    $candidate = messageCandidateFixture($type, $category, historyState: $state, mode: $mode,
        to: $mode === InsightPeriodModeEnum::Closed ? '2026-10-31' : '2026-10-11');
    $useCase = messageCompositionUseCase();
    $pairs = [];

    foreach (['2026-11-12', '2026-11-13', '2026-11-14', '2026-11-15'] as $date) {
        $message = $useCase->execute(1, $candidate, $date);
        $pairs[] = $message->title.'|'.$message->description;
        expect(mb_strlen($message->title, 'UTF-8'))->toBeLessThanOrEqual(24)
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(80)
            ->and($message->title.' '.$message->description)->toContain('out/2026')
            ->not->toMatch('/\{[^}]+\}|palco|figurante|piada|cristal/iu')
            ->and($useCase->execute(1, $candidate, $date))->toEqual($message);

        if ($mode === InsightPeriodModeEnum::Closed) {
            expect($message->description)->not->toContain('até dia', 'neste mês');
        }
    }

    expect(array_unique($pairs))->toHaveCount(4);
})->with([
    'food category' => [InsightTypeEnum::CategoryConcentration, 'food', null],
    'health category' => [InsightTypeEnum::CategoryConcentration, 'health', null],
    'subscriptions category' => [InsightTypeEnum::CategoryConcentration, 'subscriptions', null],
    'largest expense' => [InsightTypeEnum::ExpenseConcentration, 'other', null],
    'increase' => [InsightTypeEnum::RegisteredAmountIncrease, null, null],
    'decrease' => [InsightTypeEnum::RegisteredAmountDecrease, null, null],
    'food leadership' => [InsightTypeEnum::CategoryLeadStreak, 'food', null],
    'health leadership' => [InsightTypeEnum::CategoryLeadStreak, 'health', null],
    'insufficient records' => [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::CurrentExpenses],
    'empty month' => [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::NoCurrentExpenses],
    'review' => [InsightTypeEnum::CategoryReview, 'other', null],
])->with(['current' => InsightPeriodModeEnum::Current, 'closed' => InsightPeriodModeEnum::Closed]);

it('renders all approved first expense variants with the selected month and current cutoff', function (): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::FirstExpense, to: '2026-10-12');
    $approved = [
        'Sem despesas registradas até dia 12 de out/2026. Cadastre a primeira.',
        'Até dia 12 de out/2026, não há despesas registradas. Registre a primeira.',
        'Nenhuma despesa registrada até dia 12 de out/2026. Adicione a primeira.',
        'Registre sua primeira despesa: não há registros até dia 12 de out/2026.',
    ];
    $visited = [];
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->title)->toBe('Primeiro registro')
            ->and($message->description)->toBeIn($approved);
        $visited[] = $message->description;
    }
    expect($visited)->toEqualCanonicalizing($approved);
});

it('recalculates percentages without changing the chosen daily variant', function (): void {
    $useCase = messageCompositionUseCase();
    $before = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'food', '3850'), '2026-10-12');
    $after = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'food', '4200'), '2026-10-12');
    expect($before->title)->toBe('Alimentação')
        ->and($after->title)->toBe($before->title)
        ->and($before->description)->toContain('39%')
        ->and($after->description)->toContain('42%')
        ->and(str_replace('39%', '42%', $before->description))->toBe($after->description);
});

it('preserves all approved leadership variants across explicit accounts', function (int $userId): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::CategoryLeadStreak, 'food', to: '2026-10-12');
    $approved = [
        'Líder registrada em ago/2026, set/2026 e out/2026 até dia 12.',
        'Maior total registrado em ago/2026, set/2026 e out/2026 até dia 12.',
        'Lidera os registros em ago/2026, set/2026 e out/2026 até dia 12.',
        'Primeiro lugar nos registros: ago/2026, set/2026 e out/2026 até dia 12.',
    ];
    $visited = [];
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute($userId, $candidate, $date);
        expect($message->title)->toBe('Alimentação')
            ->and($message->description)->toBeIn($approved)
            ->and(messageCompositionUseCase()->execute($userId, $candidate, $date))->toEqual($message);
        $visited[] = $message->description;
    }
    expect($visited)->toEqualCanonicalizing($approved);
})->with(['account 1' => 1, 'account 2' => 2, 'account 3' => 3, 'account 4' => 4, 'account 15' => 15, 'account 1500' => 1500]);

it('keeps the variant when the comparison cutoff changes in the same month', function (): void {
    $useCase = messageCompositionUseCase();
    $first = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease), '2026-10-20');
    $second = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-19'), '2026-10-20');
    expect($first->title)->toBe($second->title)
        ->and(str_replace('11', '19', $first->description))->toBe($second->description);
});

it('fails explicitly rather than dropping an unbounded comparison magnitude', function (): void {
    messageCompositionUseCase()->execute(1,
        messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, numerator: str_repeat('9', 100)), '2026-10-12');
})->throws(InsightMessageCompositionException::class);

it('uses distinct contextual history sets without claiming the first expense', function (): void {
    $old = messageCompositionUseCase()->execute(1, messageCandidateFixture(InsightTypeEnum::InsufficientHistory,
        historyState: InsightHistoryStateEnum::NoCurrentExpenses), '2026-10-12');
    $current = messageCompositionUseCase()->execute(1, messageCandidateFixture(InsightTypeEnum::InsufficientHistory,
        historyState: InsightHistoryStateEnum::CurrentExpenses), '2026-10-12');
    expect($old->title)->toBe('Registros · out/2026')
        ->and($current->title)->toBe('Análise · out/2026')
        ->and($old->description)->not->toContain('primeira')
        ->and($current->description)->not->toContain('primeira');
});

it('rejects unknown category labels instead of inventing text', function (): void {
    messageCompositionUseCase()->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'unknown'), '2026-10-12');
})->throws(InsightMessageCompositionException::class);

it('fails when even the final identification alternative cannot preserve the fact', function (): void {
    messageCompositionUseCase()->execute(1,
        messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'food', str_repeat('9', 100)), '2026-10-12');
})->throws(InsightMessageCompositionException::class);

it('uses all neutral labels in the title and preserves the factual percentage', function (string $category, string $label): void {
    $message = messageCompositionUseCase()->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, $category), '2026-10-12');
    expect($message->title)->toBe($label)
        ->and($message->description)->toContain('60%', 'out/2026')
        ->not->toContain('fome');
})->with([
    ['health', 'Saúde'], ['housing', 'Moradia'], ['leisure', 'Lazer'], ['shopping', 'Compras'],
    ['services', 'Serviços'], ['transport', 'Transporte'], ['education', 'Educação'], ['subscriptions', 'Assinaturas'],
]);

it('starts another repeatable cycle after a month and eligible set transition', function (): void {
    $useCase = messageCompositionUseCase();
    $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::FirstExpense), '2026-10-31');
    $november = new InsightCandidateValueObject(type: InsightTypeEnum::InsufficientHistory,
        analysisPeriod: DatePeriodValueObject::fromDates('2026-11-01', '2026-11-01'), historyState: InsightHistoryStateEnum::NoCurrentExpenses);
    $pairs = [];
    foreach (['2026-11-01', '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05'] as $date) {
        $message = $useCase->execute(1, $november, $date);
        expect($message->description)->not->toContain('primeira');
        $pairs[] = $message->title.'|'.$message->description;
    }
    expect(array_unique(array_slice($pairs, 0, 4)))->toHaveCount(4)
        ->and($pairs[4])->toBe($pairs[0]);
});

it('normalizes expense whitespace and keeps markup and placeholder shaped user text literal', function (): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'housing', '120000', '222222',
        description: " \t<b>Aluguel</b>\n\u{00A0}{month}  ");
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->description)->toContain('<b>Aluguel</b> {month}', '54%', 'R$ 1.200,00')
            ->not->toContain("\n", "\t", '\u{00A0}')
            ->and($message->title)->toBe('Maior · out/2026 até 11');
    }
});

it('prioritizes complete description without amount before category date with amount', function (): void {
    $description = str_repeat('Á', 41);
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'housing', '120000', '222222', description: $description);
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->description)->toContain($description, '54%')
            ->not->toContain('R$', 'Moradia', '…')
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(80)
            ->and(strlen($message->description))->toBeGreaterThan(80);
    }
});

it('uses category and occurrence for absent blank or too long descriptions without truncation', function (?string $description): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'other', '120000', '222222', description: $description);
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->description)->toContain('Outros · 05/10', '54%', 'R$ 1.200,00')
            ->not->toContain('…', 'inferido');
    }
})->with(['absent' => null, 'blank' => " \n\t\u{2003} ", 'too long' => str_repeat('Á', 64)]);

it('formats expense cents exactly without float including values beyond native integers', function (string $amount, string $expected): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'housing', $amount, $amount, description: 'X');
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->description)->toContain($expected, '100%');
    }
})->with([
    'cent' => ['1', 'R$ 0,01'], 'single real' => ['100', 'R$ 1,00'],
    'thousands' => ['123456', 'R$ 1.234,56'],
    'above PHP_INT_MAX' => ['9223372036854775808', 'R$ 92.233.720.368.547.758,08'],
]);

it('keeps category date and percentage when even the expense amount cannot fit', function (): void {
    $amount = str_repeat('9', 100);
    $candidate = messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'gifts_and_donations', $amount, $amount);
    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->description)->toContain('Presentes e doações · 05/10', '100%')
            ->not->toContain('R$')
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(80);
    }
});

it('uses compact percentages when necessary within the same daily comparison variant', function (InsightPeriodModeEnum $mode): void {
    $regular = messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, numerator: '25', denominator: '100', mode: $mode,
        to: $mode === InsightPeriodModeEnum::Closed ? '2026-10-31' : '2026-10-11');
    $compact = messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, numerator: str_repeat('9', 30), denominator: '100', mode: $mode,
        to: $mode === InsightPeriodModeEnum::Closed ? '2026-10-31' : '2026-10-11');
    $templates = (new GetInsightMessageTemplatesUseCase)->execute($regular);
    $visited = [];
    $compactCount = 0;

    foreach (['2026-11-12', '2026-11-13', '2026-11-14', '2026-11-15'] as $date) {
        $useCase = messageCompositionUseCase();
        $base = $useCase->execute(1, $regular, $date);
        $big = $useCase->execute(1, $compact, $date);
        $parameters = ['{month}' => 'out/2026', '{previous_month}' => 'set/2026', '{day}' => '11', '{sign}' => '+', '{percent}' => '25'];
        $selected = array_values(array_filter($templates, static fn ($template): bool => strtr($template->description, $parameters) === $base->description))[0];
        $expectedCompact = strtr($selected->shortDescription, [...$parameters, '{percent}' => str_repeat('9', 30)]);
        $expectedRegular = strtr($selected->description, [...$parameters, '{percent}' => str_repeat('9', 30)]);
        $needsCompact = mb_strlen($expectedRegular, 'UTF-8') > 80;
        $compactCount += (int) $needsCompact;

        expect($big->description)->toBe($needsCompact ? $expectedCompact : $expectedRegular)
            ->and($big->description)->toContain('+'.str_repeat('9', 30).'%', 'set/2026')
            ->and(mb_strlen($big->description, 'UTF-8'))->toBeLessThanOrEqual(80);
        $visited[] = $big->description;
    }
    expect(array_unique($visited))->toHaveCount(4)
        ->and($compactCount)->toBeGreaterThan(0);
})->with(['current' => InsightPeriodModeEnum::Current, 'closed' => InsightPeriodModeEnum::Closed]);

it('preserves direction and both explicit years in every comparison variant', function (InsightPeriodModeEnum $mode, InsightTypeEnum $type, string $sign): void {
    $candidate = new InsightCandidateValueObject(
        type: $type, mode: $mode,
        analysisPeriod: DatePeriodValueObject::fromDates('2026-01-01', $mode === InsightPeriodModeEnum::Closed ? '2026-01-31' : '2026-01-11'),
        comparisonPeriod: DatePeriodValueObject::fromDates('2025-12-01', $mode === InsightPeriodModeEnum::Closed ? '2025-12-31' : '2025-12-11'),
        ratio: AmountValueObject::fromAmount('5000')->shareOf(AmountValueObject::fromAmount('10000')),
    );
    foreach (['2026-02-12', '2026-02-13', '2026-02-14', '2026-02-15'] as $date) {
        $message = messageCompositionUseCase()->execute(1, $candidate, $date);
        expect($message->title)->toBe('Total · jan/2026')
            ->and($message->description)->toContain($sign.'50%', 'dez/2025', 'registrado')
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(80);
        if ($mode === InsightPeriodModeEnum::Closed) {
            expect($message->description)->toMatch('/mês/iu')
                ->not->toContain('1–11', 'até', 'mesmos dias');
        } else {
            expect($message->description)->toContain('1–11')
                ->not->toContain('completo');
        }
    }
})->with(['current' => InsightPeriodModeEnum::Current, 'closed' => InsightPeriodModeEnum::Closed])
    ->with(['increase' => [InsightTypeEnum::RegisteredAmountIncrease, '+'], 'decrease' => [InsightTypeEnum::RegisteredAmountDecrease, '−']]);

it('retains all approved exact monetary catalog alternatives with independent expected text', function (InsightPeriodModeEnum $mode): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::RegisteredAmountDecrease, mode: $mode,
        to: $mode === InsightPeriodModeEnum::Closed ? '2026-10-31' : '2026-10-11');
    $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
    $expected = $mode === InsightPeriodModeEnum::Closed ? [
        '−R$ 92.233.720.368.547.758,08 no total registrado; mês completo vs. set/2026.',
        'Total registrado −R$ 92.233.720.368.547.758,08; mês completo vs. set/2026.',
        'Mês completo: −R$ 92.233.720.368.547.758,08 no total registrado vs. set/2026.',
        'Total registrado: −R$ 92.233.720.368.547.758,08; mês completo vs. set/2026.',
    ] : [
        '−R$ 92.233.720.368.547.758,08 no total registrado; 1–11 vs. 1–11 de set/2026.',
        'Total registrado −R$ 92.233.720.368.547.758,08; 1–11 vs. 1–11 de set/2026.',
        '1–11: −R$ 92.233.720.368.547.758,08 no total registrado vs. 1–11 de set/2026.',
        'Total registrado: −R$ 92.233.720.368.547.758,08; 1–11 vs. 1–11 de set/2026.',
    ];
    foreach ($templates as $index => $template) {
        $text = strtr($template->monetaryDescription, [
            '{sign}' => '−', '{difference}' => 'R$ 92.233.720.368.547.758,08', '{day}' => '11', '{previous_month}' => 'set/2026',
        ]);
        expect($text)->toBe($expected[$index])
            ->and(mb_strlen($text, 'UTF-8'))->toBeLessThanOrEqual(80);
    }
})->with(['current' => InsightPeriodModeEnum::Current, 'closed' => InsightPeriodModeEnum::Closed]);
