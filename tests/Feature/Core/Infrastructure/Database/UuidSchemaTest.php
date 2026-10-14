<?php

declare(strict_types=1);

use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use RuntimeException as CleanupRefusedException;
use Tests\Support\Core\Database\TestDatabaseCleanup;
use Tests\Support\Core\Database\TestDatabaseRun;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Core\Fixtures\UuidSchemaFixture;

dataset('own UUID columns', function (): iterable {
    foreach (UuidSchemaFixture::UUID_COLUMNS as $table => $columns) {
        foreach ($columns as $column) {
            yield $table.'.'.$column => [$table, $column];
        }
    }
});

it('builds native UUID columns without sequence defaults or parallel integer identities', function (): void {
    foreach (UuidSchemaFixture::UUID_COLUMNS as $table => $columns) {
        $schema = DB::select('SELECT column_name, data_type, is_nullable, column_default, is_identity FROM information_schema.columns WHERE table_schema = ? AND table_name = ?', ['public', $table]);
        $byName = array_column($schema, null, 'column_name');
        foreach ($columns as $column) {
            expect($byName[$column]->data_type)->toBe('uuid')
                ->and($byName[$column]->is_nullable)->toBe('NO')
                ->and($byName[$column]->column_default)->toBeNull()
                ->and($byName[$column]->is_identity)->toBe('NO');
        }
        foreach ($schema as $column) {
            expect($column->column_default === null || ! str_contains($column->column_default, 'nextval('))->toBeTrue();
        }
        $primary = DB::selectOne("SELECT pg_get_constraintdef(oid) AS definition FROM pg_constraint WHERE conrelid = ?::regclass AND contype = 'p'", [$table]);
        expect($primary->definition)->toBe('PRIMARY KEY (id)');
        $identityColumns = array_values(array_filter(array_keys($byName), static fn (string $name): bool => $name === 'id' || str_ends_with($name, '_id')));
        sort($identityColumns);
        $expectedColumns = $columns;
        sort($expectedColumns);
        expect($identityColumns)->toBe($expectedColumns);
    }

    expect(Schema::getColumnListing('resource_identities'))->toBe([
        'id', 'user_id', 'namespace', 'identity_version', 'logical_fingerprint', 'created_at',
    ]);
    $sequences = DB::select("SELECT c.relname AS table_name FROM pg_depend d JOIN pg_class c ON c.oid = d.refobjid JOIN pg_class s ON s.oid = d.objid WHERE s.relkind = 'S' AND c.relname IN ('users', 'expenses', 'personal_access_tokens', 'notifications', 'resource_identities')");
    expect($sequences)->toBe([])
        ->and(Schema::getColumnType('jobs', 'id'))->toBe('int8')
        ->and(Schema::getColumnType('failed_jobs', 'id'))->toBe('int8')
        ->and(Schema::getColumnType('migrations', 'id'))->toBe('int4');
});

it('accepts RFC variants and PostgreSQL canonicalizes uppercase UUIDs', function (string $table, string $column): void {
    $row = UuidSchemaFixture::row($table);
    $row[$column] = strtoupper($row[$column]);
    UuidSchemaFixture::insert($table, $row);
    expect(DB::table($table)->value($column))->toBe(strtolower($row[$column]));
})->with('own UUID columns');

it('accepts all four RFC variant prefixes for a v7 primary key', function (string $variant): void {
    $row = UuidSchemaFixture::row('users');
    $row['id'] = '017f22e2-79b0-7cc3-'.$variant.'8c4-000000000001';
    DB::table('users')->insert($row);
    expect(DB::table('users')->value('id'))->toBe($row['id']);
})->with(['8', '9', 'a', 'b']);

