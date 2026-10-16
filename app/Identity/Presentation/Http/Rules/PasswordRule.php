<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Rules;

use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Domain\ValueObjects\PasswordValueObject;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use SensitiveParameter;

use function is_string;

final class PasswordRule implements ValidationRule
{
    public function validate(string $attribute, #[SensitiveParameter] mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        try {
            PasswordValueObject::fromString(value: $value);
        } catch (InvalidPasswordException $exception) {
            $fail($exception->getMessage());
        }
    }
}
