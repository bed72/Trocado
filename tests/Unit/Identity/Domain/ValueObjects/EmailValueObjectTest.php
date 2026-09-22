<?php

declare(strict_types=1);

use App\Identity\Domain\Exceptions\InvalidEmailException;
use App\Identity\Domain\ValueObjects\EmailValueObject;

it('normalizes and compares email addresses by canonical value', function (): void {
    $email = EmailValueObject::fromString(value: '  Maria.Silva@Example.COM  ');

    expect($email->value())->toBe('maria.silva@example.com')
        ->and($email->equals(EmailValueObject::fromString(value: 'MARIA.SILVA@example.com')))->toBeTrue()
        ->and($email->equals(EmailValueObject::fromString(value: 'outra@example.com')))->toBeFalse();
});

it('rejects invalid email addresses', function (string $email): void {
    EmailValueObject::fromString(value: $email);
})->with([
    'empty' => '',
    'spaces' => '   ',
    'without at sign' => 'maria.example.com',
    'without domain' => 'maria@',
])->throws(InvalidEmailException::class, 'O e-mail informado é inválido.');
