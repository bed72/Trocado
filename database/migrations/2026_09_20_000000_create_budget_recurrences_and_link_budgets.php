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
        Schema::create('budget_write_locks', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('version')->default(0);
        });
        DB::table('budget_write_locks')->insert(['id' => 1, 'version' => 0]);

        Schema::create('budget_recurrences', function (Blueprint $table): void {
            $table->id();
            $table->string('status');
            $table->unsignedBigInteger('amount');
            $table->unsignedInteger('duration_in_days');
            $table->date('next_start_date');
            $table->timestamp('blocked_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'next_start_date']);
        });

        Schema::table('budgets', function (Blueprint $table): void {
            $table->foreignId('recurrence_id')
                ->nullable()
                ->constrained(table: 'budget_recurrences')
                ->restrictOnDelete();
            $table->unique(['recurrence_id', 'start_date']);
        });
    }

    public function down(): void
    {
        Schema::table('budgets', function (Blueprint $table): void {
            $table->dropUnique(['recurrence_id', 'start_date']);
            $table->dropConstrainedForeignId('recurrence_id');
        });

        Schema::dropIfExists('budget_recurrences');
        Schema::dropIfExists('budget_write_locks');
    }
};
