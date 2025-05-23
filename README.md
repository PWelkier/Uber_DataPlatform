# Uber_DataPlatform

# 🚖 RideShare SQL Database

Kompletny projekt bazy danych dla aplikacji typu ride-sharing (np. Uber, Bolt), zawierający:

- definicję schematu SQL,
- dane testowe (seed),
- funkcje, wyzwalacze (triggery), kursory,
- zestaw zapytań analitycznych i testowych.

## 📂 Zawartość repozytorium:

-Baza_danych-'UBER'- Tworzy strukturę tabel i wypełnia danymi testowymi
-Zarządzanie_przejazdami - Zawiera zapytania, funkcje, procedury, kursory i indeksy

## 🛠️ Technologie

- SQL Server (T-SQL)
- Transakcje, kursory, funkcje, triggery
- Statyczne i dynamiczne dane testowe

## 🧪 Zakres funkcjonalności

- Analiza kierowców i przejazdów (np. średni czas, sumy, grupowania)
- Przypisanie i rejestracja płatności (manualna i automatyczna via trigger)
- Kursory do operacji wsadowych i analitycznych
- Symulacja tras między lokalizacjami
- Funkcja skalara zliczająca przejazdy użytkownika

## 🔍 Przykładowe zapytania

- Top 20 najdroższych przejazdów z klasyfikacją cenową
- Kierowcy z więcej niż 10 zakończonymi przejazdami
- Lista unikalnych lokalizacji pickup
- Średni czas trwania przejazdu
- Symulacja tras między punktami (CROSS JOIN)
