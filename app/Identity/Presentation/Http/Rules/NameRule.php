<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Rules;

use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

use function is_string;

final class NameRule implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        try {
            NameValueObject::fromString(value: $value);
        } catch (InvalidNameException $exception) {
            $fail($exception->getMessage());
        }
    }
}
