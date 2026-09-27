<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

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
            'data.attributes' => ['required', 'array:name', 'min:1'],
            'data.attributes.name' => [
                'bail',
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
            'data.id' => ['required', 'string', Rule::in(values: [(string) $this->route(param: 'user')])],
        ];
    }
}
