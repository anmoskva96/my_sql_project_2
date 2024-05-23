/*
1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
Ник пира 1, ник пира 2, количество переданных пир поинтов. 
Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
*/

CREATE OR REPLACE FUNCTION fnc_readable_transferred_points()
RETURNS table (peer1 varchar, peer2 varchar, amount numeric) AS $readTransferredPoints$
    BEGIN
        return query
        WITH tp2 AS (SELECT tp.checkedpeer checkingpeer, tp.checkingpeer checkedpeer
            FROM transferredpoints AS tp),
        tp3 AS (SELECT tp.checkedpeer checkingpeer, tp.checkingpeer checkedpeer, tp.pointsamount
            FROM transferredpoints AS tp),
        inter_points AS (SELECT checkingpeer, checkedpeer FROM transferredpoints
        INTERSECT
        SELECT * FROM tp2),
        count_points AS (SELECT ip1.checkingpeer, ip1.checkedpeer, CAST (count(ip1.checkingpeer) AS int) ca
            FROM inter_points ip1
            LEFT JOIN inter_points ip2 ON ip1.checkingpeer = ip2.checkedpeer
            GROUP BY ip1.checkingpeer, ip1.checkedpeer),
        clear_points AS (SELECT cp.checkingpeer, cp.checkedpeer, ca, tp.pointsamount FROM count_points cp, transferredpoints tp
        WHERE ca > 1 AND cp.checkingpeer = tp.checkingpeer AND cp.checkedpeer = tp.checkedpeer),
        second_points AS ( SELECT tp3.checkingpeer, tp3.checkedpeer, -(tp3.pointsamount) pointsamount FROM tp3
                WHERE (tp3.checkingpeer, tp3.checkedpeer) IN
              (SELECT clear_points.checkingpeer, clear_points.checkedpeer FROM clear_points)),
        repeatedPoints AS (SELECT cp.checkingpeer, cp.checkedpeer, cp.pointsamount FROM clear_points cp
        UNION
        SELECT * FROM second_points),
        final_points AS (SELECT rp.checkingpeer, rp.checkedpeer, CAST (sum(pointsamount) AS int) FROM repeatedPoints rp
            GROUP BY rp.checkingpeer, rp.checkedpeer)
        SELECT tp.checkingpeer, tp.checkedpeer, tp.pointsamount FROM transferredpoints tp
            WHERE ((checkingpeer, checkedpeer) NOT IN (SELECT checkingpeer, checkedpeer FROM final_points)) AND
                  (checkingpeer, checkedpeer) NOT IN (SELECT checkedpeer, checkingpeer FROM final_points)
        UNION
        SELECT * FROM final_points ORDER BY 1;
    end;
    $readTransferredPoints$ LANGUAGE plpgsql;

-- SELECT * FROM fnc_readable_transferred_points();

-- DROP FUNCTION IF EXISTS fnc_readable_transferred_points;

/*
2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). 
Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.
*/

CREATE OR REPLACE FUNCTION fnc_successful_checks()
RETURNS table (peer varchar, task varchar, xp int) AS $successfulChecks$
    BEGIN
        return query
        SELECT checks.peer, checks.task, x.xpamount xp FROM checks
        JOIN p2p p on checks.id = p."Check"
        JOIN xp x on checks.id = x."Check"
        WHERE p."State" = 'Success' ORDER BY peer;
    end;
    $successfulChecks$ language plpgsql;

-- SELECT * FROM fnc_successful_checks();

-- DROP FUNCTION IF EXISTS fnc_successful_checks(); 

/*
3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
Параметры функции: день, например 12.05.2022. 
Функция возвращает только список пиров.
*/

CREATE OR REPLACE FUNCTION fnc_find_diligent_students(d date)
RETURNS table (peer varchar) AS $noLifeStudents$
    BEGIN
        return query
        WITH tt AS (SELECT timetracking.peer, count(timetracking."State") c, timetracking."Date" FROM timetracking
        WHERE "State" = 1 AND "Date" = d GROUP BY timetracking.peer, timetracking."Date")
        SELECT tt.peer FROM tt WHERE c = 1;
    end;
    $noLifeStudents$ LANGUAGE plpgsql;

