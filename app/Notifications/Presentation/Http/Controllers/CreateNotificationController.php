<?php

declare(strict_types=1);

namespace App\Notifications\Presentation\Http\Controllers;

use App\Notifications\Application\Data\Input\RegisterNotificationRegistrationInput;
use App\Notifications\Application\UseCases\CreateNotificationUseCase;
use App\Notifications\Domain\Enums\NotificationPlatformEnum;
use App\Notifications\Domain\ValueObjects\NotificationValueObject;
use App\Notifications\Presentation\Http\Requests\CreateNotificationRequest;
use App\Notifications\Presentation\Http\Responses\NotificationResponse;
use DateTimeImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Date;

final readonly class CreateNotificationController
{
    public function __construct(private CreateNotificationUseCase $useCase) {}

    public function __invoke(CreateNotificationRequest $request): JsonResponse
    {
        $attributes = $request->validated('data.attributes');
        $output = $this->useCase->execute(new RegisterNotificationRegistrationInput(
            registeredAt: DateTimeImmutable::createFromInterface(Date::now()),
            destination: new NotificationValueObject(
                installationId: $attributes['installation_id'],
                registrationKind: $attributes['registration_kind'],
                platform: NotificationPlatformEnum::from($attributes['platform']),
                identifier: $attributes['registration_identifier'],
            ),
        ));

        return (new NotificationResponse($output->registration))->response()
            ->setStatusCode($output->created ? 201 : 200)
            ->header('Cache-Control', 'no-store');
    }
}
