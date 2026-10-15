<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Requests;

use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

final class CreateNotificationRequest extends FormRequest
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
            'data.type' => ['bail', 'required', 'string', 'in:push-registrations'],
            'data.attributes' => ['required', 'array:installation_id,platform,registration_kind,registration_identifier'],
            // TODO reaproveitar validador de UUID
            'data.attributes.installation_id' => ['bail', 'required', 'string', function (string $attribute, mixed $value, Closure $fail): void {
                if (! NotificationValueObject::isUuid($value)) {
                    $fail('O identificador da instalação deve ser um UUIDv7 válido.');
                }
            }],
            'data.attributes.platform' => ['bail', 'required', 'string', Rule::enum(NotificationPlatformEnum::class)],
            'data.attributes.registration_kind' => ['bail', 'required', 'string', 'in:token'],
            'data.attributes.registration_identifier' => ['bail', 'required', 'string', function (string $attribute, mixed $value, Closure $fail): void {
                if (! NotificationValueObject::isIdentifier($value)) {
                    $fail('O destino deve conter de 1 a 4096 bytes ASCII sem espaços ou controles.');
                }
            }],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            foreach ([
                '' => ['data'],
                'data' => ['type', 'attributes'],
                'data.attributes' => ['installation_id', 'platform', 'registration_kind', 'registration_identifier'],
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
