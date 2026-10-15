<?php

declare(strict_types=1);

namespace App\Identity\Domain\Entities;

use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\Exceptions\InvalidAvatarException;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use DateTimeImmutable;

final readonly class UserEntity
{
    public ?string $id;

    public function __construct(
        ?string $id,
        public NameValueObject $name,
        public EmailValueObject $email,
        public ?string $avatar = null,
        public ?DateTimeImmutable $createdAt = null,
        public ?DateTimeImmutable $updatedAt = null,
        public UserStatusEnum $status = UserStatusEnum::Pending,
    ) {
        $this->id = $id === null ? null : UuidValueObject::fromString($id)->value();
        if ($avatar !== null && mb_strlen($avatar, 'UTF-8') > 2048) {
            throw new InvalidAvatarException(message: 'O avatar deve conter até 2048 caracteres.');
        }
    }
}
