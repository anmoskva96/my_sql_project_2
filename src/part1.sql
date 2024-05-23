--Таблица Peers (ник пира; день рождения)

CREATE TABLE Peers
(
    Nickname VARCHAR NOT NULL,
    Birthday date NOT NULL,
    PRIMARY KEY (Nickname)
);

INSERT INTO Peers
VALUES ('felisasi', '1988-09-15'),
       ('fatimarh', '1993-08-20'),
       ('garigusn', '1986-06-20'),
       ('lemuelge', '1997-05-11'),
       ('jesusaha', '1985-11-01');

--Таблица Tasks (название задания; название задания, являющегося условием входа; Максимальное количество XP)

CREATE TABLE Tasks
(
    Title VARCHAR NOT NULL,
    ParentTask VARCHAR,
    MaxXP INTEGER NOT NULL,
    PRIMARY KEY (Title),
    FOREIGN KEY (ParentTask) REFERENCES Tasks (Title)
);

INSERT INTO Tasks
VALUES ('C3_SimpleBashUtils', NULL, 350),
       ('C2_s21_string+', 'C3_SimpleBashUtils', 600),
       ('C4_s21_math', 'C3_SimpleBashUtils', 500),
       ('C5_s21_decimal', 'C3_SimpleBashUtils', 800),
       ('C6_s21_matrix', 'C5_s21_decimal', 250),
       ('C7_SmartCalc_v1.0', 'C6_s21_matrix', 800),
       ('C8_3DViewer_v1.0', 'C7_SmartCalc_v1.0', 900),
       ('DO1_Linux', 'C2_s21_string+', 200),
       ('DO2_LinuxNetwork', 'DO1_Linux', 350),
       ('DO3_LinuxMonitoring_v1.0', 'DO2_LinuxNetwork', 350),
       ('DO4_LinuxMonitoring_v2.0', 'DO3_LinuxMonitoring_v1.0', 350),
       ('DO5_SimpleDocker', 'DO3_LinuxMonitoring_v1.0', 200),
       ('DO6_CICD', 'DO5_SimpleDocker', 200),
       ('CPP1_s21_matrix+', 'C8_3DViewer_v1.0', 350),
       ('CPP2_s21_containers', 'CPP1_s21_matrix+', 800),
       ('CPP3_SmartCalc_v2.0', 'CPP2_s21_containers', 800),
       ('CPP4_3DViewer_v2.0', 'CPP3_SmartCalc_v2.0', 800),
       ('SQL1_Bootcamp', 'C8_3DViewer_v1.0', 1500),
       ('SQL2_Info21_v1.0', 'SQL1_Bootcamp', 300),
       ('SQL3_RetailAnalitycs_v1.0', 'SQL2_Info21_v1.0', 300);

--Статус проверки(начало проверки; успешное окончание проверки; неудачное окончание проверки)

CREATE TYPE Check_status AS ENUM ('Start', 'Success', 'Failure');

--Таблица Checks(ID; ник пира; название задания; дата проверки)

CREATE TABLE Checks
(
    ID     integer  NOT NULL,
    Peer   VARCHAR NOT NULL,
    Task   VARCHAR NOT NULL,
    "Date" date    NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (Peer) REFERENCES Peers (Nickname),
    FOREIGN KEY (Task) REFERENCES Tasks (Title)
);

