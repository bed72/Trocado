<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\AmountValueObject;

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
