# Trocado — Design System & UI Brief

> Documento mestre para gerar o design system completo do Trocado em uma ferramenta de design assistida por IA. Cobre identidade visual atual (a manter), telas existentes (a refresh) e features novas (a desenhar do zero, com destaque para o **modo casal**).

---

## 1. Missão para a ferramenta

Você vai entregar **dois artefatos integrados**:

1. **Design System** (foundation + componentes) baseado nos tokens já em uso no app.
2. **Mocks de alta fidelidade de todas as telas** — versão refresh das que já existem + features novas, mantendo coerência visual total.

**Princípio guia:** *clareza sobre dinheiro entre duas pessoas, sem fricção e sem julgamento.* O Trocado não é um app de planilha — é um assistente que mostra "quanto sobra hoje" e "como nós dois estamos indo".

**Não fuja da identidade atual** (paleta verde-sálvia, Material 3 flat, raios generosos, Inter). Refine, não substitua.

---

## 2. Produto

### O que é

App mobile (iOS + Android) de **controle financeiro para casais brasileiros**. Nome "Trocado" = gíria br para "dinheiro miúdo". Tom: amigável, direto, brasileiro, sem economês.

### Stack que dita restrições visuais

- **Flutter + Material 3** (componentes nativos M3 são a base — não invente componentes customizados sem ganho claro)
- **flex_color_scheme** — temas light + dark com paleta tonal
- **Inter Variable** como família tipográfica única
- **pt_BR** em 100% das copies, formatação de moeda (`R$ 1.234,56`) e datas (`15/04/2026`)
- **API REST Django** já existente — o app é cliente, não fonte de verdade

### Persona

**Casal de 25-40 anos**, ambos com renda própria, que já tentaram planilhas, apps gringos (Mint, YNAB) e desistiram porque eram complicados ou não falavam português. Querem:

- Saber quanto podem gastar **hoje** sem comprometer o mês
- Ver gastos do parceiro em tempo real (transparência, não vigilância)
- Combinar limites para categorias compartilhadas (mercado, lazer, casa)
- Zero fricção para registrar uma despesa (3 toques no máximo)

### Modelo mental do usuário

```
Eu defino um ORÇAMENTO de R$ X para um período (ex: mês).
Eu (e meu parceiro) registramos DESPESAS contra esse orçamento.
O app me mostra o SALDO restante, quanto sobra POR DIA, e ALERTA se eu estiver no ritmo de estourar.
```

---

## 3. Identidade Visual — Foundation (manter)

### 3.1 Paleta de cores

Material 3 ColorScheme tonal. **Use exatamente estes valores** como ponto de partida e gere os tons intermediários (containers, onContainer, etc.) seguindo a especificação M3.

**Light mode**

| Token            | Hex       | Uso                                         |
|------------------|-----------|---------------------------------------------|
| `primary`        | `#2B6A46` | Marca, CTAs primários, valores positivos    |
| `secondary`      | `#4E6354` | Acentos, ícones de apoio                    |
| `tertiary`       | `#3B6470` | Categoria/metadata, links sutis             |
| `error`          | `#BA1A1A` | Validação, "estouro" de orçamento           |
| `surface`        | `#F6FBF4` | Fundo das telas                             |
| `surfaceContainer` | `#EAEFE8` | Cards, sheets, app bar                    |

**Dark mode**

| Token            | Hex       |
|------------------|-----------|
| `primary`        | `#93D5A9` |
| `secondary`      | `#B5CCBA` |
| `tertiary`       | `#A3CDDB` |
| `error`          | `#FFB4AB` |
| `surface`        | `#0F1511` |
| `surfaceContainer` | `#1C211D` |

**Semântica financeira (derivar a partir da paleta acima — não inventar cores soltas):**

- **Saudável** (gastei até 40% do orçamento): `primary` (verde)
- **Atenção** (40-60%): laranja-âmbar interpolado entre `primary` e `error`
- **Risco** (60-85%): laranja mais intenso
- **Estouro** (>85% ou >100%): `error`

