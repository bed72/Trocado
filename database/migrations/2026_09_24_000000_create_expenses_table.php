<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained(table: 'users')->cascadeOnDelete();
            $table->unsignedBigInteger('amount');
            $table->date('occurred_on');
            $table->string('category', 32)->default('other');
            $table->string('description', 64)->nullable();
            $table->timestamp('created_at');
            $table->softDeletes();
            $table->index(columns: ['user_id', 'occurred_on']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
