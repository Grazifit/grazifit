# Login Backend Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate the existing login screen with `POST /auth/login`, retain the authenticated session only in memory, and route known roles without changing the screen's visual design or the backend method.

**Architecture:** Keep the specified `LoginScreen -> AuthController -> AuthRepository -> ApiClient` flow. Riverpod owns the in-memory auth state; the HTTP client normalizes transport and protocol failures; the screen only coordinates input, error display, and replacement navigation.

**Tech Stack:** Flutter, Dart 3.13, flutter_riverpod 2.6.1, http 1.6.0, flutter_test.

**Spec:** `C:/Users/sn/.codex/attachments/db1239f6-439a-47ab-8086-dd31be98efff/Texto colado.txt`

## Global Constraints

- Preserve every existing visual property, text, spacing, image, gradient, and component on the login screen.
- Do not modify backend implementation files or endpoint behavior.
- Keep access tokens only in Riverpod's in-memory state; never log credentials, tokens, request bodies, or authorization headers.
- Only HTTP 401 maps to the visible “E-mail ou senha inválidos” state.
- Prevent concurrent login requests and use `pushReplacement` only for `admin`, `aluno`, and `professor`.

## Review Focus

- A malformed success payload must become a controlled generic failure, never a `TypeError` or widget exception.
- An unknown role must remain on login without privileged navigation.
- A second tap while a request is pending must not issue another request.
- A stale 401 message must disappear synchronously when a new attempt starts.
- Missing `API_BASE_URL` must fail safely without exposing entered credentials.

---

### Task 1: Dependencies and strict login response DTO

**Files:**
- Modify: `app/pubspec.yaml`
- Modify: `shared/lib/dtos/auth_dto.dart`
- Create: `shared/test/dtos/auth_dto_test.dart`

**Interfaces:**
- Produces: `LoginResponseDto.fromJson(Map<String, dynamic>)` with strict field validation and `FormatException` failures.

- [ ] Write DTO tests for a complete response and every invalid field/type named by the spec.
- [ ] Run `dart test test/dtos/auth_dto_test.dart` from `shared` and verify RED because `fromJson` is absent.
- [ ] Add the minimal strict `fromJson` implementation and app dependencies (`flutter_riverpod`, `http`, local `shared`) without changing existing asset declarations.
- [ ] Run the DTO tests and verify GREEN.

### Task 2: Controlled HTTP client and authentication repository

**Files:**
- Create: `app/lib/core/network/api_exception.dart`
- Create: `app/lib/core/network/api_client.dart`
- Create: `app/lib/features/auth/data/auth_repository.dart`
- Create: `app/test/core/network/api_client_test.dart`
- Create: `app/test/features/auth/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `LoginResponseDto.fromJson` from Task 1.
- Produces: `ApiClient.postJson(String path, Map<String, Object?> body)` and `AuthRepository.login({required String email, required String senha})`.

- [ ] Write failing tests for URL/body/header, 2xx JSON, 401, 429 plus `Retry-After`, timeout, connection failure, malformed JSON, missing base URL, and non-disclosure of secrets.
- [ ] Run the focused tests and verify RED because the network classes are absent.
- [ ] Implement the minimal typed exception, injectable HTTP client with timeout, and repository mapping `/auth/login` to the DTO.
- [ ] Run the focused tests and verify GREEN.

### Task 3: In-memory authentication controller

**Files:**
- Create: `app/lib/features/auth/state/auth_state.dart`
- Create: `app/lib/features/auth/state/auth_controller.dart`
- Create: `app/test/features/auth/state/auth_controller_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.login` from Task 2.
- Produces: `authControllerProvider`, `AuthController.login(String email, String senha)`, `AuthStatus`, and in-memory `AuthState.sessao`.

- [ ] Write failing tests for successful in-memory session, 401-only invalid credentials, generic 429 failure, malformed response failure, and concurrent-call suppression.
- [ ] Run the focused controller tests and verify RED.
- [ ] Implement the minimal Riverpod controller/provider and explicit auth states.
- [ ] Run the focused tests and verify GREEN.

### Task 4: Login screen behavior and role navigation

**Files:**
- Modify: `app/lib/features/auth/screens/login_screen.dart`
- Create: `app/test/features/auth/screens/login_screen_test.dart`

**Interfaces:**
- Consumes: `authControllerProvider` and `LoginResponseDto` from Tasks 1–3.
- Produces: button-driven `_entrar()` behavior while preserving the existing widget tree and styling.

- [ ] Write widget tests that enter credentials, verify immediate stale-error clearing, 401-only copy, duplicate-tap suppression, all three role destinations, unknown-role denial, and safe generic failures.
- [ ] Run the widget tests and verify RED against the prototype callback.
- [ ] Add `_entrar`, state-derived error handling, mounted check, and `pushReplacement` mapping; change only behavior-related screen code and imports.
- [ ] Run the widget tests and verify GREEN, including structural assertions for the existing components.

### Task 5: Application initialization, Android permission, and full validation

**Files:**
- Modify: `app/lib/main.dart`
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Create: `app/test/main_test.dart`

**Interfaces:**
- Consumes: `LoginScreen` and `authControllerProvider`.
- Produces: a `ProviderScope`-wrapped app whose home is `LoginScreen`, plus release internet permission.

- [ ] Write failing tests for the initial login screen and manifest internet permission.
- [ ] Run focused tests and verify RED against the development menu/manifest.
- [ ] Implement the minimal `ProviderScope` app initialization and add the main-manifest permission.
- [ ] Run `flutter test`, `flutter analyze`, and `flutter build web --dart-define=API_BASE_URL=http://localhost:8080`; verify all exit successfully.
- [ ] Review the final diff to confirm no backend file or login visual property changed.
