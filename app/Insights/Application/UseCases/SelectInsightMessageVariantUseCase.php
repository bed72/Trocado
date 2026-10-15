<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Core\Domain\ValueObjects\UuidValueObject;
use App\Insights\Application\Data\SelectInsightMessageVariantInput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use DateTimeImmutable;
use DateTimeZone;

final readonly class SelectInsightMessageVariantUseCase
{
    public function execute(SelectInsightMessageVariantInput $input): int
    {
        $userId = UuidValueObject::fromString($input->userId)->value();
        if ($input->editorialKey === '' || $input->variantCount < 4) {
            throw new InsightMessageCompositionException('A rotação exige conta, chave editorial e pelo menos quatro variantes.');
        }

        DatePeriodValueObject::fromDates($input->referenceDate, $input->referenceDate);
        $timezone = new DateTimeZone('UTC');
        $epoch = new DateTimeImmutable('2020-01-01', $timezone);
        $reference = new DateTimeImmutable($input->referenceDate, $timezone);
        $day = (int) $epoch->diff($reference)->format('%r%a');
        $hash = hash('sha256', "{$userId}|{$input->editorialKey}");
        $offset = (int) hexdec(substr($hash, 0, 8));

        return (($offset % $input->variantCount) + ($day % $input->variantCount) + $input->variantCount) % $input->variantCount;
    }
}
