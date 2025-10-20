# Configuração dos Ícones do Clisync

## Instruções para Configurar o Logo do Aplicativo

### 1. Instalar Dependências
Execute no terminal dentro da pasta do projeto:
```bash
flutter pub get
```

### 2. Gerar Ícones Automaticamente
Execute o comando para gerar todos os ícones:
```bash
flutter pub run flutter_launcher_icons:main
```

### 3. Configuração Manual (Alternativa)

Se o comando automático não funcionar, você pode copiar manualmente o arquivo `lib/image/logo-clisync.png` para as seguintes pastas:

#### Android:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

#### Web:
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

#### iOS:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (várias resoluções)

#### Windows:
- `windows/runner/resources/app_icon.ico`

#### macOS:
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (várias resoluções)

### 4. Limpar e Rebuildar
Após configurar os ícones:
```bash
flutter clean
flutter pub get
flutter run
```

## Arquivo de Configuração

O arquivo `pubspec.yaml` já está configurado com:
- Dependência `flutter_launcher_icons: ^0.13.1`
- Configuração para todas as plataformas
- Caminho para o logo: `lib/image/logo-clisync.png`

## Verificação

Após executar os comandos, verifique se:
1. Os ícones aparecem corretamente na tela inicial do dispositivo
2. O aplicativo mostra o logo do Clisync quando instalado
3. Não há erros durante o build
