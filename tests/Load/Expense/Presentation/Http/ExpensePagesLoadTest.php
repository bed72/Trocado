<?php

declare(strict_types=1);

use Tests\Support\Core\Load\LoadEngineGate;

it('measures owned expense pages over external HTTP', function (): void {
    LoadEngineGate::assertReady();
});