-- Тест 1
/*
INSERT INTO Timetracking
VALUES (15, 'garigusn', '2023-10-29', '10:10:00', 1),
        (16, 'lemuelge', '2023-10-29', '12:10:00', 1);
SELECT * FROM fnc_find_diligent_students('2023-10-29');
*/

-- Тест 2

-- SELECT * FROM fnc_find_diligent_students('2023-05-09');

-- DROP FUNCTION IF EXISTS fnc_find_diligent_students(d date);

/*
4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
Результат вывести отсортированным по изменению числа поинтов. 
Формат вывода: ник пира, изменение в количество пир поинтов
*/

CREATE OR REPLACE PROCEDURE proc_count_points(IN c refcursor)
LANGUAGE plpgsql AS $proc_count_points$
    BEGIN
        OPEN c FOR
        WITH points_taken AS (SELECT tp.checkingpeer Peer, SUM(tp.pointsamount) PointsChange FROM transferredpoints tp
    GROUP BY tp.checkingpeer),
        points_given AS (SELECT tp.checkedpeer Peer, SUM(-tp.pointsamount) PointsChange FROM transferredpoints tp
    GROUP BY tp.checkedpeer),
        all_points AS (SELECT * FROM points_taken UNION SELECT * FROM points_given),
    result AS(SELECT all_points.Peer, SUM(PointsChange) FROM all_points GROUP BY all_points.Peer
        ORDER BY 1)
        SELECT * FROM result;
    end;
$proc_count_points$;

/*
CALL proc_count_points('my_cursor');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_count_points(IN c refcursor);

/*
5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
Результат вывести отсортированным по изменению числа поинтов. 
Формат вывода: ник пира, изменение в количество пир поинтов
*/

CREATE OR REPLACE PROCEDURE proc_count_points_fnc(IN c refcursor)
LANGUAGE plpgsql AS $proc_count_points_fnc$
    BEGIN
        OPEN c FOR
        WITH points_taken AS (SELECT tp.peer1 Peer, SUM(tp.amount) PointsChange FROM fnc_readable_transferred_points() AS tp
    GROUP BY tp.peer1),
        points_given AS (SELECT tp.peer2 Peer, SUM(-tp.amount) PointsChange FROM fnc_readable_transferred_points() tp
    GROUP BY tp.peer2),
        all_points AS (SELECT * FROM points_taken UNION ALL SELECT * FROM points_given),
    result AS(SELECT all_points.Peer, SUM(PointsChange) PointsChange FROM all_points GROUP BY Peer
        ORDER BY 1)
        SELECT * FROM result;
    end;
$proc_count_points_fnc$;

/*
CALL proc_count_points_fnc('my_cursor');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_count_points_fnc(IN c refcursor);

/*
6) Определить самое часто проверяемое задание за каждый день
При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. 
Формат вывода: день, название задания
*/

CREATE OR REPLACE PROCEDURE
proc_count_most_frequently_checked_tasks(IN c refcursor)
LANGUAGE plpgsql
AS $proc_count_most_frequently_checked_tasks$
    BEGIN
        OPEN c for
        WITH counted_checks AS (SELECT task, "Date", count(task) amount FROM checks GROUP BY task, "Date"),
        max_count AS (SELECT cc.task, cc."Date", cc.amount FROM counted_checks cc
        WHERE amount = (SELECT max(amount) FROM counted_checks WHERE counted_checks."Date" = cc."Date"))
        SELECT "Date", task FROM  max_count ORDER BY "Date";
    end;
    $proc_count_most_frequently_checked_tasks$;

-- INSERT INTO checks VALUES (21, 'lemuelge', 'DO5_SimpleDocker', '2023-06-30');

-- DELETE FROM checks WHERE id > 21;

/*
CALL proc_count_most_frequently_checked_tasks('my_cursor');
FETCH ALL IN "my_cursor";
*/
-- DROP PROCEDURE IF EXISTS proc_count_most_frequently_checked_tasks(c refcursor);

/*
7) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
Параметры процедуры: название блока, например "CPP". 
Результат вывести отсортированным по дате завершения. 
Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)
*/

