

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS Delivery;
DROP TABLE IF EXISTS Supplier;
DROP TABLE IF EXISTS Sale;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Item;

CREATE TABLE Item (
  ItemName   VARCHAR(30) NOT NULL,
  ItemType   CHAR(1)     NOT NULL,
  ItemColour VARCHAR(10),
  PRIMARY KEY (ItemName)
);

CREATE TABLE Employee (
  EmployeeNumber  SMALLINT  NOT NULL,
  EmployeeName    VARCHAR(10) NOT NULL,
  EmployeeSalary  INTEGER   NOT NULL,
  DepartmentName  VARCHAR(10) NOT NULL REFERENCES Department,
  BossNumber      SMALLINT  NOT NULL REFERENCES Employee,
  PRIMARY KEY (EmployeeNumber)
);

CREATE TABLE Department (
  DepartmentName  VARCHAR(10) NOT NULL,
  DepartmentFloor SMALLINT     NOT NULL,
  DepartmentPhone SMALLINT     NOT NULL,
  EmployeeNumber  SMALLINT     NOT NULL REFERENCES Employee,
  PRIMARY KEY (DepartmentName)
);

CREATE TABLE Sale (
  SaleNumber     INTEGER   NOT NULL,
  SaleQuantity   SMALLINT  NOT NULL DEFAULT 1,
  ItemName       VARCHAR(30) NOT NULL REFERENCES Item,
  DepartmentName VARCHAR(10) NOT NULL REFERENCES Department,
  PRIMARY KEY (SaleNumber)
);

CREATE TABLE Supplier (
  SupplierNumber INTEGER     NOT NULL,
  SupplierName   VARCHAR(30) NOT NULL,
  PRIMARY KEY (SupplierNumber)
);

CREATE TABLE Delivery (
  DeliveryNumber  INTEGER   NOT NULL,
  DeliveryQuantity SMALLINT NOT NULL DEFAULT 1,
  ItemName        VARCHAR(30) NOT NULL REFERENCES Item,
  DepartmentName  VARCHAR(10) NOT NULL REFERENCES Department,
  SupplierNumber  INTEGER     NOT NULL REFERENCES Supplier,
  PRIMARY KEY (DeliveryNumber)
);

PRAGMA foreign_keys = ON;


-- using the data in the text files, insert into the tables this information

PRAGMA foreign_keys = OFF;

-- Items (types used in questions: 'E' and 'N')
INSERT INTO Item VALUES
('Stetsons','E','Brown'),
('Compass','N','Black'),
('Jacket','E','Blue'),
('Notebook','N','White'),
('Socks','E','Red');

-- Employees (self-boss for heads to break the cycle cleanly)
INSERT INTO Employee VALUES
(1,'Clare',26000,'Marketing',1),
(2,'Alice',24000,'Clothes',2),
(3,'Bob',18000,'Clothes',2),
(4,'Eve',22000,'Marketing',1);

-- Departments (heads point to existing employees)
INSERT INTO Department VALUES
('Marketing',2,100,1),
('Clothes',3,200,2);

-- Sales
INSERT INTO Sale VALUES
(1,3,'Compass','Marketing'),
(2,2,'Stetsons','Clothes'),
(3,1,'Jacket','Marketing');

-- Suppliers
INSERT INTO Supplier VALUES
(10,'Acme Co'),
(11,'Globex'),
(12,'Umbrella');

-- Deliveries
INSERT INTO Delivery VALUES
(1,5,'Compass','Marketing',10),
(2,4,'Stetsons','Clothes',11),
(3,6, 'Notebook','Marketing',10),
(4,2, 'Socks','Clothes',12),
(5,1, 'Jacket','Marketing',12);

PRAGMA foreign_keys = ON;

-- sanity check
SELECT 'Item' AS t, COUNT(*) FROM Item
UNION ALL SELECT 'Employee', COUNT(*) FROM Employee
UNION ALL SELECT 'Department', COUNT(*) FROM Department
UNION ALL SELECT 'Sale', COUNT(*) FROM Sale
UNION ALL SELECT 'Supplier', COUNT(*) FROM Supplier
UNION ALL SELECT 'Delivery', COUNT(*) FROM Delivery;


-- 1) Names of employees in Marketing
SELECT EmployeeName
FROM Employee
WHERE DepartmentName = 'Marketing';

-- 2) Items sold by departments on the second floor (equijoin)
SELECT DISTINCT s.ItemName
FROM Sale s, Department d
WHERE s.DepartmentName = d.DepartmentName
  AND d.DepartmentFloor = 2;

-- 2b) Same using NATURAL JOIN, then compare to explicit JOIN
SELECT DISTINCT ItemName
FROM (Sale NATURAL JOIN Department)
WHERE DepartmentFloor = 2;

SELECT DISTINCT s.ItemName
FROM Sale s
JOIN Department d ON s.DepartmentName = d.DepartmentName
WHERE d.DepartmentFloor = 2;

