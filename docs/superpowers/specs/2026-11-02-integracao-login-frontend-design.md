# Integração do login no frontend

## Intenção

Conectar a `LoginScreen` existente ao `POST /auth/login`, preservando integralmente seus componentes, textos, cores, tamanhos e o contrato atual do backend.

## Objetivos

- Enviar e-mail e senha digitados para o backend.
- Manter cliente HTTP, repository e estado fora da tela.
- Manter token e identidade autenticada somente em memória.
- Exibir o estado visual já existente quando o backend responder `401`.
- Impedir duas submissões simultâneas sem introduzir indicador visual novo.
- Substituir a rota de login após sucesso:
  - `admin` → `TelaInicioAdmin`;
  - `aluno` → `TelaAgendaAluno`;
  - `professor` → `MeusAlunosScreen`.

## Não objetivos

- Alterar o endpoint ou qualquer regra de autenticação do backend.
- Alterar o layout ou os textos da tela de login.
- Persistir token em disco, navegador ou `SharedPreferences`.
- Integrar logout ou demais rotas autenticadas nesta entrega.
- Criar a home definitiva do professor.
- Criar mensagens visuais específicas para `429`, indisponibilidade ou erro inesperado.

## Restrições

- O app continua sem decidir autorização; `usuario.papel` serve apenas para escolher a interface inicial.
- A URL da API vem de `API_BASE_URL` por `--dart-define`.
- Alterações locais já existentes no worktree, especialmente em `app/pubspec.yaml`, devem ser preservadas.
- O asset atual da tela de login, `assets/images/marca.png`, deve ser declarado sem remover os assets já adicionados localmente.

## Abordagens consideradas

### 1. Alterar somente o comportamento, preservando o visual — escolhida

A tela lê um controller Riverpod, envia os valores dos controllers existentes e navega após o resultado. Cliente HTTP, parse, sessão e erros permanecem em arquivos separados. É coerente com o README da feature e mantém a alteração visual em zero.

### 2. Manter `login_screen.dart` totalmente intocado

Exigiria interceptação externa do toque ou sobreposição de widgets. Foi descartada por ser frágil, difícil de testar e incompatível com o botão que hoje possui comportamento simulado próprio.

### 3. Fazer a chamada HTTP diretamente na tela

Foi descartada porque mistura UI, transporte, contrato e sessão, além de contrariar a estrutura `data/`, `state/` e `screens/` documentada para a feature.

## Arquitetura aprovada

```text
LoginScreen
    ↓
AuthController (Riverpod)
    ↓
AuthRepository
    ↓
ApiClient
    ↓
POST /auth/login
```

`LoginResponseDto` será desserializado no pacote `shared`. O controller manterá a resposta autenticada somente em memória e devolverá um resultado explícito à tela. A tela continuará usando `_credenciaisInvalidas` somente para credenciais inválidas e fará `pushReplacement` para o destino correspondente ao papel.

Erros diferentes de `401` serão absorvidos como falha não visual nesta etapa: a tela permanece disponível para nova tentativa e não mostra uma mensagem incorreta de credenciais inválidas.

