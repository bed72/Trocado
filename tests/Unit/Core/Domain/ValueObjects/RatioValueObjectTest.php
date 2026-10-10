<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\RatioValueObject;

it('preserves the original numerator and denominator without reducing the facts', function (): void {
    $numerator = AmountValueObject::fromAmount('5000');
    $denominator = AmountValueObject::fromAmount('25000');
    $ratio = RatioValueObject::fromAmounts($numerator, $denominator);

    expect($ratio->numerator)->toBe($numerator)
        ->and($ratio->denominator)->toBe($denominator)
        ->and($ratio->isAtLeastPercent(20))->toBeTrue()
        ->and($ratio->isAtLeastPercent(21))->toBeFalse();
});

it('supports zero participation and increases above one hundred percent', function (string $numerator, string $denominator, int $threshold, bool $eligible): void {
    $ratio = RatioValueObject::fromAmounts(
        AmountValueObject::fromAmount($numerator),
        AmountValueObject::fromAmount($denominator),
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
    $ratio = RatioValueObject::fromAmounts(
        AmountValueObject::fromAmount($numerator),
        AmountValueObject::fromAmount('25000000000000000000'),
    );

    expect($ratio->isAtLeastPercent(20))->toBe($eligible);
})->with([
    ['4999999999999999999', false],
    ['5000000000000000000', true],
    ['5000000000000000001', true],
]);

it('rejects negative percentage thresholds', function (): void {
    $ratio = RatioValueObject::fromAmounts(
        AmountValueObject::fromAmount('5000'),
        AmountValueObject::fromAmount('25000'),
    );

    $ratio->isAtLeastPercent(-1);
})->throws(InvalidRatioException::class, 'O percentual mínimo não pode ser negativo.');

it('rejects undefined ratios even when the numerator is also zero', function (): void {
    RatioValueObject::fromAmounts(
        AmountValueObject::fromAmount('0'),
        AmountValueObject::fromAmount('0'),
    );
})->throws(InvalidRatioException::class, 'Uma participação exige denominador positivo.');

it('rejects negative precision without changing the exact ratio', function (): void {
    AmountValueObject::fromAmount('1')->shareOf(AmountValueObject::fromAmount('3'))->roundedPercent(decimalPlaces: -1);
})->throws(InvalidRatioException::class);

it('rounds the same exact ratio independently for each requested precision', function (): void {
    $ratio = AmountValueObject::fromAmount('16665')->shareOf(AmountValueObject::fromAmount('100000'));

    expect($ratio->roundedPercent())->toBe('17')
        ->and($ratio->roundedPercent(decimalPlaces: 2))->toBe('16.67')
        ->and($ratio->roundedPercent(decimalPlaces: 3))->toBe('16.665')
        ->and($ratio->isAtLeastPercent(17))->toBeFalse();
});