INSERT INTO Checks
VALUES (1, 'felisasi', 'C2_s21_string+', '2023-05-01'),
       (2, 'fatimarh', 'C3_SimpleBashUtils', '2023-05-03'),
       (3, 'garigusn', 'DO3_LinuxMonitoring_v1.0', '2023-05-05'),
       (4, 'felisasi', 'C4_s21_math', '2023-05-07'),
       (5, 'garigusn', 'CPP1_s21_matrix+', '2023-05-09'),
       (6, 'garigusn', 'DO4_LinuxMonitoring_v2.0', '2023-05-09'),
       (7, 'lemuelge', 'C8_3DViewer_v1.0', '2023-05-11'),
       (8, 'jesusaha', 'C6_s21_matrix', '2023-05-14'),
       (9, 'fatimarh', 'C7_SmartCalc_v1.0', '2023-06-15'),
       (10, 'lemuelge', 'CPP4_3DViewer_v2.0', '2023-06-18'),
       (11, 'fatimarh', 'SQL1_Bootcamp', '2023-06-20'),
       (12, 'lemuelge', 'DO2_LinuxNetwork', '2023-06-21'),
       (13, 'jesusaha', 'CPP1_s21_matrix+', '2023-06-23'),
       (14, 'felisasi', 'C5_s21_decimal', '2023-06-26'),
       (15, 'jesusaha', 'SQL1_Bootcamp', '2023-06-27'),
       (16, 'felisasi', 'DO1_Linux', '2023-06-30'),
       (17, 'garigusn', 'SQL2_Info21_v1.0', '2023-06-30'),
       (18, 'lemuelge', 'SQL3_RetailAnalitycs_v1.0', '2023-06-30'),
       (19, 'fatimarh', 'DO6_CICD', '2023-06-30'),
       (20, 'jesusaha', 'DO5_SimpleDocker', '2023-06-30');

--Таблица P2P(ID; ID проверки; ник проверяющего пира; статус проверки; Время)

CREATE TABLE P2P
(
    ID integer  NOT NULL,
    "Check" integer NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    "State" Check_status NOT NULL,
    "Time" time NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY ("Check") REFERENCES Checks (ID),
    FOREIGN KEY (CheckingPeer) REFERENCES Peers (Nickname)
);

INSERT INTO P2P
VALUES (1, 1, 'lemuelge', 'Start', '10:00:00'),
       (2, 1, 'lemuelge', 'Failure', '11:30:00'), -- Verter Fail
       (3, 2, 'felisasi', 'Start', '12:15:00'),
       (4, 2, 'felisasi', 'Failure', '12:45:00'), -- Verter Fail
       (5, 3, 'fatimarh', 'Start', '12:00:00'),
       (6, 3, 'fatimarh', 'Success', '13:00:00'),
       (7, 4, 'fatimarh', 'Start', '13:00:00'),
       (8, 4, 'fatimarh', 'Success', '13:45:00'), -- Verter Ok
       (9, 5, 'felisasi', 'Start', '03:45:00'),
       (10, 5, 'felisasi', 'Success', '04:30:00'),
       (11, 6, 'felisasi', 'Start', '07:15:00'),
       (12, 6, 'felisasi', 'Success', '08:15:00'),
       (13, 7, 'jesusaha', 'Start', '18:00:00'),
       (14, 7, 'jesusaha', 'Failure', '19:10:00'), -- P2P Fail
       (15, 8, 'lemuelge', 'Start', '22:00:00'),
       (16, 8, 'lemuelge', 'Success', '22:45:00'), -- Verter Ok
       (17, 9, 'lemuelge', 'Start', '20:00:00'),
       (18, 9, 'lemuelge', 'Success', '21:00:00'),
       (19, 10, 'fatimarh', 'Start', '18:15:00'),
       (20, 10, 'fatimarh', 'Success', '20:15:00'),
       (21, 11, 'garigusn', 'Start', '12:00:00'),
       (22, 11, 'garigusn', 'Failure', '12:15:00'), -- P2P Fail
       (23, 12, 'garigusn', 'Start', '11:00:00'),
       (24, 12, 'garigusn', 'Success', '12:30:00'),
       (25, 13, 'garigusn', 'Start', '23:00:00'),
       (26, 13, 'garigusn', 'Success', '23:50:00'),
       (27, 14, 'jesusaha', 'Start', '21:30:00'),
       (28, 14, 'jesusaha', 'Failure', '22:30:00'), -- Verter Fail
       (29, 15, 'felisasi', 'Start', '15:00:00'),
       (30, 15, 'felisasi', 'Success', '15:20:00'),
       (31, 16, 'lemuelge', 'Start', '19:00:00'),
       (32, 16, 'lemuelge', 'Success', '19:59:00'),
       (33, 17, 'lemuelge', 'Start', '21:30:00'),
       (34, 17, 'lemuelge', 'Success', '22:30:00'),
       (35, 18, 'fatimarh', 'Start', '17:00:00'),
       (36, 18, 'fatimarh', 'Success', '18:30:00'),
       (37, 19, 'jesusaha', 'Start', '14:15:00'),
       (38, 19, 'jesusaha', 'Failure', '15:00:00'), -- P2P Fail
       (39, 20, 'garigusn', 'Start', '21:30:00'),
       (40, 20, 'garigusn', 'Success', '22:30:00');