-- 3) Items available on floors other than floor 2, listed by floor
SELECT DISTINCT d.DepartmentFloor AS OnFloor, del.ItemName
FROM Delivery del
JOIN Department d ON del.DepartmentName = d.DepartmentName
WHERE d.DepartmentFloor <> 2
ORDER BY d.DepartmentFloor, del.ItemName;

-- 4) Average salary in Clothes
SELECT AVG(EmployeeSalary) AS avg_salary_clothes
FROM Employee
WHERE DepartmentName = 'Clothes';

-- 5) For each department, avg salary, descending by avg
SELECT DepartmentName, AVG(EmployeeSalary) AS avg_salary
FROM Employee
GROUP BY DepartmentName
ORDER BY avg_salary DESC;

-- 6) Items delivered by exactly one supplier
SELECT ItemName
FROM Delivery
GROUP BY ItemName
HAVING COUNT(DISTINCT SupplierNumber) = 1;

-- 7) Suppliers that deliver at least 10 distinct items
-- (will be empty on the tiny seed; works with full lab data)
SELECT s.SupplierNumber, s.SupplierName
FROM Delivery d
JOIN Supplier s ON d.SupplierNumber = s.SupplierNumber
GROUP BY s.SupplierNumber, s.SupplierName
HAVING COUNT(DISTINCT d.ItemName) >= 10;

-- 8) Count of direct reports per manager (self-join)
SELECT b.EmployeeNumber, b.EmployeeName, COUNT(*) AS Employees
FROM Employee w
JOIN Employee b ON w.BossNumber = b.EmployeeNumber
GROUP BY b.EmployeeNumber, b.EmployeeName;

-- 9) For each department that sells ItemType 'E', avg employee salary
SELECT d.DepartmentName, AVG(e.EmployeeSalary) AS avg_salary
FROM Employee e, Department d, Sale s, Item i
WHERE e.DepartmentName = d.DepartmentName
  AND d.DepartmentName = s.DepartmentName
  AND s.ItemName = i.ItemName
  AND i.ItemType = 'E'
GROUP BY d.DepartmentName;

-- 10) Total number of items of type 'E' sold by departments on floor 2
SELECT SUM(s.SaleQuantity) AS number_of_items
FROM Department d, Sale s, Item i
WHERE d.DepartmentName = s.DepartmentName
  AND s.ItemName = i.ItemName
  AND i.ItemType = 'E'
  AND d.DepartmentFloor = 2;



-- N1) Items sold by departments on floor 2 (subquery version)
SELECT DISTINCT ItemName
FROM Sale
WHERE DepartmentName IN (
  SELECT DepartmentName
  FROM Department
  WHERE DepartmentFloor = 2
);

-- N2) Salary of Clare's manager
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeNumber = (
  SELECT BossNumber
  FROM Employee
  WHERE EmployeeName = 'Clare'
);

-- N3) Managers with more than two employees
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeNumber IN (
  SELECT BossNumber
  FROM Employee
  GROUP BY BossNumber
  HAVING COUNT(*) > 2
);

-- N4) Employees who earn more than any employee in Marketing
SELECT EmployeeName, EmployeeSalary
FROM Employee
WHERE EmployeeSalary > (
  SELECT MAX(EmployeeSalary) FROM Employee
  WHERE DepartmentName = 'Marketing'
);

-- N5) Among departments with total salary > 25000, which sell 'Stetsons'?
SELECT DISTINCT DepartmentName
FROM Sale
WHERE ItemName = 'Stetsons'
  AND DepartmentName IN (
    SELECT DepartmentName
    FROM Employee
    GROUP BY DepartmentName
    HAVING SUM(EmployeeSalary) > 25000
  );

-- N6) Suppliers that deliver compasses and at least one other kind of item
SELECT DISTINCT d.SupplierNumber, s.SupplierName
FROM Supplier s NATURAL JOIN Delivery d
WHERE d.ItemName <> 'Compass'
  AND d.SupplierNumber IN (
    SELECT SupplierNumber FROM Delivery WHERE ItemName = 'Compass'
  );

-- N7) Suppliers that deliver compasses and at least three other kinds of item
SELECT d.SupplierNumber, s.SupplierName
FROM Supplier s NATURAL JOIN Delivery d
WHERE d.SupplierNumber IN (
  SELECT SupplierNumber FROM Delivery WHERE ItemName = 'Compass'
)
GROUP BY d.SupplierNumber, s.SupplierName
HAVING COUNT(DISTINCT d.ItemName) > 3;

-- N8) Departments where every item they receive is also delivered to some other department
SELECT DISTINCT d1.DepartmentName
FROM Delivery d1
WHERE NOT EXISTS (
  SELECT 1
  FROM Delivery d2
  WHERE d2.DepartmentName = d1.DepartmentName
    AND d2.ItemName NOT IN (
      SELECT d3.ItemName
      FROM Delivery d3
      WHERE d3.DepartmentName <> d1.DepartmentName
    )
);
