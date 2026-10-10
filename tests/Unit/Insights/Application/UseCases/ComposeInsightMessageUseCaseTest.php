<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\InsightMessageTemplateOutput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GetInsightMessageTemplatesUseCase;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
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
): InsightCandidateValueObject {
    $comparison = in_array($type, [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease], true);
    $ratio = in_array($type, [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration,
        InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryReview], true);

    return new InsightCandidateValueObject(
        type: $type,
        category: $category,
        historyState: $historyState,
        comparisonPeriod: $comparison ? DatePeriodValueObject::fromDates('2026-09-01', str_replace('2026-10', '2026-09', $to)) : null,
        ratio: $ratio ? AmountValueObject::fromAmount($numerator)->shareOf(AmountValueObject::fromAmount($denominator)) : null,
        analysisPeriod: DatePeriodValueObject::fromDates($type === InsightTypeEnum::CategoryLeadStreak ? '2026-08-01' : '2026-10-01', $to),
    );
}

it('keeps every catalog set compact for cards with four complete variants', function (): void {
    $candidates = [
        messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'food'),
        messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'health'),
        messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'other'),
        messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease),
        messageCandidateFixture(InsightTypeEnum::RegisteredAmountDecrease),
        messageCandidateFixture(InsightTypeEnum::CategoryLeadStreak, 'food'),
        messageCandidateFixture(InsightTypeEnum::FirstExpense),
        messageCandidateFixture(InsightTypeEnum::InsufficientHistory, historyState: InsightHistoryStateEnum::CurrentExpenses),
        messageCandidateFixture(InsightTypeEnum::InsufficientHistory, historyState: InsightHistoryStateEnum::NoCurrentExpenses),
        messageCandidateFixture(InsightTypeEnum::CategoryReview, 'other'),
    ];
    $parameters = ['{category}' => 'Assinaturas', '{percent}' => '100', '{day}' => '31'];

    foreach ($candidates as $candidate) {
        $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
        expect($templates)->toHaveCount(4);

        foreach ($templates as $template) {
            expect(mb_strlen(strtr($template->title, $parameters), 'UTF-8'))->toBeLessThanOrEqual(32);

            foreach ([$template->description, $template->shortDescription] as $description) {
                $description = strtr($description, $parameters);

                expect(mb_strlen($description, 'UTF-8'))->toBeLessThanOrEqual(80)
                    ->and(str_contains($description, '{'))->toBeFalse()
                    ->and(preg_match('/[.?]$/u', $description))->toBe(1);
            }
        }
    }

});

it('renders every catalog set with complete paired messages within Unicode limits', function (
    InsightTypeEnum $type,
    ?string $category,
    ?InsightHistoryStateEnum $state,
): void {
    $candidate = messageCandidateFixture($type, $category, historyState: $state);
    $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
    $useCase = messageCompositionUseCase();
    $titles = [];

    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = $useCase->execute(1, $candidate, $date);
        $titles[] = $message->title;
        $template = array_values(array_filter($templates, static fn (InsightMessageTemplateOutput $template): bool => $template->title === $message->title))[0];
        $categoryLabel = match ($category) {
            'food' => 'Alimentação', 'health' => 'Saúde', 'subscriptions' => 'Assinaturas', 'other' => 'Outros', default => '',
        };
        $parameters = ['{category}' => $categoryLabel, '{percent}' => '60', '{day}' => '11'];
        $regular = strtr($template->description, $parameters);
        $short = strtr($template->shortDescription, $parameters);

        expect(mb_strlen($message->title, 'UTF-8'))->toBeLessThanOrEqual(32)
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(110)
            ->and(str_contains($message->description, '{'))->toBeFalse()
            ->and(in_array($message->description, [$regular, $short], true))->toBeTrue();
    }

    expect(count(array_unique($titles)))->toBe(4);
})->with([
    [InsightTypeEnum::CategoryConcentration, 'food', null],
    [InsightTypeEnum::CategoryConcentration, 'health', null],
    [InsightTypeEnum::CategoryConcentration, 'subscriptions', null],
    [InsightTypeEnum::ExpenseConcentration, 'other', null],
    [InsightTypeEnum::RegisteredAmountIncrease, null, null],
    [InsightTypeEnum::RegisteredAmountDecrease, null, null],
    [InsightTypeEnum::CategoryLeadStreak, 'food', null],
    [InsightTypeEnum::CategoryLeadStreak, 'health', null],
    [InsightTypeEnum::FirstExpense, null, null],
    [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::CurrentExpenses],
    [InsightTypeEnum::InsufficientHistory, null, InsightHistoryStateEnum::NoCurrentExpenses],
    [InsightTypeEnum::CategoryReview, 'other', null],
]);

