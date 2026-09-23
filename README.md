# CliSync

Aplicativo de gestão para prestadores de serviços e empresas que trabalham com clientes, serviços, planos, pagamentos e agendamentos.

**Versão apresentada:** `1.0.0+9`  
**Plataforma:** Android  
**Tecnologia:** Flutter 3.47.0 / Dart  
**Backend:** Firebase  
**Banco:** Firebase Realtime Database  
**Autenticação:** Firebase Authentication

## Objetivo

O CliSync centraliza a organização de empresas que trabalham com prestação de serviços e agendamentos, reunindo clientes, serviços, planos, pagamentos, agendamentos, histórico e informações de análise em uma única aplicação.

O produto foi desenvolvido inicialmente considerando a realidade da Souza Líder Segurança, mas sua proposta também atende outras empresas que trabalham com atendimento, prestação de serviços e agendamento.

## Tecnologias

- Flutter 3.47.0
- Dart
- Firebase Authentication
- Firebase Realtime Database
- Firebase Core
- Google Fonts
- Intl
- Shared Preferences
- URL Launcher
- Mask Text Input Formatter
- Android

## Estrutura principal

```text
lib/
├── image/
├── models/
├── screens/
│   ├── auth/
│   ├── clientes/
│   ├── configuracao/
│   ├── home/
│   ├── metas/
│   ├── onboarding/
│   └── relatorios/
├── services/
├── theme/
├── utils/
├── firebase_options.dart
└── main.dart
```

## Recursos entregues

- autenticação e login;
- onboarding;
- gerenciamento de clientes;
- pesquisa e consulta de clientes;
- serviços;
- planos;
- serviços avulsos;
- pagamentos e acompanhamento financeiro;
- inadimplência;
- agendamentos;
- histórico;
- relatórios;
- gráficos;
- filtros;
- rankings;
- configurações;
- formulário web de agendamento.

## Acesso pelo usuário

A versão Android está publicada na Google Play:

https://play.google.com/store/apps/details?id=br.com.clisync.app

## Execução local

Pré-requisitos:

- Flutter 3.47.0;
- Android SDK configurado;
- Android Studio;
- dispositivo Android ou emulador;
- configuração do Firebase utilizada pelo projeto.

```bash
git clone https://github.com/AugustoNX/Clisync.git
cd Clisync/Clisync
flutter pub get
flutter run
```

Para verificar o ambiente:

```bash
flutter doctor
```

As configurações/credenciais do Firebase necessárias para desenvolvimento devem ser obtidas com o responsável pelo projeto e não devem ser expostas publicamente.

## Fluxos principais

### Login → Home → Cliente → Agendamento

1. Abrir o aplicativo.
2. Realizar login.
3. Acessar a Home.
4. Entrar em Clientes.
5. Abrir um cliente.
6. Acessar o fluxo de agendamento.
7. Criar ou consultar o agendamento.

### Cadastro pelo formulário web

1. Acessar o formulário web.
2. Preencher os dados.
3. Enviar.
4. Validar o resultado.
5. Conferir o registro das informações.

Formulário:

https://clisync.com.br/agendamento/

## Problemas conhecidos e limitações

- algumas telas possuem layout desatualizado e precisam de uma nova etapa de refinamento visual;
- a versão atual não possui integração com meios de pagamento externos;
- melhorias de UX/UI permanecem planejadas.

## O que foi atendido

A versão `1.0.0+9` possui aplicativo Android funcional, publicação na Google Play, autenticação, clientes, serviços, planos, pagamentos, agendamentos, relatórios, Firebase e formulário web.

## O que ficou para depois

- integração com meios de pagamento;
- atualização visual;
- melhorias de UX/UI;
- novas integrações conforme necessidade dos usuários.

## Identificação da versão

```text
Produto: CliSync
Versão: 1.0.0
Build: 9
Flutter: 3.47.0
Plataforma: Android
```

## Repositório

https://github.com/AugustoNX/Clisync/tree/main/Clisync
