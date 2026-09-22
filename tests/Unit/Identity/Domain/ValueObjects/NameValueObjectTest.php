<?php

declare(strict_types=1);

use App\Identity\Domain\Exceptions\InvalidNameException;
use App\Identity\Domain\ValueObjects\NameValueObject;

it('trims and collapses whitespace', function (): void {
    $name = NameValueObject::fromString(value: "  Maria\t \nSilva  ");

    expect($name->value())->toBe('Maria Silva');
});

it('accepts Unicode letters', function (): void {
    expect(NameValueObject::fromString(value: 'João Çé')->value())->toBe('João Çé');
});

it('compares names by normalized value', function (): void {
    $name = NameValueObject::fromString(value: ' Maria   Silva ');

    expect($name->equals(NameValueObject::fromString(value: 'Maria Silva')))->toBeTrue()
        ->and($name->equals(NameValueObject::fromString(value: 'João Silva')))->toBeFalse();
});

it('requires at least two letters', function (): void {
    expect(NameValueObject::fromString(value: 'Al')->value())->toBe('Al')
        ->and(fn (): NameValueObject => NameValueObject::fromString(value: 'A'))
        ->toThrow(InvalidNameException::class, 'O nome do usuário deve conter pelo menos 2 letras.');
});

it('allows at most twelve letters', function (): void {
    expect(NameValueObject::fromString(value: str_repeat('a', 12))->value())->toBe(str_repeat('a', 12))
        ->and(fn (): NameValueObject => NameValueObject::fromString(value: str_repeat('a', 13)))
        ->toThrow(InvalidNameException::class, 'O nome do usuário não pode exceder 12 letras.');
});

it('rejects characters other than letters and spaces', function (string $name): void {
    NameValueObject::fromString(value: $name);
})->with([
    'number' => 'Maria2',
    'hyphen' => 'Maria-Silva',
    'punctuation' => 'Maria.Silva',
])->throws(InvalidNameException::class, 'O nome do usuário deve conter apenas letras e espaços.');

it('rejects empty input', function (string $name): void {
    NameValueObject::fromString(value: $name);
})->with([
    'empty string' => '',
    'whitespace' => " \t\n ",
])->throws(InvalidNameException::class, 'O nome do usuário não pode ser vazio.');
