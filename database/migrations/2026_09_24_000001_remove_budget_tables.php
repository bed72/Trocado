<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('budgets');
        Schema::dropIfExists('budget_recurrences');
        Schema::dropIfExists('budget_write_locks');
    }

    public function down(): void
    {
        // Removed data cannot be restored by rolling back this migration.
    }
};
