@echo off

REM Встановлення кодування UTF-8
chcp 65001 > nul

REM Перевірка кількості переданих аргументів
if "%~6"=="" (
    echo Невірна кількість аргументів командного рядка
    exit /b
)

REM Розпакування аргументів командного рядка
set log_file=%1
set file_path=%2
set process_name=%3
set archive_path=%4
set ip_address=%5
set max_log_size=%6



REM (Завдання 2-4) Перевірка наявності файлу з ім'ям, переданим в першому аргументі
if exist "%log_file%" (
    echo %date% %time%: Файл з ім'ям %log_file% відкрито
    echo %date% %time%: Файл з ім'ям %log_file% відкрито>>"%log_file%"
) else (
    REM Створення файлу, якщо він не існує
    type nul > "%log_file%"
    echo %date% %time%: Файл з ім'ям %log_file% створено
    echo %date% %time%: Файл з ім'ям %log_file% створено>>"%log_file%"
)



REM (Завдання 5) Отримання часу з NTP серверу
w32tm /stripchart /computer:pool.ntp.org /dataonly /samples:1 > ntp_time.tmp

REM Отримання часу з результатів виконання команди w32tm
for /F "tokens=3,4" %%a in (ntp_time.tmp) do (
    set hh=%%a
    set mm=%%b
)

REM Додавання оновленого часу до лог-файлу
echo %date% %time%: Оновлено час >> "%log_file%"

REM Видалення тимчасового файлу
del ntp_time.tmp



REM (Завдання 6) Отримання списку усіх запущених процесів
tasklist > tasklist.txt

REM Записування списку усіх запущених процесів у лог-файл
echo %date% %time%: Список усіх запущених процесів: >> "%log_file%"
type tasklist.txt >> "%log_file%"
echo. >> "%log_file%"

REM Видалення тимчасового файлу
del tasklist.txt



REM (Завдання 7) Завершення процесу з ім'ям, переданим у третьому аргументі
taskkill /f /im "%process_name%" > nul

REM Перевірка, чи процес був завершений
if errorlevel 1 (
    echo %date% %time%: Не вдалося завершити процес з ім'ям %process_name% >> "%log_file%"
) else (
    echo %date% %time%: Процес з ім'ям %process_name% був успішно завершений >> "%log_file%"
)



REM (Завдання 8-9) Видалення усіх файлів за шляхом, які мають розширення .TMP або починаються на "temp"
REM Отримання кількості видалених файлів
for %%f in ("%file_path%\*.tmp" "%file_path%\temp*") do set /a count+=1

del /q "%file_path%\*.tmp"
del /q "%file_path%\temp*"

REM Записування інформації про видалені файли у лог-файл
echo %date% %time%: Видалено %count% файлів з розширенням .tmp або початковими символами "temp" зі шляху %file_path% >> "%log_file%"



EM (Завдання 10-13) Стиснення усіх файлів за шляхом, які залишилися, у архів .zip
REM Генерація імені архіву з поточною датою та часом
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"
set "zip_name=%datetime%.zip"

REM Стиснення усіх файлів за шляхом, які залишилися, у архів .zip
powershell Compress-Archive -Path "%file_path%\*" -DestinationPath "%zip_name%" -Force

REM Переписування створеного архіву у папку за шляхом Аргумент4
copy "%zip_name%" "%archive_path%"

REM Переписування створеного архіву у папку за шляхом Аргумент4
copy "%zip_name%" "%archive_path%"

REM Перевірка наявності файлу з архівом за минулий день
set "yesterday=%date:~6,4%%date:~3,2%%date:~0,2%"
if exist "%archive_path%\%yesterday%.zip" (
    echo %date% %time%: Файл з архівом за минулий день існує >> "%log_file%"
) else (
    echo %date% %time%: Файл з архівом за минулий день відсутній >> "%log_file%"
    REM Інформація для відправлення по електронній пошті, якщо потрібно
)

REM Інформування про виконані дії у лог-файлі
echo %date% %time%: Файли були стиснені та переміщені у %archive_path% >> "%log_file%"



REM (Завдання 14) Перевірка наявності архівів, старших за 30 днів, та їх видалення
forfiles /p "%archive_path%" /m *.zip /d -30 /c "cmd /c del @path"

REM Перевірка, чи були видалені архіви
if %errorlevel% equ 0 (
    echo %date% %time%: Були видалені архіви, старші за 30 днів, у шляху %archive_path% >> "%log_file%"
) else (
    echo %date% %time%: Не було знайдено архівів, старших за 30 днів, у шляху %archive_path% >> "%log_file%"
)



REM (Завдання 15) Перевірка підключення до Інтернету
ping -n 1 8.8.8.8 > nul
if %errorlevel% equ 0 (
    echo %date% %time%: Підключено до Інтернету >> "%log_file%"
) else (
    echo %date% %time%: Відсутнє підключення до Інтернету >> "%log_file%"
)



REM (Завдання 16) Перевірка наявності комп'ютера у локальній мережі за його IP-адресою
ping -n 1 %ip_address% > nul
if %errorlevel% equ 0 (
    echo %date% %time%: Комп'ютер з IP-адресою %ip_address% знайдено у локальній мережі >> "%log_file%"
    REM Завершення роботи комп'ютера з IP-адресою %ip_address%
    shutdown /s /m \\%ip_address% /t 0
) else (
    echo %date% %time%: Комп'ютер з IP-адресою %ip_address% не знайдено у локальній мережі >> "%log_file%"
)



REM (Завдання 17) Отримання списку комп'ютерів у мережі та запис цієї інформації у лог-файл
net view > network_computers.txt
echo %date% %time%: Список комп'ютерів у мережі: >> "%log_file%"
type network_computers.txt >> "%log_file%"
echo. >> "%log_file%"
del network_computers.txt



REM (Завдання 18) Читання IP-адрес з файлу ipon.txt
if exist ipon.txt (
    for /f %%i in (ipon.txt) do (
        REM Перевірка доступності IP-адреси
        ping -n 1 %%i > nul
        if errorlevel 1 (
            REM Якщо IP-адреса недоступна, записати інформацію у лог-файл
            echo %date% %time%: Комп'ютер з IP-адресою %%i відсутній у мережі >> "%log_file%"
            REM Надіслати повідомлення на email, якщо потрібно
            REM command_to_send_email_here
        )
    )
) else (
    REM Якщо файл ipon.txt не існує, вивести відповідне повідомлення у лог-файл
    echo %date% %time%: Файл ipon.txt не існує >> "%log_file%"
)



REM (Завдання 19) Отримання розміру поточного лог-файлу
for %%A in ("%log_file%") do set "log_file_size=%%~zA"

REM Перевірка, чи розмір поточного лог-файлу перевищує максимальний розмір
if %log_file_size% gtr %max_log_size% (
    REM Якщо розмір перевищує максимальний, записати інформацію у лог-файл
    echo %date% %time%: Розмір лог-файлу %log_file% перевищує %max_log_size% байт >> "%log_file%"
)



REM (Завдання 20) Отримання інформації про вільне та зайняте місце на усіх дисках
REM Отримання інформації про диски та запис її в журнал
echo Перевірка стану дисків... >> %log_file%
echo ----------------------------------- >> %log_file%
wmic logicaldisk get caption, description, freespace, size | findstr /v /r "^$" | findstr /v /c:"Caption" >> %log_file%



REM (Завдання 21)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "datetime=%%I"
set "datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%"

REM Створення імені файлу з поточною датою та часом
set "file_name=systeminfo_%datetime%.txt"

REM Виконання команди systeminfo та запис результату у файл
systeminfo > "%file_name%"