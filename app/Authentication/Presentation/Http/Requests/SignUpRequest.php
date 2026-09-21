<?php

declare(strict_types=1);

namespace App\Authentication\Presentation\Http\Requests;

use App\Authentication\Domain\Exceptions\InvalidPasswordException;
use App\Authentication\Domain\ValueObjects\PasswordValueObject;
use Closure;
use Illuminate\Foundation\Http\FormRequest;

final class SignUpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:sign-ups'],
            'data' => ['required', 'array:type,attributes'],
            'data.attributes.name' => ['required', 'string', 'max:255'],
            'data.attributes.email' => ['required', 'string', 'email', 'max:255'],
            'data.attributes' => ['required', 'array:name,email,password,password_confirmation'],
            'data.attributes.password' => [
                'bail',
                'required',
                'string',
                static function (string $attribute, mixed $value, Closure $fail): void {
                    try {
                        PasswordValueObject::fromString(value: $value);
                    } catch (InvalidPasswordException $exception) {
                        $fail($exception->getMessage());
                    }
                },
            ],
            'data.attributes.password_confirmation' => [
                'required',
                'string',
                'same:data.attributes.password',
            ],
        ];
    }
}
