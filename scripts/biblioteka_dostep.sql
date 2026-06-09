-- ============================================================
-- PUNKT 7: POLITYKA DOSTĘPU DO DANYCH – ROLE I UPRAWNIENIA
-- ============================================================

SET search_path TO biblioteka;

-- ============================================================
-- ROLE
-- ============================================================

-- Rola: tylko odczyt tabel (np. dla czytelnika / kiosku)
CREATE ROLE rola_czytelnik NOLOGIN;
GRANT USAGE  ON SCHEMA biblioteka         TO rola_czytelnik;
GRANT SELECT ON ksiazki                   TO rola_czytelnik;
GRANT SELECT ON autorzy                   TO rola_czytelnik;
GRANT SELECT ON kategorie                 TO rola_czytelnik;
GRANT SELECT ON wydawnictwa               TO rola_czytelnik;
GRANT SELECT ON egzemplarze               TO rola_czytelnik;
GRANT SELECT ON ksiazka_autorzy           TO rola_czytelnik;
-- Brak dostępu do: czytelnicy, wypozyczenia, kary, rezerwacje

-- Rola: bibliotekarz (pełny CRUD na wypożyczeniach, ograniczony na karach)
CREATE ROLE rola_bibliotekarz NOLOGIN;
GRANT USAGE  ON SCHEMA biblioteka         TO rola_bibliotekarz;
GRANT SELECT, INSERT, UPDATE, DELETE
      ON wypozyczenia, egzemplarze, rezerwacje, czytelnicy
          TO rola_bibliotekarz;
GRANT SELECT ON ksiazki, autorzy, kategorie, wydawnictwa, ksiazka_autorzy
    TO rola_bibliotekarz;
GRANT SELECT, INSERT ON kary             TO rola_bibliotekarz;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA biblioteka TO rola_bibliotekarz;

-- Rola: administrator (pełny dostęp)
CREATE ROLE rola_admin NOLOGIN;
GRANT ALL PRIVILEGES ON SCHEMA biblioteka          TO rola_admin;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA biblioteka TO rola_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA biblioteka TO rola_admin;

-- ============================================================
-- UŻYTKOWNICY
-- ============================================================
CREATE USER u_czytelnik   WITH PASSWORD 'Czytelnik123!';
CREATE USER u_bibliotekarz WITH PASSWORD 'Biblio123!';
CREATE USER u_admin        WITH PASSWORD 'Admin123!';

GRANT rola_czytelnik    TO u_czytelnik;
GRANT rola_bibliotekarz TO u_bibliotekarz;
GRANT rola_admin        TO u_admin;

-- ============================================================
-- WERYFIKACJA
-- ============================================================
-- Jako u_czytelnik:
--   SELECT * FROM biblioteka.ksiazki;          --> OK
--   SELECT * FROM biblioteka.czytelnicy;       --> ERROR: permission denied
--   INSERT INTO biblioteka.ksiazki ...;        --> ERROR: permission denied

-- Jako u_bibliotekarz:
--   SELECT * FROM biblioteka.czytelnicy;       --> OK
--   INSERT INTO biblioteka.wypozyczenia ...;   --> OK
--   DELETE FROM biblioteka.ksiazki ...;        --> ERROR: permission denied

-- ============================================================
-- ROW LEVEL SECURITY (RLS) – czytelnik widzi tylko SWOJE dane
-- Dotyczy tabeli rezerwacje i wypozyczenia (zaawansowane)
-- ============================================================
ALTER TABLE czytelnicy  ENABLE ROW LEVEL SECURITY;
ALTER TABLE rezerwacje  ENABLE ROW LEVEL SECURITY;
ALTER TABLE wypozyczenia ENABLE ROW LEVEL SECURITY;

-- Polityka: każdy czytelnik widzi tylko swój własny wiersz
-- (oparta na dopasowaniu email do current_user)
CREATE POLICY polityka_wlasny_czytelnik
    ON czytelnicy
    FOR SELECT
                   USING (email = current_user || '@biblioteka.pl');

-- Administratorzy i bibliotekarze omijają RLS
ALTER TABLE czytelnicy   FORCE ROW LEVEL SECURITY;
ALTER ROLE rola_admin BYPASSRLS;
ALTER ROLE rola_bibliotekarz BYPASSRLS;

-- ============================================================
-- REVOKE domyślnych uprawnień z PUBLIC
-- ============================================================
REVOKE ALL ON SCHEMA biblioteka FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA biblioteka FROM PUBLIC;
