<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("CREATE COLLATION expense_description_ci_ai (provider = icu, locale = 'und-u-ks-level1', deterministic = false)");
    }

    public function down(): void
    {
        DB::statement('DROP COLLATION expense_description_ci_ai');
    }
};
