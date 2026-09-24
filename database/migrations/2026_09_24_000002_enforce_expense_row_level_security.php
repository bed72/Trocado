<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $role = DB::selectOne("select rolcanlogin, rolsuper, rolbypassrls from pg_roles where rolname = 'trocado_runtime'");

        if ($role === null || ! $role->rolcanlogin || $role->rolsuper || $role->rolbypassrls || DB::selectOne('select current_user as name')->name === 'trocado_runtime') {
            throw new RuntimeException('Provisione trocado_runtime e execute migrations com a role de manutenção.');
        }

        DB::statement('ALTER TABLE expenses ENABLE ROW LEVEL SECURITY');
        DB::statement('ALTER TABLE expenses FORCE ROW LEVEL SECURITY');
        DB::statement(<<<'SQL'
            CREATE POLICY expenses_owner_policy ON expenses
                FOR ALL TO trocado_runtime
                USING (user_id = CASE
                    WHEN current_setting('app.user_id', true) ~ '^[1-9][0-9]{0,18}$'
                    THEN current_setting('app.user_id', true)::numeric
                    ELSE NULL
                END)
                WITH CHECK (user_id = CASE
                    WHEN current_setting('app.user_id', true) ~ '^[1-9][0-9]{0,18}$'
                    THEN current_setting('app.user_id', true)::numeric
                    ELSE NULL
                END)
            SQL);
    }

    public function down(): void
    {
        DB::statement('DROP POLICY IF EXISTS expenses_owner_policy ON expenses');
        DB::statement('ALTER TABLE expenses NO FORCE ROW LEVEL SECURITY');
        DB::statement('ALTER TABLE expenses DISABLE ROW LEVEL SECURITY');
    }
};