it('recalculates the percentage without changing the chosen variant during the day', function (): void {
    $useCase = messageCompositionUseCase();
    $before = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'food', '3850'), '2026-10-12');
    $after = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'food', '4200'), '2026-10-12');

    expect($before->title)->toBe($after->title)
        ->and(str_contains($before->description, '39%'))->toBeTrue()
        ->and(str_contains($after->description, '42%'))->toBeTrue()
        ->and(str_replace('39%', '42%', $before->description))->toBe($after->description);
});

it('preserves all approved recurring leadership messages across explicit positive accounts', function (int $userId): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::CategoryLeadStreak, 'food', to: '2026-10-12');
    $useCase = messageCompositionUseCase();
    $approvedMessages = [
        'O pódio virou endereço' => 'Alimentação lidera o registrado neste mês e liderou os dois anteriores.',
        'O ranking entrou no replay' => 'Alimentação liderou os dois meses anteriores e segue líder no registrado do mês.',
        'O primeiro lugar criou raízes' => 'Alimentação segue líder nos registros: neste mês e nos dois anteriores.',
        'Mudou o mês, não o pódio' => 'Alimentação lidera os registros deste mês, como nos dois anteriores.',
    ];
    $visitedTitles = [];

    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = $useCase->execute($userId, $candidate, $date);
        $repeated = $useCase->execute($userId, $candidate, $date);
        $visitedTitles[] = $message->title;

        expect($message->title)->toBeIn(array_keys($approvedMessages))
            ->and($message->description)->toBe($approvedMessages[$message->title])
            ->and($message)->toEqual($repeated)
            ->and(str_contains($message->description, '{'))->toBeFalse()
            ->and(mb_strlen($message->title, 'UTF-8'))->toBeLessThanOrEqual(32)
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(110);
    }

    expect($visitedTitles)->toEqualCanonicalizing(array_keys($approvedMessages));
})->with([
    'account 1' => 1,
    'account 2' => 2,
    'account 3' => 3,
    'account 4' => 4,
    'account 15' => 15,
    'account 1500' => 1500,
]);

it('keeps the variant when the comparison end day changes within the month', function (): void {
    $useCase = messageCompositionUseCase();
    $first = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease), '2026-10-20');
    $second = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, to: '2026-10-19'), '2026-10-20');

    expect($first->title)->toBe($second->title)
        ->and(str_replace('11', '19', $first->description))->toBe($second->description);
});

it('uses the complete short alternative for huge comparison percentages without truncation', function (): void {
    $useCase = messageCompositionUseCase();
    $candidate = messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, numerator: str_repeat('9', 100));
    $templates = (new GetInsightMessageTemplatesUseCase)->execute($candidate);
    $titles = [];

    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $message = $useCase->execute(1, $candidate, $date);
        $titles[] = $message->title;
        $template = array_values(array_filter($templates, static fn (InsightMessageTemplateOutput $template): bool => $template->title === $message->title))[0];

        expect($message->description)->toBe(strtr($template->shortDescription, ['{day}' => '11']))
            ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(110)
            ->and(str_contains($message->description, 'mês passado'))->toBeTrue();
    }

    expect(count(array_unique($titles)))->toBe(4);
});

