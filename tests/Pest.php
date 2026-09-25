<?php

declare(strict_types=1);

use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Tests\FeatureTestCase;
use Tests\TestCase;

pest()->extend(FeatureTestCase::class)->in('Feature');

function signUpIdentityByApi(
    TestCase $test,
    string $name = 'Maria',
    string $password = 'Correct1',
    string $email = 'maria@example.com',
): int {
    $response = $test->postJson(route('authentication.api.sign-up'), [
        'data' => [
            'type' => 'sign-ups',
            'attributes' => [
                'name' => $name,
                'email' => $email,
                'password' => $password,
                'password_confirmation' => $password,
            ],
        ],
    ])->assertCreated();

    $userId = (int) $response->json('data.relationships.user.data.id');
    UserModel::query()->whereKey($userId)->update(['status' => UserStatusEnum::Active->value]);

    return $userId;
}

function signInIdentityByApi(
    TestCase $test,
    string $email = 'maria@example.com',
    string $password = 'Correct1',
): string {
    $token = $test->postJson(route('authentication.api.sign-in'), [
        'data' => [
            'type' => 'access-tokens',
            'attributes' => [
                'email' => $email,
                'password' => $password,
            ],
        ],
    ])->assertOk()->json('data.attributes.token');

    expect($token)->toBeString()->not->toBeEmpty();

    return $token;
}
