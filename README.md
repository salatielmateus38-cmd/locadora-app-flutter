# Locadora — app Flutter

Versão mobile do projeto web **Sistema de Locação de Veículos** (Programação com Frameworks Web, UNIPÊ),
reescrita em Flutter. Não usa backend nem banco: os dados ficam em memória e são recriados a cada abertura
do app, mas todas as regras de negócio da API original foram mantidas.

## Funcionalidades

- Login e cadastro (novos usuários recebem o perfil **Cliente**)
- Catálogo de veículos com busca, filtro por categoria e por status e resumo da frota
- Locação com escolha de datas e valor estimado calculado na hora
- "Minhas locações" com filtro, aviso de atraso e registro de devolução
- Administrador: cadastra, edita e exclui veículos e vê as locações de todos os clientes
- Perfil com resumo e logout

## Regras de negócio

- Só veículos **Disponíveis** podem ser alugados; ao alugar, passam para **Locado**.
- A retirada não pode ser no passado e a devolução prevista deve ser posterior à retirada.
- A diária fica registrada na locação (mudanças de preço não afetam locações existentes).
- Na devolução, o valor final considera os dias efetivamente usados (mínimo de 1 diária).
- Placa aceita os padrões antigo (`ABC1234`) e Mercosul (`ABC1D23`) e é única.
- Veículos locados não podem mudar de status nem ser excluídos; veículos com histórico não podem ser excluídos.

## Contas de demonstração

| Perfil        | E-mail               | Senha      |
| ------------- | -------------------- | ---------- |
| Administrador | admin@locadora.com   | admin123   |
| Cliente       | maria@locadora.com   | 123456     |
| Cliente       | joao@locadora.com    | 123456     |

Na tela de login há atalhos que preenchem essas contas.

## Estrutura

```
lib/
├── main.dart              app, tema, localização pt-BR e AuthGate
├── app_store.dart         "banco" em memória + regras de negócio (ChangeNotifier)
├── models.dart            User, Vehicle, Rental e enums
├── format.dart            moeda (R$) e datas
├── theme.dart             cores e tema Material 3
├── widgets/common.dart    badges, imagem do veículo, diálogos
└── pages/                 login/cadastro, veículos, locação, locações, formulário e perfil
assets/images/             fotos dos carros
test/                      testes das regras de negócio e do fluxo de login
```

## Como rodar

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) com Dart 3.9 ou superior (conforme `pubspec.yaml`).

```bash
cd locadora_app
flutter create . --platforms=android,web   # gera as pastas de plataforma (só na primeira vez)
flutter pub get
flutter run
flutter test
```

> **Windows:** o caminho desta pasta tem acentos (`UNIPÊ`, `PROGRAMAÇÃO`) e o Gradle do Android recusa
> caminhos com caracteres não ASCII. Depois do `flutter create`, adicione `android.overridePathCheck=true`
> em `android/gradle.properties` ou copie o projeto para um caminho simples (ex.: `C:\dev\locadora_app`).
> No navegador (`flutter run -d chrome`) isso não acontece.
