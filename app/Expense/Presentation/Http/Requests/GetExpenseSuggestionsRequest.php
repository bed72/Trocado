<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Requests;

use Illuminate\Contracts\Validation\Validator as ValidatorContract;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Response;
use Illuminate\Validation\Validator;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

final class GetExpenseSuggestionsRequest extends FormRequest
{
    private string $term = '';

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
            $seen = false;

            foreach (explode('&', (string) $this->server('QUERY_STRING', '')) as $pair) {
                [$encodedName, $encodedValue] = array_pad(explode('=', $pair, 2), 2, '');
                $name = urldecode($encodedName);
                $root = explode('[', $name, 2)[0];

                if ($root === 'user_id') {
                    $validator->errors()->add('user_id', 'O proprietário não deve ser informado.');
                }

                if ($root !== 'query') {
                    continue;
                }

                if ($seen || $name !== 'query') {
                    $validator->errors()->add('query', 'Informe um único valor textual para a busca.');
                }

                $seen = true;
                $value = urldecode($encodedValue);

                if (! mb_check_encoding($value, 'UTF-8') || mb_strlen($value, 'UTF-8') > 64) {
                    $validator->errors()->add('query', 'A busca deve conter até 64 caracteres Unicode.');

                    continue;
                }

                $this->term = preg_replace('/\A[[:space:]]+|[[:space:]]+\z/u', '', $value) ?? '';
            }

            if (! $seen || $this->term === '') {
                $validator->errors()->add('query', 'Informe um texto não vazio para a busca.');
            }
        }];
    }

    public function searchTerm(): string
    {
        return $this->term;
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
