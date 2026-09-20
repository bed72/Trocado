<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class UpdateBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:budgets'],
            'data' => ['required', 'array:type,id,attributes'],
            'data.attributes.end_date' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'data.attributes' => ['required', 'array:amount,start_date,end_date', 'min:1'],
            'data.attributes.start_date' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'data.id' => ['required', 'string', Rule::in(values: [(string) $this->route(param: 'budget')])],
            'data.attributes.amount' => ['sometimes', 'required', 'integer:strict', 'min:0', 'max:9223372036854775807'],
        ];
    }
}
