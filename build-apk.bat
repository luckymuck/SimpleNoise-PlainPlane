@echo off
REM ============================================
REM  Build APK for Noise Generator
REM  Requires: Node.js, Java JDK 11+, Android SDK
REM ============================================

echo Checking prerequisites...

where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js not found. Install from https://nodejs.org/
    pause
    exit /b 1
)

where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Java JDK not found. Install JDK 11+ from https://adoptium.net/
    pause
    exit /b 1
)

if "%ANDROID_HOME%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
    ) else (
        echo [ERROR] Android SDK not found. Set ANDROID_HOME or install Android Studio.
        pause
        exit /b 1
    )
)
echo [OK] ANDROID_HOME = %ANDROID_HOME%

REM Use JDK bundled with Android Studio if available (avoids version conflicts with Gradle)
if exist "C:\Program Files\Android\Android Studio\jbr" (
    set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
    echo [OK] Using JDK from Android Studio: %JAVA_HOME%
)

set PROJECT_DIR=%~dp0
set CORDOVA_APP=%PROJECT_DIR%noise-android

REM Delete old project for clean build
if exist "%CORDOVA_APP%" rmdir /s /q "%CORDOVA_APP%"

echo Creating Cordova project...
call cordova create "%CORDOVA_APP%" plain.plane.simple "Noise Generator"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to create Cordova project.
    pause
    exit /b 1
)

echo Copying app files...
xcopy /E /Y "%PROJECT_DIR%www" "%CORDOVA_APP%\www\" >nul
copy /Y "%PROJECT_DIR%config.xml" "%CORDOVA_APP%\config.xml" >nul

echo Installing cordova-android...
cd /d "%CORDOVA_APP%"
call npm install cordova-android >nul 2>&1

echo Creating Android platform...
cd /d "%CORDOVA_APP%"
node -e "const p=require('path'),f=require('fs'),e=require('cordova-common').events,C=require('cordova-common').ConfigParser,A=require('cordova-android/lib/Api');(async()=>{const c=new C(p.join(process.cwd(),'config.xml')),d=p.join(process.cwd(),'platforms','android');f.mkdirSync(p.dirname(d),{recursive:true});await A.createPlatform(d,c,{},e);console.log('OK')})().catch(e=>console.log('ERR:'+e.message))"

REM Add AndroidX support
echo android.useAndroidX=true> "%CORDOVA_APP%\platforms\android\gradle.properties"
echo android.enableJetifier=true>> "%CORDOVA_APP%\platforms\android\gradle.properties"

REM Generate Gradle wrapper and build
cd /d "%CORDOVA_APP%\platforms\android"
call gradle wrapper --gradle-version 8.13 >nul 2>&1

echo Building release APK...
call gradlew assembleRelease
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo Building Android App Bundle (AAB)...
call gradlew bundleRelease
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] AAB build failed.
    pause
    exit /b 1
)

set KEYSTORE=%PROJECT_DIR%noise-app.keystore
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr

set APK_UNSIGNED=%CORDOVA_APP%\platforms\android\app\build\outputs\apk\release\app-release-unsigned.apk
set APK_SIGNED=%CORDOVA_APP%\platforms\android\app\build\outputs\apk\release\noise-app-signed.apk
set AAB_UNSIGNED=%CORDOVA_APP%\platforms\android\app\build\outputs\bundle\release\app-release.aab
set AAB_SIGNED=%CORDOVA_APP%\platforms\android\app\build\outputs\bundle\release\noise-app-signed.aab

if exist "%KEYSTORE%" (
    echo Signing APK...
    "%ANDROID_HOME%\build-tools\37.0.0\apksigner" sign --ks "%KEYSTORE%" --ks-key-alias noise-app --ks-pass pass:password --out "%APK_SIGNED%" "%APK_UNSIGNED%"
    if exist "%APK_SIGNED%" echo [OK] Signed APK: %APK_SIGNED%

    echo Signing AAB...
    copy /Y "%AAB_UNSIGNED%" "%AAB_SIGNED%" >nul
    "%JAVA_HOME%\bin\jarsigner" -keystore "%KEYSTORE%" -storepass password -keypass password "%AAB_SIGNED%" noise-app >nul 2>&1
    if exist "%AAB_SIGNED%" echo [OK] Signed AAB: %AAB_SIGNED%
) else (
    echo [WARN] No keystore found at %KEYSTORE%
    echo Build unsigned only.
)

echo.
echo ============================================
echo  Debug APK for testing:
echo  %CORDOVA_APP%\platforms\android\app\build\outputs\apk\debug\app-debug.apk
echo.
echo  Signed APK:
if exist "%APK_SIGNED%" echo  %APK_SIGNED%
echo.
echo  Signed AAB (for Play Store):
if exist "%AAB_SIGNED%" echo  %AAB_SIGNED%
echo ============================================
pause
