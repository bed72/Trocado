<?php

declare(strict_types=1);

use App\Budget\Domain\Exceptions\InvalidMoneyAmountException;
use App\Budget\Domain\ValueObjects\MoneyValueObject;

it('preserves cents and compares amounts by value', function (): void {
    $zero = MoneyValueObject::fromCents(cents: 0);
    $amount = MoneyValueObject::fromCents(cents: 12500);

    expect($zero->cents())->toBe(0)
        ->and($amount->cents())->toBe(12500)
        ->and($amount->equals(MoneyValueObject::fromCents(cents: 12500)))->toBeTrue()
        ->and($amount->equals($zero))->toBeFalse();
});

it('rejects negative cents', function (): void {
    MoneyValueObject::fromCents(cents: -1);
})->throws(InvalidMoneyAmountException::class, 'O valor em centavos não pode ser negativo.');
