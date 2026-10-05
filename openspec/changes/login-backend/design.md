# Desenho

## Fluxo

`AuthController` valida o JSON → `AuthService` normaliza o e-mail e verifica a senha → `AuthRepository` lê admin, professor e aluno → `TokenService` emite token → middleware valida token e existência/status da conta → Service da operação decide permissão.

## Contrato HTTP

`POST /auth/login`: `{ "email": "...", "senha": "..." }`.

Sucesso 200: `{ "access_token": "...", "token_type": "Bearer", "expires_in": 3600, "usuario": { "id": 1, "papel": "admin", "nome": "..." } }`.

Erros: envelope `{codigo, mensagem, campo?}`. Credenciais erradas, conta inativa e e-mail ambíguo recebem a mesma resposta 401.

## Sessão

JWT HS256 com `iss`, `aud`, `sub`, `papel`, `iat` e `exp`, duração de 1 hora. A chave `TOKEN_SIGNING_KEY` (Base64, mínimo 32 bytes) é distinta do pepper. O validador aceita somente HS256, confere assinatura em tempo constante, emissor, audiência, papel e prazo. O middleware consulta o banco para recusar contas removidas ou desativadas. A troca de senha não revoga tokens já emitidos; eles expiram em até 1 hora ou após rotação da chave.

## Limite de autorização

O middleware apenas identifica. `AdminService` e `AlunoService` exigem papel admin para as rotas existentes de administração e cadastro. O primeiro admin ainda depende do provisionamento inicial fora da rota HTTP autenticada.
