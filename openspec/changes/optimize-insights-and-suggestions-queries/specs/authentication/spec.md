## MODIFIED Requirements

### Requirement: Política temporal de sessão única e independente do framework

O sistema MUST centralizar em Identity Domain a política fixa de validade de 30 dias, janela inclusiva de extensão de 15 dias e idade máxima de 90 dias. Emissão, extensão e validação do token MUST reutilizar essa política com datas explícitas. O Port de extensão MUST NOT receber limites escolhidos pelo caller. A Infrastructure MUST resolver o relógio e MUST reler a persistência para avaliar elegibilidade, sem depender apenas do Model carregado durante autenticação. Quando houver possibilidade de extensão, MUST reler com lock dentro da transação e recalcular a política sobre o estado bloqueado antes de qualquer escrita. Uma leitura fresca que não indique extensão MUST retornar sem lock/transação de renovação.

#### Scenario: Emissão e validação usam a mesma política
- **WHEN** o sistema emite ou valida um Personal Access Token
- **THEN** a validade inicial e o limite absoluto são definidos pela mesma política pura de Identity
- **AND** os Adapters e o provider não duplicam os limites temporais

#### Scenario: Extensão sobre o estado bloqueado
- **WHEN** a capacidade de extensão é invocada diretamente ou após requisição elegível e a leitura fresca indica possibilidade de renovar
- **THEN** o Adapter relê o token com lock e fornece suas datas atuais à política antes da escrita
- **AND** não recebe parâmetros para ampliar a janela, a validade ou a idade máxima

#### Scenario: Sem possibilidade de extensão na leitura fresca
- **WHEN** a persistência não contém o PAT ou a política sobre suas datas atuais não indica extensão
- **THEN** a capacidade não abre transação de renovação nem adquire lock no PAT
- **AND** não renova, recria, autentica novamente ou concede nova validade pelo Model antigo

#### Scenario: Prazo encurtado depois da autenticação
- **WHEN** o Model autenticado ainda tem prazo distante mas a persistência já foi encurtada para dentro da janela de renovação
- **THEN** a leitura fresca detecta a possibilidade e a decisão final usa o estado relido sob lock
- **AND** se o registro tiver sido expirado, revogado ou estendido antes desse lock, a política é recalculada sem ressuscitar ou encurtar o prazo

#### Scenario: Mudança ainda não confirmada na decisão de não renovar
- **WHEN** outra transação modifica o PAT mas ainda não confirmou e a leitura fresca observa um estado sem possibilidade de extensão
- **THEN** a capacidade termina sem aguardar o lock de renovação nem escrever baseada no Model antigo
- **AND** uma nova invocação após o commit reavalia a persistência confirmada, preservando renovação elegível e rejeição de expirados/revogados na próxima autenticação
