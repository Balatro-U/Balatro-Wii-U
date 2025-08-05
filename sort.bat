@echo off

rmdir /s /q patch
mkdir patch
:: idk anything about powrshell so that .ps1 scrip was made by chat gpt
powershell -ExecutionPolicy Bypass -File .\sort.ps1