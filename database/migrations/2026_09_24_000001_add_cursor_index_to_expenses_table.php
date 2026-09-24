<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table): void {
            $table->index(['user_id', 'occurred_on', 'id'], 'expenses_owner_cursor_index');
        });
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table): void {
            $table->dropIndex('expenses_owner_cursor_index');
        });
    }
};