A interpolação é **linear no espaço HSL** ou similar — o efeito atual no `BudgetCardWidget` faz exatamente isso e funciona bem. Mantenha.

### 3.2 Tipografia

**Família única:** Inter Variable (já em `assets/fonts/`).

| Role            | Tamanho | Peso | Uso                                 |
|-----------------|---------|------|-------------------------------------|
| `displayLarge`  | 36 px   | 700  | Valor monetário hero (saldo)        |
| `headlineLarge` | 28 px   | 700  | Título principal de tela            |
| `headlineMedium`| 24 px   | 600  | Título de seção, valor em cards     |
| `titleLarge`    | 20 px   | 600  | Título de card, sheet header        |
| `titleMedium`   | 16 px   | 600  | Item de lista, label de campo ativo |
| `bodyLarge`     | 16 px   | 400  | Texto corrido                       |
| `bodyMedium`    | 14 px   | 400  | Descrição secundária                |
| `labelMedium`   | 12 px   | 500  | Helper text, metadata, captions     |
| `labelSmall`    | 11 px   | 500  | Tags, badges                        |

**Regra:** valores monetários sempre em **tabular numbers** (`fontFeatures: [FontFeature.tabularFigures()]`) para alinhar colunas em listas.

### 3.3 Espaçamento

Sistema base **8px**, com unidades comuns **4 / 8 / 12 / 16 / 24 / 32 / 48**.

- Padding padrão de tela: **16px** lateral
- Espaçamento entre cards: **12px**
- Padding interno de card: **16px** (grandes) ou **12px** (compactos)
- Sheet bottom padding: **24px** (acomoda área segura)

### 3.4 Raios

| Token              | Valor   | Uso                                |
|--------------------|---------|------------------------------------|
| `cornerRadius100`  | 16 px   | Cards, text fields, botões padrão  |
| `cornerRadius300`  | 20 px   | Bottom sheets, dialogs             |
| `cornerRadius500`  | 28 px   | Cards hero (active budget)         |
| `cornerRadius700`  | 36 px   | Containers especiais, FAB grande   |
| `cornerRadiusFull` | 999 px  | Pills, avatars, chips, badges      |

### 3.5 Elevação

**Material 3 flat.** Elevation 0 em quase tudo (cards, app bar, botões). Diferenciação por **cor de surface** (surface / surfaceContainer / surfaceContainerHighest), não por sombra.

Exceção: **FAB expansível** pode ter elevation sutil (1-2dp) para destacar do conteúdo.

### 3.6 Iconografia

**Material Symbols Outlined** como família principal. Stroke fino, peso 400, opcional fill em estados ativos. Tamanho padrão **24px**, ícones de ação **20px**, ícones inline em chips **16px**.

### 3.7 Motion

- **Bounce em press** de qualquer botão/CTA (escala 0.96, duração 120ms, curve `Curves.easeOut`).
- **Color interpolation suave** no progress bar do orçamento (ver `BudgetCardWidget`).
- **SwitcherAnimation** para troca de estado (ex: ícone → spinner) com fade + scale 200ms.
- **Skeleton (skeletonizer)** para loading de listas e cards — nunca spinner em tela cheia.
- Transições de tela: padrão Material (slide horizontal), mantidas pelo duck_router.

### 3.8 Voz e tom

- **Português coloquial brasileiro**, sem ser informal demais. "Você" sempre, nunca "tu".
- **Sem economês**: "saldo", "sobra", "limite" > "patrimônio líquido", "fluxo de caixa".
- **Empático em erros**: "Não rolou. Tenta de novo?" > "Erro 500 ao processar requisição".
- **Celebra wins**: ao salvar despesa dentro do limite → "Boa! Ainda sobra R$ X pro mês."
- **Honesto em alertas**: ao passar de 80% → "Tá apertado. Faltam Y dias e R$ Z."

---

## 4. Information Architecture

### 4.1 Mapa de navegação completo

