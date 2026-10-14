<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\UuidValueObject;
use Tests\Support\Core\Fixtures\UuidFixture;

it('provides distinct deterministic UUIDv7 fixtures with explicit lexical ordering', function (): void {
    $higher = UuidFixture::at(16);
    $lower = UuidFixture::at(1);
    $middle = UuidFixture::at(15);

    expect($lower)->toBe('017f22e2-79b0-7cc3-98c4-000000000001')
        ->and($middle)->toBe('017f22e2-79b0-7cc3-98c4-00000000000f')
        ->and($higher)->toBe('017f22e2-79b0-7cc3-98c4-000000000010')
        ->and(UuidFixture::at(1))->toBe($lower);

    $ids = [$higher, $lower, $middle];
    sort($ids, SORT_STRING);

    expect($ids)->toBe([$lower, $middle, $higher])
        ->and(count(array_unique($ids)))->toBe(3);

    foreach ($ids as $id) {
        expect(UuidValueObject::fromString($id)->value())->toBe($id);
    }
});

it('keeps the explicit fixture index at both boundaries', function (): void {
    expect(UuidFixture::at(0))->toBe('017f22e2-79b0-7cc3-98c4-000000000000')
        ->and(UuidFixture::at(0xFFFFFFFFFFFF))->toBe('017f22e2-79b0-7cc3-98c4-ffffffffffff');
});

it('rejects out of range fixture indexes instead of wrapping them', function (int $index): void {
    UuidFixture::at($index);
})->with([-1, 0x1000000000000])->throws(InvalidArgumentException::class);
