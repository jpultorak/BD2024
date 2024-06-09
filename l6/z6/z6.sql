DROP TABLE IF EXISTS employee;

CREATE TABLE employee (
    id INT PRIMARY KEY, 
    salary NUMERIC(12, 2),
    total_articles INT
);

INSERT INTO  employee
VALUES
  (1, 3000, 3),
  (2, 4000, 2),
  (3, 2000, 4);

CREATE OR REPLACE FUNCTION give_raise()
RETURNS VOID AS $$
BEGIN
    UPDATE employee
    SET salary = 1.10 * salary
    WHERE total_articles BETWEEN 3 AND 4;
END;
$$ LANGUAGE plpgsql;



-- T1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM give_raise();

-- T2
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE employee
SET total_articles = total_articles + 1
WHERE total_articles = 4;

-- T2' Dodanie dodatkowego pracownika  
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO employee VALUES (4, 300000, 3);