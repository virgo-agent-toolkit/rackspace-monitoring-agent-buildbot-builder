echo off

set LUVI_VERSION=release
set LIT_VERSION=2.2.15
set RMA_VERSION=master

set LIT_URL="https://lit.luvit.io/packages/luvit/lit/v%LIT_VERSION%.zip"
set RMA_URL="https://github.com/virgo-agent-toolkit/rackspace-monitoring-agent"
set LUA_SIGAR_URL="https://github.com/virgo-agent-toolkit/lua-sigar.git "

set BUILD_DIR=%CD%\build
set SRC_DIR=%CD%\src

set LIT=%BUILD_DIR%\lit
set LUVI=%BUILD_DIR%\luvi

goto ParamLoop

:build
setlocal
mkdir %BUILD_DIR%
mkdir %SRC_DIR%
set PATH=%BUILD_DIR%:%PATH%

set RMA_DIR="%SRC_DIR%/rackspace-monitoring-agent"
if not exist %RMA_DIR% git clone --depth=1 --branch %RMA_VERSION% %RMA_URL% %RMA_DIR%
pushd %RMA_DIR%
call make.bat
call make.bat package
if not "%SKIP_UPLOAD%" == "true" (
  call make.bat packageupload
) else (
  echo "skipping upload"
)
popd
endlocal
goto :eof

:show_usage
setlocal
echo "Usage: build.bat [--force-version VERSION] [--skip-upload] [--help]"
endlocal
goto :eof


:ParamLoop
IF "%1"=="" GOTO ParamContinue
IF "%1"=="--help" (
  CALL :show_usage
  exit /b 1
)
IF "%1"=="--skip-upload" set SKIP_UPLOAD="true"
IF "%1"=="--force-version" (
  set FORCE_VERSION=%2
  ECHO "Forcing version: %2"
  SHIFT
)
SHIFT
GOTO ParamLoop
:ParamContinue


GOTO build
