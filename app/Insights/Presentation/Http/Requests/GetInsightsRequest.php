<?php

declare(strict_types=1);

namespace App\Insights\Presentation\Http\Requests;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Application\Data\GetInsightsInput;
use Illuminate\Contracts\Validation\Validator as ValidatorContract;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Response;
use Illuminate\Validation\Validator;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

use function in_array;

final class GetInsightsRequest extends FormRequest
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
            $seen = [];
            $this->filters = [];

            foreach (explode('&', (string) $this->server('QUERY_STRING', '')) as $pair) {
                if ($pair === '') {
                    continue;
                }

                [$encodedName, $encodedValue] = array_pad(explode('=', $pair, 2), 2, '');
                $name = urldecode($encodedName);
                $parameter = match (true) {
                    str_starts_with($name, 'filter[year]') => 'filter[year]',
                    str_starts_with($name, 'filter[month]') => 'filter[month]',
                    default => $name,
                };

                if (! in_array($parameter, ['filter[year]', 'filter[month]'], true)) {
                    $validator->errors()->add($parameter, 'Este parâmetro de query não é suportado.');

                    continue;
                }

                if (isset($seen[$parameter])) {
                    $validator->errors()->add($parameter, 'O parâmetro deve ser informado uma única vez.');
                }

                $seen[$parameter] = true;

                if ($name !== $parameter) {
                    $validator->errors()->add($parameter, 'O parâmetro deve conter um único valor textual.');
                }

                $value = urldecode($encodedValue);
                $isYear = $parameter === 'filter[year]';

                if (preg_match($isYear ? '/\A[0-9]{1,4}\z/' : '/\A[0-9]{1,2}\z/', $value) !== 1
                    || (int) $value < 1 || (int) $value > ($isYear ? 9999 : 12)) {
                    $validator->errors()->add($parameter, $isYear ? 'Informe um ano de 1 a 9999, somente com dígitos.' : 'Informe um mês de 1 a 12, somente com dígitos.');
                }

                $this->filters[$parameter] = $value;
            }

            foreach (['filter[year]' => 'filter[month]', 'filter[month]' => 'filter[year]'] as $parameter => $complement) {
                if (isset($seen[$parameter]) && ! isset($seen[$complement])) {
                    $validator->errors()->add($complement, 'Ano e mês devem ser informados juntos.');
                }
            }
        }];
    }

    public function toInput(string $queryDate): GetInsightsInput
    {
        $queryMonth = DatePeriodValueObject::monthContaining($queryDate);
        $selectedMonth = isset($this->filters['filter[year]'], $this->filters['filter[month]'])
            ? DatePeriodValueObject::monthContaining(sprintf('%04d-%02d-01', (int) $this->filters['filter[year]'], (int) $this->filters['filter[month]']))
            : $queryMonth;
        $validator = $this->getValidatorInstance();

        if ($selectedMonth->from() > $queryMonth->from()) {
            $validator->errors()->add('filter[month]', 'O mês selecionado não pode ser futuro.');
        }

        if ($selectedMonth->from() < '0001-03-01') {
            $validator->errors()->add('filter[year]', 'A seleção exige dois meses antecedentes representáveis, a partir de março de 0001.');
        }

        if ($validator->errors()->isNotEmpty()) {
            $this->failedValidation($validator);
        }

        return new GetInsightsInput(queryDate: $queryDate, selectedMonth: $selectedMonth);
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
