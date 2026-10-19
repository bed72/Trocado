<?php

declare(strict_types=1);

use App\Expense\Application\Exceptions\ExpenseNotFoundException;
use App\Expense\Application\Exceptions\ExpenseOwnerNotFoundException;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use Illuminate\Contracts\Debug\ExceptionHandler;
use Illuminate\Support\Facades\Route;
use Throwable as ThrowableContract;

it('preserves the exact Expense translation and report policy inside and outside the API', function (ThrowableContract $exception, int $status, string $title, string $detail, ?string $pointer, bool $reported, string $path): void {
    Route::get($path, static fn () => throw $exception);
    $error = ['title' => $title, 'detail' => $detail, 'status' => (string) $status];
    if ($pointer !== null) {
        $error['source'] = ['pointer' => $pointer];
    }

    $this->get($path, ['Accept' => 'text/html'])->assertStatus($status)
        ->assertHeader('Content-Type', 'application/vnd.api+json')->assertExactJson(['errors' => [$error]]);
    expect($this->app->make(ExceptionHandler::class)->shouldReport($exception))->toBe($reported);
})->with([
    'missing expense' => [new ExpenseNotFoundException, 404, 'Despesa não encontrada', 'Despesa não encontrada.', null, true],
    'missing owner' => [new ExpenseOwnerNotFoundException, 404, 'User não encontrado', 'A identidade proprietária da despesa não existe.', null, true],
    'invalid expense' => [new InvalidExpenseException('Despesa de caracterização.'), 422, 'Dados inválidos', 'Despesa de caracterização.', null, true],
    'cursor pointer not parameter' => [new InvalidExpenseCursorException, 422, 'Cursor inválido', 'O cursor da página é inválido ou incompatível com a consulta.', '/page/cursor', false],
])->with(['api' => '/api/expense-error-probe', 'non-api' => '/expense-error-probe']);
