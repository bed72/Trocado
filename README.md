# Trocado

**Trocado** é um aplicativo de controle financeiro pessoal focado em simplicidade, clareza e performance. O objetivo do projeto é permitir que o usuário registre, visualize e acompanhe suas **entradas e saídas financeiras** de forma intuitiva, com uma base técnica sólida e escalável.

O projeto foi pensado desde o início com **arquitetura limpa**, forte separação de responsabilidades e alta testabilidade, facilitando a evolução contínua do app.

---

## 🧱 Principais Tecnologias

### 🧭 Duck Router

O **Duck Router** é responsável pela navegação do aplicativo.

Principais vantagens:

* Navegação declarativa
* Baixo acoplamento entre telas
* Fácil composição de fluxos
* Integração limpa com Cubits e módulos

Ele permite que cada módulo cuide do seu próprio fluxo de navegação sem espalhar regras pelo app inteiro.

---

### 🧠 Bloc / Cubit

Utilizamos **Bloc (Cubit)** como gerenciador de estado.

Motivações:

* Estados explícitos e previsíveis
* Separação clara entre UI e lógica
* Facilidade de testes unitários
* Controle total de side-effects (snackbars, navegação, etc.)

Cada tela possui seu próprio Cubit, responsável por:

* Carregar dados
* Transformar estado
* Emitir ações para a UI

---

### 🗄️ ObjectBox

O **ObjectBox** é utilizado como banco de dados local.

Benefícios:

* Extremamente rápido
* Tipado
* Ótimo suporte a filtros e queries
* Ideal para uso offline-first

Ele é responsável por persistir as transações localmente e servir como fonte primária de dados do app.

---

## 📱 Status das Telas

### 💸 Tela de Transações

#### ✅ Já temos

- [x] Validação de formulário
- [x] Cadastro de transação
- [x] Feedback visual de cadastro com sucesso

#### 🚧 Falta implementar

- [ ] Formatação de valor em **pt-BR**
- [ ] Testes de **apagar transação**
- [ ] Testes de **editar transação**
- [ ] Feedback visual para **falha no cadastro**

---

### 🏠 Home

#### ✅ Já temos

- [x] Listagem de transações

#### 🚧 Falta implementar

- [ ] Paginação
- [ ] Apagar transação com **swipeable**
- [ ] Filtros (todas / receitas / despesas)
- [ ] Tela de **estado vazio** (sem transações)
- [ ] Cards com **resumo financeiro** (total gasto, entradas, saldo)

---

## 🚀 Próximos Passos

* Refinar experiência de loading e empty states
* Completar cobertura de testes
* Evoluir filtros e paginação
* Melhorar feedbacks visuais

O Trocado está sendo desenvolvido com foco em **qualidade técnica**, **evolução contínua** e **experiência do usuário**.
