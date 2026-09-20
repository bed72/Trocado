<?php

declare(strict_types=1);

namespace App\Budget\Presentation\Http\Controllers;

use App\Budget\Application\UseCases\DeleteBudgetUseCase;
use Illuminate\Http\Response;

final class DeleteBudgetController
{
    public function __construct(private readonly DeleteBudgetUseCase $useCase) {}

    public function __invoke(int $budget): Response
    {
        $this->useCase->execute(id: $budget);

        return response()->noContent();
    }
}
