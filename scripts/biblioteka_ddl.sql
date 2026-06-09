-- ============================================================
-- SYSTEM INFORMATYCZNY: BIBLIOTEKA / WYPOŻYCZALNIA
-- Opis: DDL – tworzenie schematu bazy danych
-- ============================================================

-- Schemat
CREATE SCHEMA IF NOT EXISTS biblioteka;
SET search_path TO biblioteka;

-- ============================================================
-- 1. KATEGORIE KSIĄŻEK
-- ============================================================
CREATE TABLE kategorie (
    kategoria_id   SERIAL          PRIMARY KEY,
    nazwa          VARCHAR(100)    NOT NULL UNIQUE,
    opis           TEXT
);

-- ============================================================
-- 2. WYDAWNICTWA
-- ============================================================
CREATE TABLE wydawnictwa (
    wydawnictwo_id SERIAL          PRIMARY KEY,
    nazwa          VARCHAR(200)    NOT NULL,
    adres          VARCHAR(300),
    email          VARCHAR(150)    CHECK (email LIKE '%@%'),
    telefon        VARCHAR(20)
);

-- ============================================================
-- 3. AUTORZY
-- ============================================================
CREATE TABLE autorzy (
    autor_id       SERIAL          PRIMARY KEY,
    imie           VARCHAR(100)    NOT NULL,
    nazwisko       VARCHAR(100)    NOT NULL,
    data_urodzenia DATE,
    narodowosc     VARCHAR(60),
    CONSTRAINT chk_autor_urodzenie CHECK (data_urodzenia < CURRENT_DATE)
);

-- ============================================================
-- 4. KSIĄŻKI
-- ============================================================
CREATE TABLE ksiazki (
    ksiazka_id     SERIAL          PRIMARY KEY,
    tytul          VARCHAR(300)    NOT NULL,
    isbn           VARCHAR(20)     NOT NULL UNIQUE,
    rok_wydania    SMALLINT        NOT NULL CHECK (rok_wydania BETWEEN 1400 AND 2100),
    liczba_stron   SMALLINT        CHECK (liczba_stron > 0),
    jezyk          VARCHAR(30)     NOT NULL DEFAULT 'polski',
    kategoria_id   INT             NOT NULL REFERENCES kategorie(kategoria_id),
    wydawnictwo_id INT             REFERENCES wydawnictwa(wydawnictwo_id),
    opis           TEXT
);

-- ============================================================
-- 5. KSIĄŻKA_AUTORZY (M:N)
-- ============================================================
CREATE TABLE ksiazka_autorzy (
    ksiazka_id  INT  NOT NULL REFERENCES ksiazki(ksiazka_id) ON DELETE CASCADE,
    autor_id    INT  NOT NULL REFERENCES autorzy(autor_id)   ON DELETE CASCADE,
    PRIMARY KEY (ksiazka_id, autor_id)
);

-- ============================================================
-- 6. EGZEMPLARZE
-- ============================================================
CREATE TABLE egzemplarze (
    egzemplarz_id  SERIAL          PRIMARY KEY,
    ksiazka_id     INT             NOT NULL REFERENCES ksiazki(ksiazka_id),
    numer_inwent   VARCHAR(30)     NOT NULL UNIQUE,
    stan           VARCHAR(20)     NOT NULL DEFAULT 'dostepny'
                   CHECK (stan IN ('dostepny','wypozyczony','zarezerwowany','zniszczony','wycofany')),
    data_nabycia   DATE            NOT NULL DEFAULT CURRENT_DATE,
    cena_nabycia   NUMERIC(10,2)   CHECK (cena_nabycia >= 0)
);

-- ============================================================
-- 7. CZYTELNICY
-- ============================================================
CREATE TABLE czytelnicy (
    czytelnik_id   SERIAL          PRIMARY KEY,
    imie           VARCHAR(100)    NOT NULL,
    nazwisko       VARCHAR(100)    NOT NULL,
    pesel          CHAR(11)        UNIQUE,
    email          VARCHAR(150)    NOT NULL UNIQUE CHECK (email LIKE '%@%'),
    telefon        VARCHAR(20),
    adres          VARCHAR(300),
    data_rejestr   DATE            NOT NULL DEFAULT CURRENT_DATE,
    aktywny        BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_pesel_len CHECK (pesel IS NULL OR LENGTH(pesel) = 11)
);

-- ============================================================
-- 8. WYPOŻYCZENIA
-- ============================================================
CREATE TABLE wypozyczenia (
    wypozyczenie_id SERIAL         PRIMARY KEY,
    egzemplarz_id   INT            NOT NULL REFERENCES egzemplarze(egzemplarz_id),
    czytelnik_id    INT            NOT NULL REFERENCES czytelnicy(czytelnik_id),
    data_wypozycz   DATE           NOT NULL DEFAULT CURRENT_DATE,
    data_zwrotu_plan DATE          NOT NULL,
    data_zwrotu_fakt DATE,
    status          VARCHAR(20)    NOT NULL DEFAULT 'aktywne'
                    CHECK (status IN ('aktywne','zwrocone','przetrzymane','zgubione')),
    CONSTRAINT chk_daty_wypozyczenia
        CHECK (data_zwrotu_plan > data_wypozycz),
    CONSTRAINT chk_zwrot_po_wypozyczeniu
        CHECK (data_zwrotu_fakt IS NULL OR data_zwrotu_fakt >= data_wypozycz)
);

-- ============================================================
-- 9. KARY
-- ============================================================
CREATE TABLE kary (
    kara_id          SERIAL        PRIMARY KEY,
    wypozyczenie_id  INT           NOT NULL REFERENCES wypozyczenia(wypozyczenie_id),
    kwota            NUMERIC(8,2)  NOT NULL CHECK (kwota > 0),
    data_naliczenia  DATE          NOT NULL DEFAULT CURRENT_DATE,
    data_zaplaty     DATE,
    zaplacona        BOOLEAN       NOT NULL DEFAULT FALSE
);

-- ============================================================
-- 10. REZERWACJE
-- ============================================================
CREATE TABLE rezerwacje (
    rezerwacja_id  SERIAL          PRIMARY KEY,
    ksiazka_id     INT             NOT NULL REFERENCES ksiazki(ksiazka_id),
    czytelnik_id   INT             NOT NULL REFERENCES czytelnicy(czytelnik_id),
    data_rezerwacji DATE           NOT NULL DEFAULT CURRENT_DATE,
    data_waznosci   DATE           NOT NULL,
    status          VARCHAR(20)    NOT NULL DEFAULT 'oczekujaca'
                    CHECK (status IN ('oczekujaca','zrealizowana','anulowana')),
    CONSTRAINT chk_rezerwacja_waznosc
        CHECK (data_waznosci > data_rezerwacji)
);

-- ============================================================
-- INDEKSY PODSTAWOWE
-- ============================================================
CREATE INDEX idx_wypozyczenia_czytelnik   ON wypozyczenia(czytelnik_id);
CREATE INDEX idx_wypozyczenia_egzemplarz  ON wypozyczenia(egzemplarz_id);
CREATE INDEX idx_egzemplarze_ksiazka      ON egzemplarze(ksiazka_id);
CREATE INDEX idx_rezerwacje_czytelnik     ON rezerwacje(czytelnik_id);
