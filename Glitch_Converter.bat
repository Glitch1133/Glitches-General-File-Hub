@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Glitch's General File Hub

rem ====== Folders ======
set "ROOT=%~dp0"
set "TOOLS=%ROOT%tools"
set "OUT=%ROOT%downloads"
set "COMP=%ROOT%compressed"
set "CONV=%ROOT%converted"
set "IMGCONV=%CONV%\images"
set "TMP=%TOOLS%\_tmp"
for %%D in ("%TOOLS%" "%OUT%" "%COMP%" "%CONV%" "%IMGCONV%" "%TMP%") do if not exist "%%~fD" mkdir "%%~fD" >nul 2>nul

rem ====== Tools & files ======
set "YTDLP=%TOOLS%\yt-dlp.exe"
set "FFMPEG=%TOOLS%\ffmpeg.exe"
set "FFPROBE=%TOOLS%\ffprobe.exe"
set "COOKFILE=%TOOLS%\cookies.txt"
set "LOG=%TMP%\last.log"

rem ====== Download URLs ======
set "YTDLP_URL1=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
set "YTDLP_URL2=https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp.exe"
set "FF_URL1=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
set "FF_URL2=https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.zip"
set "FF_URL3=https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-n6.1-latest-win64-gpl-essentials.zip"

rem ====== yt-dlp flags ======
set "COMMON=--no-part --no-mtime --no-continue --force-overwrites --http-chunk-size 10M --retries 20 --fragment-retries 20 --retry-sleep 2"
set "FMT_MP4=-f bv*[ext=mp4]+ba[ext=m4a]/bv*[vcodec^=avc1]+ba[acodec^=mp4a]/b[ext=mp4]"
set "FMT_MUTE=-f bv*[ext=mp4]/bv*[vcodec^=avc1]/bv"
set "FMT_MP3=-f ba/b"

rem =========================
rem MAIN MENU
rem =========================
:hub
cls
echo ================================
echo     Glitch's General File Hub
echo ================================
echo 1^) Link Converter
echo 2^) Media Compressor (manual duration)
echo 3^) File Extension Converter
echo 4^) Image Converter
echo 5^) Exit
echo.
set "hopt="
set /p "hopt=Choose 1-5 (M/B to menu): "
if /I "%hopt%"=="M"  goto hub
if /I "%hopt%"=="B"  goto hub
if "%hopt%"=="1"     goto converter_menu
if "%hopt%"=="2"     goto media_comp_manual
if "%hopt%"=="3"     goto ext_converter
if "%hopt%"=="4"     goto image_converter
if "%hopt%"=="5"     goto end
goto hub

rem -----------------------------------------------------------
rem  LINK CONVERTER (cookies.txt only)  + FULL PLAYLIST SUPPORT
rem -----------------------------------------------------------
:converter_menu
call :ensure_yt_dlp
call :ensure_ffmpeg
:conv_menu_again
cls
echo ========= Link Converter =========
if exist "%COOKFILE%" (echo Cookies: "%COOKFILE%") else (echo Cookies: NOT FOUND ^- we'll help you create it)
echo Output : "%OUT%"
echo.
echo 1^) MP4 (video, AAC)
echo 2^) MP3 (audio only)
echo 3^) MP4 (no audio)
echo 4^) Update yt-dlp
echo 5^) Open downloads folder
echo 6^) Back to Hub
echo.
set "opt="
set /p "opt=Choose 1-6 (M/B to menu): "
if /I "%opt%"=="M"  goto hub
if /I "%opt%"=="B"  goto hub
if "%opt%"=="6"     goto hub
if "%opt%"=="4"     goto update_ytdlp
if "%opt%"=="5"     (start "" "%OUT%" & goto conv_menu_again)
if "%opt%"=="1" set "MODE=MP4"     & goto convert_flow
if "%opt%"=="2" set "MODE=MP3"     & goto convert_flow
if "%opt%"=="3" set "MODE=MP4MUTE" & goto convert_flow
goto conv_menu_again

:convert_flow
echo.
set "URL="
set /p "URL=Paste the video or playlist URL (M/B to menu): "
if /I "%URL%"=="M"  goto hub
if /I "%URL%"=="B"  goto hub

