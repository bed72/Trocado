<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Rules;

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

use function is_string;

final readonly class MatchesResourceIdRule implements ValidationRule
{
    public function __construct(private string $resourceId) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        try {
            $id = UuidValueObject::fromString($value);

            if (! $id->equals(UuidValueObject::fromString($this->resourceId))) {
                $fail('O identificador deve corresponder ao recurso solicitado.');
            }
        } catch (InvalidUuidException) {
            $fail('O identificador deve ser um UUIDv7 válido.');
        }
    }
}
