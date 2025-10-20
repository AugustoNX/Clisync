@echo off
echo Limpando cache do Gradle e Flutter...

REM Limpar cache do Flutter
flutter clean

REM Limpar cache do Gradle
cd android
gradlew clean
cd ..

REM Limpar pasta build
rmdir /s /q build
rmdir /s /q android\app\build

echo Cache limpo com sucesso!
echo.
echo Tentando remover diretorio antigo novamente...
rmdir /s /q "android\app\src\main\kotlin\com\example\vigilancia_app"

echo.
echo Estrutura atual:
dir "android\app\src\main\kotlin\com\example"

pause
