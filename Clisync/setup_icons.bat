@echo off
echo Configurando icones do aplicativo Clisync...

REM Copiar logo para Android (todas as densidades)
copy "lib\image\logo-clisync.png" "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
copy "lib\image\logo-clisync.png" "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
copy "lib\image\logo-clisync.png" "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
copy "lib\image\logo-clisync.png" "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
copy "lib\image\logo-clisync.png" "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

REM Copiar logo para Web
copy "lib\image\logo-clisync.png" "web\icons\Icon-192.png"
copy "lib\image\logo-clisync.png" "web\icons\Icon-512.png"
copy "lib\image\logo-clisync.png" "web\icons\Icon-maskable-192.png"
copy "lib\image\logo-clisync.png" "web\icons\Icon-maskable-512.png"

echo Icones configurados com sucesso!
pause
