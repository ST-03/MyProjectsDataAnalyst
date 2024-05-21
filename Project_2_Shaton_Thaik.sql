USE AdventureWorks2019
--question 1
GO
SELECT P.ProductID,	p.Name,	Color, ListPrice, Size
	FROM   Production.Product  P
	LEFT JOIN   sales.SalesOrderDetail OD ON P.ProductID = OD.ProductID
WHERE  p.ProductID NOT IN
	(SELECT ProductID
	FROM  Sales.SalesOrderDetail)
ORDER BY  P.ProductID;

  --question 2
  GO
SELECT c.CustomerID,
       ISNULL(P.LastName, 'Unknown') AS LastName,
       ISNULL(P.FirstName, 'Unknown') AS FirstName
FROM Sales.Customer C
	LEFT JOIN Sales.SalesOrderHeader SSH ON  SSH.CustomerID = C.CustomerID
	LEFT JOIN Person.Person P ON C.CustomerID = P.BusinessEntityID
WHERE SSH.CustomerID is null
ORDER BY C.CustomerID;

--question 3
GO
SELECT TOP 10 
   C.CustomerID,
   FirstName,
   LastName,
   COUNT(SOH.SalesOrderID) AS CountOfOrders
FROM Sales.Customer C
	LEFT JOIN Sales.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
	LEFT JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY C.CustomerID, P.LastName, P.FirstName
ORDER BY CountOfOrders DESC, C.CustomerID

--question 4
GO
with Emp1 as 
(select 
JobTitle, BusinessEntityID
from HumanResources.Employee)
SELECT 
    P.FirstName,
	P.LastName,
	E.JobTitle,
	E.HireDate,
    COUNT(Emp1.JobTitle) AS CountOfTitle 
FROM 
    HumanResources.Employee E
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
JOIN 
    Emp1  ON E.JobTitle = Emp1.JobTitle 
	GROUP BY 
     P.LastName, P.FirstName, E.HireDate, E.JobTitle
ORDER BY 
    E.JobTitle

--question 5
GO
WITH LatestOrD AS 
(
    SELECT 
    o2.CustomerID,
    MAX(o2.OrderDate) AS LatestOrderDate
    FROM 
    Sales.SalesOrderHeader o2
    GROUP BY 
    o2.CustomerID
)
SELECT 
    SOH.SalesOrderID,
    C.CustomerID,
    P.LastName,
    P.FirstName,
    LO.LatestOrderDate AS LastOrder,
    (
        SELECT MAX(OrderDate) 
        FROM Sales.SalesOrderHeader o3 
        WHERE o3.CustomerID = C.CustomerID 
        AND o3.OrderDate < LO.LatestOrderDate
    ) AS PreviousOrder
   FROM 
    Sales.Customer C 
JOIN 
    Person.Person P ON C.PersonID = P.BusinessEntityID
JOIN 
    LatestOrD LO ON C.CustomerID = LO.CustomerID
JOIN     
 Sales.SalesOrderHeader SOH ON SOH.CustomerID = LO.CustomerID AND SOH.OrderDate = LO.LatestOrderDate
 ORDER BY C.PersonID
 
	--question 6
	GO
WITH EXPENSIVE_ORDERS
AS
(
	SELECT YEAR(SOH.ORDERDATE)AS YEAR, SOH.SalesOrderID,PP.LastName,PP.FirstName,
	SUM(SOD.UNITPRICE*SOD.ORDERQTY*(1-SOD.UNITPRICEDISCOUNT)) OVER(PARTITION BY SOH.SalesOrderID ) AS TOTAL
	FROM sales.SalesOrderDetail AS SOD
	LEFT JOIN sales.SalesOrderHeader AS SOH
	ON SOD.SalesOrderID=SOH.SalesOrderID
	LEFT JOIN sales.Customer AS Cus
	ON Cus.CustomerID=SOH.CustomerID
	LEFT JOIN Person.Person AS PP
	ON PP.BusinessEntityID=Cus.PersonID
),
TOTAL_Products AS
(
	SELECT*,DENSE_RANK()OVER(PARTITION BY YEAR ORDER BY TOTAL DESC) AS Rn
	FROM EXPENSIVE_ORDERS
)
SELECT DISTINCT YEAR, SalesOrderID, LastName, FirstName,format (TOTAL,'#,#.0')as total
FROM TOTAL_Products
WHERE Rn=1
ORDER BY YEAR ASC



