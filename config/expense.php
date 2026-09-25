<?php

declare(strict_types=1);

return [
    'classification' => [
        'api_key' => env('EXPENSE_CLASSIFICATION_API_KEY'),
        'provider' => env('EXPENSE_CLASSIFICATION_PROVIDER', 'openai'),
        'model' => env('EXPENSE_CLASSIFICATION_MODEL', 'gpt-4o-mini'),
        'timeout' => (int) env('EXPENSE_CLASSIFICATION_TIMEOUT', 15),
        'tries' => (int) env('EXPENSE_CLASSIFICATION_TRIES', 3),
        'queue' => env('EXPENSE_CLASSIFICATION_QUEUE', 'expense-classification'),
    ],
];
