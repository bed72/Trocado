<?php

declare(strict_types=1);

return [
    'sign_up' => [
        'per_hour' => (int) env('IDENTITY_SIGN_UP_PER_HOUR', 3),
    ],
];
