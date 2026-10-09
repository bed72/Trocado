<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\CentsValueObject;
use App\Core\Domain\ValueObjects\RatioValueObject;

it('preserves the original numerator and denominator without reducing the facts', function (): void {
    $numerator = CentsValueObject::fromCents('5000');
    $denominator = CentsValueObject::fromCents('25000');
    $ratio = RatioValueObject::fromCents($numerator, $denominator);

    expect($ratio->numerator)->toBe($numerator)
        ->and($ratio->denominator)->toBe($denominator)
        ->and($ratio->isAtLeastPercent(20))->toBeTrue()
        ->and($ratio->isAtLeastPercent(21))->toBeFalse();
});

it('supports zero participation and increases above one hundred percent', function (string $numerator, string $denominator, int $threshold, bool $eligible): void {
    $ratio = RatioValueObject::fromCents(
        CentsValueObject::fromCents($numerator),
        CentsValueObject::fromCents($denominator),
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
    $ratio = RatioValueObject::fromCents(
        CentsValueObject::fromCents($numerator),
        CentsValueObject::fromCents('25000000000000000000'),
    );

    expect($ratio->isAtLeastPercent(20))->toBe($eligible);
})->with([
    ['4999999999999999999', false],
    ['5000000000000000000', true],
    ['5000000000000000001', true],
]);

it('rejects negative percentage thresholds', function (): void {
    $ratio = RatioValueObject::fromCents(
        CentsValueObject::fromCents('5000'),
        CentsValueObject::fromCents('25000'),
    );

    $ratio->isAtLeastPercent(-1);
})->throws(InvalidRatioException::class, 'O percentual mínimo não pode ser negativo.');

it('rejects undefined ratios even when the numerator is also zero', function (): void {
    RatioValueObject::fromCents(
        CentsValueObject::fromCents('0'),
        CentsValueObject::fromCents('0'),
    );
})->throws(InvalidRatioException::class, 'Uma participação exige denominador positivo.');

it('rejects negative precision without changing the exact ratio', function (): void {
    CentsValueObject::fromCents('1')->shareOf(CentsValueObject::fromCents('3'))->roundedPercent(decimalPlaces: -1);
})->throws(InvalidRatioException::class);

it('rounds the same exact ratio independently for each requested precision', function (): void {
    $ratio = CentsValueObject::fromCents('16665')->shareOf(CentsValueObject::fromCents('100000'));

    expect($ratio->roundedPercent())->toBe('17')
        ->and($ratio->roundedPercent(decimalPlaces: 2))->toBe('16.67')
        ->and($ratio->roundedPercent(decimalPlaces: 3))->toBe('16.665')
        ->and($ratio->isAtLeastPercent(17))->toBeFalse();
});
