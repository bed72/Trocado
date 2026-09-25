<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Requests;

use DateTimeImmutable;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Pagination\Cursor;
use Illuminate\Validation\Validator;

use function is_array;
use function is_bool;
use function is_int;
use function is_string;

final class ListExpensesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => ['prohibited'],
            'page.cursor' => ['sometimes', 'required', 'string'],
            'page' => ['sometimes', 'required', 'array:size,cursor'],
            'page.size' => ['sometimes', 'required', 'integer', 'between:1,100'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            $encoded = $this->input('page.cursor');

            if ($encoded === null || $validator->errors()->has('page.cursor')) {
                return;
            }

            $cursor = Cursor::fromEncoded($encoded);
            $values = $cursor?->toArray();

            if (! is_string($encoded) || strlen($encoded) > 1024 || ! preg_match('/^[A-Za-z0-9_-]+$/D', $encoded)
                || $cursor?->encode() !== $encoded
                || ! is_array($values)
                || array_keys($values) !== ['occurred_on', 'id', '_pointsToNextItems']
                || ! is_string($values['occurred_on'])
                || ($date = DateTimeImmutable::createFromFormat('!Y-m-d', $values['occurred_on'])) === false
                || $date->format('Y-m-d') !== $values['occurred_on']
                || ! is_int($values['id']) || $values['id'] < 1
                || ! is_bool($values['_pointsToNextItems'])) {
                $validator->errors()->add('page.cursor', 'O cursor da página é inválido.');
            }
        }];
    }
}
