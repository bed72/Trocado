<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Controllers;

use App\Expense\Application\UseCases\DeleteExpenseUseCase;
use Illuminate\Http\Response;

final readonly class DeleteExpenseController
{
    public function __construct(private DeleteExpenseUseCase $useCase) {}

    public function __invoke(string $id): Response
    {
        $this->useCase->execute(id: $id);

        return response()->noContent();
    }
}