CREATE OR REPLACE PROCEDURE
proc_count_number_of_peers_finished_block(IN c refcursor, IN block text)
LANGUAGE plpgsql
AS $proc_count_number_of_peers_finished_block$
    BEGIN
        OPEN c for
        WITH tasks_in_blocks AS (
            SELECT substring(tasks.title  FROM '\D+\d+') AS task FROM tasks
        ),
        block_tasks AS (SELECT t.task trimmed_task FROM tasks_in_blocks t
            WHERE substring(t.task FROM '\D+') = block),
        peers_finished_block AS (SELECT c.peer, c.task, c."Date", b.trimmed_task  FROM checks c
            JOIN block_tasks b ON substring(c.task FROM '\D+\d+') = b.trimmed_task
            WHERE c.id IN (SELECT xp."Check" FROM xp)),
        result AS (SELECT (SELECT CASE WHEN (SELECT COUNT(*) FROM peers_finished_block) != (SELECT COUNT(*) FROM tasks_in_blocks)
            THEN peers_finished_block.peer
            ELSE (SELECT peer "Peer" FROM peers_finished_block WHERE "Date" = '1990-01-01') END) , "Date" AS "Date"
        FROM peers_finished_block WHERE peers_finished_block.trimmed_task = (SELECT MAX(block_tasks.trimmed_task) FROM block_tasks))
        SELECT * FROM result;
    end;
    $proc_count_number_of_peers_finished_block$;

/*
CALL proc_count_number_of_peers_finished_block('my_cursor', 'SQL');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_count_number_of_peers_finished_block(c refcursor, block text);

/*
8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. 
Формат вывода: ник пира, ник найденного проверяющего
*/

CREATE OR REPLACE PROCEDURE proc_recommendations(IN c refcursor)
LANGUAGE plpgsql AS $proc_recommendations$
    BEGIN
        OPEN c FOR
        WITH friends_reccomendations AS (SELECT f.peer1, r.recommendedpeer  FROM friends f, recommendations r
            WHERE f.peer2 = r.peer AND f.peer1 <> r.recommendedpeer ORDER BY 1, 2),
        rec_amount AS (SELECT peer1, recommendedpeer, COUNT(recommendedpeer) amount  FROM friends_reccomendations fr
            GROUP BY peer1, recommendedpeer)
        SELECT peer1, recommendedpeer FROM rec_amount r1 WHERE amount = (SELECT max(amount) FROM rec_amount r2
            WHERE r1.peer1 = r2.peer1);
    end;
    $proc_recommendations$;

/*
CALL proc_recommendations('my_cursor');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_recommendations(c refcursor);

/*
9) Определить процент пиров, которые:
Приступили только к блоку 1;
Приступили только к блоку 2;
Приступили к обоим;
Не приступили ни к одному;
Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)
*/

CREATE OR REPLACE PROCEDURE proc_blocks_started(IN c refcursor, block1 varchar, block2 varchar)
LANGUAGE plpgsql AS $proc_blocks_started$
    DECLARE n int := (SELECT CASE WHEN (SELECT COUNT(*) FROM peers) = 0 THEN 1 ELSE COUNT(*) END FROM peers);
    BEGIN
        OPEN c FOR
        WITH blocks_from_checks AS (SELECT peer, substring(task FROM '\D*') block FROM checks),
             block1_started AS (SELECT DISTINCT peer FROM blocks_from_checks WHERE block = block1),
             block2_started AS (SELECT DISTINCT peer FROM blocks_from_checks WHERE block = block2),
             both_blocks AS (SELECT DISTINCT peer FROM blocks_from_checks
             WHERE peer IN (SELECT * FROM block1_started) AND peer IN (SELECT * FROM block2_started)),
             no_blocks AS (SELECT DISTINCT peer FROM blocks_from_checks
             WHERE peer NOT IN (SELECT * FROM block1_started) AND peer NOT IN (SELECT * FROM block2_started) AND peer NOT IN (SELECT * FROM both_blocks))
        SELECT (SELECT COUNT(*)::numeric FROM block1_started) / n * 100 AS StartedBlock1, (SELECT COUNT(*)::numeric FROM block2_started) / n * 100  AS StartedBlock2,
               (SELECT COUNT(*)::numeric FROM both_blocks) / n * 100  AS StartedBothBlocks, (SELECT COUNT(*)::numeric FROM no_blocks) / n * 100  AS DidntStartAnyBlock;
    end;
    $proc_blocks_started$;

