<?php

declare(strict_types=1);

namespace App\Expense\Domain\Enums;

enum ExpenseCategoryEnum: string
{
    case Food = 'food';
    case Health = 'health';
    case Housing = 'housing';
    case Leisure = 'leisure';
    case Shopping = 'shopping';
    case Services = 'services';
    case Transport = 'transport';
    case Education = 'education';
    case Subscriptions = 'subscriptions';
    case Other = 'other';
}
