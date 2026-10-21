<?php

declare(strict_types=1);

namespace App\Identity\Presentation\Http\Controllers;

use App\Identity\Application\UseCases\RequestPasswordRecoveryUseCase;
use App\Identity\Presentation\Http\Requests\RequestPasswordRecoveryRequest;
use App\Identity\Presentation\Http\Responses\PasswordRecoveryResponse;

final readonly class RequestPasswordRecoveryController
{
    public function __construct(private RequestPasswordRecoveryUseCase $useCase) {}

    public function __invoke(RequestPasswordRecoveryRequest $request): PasswordRecoveryResponse
    {
        $this->useCase->execute(email: $request->validated(key: 'data.attributes.email'));

        return new PasswordRecoveryResponse;
    }
}