```
Splash (/splash)
  ├── (não autenticado) → Sign In (/sign-in)
  │       ├── → Sign Up (/sign-up)
  │       ├── → Forgot Password (/forgot-password)
  │       └── (deep link) → Password Reset Confirm (/reset-password)
  │
  └── (autenticado) → Home (/) ★ raiz autenticada
          ├── (back) → Exit (/exit) [bottom sheet de confirmação]
          ├── (FAB +) → Expense (/expense) [criar]
          │       ├── → Calculator (/calculator) [bottom sheet]
          │       ├── → Expense Date (/expense-date) [bottom sheet]
          │       └── → Category (/category) [NOVO — bottom sheet]
          ├── (FAB +) → Budget (/budget) [criar]
          │       ├── → Calculator (/calculator)
          │       └── → Budget Date (/budget-date) [bottom sheet]
          ├── (tap card de orçamento) → Budget Detail [NOVO]
          ├── (tap despesa na lista) → Expense (/expense) [editar]
          ├── (top-right 🔔) → Notifications (/notifications)
          └── (top-right ⚙) → Settings (/settings)
                  ├── → Personal Data [NOVO — sub-tela]
                  ├── → Notifications Prefs [NOVO]
                  ├── → Subscription [NOVO]
                  ├── → Partner [NOVO ★ feature casal]
                  ├── → Categories [NOVO]
                  ├── → Terms / Privacy / Help [web view ou tela simples]
                  └── (botão Sair) → Sign In
```

### 4.2 Nova seção principal: Insights / Histórico

Atualmente a Home só mostra o card de orçamento. Vamos adicionar **abaixo do card**:

- **Lista de despesas recentes** (últimas 10 do orçamento ativo)
- **Atalho para "Ver tudo"** → tela de histórico com filtros
- **Atalho para "Insights"** → tela de analytics (médias, categorias, comparativo com período anterior)

A Home continua sem tab bar — é uma scroll única. Mantém a simplicidade atual.

---

## 5. Telas existentes — Refresh visual

Para cada tela abaixo, **mantenha estrutura e copy** (a menos que indicado), mas refine espaçamento, hierarquia, microinterações e estados. Cubra **sempre** os 5 estados quando aplicável: `initial`, `loading`, `success`, `empty`, `error`.

### 5.1 Splash

**Função:** verificar sessão e rotear.
**Layout:** logo centralizado (196×196), cor `inversePrimary`, fundo `surface`.
**Estados:** apenas `loading` (visível por <1s na maioria dos casos).
**Refresh:** considerar pequena animação de pulso suave no logo (200ms loop) só pra dar vida quando demora >500ms.

### 5.2 Sign In

**Copy fixa:**
- Header: "Bem-vindo"
- Sub: "Entre na sua conta para continuar."
- Campos: Email (placeholder "Digite seu e-mail"), Senha (com toggle de visibilidade)
- Link inline: "Esqueci minha senha" (alinhado à direita, abaixo do campo senha)
- CTA: "Entrar" (full width)
- Footer: "Ainda não tem uma conta? **Criar conta**"

**Estados:** focused, filled, error (msg vermelha sob o campo), loading (spinner no botão), failure (toast).
**Refresh:** considerar ilustração leve no topo (ver `assets/images/`), respiração visual entre header e form.

### 5.3 Sign Up

**Copy fixa:**
- Header: "Criar sua conta"
- Sub: "Preencha os dados abaixo."
- Campos: Email, Senha
- Checkbox: "Aceito os termos de uso e política de privacidade"
- CTA: "Continuar"
- Footer: "Já possui uma conta? **Entrar**"

**Refresh:** mesmo tratamento da Sign In. Termos têm link inline destacável.

### 5.4 Forgot Password

**Copy fixa:**
- Header: "Esqueceu a senha?"
- Sub: "Informe seu e-mail para receber o link de redefinição."
- Campo: Email
- CTA: "Enviar"

**Estados extras:** após sucesso, considere um estado **"sent"** (in-place, em vez de só toast): substituir form por ilustração + texto "Pronto! Olha seu e-mail" + botão "Voltar pra entrar".