it('uses different contextual history sets without claiming a first expense for existing history', function (): void {
    $useCase = messageCompositionUseCase();
    $old = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::InsufficientHistory, historyState: InsightHistoryStateEnum::NoCurrentExpenses), '2026-10-12');
    $current = $useCase->execute(1, messageCandidateFixture(InsightTypeEnum::InsufficientHistory, historyState: InsightHistoryStateEnum::CurrentExpenses), '2026-10-12');

    expect(str_contains($old->description, 'primeira'))->toBeFalse()
        ->and(str_contains($current->description, 'primeira'))->toBeFalse()
        ->and($old->title === $current->title)->toBeFalse();
});

it('rejects unsupported category labels rather than inventing editorial content', function (): void {
    messageCompositionUseCase()->execute(1, messageCandidateFixture(InsightTypeEnum::CategoryConcentration, 'unknown'), '2026-10-12');
})->throws(InsightMessageCompositionException::class);

it('fails explicitly when even the complete alternative exceeds the character budget', function (): void {
    messageCompositionUseCase()->execute(1,
        messageCandidateFixture(InsightTypeEnum::ExpenseConcentration, 'food', str_repeat('9', 100)), '2026-10-12');
})->throws(InsightMessageCompositionException::class);

it('measures the Unicode character budget instead of UTF-8 bytes', function (): void {
    $percent = str_repeat('9', 39);
    $candidate = messageCandidateFixture(InsightTypeEnum::RegisteredAmountIncrease, numerator: $percent, denominator: '100');
    $useCase = messageCompositionUseCase();
    $messages = [];

    foreach (['2026-10-12', '2026-10-13', '2026-10-14', '2026-10-15'] as $date) {
        $current = $useCase->execute(1, $candidate, $date);

        if ($current->title === 'Os números subiram no palco') {
            $messages[] = $current;
        }
    }

    expect($messages)->toHaveCount(1);
    $message = $messages[0];
    expect($message->description)->toBe("De 1 a 11: valor registrado {$percent}% maior que nos mesmos dias do mês passado.");
    expect(strlen($message->description))->toBeGreaterThan(110)
        ->and(mb_strlen($message->description, 'UTF-8'))->toBeLessThanOrEqual(110);
});

it('uses all approved neutral category labels without sensitive category humor', function (string $category, string $label): void {
    $candidate = messageCandidateFixture(InsightTypeEnum::CategoryConcentration, $category);
    $message = messageCompositionUseCase()->execute(1, $candidate, '2026-10-12');

    expect(str_contains($message->description, $label))->toBeTrue()
        ->and(str_contains($message->description, '60%'))->toBeTrue()
        ->and(str_contains($message->description, 'fome'))->toBeFalse();
})->with([
    ['health', 'Saúde'], ['housing', 'Moradia'], ['leisure', 'Lazer'],
    ['shopping', 'Compras'], ['services', 'Serviços'], ['transport', 'Transporte'],
    ['education', 'Educação'], ['subscriptions', 'Assinaturas'],
]);

it('starts another predictable cycle after a month and eligible set transition', function (): void {
    $useCase = messageCompositionUseCase();
    $october = messageCandidateFixture(InsightTypeEnum::FirstExpense);
    $november = new InsightCandidateValueObject(
        type: InsightTypeEnum::InsufficientHistory,
        analysisPeriod: DatePeriodValueObject::fromDates('2026-11-01', '2026-11-01'),
        historyState: InsightHistoryStateEnum::NoCurrentExpenses,
    );
    $useCase->execute(1, $october, '2026-10-31');
    $titles = [];

    foreach (['2026-11-01', '2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05'] as $date) {
        $message = $useCase->execute(1, $november, $date);
        $titles[] = $message->title;
        expect(str_contains($message->description, 'primeira'))->toBeFalse();
    }

    expect(count(array_unique(array_slice($titles, 0, 4))))->toBe(4)
        ->and($titles[4])->toBe($titles[0]);
});