--question 7
GO
SELECT 
    Month,
    COALESCE([2011], 0) AS '2011',
    COALESCE([2012], 0) AS '2012',
    COALESCE([2013], 0) AS '2013',
    COALESCE([2014], 0) AS '2014'
FROM  
(
    SELECT 
        MONTH(OrderDate) AS Month,
        YEAR(OrderDate) AS Year,
        COUNT(*) AS OrdersCount
    FROM 
        Sales.SalesOrderHeader
    GROUP BY 
        YEAR(OrderDate), MONTH(OrderDate)
) AS SourceTable
PIVOT
(
    SUM(OrdersCount)
    FOR Year IN ([2011], [2012], [2013], [2014])
) AS TBL;
--question 8
GO
WITH YY_YY_SUM
AS
(
SELECT YEAR(OrderDate) YY, MONTH(OrderDate) MM, SUM(UnitPrice) AS SUM_Price
FROM  Sales.SalesOrderDetail OD JOIN Sales.SalesOrderHeader O
ON OD.SalesOrderID = O.SalesOrderID
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
SUM_RANK 
AS
(
SELECT *,
SUM(SUM_Price)OVER(PARTITION BY YY ORDER BY MM ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUM_SUM,
ROW_NUMBER()OVER(PARTITION BY YY ORDER BY MM) AS RN
FROM YY_YY_SUM
),
G_TOTAL
AS
(
    SELECT YY, CAST(MM AS varchar) AS MM, SUM_Price, CUM_SUM, RN
	FROM  SUM_RANK 
	UNION	
	SELECT YEAR(OrderDate) YY, 'Grand_Total',NULL , SUM(UnitPrice) AS SUM_Price, 13
	FROM  Sales.SalesOrderDetail OD JOIN Sales.SalesOrderHeader O
	ON OD.SalesOrderID = O.SalesOrderID
	GROUP BY YEAR(OrderDate)
	UNION
	SELECT 3000, 'Grand_Total', NULL, SUM(UnitPrice) AS SUM_Price, 100
	FROM  Sales.SalesOrderDetail OD JOIN Sales.SalesOrderHeader O
	ON OD.SalesOrderID = O.SalesOrderID
)
SELECT YY, MM,  SUM_Price, CUM_SUM
FROM G_TOTAL
ORDER BY YY, RN

--question 9
GO
with Employee_list
as
(
select HD.Name as DepartmentName,
HE.BusinessEntityID as [Employee'sID],
concat (PP.FirstName,' ',PP.LastName) as [Employee'sFullName],
HE.HireDate,
datediff(MONTH, HireDate,getdate()) as Seniority,
lead(concat (PP.FirstName,' ',PP.LastName)) over(partition by HD.Name order by HE.HireDate desc) as PreviuseEmpName,
lead(HE.HireDate) over(partition by HD.Name order by HE.HireDate desc) as PreviusEmpHDate
from HumanResources.Employee as HE
join HumanResources.EmployeeDepartmentHistory as EDH
on HE.BusinessEntityID = EDH.BusinessEntityID
join HumanResources.Department as HD
on EDH.DepartmentID = HD.DepartmentID
join Person.Person as PP
on HE.BusinessEntityID = PP.BusinessEntityID
)
select*,datediff(day, PreviusEmpHDate, HireDate)as DiffDays
from Employee_list
order by DepartmentName,HireDate desc


--question 10
GO
with  Employees_HireDate
AS
(
select HE.HireDate,  HED.DepartmentID,
string_agg(concat(HE.BusinessEntityID,' ',PP.LastName,' ',PP.FirstName),',') as TeamsEmployees
from HumanResources.Employee HE
JOIN HumanResources.EmployeeDepartmentHistory HED ON HED.BusinessEntityID = HE.BusinessEntityID
AND HED.EndDate IS NULL
JOIN HumanResources.Department HD ON HD.DepartmentID = HED.DepartmentID
JOIN Person.Person AS PP ON PP.BusinessEntityID = HE.BusinessEntityID
GROUP BY HE.HireDate,  HED.DepartmentID
)
SELECT * FROM Employees_HireDate
ORDER BY Employees_HireDate.HireDate DESC