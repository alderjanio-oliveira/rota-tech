# Rota Tech

## Primeiros passos

Passo a passo para rodar o app localmente logo após o `git clone`.

### 1. Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.8.1` (channel stable)
- Um emulador/simulador (Android ou iOS) ou dispositivo físico, ou Chrome para rodar em modo web

Verifique se o ambiente está configurado corretamente:

```
flutter doctor
```

### 2. Instalar as dependências

```
flutter pub get
```

### 3. Configurar variáveis de ambiente

Copie o arquivo de exemplo e ajuste os valores conforme necessário:

```
cp .env.example .env
```

- `BASEURL`: endereço base da API
- `SOCKET_URL`: endereço do servidor de websocket

### 4. Rodar o projeto

```
flutter run
```

## Testes

```
flutter test
```
