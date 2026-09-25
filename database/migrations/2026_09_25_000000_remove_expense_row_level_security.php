<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('DROP POLICY IF EXISTS expenses_owner_policy ON expenses');
        DB::statement('ALTER TABLE expenses NO FORCE ROW LEVEL SECURITY');
        DB::statement('ALTER TABLE expenses DISABLE ROW LEVEL SECURITY');
    }

    public function down(): void
    {
        // RLS was intentionally removed from the application architecture.
    }
};
