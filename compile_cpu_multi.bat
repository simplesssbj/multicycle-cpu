@echo off
cd /d "%~dp0"

iverilog -g2012 -Wall -I "." -s tb -o cpu_multi.vvp tb.v CPU_Multi.v CPU_Path.v ALU2.v Decoder.v ROM.v SREG.v

if errorlevel 1 (
    echo Compilation failed.
    pause
    exit /b 1
)

echo Compilation successful: cpu_multi.vvp
cd Week4
cd 2