--Таблица Verter(ID; ID проверки; статус проверки вертером; время)

CREATE TABLE Verter
(
    ID      integer  NOT NULL,
    "Check" integer NOT NULL,
    "State"   check_status,
    "Time"  time    NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY ("Check") REFERENCES Checks (ID)
);

INSERT INTO Verter
VALUES (1, 1, 'Start', '20:59:00'),
       (2, 1, 'Failure', '21:46:00'),
       (3, 2, 'Start', '09:00:00'),
       (4, 2, 'Failure', '09:10:11'),
       (5, 4, 'Start', '11:00:00'),
       (6, 4, 'Success', '11:05:00'),
       (7, 8, 'Start', '16:00:00'),
       (8, 8, 'Success', '16:00:59'),
       (9, 14, 'Start', '23:14:27'),
       (10, 14, 'Failure', '23:20:03');

--Таблица Transferredpoints(ID; ник проверяющего пира; ник проверяемого пира; количество переданных поинтов)

CREATE TABLE Transferredpoints
(
    ID           integer  NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    CheckedPeer  VARCHAR NOT NULL,
    PointsAmount numeric NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (CheckingPeer) REFERENCES Peers (Nickname),
    FOREIGN KEY (CheckedPeer) REFERENCES Peers (Nickname)
);

INSERT INTO Transferredpoints
VALUES (1, 'lemuelge', 'felisasi', 2),
       (2, 'felisasi', 'fatimarh', 1),
       (3, 'fatimarh', 'garigusn', 1),
       (4, 'fatimarh', 'felisasi', 1),
       (5, 'felisasi', 'garigusn', 2),
       (6, 'jesusaha', 'lemuelge', 1),
       (7, 'lemuelge', 'jesusaha', 1),
       (8, 'lemuelge', 'fatimarh', 1),
       (9, 'fatimarh', 'lemuelge', 2),
       (10, 'garigusn', 'fatimarh', 1),
       (11, 'garigusn', 'lemuelge', 1),
       (12, 'garigusn', 'jesusaha', 2),
       (13, 'jesusaha', 'felisasi', 1),
       (14, 'felisasi', 'jesusaha', 1),
       (15, 'lemuelge', 'garigusn', 1),
       (16, 'jesusaha', 'fatimarh', 1);

--Таблица Friends(ID; ник первого пира; ник второго пира)

CREATE TABLE Friends
(
    ID    integer  NOT NULL,
    Peer1 VARCHAR NOT NULL,
    Peer2 VARCHAR NOT NULL,
    PRIMARY KEY (ID),
    FOREIGN KEY (Peer1) REFERENCES Peers (Nickname),
    FOREIGN KEY (Peer2) REFERENCES Peers (Nickname)
);

CREATE UNIQUE INDEX idx_friends_peer1_peer2 ON friends (peer1, peer2);

INSERT INTO Friends
VALUES (1, 'felisasi', 'fatimarh'),
       (2, 'fatimarh', 'lemuelge'),
       (3, 'felisasi', 'jesusaha'),
       (4, 'lemuelge', 'jesusaha'),
       (5, 'garigusn', 'felisasi'),
       (6, 'garigusn', 'lemuelge');

