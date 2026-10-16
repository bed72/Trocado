<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Requests;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Presentation\Http\Rules\CivilDateRule;
use App\Expense\Presentation\Http\Rules\ExpenseCategoriesRule;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

use function count;
use function is_string;
use function sprintf;

final class GetAllExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'user_id' => ['prohibited'],
            'filter.to' => $this->civilDateRules(),
            'filter.from' => $this->civilDateRules(),
            'page' => ['sometimes', 'required', 'array:size,cursor'],
            'page.cursor' => ['sometimes', 'required', 'string', 'max:4096'],
            'page.size' => ['sometimes', 'required', 'integer', 'between:1,100'],
            'filter.day' => ['sometimes', 'required', 'integer', 'between:1,31'],
            'filter.month' => ['required_with:filter.day', 'filled', 'integer', 'between:1,12'],
            'filter.category' => ['sometimes', 'required', 'string', new ExpenseCategoriesRule],
            'filter.amount_min' => ['sometimes', 'required', 'integer', 'between:0,9223372036854775807'],
            'filter.amount_max' => ['sometimes', 'required', 'integer', 'between:0,9223372036854775807'],
            'filter.year' => ['required_with:filter.month,filter.day', 'filled', 'integer', 'between:1,9999'],
            'filter' => ['sometimes', 'required', 'array:year,month,day,from,to,category,amount_min,amount_max'],
            'sort' => ['sometimes', 'required', 'string', 'regex:/\A-?(occurred_on|amount|description)(,-?(occurred_on|amount|description)){0,2}\z/D', function (string $attribute, mixed $value, Closure $fail): void {
                if (! is_string($value)) {
                    return;
                }
                $fields = array_map(static fn (string $sort): string => ltrim($sort, '-'), explode(',', $value));
                if (count(array_unique($fields)) !== count($fields)) {
                    $fail('Não repita campos de ordenação.');
                }
            }],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            if ($this->input('filter.day') !== null && ! checkdate((int) $this->input('filter.month'), (int) $this->input('filter.day'), (int) $this->input('filter.year'))) {
                $validator->errors()->add('filter.day', 'O dia informado não existe no mês e ano selecionados.');
            }
            if (($this->exists('filter.from') || $this->exists('filter.to'))
                && ($this->exists('filter.year') || $this->exists('filter.month') || $this->exists('filter.day'))) {
                $validator->errors()->add($this->exists('filter.from') ? 'filter.from' : 'filter.to', 'Não combine intervalos com ano, mês ou dia.');
            }
            if ($this->input('filter.from') !== null && $this->input('filter.to') !== null && $this->input('filter.from') > $this->input('filter.to')) {
                $validator->errors()->add('filter.to', 'O fim do período não pode anteceder o início.');
            }
            if ($this->input('filter.amount_min') !== null && $this->input('filter.amount_max') !== null
                && (int) $this->input('filter.amount_min') > (int) $this->input('filter.amount_max')) {
                $validator->errors()->add('filter.amount_max', 'O valor máximo não pode ser menor que o mínimo.');
            }
        }];
    }

    public function queryInput(): GetAllExpenseInput
    {
        $period = $this->period();
        $category = $this->validated('filter.category');
        $categories = $category === null ? [] : array_values(array_unique(explode(',', $category)));
        sort($categories, SORT_STRING);

        return new GetAllExpenseInput(
            categories: $categories,
            cursor: $this->validated('page.cursor'),
            size: (int) $this->validated('page.size', 20),
            to: $period?->to() ?? $this->validated('filter.to'),
            from: $period?->from() ?? $this->validated('filter.from'),
            sorts: explode(',', $this->validated('sort', '-occurred_on')),
            amountMin: $this->validated('filter.amount_min') === null ? null : (int) $this->validated('filter.amount_min'),
            amountMax: $this->validated('filter.amount_max') === null ? null : (int) $this->validated('filter.amount_max'),
        );
    }

    private function civilDateRules(): array
    {
        return ['sometimes', 'required', 'string', 'date_format:Y-m-d', new CivilDateRule];
    }

    private function period(): ?DatePeriodValueObject
    {
        $year = $this->validated('filter.year');

        if ($year === null) {
            return null;
        }

        $day = $this->validated('filter.day');
        $month = $this->validated('filter.month');

        if ($month === null) {
            return DatePeriodValueObject::fromDates(
                to: sprintf('%04d-12-31', (int) $year),
                from: sprintf('%04d-01-01', (int) $year),
            );
        }

        $date = sprintf('%04d-%02d-%02d', (int) $year, (int) $month, $day === null ? 1 : (int) $day);

        return $day === null
            ? DatePeriodValueObject::monthContaining($date)
            : DatePeriodValueObject::fromDates(from: $date, to: $date);
    }
}
