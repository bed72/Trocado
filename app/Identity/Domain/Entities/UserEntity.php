<?php

declare(strict_types=1);

namespace App\Identity\Domain\Entities;

use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use DateTimeImmutable;

final readonly class UserEntity
{
    public function __construct(
        public ?int $id,
        public NameValueObject $name,
        public EmailValueObject $email,
        public ?DateTimeImmutable $createdAt = null,
        public ?DateTimeImmutable $updatedAt = null,
    ) {}
}
