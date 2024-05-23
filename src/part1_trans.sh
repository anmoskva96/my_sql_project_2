#!/bin/bash

# egleumel;2011-05-23
# hramitaf;01/05/2005
# isasilef;06/05/1995

# Цвета текста:
DEF="\033[0;39m"     #  ${DEF}
LRED="\033[31m"      #  ${LRED}
LGREEN='\033[32m'    #  ${LGREEN}
LYELLOW="\033[33m"   #  ${LYELLOW}
LBLUE='\033[34m'     #  ${LBLUE}

help_h(){
    echo "Помощь: '--help' или '-h'"
    exit $1
}
# пароль автоматизация ввода смотри строку 107 +-

DB_NAME=$1 # база данных
PROCEDURE=$2 # import OR export
delimiter=$3 # символ
table=$4 # имя таблицы
path_csv=$5  # получаем путь к файлу

# Проверяем кол-во и качество входных параметров
if [ "$#" -eq 1 ] && [[ "$1" =~ ^(--help|-h)$ ]]; then
    echo "# - тип_образец  - описание"
    echo "1 - string - имя DataBase"
    echo "2 - string - функция IMPORT или EXPORT"
    echo "3 - char - символ для разделения данных"
    echo "4 - string - имя таблицы"
    echo "5 - string - путь к файлу (если не будет указан, то будет вызван диалог)"
    exit 0
elif [ $# -le 3 ]; then # проверка на кол-во параметров
    echo "Ожидается от четырёх параметров, а введено:" $#
    help_h 2 # 2 - код ошибки о не хватке параметров
elif [ "$PROCEDURE" != "IMPORT" ] && [ "$PROCEDURE" != "EXPORT" ]; then # проверка режима
    echo "Ожидается второй аргумент должен быть или IMPORT или EXPORT, а сейчас:" $PROCEDURE
    help_h 1 # 1 - код ошибки о не корректности параметров
else
    # ниже получаем полный путь к файлу
    path_csv=$(readlink -m $path_csv) 2> /dev/null # вывод потока ошибки 2> в никуда /dev/null
    if [[ ! -e $path_csv ]]; then
        echo "Третий параметр: не файла :"$path_csv
        echo "Сейчас будет предложено указать файл через диалог."
        if ! [ -x "$(command -v dialog)" ]; then # проверяем наличия в системе  dialog
            echo -e "${LYELLOW}"
            read -p "Dialog не установлен. Установить? [y/n]: " choice </dev/tty
            echo -e "${DEF}"
                # /dev/tty - Явно указываем, что нужно читать с клавиатуры
            if [[  "${choice,,}" == "y" || "${choice,,}" == "yes" ]]; then
                echo "Установка Dialog..."
                sudo apt-get install dialog -y &>output_install_Dialog # &>/dev/null
                if ! [ -x "$(command -v dialog)" ]; then
                    echo -e $LRED "Ошибка при установке Dialog. Подробности установки в файле 'output_install_Dialog'"$DEF
                    exit 1
                else
                    echo -e $LGREEN "Dialog установлен!"$DEF
                    $(rm -rf output_install_Dialog 2>/dev/null)
                fi
            else
                echo -e $LRED "Без установленного Dialog работа скрипта не возможно." $DEF
                exit 1
            fi
        fi
        # Открытие диалогового окна выбора файла с помощью dialog
        path_csv=$(dialog --stdout --title "Выберите файл для импорта для таблицы "$table --fselect "$(pwd)" 14 48)
        # п.1. в поле пути пишем название папки (пробел для записания вместо таба)
        # п.2. потом указываем "/" и диалог покаже содержимое папки и смотрим п.1.
        # п.3. для заврения выбора нажать Enter
        # Проверка, был ли выбран файл или нажата кнопка "Отмена"
        clear
        if [ $? -eq 0 ]; then
            echo "Выбранный файл: $path_csv"
        else
            echo "Выбор файла отменён."
            help_h 2
        fi
    fi

    file_type=$(file -b "$path_csv")
    echo "file_type="$file_type
    if [[ ! $file_type == *"text"* ]]; then
        echo "Выбранный файл не является текстовым"
        help_h 1 # 1 - код ошибки о не корректности параметров
        exit 1
    else
        # echo "Файл является текстовым"
        
        echo "Выбранный файл: $path_csv"
        # дадим право читать

        chmod -R og+rwX $path_csv
        #chown -R postgres:postgres $path_csv

        # Параметры подключения к базе данных
        DB_HOST="localhost"
        DB_PORT="5432"
        # DB_NAME="SQL2_Info21_v1"
        DB_USER="postgres"
        # DB_PASSWORD="123" # будет задан при подключении

        # SQL-запрос для выполнения
        SQL_QUERY="CALL $PROCEDURE('$table', '$path_csv', '$delimiter');"

        # Проверяем существование файла
        tmp_file="temp_psql_out"
        if [ -f $tmp_file ]; then
            rm -rf $tmp_file
        fi
        touch $tmp_file
        # Подключение к базе данных и выполнение SQL-запроса
        # export PGPASSWORD="123" # автоматизация ввода пароля
        psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "$SQL_QUERY" > $tmp_file 2>&1
        if [ "$(cat $tmp_file)" == "CALL" ]; then
            echo -e $LGREEN"$(cat $tmp_file)"$DEF
          else
            echo -e $LRED"$(cat $tmp_file)"$DEF
        fi
        if [ -f $tmp_file ]; then
            rm -rf $tmp_file
        fi
    fi
fi
