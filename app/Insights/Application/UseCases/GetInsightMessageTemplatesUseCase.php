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
    public const string Version = 'v4-monthly-editorial';

    /** @var array<string, list<array{string, string, string?, string?}>> */
    private const array CurrentTemplates = [
        'category_concentration' => [
            ['{category}', '{percent}% do total registrado em {month} até dia {day}.'],
            ['{category}', 'Soma {percent}% do total registrado em {month} até dia {day}.'],
            ['{category}', 'Em {month} até dia {day}, representa {percent}% do total registrado.'],
            ['{category}', 'Participação de {percent}% no total registrado em {month} até dia {day}.'],
        ],
        'expense_concentration' => [
            ['Maior · {month} até {day}', '{identity}: {percent}% do total registrado · {amount}.', '{identity}: {percent}% do total registrado.'],
            ['Maior · {month} até {day}', '{identity} representa {percent}% do total registrado · {amount}.', '{identity} representa {percent}% do total registrado.'],
            ['Maior · {month} até {day}', '{identity} responde por {percent}% do total registrado · {amount}.', '{identity} responde por {percent}% do total registrado.'],
            ['Maior · {month} até {day}', '{identity} soma {percent}% do total registrado · {amount}.', '{identity} soma {percent}% do total registrado.'],
        ],
        'total_comparison' => [
            ['Total · {month}', '{sign}{percent}% no total registrado: dias 1–{day} vs. 1–{day} de {previous_month}.', '{sign}{percent}% no total registrado; 1–{day} vs. 1–{day} de {previous_month}.', '{sign}{difference} no total registrado; 1–{day} vs. 1–{day} de {previous_month}.'],
            ['Total · {month}', 'Total registrado: {sign}{percent}% nos dias 1–{day} vs. 1–{day} de {previous_month}.', 'Total registrado {sign}{percent}%; 1–{day} vs. 1–{day} de {previous_month}.', 'Total registrado {sign}{difference}; 1–{day} vs. 1–{day} de {previous_month}.'],
            ['Total · {month}', 'Variação de {sign}{percent}%: total registrado de 1–{day} vs. 1–{day} de {previous_month}.', '1–{day}: {sign}{percent}% no total registrado vs. 1–{day} de {previous_month}.', '1–{day}: {sign}{difference} no total registrado vs. 1–{day} de {previous_month}.'],
            ['Total · {month}', 'Nos dias 1–{day}, total registrado {sign}{percent}% vs. 1–{day} de {previous_month}.', 'Total registrado: {sign}{percent}%; 1–{day} vs. 1–{day} de {previous_month}.', 'Total registrado: {sign}{difference}; 1–{day} vs. 1–{day} de {previous_month}.'],
        ],
        'category_lead_streak' => [
            ['{category}', 'Líder registrada em {first_month}, {previous_month} e {month} até dia {day}.'],
            ['{category}', 'Lidera os registros em {first_month}, {previous_month} e {month} até dia {day}.'],
            ['{category}', 'Maior total registrado em {first_month}, {previous_month} e {month} até dia {day}.'],
            ['{category}', 'Primeiro lugar nos registros: {first_month}, {previous_month} e {month} até dia {day}.'],
        ],
        'category_review' => [
            ['Outros · {month}', '{percent}% do total registrado até dia {day}. Revise as categorias.'],
            ['Outros · {month}', 'Até dia {day}: {percent}% do total registrado. Reveja as categorias.'],
            ['Outros · {month}', 'Até dia {day}, {percent}% do total registrado. Confira as categorias.'],
            ['Outros · {month}', 'Soma {percent}% do total registrado até dia {day}. Vale revisar as categorias.'],
        ],
        'first_expense' => [
            ['Primeiro registro', 'Sem despesas registradas até dia {day} de {month}. Cadastre a primeira.'],
            ['Primeiro registro', 'Nenhuma despesa registrada até dia {day} de {month}. Adicione a primeira.'],
            ['Primeiro registro', 'Registre sua primeira despesa: não há registros até dia {day} de {month}.'],
            ['Primeiro registro', 'Até dia {day} de {month}, não há despesas registradas. Registre a primeira.'],
        ],
        'current_history' => [
            ['Análise · {month}', 'Ainda sem observação financeira com os registros até dia {day}.'],
            ['Análise · {month}', 'Até dia {day}, os registros não sustentam uma observação financeira.'],
            ['Análise · {month}', 'Sem base para uma observação financeira nos registros até dia {day}.'],
            ['Análise · {month}', 'Registros até dia {day} insuficientes para uma observação financeira.'],
        ],
        'old_history' => [
            ['Registros · {month}', 'O mês está sem despesas registradas até dia {day}.'],
            ['Registros · {month}', 'Sem registros de despesas neste mês até dia {day}.'],
            ['Registros · {month}', 'Nenhuma despesa registrada neste mês até dia {day}.'],
            ['Registros · {month}', 'Até dia {day}, não há despesas registradas neste mês.'],
        ],
    ];

    /** @var array<string, list<array{string, string, string?, string?}>> */
    private const array ClosedTemplates = [
        'category_concentration' => [
            ['{category}', '{percent}% do total registrado em {month}, mês completo.'],
            ['{category}', 'Em {month}, representa {percent}% do total registrado no mês.'],
            ['{category}', 'Soma {percent}% do total registrado em {month}, mês completo.'],
            ['{category}', 'Participação de {percent}% no total registrado em {month}, mês completo.'],
        ],
        'expense_concentration' => [
            ['Maior despesa · {month}', '{identity}: {percent}% do total registrado · {amount}.', '{identity}: {percent}% do total registrado.'],
            ['Maior despesa · {month}', '{identity} representa {percent}% do total registrado · {amount}.', '{identity} representa {percent}% do total registrado.'],
            ['Maior despesa · {month}', '{identity} responde por {percent}% do total registrado · {amount}.', '{identity} responde por {percent}% do total registrado.'],
            ['Maior despesa · {month}', '{identity} soma {percent}% do total registrado · {amount}.', '{identity} soma {percent}% do total registrado.'],
        ],
        'total_comparison' => [
            ['Total · {month}', '{sign}{percent}% no total registrado do mês vs. {previous_month} completo.', '{sign}{percent}% no total registrado; mês completo vs. {previous_month}.', '{sign}{difference} no total registrado; mês completo vs. {previous_month}.'],
            ['Total · {month}', 'Total registrado do mês: {sign}{percent}% vs. {previous_month} completo.', 'Total registrado {sign}{percent}%; mês completo vs. {previous_month}.', 'Total registrado {sign}{difference}; mês completo vs. {previous_month}.'],
            ['Total · {month}', 'Variação de {sign}{percent}% no total registrado: mês completo vs. {previous_month}.', 'Mês completo: {sign}{percent}% no total registrado vs. {previous_month}.', 'Mês completo: {sign}{difference} no total registrado vs. {previous_month}.'],
            ['Total · {month}', 'Mês completo: total registrado {sign}{percent}% vs. {previous_month} completo.', 'Total registrado: {sign}{percent}%; mês completo vs. {previous_month}.', 'Total registrado: {sign}{difference}; mês completo vs. {previous_month}.'],
        ],
        'category_lead_streak' => [
            ['{category}', 'Líder registrada de {first_month} a {month}, três meses completos.'],
            ['{category}', 'Maior total registrado de {first_month} a {month}, três meses completos.'],
            ['{category}', 'Liderou os registros de {first_month} a {month}, três meses completos.'],
            ['{category}', 'Primeiro lugar nos registros de {first_month} a {month}, três meses completos.'],
        ],
        'category_review' => [
            ['Outros · {month}', '{percent}% do total registrado no mês. Revise as categorias.'],
            ['Outros · {month}', 'Mês completo: {percent}% do total registrado. Reveja as categorias.'],
            ['Outros · {month}', 'No mês completo, {percent}% do total registrado. Confira as categorias.'],
            ['Outros · {month}', 'Soma {percent}% do total registrado no mês. Vale revisar as categorias.'],
        ],
        'current_history' => [
            ['Análise · {month}', 'Os registros do mês não sustentam uma observação financeira.'],
            ['Análise · {month}', 'Registros do mês insuficientes para uma observação financeira.'],
            ['Análise · {month}', 'Sem observação financeira com os registros desse mês completo.'],
            ['Análise · {month}', 'Sem base para uma observação financeira nos registros do mês completo.'],
        ],
        'old_history' => [
            ['Registros · {month}', 'Sem registros de despesas nesse mês completo.'],
            ['Registros · {month}', 'Nenhuma despesa registrada nesse mês completo.'],
            ['Registros · {month}', 'O mês selecionado não tem despesas registradas.'],
            ['Registros · {month}', 'Não há despesas registradas no mês selecionado.'],
        ],
    ];

    /** @return list<InsightMessageTemplateOutput> */
    public function execute(InsightCandidateValueObject $candidate): array
    {
        $key = match ($candidate->type) {
            InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::RegisteredAmountDecrease => 'total_comparison',
            InsightTypeEnum::InsufficientHistory => $candidate->historyState === InsightHistoryStateEnum::CurrentExpenses ? 'current_history' : 'old_history',
            default => $candidate->type->value,
        };
        $templates = $candidate->mode === InsightPeriodModeEnum::Closed ? self::ClosedTemplates : self::CurrentTemplates;

        return array_map(static fn (array $template): InsightMessageTemplateOutput => new InsightMessageTemplateOutput(
            title: $template[0],
            description: $template[1],
            monetaryDescription: $template[3] ?? null,
            shortDescription: $template[2] ?? $template[1],
        ), $templates[$key]);
    }
}
