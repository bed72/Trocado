<?php

declare(strict_types=1);

namespace App\Insights\Application\UseCases;

use App\Insights\Application\Data\InsightMessageTemplateOutput;
use App\Insights\Domain\Enums\InsightHistoryStateEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;
use App\Insights\Domain\ValueObjects\InsightCandidateValueObject;

final readonly class GetInsightMessageTemplatesUseCase
{
    public const string Version = 'v1';

    /** @var array<string, list<array{string, string, string}>> */
    private const array Templates = [
        'food_concentration' => [
            ['O prato levou a maior fatia!', 'Alimentação lidera com {percent}% do valor registrado neste mês. Veio com fome.', 'Alimentação lidera: {percent}% do valor registrado neste mês.'],
            ['Alimentação na liderança', 'Neste mês, Alimentação tem a maior fatia: {percent}% do valor registrado.', 'Neste mês, Alimentação lidera com {percent}% do valor registrado.'],
            ['A maior fatia está na mesa', 'Alimentação reúne {percent}% do valor registrado neste mês e lidera as categorias.', 'Alimentação: líder com {percent}% do valor registrado neste mês.'],
            ['O prato ficou em primeiro', 'Com {percent}% do valor registrado neste mês, Alimentação lidera. A mesa está posta.', 'Alimentação lidera com {percent}% do valor registrado neste mês.'],
        ],
        'category_concentration' => [
            ['Uma categoria em destaque', '{category} lidera com {percent}% do valor registrado neste mês.', '{category}: líder com {percent}% do valor registrado neste mês.'],
            ['A maior participação', 'Neste mês, {category} tem a maior participação: {percent}% do valor registrado.', 'Neste mês, {category} lidera com {percent}% do valor registrado.'],
            ['Liderança nos registros', '{category} reúne {percent}% do valor registrado neste mês e lidera as categorias.', '{category} lidera: {percent}% do valor registrado neste mês.'],
            ['O destaque deste mês', 'Com {percent}% do valor registrado neste mês, {category} aparece na liderança.', '{category} tem a maior fatia: {percent}% do valor registrado neste mês.'],
        ],
        'expense_concentration' => [
            ['Um registro em destaque', 'Um único lançamento reúne {percent}% do valor registrado neste mês.', 'Um lançamento: {percent}% do valor registrado neste mês.'],
            ['A maior parcela individual', 'O maior lançamento representa {percent}% do valor registrado neste mês.', 'Maior lançamento: {percent}% do valor registrado neste mês.'],
            ['Uma parcela dos registros', 'Neste mês, {percent}% do valor registrado está em um único lançamento.', 'Neste mês, um lançamento reúne {percent}% do valor registrado.'],
            ['Destaque entre lançamentos', 'Um lançamento concentra {percent}% do valor registrado neste mês.', 'Um lançamento tem {percent}% do valor registrado neste mês.'],
        ],
        'registered_amount_increase' => [
            ['Mais valor registrado', 'De 1 a {day}, você registrou {percent}% mais valor que nos mesmos dias do mês passado.', 'De 1 a {day}, houve mais valor registrado que nos mesmos dias do mês passado.'],
            ['O total registrado subiu', 'O valor registrado de 1 a {day} subiu {percent}% frente aos mesmos dias do mês passado.', 'O valor registrado de 1 a {day} subiu frente aos mesmos dias do mês passado.'],
            ['Um total maior no intervalo', 'Até dia {day}, o valor registrado ficou {percent}% maior que no mesmo intervalo do mês passado.', 'Até dia {day}, o valor registrado foi maior que no mesmo intervalo do mês passado.'],
            ['Comparando os registros', 'De 1 a {day}, o valor registrado aumentou {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o valor registrado aumentou ante os mesmos dias do mês passado.'],
        ],
        'registered_amount_decrease' => [
            ['Menos valor registrado', 'De 1 a {day}, você registrou {percent}% menos valor que nos mesmos dias do mês passado.', 'De 1 a {day}, houve menos valor registrado que nos mesmos dias do mês passado.'],
            ['O total registrado caiu', 'O valor registrado de 1 a {day} caiu {percent}% frente aos mesmos dias do mês passado.', 'O valor registrado de 1 a {day} caiu frente aos mesmos dias do mês passado.'],
            ['Um total menor no intervalo', 'Até dia {day}, o valor registrado ficou {percent}% menor que no mesmo intervalo do mês passado.', 'Até dia {day}, o valor registrado foi menor que no mesmo intervalo do mês passado.'],
            ['Os registros em comparação', 'De 1 a {day}, o valor registrado diminuiu {percent}% ante os mesmos dias do mês passado.', 'De 1 a {day}, o valor registrado diminuiu ante os mesmos dias do mês passado.'],
        ],
        'category_lead_streak' => [
            ['Uma liderança recorrente', '{category} segue líder nos registros deste mês, após liderar os dois meses anteriores.', '{category} liderou os dois meses anteriores e segue líder nos registros deste mês.'],
            ['O destaque continua', 'Nos registros, {category} liderou os dois meses anteriores e lidera este mês até agora.', '{category} lidera os registros deste mês após liderar os dois meses anteriores.'],
            ['Liderança em três períodos', '{category} liderou os dois meses anteriores e segue à frente nos registros deste mês.', '{category} segue à frente neste mês após liderar os registros dos dois anteriores.'],
            ['A categoria segue à frente', 'Até agora, {category} lidera os registros deste mês, como nos dois meses anteriores.', '{category} lidera este mês até agora, como nos registros dos dois meses anteriores.'],
        ],
        'first_expense' => [
            ['Vamos começar?', 'Cadastre sua primeira despesa para começar a conhecer seus registros. Sem prova surpresa.', 'Cadastre sua primeira despesa para começar a conhecer seus registros.'],
            ['O primeiro registro conta', 'Comece com uma despesa. Os insights chegam quando houver registros suficientes.', 'Registre uma despesa. Os insights chegam com registros suficientes.'],
            ['Uma despesa para começar', 'Seu histórico começa com um registro. Cadastre uma despesa para dar o primeiro passo.', 'Cadastre uma despesa para começar seu histórico.'],
            ['Bora abrir o histórico?', 'Registre sua primeira despesa. Por enquanto, a página está esperando sua estreia.', 'Registre sua primeira despesa para abrir seu histórico.'],
        ],
        'current_history' => [
            ['Ainda sem observações', 'Há registros neste mês, mas ainda não há uma observação financeira elegível.', 'Seus registros deste mês ainda não permitem uma observação financeira.'],
            ['Cada registro traz contexto', 'Por enquanto, os registros não sustentam uma observação financeira.', 'Por enquanto, seus registros não sustentam uma observação financeira.'],
            ['O histórico está em construção', 'Os registros deste mês ainda não oferecem evidência para os insights financeiros.', 'Ainda não há evidência para insights financeiros nos registros deste mês.'],
            ['Sem apressar conclusões', 'Há registros neste mês. Vamos esperar evidência suficiente antes de apresentar uma observação financeira.', 'Há registros neste mês, mas ainda falta evidência para uma observação financeira.'],
        ],
        'old_history' => [
            ['Seu histórico segue aqui', 'Você tem histórico, mas não há despesas registradas neste mês. Registre as que ocorrerem.', 'Você tem histórico, mas ainda não há despesas registradas neste mês.'],
            ['Um mês sem registros', 'Não há registros neste mês. Seu histórico anterior continua disponível.', 'Neste mês não há registros; seu histórico anterior continua disponível.'],
            ['Novos registros, novo contexto', 'Seu histórico já começou. Ainda não há registros neste mês para novas observações.', 'Seu histórico já começou, mas este mês ainda está sem registros.'],
            ['Vamos atualizar o histórico?', 'Há registros anteriores, mas nenhum neste mês. Cadastre suas despesas quando ocorrerem.', 'Há registros anteriores, mas nenhum neste mês.'],
        ],
        'category_review' => [
            ['Uma olhada nas categorias?', 'Outros reúne {percent}% do valor registrado neste mês. Vale revisar se as categorias fazem sentido.', 'Outros reúne {percent}% do valor registrado neste mês. Que tal revisar as categorias?'],
            ['Outros está em destaque', 'Neste mês, {percent}% do valor registrado está em Outros. Revise as categorias se fizer sentido.', 'Neste mês, Outros reúne {percent}% do valor registrado. Revise se fizer sentido.'],
            ['Mais contexto nas categorias', 'Outros tem {percent}% do valor registrado neste mês. Uma revisão pode dar mais contexto aos registros.', 'Outros tem {percent}% do valor registrado neste mês. Uma revisão pode dar mais contexto.'],
            ['As categorias fazem sentido?', '{percent}% do valor registrado neste mês está em Outros. Confira se essa escolha ainda faz sentido.', 'Outros: {percent}% do valor registrado neste mês. Confira se a escolha faz sentido.'],
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
