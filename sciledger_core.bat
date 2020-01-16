@echo off

if not exist "sciledger\" ( mkdir sciledger )
set fillname=%USERNAME%000000
echo %fillname:~0,6%>sciledger\address.tmp
FOR /F "tokens=* skip=1" %%g IN ('certutil -hashfile "sciledger\address.tmp" MD2') do (SET Asum=%%g && goto CAsumbrek)
:CAsumbrek
set address=%fillname:~0,6%%Asum:~0,2%

del /Q sciledger\address.tmp

:action
set /p action=check/redownload/send/node/info 
if "%action%"=="check" (goto scan)
if "%action%"=="redownload" (goto redownload)
if "%action%"=="send" (goto send)
if "%action%"=="info" (echo address: %address%)
if "%action%"=="node" (goto nodestart)
goto action

:redownload
if exist "P:\sciledger\" ( del /Q sciledger\* ) else ( echo ledger unreachable && goto action )

set balance=0
set point=0

if not exist sciledger\ ( mkdir sciledger )

:scan
set point=0
set copycount=0
:copyloop
if exist "P:\sciledger\transaction%point%.txt" ( if not exist sciledger\transaction%point%.txt ( copy "P:\sciledger\transaction%point%.txt" sciledger\ && set /A copycount=%copycount%+1 ) ) else ( echo %copycount% transactions downloaded && goto copydone )
set /A point=%point%+1
goto copyloop
:copydone

set balance=0
set point=0

:scanloop
if not exist sciledger\transaction0.txt ( echo "no transactions downloaded, use FullCheck. it is also possible that no transactions were made if noone ran a node" && goto action )
set /p transaction=<sciledger\transaction%point%.txt
set /A point=%point%+1

if "%transaction:~8,8%"=="%address%" ( set /A balance=%balance%+%transaction:~17% )
if "%transaction:~0,8%"=="%address%" ( set /A balance=%balance%-%transaction:~17% )

if not exist "sciledger\transaction%point%.txt" (goto scandone)
goto scanloop
:scandone
echo balance %balance%
goto action

:send
if not exist P:\sciledger\ ( mkdir P:\sciledger )
set /p who=to who?
set /p much=how much?

echo %who:~0,6%>sciledger\address.tmp
FOR /F "tokens=* skip=1" %%g IN ('certutil -hashfile "sciledger\address.tmp" MD2') do (SET Asum=%%g && goto SAsumbrek)
:SAsumbrek
del /Q sciledger\address.tmp
if not "%who:~6,2%"=="%Asum:~0,2%" ( echo transaction canceled because address was invalid, check for mistakes and try again && goto action )

set who=%who:~0,6%%Asum:~0,2%

set point=0
:Ppoint
set /A point=%point%+1
if exist "P:\sciledger\transaction%point%.txt" (goto Ppoint)
echo %address%%who% %much%
set /A Hpoint=%point%-1
FOR /F "tokens=* skip=1" %%g IN ('certutil -hashfile "P:\sciledger\transaction%Hpoint%.txt" MD2') do (SET Shash=%%g && goto sendbrek)
:sendbrek
echo %address%%who% %much% > "P:\sciledger\transaction%point%.txt"
echo %Shash%>"P:\sciledger\transaction%point%.MD2"
echo %Shash%>>"P:\sciledger\transaction%point%.txt"
goto action

:nodestart
set uploaded=0
set cycles=0
set trustedtime=60
:node
set point=1
set /A cycles=%cycles%+1
set /A trustedtime=%trustedtime%+1
if %trustedtime% LSS 5 ( set trustedtime=5 )
if %trustedtime% GTR 600 ( set trustedtime=600 )
set /A waittime=%trustedtime%+(%RANDOM%*5/32768)
:renode
if not exist "sciledgernode\" ( mkdir sciledgernode )
if %cycles%==3 (set cycles=0 && goto selfnode)
if not exist "P:\sciledger\" ( mkdir P:\sciledger && echo 00000000andrew00 10000>P:\sciledger\transaction0.txt && goto node)
if not exist "P:\sciledger\transaction0.txt" ( echo 00000000andrew00 10000>P:\sciledger\transaction0.txt && goto node)
if exist "P:\sciledger\transaction%point%.txt" ( set /p transaction=<P:\sciledger\transaction%point%.txt ) else ( timeout %waittime% && goto node)

