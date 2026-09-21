<?php

declare(strict_types=1);

namespace App\Authentication\Presentation\Http\Controllers;

use App\Authentication\Application\UseCases\SignInUseCase;
use App\Authentication\Presentation\Http\Requests\SignInRequest;
use App\Authentication\Presentation\Http\Responses\AccessTokenResponse;
use Illuminate\Http\JsonResponse;

final class SignInController
{
    public function __construct(private readonly SignInUseCase $useCase) {}

    public function __invoke(SignInRequest $request): JsonResponse
    {
        $attributes = $request->validated(key: 'data.attributes');
        $accessToken = $this->useCase->execute(
            email: $attributes['email'],
            password: $attributes['password'],
        );

        return (new AccessTokenResponse(resource: $accessToken))->response()
            ->header(key: 'Cache-Control', values: 'no-store')
            ->header(key: 'Pragma', values: 'no-cache');
    }
}
