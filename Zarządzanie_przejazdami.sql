-- Zwraca identyfikatory kierowców, którzy wykonali wiêcej ni¿ 10 zakoñczonych przejazdów
SELECT driver_id, COUNT(*) AS total_rides
FROM Rides
WHERE status = 'completed'
GROUP BY driver_id
HAVING COUNT(*) > 10;

-- Zwraca kierowców, sortuj¹c od najnowszego, pomija pierwsze 10 i zwraca kolejne 10
SELECT *
FROM Users
WHERE user_type = 'driver'
ORDER BY created_at DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Pokazuje szczegó³y przejazdów z nazw¹ pasa¿era
SELECT R.*, U.name AS rider_name
FROM Rides R
INNER JOIN Users U ON R.rider_id = U.user_id;

-- Pokazuje ka¿dy przejazd wraz z powi¹zan¹ p³atnoœci¹
SELECT R.*, P.amount
FROM Rides R
LEFT JOIN Payments P ON R.ride_id = P.ride_id;

-- Oblicza œredni czas przejazdów zakoñczonych 
SELECT AVG(DATEDIFF(SECOND, start_time, end_time) / 60.0) AS avg_duration_min
FROM Rides
WHERE end_time IS NOT NULL;

-- Zwraca wszystkie lokalizacje, niezale¿nie od tego, czy by³y u¿yte w przejazdach.
SELECT L.name, RL.type
FROM RideLocations RL
RIGHT JOIN Locations L ON RL.location_id = L.location_id;

-- Pokazuje pe³ne po³¹czenie miêdzy u¿ytkownikami a p³atnoœciami, niezale¿nie czy maj¹ powi¹zanie
SELECT U.name AS rider_name, P.amount
FROM Users U
FULL OUTER JOIN Payments P ON U.user_id = P.ride_id;

-- Symulacja ka¿dej potencjalnej trasy miêdzy dwoma ró¿nymi lokalizacjami, gdzie kierowca móg³by zostaæ przypisany
SELECT 
    D.user_id AS driver_id,
    D.name AS driver_name,
    P.name AS pickup_location,
    Dp.name AS dropoff_location
FROM Users D
CROSS JOIN Locations P
CROSS JOIN Locations Dp
WHERE D.user_type = 'driver' 
  AND P.location_id <> Dp.location_id;

-- Pokazuje ³¹czny koszt przejazdów ka¿dego kierowcy
SELECT driver_id, SUM(cost) AS total_earnings
FROM Rides
GROUP BY driver_id;

-- Znajduje przejazdy, dla których nie zosta³a zarejestrowana p³atnoœæ
SELECT R.*
FROM Rides R
LEFT JOIN Payments P ON R.ride_id = P.ride_id
WHERE P.payment_id IS NULL;


-- Zwraca 20 najdro¿szych przejazdów z klasyfikacj¹ ceny 
SELECT TOP 20 ride_id, cost,
    CASE 
        WHEN cost >= 40 THEN 'premium'
        WHEN cost >= 20 THEN 'standard'
        ELSE 'cheap'
    END AS price_class
FROM Rides
ORDER BY cost DESC;


-- Lista unikalnych lokalizacji typu pickup, posortowana alfabetycznie
SELECT DISTINCT L.name
FROM RideLocations RL
JOIN Locations L ON RL.location_id = L.location_id
WHERE RL.type = 'pickup'
ORDER BY L.name;


-- Funkcja skalara: zwraca ³¹czn¹ liczbê przejazdów u¿ytkownika
CREATE OR ALTER FUNCTION GetUserRideCount (@user_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_rides INT;

    SELECT @total_rides = COUNT(*)
    FROM Rides
    WHERE rider_id = @user_id OR driver_id = @user_id;

    RETURN @total_rides;
END;
SELECT dbo.GetUserRideCount(5) AS total_rides;

--transakcja nowego przejazdu i od razu tworzy powi¹zan¹ p³atnoœæ
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ride_id INT;

    INSERT INTO Rides (rider_id, driver_id, status, start_time)
    VALUES (1, 2, 'completed', GETDATE());

    SET @ride_id = SCOPE_IDENTITY();

    INSERT INTO Payments (ride_id, amount, payment_time, status)
    VALUES (@ride_id, 35.50, GETDATE(), 'paid');

    COMMIT;
END TRY
BEGIN CATCH
    PRINT 'Rollback: ' + ERROR_MESSAGE();
    ROLLBACK;
END CATCH;

CREATE OR ALTER TRIGGER trg_after_ride_complete
ON Rides
AFTER UPDATE
AS
BEGIN
    INSERT INTO Payments (ride_id, amount, payment_time, status)
    SELECT i.ride_id, i.cost, GETDATE(), 'paid'
    FROM inserted i
    JOIN deleted d ON i.ride_id = d.ride_id
    WHERE d.status <> 'completed' AND i.status = 'completed'
END

UPDATE Rides
SET status = 'completed', cost = 49.99
WHERE ride_id = 1 AND status <> 'completed';

--kierowcy z co najmniej 5 przejazdami
DECLARE @driver_id INT, @ride_count INT;
DECLARE driver_cursor CURSOR FOR
    SELECT driver_id, COUNT(*) AS ride_count
    FROM Rides
    GROUP BY driver_id
    HAVING COUNT(*) > 5;
OPEN driver_cursor;
FETCH NEXT FROM driver_cursor INTO @driver_id, @ride_count;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Driver ' + CAST(@driver_id AS NVARCHAR) + ' has ' + CAST(@ride_count AS NVARCHAR) + ' rides';
    FETCH NEXT FROM driver_cursor INTO @driver_id, @ride_count;
END;
CLOSE driver_cursor;
DEALLOCATE driver_cursor;

-- wypisuje identyfikatory oraz koszty przejazdów z kosztem wiêkszym ni¿ 50
DECLARE @ride_id INT, @cost DECIMAL(10,2);
DECLARE ride_cursor CURSOR FOR
    SELECT ride_id, cost FROM Rides WHERE cost > 50;
OPEN ride_cursor;
FETCH NEXT FROM ride_cursor INTO @ride_id, @cost;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Expensive ride: ID ' + CAST(@ride_id AS NVARCHAR) + ', Cost ' + CAST(@cost AS NVARCHAR);
    FETCH NEXT FROM ride_cursor INTO @ride_id, @cost;
END;
CLOSE ride_cursor;
DEALLOCATE ride_cursor;



IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_driver_id' AND object_id = OBJECT_ID('Rides'))
    DROP INDEX idx_driver_id ON Rides;
CREATE INDEX idx_driver_id ON Rides(driver_id);
SET STATISTICS IO ON;
SELECT * FROM Rides WHERE driver_id = 2;
SET STATISTICS IO OFF;