/*
CALL proc_blocks_started('my_cursor', 'C', 'SQL');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_blocks_started(c refcursor, block1 varchar, block2 varchar);

/*
10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения
*/

CREATE OR REPLACE PROCEDURE proc_success_on_birthday(IN c refcursor)
LANGUAGE plpgsql AS $proc_success_on_birthday$
--     DECLARE n numeric = (SELECT COUNT(*) n FROM peers p);
    BEGIN
        OPEN c for
        WITH birthday_checks AS (SELECT p.nickname, p.birthday, c.id, (to_char(p.birthday, 'mon DD')) day_of_birth,
                                        (to_char(c."Date", 'mon DD')) day_of_check
        FROM peers p, checks c WHERE p.nickname = c.peer),
        successfull_checks AS (SELECT nickname FROM birthday_checks, p2p
            WHERE day_of_birth = day_of_check AND p2p."Check" = birthday_checks.id AND p2p."State" = 'Success'),
        fail_checks AS (SELECT nickname FROM birthday_checks, p2p WHERE day_of_birth = day_of_check
                                                    AND p2p."Check" = birthday_checks.id AND p2p."State" = 'Failure'),
        amount_of_peers AS (SELECT (SELECT COUNT(*) FROM successfull_checks s) + (SELECT COUNT(*) FROM fail_checks f) AS n),
        s_amount AS (SELECT (CASE WHEN amount_of_peers.n = 0 THEN 0
            ELSE ((SELECT COUNT(*) FROM successfull_checks)) / (SELECT a.n FROM amount_of_peers a) * 100 END) AS percent
        FROM amount_of_peers, successfull_checks),
        f_amount AS (SELECT (CASE WHEN amount_of_peers.n = 0 THEN 0
            ELSE ((SELECT COUNT(*) FROM fail_checks) / (SELECT a.n FROM amount_of_peers a) * 100) END) AS percent
        FROM amount_of_peers, fail_checks)
        SELECT COALESCE(s_amount.percent, '0') "SuccessfulChecks", COALESCE(f_amount.percent, '0') "UnsuccessfulChecks"
        FROM f_amount
        FULL JOIN s_amount ON true AND false;
    end;
    $proc_success_on_birthday$;


/*
CALL proc_success_on_birthday('my_cursor');
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_success_on_birthday(c refcursor);

/*
11) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
Параметры процедуры: названия заданий 1, 2 и 3. 
Формат вывода: список пиров
*/

CREATE OR REPLACE PROCEDURE proc_first_two_not_three(IN c refcursor, task1 varchar, task2 varchar, task3 varchar)
AS $proc_first_two_not_three$
    BEGIN
        open c for
        WITH task1_succeed AS (SELECT DISTINCT checks.peer FROM checks, xp, tasks WHERE checks.id = xp."Check"
                                                                    AND checks.task = task1),
             task2_succeed AS (SELECT DISTINCT checks.peer FROM checks, xp, tasks WHERE checks.id = xp."Check"
                                                                    AND checks.task = task2),
             task3__fail AS (SELECT DISTINCT checks.peer FROM checks, xp, tasks WHERE checks.id NOT IN (SELECT "Check" FROM xp)
                 AND checks.task = task3),
             all_tasks AS (SELECT DISTINCT peer FROM checks WHERE peer NOT IN (SELECT peer FROM checks WHERE checks.task = task3))
        SELECT peer FROM task1_succeed
        INTERSECT
        SELECT peer FROM task2_succeed
        INTERSECT
        SELECT peer FROM all_tasks
        EXCEPT
        SELECT peer FROM task3__fail ORDER BY peer ASC;
    end;
    $proc_first_two_not_three$ LANGUAGE plpgsql;


/*
CALL AddP2PCheck('jesusaha', 'fatimarh', 'C3_SimpleBashUtils', 'Start'::check_status, '15:30:00');
CALL AddP2PCheck('jesusaha', 'fatimarh', 'C3_SimpleBashUtils', 'Failure'::check_status, '16:00:00');
CALL proc_first_two_not_three('my_cursor', 'SQL1_Bootcamp', 'C6_s21_matrix', 'C3_SimpleBashUtils');
FETCH ALL IN "my_cursor";
*/

/*
12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач
То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. 
Формат вывода: название задачи, количество предшествующих
*/

