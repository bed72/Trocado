<?php

declare(strict_types=1);

use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\QueryException;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use RuntimeException as MigrationException;
use SensitiveParameter as SensitiveArgument;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        try {
            DB::transaction(static function (): void {
                DB::statement('LOCK TABLE notifications IN ACCESS EXCLUSIVE MODE');
                DB::table('notifications')->select('id', 'provider', 'registration_kind', 'registration_identifier')
                    ->chunkById(100, static function (#[SensitiveArgument] Collection $rows): void {
                        foreach ($rows as $row) {
                            $identifier = Crypt::decryptString($row->registration_identifier);
                            $fingerprint = hash('sha256', "{$row->provider}\0{$row->registration_kind}\0{$identifier}");
                            DB::table('notifications')->where('id', $row->id)->update(['identifier_fingerprint' => $fingerprint]);
                        }
                    });
            });
        } catch (DecryptException|QueryException) {
            throw new MigrationException('Não foi possível recalcular os fingerprints; nenhuma alteração foi confirmada.');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        throw new MigrationException('A reversão dos fingerprints exige restaurar os valores anteriores e sua chave; rollback automático indisponível.');
    }
};
