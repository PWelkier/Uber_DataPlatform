-- Usuñ tabele jeœli istniej¹ (zachowaj kolejnoœæ przez zale¿noœci)
IF OBJECT_ID('Payments', 'U') IS NOT NULL DROP TABLE Payments;
IF OBJECT_ID('RideLocations', 'U') IS NOT NULL DROP TABLE RideLocations;
IF OBJECT_ID('Rides', 'U') IS NOT NULL DROP TABLE Rides;
IF OBJECT_ID('Locations', 'U') IS NOT NULL DROP TABLE Locations;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;

-- Tworzenie tabel
CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100),
    user_type NVARCHAR(10) CHECK (user_type IN ('driver', 'rider')),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Rides (
    ride_id INT IDENTITY(1,1) PRIMARY KEY,
    rider_id INT FOREIGN KEY REFERENCES Users(user_id),
    driver_id INT FOREIGN KEY REFERENCES Users(user_id),
    status NVARCHAR(20) CHECK (status IN ('completed', 'cancelled', 'ongoing')),
    start_time DATETIME,
    end_time DATETIME,
    cost DECIMAL(10, 2)
);

CREATE TABLE Locations (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

CREATE TABLE RideLocations (
    ride_id INT FOREIGN KEY REFERENCES Rides(ride_id),
    location_id INT FOREIGN KEY REFERENCES Locations(location_id),
    type NVARCHAR(10) CHECK (type IN ('pickup', 'dropoff')),
    PRIMARY KEY (ride_id, type)
);

CREATE TABLE Payments (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    ride_id INT FOREIGN KEY REFERENCES Rides(ride_id),
    amount DECIMAL(10, 2),
    payment_time DATETIME,
    status NVARCHAR(20)
);

-- Dodajemy u¿ytkowników
DECLARE @i INT = 1;
WHILE @i <= 50
BEGIN
    INSERT INTO Users (name, user_type) VALUES ('Driver_' + CAST(@i AS NVARCHAR), 'driver');
    SET @i = @i + 1;
END;
SET @i = 1;
WHILE @i <= 50
BEGIN
    INSERT INTO Users (name, user_type) VALUES ('Rider_' + CAST(@i AS NVARCHAR), 'rider');
    SET @i = @i + 1;
END;

-- Dodajemy lokalizacje
SET @i = 1;
WHILE @i <= 100
BEGIN
    INSERT INTO Locations (name, latitude, longitude)
    VALUES (
        'Location_' + CAST(@i AS NVARCHAR),
        ROUND(RAND(CHECKSUM(NEWID())) * 180 - 90, 6),
        ROUND(RAND(CHECKSUM(NEWID())) * 360 - 180, 6)
    );
    SET @i = @i + 1;
END;

-- Dodajemy przejazdy (100)
SET @i = 1;
DECLARE @rider_id INT, @driver_id INT, @start_time DATETIME, @end_time DATETIME, @cost DECIMAL(10,2);
WHILE @i <= 100
BEGIN
    SELECT TOP 1 @rider_id = user_id FROM Users WHERE user_type = 'rider' ORDER BY NEWID();
    SELECT TOP 1 @driver_id = user_id FROM Users WHERE user_type = 'driver' ORDER BY NEWID();
    SET @start_time = DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 30), GETDATE());
    SET @end_time = DATEADD(MINUTE, 10 + (ABS(CHECKSUM(NEWID()) % 30)), @start_time);
    SET @cost = ROUND(5 + (RAND(CHECKSUM(NEWID())) * 50), 2);
    INSERT INTO Rides (rider_id, driver_id, status, start_time, end_time, cost)
    VALUES (@rider_id, @driver_id, 'completed', @start_time, @end_time, @cost);
    SET @i = @i + 1;
END;

-- Dodajemy RideLocations (pickup + dropoff)
DECLARE @ride_id INT, @pickup_id INT, @dropoff_id INT;
DECLARE ride_cursor CURSOR FOR SELECT ride_id FROM Rides;
OPEN ride_cursor;
FETCH NEXT FROM ride_cursor INTO @ride_id;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT TOP 1 @pickup_id = location_id FROM Locations ORDER BY NEWID();
    SELECT TOP 1 @dropoff_id = location_id FROM Locations ORDER BY NEWID();
    INSERT INTO RideLocations (ride_id, location_id, type) VALUES (@ride_id, @pickup_id, 'pickup');
    INSERT INTO RideLocations (ride_id, location_id, type) VALUES (@ride_id, @dropoff_id, 'dropoff');
    FETCH NEXT FROM ride_cursor INTO @ride_id;
END;
CLOSE ride_cursor;
DEALLOCATE ride_cursor;

-- Dodajemy Payments
DECLARE @payment_time DATETIME;
DECLARE payment_cursor CURSOR FOR SELECT ride_id, cost, end_time FROM Rides WHERE status = 'completed';
DECLARE @payment_ride_id INT, @payment_amount DECIMAL(10,2);
OPEN payment_cursor;
FETCH NEXT FROM payment_cursor INTO @payment_ride_id, @payment_amount, @payment_time;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO Payments (ride_id, amount, payment_time, status)
    VALUES (@payment_ride_id, @payment_amount, @payment_time, 'paid');
    FETCH NEXT FROM payment_cursor INTO @payment_ride_id, @payment_amount, @payment_time;
END;
CLOSE payment_cursor;
DEALLOCATE payment_cursor;
