--Advanced select and joins
--1. Consecutive_Numbers
select distinct l1.num as ConsecutiveNums from logs l1, logs l2, logs l3
where l1.id=l2.id+1 and l1.num=l2.num
and l1.id=l3.id+2 and l1.num= l3.num

--2. Count_Salary_Categories
(SELECT "Low Salary" AS category, COUNT(*) AS accounts_count FROM accounts WHERE income < 20000)
UNION
(SELECT "Average Salary" AS category, COUNT(*) AS accounts_count FROM accounts WHERE income BETWEEN 20000 AND 50000)
UNION
(SELECT "High Salary" AS category, COUNT(*) AS accounts_count FROM accounts WHERE income > 50000)

--3. Last_Person_to_Fit_in_the_Bus
select 
    queue1.person_name
from 
    queue queue1 join queue queue2
on 
    queue1.turn >= queue2.turn
group by 
    queue1.turn
having 
    sum(queue2.weight) <= 1000
order by 
    sum(queue2.weight) desc
limit 1;

--4. Primary_Department_for_Each_Employee
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag='Y' OR 
    employee_id in
    (SELECT employee_id
    FROM Employee
    Group by employee_id
    having count(employee_id)=1)

--5. Product_Price_at_a_Given_Date
select product_id ,10 as price from products group by product_id having min(change_date) > '2019-08-16'
union all
select product_id , new_price as price from products
where( product_id , change_date) in (select product_id , max(change_date) as price from products where change_date <=  '2019-08-16' group by product_id)

--6. The_Number_of_Employees_Which_Report_to_Each_Employee
select e1.employee_id, e1.name, count(e2.employee_id) as reports_count,
     round(avg(e2.age)) as average_age
     from employees e1 join employees e2 on e1.employee_id = e2.reports_to
group by e1.employee_id, e1.name
order by e1.employee_id

--7. Triangle_Judgement
SELECT *, IF(x+y>z and y+z>x and z+x>y, "Yes", "No") as triangle FROM Triangle

--Advanced_String_Functions_Regex_Clause
--1. Delete_Duplicate_Emails
DELETE p1 FROM Person p1,
    Person p2
WHERE
    p1.Email = p2.Email AND p1.Id > p2.Id

--2.Find_Users_With_Valid_E_Mails
SELECT * FROM Users
WHERE regexp_like(mail, '^[A-Za-z]+[A-Za-z0-9\_\.\-]*@leetcode\\.com$')

--3. Fix_Names_in_a_Table
SELECT user_id, 
CONCAT(UPPER(LEFT(name, 1)), 
LOWER(RIGHT(name, LENGTH(name) - 1))) 
AS name 
FROM Users 
ORDER BY user_id;

--4. Group_Sold_Products_By_The_Date
select sell_date, count(DISTINCT product) as num_sold,
GROUP_CONCAT(DISTINCT product order by product ASC separator ',') as products
FROM Activities GROUP BY sell_date order by sell_date ASC;

--5. List_the_Products_Ordered_in_a_Period
select p.product_name, sum(o.unit) as unit from Products p join Orders o on p.product_id=o.product_id where o.order_date>='2020-02-01' and o.order_date<='2020-02-29'
group by o.product_id having unit>=100

--6. List_the_Products_Ordered_in_a_Period
select p.product_name, sum(o.unit) as unit from Products p join Orders o on p.product_id=o.product_id where o.order_date>='2020-02-01' and o.order_date<='2020-02-29'
group by o.product_id having unit>=100 

--7.Patients_With_a_Condition
SELECT * FROM patients WHERE conditions REGEXP '\\bDIAB1'

--8.Second_Highest_Salary
select
(select distinct Salary 
from Employee order by salary desc 
limit 1 offset 1) 
as SecondHighestSalary;

--Basic Aggregate functions
--1.Average_Selling_Price
select p.product_id ,Coalesce(round(sum(p.price * u.units) / sum(u.units),2),0) as average_price from prices p left join unitssold u
on p.product_id = u.product_id and u.purchase_date between p.start_date and p.end_date
group by p.product_id;

--2.Game_Play_Analysis_IV
SELECT
  ROUND(COUNT(DISTINCT player_id) / (SELECT COUNT(DISTINCT player_id) FROM Activity), 2) AS fraction
FROM
  Activity
