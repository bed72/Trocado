<?php

declare(strict_types=1);

namespace App\User\Domain\Entities;

use App\User\Domain\Exceptions\InvalidUserNameException;
use App\User\Domain\ValueObjects\EmailValueObject;
use DateTimeImmutable;

final readonly class UserEntity
{
    public string $name;

    public function __construct(
        string $name,
        public ?int $id,
        public EmailValueObject $email,
        public ?DateTimeImmutable $createdAt = null,
        public ?DateTimeImmutable $updatedAt = null,
    ) {
        $normalizedName = trim($name);

        if ($normalizedName === '') {
            throw new InvalidUserNameException(message: 'O nome do usuário não pode ser vazio.');
        }

        if (mb_strlen($normalizedName) > 255) {
            throw new InvalidUserNameException(message: 'O nome do usuário não pode exceder 255 caracteres.');
        }

        $this->name = $normalizedName;
    }
}
