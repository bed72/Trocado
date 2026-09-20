<?php

declare(strict_types=1);

use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('accepts zero and preserves integer cents', function (): void {
    $zero = MoneyValueObject::fromCents(cents: 0);
    $amount = MoneyValueObject::fromCents(cents: 12500);

    expect($zero->cents())->toBe(0);
    expect($amount->cents())->toBe(12500);
    expect($amount->equals(MoneyValueObject::fromCents(cents: 12500)))->toBeTrue();
    expect($amount->equals($zero))->toBeFalse();
});

it('returns new amounts from arithmetic without changing operands', function (): void {
    $amount = MoneyValueObject::fromCents(cents: 12500);
    $other = MoneyValueObject::fromCents(cents: 2500);

    expect($amount->add(other: $other)->cents())->toBe(15000);
    expect($amount->subtract(other: $other)->cents())->toBe(10000);
    expect($amount->cents())->toBe(12500);
    expect($other->cents())->toBe(2500);
});

it('rejects negative cents', function (): void {
    MoneyValueObject::fromCents(cents: -1);
})->throws(InvalidMoneyAmountException::class);

it('rejects subtraction below zero', function (): void {
    MoneyValueObject::fromCents(cents: 1)->subtract(other: MoneyValueObject::fromCents(cents: 2));
})->throws(InvalidMoneyAmountException::class);

it('rejects integer overflow when adding', function (): void {
    MoneyValueObject::fromCents(cents: PHP_INT_MAX)->add(other: MoneyValueObject::fromCents(cents: 1));
})->throws(InvalidMoneyAmountException::class);
