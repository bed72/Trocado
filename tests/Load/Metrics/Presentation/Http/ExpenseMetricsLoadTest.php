<?php

declare(strict_types=1);

use Tests\Support\Core\Load\LoadEngineGate;

it('measures expense metrics over external HTTP', function (): void {
    LoadEngineGate::assertReady();
});
