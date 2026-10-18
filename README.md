# goit-rdb-fp: Pandemic (infectious_cases)

Фінальний проєкт курсу Relational Databases for DS (GoIT). PostgreSQL 16, Google Colab.

## Зміст репозиторію

- `fp_pandemic.ipynb`: notebook із виконаними запитами та виводами;
- `fp_pandemic.sql`: те саме одним SQL-скриптом (для `psql`);
- `infectious_cases.csv`: вихідні дані (10 521 рядок);
- `screenshots/`: скриншоти таблиць, запитів і результатів.

## Як виконано

1. **Завантаження.** Створено схему `pandemic` (`CREATE SCHEMA IF NOT EXISTS`), задано `SET search_path TO pandemic`. CSV імпортовано в `pandemic.infectious_cases` через `COPY ... FROM STDIN` (psycopg2 `copy_expert`); порожні значення стають NULL.
2. **Нормалізація до 3НФ.** `pandemic.entities` (унікальні Entity + Code, `entity_id`) і `pandemic.disease_cases` (показники, `entity_id` замість Entity і Code, унікальний `(entity_id, year)`). Кількість рядків перевірено: 245 і 10 521 (як в оригіналі).
3. **Аналіз.** Для Number_rabies по кожному `entity_id`: AVG, MIN, MAX, SUM, сортування за AVG за спаданням, 10 рядків. Рядки без значення виключено (`IS NOT NULL`).
4. **Різниця в роках.** `MAKE_DATE(year, 1, 1)`, `CURRENT_DATE`, `DATE_PART('year', AGE(...))`.
5. **Функції.** `pandemic.years_since(year)` і `pandemic.avg_cases_per_period(cases_per_year, divisor)`; використані у запитах (дільники 12, 4, 2; лише числові значення Number_rabies).

## Як запустити

1. Відкрити `fp_pandemic.ipynb` у Google Colab.
2. Runtime -> Restart session and run all; коли з'явиться вікно завантаження, вибрати `infectious_cases.csv`.

PostgreSQL 16 встановлюється через `apt` у Colab: пакет `pgserver` не ставиться на Python 3.13 (pip: "No matching distribution found").

## Скриншоти

**Завдання 1. Завантаження даних**

![Схема pandemic і search_path](screenshots/Pasted%20image.png)

![Імпорт CSV: 10 521 рядок](screenshots/Pasted%20image%20%282%29.png)

![Профіль даних](screenshots/Pasted%20image%20%283%29.png)


**Завдання 2. Нормалізація до 3НФ**

![Кількість рядків: оригінал, entities, disease_cases](screenshots/Pasted%20image%20%284%29.png)

![JOIN нормалізованих таблиць](screenshots/Pasted%20image%20%285%29.png)


**Завдання 3. Аналіз Number_rabies**

![Топ-10 за середнім Number_rabies](screenshots/Pasted%20image%20%286%29.png)


**Завдання 4. Різниця в роках**

![year_start, today, year_diff](screenshots/Pasted%20image%20%287%29.png)


**Завдання 5. Власні функції**

![years_since проти вбудованого виразу](screenshots/Pasted%20image%20%288%29.png)

![Перевірка: 0 розбіжностей](screenshots/Pasted%20image%20%289%29.png)

![avg_cases_per_period: місяць, квартал, півріччя](screenshots/Pasted%20image%20%2810%29.png)
