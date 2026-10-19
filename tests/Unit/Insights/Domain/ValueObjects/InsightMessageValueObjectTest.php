<?php

declare(strict_types=1);

use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightMessageValueObject;

it('counts the complete pair including the separator by extended graphemes', function (string $cluster): void {
    $message = new InsightMessageValueObject(str_repeat($cluster, 24), str_repeat($cluster, 55));
    expect(grapheme_strlen($message->title.' '.$message->description))->toBe(80);
    expect(fn () => new InsightMessageValueObject(str_repeat($cluster, 24), str_repeat($cluster, 56)))
        ->toThrow(InvalidInsightAnalysisException::class);
    expect(fn () => new InsightMessageValueObject(str_repeat($cluster, 25), 'Curto.'))
        ->toThrow(InvalidInsightAnalysisException::class);
})->with(['letter' => 'Á', 'combining accent' => "a\u{0301}", 'skin tone' => '👍🏽', 'joined emoji' => '👩🏽‍💻']);

it('normalizes whitespace before counting without discounting punctuation or internal spaces', function (): void {
    $message = new InsightMessageValueObject(" \nEm\t foco ", " Registro\u{00A0} feito. ");
    expect($message->title)->toBe('Em foco')->and($message->description)->toBe('Registro feito.')
        ->and(grapheme_strlen($message->title.' '.$message->description))->toBe(23);
});

it('rejects empty and invalid Unicode pairs explicitly', function (string $title, string $description): void {
    expect(fn () => new InsightMessageValueObject($title, $description))->toThrow(InvalidInsightAnalysisException::class);
})->with([[' ', 'Descrição'], ['Título', ''], ["\xFF", 'Descrição']]);

it('ignores cosmetic differences but preserves factual letters numbers and dates', function (): void {
    $first = new InsightMessageValueObject('Em foco', 'Saúde: jan/2026 até 12.');
    $cosmetic = new InsightMessageValueObject('EM FOCO ❤️', "SAU\u{0301}DE · jan/2026 até 12!");
    expect($first->comparisonKey())->toBe($cosmetic->comparisonKey());
    foreach (['Saúde: jan/2026 até 13.', 'Saúde: jan/2025 até 12.', 'Pets: jan/2026 até 12.'] as $description) {
        expect((new InsightMessageValueObject('Em foco', $description))->comparisonKey())->not->toBe($first->comparisonKey());
    }
});
