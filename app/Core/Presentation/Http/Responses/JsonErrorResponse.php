<?php

declare(strict_types=1);

namespace App\Core\Presentation\Http\Responses;

use Illuminate\Http\JsonResponse;

final class JsonErrorResponse extends JsonResponse
{
    /**
     * @param  list<array{title: string, detail: string, source?: array<string, string>, id?: string, code?: string, links?: array<string, mixed>, meta?: array<string, mixed>}>  $errors
     */
    public function __construct(array $errors, int $status)
    {
        parent::__construct(self::document($errors, $status), $status, [
            'Content-Type' => 'application/vnd.api+json',
        ]);
    }

    /**
     * @param  list<array{title: string, detail: string, source?: array<string, string>, id?: string, code?: string, links?: array<string, mixed>, meta?: array<string, mixed>}>  $errors
     * @return array{errors: list<array<string, mixed>>}
     */
    public static function document(array $errors, int $status): array
    {
        foreach ($errors as $index => $error) {
            $errors[$index] = [...$error, 'status' => (string) $status];
        }

        return ['errors' => $errors];
    }
}
