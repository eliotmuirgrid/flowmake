@echo off

@REM OpenSSL needs Perl to compile. Strawberry Perl or ActivePerl works
Where perl.exe
if %errorlevel% neq 0 echo Missing OpenSSL dependency Perl && exit /b %errorlevel%

@REM OpenSSL needs NASM to compile.
@REM We could remove this dependency if we 'perl configure VC-WIN64-nasm', but not recommended by OpenSSL
Where nasm.exe
if %errorlevel% neq 0 echo Missing OpenSSL dependency Netwide Assembler && exit /b %errorlevel%

@REM CMake is needed to build libcurl and dependencies
Where cmake.exe
if %errorlevel% neq 0 echo Missing libcurl dependency CMake && exit /b %errorlevel%

@REM Git is needed to generate DBDVERgitInfo.cpp, see makefile.core
Where git.exe
if %errorlevel% neq 0 echo Missing Iguana DBDVER dependency Git && exit /b %errorlevel%