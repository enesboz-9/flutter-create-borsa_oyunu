@echo off
chcp 65001 >nul
setlocal

rem ==== Ayarlar ====
set "REPO_URL=https://github.com/enesboz-9/flutter-create-borsa_oyunu.git"
set "BRANCH=main"
rem =================

cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
  echo Git bulunamadi. Once Git'i kur: https://git-scm.com/download/win
  pause
  exit /b 1
)

if not exist ".git" (
  echo Git deposu olusturuluyor...
  git init
  git branch -M %BRANCH%
  git remote add origin %REPO_URL%
  echo Uzak depodaki mevcut dosyalar cekiliyor...
  git pull origin %BRANCH% --allow-unrelated-histories --no-edit
)

git remote get-url origin >nul 2>nul
if errorlevel 1 git remote add origin %REPO_URL%

for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm"') do set "STAMP=%%i"

git add -A

git diff --cached --quiet
if errorlevel 1 (
  git commit -m "Otomatik guncelleme %STAMP%"
  if errorlevel 1 goto :error
) else (
  echo Commit edilecek yeni degisiklik yok.
)

git push -u origin %BRANCH%
if errorlevel 1 goto :error

echo.
echo Push tamamlandi.
timeout /t 3 >nul
exit /b 0

:error
echo.
echo Bir hata olustu. Yukaridaki mesaji kontrol et.
pause
exit /b 1
