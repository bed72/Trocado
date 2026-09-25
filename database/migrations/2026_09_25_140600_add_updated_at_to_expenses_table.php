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
        Schema::table('expenses', function (Blueprint $table): void {
            $table->timestamp('updated_at')->nullable();
        });

        DB::table('expenses')->update(['updated_at' => DB::raw('created_at')]);

        Schema::table('expenses', function (Blueprint $table): void {
            $table->timestamp('updated_at')->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table): void {
            $table->dropColumn('updated_at');
        });
    }
};
