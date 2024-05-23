CREATE TABLE table_1 (
    col1 text,
    col2 text,
    col3 text
);

CREATE TABLE table_2 (
    col1 text,
    col2 text,
    col3 text
);
CREATE TABLE table_3 (
    col1 text,
    col2 text,
    col3 text
);

/*
1) Создать хранимую процедуру, которая,
не уничтожая базу данных, уничтожает все
те таблицы текущей базы данных, имена которых начинаются с фразы 'TableName'.
*/

CREATE OR REPLACE PROCEDURE DropTablesByPrefix(prefix VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    tableName RECORD;
BEGIN
    FOR tableName IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = current_schema() AND table_name LIKE prefix || '%'
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || tableName.table_name;
    END LOOP;
END;
$$;


/* Тест 1
SELECT table_name
FROM information_schema.tables 
WHERE table_schema = current_schema() AND table_name LIKE 'table%';
*/

/* Test 2
CALL DropTablesByPrefix('table_');
*/

-- DROP PROCEDURE IF EXISTS DropTablesByPrefix CASCADE;

/*
2) Создать хранимую процедуру с выходным параметром,
которая выводит список имен и параметров всех скалярных
SQL функций пользователя в текущей базе данных.
Имена функций без параметров не выводить.
Имена и список параметров должны выводиться в одну строку.
Выходной параметр возвращает количество найденных функций.
*/

CREATE OR REPLACE PROCEDURE GetScalarFunctions(out_function_count INT)
LANGUAGE plpgsql
AS $$
DECLARE
    func_info RECORD;
    func_name TEXT;
    func_params TEXT;
BEGIN
    out_function_count := 0;
    FOR func_info IN
        SELECT proname AS function_name,
               pg_catalog.pg_get_function_result(func.oid) AS return_type,
               pg_catalog.pg_get_function_arguments(func.oid) AS parameters
        FROM pg_catalog.pg_proc func
        JOIN pg_catalog.pg_namespace nsp ON nsp.oid = func.pronamespace
        WHERE nsp.nspname = current_schema() AND pg_catalog.pg_function_is_visible(func.oid)
    LOOP
        IF func_info.parameters <> '' THEN
            func_name := func_info.function_name;
            func_params := REPLACE(func_info.parameters, ' ', ', ');
            RAISE NOTICE 'Function: %, Parameters: %', func_name, func_params;
            out_function_count := out_function_count + 1;
        END IF;
    END LOOP;
END;
$$;

/*
-- Создаем переменную для хранения количества найденных функций
DO $$
DECLARE
    out_function_count INT;
BEGIN
    -- Вызываем процедуру и получаем количество функций
    CALL GetScalarFunctions(out_function_count);
    
    -- Печать количества найденных функций
    RAISE NOTICE 'Number of scalar functions: %', out_function_count;
END;
$$ LANGUAGE plpgsql;
*/

-- DROP PROCEDURE IF EXISTS GetScalarFunctions CASCADE;

/*
3) Создать хранимую процедуру с выходным параметром, которая уничтожает все SQL DML триггеры в текущей базе данных.
Выходной параметр возвращает количество уничтоженных триггеров.
*/

CREATE OR REPLACE PROCEDURE DropAllDMLTriggers(out_trigger_count INT)
LANGUAGE plpgsql
AS $$
DECLARE
    trigger_record RECORD;
BEGIN
    out_trigger_count := 0;
    FOR trigger_record IN
        SELECT trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = current_schema()
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.trigger_name;
        out_trigger_count := out_trigger_count + 1;
    END LOOP;
END;
$$;

/*
-- Создаем переменную для хранения количества уничтоженных триггеров
DO $$
DECLARE
    out_trigger_count INT;
BEGIN
    -- Вызываем процедуру и получаем количество уничтоженных триггеров
    CALL DropAllDMLTriggers(out_trigger_count);
    
    -- Печать количества уничтоженных триггеров
    RAISE NOTICE 'Number of dropped triggers: %', out_trigger_count;
END;
$$ LANGUAGE plpgsql;
*/

-- DROP PROCEDURE IF EXISTS DropAllDMLTriggers CASCADE;

/*
4) Создать хранимую процедуру с входным параметром,
которая выводит имена и описания типа объектов
(только хранимых процедур и скалярных функций),
в тексте которых на языке SQL встречается строка,
задаваемая параметром процедуры.
*/

CREATE OR REPLACE PROCEDURE FindObjectsByText(
    IN search_text TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    obj_name TEXT;
    obj_type TEXT;
    obj_definition TEXT;
BEGIN
    -- Поиск скалярных функций
    FOR obj_name, obj_definition IN
        SELECT proname, pg_get_functiondef(p.oid)
        FROM pg_proc p
        WHERE p.prosrc ILIKE '%' || search_text || '%'
    LOOP
        RAISE NOTICE 'Scalar Function Name: %, Definition: %', obj_name, obj_definition;
    END LOOP;

    -- Поиск хранимых процедур
    FOR obj_name, obj_definition IN
        SELECT routine_name, routine_definition
        FROM information_schema.routines
        WHERE routine_definition ILIKE '%' || search_text || '%' AND routine_type = 'PROCEDURE'
    LOOP
        RAISE NOTICE 'Procedure Name: %, Definition: %', obj_name, obj_definition;
    END LOOP;
END;
$$;

/*
-- Вызываем процедуру и передаем строку для поиска
CALL FindObjectsByText('routine_type');
*/

-- DROP PROCEDURE IF EXISTS FindObjectsByText CASCADE;