WHERE
  (player_id, DATE_SUB(event_date, INTERVAL 1 DAY))
  IN (SELECT player_id, MIN(event_date) AS first_login FROM Activity GROUP BY player_id)

--3.Immediate_Food_Delivery_II
Select 
    round(avg(order_date = customer_pref_delivery_date)*100, 2) as immediate_percentage
from Delivery
where (customer_id, order_date) in (
  Select customer_id, min(order_date) 
  from Delivery
  group by customer_id
);

--4. Monthly_Transactions_I
SELECT  SUBSTR(trans_date,1,7) as month, country, count(id) as trans_count, SUM(CASE WHEN state = 'approved' then 1 else 0 END) as approved_count, SUM(amount) as trans_total_amount, SUM(CASE WHEN state = 'approved' then amount else 0 END) as approved_total_amount
FROM Transactions
GROUP BY month, country

--5.Not_Boring_Movies
SELECT * FROM Cinema WHERE MOD( id, 2) = 1 AND 
description <> 'boring' ORDER BY rating DESC

--6.Percentage_of_Users_Attended_a_Contest
select 
contest_id, 
round(count(distinct user_id) * 100 /(select count(user_id) from Users) ,2) as percentage
from  Register
group by contest_id
order by percentage desc,contest_id

--7.Project_Employees_I
select
    project_id,
    round(sum(experience_years)/count(project_id), 2) average_years
from
    Project P
left join
    Employee E on P.employee_id = E.employee_id
group by project_id

--8. Queries_Quality_and_Percentage
select distinct query_name , round(avg(rating/position) over(partition by query_name) ,2) as quality,
round(avg(case when rating<3 then 1 else 0 end) over(partition by query_name)*100,2) as poor_query_percentage from queries
where query_name is not null

--Basic Joins
--1. Average_Time_of_Process_per_Machine
select a1.machine_id, round(avg(a2.timestamp-a1.timestamp), 3) as processing_time 
from Activity a1
join Activity a2 
on a1.machine_id=a2.machine_id and a1.process_id=a2.process_id
and a1.activity_type='start' and a2.activity_type='end'
group by a1.machine_id

--2.Confirmation_Rate
select s.user_id, round(avg(if(c.action="confirmed",1,0)),2) as confirmation_rate
from Signups as s left join Confirmations as c on s.user_id= c.user_id group by user_id;

--3.Customer_Who_Visited_but_Did_Not_Make_Any_Transactions
SELECT customer_id, COUNT(v.visit_id) as count_no_trans 
FROM Visits v
LEFT JOIN Transactions t ON v.visit_id = t.visit_id
WHERE transaction_id IS NULL
GROUP BY customer_id

--4.Employee_Bonus
SELECT Employee.name,Bonus.bonus FROM Employee 
LEFT JOIN Bonus ON Employee.empID = Bonus.empID
WHERE bonus < 1000 OR Bonus IS NULL ;

--5.Managers_with_at_Least_5_Direct_Reports
SELECT a.name 
FROM Employee a 
JOIN Employee b ON a.id = b.managerId 
GROUP BY b.managerId 
HAVING COUNT(*) >= 5

--6. Product_Sales_Analysis_I
SELECT product_name, year, price FROM Sales
INNER JOIN Product
ON Sales.product_id = Product.product_id;

--7. Replace_Employee_ID_With_The_Unique_Identifier
select eu.unique_id as unique_id, e.name as name
from Employees e left join EmployeeUNI eu on e.id = eu.id

--8.Rising_Temperature
SELECT id
FROM Weather w1
WHERE temperature > (
    SELECT temperature
    FROM Weather w2
    WHERE w2.recordDate = DATE_SUB(w1.recordDate, INTERVAL 1 DAY)
);

--9.Students_and_Examinations
select s.student_id, s.student_name, sub.subject_name , count(e.student_id) as attended_exams 
from students s
cross join subjects sub
left join examinations e ON s.student_id = e.student_id and sub.subject_name = e.subject_name
group by 1,2,3
order by 1,3

--Select statements
--1.Article_Views_I
select distinct author_id as id from Views
where author_id = viewer_id 
order by id;

--2.Big_Countries
SELECT name, population, area FROM World
WHERE population >= 25000000 OR area >= 3000000;

--3.Find_Customer_Referees
select name from Customer where referee_id is null or referee_id!=2;

--4.Invalid_Tweets
SELECT tweet_id FROM Tweets
WHERE LENGTH(content) > 15;

