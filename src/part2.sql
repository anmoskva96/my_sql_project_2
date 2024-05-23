/*
1) Написать процедуру добавления P2P проверки
Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P проверки, время.
*/

CREATE PROCEDURE AddP2PCheck(
    checked_peer varchar,
    checking_peer varchar,
	task_name text,
    p2p_status Check_status,
	p2p_time TIME
)
AS $$
BEGIN
    IF (p2p_status = 'Start') THEN -- Если задан статус "начало", в качестве проверки указать только что добавленную запись
        IF ((SELECT COUNT(*) FROM p2p
            JOIN checks
			ON p2p."Check" = checks.id
            WHERE p2p.checkingpeer = checking_peer
            AND checks.peer = checked_peer
            AND checks.task = task_name) = 0) THEN
				INSERT INTO checks -- добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю)
                VALUES ((SELECT MAX(id) FROM checks) + 1, checked_peer, task_name, NOW());
                INSERT INTO p2p -- добавить запись в таблицу P2P
                VALUES ((SELECT MAX(id) FROM p2p) + 1, (SELECT MAX(id) FROM checks), checking_peer, p2p_status, p2p_time);
            ELSE
                RAISE EXCEPTION 'Ошибка: Проверка не завершена';
            END IF;
        ELSE -- иначе указать проверку с незавершенным P2P этапом
            INSERT INTO p2p
            VALUES ((SELECT MAX(id) FROM p2p) + 1,
                    (SELECT "Check" FROM p2p
                    JOIN checks
					ON p2p."Check" = checks.id
                    WHERE p2p.checkingpeer = checking_peer
					AND checks.peer = checked_peer
					AND checks.task = task_name),
                    checking_peer, p2p_status, p2p_time);
        END IF;
    END;
 $$ LANGUAGE PLPGSQL;

-- Удаление процедуры и добавленных строк
/*
DELETE FROM p2p WHERE id > 40;
DELETE FROM checks WHERE id > 20;
DROP PROCEDURE IF EXISTS AddP2PCheck CASCADE;
*/

-- Тест 1, ожидается добавление записей в таблицы checks, p2p
-- Корректный ввод
/*
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
SELECT * FROM checks;
SELECT * FROM p2p;
*/

-- Тест 2, ожидается 'Ошибка: Проверка не завершена'
-- Попытка добавления записи, при имеющейся незавершенной проверкe проекта "C3_SimpleBashUtils" у пары пиров
/*
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
*/

-- Тест 3, ожидается добавление записей в таблицы p2p
-- Добавление записей для случая, когда у проверяющего имеется незакрытая проверка
/*
CALL AddP2PCheck('jesusaha', 'fatimarh', 'SQL2_Info21_v1.0', 'Start'::check_status, '17:15:00');
*/

-- Тест 4, ожидается ERROR
-- Попытка добавления неверной записи
/*
CALL AddP2PCheck('garigusn', 'fatimarh', 'C3_SimpleBashUtils', 'Failure'::check_status, '16:30:00');
*/

/*
2) Написать процедуру добавления проверки Verter'ом
Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
*/

CREATE PROCEDURE AddVerterCheck(
    checked_peer varchar, 
    task_name text,
    verter_status Check_status, 
    verter_time TIME
)
AS $$
BEGIN
    IF (verter_status = 'Start') THEN
        IF ((SELECT MAX(p2p."Time") FROM p2p -- проверка задания с самым поздним (по времени) успешным P2P этапом
            JOIN checks
            ON p2p."Check" = checks.id
            WHERE checks.peer = checked_peer
            AND checks.task = task_name
            AND p2p."State" = 'Success') IS NOT NULL) THEN
                INSERT INTO verter -- добавить запись в таблицу Verter
                VALUES ((SELECT MAX(id) FROM verter) + 1,
                        (SELECT DISTINCT checks.id FROM p2p
                        JOIN checks
                        ON p2p."Check" = checks.id
                        WHERE checks.peer = checked_peer
                        AND p2p."State" = 'Success'
                        AND checks.task = task_name),
                        verter_status, verter_time);
                ELSE
                    RAISE EXCEPTION 'P2P-проверка не завершена или имеет статус Failure';
                END IF;
        ELSE
            INSERT INTO verter
            VALUES ((SELECT MAX(id) FROM verter) + 1,
                    (SELECT "Check" FROM verter
                     GROUP BY "Check" HAVING COUNT(*) % 2 = 1), verter_status, verter_time);
        END IF;
    END;
