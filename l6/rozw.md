# Bazy danych 2024
## Lista 6

## Zadanie 1

Zakładamy, że sektory przechowywane są w tabeli 

| id     | opis |
| ----------- | ----------- |
| 1      | NULL       |
| 2   | Rzadkie gatunki ptaków        | 

Wyobraźmy sobie, że mamy dwóch pracowników P1, P2.

P1 pobiera sektor z id = 1, opis = NULL. Następnie P2 pobiera ten sam sektor - też id = 1 opis = NULL.
Teraz P1 edytuje opis na "B" i zatwierdza to - odpala się nowa transakcja, która zmienia opis w bazie na "Rzadki gatunek ptaka" i commituje.
W między czasie P2 pracował sobie nad tym samym sektorem, nieświadomy zmiany dokonanej przez P1, zmienia opis na '1000k - 4000k z wycikni drewna'

Problemem jest to, że dane są pobierane i zmieniane w innych transakcjach.

### Rozwiązania:

1. Odczyt i zapis w jednej transakcji

W takiej sytuacji transkacje będą na siebie nachodzić - jeśli P1 i P2 zaczną edycję, to gdy P1 zacommituje swoje zmiany i P2 spróbuje skommitować swoje, to baza danych wykryje, że opis sektora się zmienił
od rozpoczęcia transakcji i uniemożliwi dokonanie zmian.

2. Zmiana schematu bazy danych

Można zmienić schemat na np 

| id  | opis | wersja |
| ---| --- | --- |
| 1 | NULL | 1 |

Teraz wraz z opisem pobieramy werjsę. Podczas zmiany opisu sprawdzamy czy wersja się zgadza - jeśli tak, to zwiększamy wersję. Jeśli nie
to wiemy, że w międzyczasie doszło do aktualizacji i możemy np. powiadomić użytkownika o tym i zaprezentować mu zaktualizowany opis.


Wadą 1. jest na pewno to, że jeśli edycja trwa długo (np. pracownik chodzi po lesie i dodaje sobie stopniowo notatki o danym sektorze), to transakcja będzie trwała długo.
2, nie ma tego problem, wydaje się być lepsze.



### *Poziom uncommited read nie istnieje tak naprawde w Postgresql, więc nie będzie nawet rozważany*

## Zadanie 2

Odpowiedź: Repeatable Read

1. Read commited

Potencjalny problem jest taki, że jeśli pomiędzy wyrażeniami SELECT zostaną zacommitowane zmiany do godzin, to pierwszy SELECT obliczy starą wersję, drugi uwzględni zmiany i wynik nie bedzie
się zgadzał.

2. Repeatable Read

Różnica jest taka, że jest tylko jeden snapshot bazy danych, brany z początku transakcji, a nie przed każdym wyrażeniem. Stąd SELECT-y zawsze będą widziały to same dane.

3. Serializable

Wada jest taka, że jest po prostu najwolniejsze i niepotrzebne - Repeatable Read wydaje mi się być idealne do sekwencji operacji READ-ONLY.


## Zadanie 3


Odpowiedź: Read Commited

Moim zdaniem Read Commited to odpowiedni poziom izolacji dla tej transakcji. Zmartwieniem mogłoby być sytuacja, w której dwaj dyrektorzy zmieniają jednemu nauczycielowi w jednym momencie godziny i nie zostanie to uwzględnione . To znaczy załóżmy, że mamy krotkę (1, 200) w tabeli. Zarówno dyrektor 1 i dyrektor 2 chcą dodać 10h do nauczyciela z id = 1. Pierwsza z transakcji zaktualizuje jego godziny. Druga transakcja jak będzie chciała zaktualizować jego godziny to będzie musiała poczekać, aż pierwsza transakcja się rozwiąże. Jeśli zacommituje, to nasza tranzakcja uwzględni ten update i poprawnie obliczy, że suma jest równa 210 + 10 = 220 - przekraczający limit. W tym przypadku to, że zobaczymy inny wynik mimo tego samego query jest dla nas dobry. Tryby REPEATABLE READ i SERIALIZABLE wywalą wtedy błąd i transakcje trzeba będzie powtarzać  **(dlatego też wyższe poziomy są według mnie niewskazane)**

