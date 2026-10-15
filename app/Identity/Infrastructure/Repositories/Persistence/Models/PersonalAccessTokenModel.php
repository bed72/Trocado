<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence\Models;

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Laravel\Sanctum\PersonalAccessToken;
use SensitiveParameter;

use function is_string;

#[Table('personal_access_tokens')]
final class PersonalAccessTokenModel extends PersonalAccessToken
{
    use HasUuids;

    public static function findToken(#[SensitiveParameter] mixed $token): ?static
    {
        if (! is_string($token)) {
            return null;
        }

        if (str_contains($token, '|')) {
            [$id, $secret] = explode('|', $token, 2);
            try {
                $id = UuidValueObject::fromString($id)->value();
            } catch (InvalidUuidException) {
                return null;
            }
            $token = $id.'|'.$secret;
        }

        return parent::findToken($token);
    }
}
