<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidAmountException;
use App\Core\Domain\ValueObjects\AmountValueObject;

it('preserves canonical nonnegative amount strings including arbitrary precision', function (string $rawAmount): void {
    $amount = AmountValueObject::fromAmount($rawAmount);

    expect($amount->amount())->toBe($rawAmount)
        ->and($amount->isZero())->toBe($rawAmount === '0');
})->with(['0', '1', '123456', '12000000000000000000', '999999999999999999999999999999999999999999']);

it('rejects malformed or noncanonical monetary values', function (string $rawAmount): void {
    AmountValueObject::fromAmount($rawAmount);
})->with(['', ' ', '-1', '-0', '+1', '00', '001', '1.00', '1,000', '1e3', ' 1', '1 ', "1\n", "1\0", 'NaN'])
    ->throws(InvalidAmountException::class);

it('adds amounts exactly beyond native integers without mutating operands', function (): void {
    $amount = AmountValueObject::fromAmount('4000000000000000000');
    $zero = AmountValueObject::fromAmount('0');

    expect($amount->plus($amount)->plus($amount)->amount())->toBe('12000000000000000000')
        ->and($amount->plus($zero)->amount())->toBe('4000000000000000000')
        ->and($zero->plus($zero)->amount())->toBe('0')
        ->and($amount->amount())->toBe('4000000000000000000')
        ->and($zero->amount())->toBe('0');
});

it('compares exact numeric totals rather than their lexical or floating point order', function (string $left, string $right, int $comparison): void {
    $amount = AmountValueObject::fromAmount($left);
    $other = AmountValueObject::fromAmount($right);

    expect($amount->compareTo($other))->toBe($comparison)
        ->and($other->compareTo($amount))->toBe(-$comparison);
})->with([
    ['10000', '900', 1],
    ['0', '1', -1],
    ['12000000000000000000', '12000000000000000000', 0],
    ['12000000000000000001', '12000000000000000000', 1],
]);