### 5.5 Password Reset Confirm

**Copy fixa:**
- Header: "Criar nova senha"
- Sub: "Informe sua nova senha para redefini-la."
- Campos: "Nova senha", "Confirmar senha" (ambos com toggle)
- CTA: "Redefinir senha"

**Refresh:** adicionar **indicador de força de senha** (barra com 4 níveis) abaixo do primeiro campo.

### 5.6 Home ★

**Função:** coração do app. Mostra orçamento ativo + ações rápidas + (NOVO) despesas recentes.

**Estrutura atual:**
```
┌─────────────────────────────────┐
│ Avatar  Olá, Gabriel    🔔  ⚙  │  ← AppBar (transparente, surface)
├─────────────────────────────────┤
│                                 │
│   ┌───────────────────────┐    │
│   │   BudgetCardWidget    │    │  ← Card hero (radius 28)
│   │   - %, progress bar   │    │
│   │   - Gasto / Total     │    │
│   │   - Disponível        │    │
│   └───────────────────────┘    │
│                                 │
│                            (+)  │  ← FAB expansível
└─────────────────────────────────┘
```

**Refresh + adições:**

- **Header de saudação dinâmico**: "Bom dia/Boa tarde/Boa noite, [Nome]". Avatar do usuário (ou avatar combinado do casal — ver §7).
- **Card de orçamento** (já existe, mantém — só refinar tipografia do valor disponível para `displayLarge` ou `headlineMedium` bold).
- **NOVO: Bloco "Despesas recentes"** logo abaixo do card:
  - Header da seção: "Despesas recentes" + botão texto "Ver tudo"
  - Lista de até 5 itens (componente `ExpenseItemWidget`, ver §7)
  - Estado vazio: "Nada por aqui ainda. Toca no + pra registrar."
- **NOVO: Bloco "Insights rápidos"** (opcional, abaixo da lista):
  - Card horizontal scrollável com 2-3 mini-cards: "Categoria que mais gastei", "Média diária", "Comparado ao mês passado"
- **FAB expansível** mantém: + abre dois mini-FABs (Despesa, Orçamento) com labels.

**Estados do card:**
- `loading`: skeleton do card inteiro
- `success`: dados completos
- `empty`: "Nenhum orçamento ativo" + CTA "Criar orçamento" (mantém atual)
- `failure`: ícone de erro + "Não consegui carregar." + botão "Tentar de novo"

### 5.7 Expense (criar/editar)

**Copy:**
- Header (criar): "Nova despesa" / Sub: "Registre um gasto."
- Header (editar): "Editar despesa" / Sub: "Atualize os dados abaixo."
- Campos: Descrição (texto), Valor (read-only → abre Calculator), Data (read-only → abre Date picker)
- **NOVO**: Categoria (read-only → abre seletor), Pago por (read-only → "Eu" / "[Nome do parceiro]" / "Compartilhado")
- CTA: "Salvar despesa"

**Estados:** loading no botão, failure toast, success (auto-fecha + toast verde "Despesa salva. Sobra R$ X.").

**Refresh:** valor em destaque tipográfico no topo (preview "R$ 0,00" → ao tocar abre calculator). Hierarquia: valor > descrição > data > categoria > pago por.

### 5.8 Budget (criar)

**Copy:**
- Header: "Novo orçamento" / Sub: "Defina seu limite e o período."
- Campos: Valor (→ Calculator), Descrição, Período (→ Budget Date picker)
- CTA: "Salvar orçamento"

**Refresh:** mesmo tratamento — valor em destaque no topo.

### 5.9 Calculator (bottom sheet)

**Copy:** "Qual o valor?" / "Informe o valor."
**Layout:** display grande no topo (`displayLarge`, format `R$ 0,00` em tempo real) + teclado numérico 4×3 (0-9, ⌫, C, ✓).
**Refresh:** garantir que o display nunca quebra linha. Vibração háptica leve em cada tap.

