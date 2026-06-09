### Wejdź do kontenera
docker exec -it postgres psql -U <user> -d <db>

### Wykonaj po kolei:
```bash
\i /scripts/biblioteka_ddl.sql
```

```bash
\i /scripts/biblioteka_dane.sql
```

```bash
\i /scripts/biblioteka_indeks.sql
```

```bash
\i /scripts/biblioteka_dostep.sql
```

```bash
\i /scripts/test_dostepow.sql
```
