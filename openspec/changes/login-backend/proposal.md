# Login do backend — F-01

## Objetivo

Permitir login por e-mail e senha para aluno, professor e admin, conforme D19, D59 e D61, e transportar a identidade autenticada às rotas do backend.

## Escopo

- Leitura das três tabelas de pessoas pela feature `auth`, sem escrita.
- Verificação do hash PHC Argon2id com `SENHA_PEPPER`.
- `POST /auth/login` com DTO compartilhado e erro codificado.
- Token Bearer assinado e middleware de identidade.
- Restrição das rotas existentes de admin e cadastro de aluno ao papel admin.

## Fora do escopo

Refresh token, recuperação de senha, app Flutter e matriz RBAC completa das features futuras.
