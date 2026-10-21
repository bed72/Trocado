<?php

declare(strict_types=1);

return [
    'password_recovery' => [
        'url' => env('PASSWORD_RESET_URL'),
    ],
    'sign_up' => [
        'per_hour' => (int) env('IDENTITY_SIGN_UP_PER_HOUR', 3),
    ],
];
