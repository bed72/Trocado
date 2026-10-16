<?php

declare(strict_types=1);

namespace App\Expense\Presentation\Http\Rules;

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

use function is_string;

final class ExpenseCategoriesRule implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        foreach (explode(',', $value) as $category) {
            if (ExpenseCategoryEnum::tryFrom($category) === null) {
                $fail('Informe categorias válidas separadas por vírgula.');

                return;
            }
        }
    }
}
