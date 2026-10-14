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
        Schema::create('expenses', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained(table: 'users')->cascadeOnDelete();
            $table->unsignedBigInteger('amount');
            $table->date('occurred_on');
            $table->string('category', 32)->default('other');
            $table->string('description', 64)->nullable();
            $table->timestamp('created_at');
            $table->softDeletes();
            $table->index(columns: ['user_id', 'occurred_on']);
        });

        foreach (['id', 'user_id'] as $column) {
            DB::statement("ALTER TABLE expenses ADD CONSTRAINT expenses_{$column}_uuid_v7_check CHECK ({$column}::text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
