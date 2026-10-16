<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Rules;

use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use SensitiveParameter;

use function is_string;

final class NotificationIdentifierRule implements ValidationRule
{
    public function validate(string $attribute, #[SensitiveParameter] mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        if (! NotificationValueObject::isIdentifier($value)) {
            $fail('O destino deve conter de 1 a 4096 bytes ASCII sem espaços ou controles.');
        }
    }
}
