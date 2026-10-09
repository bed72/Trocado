<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidCentsException;
use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\CentsValueObject;

it('keeps sums differences and comparisons exact above native integer limits', function (): void {
    $amount = CentsValueObject::fromCents('18446744073709551614');
    $other = CentsValueObject::fromCents('9223372036854775807');

    expect($amount->plus($other)->cents())->toBe('27670116110564327421')
        ->and($amount->absoluteDifference($other)->cents())->toBe('9223372036854775807')
        ->and($other->absoluteDifference($amount)->cents())->toBe('9223372036854775807')
        ->and($amount->compareTo($other))->toBe(1)
        ->and($other->compareTo($amount))->toBe(-1);
});

it('rejects noncanonical noninteger or negative cents', function (string $amount): void {
    CentsValueObject::fromCents($amount);
})->with(['-1', '1.5', '1e3', '01', '+1', ' 1 ', '', '1\n'])
    ->throws(InvalidCentsException::class);

it('evaluates thresholds before rounding and rounds only on request', function (): void {
    $ratio = CentsValueObject::fromCents('295')->shareOf(CentsValueObject::fromCents('1000'));

    expect($ratio->isAtLeastPercent(30))->toBeFalse()
        ->and($ratio->roundedPercent())->toBe('30')
        ->and($ratio->numerator->cents())->toBe('295')
        ->and($ratio->denominator->cents())->toBe('1000');
});

it('rounds half up without overflowing large percentages', function (string $numerator, string $denominator, string $expected): void {
    $ratio = CentsValueObject::fromCents($numerator)->shareOf(CentsValueObject::fromCents($denominator));

    expect($ratio->roundedPercent())->toBe($expected);
})->with([
    ['294', '1000', '29'],
    ['295', '1000', '30'],
    ['305', '1000', '31'],
    ['0', '1000', '0'],
    ['9223372036854775807', '1', '922337203685477580700'],
]);

it('rejects zero denominators', function (): void {
    CentsValueObject::fromCents('100')->shareOf(CentsValueObject::fromCents('0'));
})->throws(InvalidRatioException::class);
