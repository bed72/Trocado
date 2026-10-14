<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Controllers;

use App\Notifications\Application\UseCases\DeleteNotificationUseCase;
use DateTimeImmutable;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Date;

final readonly class DeleteNotificationController
{
    public function __construct(private DeleteNotificationUseCase $useCase) {}

    public function __invoke(string $registration): Response
    {
        $this->useCase->execute($registration, DateTimeImmutable::createFromInterface(Date::now()));

        return response()->noContent()->header('Cache-Control', 'no-store');
    }
}
