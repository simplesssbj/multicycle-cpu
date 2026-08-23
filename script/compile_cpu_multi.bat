
@echo off
cd /d "%~dp0\.."
 
iverilog -g2012 -Wall -I "src" -s tb -o cpu_multi.vvp sim\tb.v src\CPU_Multi.v src\CPU_Path.v src\ALU2.v src\Decoder.v src\ROM.v src\SREG.v
 
if errorlevel 1 (
    echo Compilation failed.
    pause
    exit /b 1
)
 
echo Compilation successful: cpu_multi.vvp
 