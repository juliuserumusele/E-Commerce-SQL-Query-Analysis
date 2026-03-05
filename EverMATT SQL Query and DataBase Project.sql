--Create a New DataBase--
CREATE DATABASE EverMATT

USE EverMATT

--Creating Tables--

CREATE TABLE Customers( 
CustomerID VARCHAR(10) NOT NULL,
Customer_Name VARCHAR(100) NULL,
Region VARCHAR(100) NULL,
Sign_up_Date DATE NULL,PRIMARY KEY(CustomerID))


CREATE TABLE Products(
ProductID VARCHAR(10) PRIMARY KEY,
ProductName VARCHAR(50) NULL,
Category VARCHAR(50) NULL,
Price DECIMAL(8,3) NULL)

CREATE TABLE Transcations (
Transcation_ID VARCHAR(10) PRIMARY KEY,
CustomerID VARCHAR(10) NOT NULL,
ProductID VARCHAR(10) NOT NULL,
Transcation_Date DATETIME NULL,
Quantity INT NULL,
Total_Value DECIMAL(8,2) NULL,
Price DECIMAL(8,2) NULL,
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
FOREIGN KEY (ProductID) REFERENCES Products(ProductID))


ALTER TABLE Products
ALTER COLUMN Price DECIMAL(8,2)

/* Which Region are giving us the strongest Customer Growth and which Region are under performing */

SELECT
	RANK() OVER (ORDER BY GrowthNumber DESC) AS Position,
	Region,
	GrowthNumber,
	CASE WHEN GrowthNumber >= 50
	THEN 'Growth'
	ELSE 'UnderPerforming'
	END AS Status
FROM (
	
	SELECT Region,
	COUNT(CustomerID) GrowthNumber
	FROM Customers
	GROUP BY Region) AS [Growth Table]



--Find the Month-on-Month Growth of Total Sales over the last 3 years 

SELECT *,
	FORMAT((NextMonth-Thismonth)/ Thismonth, 'P') AS PercentChange
FROM(
	SELECT MONTH(Transcation_Date) Months,
	YEAR(Transcation_Date) Year,
	SUM(Total_Value) AS Thismonth,
	LEAD(SUM(Total_Value),1) OVER( ORDER BY MONTH(Transcation_Date)) NextMonth 
FROM Transcations
	WHERE YEAR(Transcation_Date) = 2024
	GROUP BY YEAR(Transcation_Date),MONTH(Transcation_Date))t



	--Find the Month-on-Month Growth of Total Sales in 2024--
SELECT *,
	FORMAT((RecentSales- PreviousSales)/ PreviousSales, 'P') AS '% Change'
FROM (
	SELECT DATENAME(MONTH,Transcation_Date) AS Months,
	SUM(Total_value) PreviousSales,
	LEAD(SUM(Total_value),1,NULL) OVER(ORDER BY MONTH(Transcation_Date)) AS RecentSales
FROM Transcations
	WHERE YEAR(Transcation_Date) = 2024
	GROUP BY MONTH(Transcation_Date),DATENAME(MONTH,Transcation_Date)) AS YoY_Table


--How long did it take Customers to make their first Transcation after their Sign Up--
SELECT *,
DATEDIFF(DAY, Sign_up_Date, Transcation_Date) AS  DaysBetween
FROM (
SELECT Customers.CustomerID,
Customer_Name,
Sign_up_Date,
Transcation_Date,
ROW_NUMBER() OVER( PARTITION BY Customers.CustomerID ORDER BY Transcation_Date) AS Rank
FROM Customers
LEFT JOIN Transcations
ON Customers.CustomerID = Transcations.CustomerID) AS t
WHERE Rank = 1


--How long did it take Customers to make their first Transcation after their Sign Up--

