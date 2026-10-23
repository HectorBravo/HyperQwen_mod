@echo off
setlocal

REM ==============================
REM Parameters: gpu (0/1/2)
REM ==============================
set GPU=%~1

if "%GPU%" == "" (
    echo Error: GPU number required
    goto :end
)

REM ==============================
REM Configuration (edit these)
REM ==============================
set REPO_PATH=/mnt/d/repos/HyperQwen_mod
rem set HOST=0.0.0.0
rem set PREFIX_CACHE=1
set VLLM_WSL2_ENABLE_PIN_MEMORY=1
set CUDA_HOME=/home/hbravo/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13
set INT8_ACT=int8
set PREFILL_ATTN=int8
rem set SPEC=mtp
set SPEC=dflash2
rem set DFLASH_TOKENS=15

echo ============================================
echo  Qwen3.8-27B vLLM Server
echo  GPU: %GPU%
echo  KV: %KV_TYPE%, GPU_UTIL=0.93
echo ============================================
echo.
echo Starting server... (takes ~90s)
echo.

wsl -d Ubuntu-26.04 -- bash -c "cd %REPO_PATH% && CUDA_VISIBLE_DEVICES=%GPU% VLLM_WSL2_ENABLE_PIN_MEMORY=%VLLM_WSL2_ENABLE_PIN_MEMORY% HOST=%HOST% CUDA_HOME=%CUDA_HOME% INT8_ACT=%INT8_ACT% PREFILL_ATTN=%PREFILL_ATTN% SPEC=%SPEC% PREFIX_CACHE=%PREFIX_CACHE% DFLASH_TOKENS=%DFLASH_TOKENS% bash bench/run_benchmarks.sh single"

echo.
echo Server stopped.
:end
pause