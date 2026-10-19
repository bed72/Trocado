<?php

declare(strict_types=1);

use App\Insights\Application\Data\InsightMessageOutput;
use App\Insights\Application\UseCases\SelectInsightMessagesUseCase;

it('keeps only the highest ordered message in cosmetic collisions without replacing it', function (): void {
    $messages = [
        new InsightMessageOutput('Em foco', 'Saúde: jan/2026 até 12.'),
        new InsightMessageOutput('EM FOCO ✨', 'SAÚDE · jan/2026 até 12!'),
        new InsightMessageOutput('Em foco', 'Saúde: jan/2026 até 13.'),
        new InsightMessageOutput('Em foco', 'Pets: jan/2026 até 12.'),
        new InsightMessageOutput(' Em  foco ', 'Saúde jan/2026 até 12'),
    ];
    $useCase = new SelectInsightMessagesUseCase;
    expect($useCase->execute($messages))->toBe([0, 2, 3])
        ->and($useCase->execute($messages))->toBe([0, 2, 3])
        ->and($useCase->execute([]))->toBe([]);
});
