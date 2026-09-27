<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class ResendEmailVerificationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data' => ['required', 'array:type,attributes'],
            'data.attributes' => ['required', 'array:email'],
            'data.type' => ['required', 'in:email-verifications'],
            'data.attributes.email' => ['required', 'string', 'email', 'max:255'],
        ];
    }
}
