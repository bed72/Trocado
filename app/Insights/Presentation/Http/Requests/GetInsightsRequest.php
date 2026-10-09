<?php

declare(strict_types=1);

namespace App\Insights\Presentation\Http\Requests;

use Illuminate\Contracts\Validation\Validator as ValidatorContract;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Response;
use Illuminate\Validation\Validator;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

final class GetInsightsRequest extends FormRequest
{
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
            foreach (array_keys($this->query()) as $parameter) {
                $validator->errors()->add((string) $parameter, 'A consulta de insights não aceita parâmetros de query.');
            }
        }];
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