if %transaction:~17% LEQ 0 ( del /Q "P:\sciledger\transaction%point%.*" && goto renode )
set /A Hpoint=%point%-1
set /A Fpoint=%point%+10
set /A Opoint=%point%-10
if exist "P:\sciledger\transaction%Hpoint%.txt" ( FOR /F "tokens=* skip=1" %%g IN ('certutil -hashfile "P:\sciledger\transaction%Hpoint%.txt" MD2') do (SET Rhash=%%g && goto nodebrek) )
:nodebrek
if exist "P:\sciledger\transaction%point%.MD2" ( set /p Thash=<P:\sciledger\transaction%point%.MD2 ) else ( del /Q P:\sciledger\transaction%point%.* )
if not "%Thash:~0,32%"=="%Rhash:~0,32%" ( echo hashes don't match && set /A trustedtime=%trustedtime%-10 && if not exist "sciledgernode\transaction%Hpoint%.txt" ( del /Q P:\sciledger\transaction%point%.* && del /Q P:\sciledger\transaction%Hpoint%.* ) else ( if exist sciledgernode\transaction%Hpoint%.txt ( type sciledgernode\transaction%Hpoint%.txt>P:\sciledger\transaction%Hpoint%.txt && type sciledgernode\transaction%point%.MD2>P:\sciledger\transaction%point%.MD2 ) ) )
if exist "P:\sciledger\transaction%Opoint%.txt" ( if not exist sciledgernode\transaction%Opoint%.txt ( copy "P:\sciledger\transaction%Opoint%.txt" sciledgernode\ ) )
if exist "P:\sciledger\transaction%Opoint%.MD2" ( if not exist sciledgernode\transaction%Opoint%.MD2 ( copy "P:\sciledger\transaction%Opoint%.MD2" sciledgernode\ ) )

set /A point=%point%+1

goto renode

:selfnode
echo checking self
set point=1
:selfnodeloop
if exist "sciledgernode\transaction%point%.txt" ( set /p transaction=<sciledgernode\transaction%point%.txt ) else ( goto node )

if %transaction:~17% LEQ 0 ( del /Q "sciledgernode\transaction%point%.*" && goto selfnodeloop )
set /A Hpoint=%point%-1
if exist "sciledgernode\transaction%Hpoint%.txt" ( FOR /F "tokens=* skip=1" %%g IN ('certutil -hashfile "sciledgernode\transaction%Hpoint%.txt" MD2') do (SET Rhash=%%g && goto selfnodebrek) )
:selfnodebrek
if exist "sciledgernode\transaction%point%.MD2" ( set /p Thash=<sciledgernode\transaction%point%.MD2 ) else ( del /Q sciledgernode\transaction%point%.* )
if not "%Thash:~0,32%"=="%Rhash:~0,32%" ( del /Q sciledgernode\transaction%point%.* && del /Q sciledgernode\transaction%Hpoint%.* ) else ( if not exist "P:\sciledger\transaction%Hpoint%.txt" ( type sciledgernode\transaction%Hpoint%.txt>"P:\sciledger\transaction%Hpoint%.txt" && type sciledgernode\transaction%point%.MD2>"P:\sciledger\transaction%point%.MD2" && echo transaction reuploaded ) )

set /A point=%point%+1

if exist "sciledgernode\transaction%point%.txt" ( goto selfnodeloop ) else ( set /A uploaded=%point%+1 && goto selfnodedone )
:selfnodedone

goto node


:nodereset
del /Q sciledgernode\*
goto action