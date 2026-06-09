-- ============================================================
-- PUNKT 6: INDEKS NA TABELI wypozyczenia + EXPLAIN PLAN
-- ============================================================

SET search_path TO biblioteka;

-- ============================================================
-- KROK A – PRZED ZAŁOŻENIEM INDEKSU KOMPOZYTOWEGO
-- (istnieje już tylko idx_wypozyczenia_czytelnik z DDL)
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    w.wypozyczenie_id,
    w.data_wypozycz,
    w.data_zwrotu_plan,
    w.status,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    k.tytul
FROM biblioteka.wypozyczenia    w
         JOIN biblioteka.egzemplarze     e ON e.egzemplarz_id = w.egzemplarz_id
         JOIN biblioteka.ksiazki         k ON k.ksiazka_id    = e.ksiazka_id
         JOIN biblioteka.czytelnicy      c ON c.czytelnik_id  = w.czytelnik_id
WHERE w.czytelnik_id = 123
  AND w.status = 'aktywne';

-- ============================================================
-- KROK B – ZAŁOŻENIE INDEKSU KOMPOZYTOWEGO
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_wypozyczenia_czyt_status
    ON biblioteka.wypozyczenia (czytelnik_id, status);

ANALYZE biblioteka.wypozyczenia;

-- ============================================================
-- KROK C – PO ZAŁOŻENIU INDEKSU
-- DISCARD ALL resetuje search_path, dlatego używamy pełnych nazw
-- ============================================================
DISCARD ALL;

SET search_path TO biblioteka;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    w.wypozyczenie_id,
    w.data_wypozycz,
    w.data_zwrotu_plan,
    w.status,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    k.tytul
FROM biblioteka.wypozyczenia    w
         JOIN biblioteka.egzemplarze     e ON e.egzemplarz_id = w.egzemplarz_id
         JOIN biblioteka.ksiazki         k ON k.ksiazka_id    = e.ksiazka_id
         JOIN biblioteka.czytelnicy      c ON c.czytelnik_id  = w.czytelnik_id
WHERE w.czytelnik_id = 123
  AND w.status = 'aktywne';

-- ============================================================
-- DODATKOWE: przetrzymane posortowane po opóźnieniu
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    w.wypozyczenie_id,
    c.email,
    (CURRENT_DATE - w.data_zwrotu_plan)        AS dni_opoznienia,
    (CURRENT_DATE - w.data_zwrotu_plan) * 0.50 AS naliczona_kara
FROM biblioteka.wypozyczenia w
         JOIN biblioteka.czytelnicy   c ON c.czytelnik_id = w.czytelnik_id
WHERE w.status = 'przetrzymane'
ORDER BY dni_opoznienia DESC
    LIMIT 100;
