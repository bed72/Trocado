<?php

declare(strict_types=1);

use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Identity\Domain\Enums\UserStatusEnum;
use App\Identity\Infrastructure\Repositories\Persistence\Models\PersonalAccessTokenModel as PersonalAccessToken;
use App\Insights\Application\Data\ExpenseAnalysisOutput;
use App\Insights\Application\Data\ExpenseCategoryAnalysisOutput;
use App\Insights\Application\Data\ExpensePeriodAnalysisOutput;
use App\Insights\Application\Exceptions\InsightMessageCompositionException;
use App\Insights\Application\Repositories\ExpenseAnalysisRepository;
use App\Insights\Application\UseCases\ComposeInsightMessageUseCase;
use App\Insights\Application\UseCases\GenerateInsightCandidatesUseCase;
use App\Insights\Application\UseCases\SelectInsightCandidatesUseCase;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightAnalysisPeriodValueObject;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\Exceptions;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    Date::setTestNow('2026-10-12 12:00:00 UTC');
});

afterEach(function (): void {
    Date::setTestNow();
});

it('returns no partial insights or successful onboarding when composition fails after a valid comparison', function (bool $closed): void {
    $user = IdentityFixture::create(status: UserStatusEnum::Active, verifiedAt: now());
    $token = IdentityFixture::token($user, expiresAt: now()->addDays(30));
    $record = PersonalAccessToken::findToken($token);
    $originalExpiry = $record->expires_at;
    Date::setTestNow('2026-10-28 12:00:00 UTC');
    $period = new InsightAnalysisPeriodValueObject('2026-10-28', DatePeriodValueObject::monthContaining($closed ? '2026-09-01' : '2026-10-01'));
    $current = new ExpensePeriodAnalysisOutput(
        period: $period->currentMonth, expenseCount: 5, distinctDateCount: 3, totalAmount: '30000',
        largestExpenseAmount: '20000', largestExpenseCategory: 'unmapped',
        largestExpenseDescription: 'Descrição privada', largestExpenseOccurredOn: $period->currentMonth->from(),
        categories: [new ExpenseCategoryAnalysisOutput('unmapped', '25000'), new ExpenseCategoryAnalysisOutput('food', '5000')],
    );
    $previous = new ExpensePeriodAnalysisOutput(
        period: $period->previousMonth, expenseCount: 5, distinctDateCount: 3, totalAmount: '20000',
        largestExpenseAmount: '4000', largestExpenseCategory: 'food', largestExpenseOccurredOn: $period->previousMonth->from(),
        categories: [new ExpenseCategoryAnalysisOutput('food', '20000')],
    );
    $analysis = new ExpenseAnalysisOutput(
        mode: $period->mode, hasHistoricalExpenses: true, currentMonth: $current, previousMonth: $previous,
        twoMonthsAgo: new ExpensePeriodAnalysisOutput(
            period: $period->twoMonthsAgo, expenseCount: 0, distinctDateCount: 0,
            totalAmount: '0', largestExpenseAmount: '0', largestExpenseCategory: null, categories: [],
        ),
        currentComparison: new ExpensePeriodAnalysisOutput(
            period: $period->currentComparison, expenseCount: 5, distinctDateCount: 3, totalAmount: '30000',
            largestExpenseAmount: '20000', largestExpenseCategory: 'unmapped', largestExpenseOccurredOn: $period->currentComparison->from(),
            categories: $current->categories,
        ),
        previousComparison: new ExpensePeriodAnalysisOutput(
            period: $period->previousComparison, expenseCount: 5, distinctDateCount: 3, totalAmount: '20000',
            largestExpenseAmount: '4000', largestExpenseCategory: 'food', largestExpenseOccurredOn: $period->previousComparison->from(),
            categories: $previous->categories,
        ),
    );
    $candidates = (new SelectInsightCandidatesUseCase)->execute((new GenerateInsightCandidatesUseCase)->execute($analysis));
    expect($candidates)->toHaveCount(2)
        ->and($candidates[0]->type)->toBe(InsightTypeEnum::RegisteredAmountIncrease)
        ->and($candidates[1]->type)->toBe(InsightTypeEnum::CategoryConcentration);
    expect($this->app->make(ComposeInsightMessageUseCase::class)->execute($user->getKey(), $candidates[0], '2026-10-28')->description)->toContain('+50%');

    $repository = $this->createMock(ExpenseAnalysisRepository::class);
    $repository->expects($this->once())->method('analyze')->with($user->getKey(), $period)->willReturn($analysis);
    $this->app->instance(ExpenseAnalysisRepository::class, $repository);
    $handler = Exceptions::getFacadeRoot();
    Exceptions::fake();
    try {
        $this->withToken($token)->getJson(route('insights.index').($closed ? '?filter[year]=2026&filter[month]=9' : '?filter[year]=2026&filter[month]=10'))
            ->assertStatus(500)->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertExactJson(['errors' => [[
                'status' => '500', 'title' => 'Erro interno do servidor', 'detail' => 'Não foi possível processar a solicitação.',
            ]]])->assertJsonMissingPath('data');
        Exceptions::assertReported(static fn (InsightMessageCompositionException $exception): bool => $exception->getMessage() === 'A categoria não possui um rótulo editorial aprovado.');
        Exceptions::assertReportedCount(1);
        expect($record->fresh()->expires_at->equalTo($originalExpiry))->toBeTrue();
    } finally {
        Exceptions::swap($handler);
    }
})->with(['explicit current' => false, 'closed' => true]);
