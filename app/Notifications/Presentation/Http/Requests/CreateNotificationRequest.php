<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Requests;

use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Presentation\Http\Rules\NotificationIdentifierRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

use function in_array;
use function is_array;

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
            'data.attributes.registration_kind' => ['bail', 'required', 'string', 'in:token'],
            'data.attributes.installation_id' => ['bail', 'required', 'string', 'uuid', 'uuid:7'],
            'data.attributes.platform' => ['bail', 'required', 'string', Rule::enum(NotificationPlatformEnum::class)],
            'data.attributes.registration_identifier' => ['bail', 'required', 'string', new NotificationIdentifierRule],
            'data.attributes' => ['required', 'array:installation_id,platform,registration_kind,registration_identifier'],
        ];
    }

    public function messages(): array
    {
        return [
            'data.attributes.installation_id.uuid' => 'O identificador da instalação deve ser um UUIDv7 válido.',
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
