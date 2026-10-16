<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use App\Identity\Presentation\Http\Rules\MatchesResourceIdRule;
use App\Identity\Presentation\Http\Rules\NameRule;
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
            'data.attributes.email' => ['prohibited'],
            'data' => ['required', 'array:type,id,attributes'],
            'data.attributes' => ['required', 'array:name,avatar', 'min:1'],
            'data.attributes.avatar' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'data.attributes.name' => [
                'bail',
                'sometimes',
                'required',
                'string',
                new NameRule,
            ],
            'data.id' => ['bail', 'required', 'string', 'uuid', 'uuid:7', new MatchesResourceIdRule($this->route('user'))],
        ];
    }

    public function messages(): array
    {
        return [
            'data.id.uuid' => 'O identificador deve ser um UUIDv7 válido.',
        ];
    }
}