rem normalize quotes/spaces
set "URL=%URL:"=%"
for /f "tokens=* delims= " %%A in ("%URL%") do set "URL=%%A"

rem if empty, try clipboard (QoL)
if not defined URL for /f "delims=" %%C in ('powershell -NoP -C "Get-Clipboard" 2^>nul') do set "URL=%%C"

rem basic validation: must start with http/https (robust; no regex/pipes)
set "U=%URL%"
set "U=%U: =%"
if /I not "%U:~0,7%"=="http://" if /I not "%U:~0,8%"=="https://" (
  echo ^> That doesn't look like a link. Please paste a full http/https URL.
  pause
  goto conv_menu_again
)

if not exist "%COOKFILE%" call :cookie_helper || (
  echo.& echo Cancelled.
  choice /C MR /N /M "Press M for Menu, R to Converter: "
  if errorlevel 2 goto conv_menu_again
  goto hub
)

rem ask playlist mode
echo.
set "PLCHOICE="
set /p "PLCHOICE=Download FULL playlist if URL is a playlist? (Y/N, default N; M/B to menu): "
if /I "%PLCHOICE%"=="M" goto hub
if /I "%PLCHOICE%"=="B" goto hub

set "PLFLAGS=--no-playlist"
set "OUTTEMPLATE=%OUT%\%%(title).200s.%%(ext)s"
if /I "%PLCHOICE%"=="Y" (
  set "PLFLAGS=--yes-playlist"
  set "OUTTEMPLATE=%OUT%\%%(playlist_title|NA)s\%%(playlist_index)03d - %%(title).200s.%%(ext)s"
)

del /q "%LOG%" >nul 2>nul
echo.
echo Downloading with cookies.txt...
echo.

if /I "%MODE%"=="MP4" (
  "%YTDLP%" %COMMON% %PLFLAGS% %FMT_MP4% --merge-output-format mp4 ^
    --postprocessor-args "ffmpeg:-c:a aac -b:a 192k -movflags +faststart" ^
    --ffmpeg-location "%FFMPEG%" -o "%OUTTEMPLATE%" --cookies "%COOKFILE%" "%URL%" > "%LOG%" 2>&1
) else if /I "%MODE%"=="MP4MUTE" (
  "%YTDLP%" %COMMON% %PLFLAGS% %FMT_MUTE% --merge-output-format mp4 ^
    --postprocessor-args "ffmpeg:-movflags +faststart -an" ^
    --ffmpeg-location "%FFMPEG%" -o "%OUTTEMPLATE%" --cookies "%COOKFILE%" "%URL%" > "%LOG%" 2>&1
) else (
  "%YTDLP%" %COMMON% %PLFLAGS% %FMT_MP3% -x --audio-format mp3 --audio-quality 0 ^
    --ffmpeg-location "%FFMPEG%" -o "%OUTTEMPLATE%" --cookies "%COOKFILE%" "%URL%" > "%LOG%" 2>&1
)

if errorlevel 1 (
  echo.
  echo ===== yt-dlp error (last 60 lines) =====
  if exist "%LOG%" powershell -NoLogo -NoProfile -Command "Get-Content -Path '%LOG%' -Tail 60"
  echo ---------------------------------------
  echo Full log: "%LOG%"
  echo.
  choice /C MR /N /M "Press M for Menu, R to Converter: "
  if errorlevel 2 goto conv_menu_again
  goto hub
)

echo.
echo Done. Files are in: "%OUT%"
choice /C MH /N /M "Press M for Menu, H for Converter: "
if errorlevel 2 goto conv_menu_again
goto hub

:update_ytdlp
echo.
echo Updating yt-dlp...
call :dl "%YTDLP_URL1%" "%YTDLP%"
if not exist "%YTDLP%" call :dl "%YTDLP_URL2%" "%YTDLP%"
if exist "%YTDLP%" (echo ^> yt-dlp ready: "%YTDLP%") else (echo ^> Could not fetch yt-dlp automatically.)
pause
goto conv_menu_again

