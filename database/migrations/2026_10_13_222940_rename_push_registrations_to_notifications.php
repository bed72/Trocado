<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::rename('push_registrations', 'notifications');
        $this->renameConstraints('push_registrations', 'notifications');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $this->renameConstraints('notifications', 'push_registrations');
        Schema::rename('notifications', 'push_registrations');
    }

    private function renameConstraints(string $from, string $to): void
    {
        foreach (['pkey', 'installation_id_unique', 'identifier_fingerprint_unique', 'user_id_foreign', 'session_id_foreign', 'values_check'] as $suffix) {
            DB::statement("ALTER TABLE notifications RENAME CONSTRAINT {$from}_{$suffix} TO {$to}_{$suffix}");
        }

        foreach (['user_id_index', 'session_id_index'] as $suffix) {
            DB::statement("ALTER INDEX {$from}_{$suffix} RENAME TO {$to}_{$suffix}");
        }
    }
};
