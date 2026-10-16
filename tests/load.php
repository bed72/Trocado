<?php

declare(strict_types=1);

use Tests\Support\Core\Load\LoadCommand;

require dirname(__DIR__).'/vendor/autoload.php';

exit((new LoadCommand(dirname(__DIR__)))->run(array_slice($argv, 1)));