rem -----------------------------------------------------------
rem  MEDIA COMPRESSOR (manual duration -> target size)
rem -----------------------------------------------------------
:media_comp_manual
call :ensure_ffmpeg
:mc_start
cls
echo ======== Media Compressor (manual duration) ========
echo Output folder: "%COMP%"
echo Drag-and-drop a video (mp4/mov/mkv) or type a path.
echo.
set "SRC="
set /p "SRC=Path to video (M/B to menu): "
if /I "%SRC%"=="M"  goto hub
if /I "%SRC%"=="B"  goto hub
if not defined SRC goto hub
set "SRC=%SRC:"=%"
if not exist "%SRC%" (
  echo ^> Path not found.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)
for %%I in ("%SRC%") do set "BASENAME=%%~nI"

echo.
set "TARGETIN="
set /p "TARGETIN=Target final size in MB (example: 12) (M/B to menu): "
if /I "%TARGETIN%"=="M" goto hub
if /I "%TARGETIN%"=="B" goto hub
if not defined TARGETIN goto mc_start
set "TARGETMB=%TARGETIN: =%"
for /f "tokens=1 delims=.,MBmb" %%d in ("%TARGETMB%") do set "TARGETMB=%%d"
echo.%TARGETMB%| findstr /R "^[0-9][0-9]*$" >nul || (
  echo ^> Not a valid number.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)

echo.
echo Enter the video's duration (seconds OR mm:ss OR hh:mm:ss).
set "DURRAW="
set /p "DURRAW=Duration (M/B to menu): "
if /I "%DURRAW%"=="M" goto hub
if /I "%DURRAW%"=="B" goto hub
if not defined DURRAW goto mc_start

rem parse duration
set "DURSEC="
set "_t1=" & set "_t2=" & set "_t3="
for /f "tokens=1-3 delims=:" %%a in ("%DURRAW%") do (
  set "_t1=%%a"
  set "_t2=%%b"
  set "_t3=%%c"
)
if defined _t3 (
  set /a DURSEC=1*!_t1!*3600 + 1*!_t2!*60 + 1*!_t3!
) else if defined _t2 (
  set /a DURSEC=1*!_t1!*60 + 1*!_t2!
) else (
  set /a DURSEC=1*!_t1!
)

echo.%DURSEC%| findstr /R "^[0-9][0-9]*$" >nul || (
  echo ^> Invalid duration.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)
if %DURSEC% LEQ 0 (
  echo ^> Duration must be ^> 0.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)

rem compute bitrates to hit target size
set "AUDKBPS=128"
set "OVHKBPS=32"
set /a TOTKBITS=%TARGETMB%*8192
set /a VBIT=%TOTKBITS%/%DURSEC% - %AUDKBPS% - %OVHKBPS%
if %VBIT% LSS 100 set "VBIT=100"

echo.
echo Duration: %DURSEC% s
echo Target: %TARGETMB% MB
echo Using video bitrate: %VBIT% kb/s  and audio: %AUDKBPS% kb/s
echo 2-pass H.264 (libx264) in progress...
echo.

set "DEST=%COMP%\%BASENAME%_%TARGETMB%MB.mp4"
set "PASSLOG=%TMP%\pass_%RANDOM%"

"%FFMPEG%" -y -hide_banner -loglevel error -i "%SRC%" -c:v libx264 -b:v %VBIT%k -preset slow -pass 1 -passlogfile "%PASSLOG%" -an -f mp4 NUL
if errorlevel 1 (
  echo ^> Pass 1 failed.
  del /q "%PASSLOG%*" >nul 2>nul
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)

"%FFMPEG%" -y -hide_banner -loglevel error -i "%SRC%" -c:v libx264 -b:v %VBIT%k -preset slow -pass 2 -passlogfile "%PASSLOG%" -c:a aac -b:a %AUDKBPS%k -movflags +faststart "%DEST%"
set "RC=%ERRORLEVEL%"
del /q "%PASSLOG%*" >nul 2>nul

if %RC% NEQ 0 (
  echo ^> Pass 2 failed.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto mc_start
  goto hub
)

for %%A in ("%DEST%") do set "OUTBYTES=%%~zA"
set /a OUTMB=(OUTBYTES + 1048575) / 1048576
echo.
echo Done: "%DEST%"
echo Output size: %OUTMB% MB  (target %TARGETMB% MB)
echo.
choice /C OM /N /M "Open output folder (O) or Menu (M)? "
if errorlevel 2 goto hub
start "" "%COMP%"
goto hub

