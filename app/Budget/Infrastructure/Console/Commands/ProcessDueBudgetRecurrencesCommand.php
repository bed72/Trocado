<?php

declare(strict_types=1);

namespace App\Budget\Infrastructure\Console\Commands;

use App\Budget\Application\UseCases\GenerateDueBudgetRecurrencesUseCase;
use Illuminate\Console\Command;
use Illuminate\Contracts\Config\Repository as ConfigRepository;
use Illuminate\Support\Carbon;

final class ProcessDueBudgetRecurrencesCommand extends Command
{
    protected $signature = 'budgets:process-recurrences';

    protected $description = 'Gera as ocorrências de Budget recorrentes que estão vencidas';

    public function __construct(
        private readonly ConfigRepository $repository,
        private readonly GenerateDueBudgetRecurrencesUseCase $useCase,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $generated = $this->useCase->execute(
            processingDate: Carbon::now((string) $this->repository->get(key: 'app.timezone', default: 'UTC'))->toDateString(),
        );
        $this->info(string: "{$generated} ocorrência(s) gerada(s).");

        return self::SUCCESS;
    }
}
