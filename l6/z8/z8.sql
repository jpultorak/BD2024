DROP TABLE IF EXISTS offer;
DROP TABLE IF EXISTS company;

CREATE TABLE company(
  id INT PRIMARY KEY
);

CREATE TABLE offer (
  id INT PRIMARY KEY,
  company_id INT REFERENCES company(id)
);

INSERT INTO company(id)
SELECT generate_series(1, 1000000);

INSERT INTO offer(id, company_id)
SELECT n, floor((random() * 1000000 + 1))
FROM generate_series(1, 5000000) AS n;

-- usuwanie firm bez żadnej oferty
EXPLAIN ANALYSE
DELETE FROM company c
WHERE NOT EXISTS (
    SELECT 1 FROM offer o WHERE o.company_id = c.id
);

-- podgląd firm bez żadnej oferty
EXPLAIN ANALYSE
SELECT * FROM company c 
WHERE NOT EXISTS (
    SELECT 1 FROM offer o WHERE o.company_id = c.id
);

-- tworzenie indeksu
CREATE INDEX idx ON offer(company_id);
