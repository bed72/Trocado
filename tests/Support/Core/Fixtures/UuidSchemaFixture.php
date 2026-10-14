<?php

declare(strict_types=1);

namespace Tests\Support\Core\Fixtures;

use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

final class UuidSchemaFixture
{
    /** @var array<string, list<string>> */
    public const UUID_COLUMNS = [
        'users' => ['id'],
        'personal_access_tokens' => ['id', 'tokenable_id'],
        'expenses' => ['id', 'user_id'],
        'notifications' => ['id', 'user_id', 'session_id', 'installation_id'],
        'resource_identities' => ['id', 'user_id'],
    ];

    public static function parents(): void
    {
        DB::table('users')->insert(self::row('users'));
        DB::table('personal_access_tokens')->insert(self::row('personal_access_tokens'));
    }

    /** @return array<string, string|int|null> */
    public static function row(string $table): array
    {
        $timestamps = ['created_at' => '2026-10-14 12:00:00', 'updated_at' => '2026-10-14 12:00:00'];

        return match ($table) {
            'users' => [
                'id' => UuidFixture::at(1), 'name' => 'Maria Silva', 'email' => 'uuid-schema@example.com',
                'password' => 'schema-only-hash', 'status' => 'active',
                'email_verified_at' => '2026-10-14 11:00:00', 'avatar' => null, ...$timestamps,
            ],
            'personal_access_tokens' => [
                'id' => UuidFixture::at(2), 'tokenable_id' => UuidFixture::at(1),
                'tokenable_type' => 'App\\Identity\\Infrastructure\\Repositories\\Persistence\\Models\\UserModel',
                'name' => 'schema', 'token' => str_repeat('a', 64), 'abilities' => '["*"]',
                'expires_at' => '2026-11-13 12:00:00', 'last_used_at' => null, ...$timestamps,
            ],
            'expenses' => [
                'id' => UuidFixture::at(3), 'user_id' => UuidFixture::at(1), 'amount' => 12500,
                'occurred_on' => '2026-10-14', 'category' => 'food', 'description' => null,
                'classification_token' => 'schema-fencing', 'classification_expires_at' => '2026-10-14 12:05:00',
                ...$timestamps,
            ],
            'notifications' => [
                'id' => UuidFixture::at(4), 'user_id' => UuidFixture::at(1), 'session_id' => UuidFixture::at(2),
                'installation_id' => UuidFixture::at(5), 'provider' => 'fcm', 'platform' => 'android',
                'registration_kind' => 'token', 'registration_identifier' => 'schema-only-ciphertext',
                'identifier_fingerprint' => str_repeat('b', 64), 'generation' => 1,
                'last_registered_at' => '2026-10-14 12:00:00.123456+00', ...$timestamps,
            ],
            'resource_identities' => [
                'id' => UuidFixture::at(6), 'user_id' => UuidFixture::at(1), 'namespace' => 'insights',
                'identity_version' => 1, 'logical_fingerprint' => str_repeat('c', 64),
                'created_at' => '2026-10-14 12:00:00.123456+00',
            ],
            default => throw new InvalidArgumentException('Unknown UUID schema fixture table.'),
        };
    }

    /** @param array<string, mixed> $row */
    public static function insert(string $table, array $row): void
    {
        if ($table === 'personal_access_tokens') {
            DB::table('users')->insert(self::row('users'));
        } elseif ($table !== 'users') {
            self::parents();
        }

        DB::table($table)->insert($row);
    }
}
