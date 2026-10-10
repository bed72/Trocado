<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidAmountException;
use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\AmountValueObject;

it('keeps sums differences and comparisons exact above native integer limits', function (): void {
    $amount = AmountValueObject::fromAmount('18446744073709551614');
    $other = AmountValueObject::fromAmount('9223372036854775807');

    expect($amount->plus($other)->amount())->toBe('27670116110564327421')
        ->and($amount->absoluteDifference($other)->amount())->toBe('9223372036854775807')
        ->and($other->absoluteDifference($amount)->amount())->toBe('9223372036854775807')
        ->and($amount->compareTo($other))->toBe(1)
        ->and($other->compareTo($amount))->toBe(-1);
});

it('rejects noncanonical noninteger or negative amounts', function (string $amount): void {
    AmountValueObject::fromAmount($amount);
})->with(['-1', '1.5', '1e3', '01', '+1', ' 1 ', '', '1\n'])
    ->throws(InvalidAmountException::class);

it('evaluates thresholds before rounding and rounds only on request', function (): void {
    $ratio = AmountValueObject::fromAmount('295')->shareOf(AmountValueObject::fromAmount('1000'));

    expect($ratio->isAtLeastPercent(30))->toBeFalse()
        ->and($ratio->roundedPercent())->toBe('30')
        ->and($ratio->numerator->amount())->toBe('295')
        ->and($ratio->denominator->amount())->toBe('1000');
});

it('rounds half up without overflowing large percentages', function (string $numerator, string $denominator, string $expected): void {
    $ratio = AmountValueObject::fromAmount($numerator)->shareOf(AmountValueObject::fromAmount($denominator));

    expect($ratio->roundedPercent())->toBe($expected);
})->with([
    ['294', '1000', '29'],
    ['295', '1000', '30'],
    ['305', '1000', '31'],
    ['0', '1000', '0'],
    ['9223372036854775807', '1', '922337203685477580700'],
]);

it('rejects zero denominators', function (): void {
    AmountValueObject::fromAmount('100')->shareOf(AmountValueObject::fromAmount('0'));
})->throws(InvalidRatioException::class);