>UPDATE, DELETE, SELECT FOR UPDATE, and SELECT FOR SHARE commands behave the same as SELECT in terms of searching for target rows: they will only find target rows that were committed as of the command start time. However, such a target row might have already been updated (or deleted or locked) by another concurrent transaction by the time it is found. In this case, the would-be updater will wait for the first updating transaction to commit or roll back (if it is still in progress). If the first updater rolls back, then its effects are negated and the second updater can proceed with updating the originally found row. If the first updater commits, the second updater will ignore the row if the first updater deleted it, otherwise it will attempt to apply its operation to the updated version of the row.

Alternatywne rozwiązanie to użycie triggerów.

## Zadanie 4

Odpowiedź: Serializable

Teraz insertujemy, więc równoległe transakcje nie dowiedzą się o sobie nawzajem. Zarówno read commited jak i repeatable read odpadają. Musimy użyć Serializable, wtedy postgresql nie dopuści do konfliktu

W /z4/*.png są wyniki, które pokazują, że w trybach READ COMMITED i REPEATABLE READS  jesteśmy rzeczywiście w stanie łatwo zepsuć stan bazy

## Zadanie 5

Tak samo jak 4 tak naprawdę, nie ma dużo do dodania. Na screen-shotach (i w skrypcie z5.sql) widać wyniki - repeatable read pozwala na zapisanie studenta na > 2 sprawdziany, seriazable nie.

## Zadanie 6

Odopowiedź: Serializable

1. Może zostać dodany pracownik w trakcie działania transakcji
2. Liczba artykułów pracownika może zostać zmieniona podczas transakcji.

W każdym poziomie żmoże zdarzyć się taka sytuacja:

```
-- T1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM give_raise();
```

``` 
-- T2
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE employee
SET total_articles = total_articles + 1
WHERE total_articles = 2; 
```
Odpalamy T1, commitujemy T2, potem T1 - no i nic się nie zepsuje niezależnie od poziomu, a potencjalnie pojawiło się dużo nowych pracowników nadających się teraz na podwyżkę.

Mimo wszystko, to raczej nie jest problem. Jeśli założymy, że podwyżkę dajemy w oparciu o konkretny okres (np. w ostatni dzień roku bierzemy pod uwagę cały rok). PRZED tym powinniśmy zapewnić o tym, żeby baza była aktualna - uwzględnić wszystkie artykuły z tego roku (dodać brakujące), zaktualizować najpierw bazę pracowników których chcemy uwzględnić do podwyżki itd. Jeśli z kolei te wszystkie rzeczy mogą być robione w trakcie dawania podwyżki, to jest to raczej słaby design i możemy mieć niespójności takie jak opisane wyżej.


## Zadanie 7

Obserwacja: jeśli jaki agent ma atrybut bombiarz = NULL, to każdy bombiarz może mieć przydzielonego agenta. Stąd od razu wiemy, że zapytanie jest złe - nie bierze pod uwagę wartości NULL. Nawet po poprawkach pozostaje problem - jest wolne. Po odpaleniu EXPLAIN ... widzimy (plik z7/analiza_1.png), że zamierza zrobić seq skan zarówno na tabeli agent i bombiarz, więc robi coś w stylu nested loopa.

Alternatywne zapytanie z left joinem działa bardzo szybko dla dużych danych (z7/szybkie_rozw.png) - około 800ms. Ma kompletnie inny plan wykonania - korzysta z hash joina (z7/analiza_2.png).

Czemu silnik nie optymalizuje gorszego zapytania? Nie wiem za dużo na ten temat, ale wydaje mi się, że te zapytania mają trochę inną semantykę. SELECT * FROM bombiarze WHERE id NOT IN [lista] nie zwraca nic, gdy w liście jest jakikolwiek null i może dlatego postgres uważa, że trzeba zrobić zagnieżdżone seq scany.

## Zadanie 8

Pierwsza rzecz, to to że trzeba było zmienić query, tak żeby nie używało NOT IN a NOT EXISTS . Podobna sytuacja jak w zadaniu 7 - NOT IN korzysta z seq scan, a EXISTS robi jakieś hashe i wychodzi **dużo** razy szybciej. Dodatkowo indeks nic a nic nie pomagał gdy jest NOT IN.

w z8/z8.sql są zaimplementowane wszystkie użyte zapytania.


|  | Z INDEKSEM | BEZ INDEKSU |
| -------| -----------| ------------|
| DELETE |5450ms |1500000ms = 1500s = 25min  |
| SELECT |2900ms|2200ms |

Mniej więcej 275 krotne przyspieszenie w przypadku DELETE. W /z8/*.png są dokładne wyniki EXPLAIN ANALYSE, po których widać, że praktycznie cały czas jest spędzony na triggerach związanych z FK.
