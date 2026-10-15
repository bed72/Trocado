<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Closure;
use Illuminate\Foundation\Http\FormRequest;

final class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:users'],
            'data' => ['required', 'array:type,id,attributes'],
            'data.attributes' => ['required', 'array:name,avatar', 'min:1'],
            'data.attributes.avatar' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'data.attributes.name' => [
                'bail',
                'sometimes',
                'required',
                'string',
                static function (string $attribute, mixed $value, Closure $fail): void {
                    try {
                        NameValueObject::fromString(value: $value);
                    } catch (InvalidNameException $exception) {
                        $fail($exception->getMessage());
                    }
                },
            ],
            'data.attributes.email' => ['prohibited'],
            // TODO nao pode ser algo que fazemos uma vez e reaproveitamos em outros lugares?
            'data.id' => ['bail', 'required', 'string', function (string $attribute, mixed $value, Closure $fail): void {
                try {
                    $id = UuidValueObject::fromString($value);
                    if (! $id->equals(UuidValueObject::fromString($this->route('user')))) {
                        $fail('O identificador deve corresponder ao recurso solicitado.');
                    }
                } catch (InvalidUuidException) {
                    $fail('O identificador deve ser um UUIDv7 válido.');
                }
            }],
        ];
    }
}
