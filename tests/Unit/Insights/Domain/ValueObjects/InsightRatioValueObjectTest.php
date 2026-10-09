<?php

declare(strict_types=1);

use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use App\Insights\Domain\ValueObjects\InsightAmountValueObject;
use App\Insights\Domain\ValueObjects\InsightRatioValueObject;

it('preserves the original numerator and denominator without reducing the facts', function (): void {
    $numerator = InsightAmountValueObject::fromCents('5000');
    $denominator = InsightAmountValueObject::fromCents('25000');
    $ratio = InsightRatioValueObject::fromAmounts($numerator, $denominator);

    expect($ratio->numerator)->toBe($numerator)
        ->and($ratio->denominator)->toBe($denominator)
        ->and($ratio->isAtLeastPercent(20))->toBeTrue()
        ->and($ratio->isAtLeastPercent(21))->toBeFalse();
});

it('supports zero participation and increases above one hundred percent', function (string $numerator, string $denominator, int $threshold, bool $eligible): void {
    $ratio = InsightRatioValueObject::fromAmounts(
        InsightAmountValueObject::fromCents($numerator),
        InsightAmountValueObject::fromCents($denominator),
    );

    expect($ratio->isAtLeastPercent($threshold))->toBe($eligible);
})->with([
    ['0', '10000', 0, true],
    ['0', '10000', 1, false],
    ['10000', '10000', 100, true],
    ['25000', '10000', 250, true],
    ['25000', '10000', 251, false],
]);

it('compares percentage products exactly beyond native integer limits', function (string $numerator, bool $eligible): void {
    $ratio = InsightRatioValueObject::fromAmounts(
        InsightAmountValueObject::fromCents($numerator),
        InsightAmountValueObject::fromCents('25000000000000000000'),
    );

    expect($ratio->isAtLeastPercent(20))->toBe($eligible);
})->with([
    ['4999999999999999999', false],
    ['5000000000000000000', true],
    ['5000000000000000001', true],
]);

it('rejects negative percentage thresholds', function (): void {
    $ratio = InsightRatioValueObject::fromAmounts(
        InsightAmountValueObject::fromCents('5000'),
        InsightAmountValueObject::fromCents('25000'),
    );

    $ratio->isAtLeastPercent(-1);
})->throws(InvalidInsightAnalysisException::class, 'O percentual mínimo não pode ser negativo.');

it('rejects undefined ratios even when the numerator is also zero', function (): void {
    InsightRatioValueObject::fromAmounts(
        InsightAmountValueObject::fromCents('0'),
        InsightAmountValueObject::fromCents('0'),
    );
})->throws(InvalidInsightAnalysisException::class, 'Uma participação exige denominador positivo.');
