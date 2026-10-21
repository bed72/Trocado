<?php

declare(strict_types=1);

namespace App\Identity\Infrastructure\Repositories\Persistence;

use App\Identity\Application\Data\Output\PasswordRecoveryEmissionOutput;
use App\Identity\Application\Repositories\PasswordRecoveryRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Domain\ValueObjects\EmailValueObject;
use App\Identity\Infrastructure\Repositories\Persistence\Models\UserModel;
use Illuminate\Auth\Passwords\DatabaseTokenRepository;
use Illuminate\Auth\Passwords\PasswordBrokerManager;
use Illuminate\Contracts\Config\Repository;
use Illuminate\Contracts\Database\ConcurrencyErrorDetector;
use Illuminate\Database\DeadlockException;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Date;
use LogicException;
use RuntimeException;

use function is_string;

final readonly class EloquentPasswordRecoveryRepository implements PasswordRecoveryRepository
{
    public function __construct(
        private Repository $repository,
        private PasswordBrokerManager $manager,
        private ConcurrencyErrorDetector $detector,
    ) {}

    public function issue(EmailValueObject $email): ?PasswordRecoveryEmissionOutput
    {
        $query = UserModel::query();
        $connection = $query->getConnection();
        $tokens = $this->manager->broker('users')->getRepository();

        if (! $tokens instanceof DatabaseTokenRepository || $tokens->getConnection() !== $connection) {
            throw new LogicException('A recuperação exige a mesma conexão de persistência da conta.');
        }

        if ($connection->transactionLevel() === 0) {
            throw new LogicException('A emissão de recuperação exige uma transação ativa.');
        }

        try {
            $user = $query->where('email', $email->value())->lockForUpdate()->first();

            if ($user === null || $user->status !== UserStatusEnum::Active || ! $user->hasVerifiedEmail()) {
                return null;
            }

            $record = $connection->table($this->repository->get('auth.passwords.users.table'))
                ->where('email', $user->email)->lockForUpdate()->first();
            $reference = Date::now();

            if ($record !== null) {
                if (! is_string($record->created_at) || $record->created_at === '') {
                    throw new RuntimeException('O estado de recuperação de senha é inválido.');
                }

                if (Date::parse($record->created_at)
                    ->addSeconds($this->repository->get('auth.passwords.users.throttle'))
                    ->greaterThan($reference)) {
                    return new PasswordRecoveryEmissionOutput(userId: $user->getKey(), token: null);
                }
            }

            return new PasswordRecoveryEmissionOutput(userId: $user->getKey(), token: $tokens->create($user));
        } catch (QueryException $exception) {
            if ($this->detector->causedByConcurrencyError($exception)) {
                throw new DeadlockException('Não foi possível persistir a recuperação de senha.', 40001);
            }

            throw new RuntimeException('Não foi possível persistir a recuperação de senha.');
        }
    }
}
