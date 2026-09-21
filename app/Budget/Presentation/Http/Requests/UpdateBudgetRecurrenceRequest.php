<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class UpdateBudgetRecurrenceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data' => ['required', 'array:type,id,attributes'],
            'data.type' => ['required', 'in:budget-recurrences'],
            'data.attributes' => ['required', 'array:amount,duration_in_days', 'min:1'],
            'data.id' => ['required', 'string', Rule::in(values: [(string) $this->route(param: 'recurrence')])],
            'data.attributes.amount' => ['sometimes', 'required', 'integer:strict', 'min:0', 'max:9223372036854775807'],
            'data.attributes.duration_in_days' => ['sometimes', 'required', 'integer:strict', 'min:1', 'max:4294967295'],
        ];
    }
}
