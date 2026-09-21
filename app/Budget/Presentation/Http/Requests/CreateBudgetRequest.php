<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class CreateBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:budgets'],
            'data' => ['required', 'array:type,attributes'],
            'data.attributes.start_date' => ['required', 'date_format:Y-m-d'],
            'data.attributes' => ['required', 'array:amount,start_date,end_date,recurring'],
            'data.attributes.amount' => ['required', 'integer:strict', 'min:0', 'max:9223372036854775807'],
            'data.attributes.end_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:data.attributes.start_date'],
            'data.attributes.recurring' => ['sometimes', 'required', 'boolean:strict'],
        ];
    }
}
