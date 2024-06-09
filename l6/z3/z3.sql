DROP TABLE IF EXISTS plan; 
CREATE TABLE plan (
  teacher INT,
  hours INT
);
INSERT INTO plan VALUES (1, 200);


BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

CREATE OR REPLACE FUNCTION update_hours(newhours INT, emp INT)
RETURNS VOID AS $$
DECLARE
    asum INT;
BEGIN

    UPDATE plan SET hours = hours + newhours WHERE teacher = emp;
    SELECT hours INTO asum FROM plan WHERE teacher = emp;

    IF asum > 210 THEN
        RAISE EXCEPTION 'Total hours limit of 210';
    END IF;

END;
$$ LANGUAGE plpgsql;


SELECT * FROM update_hours(10, 1);