<?php

declare(strict_types=1);

return [
    'classification' => [
        'tries' => 3,
        'timeout' => 15,
        'job_timeout' => 25,
        'api_key' => env('EXPENSE_CLASSIFICATION_API_KEY'),
        'model' => env('EXPENSE_CLASSIFICATION_MODEL', 'gpt-4o-mini'),
        'provider' => env('EXPENSE_CLASSIFICATION_PROVIDER', 'openai'),
        'queue' => env('EXPENSE_CLASSIFICATION_QUEUE', 'expense-classification'),
    ],
];