SELECT *,
CASE WHEN DayDifference < 0 THEN 'Before Signup'
WHEN DayDifference > 0 THEN 'After Signup'
END as Status
FROM(
SELECT *,
DATEDIFF (DAY,Sign_up_Date,Transcation_Date) AS DayDifference
FROM(
SELECT 
RANK() OVER (PARTITION BY Customers.CustomerID ORDER BY Transcation_Date) AS Rank,
Customers.CustomerID,
Customer_Name,
Region,
Sign_up_Date,
Transcation_Date
FROM Customers
LEFT JOIN Transcations
ON Customers.CustomerID = Transcations.CustomerID)t
WHERE Rank = 1)t

-- Find our Top 10 Most Profitable Customer and their Region--
WITH Tables AS (
SELECT
Customers.CustomerID,
Customer_Name,
Region,
SUM(Total_Value) AS AmountSpent
FROM Customers
LEFT JOIN Transcations
ON Customers.CustomerID = Transcations.CustomerID
GROUP BY Customers.CustomerID,Customer_Name,Region)


SELECT TOP 10 
*
FROM Tables
ORDER BY AmountSpent DESC 

-- Find the Average Number of days it Takes each Customer to Make Orders--
SELECT CustomerID,
	AVG([Days Before Next Buy])
	FROM (
	SELECT *,
	LEAD(Transcation_Date) OVER(PARTITION BY CustomerID ORDER BY Transcation_Date) AS Days,
	DATEDIFF(DAY,Transcation_Date, LEAD(Transcation_Date)
	OVER(PARTITION BY CustomerID ORDER BY Transcation_Date)) AS [Days Before Next Buy]
FROM Transcations) AS t
GROUP BY CustomerID


--what Product Category Makes up the bulk Percentage of our Sales--

SELECT ProductName,
FORMAT(SUM(Total_Value), 'C') AS TotalSales,
ROUND(PERCENT_RANK() OVER(ORDER BY SUM(Total_Value)), 3) * 100
FROM Products
LEFT JOIN Transcations
ON Products.ProductID = Transcations.ProductID
GROUP BY ProductName

--what Product Category Makes up the bulk Percentage of our Sales--

SELECT ProductName,
SUM(Total_Value) AS TotalSales,
SUM(Total_Value)* 100/ SUM(SUM(Total_Value)) OVER ()
FROM Products
LEFT JOIN Transcations
ON Products.ProductID = Transcations.ProductID
GROUP BY ProductName
ORDER BY SUM(Total_Value) DESC

--How Regions make up for the Percentage of our customers--

SELECT COUNT(CustomerID) Count,
ROUND(CAST(COUNT(CustomerID) *100 /
SUM(COUNT(CustomerID)) OVER() AS DECIMAL), 3),
Region
FROM Customers
GROUP BY Region
ORDER BY COUNT(CustomerID) DESC

SELECT *
FROM Transcations

