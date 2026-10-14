<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('resource_identities', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('namespace', 64);
            $table->smallInteger('identity_version');
            $table->char('logical_fingerprint', 64);
            $table->timestampTz('created_at', 6);
            $table->unique(['user_id', 'namespace', 'identity_version', 'logical_fingerprint'], 'resource_identities_logical_key_unique');
        });

        foreach (['id', 'user_id'] as $column) {
            DB::statement("ALTER TABLE resource_identities ADD CONSTRAINT resource_identities_{$column}_uuid_v7_check CHECK ({$column}::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')");
        }

        DB::statement("ALTER TABLE resource_identities ADD CONSTRAINT resource_identities_namespace_check CHECK (namespace ~ '^[a-z][a-z0-9]*(-[a-z0-9]+)*$')");
        DB::statement('ALTER TABLE resource_identities ADD CONSTRAINT resource_identities_version_check CHECK (identity_version > 0)');
        DB::statement("ALTER TABLE resource_identities ADD CONSTRAINT resource_identities_fingerprint_check CHECK (logical_fingerprint::text ~ '^[0-9a-f]{64}$')");
    }

    public function down(): void
    {
        Schema::dropIfExists('resource_identities');
    }
};
