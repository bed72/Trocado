<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Adapters;

use App\Identity\Application\Ports\SignOutPort;
use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\AuthManager;
use Illuminate\Database\Eloquent\Model;

final readonly class SignOutAdapter implements SignOutPort
{
    public function __construct(private AuthManager $auth) {}

    public function revokeToken(): void
    {
        $user = $this->auth->guard(name: 'sanctum')->user();
        $token = $user instanceof UserModel ? $user->currentAccessToken() : null;

        if (! $token instanceof Model) {
            throw new AuthenticationException;
        }

        $token->delete();
    }
}