--Таблица Recommendations(ID; ник пира; ник пира, к которому рекомендуют идти на проверку)

CREATE TABLE Recommendations
(
    ID              integer PRIMARY KEY NOT NULL,
    Peer            varchar NOT NULL,
    RecommendedPeer varchar NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers (Nickname),
    FOREIGN KEY (RecommendedPeer) REFERENCES Peers (Nickname)
);

INSERT INTO Recommendations
VALUES (1, 'felisasi', 'fatimarh'),
       (2, 'felisasi', 'lemuelge'),
       (3, 'felisasi', 'garigusn'),
       (4, 'fatimarh', 'lemuelge'),
       (5, 'fatimarh', 'jesusaha'),
       (6, 'lemuelge', 'fatimarh'),
       (7, 'lemuelge', 'jesusaha'),
       (8, 'jesusaha', 'lemuelge'),
       (9, 'jesusaha', 'felisasi'),
       (10, 'jesusaha', 'fatimarh');

--Таблица XP(ID; ID проверки; Количество полученного XP)

CREATE TABLE XP
(
    ID serial NOT NULL PRIMARY KEY,
    "Check" integer NOT NULL REFERENCES Checks (ID),
    XPAmount integer NOT NULL
);

INSERT INTO XP
VALUES (1, 3, 350),
       (2, 4, 500),
       (3, 5, 340),
       (4, 6, 350),
       (5, 8, 240),
       (6, 9, 780),
       (7, 10, 800),
       (8, 12, 340),
       (9, 13, 350),
       (10, 15, 1500),
       (11, 16, 200),
       (12, 17, 300),
       (13, 18, 300),
       (14, 20, 190);

--Таблица TimeTracking(ID; ник пира; дата; время; состояние(1-пришел, 2-вышел))

CREATE TABLE TimeTracking
(
    ID     bigint PRIMARY KEY NOT NULL,
    Peer   varchar NOT NULL,
    "Date"   date NOT NULL,
    "Time"   time NOT NULL,
    "State"  bigint NOT NULL CHECK ( "State" IN (1, 2)),
    FOREIGN KEY (Peer) REFERENCES Peers (Nickname)
);

INSERT INTO Timetracking
VALUES (1, 'garigusn', '2023-05-09', '10:10:00', 1),
       (2, 'garigusn', '2023-05-09', '15:20:00', 2),
       (3, 'garigusn', '2023-05-09', '16:00:00', 1),
       (4, 'garigusn', '2023-05-09', '22:30:00', 2),
       (5, 'fatimarh', '2023-06-15', '08:30:00', 1),
       (6, 'fatimarh', '2023-06-15', '12:00:00', 2),
       (7, 'fatimarh', '2023-06-15', '13:00:00', 1),
       (8, 'fatimarh', '2023-06-15', '19:50:00', 2),
       (9, 'felisasi', '2023-06-30', '06:10:30', 1),
       (10, 'felisasi', '2023-06-30', '12:20:00', 2),
       (11, 'felisasi', '2023-06-30', '13:00:00', 1),
       (12, 'felisasi', '2023-06-30', '17:21:00', 2),
       (13, 'felisasi', '2023-06-30', '17:50:00', 1),
       (14, 'felisasi', '2023-06-30', '23:50:00', 2);

--Процедура экспорта(Таблица, куда, разделитель)

CREATE OR REPLACE PROCEDURE EXPORT(IN TABLENAME varchar, IN PATH text, IN SEPARATOR char) AS $$
    BEGIN
        EXECUTE format('COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;',
            tablename, path, separator);
    END;
$$ LANGUAGE PLPGSQL;

--Процедура импорта(Таблица, откуда, разделитель)

CREATE OR REPLACE PROCEDURE IMPORT(IN TABLENAME varchar, IN PATH text, IN SEPARATOR char) AS $$
    BEGIN
        EXECUTE format('COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;',
            tablename, path, separator);
    END;
$$ LANGUAGE PLPGSQL;