<?php

declare(strict_types=1);

namespace App\Expense\Infrastructure\Adapters;

use App\Core\Domain\Exceptions\InvalidDatePeriodException;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Expense\Application\Data\ExpenseCursorOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Application\Ports\ExpenseQueryCursorPort;

use function is_array;
use function is_bool;
use function is_int;
use function is_string;
use function strlen;

final class ExpenseQueryCursorAdapter implements ExpenseQueryCursorPort
{
    public function fingerprint(GetAllExpenseInput $input): string
    {
        $categories = array_values(array_unique($input->categories));
        sort($categories, SORT_STRING);

        return hash('sha256', json_encode([$input->from, $input->to, $categories, $input->amountMin, $input->amountMax, $input->sorts], JSON_THROW_ON_ERROR));
    }

    public function encode(GetAllExpenseInput $input, ExpenseCursorOutput $cursor): string
    {
        return $this->encodePayload(['v' => 2, 'query' => $this->fingerprint($input), 'position' => $cursor->position, 'forward' => $cursor->forward]);
    }

    private function encodePayload(array $payload): string
    {
        return rtrim(strtr(base64_encode(json_encode($payload, JSON_THROW_ON_ERROR)), '+/', '-_'), '=');
    }

    private function isCivilDate(mixed $value): bool
    {
        if (! is_string($value)) {
            return false;
        }

        try {
            DatePeriodValueObject::fromDates($value, $value);

            return true;
        } catch (InvalidDatePeriodException) {
            return false;
        }
    }

    public function decode(GetAllExpenseInput $input): ?ExpenseCursorOutput
    {
        if ($input->cursor === null) {
            return null;
        }

        $encoded = $input->cursor;
        if (strlen($encoded) > 4096 || preg_match('/\A[A-Za-z0-9_-]+\z/D', $encoded) !== 1) {
            throw new InvalidExpenseCursorException;
        }
        $json = base64_decode(strtr($encoded, '-_', '+/'), true);
        $payload = $json === false ? null : json_decode($json, true);

        if (! is_array($payload) || $this->encodePayload($payload) !== $encoded) {
            throw new InvalidExpenseCursorException;
        }

        if (array_keys($payload) !== ['v', 'query', 'position', 'forward'] || $payload['v'] !== 2
            || $payload['query'] !== $this->fingerprint($input)) {
            throw new InvalidExpenseCursorException;
        }

        $forward = $payload['forward'];
        $position = $payload['position'];

        $fields = [...array_map(static fn (string $sort): string => ltrim($sort, '-'), $input->sorts), 'id'];

        if (! is_array($position) || array_keys($position) !== $fields || ! is_bool($forward)) {
            throw new InvalidExpenseCursorException;
        }

        foreach ($position as $field => $value) {
            $valid = match ($field) {
                'id' => is_string($value),
                'amount' => is_int($value) && $value > 0,
                'occurred_on' => $this->isCivilDate($value),
                'description' => is_string($value) && mb_check_encoding($value, 'UTF-8') && mb_strlen($value, 'UTF-8') <= 64,
                default => false,
            };

            if (! $valid) {
                throw new InvalidExpenseCursorException;
            }
        }

        try {
            $position['id'] = UuidValueObject::fromString($position['id'])->value();
        } catch (InvalidUuidException) {
            throw new InvalidExpenseCursorException;
        }

        return new ExpenseCursorOutput(position: $position, forward: $forward);
    }
}
