@echo off
title XP Internet Fixer - Run as Administrator
echo === XP Internet Fixer ===
echo WARNING: Bu betik sistem ayarlarini degistirir. Yedek alin!
echo Lütfen bu dosyayi YONETICI olarak calistirin.
pause

:: --- 1) Kayıt defteri yedeği al ---
echo [1/9] Registry yedegi aliniyor...
set BACKUP=%~dp0RegistryBackup.reg
reg export "HKLM\SYSTEM\CurrentControlSet\Control" "%BACKUP%" /y >nul 2>&1
if errorlevel 1 (
  echo Registry yedegi ALINAMADI veya yetki yok.
) else (
  echo Yedek alindi: %BACKUP%
)

:: --- 2) TLS 1.2 anahtarlarını ekle (varsa) ---
echo [2/9] TLS 1.2 ayarlari ekleniyor...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols" /f >nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "DisabledByDefault" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1

reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "DisabledByDefault" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v "Enabled" /t REG_DWORD /d 1 /f >nul 2>&1

echo TLS 1.2 kayitlari eklendi (varsa). Not: XP'nin tum TLS yiginini desteklemesi garantili degildir.

:: --- 3) Winsock sıfırlama ---
echo [3/9] Winsock sifirlaniyor...
netsh winsock reset
if errorlevel 1 (
  echo Winsock sifirlama basarisiz veya netsh uyumsuz.
) else (
  echo Winsock sifirlendi.
)

:: --- 4) DNS ayarlarini degistir (IKI yaygin interface adi) ---
echo [4/9] DNS ayarlari yapiliyor...
:: Eger baglanti adi farkliysa bu satirlari duzelt.
netsh interface ip set dns "Local Area Connection" static 1.1.1.1 primary >nul 2>&1
netsh interface ip add dns "Local Area Connection" 8.8.8.8 index=2 >nul 2>&1
netsh interface ip set dns "Wireless Network Connection" static 1.1.1.1 primary >nul 2>&1
netsh interface ip add dns "Wireless Network Connection" 8.8.8.8 index=2 >nul 2>&1
echo DNS'ler 1.1.1.1 ve 8.8.8.8 olarak denendi.
echo Not: Baglanti ismi farkliysa "Local Area Connection" ve "Wireless Network Connection" satirlarini duzenleyin.

:: --- 5) Gereksiz servisleri durdur ve devre disi birak ---
echo [5/9] Gereksiz servisler durduruluyor (Error Reporting, Remote Registry, Messenger, Indexing, Automatic Updates)...
sc stop ERSvc >nul 2>&1
sc config ERSvc start= disabled >nul 2>&1

sc stop RemoteRegistry >nul 2>&1
sc config RemoteRegistry start= disabled >nul 2>&1

sc stop Messenger >nul 2>&1
sc config Messenger start= disabled >nul 2>&1

sc stop cisvc >nul 2>&1
sc config cisvc start= disabled >nul 2>&1

sc stop wuauserv >nul 2>&1
sc config wuauserv start= disabled >nul 2>&1

echo Servis islemleri tamamladi (bazilari sistemde olmayabilir).

:: --- 6) Temp dosyalarini temizle ---
echo [6/9] Temp dosyalari temizleniyor...
del /q /s "%TEMP%\*" >nul 2>&1
del /q /s "%USERPROFILE%\Local Settings\Temp\*" >nul 2>&1
for /d %%D in ("%USERPROFILE%\Local Settings\Temporary Internet Files\*") do rd /s /q "%%D" >nul 2>&1
echo Temp temizligi tamamlandi.

:: --- 7) Ağ adaptörü sürücüsünü yenileme (uygulama talebi) ---
echo [7/9] Ag adaptoru yeniden başlatilacak (dongu). Bazi durumlarda adaptr yeniden takilmalidir.
ipconfig /release >nul 2>&1
timeout /t 2 >nul
ipconfig /renew >nul 2>&1
echo IP bilgileri yenilendi.

:: --- 8) Kullaniciya saati kontrol ettir ---
echo [8/9] Lütfen bilgisayar saatini kontrol edin. HTTPS icin dogru saat gerekiyor.
echo Saat: 
time /t
echo Tarih:
date /t
echo Saat hataliysa Ayarlar > Tarih ve Saat'den duzeltin.

:: --- 9) Son islemler ve yeniden baslatma istegi ---
echo [9/9] Islemler tamamlandi.
echo Lutfen bilgisayari simdi yeniden baslati (REBOOT) - Winsock ve TLS degisiklikleri icin GEREKLI.
echo Yeniden baslatmak istiyor musunuz? (E/H)
choice /c YN /n /m "Yeniden baslat? [Y/N]" >nul
if errorlevel 2 goto noReboot
if errorlevel 1 goto doReboot

:doReboot
echo Bilgisayar yeniden baslatiliyor...
shutdown -r -t 5
goto end

:noReboot
echo Yeniden baslatilmadi. Lütfen el ile yeniden baslatin.
goto end

:end
echo Bitti.
pause