<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageTemplateOutput;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightPeriodModeEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightMessageTemplatesUseCase
{
    public const string Version = 'v6-monetary-editorial';

    /** @return list<InsightMessageTemplateOutput> */
    public function execute(InsightCandidateValueObject $candidate): array
    {
        $current = $candidate->mode === InsightPeriodModeEnum::Current;
        $pairs = match ($candidate->type) {
            InsightTypeEnum::CategoryConcentration => [
                ['{amount} em {month}; lidera nos registros.', '{amount}; categoria líder.'],
                ['Maior categoria em {month}: {amount}.', 'Categoria líder: {amount}.'],
                ['{amount} registrados em {month}; categoria líder.', '{amount}; maior categoria.'],
                ['Em {month}, {amount}; maior total por categoria.', 'Maior total por categoria: {amount}.'],
            ],
            InsightTypeEnum::CategoryLeadStreak => [
                ['{amount} em {month}; lidera pelo terceiro mês.', '{amount}; líder por 3 meses.'],
                ['{amount} em {month}; terceiro mês na liderança.', '3º mês na liderança: {amount}.'],
                ['Terceiro mês como líder: {amount} em {month}.', '{amount}; 3ª liderança seguida.'],
                ['Em {month}, {amount}; terceira liderança seguida.', '3 meses como líder: {amount}.'],
            ],
            InsightTypeEnum::ExpenseConcentration => [
                ['{amount} em {month}; maior lançamento.', 'Maior em {expense_date}: {amount}.'],
                ['Maior lançamento em {month}: {amount}.', '{expense_date}: {amount}; maior registro.'],
                ['Em {month}, {amount}; maior lançamento.', '{amount}; maior em {expense_date}.'],
                ['{amount}; maior registro de {month}.', 'Maior: {amount} em {expense_date}.'],
            ],
            InsightTypeEnum::CategoryReview => [
                ['{amount} em {month}. Vale revisar as categorias.', '{amount}. Vale revisar as categorias.'],
                ['{amount} em {month}; confira as categorias.', '{amount}; confira as categorias.'],
                ['Em {month}, {amount}. Vale rever as categorias.', '{amount}. Vale rever as categorias.'],
                ['{amount} registrados em {month}. Reveja as categorias.', '{amount}. Reveja as categorias.'],
            ],
            InsightTypeEnum::FirstExpense => [
                ['Cadastre sua primeira despesa para começar.'],
                ['Comece registrando sua primeira despesa.'],
                ['Registre uma despesa para iniciar seu histórico.'],
                ['Seu histórico começa com a primeira despesa registrada.'],
            ],
            InsightTypeEnum::InsufficientHistory => $candidate->historyState === InsightHistoryStateEnum::CurrentExpenses ? [
                ['Registros de {month} ainda não permitem análise.', '{short_month}: registros insuficientes para análise.'],
                ['Ainda não há base para analisar {month}.', '{short_month}: ainda sem base para análise.'],
                ['{month}: ainda falta base para análise.', '{short_month}: falta base para análise.'],
                ['A base de {month} ainda não permite análise.', '{short_month}: base ainda insuficiente.'],
            ] : [
                ['Sem despesas registradas em {month}.', 'Sem despesas registradas em {short_month}.'],
                ['Nenhum registro de despesa em {month}.', 'Nenhum registro de despesa em {short_month}.'],
                ['{month}: sem despesas registradas.', '{short_month}: sem despesas registradas.'],
                ['Não há registros de despesas em {month}.', 'Não há registros de despesas em {short_month}.'],
            ],
            InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease => $current ? [
                ['{amount} a mais que no mesmo intervalo de {previous_month}.', '{amount} a mais nos mesmos dias do mês anterior.', '{amount} a mais.'],
                ['{amount} acima do mesmo intervalo de {previous_month}.', '{amount} acima do mesmo intervalo anterior.', 'A mais: {amount}.'],
                ['Mesmo intervalo de {previous_month}: {amount} a mais.', 'Mesmo intervalo anterior: {amount} a mais.', '{amount}; variação para mais.'],
                ['Frente ao mesmo intervalo de {previous_month}: +{amount}.', 'Contra o mesmo intervalo anterior: +{amount}.', 'Variação: +{amount}.'],
            ] : [
                ['{amount} a mais em {month} que em {previous_month}.', '{amount} a mais no mês selecionado.', '{amount} a mais.'],
                ['{amount} acima de {previous_month}, em {month}.', '{amount} acima do mês anterior.', 'A mais: {amount}.'],
                ['Em {month}, {amount} a mais que em {previous_month}.', 'Contra o mês anterior: {amount} a mais.', '{amount}; variação para mais.'],
                ['{month} contra {previous_month}: +{amount}.', 'Variação mensal: +{amount}.', 'Variação: +{amount}.'],
            ],
        };

        $title = match ($candidate->type) {
            InsightTypeEnum::ExpenseConcentration => '{identity}',
            InsightTypeEnum::RegisteredAmountIncrease => 'Total registrado subiu',
            InsightTypeEnum::RegisteredAmountDecrease => 'Total registrado caiu',
            InsightTypeEnum::CategoryReview => 'Outros',
            InsightTypeEnum::FirstExpense => 'Primeiro registro',
            InsightTypeEnum::InsufficientHistory => $candidate->historyState === InsightHistoryStateEnum::CurrentExpenses ? 'Base insuficiente' : 'Mês sem registros',
            default => '{category}',
        };

        return array_map(static function (array $descriptions) use ($candidate, $title): InsightMessageTemplateOutput {
            if ($candidate->type === InsightTypeEnum::RegisteredAmountDecrease) {
                $descriptions = array_map(static fn (string $description): string => strtr($description, [
                    'a mais' => 'a menos', 'acima' => 'abaixo', 'A mais' => 'A menos', 'para mais' => 'para menos', '+' => '−',
                ]), $descriptions);
            }

            $alternativeTitle = $candidate->type === InsightTypeEnum::ExpenseConcentration ? '{category}' : $title;

            return new InsightMessageTemplateOutput(
                title: $title,
                description: $descriptions[0],
                alternatives: array_map(static fn (string $description): InsightMessageTemplateOutput => new InsightMessageTemplateOutput(
                    title: $alternativeTitle, description: $description,
                ), array_slice($descriptions, 1)),
            );
        }, $pairs);
    }
}
