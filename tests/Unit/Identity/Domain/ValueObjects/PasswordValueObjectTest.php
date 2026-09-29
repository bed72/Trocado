<?php

declare(strict_types=1);

use App\Identity\Domain\Exceptions\InvalidPasswordException;
use App\Identity\Domain\ValueObjects\PasswordValueObject;

it('preserves valid passwords exactly', function (string $password): void {
    expect(PasswordValueObject::fromString(value: $password)->value())->toBe($password);
})->with([
    'external spaces' => [' Abc123 '],
    'six characters' => ['Abc123'],
    'twelve characters' => ['Password1234'],
    'thirty-two characters' => ['ABCDEFGHIJKLMNOPQRSTUVWXYZ123456'],
    'seventy-two bytes with multibyte characters' => [str_repeat('界', 20).'A12345678901'],
    'multibyte uppercase letter' => ['Ábc123'],
]);

it('rejects passwords outside the policy', function (string $password): void {
    PasswordValueObject::fromString(value: $password);
})->with([
    'fewer than six characters' => ['Abc12'],
    'more than thirty-two characters' => ['ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567'],
    'more than seventy-two bytes with thirty-two characters' => [str_repeat('界', 21).'A1234567890'],
    'without uppercase letter' => ['password1'],
    'without number' => ['Password'],
])->throws(InvalidPasswordException::class);
