<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidRatioException;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\RatioValueObject;

it('rounds exact shares only once to two percentage decimal places', function (string $amount, string $total, string $percentage): void {
    $share = RatioValueObject::fromShare(
        amount: AmountValueObject::fromAmount($amount),
        total: AmountValueObject::fromAmount($total),
    );

    expect($share->roundedPercent(decimalPlaces: 2))->toBe($percentage)
        ->and($share->numerator->amount())->toBe($amount)
        ->and($share->denominator->amount())->toBe($total);
})->with([
    'sixty percent' => ['60000', '100000', '60.00'],
    'thirty percent' => ['30000', '100000', '30.00'],
    'ten percent' => ['10000', '100000', '10.00'],
    'half up tie' => ['16665', '100000', '16.67'],
    'below half up tie' => ['166649', '1000000', '16.66'],
    'above half up tie' => ['166651', '1000000', '16.67'],
    'third' => ['1', '3', '33.33'],
    'tiny share' => ['1', '1000000', '0.00'],
    'small half up tie' => ['1', '20000', '0.01'],
    'full share' => ['2500', '2500', '100.00'],
    'zero numerator' => ['0', '1', '0.00'],
    'two thirds' => ['2', '3', '66.67'],
    'large totals' => ['12000000000000000000', '20000000000000000000', '60.00'],
    'multiplication beyond native integer' => ['4000000000000000000', '8000000000000000000', '50.00'],
    'large exact tie' => ['166650000000000000000', '1000000000000000000000', '16.67'],
    'large immediately below tie' => ['166649999999999999999', '1000000000000000000000', '16.66'],
]);

it('rejects a zero denominator instead of inventing an empty result', function (string $amount): void {
    RatioValueObject::fromShare(
        total: AmountValueObject::fromAmount('0'),
        amount: AmountValueObject::fromAmount($amount),
    );
})->with(['0', '1'])->throws(InvalidRatioException::class, 'Uma participação exige denominador positivo.');

it('rejects a share above the total even beyond floating point precision', function (): void {
    RatioValueObject::fromShare(
        amount: AmountValueObject::fromAmount('12000000000000000001'),
        total: AmountValueObject::fromAmount('12000000000000000000'),
    );
})->throws(InvalidRatioException::class, 'Uma participação não pode superar o total.');

it('keeps independently rounded percentages without forcing their sum to one hundred', function (array $amounts, string $total, array $percentages): void {
    $sum = AmountValueObject::fromAmount('0');
    $shares = [];
    $denominator = AmountValueObject::fromAmount($total);

    foreach ($amounts as $rawAmount) {
        $amount = AmountValueObject::fromAmount($rawAmount);
        $sum = $sum->plus($amount);
        $shares[] = RatioValueObject::fromShare(amount: $amount, total: $denominator)->roundedPercent(decimalPlaces: 2);
    }

    expect($sum->amount())->toBe($total)
        ->and($shares)->toBe($percentages);
})->with([
    '99.99 percent' => [['1', '1', '1'], '3', ['33.33', '33.33', '33.33']],
    '100.01 percent' => [['16665', '16665', '16670', '50000'], '100000', ['16.67', '16.67', '16.67', '50.00']],
]);
