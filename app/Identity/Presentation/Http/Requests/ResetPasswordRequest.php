<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Requests;

use App\Identity\Presentation\Http\Rules\PasswordRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

use function in_array;
use function is_array;

final class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function validationData(): array
    {
        return $this->json()->all();
    }

    public function rules(): array
    {
        return [
            'data' => ['required', 'array:type,attributes'],
            'data.attributes.token' => ['bail', 'required', 'string'],
            'data.type' => ['bail', 'required', 'string', 'in:password-resets'],
            'data.attributes.password' => ['bail', 'required', 'string', new PasswordRule],
            'data.attributes.email' => ['bail', 'required', 'string', 'email:filter', 'max:255'],
            'data.attributes' => ['required', 'array:email,token,password,password_confirmation'],
            'data.attributes.password_confirmation' => ['bail', 'required', 'string', 'same:data.attributes.password'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            foreach ([
                '' => ['data'],
                'data' => ['type', 'attributes'],
                'data.attributes' => ['email', 'token', 'password', 'password_confirmation'],
            ] as $path => $allowed) {
                $members = $path === '' ? $this->json()->all() : $this->json($path);

                if (! is_array($members)) {
                    continue;
                }

                foreach (array_keys($members) as $member) {
                    if (! in_array($member, $allowed, true)) {
                        $field = $path === '' ? (string) $member : $path.'.'.$member;
                        $validator->errors()->add($field, 'O membro informado não é permitido.');
                    }
                }
            }
        }];
    }
}
