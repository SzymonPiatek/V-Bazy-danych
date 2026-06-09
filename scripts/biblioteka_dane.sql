-- ============================================================
-- PUNKT 5: GENEROWANIE DANYCH – minimum 1 000 000 wierszy
-- ============================================================

SET search_path TO biblioteka;

-- Wyczyść w odpowiedniej kolejności (od dzieci do rodziców)
TRUNCATE TABLE kary, rezerwacje, wypozyczenia, egzemplarze,
               ksiazka_autorzy, ksiazki, czytelnicy,
               autorzy, wydawnictwa, kategorie
RESTART IDENTITY CASCADE;

-- ============================================================
-- KROK 1: Słowniki
-- ============================================================
INSERT INTO kategorie (nazwa, opis) VALUES
                                        ('Beletrystyka',     'Powieści i opowiadania'),
                                        ('Kryminał',         'Literatura kryminalna i sensacyjna'),
                                        ('Fantastyka',       'Science-fiction, fantasy, horror'),
                                        ('Historia',         'Książki o tematyce historycznej'),
                                        ('Nauka i technika', 'Popularnonaukowe i techniczne'),
                                        ('Dla dzieci',       'Literatura dziecięca i młodzieżowa'),
                                        ('Podróże',          'Przewodniki i reportaże podróżnicze'),
                                        ('Biznes',           'Zarządzanie, ekonomia, finanse'),
                                        ('Psychologia',      'Psychologia popularna i naukowa'),
                                        ('Encyklopedie',     'Encyklopedie i słowniki');

INSERT INTO wydawnictwa (nazwa, adres, email, telefon) VALUES
                                                           ('PWN',        'Warszawa, ul. Polna 1',     'kontakt@pwn.pl',      '22-100-2000'),
                                                           ('Znak',       'Kraków, ul. Kościuszki 37', 'kontakt@znak.pl',     '12-619-9600'),
                                                           ('Prószyński', 'Warszawa, ul. Garażowa 7',  'biuro@proszynski.pl', '22-536-8000'),
                                                           ('Rebis',      'Poznań, ul. Żmigrodzka 41', 'rebis@rebis.pl',      '61-867-8100'),
                                                           ('Marginesy',  'Warszawa, ul. Forteczna 1', 'info@marginesy.pl',   '22-839-9100'),
                                                           ('Czarne',     'Wołowiec 11',               'czarne@czarne.pl',    '13-441-7085'),
                                                           ('Zysk i S-ka','Poznań, ul. Wielka 10',     'zysk@zysk.pl',        '61-853-2738'),
                                                           ('WAM',        'Kraków, ul. Kopernika 26',  'wam@wam.pl',          '12-629-9300');

INSERT INTO autorzy (imie, nazwisko, data_urodzenia, narodowosc) VALUES
                                                                     ('Adam',      'Mickiewicz',  '1798-12-24', 'polska'),
                                                                     ('Bolesław',  'Prus',        '1847-08-20', 'polska'),
                                                                     ('Wisława',   'Szymborska',  '1923-07-02', 'polska'),
                                                                     ('Andrzej',   'Sapkowski',   '1948-06-21', 'polska'),
                                                                     ('Olga',      'Tokarczuk',   '1962-01-29', 'polska'),
                                                                     ('Ryszard',   'Kapuściński', '1932-03-04', 'polska'),
                                                                     ('Stanisław', 'Lem',         '1921-09-12', 'polska'),
                                                                     ('Stephen',   'King',        '1947-09-21', 'amerykańska'),
                                                                     ('J.K.',      'Rowling',     '1965-07-31', 'brytyjska'),
                                                                     ('Haruki',    'Murakami',    '1949-01-12', 'japońska');

-- ============================================================
-- KROK 2: 200 książek
-- ============================================================
INSERT INTO ksiazki (tytul, isbn, rok_wydania, liczba_stron, jezyk, kategoria_id, wydawnictwo_id)
SELECT
    'Książka nr ' || i,
    'BIB' || LPAD(i::text, 10, '0'),
    (1980 + (i % 44))::smallint,
    (100 + (i % 900))::smallint,
    CASE WHEN i % 5 = 0 THEN 'angielski' ELSE 'polski' END,
    (i % 10) + 1,
    (i % 8) + 1
