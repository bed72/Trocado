<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\SignInUseCase;
use App\Identity\Presentation\Http\Requests\SignInRequest;
use App\Identity\Presentation\Http\Responses\AccessTokenResponse;
use Illuminate\Http\JsonResponse;

final class SignInController
{
    public function __construct(private readonly SignInUseCase $useCase) {}

    public function __invoke(SignInRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $token = $this->useCase->execute(
            email: $attributes['email'],
            password: $attributes['password'],
        );

        return (new AccessTokenResponse(resource: $token))->response()
            ->header(key: 'Cache-Control', values: 'no-store')
            ->header(key: 'Pragma', values: 'no-cache');
    }
}