it('rejects other versions and non RFC variants in every own UUID column', function (string $table, string $column, string $invalid): void {
    $row = UuidSchemaFixture::row($table);
    $row[$column] = $invalid;
    try {
        UuidSchemaFixture::insert($table, $row);
        $this->fail('A non-v7 UUID was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe('23514');
    }
    expect(DB::table($table)->where($column, $invalid)->exists())->toBeFalse();
})->with('own UUID columns')->with([
    'v1' => '017f22e2-79b0-1cc3-98c4-000000000009',
    'v4' => '017f22e2-79b0-4cc3-98c4-000000000009',
    'v6' => '017f22e2-79b0-6cc3-98c4-000000000009',
    'v8' => '017f22e2-79b0-8cc3-98c4-000000000009',
    'nil' => '00000000-0000-0000-0000-000000000000',
    'variant 0' => '017f22e2-79b0-7cc3-08c4-000000000009',
    'variant 7' => '017f22e2-79b0-7cc3-78c4-000000000009',
    'variant c' => '017f22e2-79b0-7cc3-c8c4-000000000009',
    'variant f' => '017f22e2-79b0-7cc3-f8c4-000000000009',
]);

it('rejects null in mandatory UUID columns', function (string $table, string $column): void {
    $row = UuidSchemaFixture::row($table);
    $row[$column] = null;
    try {
        UuidSchemaFixture::insert($table, $row);
        $this->fail('A null identity was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe('23502');
    }
})->with('own UUID columns');

it('rejects orphan references in each actual foreign key', function (string $table, string $column): void {
    $row = UuidSchemaFixture::row($table);
    $row[$column] = UuidFixture::at(999);
    try {
        UuidSchemaFixture::insert($table, $row);
        $this->fail('An orphan reference was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe('23503');
    }
    expect(DB::table($table)->count())->toBe(0);
})->with([
    'expense owner' => ['expenses', 'user_id'],
    'notification owner' => ['notifications', 'user_id'],
    'notification session' => ['notifications', 'session_id'],
    'resource owner' => ['resource_identities', 'user_id'],
]);

it('preserves existing fields and indexes and creates only the minimal Core association', function (): void {
    UuidSchemaFixture::parents();
    foreach (['expenses', 'notifications', 'resource_identities'] as $table) {
        DB::table($table)->insert(UuidSchemaFixture::row($table));
    }
    $user = DB::table('users')->first();
    $token = DB::table('personal_access_tokens')->first();
    $expense = DB::table('expenses')->first();
    $notification = DB::table('notifications')->first();
    expect($user->password)->toBe('schema-only-hash')->and($user->status)->toBe('active')
        ->and($user->email_verified_at)->toBe('2026-10-14 11:00:00')->and($user->avatar)->toBeNull()
        ->and($token->tokenable_type)->toBe(UuidSchemaFixture::row('personal_access_tokens')['tokenable_type'])
        ->and($token->abilities)->toBe('["*"]')->and($token->token)->toBe(str_repeat('a', 64))
        ->and($token->expires_at)->toBe('2026-11-13 12:00:00')->and($token->last_used_at)->toBeNull()
        ->and($expense->amount)->toBe(12500)->and($expense->occurred_on)->toBe('2026-10-14')
        ->and($expense->category)->toBe('food')->and($expense->description)->toBeNull()
        ->and($expense->classification_token)->toBe('schema-fencing')
        ->and($expense->classification_expires_at)->toBe('2026-10-14 12:05:00')
        ->and($notification->registration_identifier)->toBe('schema-only-ciphertext')
        ->and($notification->identifier_fingerprint)->toBe(str_repeat('b', 64))
        ->and($notification->generation)->toBe(1)
        ->and($notification->last_registered_at)->toBe('2026-10-14 12:00:00.123456+00');
    $indexes = array_column(DB::select("SELECT indexname FROM pg_indexes WHERE schemaname = 'public'"), 'indexname');
    expect($indexes)->toContain(
        'users_email_unique', 'personal_access_tokens_token_unique',
        'personal_access_tokens_tokenable_type_tokenable_id_index', 'personal_access_tokens_expires_at_index',
        'expenses_user_id_occurred_on_index', 'expenses_owner_cursor_index',
        'expenses_classification_token_unique', 'notifications_installation_id_unique',
        'notifications_identifier_fingerprint_unique', 'notifications_user_id_index',
        'notifications_session_id_index', 'resource_identities_logical_key_unique',
    );
    $foreignKeys = DB::select("SELECT conname FROM pg_constraint WHERE conrelid = 'personal_access_tokens'::regclass AND contype = 'f'");
    expect($foreignKeys)->toBe([]);
});

it('preserves uniqueness of primary keys and existing business keys', function (string $table, string $column): void {
    $row = UuidSchemaFixture::row($table);
    UuidSchemaFixture::insert($table, $row);
    $duplicate = $row;
    if ($column !== 'id') {
        $duplicate['id'] = UuidFixture::at(100);
    }
    if ($table === 'notifications') {
        if ($column !== 'installation_id') {
            $duplicate['installation_id'] = UuidFixture::at(101);
        }
        if ($column !== 'identifier_fingerprint') {
            $duplicate['identifier_fingerprint'] = str_repeat('d', 64);
        }
    }
    try {
        DB::table($table)->insert($duplicate);
        $this->fail('A duplicate key was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe('23505');
    }
    expect(DB::table($table)->count())->toBe(1);
})->with([
    'user PK' => ['users', 'id'], 'PAT PK' => ['personal_access_tokens', 'id'],
    'expense PK' => ['expenses', 'id'], 'notification PK' => ['notifications', 'id'],
    'resource PK' => ['resource_identities', 'id'], 'email' => ['users', 'email'],
    'token hash' => ['personal_access_tokens', 'token'], 'fencing' => ['expenses', 'classification_token'],
    'installation' => ['notifications', 'installation_id'], 'destination' => ['notifications', 'identifier_fingerprint'],
    'logical key' => ['resource_identities', 'logical_fingerprint'],
]);

it('distinguishes every dimension of the resource identity unique key', function (string $column, string|int $different): void {
    UuidSchemaFixture::parents();
    $other = UuidSchemaFixture::row('users');
    $other['id'] = UuidFixture::at(9);
    $other['email'] = 'other-uuid-schema@example.com';
    DB::table('users')->insert($other);
    $row = UuidSchemaFixture::row('resource_identities');
    DB::table('resource_identities')->insert($row);
    $row['id'] = UuidFixture::at(10);
    $row[$column] = $different;
    DB::table('resource_identities')->insert($row);
    expect(DB::table('resource_identities')->count())->toBe(2);
})->with([
    'owner' => ['user_id', UuidFixture::at(9)], 'namespace' => ['namespace', 'expense-metrics'],
    'version' => ['identity_version', 2], 'fingerprint' => ['logical_fingerprint', str_repeat('d', 64)],
]);

it('rejects invalid registry metadata and missing mandatory fields', function (string $column, string|int|null $invalid, string $state): void {
    $row = UuidSchemaFixture::row('resource_identities');
    $row[$column] = $invalid;
    try {
        UuidSchemaFixture::insert('resource_identities', $row);
        $this->fail('Invalid registry metadata was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe($state);
    }
})->with([
    'empty namespace' => ['namespace', '', '23514'], 'uppercase namespace' => ['namespace', 'Insights', '23514'],
    'namespace whitespace' => ['namespace', 'insights ', '23514'], 'namespace punctuation' => ['namespace', 'insights/key', '23514'],
    'namespace too long' => ['namespace', str_repeat('a', 65), '22001'],
    'zero version' => ['identity_version', 0, '23514'], 'negative version' => ['identity_version', -1, '23514'],
    'short digest' => ['logical_fingerprint', str_repeat('a', 63), '23514'],
    'uppercase digest' => ['logical_fingerprint', str_repeat('A', 64), '23514'],
    'non hex digest' => ['logical_fingerprint', str_repeat('z', 64), '23514'],
    'null namespace' => ['namespace', null, '23502'], 'null version' => ['identity_version', null, '23502'],
    'null digest' => ['logical_fingerprint', null, '23502'], 'null instant' => ['created_at', null, '23502'],
]);

it('preserves the closed status and notification value checks', function (string $table, string $column, string|int $invalid): void {
    $row = UuidSchemaFixture::row($table);
    $row[$column] = $invalid;
    try {
        UuidSchemaFixture::insert($table, $row);
        $this->fail('An invalid closed value was persisted.');
    } catch (QueryException $exception) {
        expect($exception->errorInfo[0])->toBe('23514');
    }
})->with([
    'status' => ['users', 'status', 'unknown'], 'provider' => ['notifications', 'provider', 'unknown'],
    'platform' => ['notifications', 'platform', 'web'], 'kind' => ['notifications', 'registration_kind', 'fid'],
    'generation zero' => ['notifications', 'generation', 0], 'generation negative' => ['notifications', 'generation', -1],
]);

it('removes only session destinations and retains resource identities and other installations', function (): void {
    UuidSchemaFixture::parents();
    DB::table('notifications')->insert(UuidSchemaFixture::row('notifications'));
    DB::table('resource_identities')->insert(UuidSchemaFixture::row('resource_identities'));
    $token = UuidSchemaFixture::row('personal_access_tokens');
    $token['id'] = UuidFixture::at(20);
    $token['token'] = str_repeat('d', 64);
    DB::table('personal_access_tokens')->insert($token);
    $registration = UuidSchemaFixture::row('notifications');
    $registration['id'] = UuidFixture::at(21);
    $registration['session_id'] = UuidFixture::at(20);
    $registration['installation_id'] = UuidFixture::at(22);
    $registration['identifier_fingerprint'] = str_repeat('e', 64);
    DB::table('notifications')->insert($registration);
    DB::table('personal_access_tokens')->where('id', UuidFixture::at(2))->delete();
    expect(DB::table('notifications')->pluck('id')->all())->toBe([UuidFixture::at(21)])
        ->and(DB::table('resource_identities')->value('id'))->toBe(UuidFixture::at(6))
        ->and(DB::table('users')->count())->toBe(1);
});

it('cascades owner deletion without affecting another owner and does not invent a polymorphic cascade', function (): void {
    UuidSchemaFixture::parents();
    foreach (['expenses', 'notifications', 'resource_identities'] as $table) {
        DB::table($table)->insert(UuidSchemaFixture::row($table));
    }
    $other = UuidSchemaFixture::row('users');
    $other['id'] = UuidFixture::at(30);
    $other['email'] = 'other-owner@example.com';
    DB::table('users')->insert($other);
    $resource = UuidSchemaFixture::row('resource_identities');
    $resource['id'] = UuidFixture::at(31);
    $resource['user_id'] = UuidFixture::at(30);
    DB::table('resource_identities')->insert($resource);
    DB::table('users')->where('id', UuidFixture::at(1))->delete();
    expect(DB::table('expenses')->count())->toBe(0)->and(DB::table('notifications')->count())->toBe(0)
        ->and(DB::table('resource_identities')->pluck('id')->all())->toBe([UuidFixture::at(31)])
        ->and(DB::table('users')->value('id'))->toBe(UuidFixture::at(30))
        ->and(DB::table('personal_access_tokens')->count())->toBe(1);
});

it('reverses and reapplies the notification rename without losing UUID checks or rows', function (): void {
    UuidSchemaFixture::parents();
    DB::table('notifications')->insert(UuidSchemaFixture::row('notifications'));
    $migration = require database_path('migrations/2026_10_13_222940_rename_push_registrations_to_notifications.php');
    try {
        $migration->down();
        expect(Schema::hasTable('notifications'))->toBeFalse()
            ->and(DB::table('push_registrations')->value('id'))->toBe(UuidFixture::at(4));
        $checks = array_column(DB::select("SELECT conname FROM pg_constraint WHERE conrelid = 'push_registrations'::regclass AND contype = 'c'"), 'conname');
        expect($checks)->toContain('push_registrations_id_uuid_v7_check', 'push_registrations_installation_id_uuid_v7_check', 'push_registrations_user_id_uuid_v7_check', 'push_registrations_session_id_uuid_v7_check', 'push_registrations_values_check');
    } finally {
        if (Schema::hasTable('push_registrations')) {
            $migration->up();
        }
    }
    expect(DB::table('notifications')->value('id'))->toBe(UuidFixture::at(4));
});

it('cleans registered resource identities under exact execution ownership while preserving migrations and technical sequences', function (): void {
    UuidSchemaFixture::parents();
    DB::table('resource_identities')->insert(UuidSchemaFixture::row('resource_identities'));
    $migrations = DB::table('migrations')->orderBy('id')->get()->all();
    $sequence = DB::selectOne('SELECT last_value, is_called FROM migrations_id_seq');
    $identity = DB::selectOne("SELECT current_database() AS name, shobj_description(oid, 'pg_database') AS owner FROM pg_database WHERE datname = current_database()");
    $run = TestDatabaseRun::fromEnvironment();
    expect($identity->name)->toBe($run->database)->and($identity->owner)->toBe($run->marker());
    TestDatabaseCleanup::clean($this->app);
    expect(DB::table('resource_identities')->count())->toBe(0)->and(DB::table('users')->count())->toBe(0)
        ->and(DB::table('migrations')->orderBy('id')->get()->all())->toEqual($migrations)
        ->and(DB::selectOne('SELECT last_value, is_called FROM migrations_id_seq'))->toEqual($sequence);
});

it('refuses cleanup with divergent configuration before removing the registered association', function (): void {
    UuidSchemaFixture::parents();
    DB::table('resource_identities')->insert(UuidSchemaFixture::row('resource_identities'));
    $original = config('database.connections.pgsql.database');
    try {
        config(['database.connections.pgsql.database' => 'trocado']);
        expect(fn () => TestDatabaseCleanup::clean($this->app))->toThrow(CleanupRefusedException::class, 'Unsafe test database configuration');
    } finally {
        config(['database.connections.pgsql.database' => $original]);
    }
    expect(DB::table('resource_identities')->value('id'))->toBe(UuidFixture::at(6))
        ->and(DB::table('users')->count())->toBe(1);
});