--5. Recyclable_and_Low_Fat_Products
select product_id from Products where low_fats ="Y" and recyclable ="Y"

--Sorting and grouping
--1.Biggest_Single_Number
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(*) = 1
) AS single_numbers
ORDER BY num DESC
LIMIT 1;

--2.Classes_More_Than_5_Students
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5;

--3.Customers_Who_Bought_All_Products
SELECT  customer_id FROM Customer GROUP BY customer_id
HAVING COUNT(distinct product_key) = (SELECT COUNT(product_key) FROM Product)

--4.Find_Followers_Count
select user_id, count(follower_id) as followers_count
from Followers
group by user_id
order by user_id asc

--5.Number_of_Unique_Subjects_Taught_by_Each_Teacher
select  teacher_id , count( distinct subject_id)  as cnt from teacher
group by teacher_id;

--6.Product_Sales_Analysis_III
WITH CTE AS (
    SELECT product_id, MIN(year) AS minyear FROM Sales 
    GROUP BY product_id )
SELECT s.product_id, s.year AS first_year, s.quantity, s.price 
FROM Sales s
INNER JOIN CTE ON cte.product_id = s.product_id  AND s.year = cte.minyear; 

--7.User_Activity_for_the_Past_30_Days_I
SELECT activity_date AS day, COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE (activity_date > "2019-06-27" AND activity_date <= "2019-07-27")
GROUP BY activity_date;

--Subqueries
--1. Department_Top_Three_Salaries
SELECT 
    Department, 
    Employee, 
    salary 
FROM (
    SELECT     
        dept.name AS Department,     
        emp.name AS Employee,     
        emp.salary,     
        DENSE_RANK() OVER (PARTITION BY dept.name ORDER BY emp.salary DESC) AS rate
    FROM 
        Employee emp
    JOIN 
        Department dept
    ON 
        emp.departmentid = dept.id 
) t1 
WHERE rate <= 3;

--2.Employees_Whose_Manager_Left_the_Company
SELECT DISTINCT E2.EMPLOYEE_ID FROM EMPLOYEES E1,EMPLOYEES E2 WHERE E2.SALARY<30000 AND
E2.MANAGER_ID NOT IN(SELECT EMPLOYEE_ID FROM EMPLOYEES) ORDER BY EMPLOYEE_ID;

--3.Exchange_Seats
SELECT CASE
           WHEN s.id % 2 <> 0 AND s.id = (SELECT COUNT(*) FROM Seat) THEN s.id
           WHEN s.id % 2 = 0 THEN s.id - 1
           ELSE
               s.id + 1
           END AS id,
       student
FROM Seat AS s
ORDER BY id

--4.Friend_Requests_II_Who_Has_the_Most_Friends
with base as(select requester_id id from RequestAccepted
union all
select accepter_id id from RequestAccepted)
select id, count(*) num  from base group by 1 order by 2 desc limit 1

--5.Investments_in_2016
SELECT ROUND(SUM(tiv_2016),2) AS tiv_2016 
FROM Insurance 
WHERE tiv_2015 IN (
    SELECT tiv_2015 
    FROM Insurance 
    GROUP BY tiv_2015 
    HAVING COUNT(*) > 1
) AND (lat, lon) IN (
    SELECT lat, lon 
    FROM Insurance 
    GROUP BY lat, lon 
    HAVING COUNT(*) = 1
);

--6.Movie_Rating
WITH 
TheMostActiveUser AS (
    SELECT name
    FROM 
        Users
        NATURAL JOIN MovieRating
    GROUP BY user_id
    ORDER BY COUNT(*) DESC, name
    LIMIT 1
),
TheBestMovieFebruary AS (
    SELECT title
    FROM
        Movies
        NATURAL JOIN MovieRating
    WHERE created_at BETWEEN '2020-02-01' AND '2020-02-29'
    GROUP BY movie_id
    ORDER BY AVG(rating) DESC, title
    LIMIT 1
)

SELECT name AS results
FROM TheMostActiveUser
UNION ALL
SELECT title
FROM TheBestMovieFebruary

--7.Restaurant_Growth
select visited_on,
sum(sum(amount)) over (rows between 6 preceding and current row) as amount,
round(avg(sum(amount)) OVER (rows between 6 preceding and current row),2) AS average_amount
from Customer
group by visited_on
order by visited_on 
limit 999999 offset 6;
