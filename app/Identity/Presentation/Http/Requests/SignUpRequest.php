<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use App\Identity\Presentation\Http\Rules\NameRule;
use App\Identity\Presentation\Http\Rules\PasswordRule;
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
            'data.attributes.name' => [
                'bail',
                'required',
                'string',
                new NameRule,
            ],
            'data.attributes.email' => ['required', 'string', 'email', 'max:255'],
            'data.attributes.avatar' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'data.attributes' => ['required', 'array:name,email,password,password_confirmation,avatar'],
            'data.attributes.password' => [
                'bail',
                'required',
                'string',
                new PasswordRule,
            ],
            'data.attributes.password_confirmation' => [
                'required',
                'string',
                'same:data.attributes.password',
            ],
        ];
    }
}