CREATE OR REPLACE FUNCTION fnc_count_parent_projects()
RETURNS table (Task varchar, PrevCount int)
AS $fnc_count_parent_projects$
    BEGIN
        return query
        WITH recursive parent_projects AS (
            SELECT title, parenttask AS current_task, (CASE WHEN parenttask IS NULL THEN 0 ELSE 1 END) amount FROM tasks
            UNION
            SELECT t.title, t.parenttask AS current_task, (CASE WHEN t.parenttask IS NULL THEN 0 ELSE amount + 1 END)
                AS amount FROM tasks t
            JOIN parent_projects pp ON pp.title = t.parenttask
    )
        SELECT title, MAX(amount) FROM parent_projects GROUP BY title;
    end;
    $fnc_count_parent_projects$ LANGUAGE plpgsql;

-- SELECT * FROM fnc_count_parent_projects();

-- DROP FUNCTION IF EXISTS fnc_count_parent_projects();

/*
13) Найти "удачные" для проверок дни. День считается "удачным",
если в нем есть хотя бы N идущих подряд успешных проверки
*/

CREATE OR REPLACE PROCEDURE proc_lucky_days(IN c refcursor, N int)
LANGUAGE plpgsql AS $proc_lucky_days$
    BEGIN
        OPEN c for
            WITH  all_checks AS (
                SELECT c.id, c."Date", p2p."Time", p2p."State", xp.xpamount FROM checks c, p2p, xp
                WHERE c.id = p2p."Check" AND (p2p."State" = 'Success' OR p2p."State" = 'Failure')
                AND c.id = xp."Check" AND xpamount >= (SELECT tasks.maxxp FROM tasks WHERE tasks.title = c.task) * 0.8
                ORDER BY c."Date", p2p."Time"),
             amount_of_succesful_checks_in_a_row AS (
                 SELECT id, "Date", "Time", "State",
                (CASE WHEN "State" = 'Success' THEN row_number() over (partition by "State", "Date") ELSE 0 END) AS amount
                                                     FROM all_checks ORDER BY "Date"
             ),
             max_in_day AS (SELECT a."Date", MAX(amount) amount FROM amount_of_succesful_checks_in_a_row a GROUP BY "Date"),
             max_in_day_of_week AS (SELECT to_char(m."Date", 'day') AS dow, sum(amount) s_amount FROM max_in_day m
                                                                                               GROUP BY dow)
             SELECT dow FROM max_in_day_of_week WHERE s_amount >= N;
    end;
    $proc_lucky_days$;

/*
CALL proc_lucky_days('1', 2);
FETCH ALL IN "1";
*/

-- DROP PROCEDURE IF EXISTS proc_lucky_days(c refcursor, N int);

/*
14) Определить пира с наибольшим количеством XP
Формат вывода: ник пира, количество XP
*/

CREATE OR REPLACE FUNCTION fnc_find_biggest_xp_peer()
RETURNS TABLE (Peer varchar, XP bigint)
AS $$
    BEGIN
    return query
    WITH succesful_projects AS
    (
        SELECT checks.peer, checks.id , checks.task FROM checks
        JOIN xp ON checks.id = xp."Check"

    ),
        xp_amount AS (SELECT s.peer, xp.xpamount, s.task, s.id FROM succesful_projects s, xp WHERE s.id = xp."Check"),
        sum_xp AS (SELECT x.peer, SUM(x.xpamount) AS xp FROM xp_amount x GROUP BY x.peer ORDER BY xp DESC)
    SELECT * FROM sum_xp WHERE sum_xp.xp = (SELECT MAX(sum_xp.xp) FROM sum_xp);
    end;
$$ LANGUAGE plpgsql;

-- DROP FUNCTION IF EXISTS fnc_find_biggest_xp_peer();

-- SELECT* FROM fnc_find_biggest_xp_peer();

/*
15) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
Параметры процедуры: время, количество раз N. 
Формат вывода: список пиров
*/

