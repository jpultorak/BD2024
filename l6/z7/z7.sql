DROP TABLE IF EXISTS bombiarz;
DROP TABLE IF EXISTS agent;

CREATE table bombiarz (
  id int PRIMARY KEY,
  stopien int
);

CREATE table agent (
  id int PRIMARY KEY,
  bombiarz int
);

-- Mniejsze dane dla weryfikacji poprawności
INSERT INTO agent
VALUES 
  (1, 1),
  (2, 2),
  (3, 1),
  (4, NULL),
  (5, 3);

INSERT INTO bombiarz
VALUES 
  (1, 5),
  (2, 15),
  (3, 5),
  (4, 5);

-- Generowanie dużych danych
INSERT INTO bombiarz (id, stopien)
SELECT
    s,
    FLOOR(RANDOM() * 100 + 1)
FROM generate_series(1, 1000000) s;

INSERT INTO agent (id, bombiarz)
SELECT
    s,
    floor(RANDOM() * 1000000 + 1)
FROM generate_series(1, 1000000) s;


-- Wolne rozwiązania 

SELECT b.id 
FROM bombiarz b
WHERE  b.id NOT IN (SELECT bombiarz FROM agent)
AND NOT EXISTS (
    SELECT 1 FROM agent WHERE agent.bombiarz IS NULL
  );

SELECT id FROM bombiarz
WHERE id NOT IN (SELECT bombiarz FROM agent);

-- Szybsze rozwiązanania

-- 1. Może nie mają przypisanego agenta
SELECT bombiarz.id AS bombiarz, bombiarz.stopien
FROM bombiarz
LEFT JOIN agent ON agent.bombiarz = bombiarz.id
WHERE agent.id IS NULL;

-- 2. Na pewno nie mają przypisanego agenta
SELECT bombiarz.id AS bombiarz, bombiarz.stopien
FROM bombiarz
LEFT JOIN agent ON agent.bombiarz = bombiarz.id
WHERE agent.id IS NULL
AND NOT EXISTS (
    SELECT 1 FROM agent WHERE agent.bombiarz IS NULL
  );