rem -----------------------------------------------------------
rem  FILE EXTENSION CONVERTER (audio/video)
rem -----------------------------------------------------------
:ext_converter
call :ensure_ffmpeg
:ext_start
cls
echo ======== File Extension Converter ========
echo Input ^> any audio/video file. Output folder: "%CONV%"
echo Drag-and-drop or type a path.
echo.
set "SRC="
set /p "SRC=Path to file (M/B to menu): "
if /I "%SRC%"=="M" goto hub
if /I "%SRC%"=="B" goto hub
if not defined SRC goto hub
set "SRC=%SRC:"=%"
if not exist "%SRC%" (
  echo ^> Path not found.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto ext_start
  goto hub
)
for %%I in ("%SRC%") do (set "BASENAME=%%~nI" & set "SRCEXT=%%~xI")

echo.
echo Choose output format:
echo   1^) MP4  (H.264 + AAC)   [video]
echo   2^) WEBM (VP9  + Opus)   [video]
echo   3^) MP3  (libmp3lame)    [audio]
echo   4^) WAV  (PCM s16le)     [audio]
echo   5^) M4A  (AAC)           [audio]
echo   6^) Back to Hub
echo.
set "fmt="
set /p "fmt=Choose 1-6 (M/B to menu): "
if /I "%fmt%"=="M" goto hub
if /I "%fmt%"=="B" goto hub
if "%fmt%"=="6" goto hub

set "OUTEXT=" & set "ARGS="
if "%fmt%"=="1" ( set "OUTEXT=.mp4"  & set "ARGS=-c:v libx264 -preset medium -crf 23 -c:a aac -b:a 192k -movflags +faststart" )
if "%fmt%"=="2" ( set "OUTEXT=.webm" & set "ARGS=-c:v libvpx-vp9 -crf 34 -b:v 0 -c:a libopus -b:a 128k" )
if "%fmt%"=="3" ( set "OUTEXT=.mp3"  & set "ARGS=-vn -c:a libmp3lame -q:a 2" )
if "%fmt%"=="4" ( set "OUTEXT=.wav"  & set "ARGS=-vn -c:a pcm_s16le" )
if "%fmt%"=="5" ( set "OUTEXT=.m4a"  & set "ARGS=-vn -c:a aac -b:a 192k" )
if not defined OUTEXT (
  echo ^> Invalid selection.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto ext_start
  goto hub
)

set "DEST=%CONV%\%BASENAME%%OUTEXT%"
echo.
echo Converting to "%DEST%" ...
"%FFMPEG%" -y -hide_banner -loglevel error -i "%SRC%" %ARGS% "%DEST%"
if errorlevel 1 (
  echo ^> Conversion failed.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto ext_start
  goto hub
)

for %%A in ("%DEST%") do set "OUTBYTES=%%~zA"
set /a OUTMB=(OUTBYTES + 1048575) / 1048576
echo.
echo Done: "%DEST%"
echo Output size: %OUTMB% MB
echo.
choice /C OM /N /M "Open output folder (O) or Menu (M)? "
if errorlevel 2 goto hub
start "" "%CONV%"
goto hub

rem -----------------------------------------------------------
rem  IMAGE CONVERTER (single file or folder)
rem -----------------------------------------------------------
:image_converter
call :ensure_ffmpeg
:img_start
cls
echo ======== Image Converter ========
echo Input: image file OR a folder with images.
echo Output folder: "%IMGCONV%"
echo Supported: jpg/jpeg/png/webp/bmp/tiff/gif
echo.
set "SRC="
set /p "SRC=Path to file or folder (M/B to menu): "
if /I "%SRC%"=="M" goto hub
if /I "%SRC%"=="B" goto hub
if not defined SRC goto hub
set "SRC=%SRC:"=%"
set "ISDIR="
if exist "%SRC%\" set "ISDIR=1"
if not exist "%SRC%" if not defined ISDIR (
  echo ^> Path not found.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto img_start
  goto hub
)

