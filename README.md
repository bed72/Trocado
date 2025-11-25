# 💸 Trocado

Aplicativo de **finanças pessoais para casais**, desenvolvido em **Flutter**, com foco em simplicidade, modularização e experiência fluida. A proposta é permitir que cada usuário gerencie suas carteiras, categorias e transações, com possibilidade futura de compartilhamento entre parceiros.

---

## 🚀 Tecnologias Utilizadas

* **Flutter (>=3.22)**
* **DuckRouter** para navegação declarativa, deep links e rotas aninhadas
* **Provider** como camada de injeção de dependências e compartilhamento de objetos
* **ChangeNotifier** como mecanismo de gerenciamento de estado, direto e intuitivo
* **Tostore** para persistência local
* **Equatable** para modelos imutáveis e comparações consistentes

---

## 🧭 Navegação com DuckRouter

O projeto utiliza o DuckRouter como solução principal de navegação, garantindo organização clara das rotas, URLs limpas e suporte a deep links. A estrutura de rotas permanece centralizada, facilitando manutenção e expansão.

---

## 📦 Injeção de Dependências com Provider

Toda a camada de infraestrutura (repositórios, serviços, utilidades e notifiers) é fornecida ao app por meio do Provider. Isso permite desacoplamento, testabilidade e fácil substituição de implementações.

---

## 🔄 Gerenciamento de Estado com ChangeNotifier

Os estados da aplicação são gerenciados com ChangeNotifier de forma simples, previsível e centralizada. Cada módulo possui seu próprio notifier responsável por atualizar a interface e coordenar chamadas para repositórios.

---

## 🧪 Estrutura do Projeto

O projeto segue uma arquitetura modularizada por features, com divisão clara de responsabilidades:

* **app/**: tema, roteamento, widgets globais
* **modules/**: organização por funcionalidades (carteiras, categorias, transações)
* **shared/**: modelos, utilidades, repositórios e abstrações comuns
* **main.dart**: inicialização da aplicação

Essa estrutura facilita escalabilidade e manutenção, separando lógica de negócio, estado e interface.

---

## 📲 Como Rodar o Projeto

1. Instale as dependências com `flutter pub get`.
2. Execute o aplicativo com `flutter run`.

---

## 🔐 Licença

```
Copyright (c) 2025 Gabriel Ramos
Todos os direitos reservados.

Este software é propriedade exclusiva de Gabriel Ramos.
É proibida qualquer cópia, modificação, distribuição, comercialização
ou uso sem autorização expressa e por escrito do proprietário.

Contato para autorização: developer.bed@gmail.com
```
