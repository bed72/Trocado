<?php

declare(strict_types=1);

namespace App\Metrics\Presentation\Http\Requests;

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Application\Data\GetExpenseMetricsInput;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;
use Illuminate\Contracts\Validation\Validator as ValidatorContract;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Response;
use Illuminate\Validation\Validator;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

use function array_key_exists;
use function in_array;

final class GetExpenseMetricsRequest extends FormRequest
{
    /** @var array<string, string> */
    private array $filters = [];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            $this->inspectQuery($validator);

            foreach (['start_date', 'end_date'] as $parameter) {
                if (! array_key_exists($parameter, $this->filters)) {
                    continue;
                }

                $complement = $parameter === 'start_date' ? 'end_date' : 'start_date';

                if (! array_key_exists($complement, $this->filters)) {
                    $validator->errors()->add($complement, 'As datas inicial e final devem ser informadas juntas.');
                }

                try {
                    DatePeriodValueObject::fromDates($this->filters[$parameter], $this->filters[$parameter]);
                } catch (InvalidDatePeriodException) {
                    $validator->errors()->add($parameter, 'Informe uma data real no formato YYYY-MM-DD.');
                }
            }

            if (isset($this->filters['start_date'], $this->filters['end_date'])
                && ! $validator->errors()->has('start_date') && ! $validator->errors()->has('end_date')
                && $this->filters['start_date'] > $this->filters['end_date']) {
                $validator->errors()->add('end_date', 'A data final deve ser igual ou posterior à data inicial.');
            }

            if (isset($this->filters['group_by']) && $this->filters['group_by'] !== 'category') {
                $validator->errors()->add('group_by', 'O agrupamento deve ser category.');
            }
        }];
    }

    public function toInput(string $referenceDate): GetExpenseMetricsInput
    {
        return new GetExpenseMetricsInput(
            period: isset($this->filters['start_date'])
                ? DatePeriodValueObject::fromDates($this->filters['start_date'], $this->filters['end_date'])
                : DatePeriodValueObject::monthContaining($referenceDate),
            grouping: isset($this->filters['group_by']) ? ExpenseMetricsGroupingEnum::Category : ExpenseMetricsGroupingEnum::Total,
        );
    }

    private function inspectQuery(Validator $validator): void
    {
        $seen = [];
        $this->filters = [];

        foreach (explode('&', (string) $this->server('QUERY_STRING', '')) as $pair) {
            if ($pair === '') {
                continue;
            }

            [$encodedName, $encodedValue] = array_pad(explode('=', $pair, 2), 2, '');
            $name = urldecode($encodedName);
            $root = explode('[', $name, 2)[0];

            if (! in_array($root, ['start_date', 'end_date', 'group_by'], true)) {
                $validator->errors()->add($name, 'Este parâmetro de query não é suportado.');

                continue;
            }

            if (isset($seen[$root])) {
                $validator->errors()->add($root, 'O parâmetro deve ser informado uma única vez.');
            }

            $seen[$root] = true;

            if ($name !== $root) {
                $validator->errors()->add($root, 'O parâmetro deve conter um único valor textual.');
            }

            $this->filters[$root] = trim(urldecode($encodedValue));
        }
    }

    protected function failedValidation(ValidatorContract $validator): void
    {
        $errors = [];

        foreach ($validator->errors()->messages() as $parameter => $messages) {
            foreach ($messages as $message) {
                $errors[] = [
                    'detail' => $message,
                    'title' => 'Parâmetro inválido',
                    'source' => ['parameter' => (string) $parameter],
                    'status' => (string) HttpResponse::HTTP_UNPROCESSABLE_ENTITY,
                ];
            }
        }

        throw new HttpResponseException(Response::json(['errors' => $errors], HttpResponse::HTTP_UNPROCESSABLE_ENTITY)
            ->header('Content-Type', 'application/vnd.api+json'));
    }
}