echo.
echo Choose target format:
echo   1^) JPG   (lossy)
echo   2^) PNG   (lossless)
echo   3^) WEBP  (lossy)
echo   4^) Back to Hub
echo.
set "fmt="
set /p "fmt=Choose 1-4 (M/B to menu): "
if /I "%fmt%"=="M" goto hub
if /I "%fmt%"=="B" goto hub
if "%fmt%"=="4" goto hub
if "%fmt%"=="1" (set "OFMT=jpg"  & set "DEFQ=85")
if "%fmt%"=="2" (set "OFMT=png"  & set "DEFQ=")
if "%fmt%"=="3" (set "OFMT=webp" & set "DEFQ=80")
if not defined OFMT (
  echo ^> Invalid selection.
  choice /C MR /N /M "Press M for Menu, R to retry: "
  if errorlevel 2 goto img_start
  goto hub
)

echo.
set "MAXW="
set /p "MAXW=Optional max width (px; Enter to keep original): "
if /I "%MAXW%"=="M" goto hub
if /I "%MAXW%"=="B" goto hub

set "QUAL="
set /p "QUAL=Optional quality 1-100 (Enter for default %DEFQ%): "
if /I "%QUAL%"=="M" goto hub
if /I "%QUAL%"=="B" goto hub

if defined ISDIR (
  for %%F in ("%SRC%\*.jpg" "%SRC%\*.jpeg" "%SRC%\*.png" "%SRC%\*.webp" "%SRC%\*.bmp" "%SRC%\*.tif" "%SRC%\*.tiff" "%SRC%\*.gif") do call :_img_one "%%~fF" "%OFMT%" "%MAXW%" "%QUAL%"
) else (
  call :_img_one "%SRC%" "%OFMT%" "%MAXW%" "%QUAL%"
)
echo.
echo Done converting images.
choice /C OM /N /M "Open output folder (O) or Menu (M)? "
if errorlevel 2 goto hub
start "" "%IMGCONV%"
goto hub

:_img_one
setlocal EnableDelayedExpansion
set "INIMG=%~1"
set "OFMT=%~2"
set "MAXW=%~3"
set "QUAL=%~4"
for %%I in ("%INIMG%") do set "BN=%%~nI"
set "DEST=%IMGCONV%\%BN%.%OFMT%"

rem scale arg (no parentheses in filter to avoid CMD parse issues)
set "SCALE="
if defined MAXW (
  set "MAXW=!MAXW: =!"
  set "NON="
  for /f "delims=0123456789" %%Z in ("!MAXW!") do set "NON=%%Z"
  if not defined NON if defined MAXW set "SCALE=-vf scale=!MAXW!:-2"
)

rem quality args per format
set "QARG="
if /I "!OFMT!"=="jpg" (
  if not defined QUAL set "QUAL=85"
  set "QUAL=!QUAL: =!"
  set "NON="
  for /f "delims=0123456789" %%Z in ("!QUAL!") do set "NON=%%Z"
  if defined NON set "QUAL=85"
  if not defined QUAL set "QUAL=85"
  set /a QS=31-!QUAL!*28/100
  if !QS! LSS 2  set "QS=2"
  if !QS! GTR 31 set "QS=31"
  set "QARG=-q:v !QS!"
) else if /I "!OFMT!"=="webp" (
  if not defined QUAL set "QUAL=80"
  set "QUAL=!QUAL: =!"
  set "NON="
  for /f "delims=0123456789" %%Z in ("!QUAL!") do set "NON=%%Z"
  if defined NON set "QUAL=80"
  if not defined QUAL set "QUAL=80"
  set "QARG=-qscale:v !QUAL!"
)
echo Converting: "!INIMG!" -> "!DEST!"
"%FFMPEG%" -y -hide_banner -loglevel error -i "!INIMG!" !SCALE! !QARG! "!DEST!" 1>nul 2>&1
endlocal & exit /b