$$ LANGUAGE PLPGSQL;


-- Удаление процедуры и добавленных строк
/*
DROP PROCEDURE AddVerterCheck CASCADE;
DELETE FROM verter WHERE id > 10;
DELETE FROM p2p WHERE id > 40;
DELETE FROM checks WHERE id > 20;
*/

-- Тест 1, ожидается добавление записей в таблицу verter
-- Корректный ввод
/*
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Success'::check_status, '16:00:00');
CALL AddVerterCheck('lemuelge', 'C3_SimpleBashUtils', 'Start', '16:00:05');
SELECT * FROM verter;
*/

-- Тест 2, ожидается 'P2P-проверка не завершена или имеет статус Failure'
-- Попытка добавления записи при условии, что p2p проверка еще не завершена
/*
CALL AddP2PCheck('lemuelge', 'jesusaha', 'C4_s21_math', 'Start'::check_status, '17:30:00');
CALL AddVerterCheck('lemuelge', 'C4_s21_math', 'Start', '18:00:05');
*/

-- Тест 3, ожидается 'P2P-проверка не завершена или имеет статус Failure'
-- Попытка добавления записи при условии, что нет успешных p2p проверок 
/*
CALL AddP2PCheck('lemuelge', 'jesusaha', 'C4_s21_math', 'Failure'::check_status, '18:00:00');
CALL AddVerterCheck('lemuelge', 'C4_s21_math', 'Start', '18:00:05');
*/

/*3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, 
изменить соответствующую запись в таблице TransferredPoints
*/

CREATE OR REPLACE FUNCTION fnc_trg_update_transferredpoints()
RETURNS TRIGGER
AS $trg_update_transferredpoints$
DECLARE
    t2 varchar = ((SELECT checks.peer
                    FROM p2p
                    JOIN checks
			        ON p2p."Check" = checks.id
			        WHERE checks.id = NEW."Check"
                    )
			    UNION
			        (SELECT checks.peer
                    FROM p2p
                    JOIN checks
                    ON p2p."Check" = checks.id
                    WHERE checks.id = NEW."Check"
                    ));
BEGIN
    IF (NEW."State" = 'Start') THEN -- после добавления записи со статутом "начало"
        IF ((SELECT COUNT(*)
		    FROM transferredpoints
            WHERE checkedpeer = t2
            AND checkingpeer = NEW.checkingpeer) = 0
            AND NEW."State" = 'Start') THEN
                INSERT INTO transferredpoints -- если такой пары пиров не существует, добавить новую запись
                VALUES ((SELECT MAX(id) FROM transferredpoints) + 1, NEW.checkingpeer, t2, '1');
            ELSE
                WITH t1 AS (SELECT checks.peer AS peer
                    FROM p2p
                    JOIN checks
                    ON p2p."Check" = checks.id
                    AND NEW."Check" = checks.id
                    )
                    UPDATE transferredpoints -- изменить существующую запись в таблице TransferredPoints
                    SET pointsamount = pointsamount + 1
                    FROM t1
                    WHERE  transferredpoints.checkedpeer = t1.peer
                    AND  transferredpoints.checkingpeer = NEW.checkingpeer;
            END IF;
        END IF;
    RETURN NULL;
END;
$trg_update_transferredpoints$ LANGUAGE PLPGSQL;

CREATE TRIGGER trg_update_transferredpoints
AFTER INSERT ON P2P
FOR EACH ROW EXECUTE
FUNCTION fnc_trg_update_transferredpoints();
	
	
-- Удаление триггера и добавленных строк
/*
DROP FUNCTION IF EXISTS fnc_trg_update_transferredpoints() CASCADE;
DELETE FROM p2p WHERE id > 40;
DELETE FROM checks WHERE id > 20;
DELETE FROM transferredpoints WHERE id > 16;
*/

-- Тест 1, ожидается изменение существующей записи в таблице transferredpoints
-- Добавление записи со статутом "начало" в таблицу P2P с помощью вызова AddP2PCheck
/*
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
select * from transferredpoints;
*/

