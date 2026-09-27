<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;

it('limits sign-up to three requests per hour and IP by default, including invalid documents', function (): void {
    $payload = ['data' => ['type' => 'sign-ups', 'attributes' => []]];

    for ($attempt = 0; $attempt < 3; $attempt++) {
        $this->postJson(route('authentication.api.sign-up'), $payload)->assertUnprocessable();
    }

    $this->postJson(route('authentication.api.sign-up'), $payload)
        ->assertTooManyRequests()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertHeader('Retry-After');

    expect(UserModel::query()->count())->toBe(0);

    $this->withServerVariables(['REMOTE_ADDR' => '192.0.2.10'])
        ->postJson(route('authentication.api.sign-up'), $payload)
        ->assertUnprocessable();
});

it('applies a more generous sign-up quota when configured', function (): void {
    config()->set('identity.sign_up.per_hour', 100);
    $payload = ['data' => ['type' => 'sign-ups', 'attributes' => []]];

    for ($attempt = 0; $attempt < 100; $attempt++) {
        $this->postJson(route('authentication.api.sign-up'), $payload)->assertUnprocessable();
    }

    $this->postJson(route('authentication.api.sign-up'), $payload)->assertTooManyRequests();

    expect(UserModel::query()->count())->toBe(0);
});
