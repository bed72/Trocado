<?php

declare(strict_types=1);

namespace App\Authentication\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class SignInRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:access-tokens'],
            'data' => ['required', 'array:type,attributes'],
            'data.attributes.email' => ['required', 'string'],
            'data.attributes.password' => ['required', 'string'],
            'data.attributes' => ['required', 'array:email,password'],
        ];
    }
}