-- Find the Moving Average and Culminative average of Monthly Sales--
SELECT 
MONTH(Transcation_date) AS MonthNumber,
DATENAME(MONTH,Transcation_Date),
SUM(Total_Value) AS TotalSales,
SUM(SUM(Total_Value)) OVER (ORDER BY MONTH(Transcation_date)) RunningTotal,
SUM(SUM(Total_Value)) OVER (ORDER BY MONTH(Transcation_date) ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS RollingTotal 
FROM Transcations
WHERE YEAR(Transcation_Date) = 2024
GROUP BY MONTH(Transcation_date),DATENAME(MONTH,Transcation_Date)
ORDER BY MONTH(Transcation_Date)


/* Which regions are bringing in new Customers most recently, 
and are we seeing any regions where signups are slowing down over time*/

SELECT 
Region,
COUNT(*) AS RecentSignups
FROM Customers
WHERE Sign_up_Date >= DATEADD(MONTH, -24, GETDATE())
GROUP BY Region
ORDER BY RecentSignups DESC

SELECT 
Region,
SUM(CASE WHEN Sign_up_Date >= DATEADD(MONTH, -24, GETDATE()) THEN 1
ELSE 0 END) AS RecentSignups,
SUM(CASE WHEN Sign_up_Date < DATEADD(MONTH, -24, GETDATE()) THEN 1
ELSE 0 END ) AS OlderSignings
FROM Customers
GROUP BY Region 
ORDER BY RecentSignups DESC


SELECT 
Region,
YEAR(Sign_up_Date) AS SignUpYear,
COUNT(Sign_up_Date) AS Count
FROM Customers
GROUP BY Region,YEAR(Sign_up_Date)
ORDER BY Region,YEAR(Sign_up_Date)


-- Which Products are we selling the most--

SELECT TOP 10
ProductName,
FORMAT(SUM(Total_Value), 'C') TotalSales
FROM products 
LEFT JOIN Transcations
ON Products.ProductID = Transcations.ProductID
GROUP BY ProductName
ORDER BY SUM(Total_Value) DESC


--Who are our Top Customers by Total Spending--

SELECT TOP 10
C.CustomerID,
	Customer_Name,
	FORMAT(SUM(Total_value), 'C') AS [Total Money Spent]
	FROM Transcations t
	LEFT JOIN Customers c
	ON t.CustomerID= c.CustomerID
GROUP BY C.CustomerID, Customer_Name
ORDER BY SUM(Total_value) DESC

--Which Days of the Week Do we get the Most Orders--

SELECT *,
DATEPART(WEEKDAY, Week) AS Weekday
FROM (
SELECT MONTH(Transcation_Date) MonthNumber,
DATENAME(MONTH,Transcation_Date) MonthName,
DATEPART( WEEK, Transcation_Date) Week,
YEAR(Transcation_Date) Years,
COUNT(Transcation_ID) AS Orders
FROM Transcations
GROUP BY YEAR(Transcation_Date), MONTH(Transcation_Date),DATENAME(MONTH,Transcation_Date) , DATEPART( WEEK, Transcation_Date)
)t



SELECT
MonthName,
COUNT(Week) OVER (PARTITION BY Years, MonthNumber ORDER BY Years, MonthNumber ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING),
Years,
Orders
FROM Monthly
ORDER BY Years,MonthNumber

USE EverMATT
-- The Top Selling Products in Each Region--

SELECT ProductName,
SUM(Total_value) TotalSales,
Region,
RANK() OVER ( PARTITION BY Region ORDER BY MAX(SUM(Total_value)))
FROM Transcations t
LEFT JOIN Customers c
ON  t.CustomerID  = C.CustomerID
LEFT JOIN Products p
ON T.ProductID = P.ProductID
GROUP BY Region, ProductName
ORDER BY SUM(Total_value) DESC


--What's Our Total Revenue Per Month--

SELECT MONTH(Transcation_Date) MonthNumber,
DATENAME(MONTH,Transcation_Date) MonthName,
YEAR(Transcation_Date) Years,
FORMAT(SUM(Total_Value), 'C') TotalRevenue
FROM Transcations
GROUP BY MONTH(Transcation_Date),
YEAR(Transcation_Date),DATENAME(MONTH,Transcation_Date)
ORDER BY YEAR(Transcation_Date)

--Whats is the Average Order Value(AOV) ??--

SELECT *,
AVG(Total_Value) OVER (PARTITION BY customerID)
FROM transcations


SELECT CustomerID,
AVG(Total_Value) as Total
FROM transcations
GROUP BY CustomerID

--Find How Many Repeat Customers do we have ?--

SELECT c.CustomerID,c.Customer_Name,
COUNT(Transcation_ID) AS [Number of Orders]
FROM Transcations t
LEFT JOIN Customers c
ON t.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Customer_Name
HAVING COUNT(Transcation_ID) >= 10
ORDER BY COUNT(Transcation_ID) DESC



--What Percentage of Our Customers are Repeat Customers--


SELECT CustomerID,
COUNT(Transcation_Date) AS Count
FROM Transcations
GROUP BY CustomerID)t