### 5.10 Budget Date / Expense Date (bottom sheet)

**Copy:** "Período" (range) / "Data" (single) — "Selecione [...]"
**Picker:** Syncfusion (mantém). Estilo customizado para bater com a paleta.
**CTA:** "Selecionar"

### 5.11 Settings

**Estrutura atual:**
- Header: "Configurações" / Sub: "Gerencie suas preferências e dados da conta."
- Seção "Conta": Dados pessoais, Notificações, Subscrição (badge premium)
- Seção "Informações": Termos, Privacidade, Ajuda
- Botão "Sair" no rodapé

**NOVO — adicionar seções:**
- **"Casal"** (no topo, antes de Conta) — ver §6.1
- **"Categorias"** (em Conta) — gerenciar categorias customizadas

### 5.12 Notifications (atualmente placeholder)

Ver §6.2 — desenhar do zero.

### 5.13 Exit (bottom sheet)

**Copy:** "Opps" / "Deseja realmente sair do app?"
**Layout:** dois botões lado a lado: "Sair" (elevated) + "Cancelar" (outlined).
**Refresh:** trocar "Opps" por algo mais cordial: **"Já vai?"**.

### 5.14 Failure (genérica)

Atualmente só "Failure". **Refresh:** ilustração + "Algo deu errado." + "Tenta de novo" + link "Voltar pra Home".

---

## 6. Telas/Features novas — Desenhar do zero

### 6.1 Modo Casal ★ (feature flagship)

**Conceito:** dois usuários (parceiros) compartilham um **espaço único** (workspace). Orçamentos, despesas e categorias são compartilhados. Cada despesa é **atribuída** a um dos dois (ou marcada como "compartilhada").

**Modelo mental:**
```
1 Casal = 1 workspace
1 workspace contém: N orçamentos, N despesas, N categorias
Cada despesa pertence a → workspace + atribuída a (parceiro A | parceiro B | ambos)
```

**Telas a desenhar:**

#### 6.1.1 Convite de parceiro
- Acessível em Settings → "Casal" → "Convidar parceiro"
- Estados: **sem parceiro** (mostra ilustração + CTA "Convidar parceiro" → modal com email/link), **convite pendente** (mostra "Aguardando [email]" + opção cancelar), **conectados** (mostra ambos avatares + nome + opção desconectar).

#### 6.1.2 Aceite de convite
- Tela acessada por deep link (`/invite?token=X`)
- Mostra: "[Nome] te convidou pro Trocado dele." + dois CTAs: "Aceitar" / "Recusar"
- Aviso: "Vocês vão compartilhar orçamentos e despesas."

#### 6.1.3 Avatar combinado
- Componente novo: dois avatares sobrepostos (offset horizontal de ~30%) com borda da cor `surface`. Usar na AppBar da Home quando houver parceiro.

#### 6.1.4 Atribuição de despesa
- Novo campo no Expense screen: "Pago por" (chip selector: "Eu" | "[Nome parceiro]" | "Nós dois")
- Em "Nós dois", aparece sub-controle: divisão (50/50, 60/40 customizável, "Cada um pagou metade")

#### 6.1.5 Saldo entre parceiros (opcional, v2)
- Se as despesas compartilhadas forem pagas por um só, app calcula "[Parceiro A] deve R$ X pra [Parceiro B]" e mostra num card discreto na Home.

#### 6.1.6 Lista de despesas com identificação
- Cada `ExpenseItemWidget` mostra mini-avatar do pagador no canto. Compartilhada → ícone de duas pessoas.

**Tom da feature:** colaborativo, transparente, sem fricção. **Não** tratar como "controle/vigilância" — sempre como "nossa visão conjunta".

---

### 6.2 Notificações

Atualmente é placeholder. **Desenhar:**