FROM generate_series(1, 200) AS s(i);

-- ============================================================
-- KROK 3: Relacje książka-autor
-- ============================================================
INSERT INTO ksiazka_autorzy (ksiazka_id, autor_id)
SELECT ksiazka_id, (ksiazka_id % 10) + 1
FROM ksiazki;

-- ============================================================
-- KROK 4: 4 egzemplarze na książkę → 800 egzemplarzy
-- ============================================================
INSERT INTO egzemplarze (ksiazka_id, numer_inwent, stan, data_nabycia, cena_nabycia)
SELECT
    k.ksiazka_id,
    'INW/' || LPAD(row_number() OVER ()::text, 6, '0'),
    'dostepny',
    CURRENT_DATE - (random() * 3650)::int,
    (20 + random() * 130)::numeric(10,2)
FROM ksiazki k
         CROSS JOIN generate_series(1, 4);

-- ============================================================
-- KROK 5: 5000 czytelników
-- ============================================================
INSERT INTO czytelnicy (imie, nazwisko, email, telefon, data_rejestr, aktywny)
SELECT
    (ARRAY['Anna','Jan','Katarzyna','Piotr','Magdalena','Tomasz','Agnieszka',
     'Michał','Monika','Krzysztof','Ewa','Marek','Joanna','Andrzej',
     'Barbara','Paweł','Marta','Grzegorz','Aleksandra','Łukasz'])[(i % 20) + 1],
    (ARRAY['Kowalski','Nowak','Wiśniewski','Dąbrowski','Lewandowski','Wójcik',
            'Kamiński','Kowalczyk','Zielińska','Szymański','Woźniak','Kozłowski',
            'Jankowski','Wojciechowski','Kwiatkowski','Krawczyk','Piotrowska',
            'Grabowski','Nowakowski','Pawlak'])[(i % 20) + 1],
    'czytelnik' || i || '@biblioteka.pl',
    '500' || LPAD((i % 1000000)::text, 6, '0'),
    CURRENT_DATE - (random() * 1825)::int,
    random() > 0.05
FROM generate_series(1, 5000) AS s(i);

-- ============================================================
-- KROK 6: 1 200 000 wypożyczeń
-- ============================================================
INSERT INTO wypozyczenia
(egzemplarz_id, czytelnik_id, data_wypozycz, data_zwrotu_plan, data_zwrotu_fakt, status)
SELECT
    (1 + (random() * 799)::int)  AS egzemplarz_id,
    (1 + (random() * 4999)::int) AS czytelnik_id,
    (CURRENT_DATE - offset_dni)  AS data_wypozycz,
    (CURRENT_DATE - offset_dni + plan_dni)   AS data_zwrotu_plan,
    CASE WHEN losuj_zwrot < 0.75
             THEN CURRENT_DATE - offset_dni + fakt_dni
         ELSE NULL
        END AS data_zwrotu_fakt,
    CASE
        WHEN losuj_zwrot >= 0.75 THEN 'aktywne'
        WHEN losuj_status < 0.6  THEN 'zwrocone'
        WHEN losuj_status < 0.9  THEN 'przetrzymane'
        ELSE 'zgubione'
        END AS status
FROM (
         SELECT
             (random() * 1825)::int          AS offset_dni,
             (14 + (random() * 16)::int)     AS plan_dni,
             (random() * 50)::int            AS fakt_dni,
             random()                        AS losuj_zwrot,
             random()                        AS losuj_status
         FROM generate_series(1, 1200000)
     ) dane;

UPDATE wypozyczenia
SET    data_zwrotu_fakt = NULL
WHERE  status = 'aktywne' AND data_zwrotu_fakt IS NOT NULL;

-- ============================================================
-- WERYFIKACJA
-- ============================================================
ANALYZE;

SELECT relname AS tabela, n_live_tup AS wiersze
FROM   pg_stat_user_tables
WHERE  schemaname = 'biblioteka'
ORDER  BY n_live_tup DESC;
