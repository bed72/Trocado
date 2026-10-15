<?php

declare(strict_types=1);

use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Identity\Application\Repositories\UserRepository;
use App\Identity\Domain\Entities\UserEntity;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Domain\ValueObjects\NameValueObject;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

it('generates a v7 identity and maps create read and update without numeric casts or credentials', function (): void {
    $repository = app(UserRepository::class);
    $created = $repository->create(new UserEntity(null, NameValueObject::fromString('Maria'), EmailValueObject::fromString('maria@example.com')), 'Correct1');
    expect($created->id)->toMatch('/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/')
        ->and($created->status)->toBe(UserStatusEnum::Pending)
        ->and(Hash::check('Correct1', DB::table('users')->value('password')))->toBeTrue()
        ->and($repository->getById(strtoupper($created->id))?->id)->toBe($created->id);
    $updated = $repository->update(new UserEntity($created->id, NameValueObject::fromString('Maria Silva'), $created->email, avatar: 'https://example.com/avatar'));
    expect($updated->id)->toBe($created->id)->and($updated->name->value())->toBe('Maria Silva')
        ->and($updated->avatar)->toBe('https://example.com/avatar')->and(DB::table('users')->count())->toBe(1);
});

it('refuses malformed direct repository identifiers before SQL', function (string $operation): void {
    $repository = app(UserRepository::class);
    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        expect(fn () => $operation === 'read' ? $repository->getById('42') : $repository->delete('42'))->toThrow(InvalidUuidException::class);
        expect(DB::getQueryLog())->toBe([]);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
})->with(['read', 'delete']);
