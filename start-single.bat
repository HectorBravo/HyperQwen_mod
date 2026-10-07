@echo off
setlocal

REM ==============================
REM Parameters: type (fast/long) and gpu (0/1/2)
REM ==============================
set TYPE=%~1
set GPU=%~2

if "%TYPE%" == "" (
    echo Usage: start-single.bat ^<fast^|long^> ^<0^|1^|2^>
    goto :end
)
if "%GPU%" == "" (
    echo Error: GPU number required
    goto :end
)

REM Calculate port: 18000 + (10 if long) + gpu
set /a PORT=18000
if /i "%TYPE%"=="long" set /a PORT=PORT+10
set /a PORT=PORT+GPU

REM Calculate CTX
if /i "%TYPE%"=="fast" (
    set CTX=fast
    set KV_TYPE=bf16
) else (
    if /i "%TYPE%"=="long" (
        set CTX=long
        set KV_TYPE=fp8
    ) else (
        echo Error: type must be 'fast' or 'long'
        goto :end
    )
)

REM ==============================
REM Configuration (edit these)
REM ==============================
set REPO_PATH=/mnt/d/repos/HyperQwen_mod
set HOST=0.0.0.0
set VLLM_WSL2_ENABLE_PIN_MEMORY=1
set CUDA_HOME=/home/hbravo/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13

rem set PORT=18020

echo ============================================
echo  Qwen3.8-27B vLLM Server
echo  GPU: %GPU%, CTX: %CTX%, Port: %PORT%
echo  KV: %KV_TYPE%, GPU_UTIL=0.93
echo ============================================
echo.
echo Starting server... (takes ~90s)
echo.

wsl -d Ubuntu-26.04 -- bash -c "cd %REPO_PATH% && CUDA_VISIBLE_DEVICES=%GPU% VLLM_WSL2_ENABLE_PIN_MEMORY=%VLLM_WSL2_ENABLE_PIN_MEMORY% CTX=%CTX% HOST=%HOST% PORT=%PORT% CUDA_HOME=%CUDA_HOME% bash single-user/start_qwen.sh"
rem wsl -d Ubuntu-26.04 -- bash -c "cd %REPO_PATH% && CUDA_VISIBLE_DEVICES=%GPU% VLLM_WSL2_ENABLE_PIN_MEMORY=%VLLM_WSL2_ENABLE_PIN_MEMORY% CTX=%CTX% HOST=%HOST% PORT=%PORT% CUDA_HOME=%CUDA_HOME% bash single-user/start_qwen.sh"

echo.
echo Server stopped.
:end
pause