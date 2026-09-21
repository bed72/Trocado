<?php

declare(strict_types=1);

namespace App\Authentication\Infrastructure\Adapters;

use App\Authentication\Application\Ports\SignOutPort;
use App\User\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Database\Eloquent\Model;

final readonly class SignOutAdapter implements SignOutPort
{
    public function __construct(private AuthManager $auth) {}

    public function revokeCurrentToken(): void
    {
        $user = $this->auth->guard(name: 'sanctum')->user();
        $token = $user instanceof UserModel ? $user->currentAccessToken() : null;

        if (! $token instanceof Model) {
            throw new AuthenticationException;
        }

        $token->delete();
    }
}
