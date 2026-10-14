<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\UuidValueObject;

it('preserves UUIDv7 values with every RFC variant prefix and canonicalizes only case', function (string $raw, string $canonical): void {
    expect(UuidValueObject::fromString($raw)->value())->toBe($canonical);
})->with([
    'variant 8' => ['017f22e2-79b0-7cc3-88c4-dc0c0c07398f', '017f22e2-79b0-7cc3-88c4-dc0c0c07398f'],
    'variant 9' => ['017F22E2-79B0-7CC3-98C4-DC0C0C07398F', '017f22e2-79b0-7cc3-98c4-dc0c0c07398f'],
    'variant a' => ['017f22E2-79b0-7Cc3-A8c4-dC0c0c07398f', '017f22e2-79b0-7cc3-a8c4-dc0c0c07398f'],
    'variant b' => ['017f22e2-79b0-7cc3-b8c4-dc0c0c07398f', '017f22e2-79b0-7cc3-b8c4-dc0c0c07398f'],
    'minimum bits' => ['00000000-0000-7000-8000-000000000000', '00000000-0000-7000-8000-000000000000'],
    'maximum bits' => ['ffffffff-ffff-7fff-bfff-ffffffffffff', 'ffffffff-ffff-7fff-bfff-ffffffffffff'],
]);

it('compares identity by canonical value without changing either operand', function (): void {
    $uuid = UuidValueObject::fromString('017f22e2-79b0-7cc3-98c4-dc0c0c07398f');
    $equivalent = UuidValueObject::fromString('017F22E2-79B0-7CC3-98C4-DC0C0C07398F');
    $different = UuidValueObject::fromString('017f22e2-79b0-7cc3-98c4-dc0c0c073990');

    expect($uuid->equals($uuid))->toBeTrue()
        ->and($uuid->equals($equivalent))->toBeTrue()
        ->and($equivalent->equals($uuid))->toBeTrue()
        ->and($uuid->equals($different))->toBeFalse()
        ->and($different->equals($uuid))->toBeFalse()
        ->and($uuid->value())->toBe('017f22e2-79b0-7cc3-98c4-dc0c0c07398f')
        ->and($equivalent->value())->toBe('017f22e2-79b0-7cc3-98c4-dc0c0c07398f');
});

it('rejects legacy and malformed strings without repairing them', function (string $raw): void {
    UuidValueObject::fromString($raw);
})->with([
    'v1' => '017f22e2-79b0-1cc3-98c4-dc0c0c07398f',
    'v4' => '017f22e2-79b0-4cc3-98c4-dc0c0c07398f',
    'v6' => '017f22e2-79b0-6cc3-98c4-dc0c0c07398f',
    'v8' => '017f22e2-79b0-8cc3-98c4-dc0c0c07398f',
    'nil' => '00000000-0000-0000-0000-000000000000',
    'max UUID' => 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'NCS variant' => '017f22e2-79b0-7cc3-78c4-dc0c0c07398f',
    'Microsoft variant' => '017f22e2-79b0-7cc3-c8c4-dc0c0c07398f',
    'reserved variant' => '017f22e2-79b0-7cc3-f8c4-dc0c0c07398f',
    'SHA-256' => 'c4d9b3f0f16f601d9164f7ec1ebcf8bc21f13311fe4bc842194939a109ca6cc4',
    'numeric string' => '42',
    'zero' => '0',
    'empty' => '',
    'whitespace' => ' ',
    'leading space' => ' 017f22e2-79b0-7cc3-98c4-dc0c0c07398f',
    'trailing space' => '017f22e2-79b0-7cc3-98c4-dc0c0c07398f ',
    'trailing newline' => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f\n",
    'leading tab' => "\t017f22e2-79b0-7cc3-98c4-dc0c0c07398f",
    'embedded space' => '017f22e2-79b0-7cc3-98c4-dc0c0c07398 ',
    'trailing NUL' => "017f22e2-79b0-7cc3-98c4-dc0c0c07398f\0",
    'non-hex' => '017f22e2-79b0-7cc3-98c4-dc0c0c07398g',
    'no hyphens' => '017f22e279b07cc398c4dc0c0c07398f',
    'short' => '017f22e2-79b0-7cc3-98c4-dc0c0c07398',
    'long' => '017f22e2-79b0-7cc3-98c4-dc0c0c07398ff',
    'braces' => '{017f22e2-79b0-7cc3-98c4-dc0c0c07398f}',
    'URN' => 'urn:uuid:017f22e2-79b0-7cc3-98c4-dc0c0c07398f',
])->throws(InvalidUuidException::class);

it('rejects non-string identities and absence instead of creating an empty identity', function (mixed $raw): void {
    UuidValueObject::fromString($raw);
})->with([
    'integer' => [42],
    'float' => [42.0],
    'boolean' => [false],
    'null' => [null],
    'array' => [[]],
])->throws(TypeError::class);

it('does not disclose the rejected input in the invariant error', function (): void {
    expect(fn () => UuidValueObject::fromString('private-invalid-identifier'))
        ->toThrow(InvalidUuidException::class, 'O identificador deve ser um UUIDv7 textual com variante RFC 9562.');
});
