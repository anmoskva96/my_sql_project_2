#!/bin/bash

# Параметры подключения к базе данных
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME=$1
DB_USER="postgres"
# DB_PASSWORD="123"
LIMIT_LINES=10
# export PGPASSWORD="123" # автоматизация ввода пароля


# Получение списка таблиц из информационной схемы
tables=$(psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_type = 'BASE TABLE'
    AND table_name NOT LIKE 'sql\_%'
    AND table_name NOT LIKE 'pg\_%'
" | sed '1,2d') 

# Избавляемся от заголовков и строк счетчика
echo -e $tables
# Цикл для выполнения запроса SELECT для каждой таблицы
while read -r table_name; do
    echo "Таблица: $table_name"
    psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM $table_name LIMIT $LIMIT_LINES"
    echo "-----------------------"
done <<< "$tables"
