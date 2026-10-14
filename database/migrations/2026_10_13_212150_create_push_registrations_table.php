<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('push_registrations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('session_id')->constrained('personal_access_tokens')->cascadeOnDelete();
            $table->uuid('installation_id')->unique();
            $table->string('provider', 16);
            $table->string('platform', 16);
            $table->string('registration_kind', 16);
            $table->text('registration_identifier');
            $table->char('identifier_fingerprint', 64)->unique();
            $table->bigInteger('generation');
            $table->timestampTz('last_registered_at', 6);
            $table->timestampsTz(6);
            $table->index('user_id');
            $table->index('session_id');
        });

        DB::statement("ALTER TABLE push_registrations ADD CONSTRAINT push_registrations_values_check CHECK (provider = 'fcm' AND platform IN ('android', 'ios') AND registration_kind = 'token' AND generation > 0)");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('push_registrations');
    }
};
