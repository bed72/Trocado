<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidCentsException;
use App\Core\Domain\ValueObjects\CentsValueObject;

it('preserves canonical nonnegative cent strings including arbitrary precision', function (string $cents): void {
    $amount = CentsValueObject::fromCents($cents);

    expect($amount->cents())->toBe($cents)
        ->and($amount->isZero())->toBe($cents === '0');
})->with(['0', '1', '123456', '12000000000000000000', '999999999999999999999999999999999999999999']);

it('rejects malformed or noncanonical monetary values', function (string $cents): void {
    CentsValueObject::fromCents($cents);
})->with(['', ' ', '-1', '-0', '+1', '00', '001', '1.00', '1,000', '1e3', ' 1', '1 ', "1\n", "1\0", 'NaN'])
    ->throws(InvalidCentsException::class);

it('adds cents exactly beyond native integers without mutating operands', function (): void {
    $amount = CentsValueObject::fromCents('4000000000000000000');
    $zero = CentsValueObject::fromCents('0');

    expect($amount->plus($amount)->plus($amount)->cents())->toBe('12000000000000000000')
        ->and($amount->plus($zero)->cents())->toBe('4000000000000000000')
        ->and($zero->plus($zero)->cents())->toBe('0')
        ->and($amount->cents())->toBe('4000000000000000000')
        ->and($zero->cents())->toBe('0');
});

it('compares exact numeric totals rather than their lexical or floating point order', function (string $left, string $right, int $comparison): void {
    $amount = CentsValueObject::fromCents($left);
    $other = CentsValueObject::fromCents($right);

    expect($amount->compareTo($other))->toBe($comparison)
        ->and($other->compareTo($amount))->toBe(-$comparison);
})->with([
    ['10000', '900', 1],
    ['0', '1', -1],
    ['12000000000000000000', '12000000000000000000', 0],
    ['12000000000000000001', '12000000000000000000', 1],
]);
