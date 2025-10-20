# Clisync 📱

Aplicativo de controle de orçamento para empresa de vigilância desenvolvido em Flutter.

## 🚀 Características

- **Autenticação**: Sistema de login e registro com Firebase Auth
- **Banco de Dados**: Firebase Realtime Database para armazenamento de dados
- **Interface**: Design moderno e responsivo
- **Relatórios**: Geração de relatórios em PDF
- **Multiplataforma**: Suporte para Android, iOS, Web, Windows, macOS e Linux

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento multiplataforma
- **Firebase**: Backend como serviço (Auth, Database)
- **Dart**: Linguagem de programação
- **Google Fonts**: Tipografia personalizada
- **PDF**: Geração de relatórios
- **Intl**: Internacionalização

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.1.1
  firebase_auth: ^6.1.0
  firebase_database: ^12.0.2
  google_fonts: ^6.1.0
  pdf: ^3.11.1
  printing: ^5.13.2
  path_provider: ^2.1.4
```

## 🔧 Configuração do Projeto

### Pré-requisitos

- Flutter SDK (versão 3.8.1 ou superior)
- Dart SDK
- Android Studio / VS Code
- Git

### Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/AugustoNX/Clisync.git
   cd Clisync
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase**
   - O projeto já está configurado com o Firebase
   - Database URL: `https://clisync-4bff7-default-rtdb.firebaseio.com`
   - Project ID: `clisync-4bff7`

4. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 📱 Plataformas Suportadas

- ✅ **Android** - APK nativo
- ✅ **iOS** - App Store
- ✅ **Web** - PWA
- ✅ **Windows** - Executável
- ✅ **macOS** - App Bundle
- ✅ **Linux** - AppImage/Snap

## 🎨 Personalização

### Ícones do Aplicativo

O projeto está configurado para usar o logo personalizado do Clisync:

```bash
# Gerar ícones automaticamente
flutter pub run flutter_launcher_icons:main
```

### Configuração do Firebase

As configurações do Firebase estão em `lib/firebase_options.dart` e incluem:

- **Web**: Configuração completa com analytics
- **Android**: Configuração para aplicativo móvel
- **iOS**: Configuração com bundle ID `com.example.clisync`
- **macOS**: Configuração com bundle ID `com.example.clisync`
- **Windows**: Configuração para aplicativo desktop

## 📁 Estrutura do Projeto

```
lib/
├── firebase_options.dart    # Configurações do Firebase
├── main.dart               # Ponto de entrada da aplicação
├── models/                 # Modelos de dados
│   ├── cliente.dart
│   └── usuario.dart
├── screens/                # Telas da aplicação
│   ├── auth/               # Autenticação
│   ├── clientes/           # Gestão de clientes
│   ├── home/               # Tela principal
│   └── relatorios/         # Relatórios
├── services/               # Serviços
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── pdf_service.dart
├── theme/                  # Tema da aplicação
│   └── app_theme.dart
└── utils/                  # Utilitários
    └── string_utils.dart
```

## 🔐 Segurança

- Autenticação segura com Firebase Auth
- Dados protegidos no Firebase Realtime Database
- Validação de entrada em todos os formulários

## 📊 Funcionalidades

### Autenticação
- Login com email e senha
- Registro de novos usuários
- Recuperação de senha

### Gestão de Clientes
- Cadastro de clientes
- Listagem de clientes
- Edição de informações

### Relatórios
- Geração de relatórios em PDF
- Relatórios mensais
- Relatórios de pendências

## 🚀 Deploy

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Linux
```bash
flutter build linux --release
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Desenvolvedor

**Augusto NX**
- GitHub: [@AugustoNX](https://github.com/AugustoNX)

## 📞 Suporte

Se você encontrar algum problema ou tiver dúvidas, por favor abra uma issue no GitHub.

---

**Clisync** - Controle de orçamento para empresas de vigilância 🛡️