<?php

declare(strict_types=1);

use Tests\Support\Core\Load\LoadEngineGate;

it('measures monthly insights over external HTTP', function (): void {
    LoadEngineGate::assertReady();
});
