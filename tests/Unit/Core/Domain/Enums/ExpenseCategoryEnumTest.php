<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;

it('preserves the existing cases and adds exactly the eight specified categories', function (): void {
    expect(array_column(ExpenseCategoryEnum::cases(), 'value', 'name'))->toEqual([
        'Food' => 'food',
        'Health' => 'health',
        'Housing' => 'housing',
        'Leisure' => 'leisure',
        'Shopping' => 'shopping',
        'Services' => 'services',
        'Transport' => 'transport',
        'Education' => 'education',
        'Subscriptions' => 'subscriptions',
        'Financing' => 'financing',
        'Investments' => 'investments',
        'Taxes' => 'taxes',
        'Insurance' => 'insurance',
        'PersonalCare' => 'personal_care',
        'Pets' => 'pets',
        'GiftsAndDonations' => 'gifts_and_donations',
        'Travel' => 'travel',
        'Other' => 'other',
    ]);
});