CREATE OR REPLACE PROCEDURE proc_find_entrance_before_time(IN c refcursor, t time, number int)
LANGUAGE plpgsql AS $proc_find_entrance_before_time$
    BEGIN
        open c for
        WITH entrance_times AS (SELECT DISTINCT tt.peer, tt."Date" EarlyEntries FROM timetracking tt WHERE "State" = 1 AND "Time" < t),
             count_entries AS (SELECT et.peer, COUNT(et.peer) EarlyEntries FROM entrance_times et GROUP BY et.peer)
        SELECT * FROM count_entries WHERE EarlyEntries >= number;
    end;
    $proc_find_entrance_before_time$;


/*
CALL proc_find_entrance_before_time('my_cursor', '22:00:00', 2);
FETCH ALL IN "my_cursor";
*/

/*
16) Определить пиров, выходивших за последние N дней из кампуса больше M раз
Параметры процедуры: количество дней N, количество раз M. 
Формат вывода: список пиров
*/

CREATE OR REPLACE PROCEDURE proc_find_exits_last_days(IN c refcursor, N int, M int)
LANGUAGE plpgsql
AS $proc_find_entrance_last_days$
    DECLARE date_start date := now()::date - N;
    BEGIN
        open c for
        WITH exits AS (
            SELECT tt.peer, COUNT(tt."Date") exits FROM timetracking tt
            WHERE "State" = '2' AND tt."Date" BETWEEN date_start AND now()::date
            GROUP BY tt.peer
        )
        SELECT e.peer  FROM exits e WHERE e.exits >= M;
    end;
$proc_find_entrance_last_days$;

/*
CALL proc_find_exits_last_days('my_cursor', 360, 2);
FETCH ALL IN "my_cursor";
*/

-- DROP PROCEDURE IF EXISTS proc_find_exits_last_days(IN c refcursor, N int, M int);

-- 17) Определить для каждого месяца процент ранних входов

CREATE OR REPLACE FUNCTION fnc_count_early_entries_percent()
RETURNS table (Month varchar, EarlyEntries numeric(5, 1))
AS $fnc_count_early_entries_percent$
    BEGIN
        return query
        WITH entries AS (
            SELECT tt.peer, tt."Time", (to_char(tt."Date", 'month')) AS entrance_date,
                   (to_char(p.birthday, 'month')) AS birthday FROM timetracking tt
            JOIN peers p on p.nickname = tt.peer
            WHERE tt."State" = 1
            ),
         number_of_entries AS (
             SELECT e.peer, e."Time", e.entrance_date FROM entries e
             WHERE e.entrance_date = e.birthday
             ),
         total_number_of_entries AS (
             SELECT DISTINCT e.peer, e.entrance_date, COUNT(e.entrance_date) entries FROM entries e
             WHERE e.entrance_date = e.birthday GROUP BY e.peer, e.entrance_date
             ),
         number_of_early_entries AS (SELECT t.entries, substring(t.entrance_date from '\D*') AS month
             FROM total_number_of_entries t, number_of_entries n
                 WHERE n."Time" < '12:00:00' AND n.entrance_date = t.entrance_date AND n.peer = t.peer GROUP BY t.entrance_date, t.entries),
         months AS (SELECT TRIM(to_char(generate_series('2023-01-01'::date, '2023-12-01'::date, '1 month'), 'month')) AS month, 0 AS entries),
        result AS (
            SELECT TRIM(t.month::varchar) AS month,
            (t.entries::numeric / (SELECT SUM(t.entries) FROM total_number_of_entries t) * 100) AS entries
            FROM number_of_early_entries t
            GROUP BY t.entries, t.month
            UNION ALL
            SELECT m.month::varchar, 0 FROM months m, number_of_early_entries n)
        SELECT r.month::varchar, (SUM(r.entries))::numeric(5,1) FROM result r GROUP BY r.month
            ORDER BY concat('2023-'::varchar, r.month::varchar,'-01'::varchar)::date;
    end;
    $fnc_count_early_entries_percent$ LANGUAGE plpgsql;

-- SELECT * FROM fnc_count_early_entries_percent();
--
-- UPDATE timetracking SET time = '08:00:00' WHERE id = 1;
-- INSERT INTO timetracking VALUES (23, 'peer1', '2023-01-01', '08:00:00', 1);
-- UPDATE timetracking SET date = '2023-04-05' WHERE id = 13 OR id = 14;
-- UPDATE timetracking SET time = '08:00:00' WHERE id = 13;

-- DROP FUNCTION IF EXISTS fnc_count_early_entries_percent();
