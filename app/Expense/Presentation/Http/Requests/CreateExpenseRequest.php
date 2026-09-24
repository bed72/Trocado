<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Requests;

use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class CreateExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'data.type' => ['required', 'in:expenses'],
            'data' => ['required', 'array:type,attributes'],
            'data.attributes.description' => ['sometimes', 'nullable', 'string', 'max:64'],
            'data.attributes.occurred_on' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'data.attributes' => ['required', 'array:amount,occurred_on,category,description'],
            'data.attributes.amount' => ['required', 'integer:strict', 'min:1', 'max:9223372036854775807'],
            'data.attributes.category' => ['sometimes', 'required', 'string', 'max:32', Rule::enum(type: ExpenseCategoryEnum::class)],
        ];
    }
}