-- Тест 2, добавим еще одного пира в таблицу Peers, затем создадим новую пару пиров
-- Добавление записи со статутом "начало" в таблицу P2P с помощью вызова AddP2PCheck
/*
INSERT INTO Peers
VALUES ('deadpool', '2000-01-01');
CALL AddP2PCheck('lemuelge', 'deadpool', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
select * from transferredpoints;
*/


/*
4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
Запись считается корректной, если:

Количество XP не превышает максимальное доступное для проверяемой задачи
Поле Check ссылается на успешную проверку
Если запись не прошла проверку, не добавлять её в таблицу.
*/

CREATE OR REPLACE FUNCTION fnc_check_before_insert_xp()
RETURNS TRIGGER
AS $trg_check_before_insert_xp$
BEGIN
    IF ((SELECT maxxp FROM checks
        JOIN tasks 
        ON checks.task = tasks.title
        WHERE NEW."Check" = checks.id) < NEW.xpamount OR
        (SELECT "State" 
            FROM p2p
            WHERE NEW."Check" = p2p."Check" AND p2p."State" IN ('Success', 'Failure')) = 'Failure' OR
        (SELECT "State"
            FROM verter
            WHERE NEW."Check" = verter."Check" AND verter."State" = 'Failure') = 'Failure') 
            THEN
            RAISE EXCEPTION 'Результат проверки не успешен или некорректное количество xp';
    END IF;
RETURN (NEW.id, NEW."Check", NEW.xpamount);
END;
$trg_check_before_insert_xp$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_before_insert_xp
BEFORE INSERT ON XP
FOR EACH ROW EXECUTE FUNCTION fnc_check_before_insert_xp();


-- Удаление триггера и добавленных строк
/*
DROP FUNCTION IF EXISTS fnc_check_before_insert_xp() CASCADE;
DELETE FROM p2p WHERE id > 40;
DELETE FROM checks WHERE id > 20;
DELETE FROM verter WHERE id > 10;
DELETE FROM xp WHERE id > 14;
*/

-- Тест 1, ожидается добавление записи в таблицу ХР т.к. проверки p2p и verter успешны
/*
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
CALL AddP2PCheck('lemuelge', 'fatimarh', 'C3_SimpleBashUtils', 'Success'::check_status, '16:00:00');
CALL AddVerterCheck('lemuelge', 'C3_SimpleBashUtils', 'Start', '16:00:05');
CALL AddVerterCheck('lemuelge', 'C3_SimpleBashUtils', 'Success', '16:00:35');
INSERT INTO xp (id, "Check", xpamount)
VALUES (15, 21, 330);
select * from xp
*/

-- Тест 2, ожидается 'Результат проверки не успешен или некорректное количество xp' 
-- т.к. проверка р2р успешна, а проверкa verter нет
/*
CALL AddP2PCheck('fatimarh', 'deadpool', 'C3_SimpleBashUtils', 'Start'::check_status, '16:30:00');
CALL AddP2PCheck('fatimarh', 'deadpool', 'C3_SimpleBashUtils', 'Success'::check_status, '17:00:00');
CALL AddVerterCheck('fatimarh', 'C3_SimpleBashUtils', 'Start', '17:00:05');
CALL AddVerterCheck('fatimarh', 'C3_SimpleBashUtils', 'Failure', '17:00:35');
INSERT INTO xp (id, "Check", xpamount)
VALUES (16, 22, 330);
*/

-- Тест 3, ожидается 'Результат проверки не успешен или некорректное количество xp' 
-- т.к. некорректное количество xp
/*
CALL AddP2PCheck('jesusaha', 'fatimarh', 'C4_s21_math', 'Start'::check_status, '20:30:00');
CALL AddP2PCheck('jesusaha', 'fatimarh', 'C4_s21_math', 'Success'::check_status, '21:00:00');
CALL AddVerterCheck('jesusaha', 'C4_s21_math', 'Start', '16:00:05');
CALL AddVerterCheck('jesusaha', 'C4_s21_math', 'Success', '16:00:35');
INSERT INTO xp (id, "Check", xpamount)
VALUES (24, 16, 400)
*/