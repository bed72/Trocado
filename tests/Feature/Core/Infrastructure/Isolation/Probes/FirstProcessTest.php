<?php

declare(strict_types=1);

use Tests\Support\Core\Fixtures\ExecutionIsolationProbe;

it('preserves the first process sentinel with coincident fixture identities', function (): void {
    ExecutionIsolationProbe::exercise($this);
})->group('integration', 'redis', 'parallel-isolation');