#### 6.2.1 Lista
- Header: "Notificações" / Sub: "Acompanhe os alertas e avisos da sua conta."
- Tabs (segmented): "Todas" | "Não lidas"
- Items agrupados por dia: "Hoje", "Ontem", "Esta semana", "Mais antigas"
- Cada item: ícone (por tipo) + título + descrição + timestamp relativo ("há 2h") + indicador visual de não lida (dot primary à esquerda)

**Tipos de notificação:**
1. **Despesa do parceiro** — "[Nome] registrou R$ X em [categoria]"
2. **Alerta de orçamento** — "Você já gastou 80% do orçamento [Nome]"
3. **Estouro** — "Orçamento [Nome] foi estourado"
4. **Convite de parceiro** — "[Nome] aceitou seu convite"
5. **Sistema** — "Atualização disponível", "Manutenção amanhã"

#### 6.2.2 Estado vazio
- Ilustração + "Tudo em dia. Sem notificações por aqui."

#### 6.2.3 Preferências (em Settings → Notificações)
- Toggle por tipo: alertas de orçamento (com slider de threshold: 50/70/85%), atividade do parceiro, novidades do app
- Toggle de canais: push, email

---

### 6.3 Histórico de despesas

Acessível via "Ver tudo" na Home.

**Layout:**
- AppBar: "Despesas"
- Filtros (chips horizontais scrolláveis): período (este mês / mês passado / personalizado), categoria, parceiro
- Resumo no topo: "Total no período: **R$ X**" + "X despesas"
- Lista agrupada por **dia** com header sticky ("15 abr · R$ 230,00")
- Cada item: descrição + valor + categoria (chip) + mini-avatar do pagador
- Pull-to-refresh
- Empty: "Nenhuma despesa no filtro."
- Loading: skeleton list (5 items)

---

### 6.4 Detalhe do orçamento

Tap no card da Home abre tela completa.

**Layout:**
- AppBar: nome do orçamento + ícone de editar
- Hero: gauge/progresso grande, valor disponível em `displayLarge`, badge de % de uso
- Stats grid 2×2: Gasto, Disponível, Por dia, Dias restantes
- **Gráfico de evolução** (line chart) — gasto acumulado vs. ritmo ideal linear
- **Breakdown por categoria** (donut chart pequeno + lista de top 5)
- **Breakdown por parceiro** (se modo casal ativo)
- Botão "Ver todas as despesas deste orçamento"

**Componentes de chart:** considerar `fl_chart` (já está no pubspec, ainda não usado).

---

### 6.5 Insights / Analytics

Acessível via atalho na Home ou tab futura.

**Cards/seções:**
1. **Resumo do mês**: gasto total, comparativo com mês anterior (% e setinha)
2. **Categoria que mais cresceu**: com mini-bar chart 6 meses
3. **Média diária**: linha horizontal mostrando hoje vs. média
4. **Top categorias**: lista com valores e %
5. **Comparativo entre parceiros** (modo casal): "Quem gastou mais", barras horizontais

---

### 6.6 Categorias (gerenciamento)

Settings → "Categorias" → tela de gerenciamento.

**Layout:**
- Lista de categorias customizadas + categorias padrão (read-only)
- Cada item: ícone colorido + nome + valor total gasto (this month) + chevron
- FAB: "Nova categoria"
- Form de categoria: nome + ícone (grid de Material Symbols) + cor (palette de 12 cores derivadas da paleta principal)

---

### 6.7 Subscrição (premium)

Acessível via Settings → "Subscrição".

**Layout:**
- Hero: ilustração + headline "Trocado Premium"
- Bullets de benefícios: "Sincronização em tempo real do casal", "Insights avançados", "Categorias ilimitadas", "Sem limites de orçamentos"
- Cards de planos: Mensal / Anual (com badge "Economiza X%")
- CTA grande: "Assinar"
- Link discreto: "Restaurar compra"

---

### 6.8 Settings — sub-telas

#### 6.8.1 Dados pessoais
- Avatar (tap → upload), Nome, Email (read-only ou com confirmação por email para alterar), Senha (link "Alterar senha")

