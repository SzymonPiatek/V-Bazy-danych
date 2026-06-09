-- Test jako u_czytelnik
SET ROLE u_czytelnik;

SELECT tytul FROM biblioteka.ksiazki LIMIT 3;         -- powinno działać
SELECT * FROM biblioteka.czytelnicy LIMIT 1;          -- powinno dać błąd
SELECT * FROM biblioteka.wypozyczenia LIMIT 1;        -- powinno dać błąd

RESET ROLE;

-- Test jako u_bibliotekarz
SET ROLE u_bibliotekarz;

SELECT czytelnik_id, email FROM biblioteka.czytelnicy LIMIT 3;   -- powinno działać
DELETE FROM biblioteka.ksiazki WHERE ksiazka_id = 1;             -- powinno dać błąd

RESET ROLE;