rem -----------------------------------------------------------
rem  COOKIE helper (for converter)
rem -----------------------------------------------------------
:cookie_helper
cls
echo === Create cookies.txt (one-time) ===
echo 1) Edge will open Extensions and a search for "cookies.txt".
echo 2) Install any "cookies.txt" exporter extension.
echo 3) Log into YouTube in Edge if needed.
echo 4) Export cookies for youtube.com to:
echo    "%COOKFILE%"
echo 5) This window waits until the file appears.
echo.
start "" "%TOOLS%"
start "" msedge.exe "edge://extensions"
start "" msedge.exe "https://chromewebstore.google.com/search/cookies.txt"
:wait_cookie
if exist "%COOKFILE%" exit /b 0
choice /C RC /N /M "Press R to re-check for cookies.txt, or C to cancel to previous: "
if errorlevel 2 exit /b 1
goto :wait_cookie

rem -----------------------------------------------------------
rem  Dependencies
rem -----------------------------------------------------------
:ensure_yt_dlp
if exist "%YTDLP%" for %%A in ("%YTDLP%") do if %%~zA gtr 200000 goto :eoy
echo Getting yt-dlp.exe ...
call :dl "%YTDLP_URL1%" "%YTDLP%"
if not exist "%YTDLP%" call :dl "%YTDLP_URL2%" "%YTDLP%"
:eoy
if not exist "%YTDLP%" (
  echo ^> Could not fetch yt-dlp automatically.
  echo   Place yt-dlp.exe into "%TOOLS%" and run again.
  pause
)
exit /b

:ensure_ffmpeg
if exist "%FFMPEG%" for %%A in ("%FFMPEG%" ) do if %%~zA gtr 3000000 goto :ffok
for /f "delims=" %%I in ('where ffmpeg.exe 2^>nul') do copy /y "%%~fI" "%FFMPEG%" >nul 2>nul
for /f "delims=" %%I in ('where ffprobe.exe 2^>nul') do copy /y "%%~fI" "%FFPROBE%" >nul 2>nul
if exist "%FFMPEG%" goto :ffok
echo Getting FFmpeg (Windows zip) ...
set "FFZIP=%TMP%\ffmpeg.zip"
del /q "%FFZIP%" >nul 2>nul
call :dl "%FF_URL1%" "%FFZIP%"
if not exist "%FFZIP%" call :dl "%FF_URL2%" "%FFZIP%"
if not exist "%FFZIP%" call :dl "%FF_URL3%" "%FFZIP%"
if not exist "%FFZIP%" (
  echo ^> Could not fetch FFmpeg automatically.
  echo   Place ffmpeg.exe (+ ffprobe.exe) into "%TOOLS%" and run again.
  pause
  goto :ffok
)
set "FFDIR=%TMP%\ffmpeg_zip"
rd /s /q "%FFDIR%" >nul 2>nul & mkdir "%FFDIR%" >nul 2>nul
tar -xf "%FFZIP%" -C "%FFDIR%" 2>nul || powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%FFZIP%' -DestinationPath '%FFDIR%' -Force" 1>nul 2>nul
for /f "delims=" %%I in ('powershell -NoP -C "(Get-ChildItem -Recurse -Filter ffmpeg.exe -Path '%FFDIR%' | Select-Object -First 1).FullName"') do copy /y "%%~fI" "%FFMPEG%" >nul 2>nul
for /f "delims=" %%I in ('powershell -NoP -C "(Get-ChildItem -Recurse -Filter ffprobe.exe -Path '%FFDIR%' | Select-Object -First 1).FullName"') do copy /y "%%~fI" "%FFPROBE%" >nul 2>nul
del /q "%FFZIP%" >nul 2>nul & rd /s /q "%FFDIR%" >nul 2>nul
:ffok
exit /b

rem -----------------------------------------------------------
rem  Downloader fallback chain (curl -> PowerShell -> certutil)
rem -----------------------------------------------------------
:dl
set "URL=%~1"
set "OUTFILE=%~2"
where curl.exe >nul 2>nul && (curl -L --retry 5 --retry-delay 2 -o "%OUTFILE%" "%URL%" 1>nul 2>nul)
if not exist "%OUTFILE%" powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest '%URL%' -UseBasicParsing -OutFile '%OUTFILE%'}catch{exit 1}" 1>nul 2>nul
if not exist "%OUTFILE%" certutil -urlcache -split -f "%URL%" "%OUTFILE%" >nul 2>nul
exit /b

:end
echo.
echo Bye!
pause >nul
exit /b
