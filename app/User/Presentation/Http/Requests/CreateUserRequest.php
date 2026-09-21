<?php

declare(strict_types=1);

namespace App\User\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:users'],
            'data' => ['required', 'array:type,attributes'],
            'data.attributes' => ['required', 'array:name,email'],
            'data.attributes.name' => ['required', 'string', 'max:255'],
            'data.attributes.email' => ['required', 'string', 'email', 'max:255'],
        ];
    }
}
