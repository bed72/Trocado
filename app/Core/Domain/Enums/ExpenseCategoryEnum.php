<?php

declare(strict_types=1);

namespace App\Core\Domain\Enums;

enum ExpenseCategoryEnum: string
{
    case Food = 'food';
    case Pets = 'pets';
    case Taxes = 'taxes';
    case Health = 'health';
    case Travel = 'travel';
    case Housing = 'housing';
    case Leisure = 'leisure';
    case Shopping = 'shopping';
    case Services = 'services';
    case Transport = 'transport';
    case Education = 'education';
    case Financing = 'financing';
    case Insurance = 'insurance';
    case Investments = 'investments';
    case PersonalCare = 'personal_care';
    case Subscriptions = 'subscriptions';
    case GiftsAndDonations = 'gifts_and_donations';
    case Other = 'other';
}
