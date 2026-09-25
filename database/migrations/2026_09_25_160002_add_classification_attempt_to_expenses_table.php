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
            $table->string('classification_token', 32)->nullable()->unique()->after('description');
            $table->timestamp('classification_expires_at')->nullable()->after('classification_token');
        });
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table): void {
            $table->dropUnique(['classification_token']);
            $table->dropColumn(['classification_token', 'classification_expires_at']);
        });
    }
};
