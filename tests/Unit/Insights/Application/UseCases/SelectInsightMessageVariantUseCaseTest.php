<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Insights\Application\Data\SelectInsightMessageVariantInput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Application\UseCases\SelectInsightMessageVariantUseCase;
use Tests\Support\Core\Fixtures\UuidFixture;

it('preserves the same variant within the day and visits every variant before repeating', function (int $variantCount, string $firstDay): void {
    $useCase = new SelectInsightMessageVariantUseCase;
    $day = new DateTimeImmutable($firstDay, new DateTimeZone('UTC'));
    $variants = [];

    for ($index = 0; $index <= $variantCount; $index++) {
        $input = new SelectInsightMessageVariantInput(userId: UuidFixture::at(15), editorialKey: 'v1|category_concentration|food|2026-10', referenceDate: $day->format('Y-m-d'), variantCount: $variantCount);
        $variant = $useCase->execute($input);
        expect($variant)->toBe($useCase->execute($input))
            ->toBe($useCase->execute(new SelectInsightMessageVariantInput(userId: strtoupper(UuidFixture::at(15)), editorialKey: $input->editorialKey, referenceDate: $input->referenceDate, variantCount: $variantCount)))
            ->toBeGreaterThanOrEqual(0)->toBeLessThan($variantCount);
        $variants[] = $variant;
        $day = $day->modify('+1 day');
    }

    expect(count(array_unique(array_slice($variants, 0, $variantCount))))->toBe($variantCount)
        ->and($variants[$variantCount])->toBe($variants[0]);
})->with([
    [4, '2026-10-12'],
    [6, '2026-10-12'],
    [4, '2019-12-29'],
    [4, '2024-02-27'],
    [4, '2026-12-30'],
]);

it('distributes stable offsets across accounts and editorial keys', function (): void {
    $keys = [];
    $accounts = [];
    $useCase = new SelectInsightMessageVariantUseCase;

    for ($index = 1; $index <= 32; $index++) {
        $accounts[] = $useCase->execute(new SelectInsightMessageVariantInput(userId: UuidFixture::at($index), editorialKey: 'v1|food|2026-10', referenceDate: '2026-10-12', variantCount: 4));
        $keys[] = $useCase->execute(new SelectInsightMessageVariantInput(userId: UuidFixture::at(1), editorialKey: "v1|subject-{$index}|2026-10", referenceDate: '2026-10-12', variantCount: 4));
    }

    expect(count(array_unique($accounts)))->toBeGreaterThan(1)
        ->and(count(array_unique($keys)))->toBeGreaterThan(1);
});

it('counts civil days independently of the process timezone', function (): void {
    $original = date_default_timezone_get();
    $input = new SelectInsightMessageVariantInput(userId: UuidFixture::at(1), editorialKey: 'v1|food|2026-03', referenceDate: '2026-03-09', variantCount: 4);
    $useCase = new SelectInsightMessageVariantUseCase;

    try {
        date_default_timezone_set('America/New_York');
        $first = $useCase->execute($input);
        date_default_timezone_set('Pacific/Auckland');
        expect($useCase->execute($input))->toBe($first);
    } finally {
        date_default_timezone_set($original);
    }
});

it('rejects invalid rotation inputs', function (string $key, int $count): void {
    (new SelectInsightMessageVariantUseCase)->execute(new SelectInsightMessageVariantInput(userId: UuidFixture::at(1), editorialKey: $key, referenceDate: '2026-10-12', variantCount: $count));
})->with([['', 4], ['v1|food', 3], ['v1|food', 0]])
    ->throws(InsightMessageCompositionException::class);

it('rejects invalid rotation owners without coercion', function (string $id): void {
    (new SelectInsightMessageVariantUseCase)->execute(new SelectInsightMessageVariantInput(userId: $id, editorialKey: 'v1|food', referenceDate: '2026-10-12', variantCount: 4));
})->with(['0', '-1', '017f22e2-79b0-4cc3-98c4-000000000001'])->throws(InvalidUuidException::class);

it('rejects noncanonical or impossible reference dates', function (string $date): void {
    (new SelectInsightMessageVariantUseCase)->execute(new SelectInsightMessageVariantInput(userId: UuidFixture::at(1), editorialKey: 'v1|food', referenceDate: $date, variantCount: 4));
})->with(['2026-02-29', '2026-10-1', 'tomorrow'])
    ->throws(InvalidDatePeriodException::class);
