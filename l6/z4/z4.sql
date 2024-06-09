CREATE TABLE plan2 (
  teacher INT,
  course INT,
  hours INT
);

INSERT INTO plan2 VALUES (1, 1, 200);


CREATE OR REPLACE FUNCTION update_hours(newhours INT, emp INT, course INT)
RETURNS VOID AS $$
DECLARE
    asum INT;
BEGIN

    INSERT INTO plan2 (teacher, course, hours) VALUES (emp, course, newhours);
    SELECT SUM(hours) INTO asum
    FROM plan2
    WHERE teacher = emp;

    IF asum > 210 THEN
        RAISE EXCEPTION 'Total hours limit of 210';
    END IF;

END;
$$ LANGUAGE plpgsql;

-- T1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM plan2;
SELECT * FROM update_hours(10, 1, 2);

-- T2 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM plan2;
SELECT * FROM update_hours(10, 1, 3);


-- Repeatable read

-- T1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM plan2;
SELECT * FROM update_hours(10, 1, 2);

-- T2 
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM plan2;
SELECT * FROM update_hours(10, 1, 3);