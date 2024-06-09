CREATE TABLE enrol (
  student INT,
  course INT,
  slot INT
);

INSERT INTO enrol VALUES (1, 1, 1);


CREATE OR REPLACE FUNCTION enrol_student(student INT, course INT, newslot INT)
RETURNS VOID AS $$
DECLARE
    atotal INT;
BEGIN
    SELECT COUNT(*) INTO atotal FROM enrol
    WHERE enrol.student = $1
    AND enrol.course = $2;

    IF atotal >= 2 THEN
        RAISE EXCEPTION 'There are max. 2 exam attmepts per course';
    ELSE INSERT INTO enrol VALUES (student, course, newslot);
    END IF;

END;
$$ LANGUAGE plpgsql;


-- T1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM enrol;
SELECT * FROM enrol_student(1, 1, 2);

-- T2 
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM enrol;
SELECT * FROM enrol_student(1, 1, 2);


-- SERIALIZABLE
-- T1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM enrol;
SELECT * FROM enrol_student(1, 1, 2);

-- T2 
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM enrol;
SELECT * FROM enrol_student(1, 1, 2);