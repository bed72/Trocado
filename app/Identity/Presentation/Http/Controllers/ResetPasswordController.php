<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\Data\Input\ResetPasswordInput;
use App\Identity\Application\UseCases\ResetPasswordUseCase;
use App\Identity\Presentation\Http\Requests\ResetPasswordRequest;
use Illuminate\Http\Response;

final class ResetPasswordController
{
    public function __construct(private readonly ResetPasswordUseCase $useCase) {}

    public function __invoke(ResetPasswordRequest $request): Response
    {
        $this->useCase->execute(new ResetPasswordInput(
            email: $request->validated('data.attributes.email'),
            token: $request->validated('data.attributes.token'),
            password: $request->validated('data.attributes.password'),
        ));

        return response()->noContent();
    }
}