#### 6.8.2 Termos / Privacidade / Ajuda
- Pode ser web view simples ou tela com markdown. Header padrão + conteúdo scrollável. Não precisa design especial.

---

## 7. Component Library

Componentes a entregar como parte do design system. Para cada um: variantes, estados, anatomia, tokens usados.

### 7.1 Foundation
- **Color** (tokens definidos em §3.1)
- **Typography** (escala definida em §3.2)
- **Spacing scale** (§3.3)
- **Radius scale** (§3.4)
- **Iconography** (§3.6)
- **Motion tokens** (§3.7)

### 7.2 Componentes core

| Componente             | Variantes                                      | Estados                                  |
|------------------------|------------------------------------------------|------------------------------------------|
| `ButtonElevated`       | default, with leading icon, with trailing icon | enabled, pressed, loading, disabled      |
| `ButtonOutlined`       | idem                                           | idem                                     |
| `ButtonText`           | idem                                           | idem                                     |
| `IconButton`           | flat, with background container                | enabled, pressed, disabled               |
| `TextField`            | with label, with helper, with leading/trailing icon | empty, focused, filled, error, disabled, read-only |
| `Checkbox`             | with label, with helper                        | unchecked, checked, indeterminate, error |
| `Chip`                 | filter (toggle), input, action                 | enabled, selected, disabled              |
| `Card`                 | flat, hero (radius 28), compact                | default, pressed (em interativos)        |
| `BottomSheet`          | header + content + optional action             | —                                        |
| `AppBar`               | flat, with avatar + greeting + actions         | —                                        |
| `Toast`                | success, failure, info                         | entering, visible, exiting               |
| `Skeleton`             | line, circle, rect                             | —                                        |
| `FabExpandable`        | menu + 2 actions                               | collapsed, expanded                      |
| `BadgePill`            | premium, count, status                         | —                                        |
| `AvatarSingle`         | sizes 24/32/40/56                              | image, initials fallback                 |
| `AvatarCombined` ★     | dois sobrepostos (modo casal)                  | image+image, image+initials, etc.        |
| `ExpenseItem`          | list item de despesa                           | default, pressed                         |
| `BudgetProgressBar`    | já existe — manter                             | dynamic color (green→amber→red)          |
| `BudgetCard`           | hero card (radius 28)                          | loading, success, empty, failure         |
| `EmptyState`           | ilustração + texto + CTA opcional              | —                                        |
| `ErrorState`           | ícone + msg + retry                            | —                                        |
| `SegmentedTabs`        | 2-3 segmentos                                  | selected, unselected                     |
| `MoneyDisplay`         | hero (display), inline (body), tabular         | positive, negative, neutral              |

### 7.3 Convenções de componente

- **Alvo de toque mínimo:** 48×48 dp (acessibilidade)
- **Densidade:** confortável (M3 default)
- **Splash:** desabilitado (`NoSplash`) — feedback é via bounce + color change
- **Dark mode:** todos os componentes têm versão dark equivalente
- **Estados de erro:** sempre cor + ícone + texto (nunca só cor)

---

## 8. Constraints & Conventions

### 8.1 Técnicas (não violar)

- **Material 3** — não usar componentes Cupertino nem custom totalmente do zero quando há equivalente M3
- **Sem ConsumerWidget** — telas são `StatelessWidget` com `Consumer` interno (impacta como você pensa em "tela vs. widget reativo" — não muda design, mas mostra que widgets podem ser puros)
- **Single language: pt_BR** — todas as copies em português brasileiro
- **Moeda:** `R$` + valor com `,` como decimal, `.` como milhar
- **Datas:** `DD/MM/YYYY`
- **Centavos como `int`** internamente — mas isso é detalhe de implementação, design exibe sempre formatado

### 8.2 Acessibilidade

- Contraste mínimo WCAG AA (4.5:1 texto normal, 3:1 texto grande)
- Tamanho mínimo de fonte interativa: 14px
- Suporte a Dynamic Type (escalar até 130% sem quebrar)
- Estados de foco visíveis em navegação por teclado/switch
- Labels em todos os ícones-only buttons

