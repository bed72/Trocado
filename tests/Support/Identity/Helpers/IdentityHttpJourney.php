<?php

declare(strict_types=1);

namespace Tests\Support\Identity\Helpers;

use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use DateTimeInterface;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\URL;
use PHPUnit\Framework\Assert;
use Tests\TestCase;

final readonly class IdentityHttpJourney
{
    public function __construct(private TestCase $test) {}

    public function signUp(string $name = 'Maria', string $password = 'Correct1', string $email = 'maria@example.com'): int
    {
        $response = $this->test->postJson(route('authentication.api.sign-up'), [
            'data' => ['type' => 'sign-ups', 'attributes' => [
                'name' => $name, 'email' => $email, 'password' => $password, 'password_confirmation' => $password,
            ]],
        ])->assertCreated();

        return (int) $response->json('data.relationships.user.data.id');
    }

    public function verifyEmail(UserModel $user, DateTimeInterface $expiresAt): void
    {
        $this->test->getJson(URL::temporarySignedRoute(
            name: 'verification.verify',
            expiration: $expiresAt,
            parameters: ['id' => $user->getKey(), 'hash' => sha1($user->email)],
        ))->assertNoContent();
    }

    public function signIn(string $email = 'maria@example.com', string $password = 'Correct1'): string
    {
        Auth::forgetGuards();
        $token = $this->test->postJson(route('authentication.api.sign-in'), [
            'data' => ['type' => 'access-tokens', 'attributes' => ['email' => $email, 'password' => $password]],
        ])->assertOk()->json('data.attributes.token');

        Assert::assertIsString($token);
        Assert::assertNotSame('', $token);

        return $token;
    }
}
