<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;
use Normalizer;

final readonly class InsightMessageValueObject
{
    public string $title;

    public string $description;

    public function __construct(string $title, string $description)
    {
        $this->title = $this->normalize($title);
        $this->description = $this->normalize($description);

        $titleLength = grapheme_strlen($this->title);
        $length = grapheme_strlen("{$this->title} {$this->description}");

        if ($this->title === '' || $this->description === '' || $titleLength === false || $length === false
            || $titleLength > 24 || $length > 80) {
            throw new InvalidInsightAnalysisException('O par editorial excede o orçamento ou não é texto válido.');
        }
    }

    public function comparisonKey(): string
    {
        $text = Normalizer::normalize("{$this->title} {$this->description}", Normalizer::FORM_C);

        $text = preg_replace('/[\x{FE00}-\x{FE0F}\x{E0100}-\x{E01EF}]/u', '', $text);
        $text = preg_replace('/[^\p{L}\p{M}\p{N}]+/u', ' ', mb_strtolower($text, 'UTF-8'));

        return trim($text);
    }

    private function normalize(string $text): string
    {
        $normalized = preg_replace('/[\s\p{Z}]+/u', ' ', $text);

        if ($normalized === null) {
            throw new InvalidInsightAnalysisException('O par editorial não é texto Unicode válido.');
        }

        return trim($normalized);
    }
}