### 8.3 Dark mode

**Obrigatório.** Toda tela e componente entregue em ambas as versões. Sistema-based (segue o OS).

### 8.4 Responsividade

App é primariamente mobile portrait. Garantir que funciona bem em:
- iPhone SE (375×667)
- iPhone 15 Pro Max (430×932)
- Pixel 8 (412×915)
- Tablets (lower priority — layout single column é OK, mas com max-width de 600px centralizado)

### 8.5 Out of scope (não desenhar)

- Apple Watch / wearables
- Web app
- Onboarding multi-step (vamos resolver depois — por ora Sign Up direto)
- Internacionalização (en/es) — só pt_BR

---

## 9. Deliverables

A ferramenta deve entregar:

### 9.1 Design system
- Página de **Foundation** (color, typography, spacing, radius, motion, voice)
- Página de **Components** (todos listados em §7.2, com anatomia, variantes, estados, exemplos de uso, do's and don'ts)
- Tokens exportáveis (idealmente JSON ou similar para alimentar tema Flutter)

### 9.2 Mocks de tela
Para **cada tela** listada em §5 e §6:
- Versão **light** + **dark**
- Todos os **estados** relevantes (loading, success, empty, error)
- Versão **com modo casal ativo** + **sem modo casal** quando aplicável
- Anotações nos pontos não-óbvios (motion, copy alternativa, transições)

### 9.3 Fluxos prioritários (clicáveis se a ferramenta suportar)
1. **Onboarding novo usuário**: Sign Up → Home (vazio) → Criar primeiro orçamento → Home (com orçamento) → Criar primeira despesa
2. **Conexão de casal**: Settings → Convidar → Aceite → Home com avatar combinado
3. **Despesa rápida**: Home → FAB → Expense → Calculator → Save → Home (atualizado)
4. **Alerta de estouro**: Home recebe notificação push → tap → Notifications → tap item → Budget Detail

### 9.4 Hand-off
- Specs de espaçamento, fonte, cor por elemento
- Export de assets (ilustrações, ícones custom se houver)
- Lista de componentes M3 padrão usados (pra dev mapear pro Flutter direto)

---

## 10. Inspiração e referências

- **Apps de referência (não copiar):** Monarch Money (clareza tipográfica), YNAB (filosofia de "sobra"), Splitwise (atribuição entre pessoas), Apple Wallet (cards hero)
- **Brasil:** Mobills, Organizze, Guiabolso (ver o que NÃO fazer — geralmente excesso de info, gráficos demais)
- **Visual benchmarks:** Linear, Notion, Things 3 (clareza, calma, motion sutil)

---

## 11. Constraints específicas do nome "Trocado"

- **Logo atual:** existe em `assets/images/logo.webp` — manter ou refinar minimamente, não redesenhar do zero
- **Tom da marca:** brasileiro, descontraído, confiável. **Não** corporate, **não** infantil
- **Possíveis tag lines a explorar:** "Quanto ainda sobra?" / "O dinheiro de vocês, claro." / "Controle simples pra dois."

---

## 12. Critério de pronto

O design está pronto quando:

- [ ] Todos os tokens da §3 estão aplicados consistentemente em todos os mocks
- [ ] Todas as telas das §5 e §6 têm light + dark + estados
- [ ] Componentes da §7.2 estão documentados com anatomia
- [ ] Modo casal está visível em pelo menos 5 telas (Home, Expense, Settings/Casal, Notifications, Budget Detail)
- [ ] Fluxos da §9.3 estão navegáveis ou storyboards completos
- [ ] Nenhuma copy em inglês (exceto nomes de marca/produto)
- [ ] Acessibilidade WCAG AA validada nos textos principais

---

**Última atualização:** 18 abril 2026
**Autor:** time Trocado (Gabriel) + Claude
**Status atual do app:** auth completo, home + budget card refeito recentemente, expense + budget creation funcionais, settings com placeholders, notifications/insights/casal **a desenhar**.
