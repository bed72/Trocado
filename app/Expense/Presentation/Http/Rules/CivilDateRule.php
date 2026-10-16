<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Rules;

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

use function is_string;

final class CivilDateRule implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        try {
            DatePeriodValueObject::fromDates($value, $value);
        } catch (InvalidDatePeriodException) {
            $fail('Informe uma data civil válida entre 0001-01-01 e 9999-12-31.');
        }
    }
}
