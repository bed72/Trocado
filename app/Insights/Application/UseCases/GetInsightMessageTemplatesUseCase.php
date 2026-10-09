<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageTemplateOutput;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightMessageTemplatesUseCase
{
    public const string Version = 'v2';

    /** @var array<string, list<array{string, string, string}>> */
    private const array Templates = [
        'food_concentration' => [
            ['Era só uma entradinha', 'Alimentação lidera: {percent}% do registrado no mês.', 'Alimentação lidera: {percent}% do registrado no mês.'],
            ['A fome de protagonismo', 'Alimentação tem a maior fatia: {percent}% do registrado no mês.', 'Alimentação lidera: {percent}% do registrado no mês.'],
            ['O prato pediu o pódio', 'Alimentação ficou em primeiro: {percent}% do registrado no mês.', 'Alimentação lidera: {percent}% do registrado no mês.'],
            ['Só veio beliscar', 'Alimentação levou a maior fatia: {percent}% do registrado no mês.', 'Alimentação lidera: {percent}% do registrado no mês.'],
        ],
        'category_concentration' => [
            ['O ranking tem seus favoritos', '{category} lidera: {percent}% do registrado no mês.', '{category} lidera: {percent}% do registrado no mês.'],
            ['O pódio já tem nome', '{category} tem a maior fatia: {percent}% do registrado no mês.', '{category} lidera: {percent}% do registrado no mês.'],
            ['Suspense no ranking? Nem tanto', '{category} ficou em primeiro: {percent}% do registrado no mês.', '{category} lidera: {percent}% do registrado no mês.'],
            ['Participação nada discreta', '{category} lidera o mês com {percent}% do valor registrado.', '{category} lidera: {percent}% do registrado no mês.'],
        ],
        'expense_concentration' => [
            ['Um figurante? Claro que não', 'Um lançamento reúne {percent}% do registrado no mês.', 'Um lançamento reúne {percent}% do registrado no mês.'],
            ['Esse veio com holofote', 'O maior lançamento tem {percent}% do registrado no mês.', 'Maior lançamento: {percent}% do registrado no mês.'],
            ['Discrição passou longe', 'Um só lançamento concentra {percent}% do registrado no mês.', 'Um lançamento reúne {percent}% do registrado no mês.'],
            ['Um registro, muito palco', 'Um lançamento levou {percent}% do registrado no mês.', 'Um lançamento reúne {percent}% do registrado no mês.'],
        ],
        'registered_amount_increase' => [
            ['O total pegou o elevador', 'Registrado de 1 a {day}: {percent}% a mais que nos mesmos dias do mês passado.', 'Registrado de 1 a {day}: mais valor que nos mesmos dias do mês passado.'],
            ['A soma resolveu subir', 'De 1 a {day}, o registrado subiu {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o registrado subiu ante os mesmos dias do mês passado.'],
            ['Os números subiram no palco', 'De 1 a {day}: valor registrado {percent}% maior que nos mesmos dias do mês passado.', 'De 1 a {day}: valor registrado maior que nos mesmos dias do mês passado.'],
            ['A soma ganhou altitude', 'De 1 a {day}, o registrado cresceu {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o registrado cresceu ante os mesmos dias do mês passado.'],
        ],
        'registered_amount_decrease' => [
            ['O total desceu do salto', 'Registrado de 1 a {day}: {percent}% a menos que nos mesmos dias do mês passado.', 'Registrado de 1 a {day}: menos valor que nos mesmos dias do mês passado.'],
            ['A soma baixou o volume', 'De 1 a {day}, o registrado caiu {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o registrado caiu ante os mesmos dias do mês passado.'],
            ['Os números saíram do palco', 'De 1 a {day}: valor registrado {percent}% menor que nos mesmos dias do mês passado.', 'De 1 a {day}: valor registrado menor que nos mesmos dias do mês passado.'],
            ['A soma perdeu altitude', 'De 1 a {day}, o registrado recuou {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o registrado recuou ante os mesmos dias do mês passado.'],
        ],
        'category_lead_streak' => [
            ['O pódio virou endereço', '{category} lidera o registrado neste mês e liderou os dois anteriores.', '{category} lidera o registrado neste mês e liderou os dois anteriores.'],
            ['O ranking entrou no replay', '{category} liderou os dois meses anteriores e segue líder no registrado do mês.', '{category} lidera o registrado neste mês e liderou os dois anteriores.'],
            ['O primeiro lugar criou raízes', '{category} segue líder nos registros: neste mês e nos dois anteriores.', '{category} lidera o registrado neste mês e liderou os dois anteriores.'],
            ['Mudou o mês, não o pódio', '{category} lidera os registros deste mês, como nos dois anteriores.', '{category} lidera o registrado neste mês e liderou os dois anteriores.'],
        ],
        'first_expense' => [
            ['A bola de cristal está offline', 'Registre sua primeira despesa para começar seu histórico.', 'Registre sua primeira despesa para começar seu histórico.'],
            ['O nada ainda não virou dado', 'Seu histórico começa com a primeira despesa registrada.', 'Registre sua primeira despesa para começar seu histórico.'],
            ['O gráfico tirou folga', 'Registre sua primeira despesa para abrir o histórico.', 'Registre sua primeira despesa para abrir o histórico.'],
            ['Spoiler: faltam dados', 'Cadastre sua primeira despesa. Insight não vive de palpite.', 'Cadastre sua primeira despesa para começar seu histórico.'],
        ],
        'current_history' => [
            ['Palpite não é insight', 'Há registros no mês, mas ainda sem base para uma observação.', 'Há registros no mês, mas ainda sem base para uma observação.'],
            ['A bola de cristal segue offline', 'Os registros do mês ainda não sustentam um insight financeiro.', 'Os registros do mês ainda não sustentam um insight financeiro.'],
            ['O suspense é estatístico', 'Ainda não há base para insights nos registros deste mês.', 'Ainda não há base para insights nos registros deste mês.'],
            ['Conclusão apressada? Passo', 'Há registros no mês. Uma observação ainda seria palpite.', 'Há registros no mês, mas ainda sem base para uma observação.'],
        ],
        'old_history' => [
            ['O mês está no modo silencioso', 'Nenhuma despesa registrada no mês. Seu histórico segue aqui.', 'Nenhuma despesa registrada no mês. Seu histórico segue aqui.'],
            ['O histórico não faz previsão', 'Há histórico, mas nenhuma despesa registrada neste mês.', 'Há histórico, mas nenhuma despesa registrada neste mês.'],
            ['O mês ainda não deu entrevista', 'Sem registros neste mês. Os anteriores continuam disponíveis.', 'Sem registros neste mês. Os anteriores continuam disponíveis.'],
            ['O passado não preenche o mês', 'Há registros anteriores, mas nenhum neste mês.', 'Há registros anteriores, mas nenhum neste mês.'],
        ],
        'category_review' => [
            ['Outros, esse mistério', 'Outros reúne {percent}% do registrado no mês. Vale revisar as categorias.', 'Outros: {percent}% do registrado no mês. Vale revisar as categorias.'],
            ['Outros virou protagonista', '{percent}% do registrado no mês está em Outros. Que tal revisar as categorias?', 'Outros: {percent}% do registrado no mês. Vale revisar as categorias.'],
            ['O famoso Outros ataca de novo', 'Outros tem {percent}% do registrado no mês. As categorias merecem uma olhada.', 'Outros: {percent}% do registrado no mês. Vale revisar as categorias.'],
            ['Outros está bem acompanhado', 'Outros soma {percent}% do registrado no mês. Cabe revisar as categorias.', 'Outros: {percent}% do registrado no mês. Vale revisar as categorias.'],
        ],
    ];

    /** @return list<InsightMessageTemplateOutput> */
    public function execute(InsightCandidateValueObject $candidate): array
    {
        $key = match ($candidate->type) {
            InsightTypeEnum::CategoryConcentration => $candidate->category === 'food' ? 'food_concentration' : 'category_concentration',
            InsightTypeEnum::InsufficientHistory => $candidate->historyState === InsightHistoryStateEnum::CurrentExpenses ? 'current_history' : 'old_history',
            default => $candidate->type->value,
        };

        return array_map($this->templateOutput(...), self::Templates[$key]);
    }

    /** @param array{string, string, string} $template */
    private function templateOutput(array $template): InsightMessageTemplateOutput
    {
        return new InsightMessageTemplateOutput(title: $template[0], description: $template[1], shortDescription: $template[2]);
    }
}
