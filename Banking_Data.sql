# Practice

use bank_data;
select * from  transactions;
select * from branches;
select * from accounts;
select * from customers;
select * from employees;

#Create Age column in customers table

alter table customers
add age int;

update customers
set age =  TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE());

set sql_safe_updates = 0; 
set sql_safe_updates = 1;


#Calculate Amount Region_wise

select b.branch_location ,round(sum(t.amount)) as total_amount from accounts a 
join branches b on b.branch_id = a.branch_id
join transactions t on t.account_number = a.account_number
group by b.branch_location;

# calculate time_wise transactions
select 
	case 
		when hour(transaction_date) >= 0 and hour(transaction_date) <=6 then "Night"
        when hour(transaction_date) >= 7 and hour(transaction_date) <= 12 then "morning"
		when hour(transaction_date)>=13 and hour(transaction_date) <= 18 then "afternoon"
        else "evening"
        end as Time_Category,
count(transaction_id) from transactions
group by Time_Category;

# High_Value Flag Amount

SELECT 
    count(transaction_id),sum(amount),
    CASE 
        WHEN amount > 0 AND amount <= 5000 THEN "Low"
        ELSE "High"
    END AS High_Value_Flag
FROM transactions
group by High_Value_Flag;

# Top 10 branches

select sum(a.balance),b.branch_name,year(t.transaction_date)from accounts a 
  join branches b on a.branch_id = b.branch_id
  join transactions t on t.account_number = a.account_number
  group by b.branch_name,year(t.transaction_date)
  order by b.branch_name desc 
  limit 10;
  
  
#Transactions done by employees

 select b.branch_location,b.branch_id,e.employee_id,e.first_name,sum(t.amount),count(t.transaction_id)from accounts a
  join branches b on a.branch_id = b.branch_id
  join employees e on e.branch_id = a.branch_id
  join transactions t on t.account_number = a.account_number
  group by e.employee_id,b.branch_location,e.first_name,b.branch_id
  order by e.employee_id;
  
#  Summarize the total transaction amount per account per month.

SELECT account_number, year(transaction_date) as year , month(transaction_date) as month,sum(amount) as total_amt
from transactions t 
group by account_number, year(transaction_date), month(transaction_date)
order by account_number,year,month;


# Find the name of the customer who  has deposited the highest amount.

SELECT  c.full_name, t.amount 
from customers c 
inner join accounts a on c.customer_id=a.customer_id 
inner join transactions t on t.account_number=a.account_number
where t.transaction_type="Deposit"
order by t.amount desc
limit 1;

# Identify any accounts that have made more than two transactions in a single day, which could indicate fraudulent activity. 

SELECT a.account_number as fraud_accounts,count(t.transaction_id) as no_of_transactions ,day(t.transaction_date) as single_day
from accounts a inner join transactions t 
using(account_number)
group by fraud_accounts,single_day
having no_of_transactions>2;

# Calculate the average number of transactions per customer per account per month over the last year.

WITH MonthlyTransactions AS (
 SELECT a.customer_id, a.account_number, YEAR(t.transaction_date) AS transaction_year,
 MONTH(t.transaction_date) AS transaction_month,
 COUNT(t.transaction_id) AS num_transactions
 FROM accounts a
 INNER JOIN transactions t ON a.account_number = t.account_number
 WHERE
 t.transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
 GROUP BY a.customer_id, a.account_number,
 YEAR(t.transaction_date), MONTH(t.transaction_date)
)
SELECT customer_id, account_number, ROUND(AVG(num_transactions), 2) AS avg_month_trans
FROM MonthlyTransactions
GROUP BY customer_id, account_number
ORDER BY avg_month_trans DESC;
 
 
# Calculate the total transaction amount performed by each age group.

Create View age_group_transactions as
select count(t.transaction_id) as count,
  CASE 
    WHEN age < 18 THEN 'Under 18'
    WHEN age < 25 THEN '18 - 24'
    WHEN age < 35 THEN '25 - 34'
    WHEN age < 45 THEN '35 - 44'
    WHEN age < 55 THEN '45 - 54'
    WHEN age < 65 THEN '55 - 64'
    WHEN age < 75 THEN '65 - 74'
    ELSE '75 and above'
  END AS age_group,
sum(t.amount) as amount from customers c inner join accounts a on c.customer_id=a.customer_id 
inner join transactions t on t.account_number=a.account_number
group by age_group;

select * from age_group_transactions;

# Find the branch with the highest average account balance.

SELECT branch_id, avg(balance) as avg_bal
from accounts 
group by branch_id
order by avg_bal desc
limit 1;

# Calculate the average balance per customer at the end of each month in last year.

SELECT a.customer_id,year(t.transaction_date) as year,month(t.transaction_date) as month ,round(avg(a.balance),2)as avg_balance 
from accounts a join transactions t 
using(account_number) 
where 
t.transaction_date>=date_sub(current_date,interval 1 year)
group by customer_id,year,month
order by year,month;

#  List all inactive accounts (no transactions in the last year).

SELECT a.account_number, c.customer_id, c.full_name
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM transactions t
    WHERE t.account_number = a.account_number
      AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
)
order by customer_id asc;

# Find the most common transaction type per branch.

SELECT b.branch_id, t.transaction_type, COUNT(*) AS transaction_count
FROM transactions t
JOIN accounts a ON t.account_number = a.account_number
JOIN branches b ON a.branch_id = b.branch_id
GROUP BY b.branch_id, t.transaction_type
ORDER BY b.branch_id, transaction_count DESC;



#  Get the number of transactions per branch per month.

SELECT 
    b.branch_id, 
    YEAR(t.transaction_date) AS year, 
    MONTH(t.transaction_date) AS month,
    COUNT(t.transaction_id) AS total_transactions_in_month
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_number = t.account_number
GROUP BY b.branch_id, year, month;


#  Find the running total of transactions per account.

SELECT account_number, transaction_date, amount,
       SUM(amount) OVER (PARTITION BY account_number ORDER BY transaction_date) AS running_total
FROM transactions;

#  Find the previous transaction amount for each transaction.

SELECT account_number, transaction_id, transaction_date, amount,
       LAG(amount, 1, 0) OVER (PARTITION BY account_number ORDER BY transaction_date) AS previous_transaction
FROM transactions;

#  Find customers whose account balance is below the average balance of their branch.

SELECT c.customer_id, c.full_name, a.account_number, a.balance, branch_avg.avg_balance
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
JOIN (
    SELECT branch_id, AVG(balance) AS avg_balance
    FROM accounts
    GROUP BY branch_id
) branch_avg ON a.branch_id = branch_avg.branch_id
WHERE a.balance < branch_avg.avg_balance;

#  Calculate the moving average of transactions per account over the last 3 transactions.

SELECT account_number, transaction_id, transaction_date, amount,
       AVG(amount) OVER (PARTITION BY account_number ORDER BY transaction_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM transactions;

#  Find the difference between each transaction amount and the account’s average transaction amount.

SELECT account_number, transaction_id, transaction_date, amount,
       amount - AVG(amount) OVER (PARTITION BY account_number) AS difference_from_avg
FROM transactions;

#   Find the first and last transaction date for each account using window functions.

SELECT account_number, transaction_id, transaction_date, amount,
       FIRST_VALUE(transaction_date) OVER (PARTITION BY account_number ORDER BY transaction_date) AS first_transaction,
       LAST_VALUE(transaction_date) OVER (PARTITION BY account_number ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_transaction
FROM transactions;

#  Find which branch has the highest total deposit amount.

SELECT b.branch_id, b.branch_name, SUM(t.amount) AS total_deposits
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_number = t.account_number
WHERE t.transaction_type = 'deposit'
GROUP BY b.branch_id, b.branch_name
ORDER BY total_deposits DESC
LIMIT 1;

# Find customers who have made the highest number of transactions.

SELECT c.customer_id, c.full_name, COUNT(t.transaction_id) AS total_transactions
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_number = t.account_number
GROUP BY c.customer_id, c.full_name
ORDER BY total_transactions DESC
LIMIT 10;

# Stored Procedure

# Get Inactive Customers (1 Year No Transaction)

DELIMITER //
CREATE PROCEDURE GetInactiveCustomers()
BEGIN
    SELECT a.account_number, c.customer_id, c.full_name
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM transactions t
    WHERE t.account_number = a.account_number
      AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
)
order by customer_id asc;
END //
DELIMITER ;

call GetInactiveCustomers();

drop procedure GetInactiveCustomers;

# Monthly Transaction Summary

DELIMITER //
CREATE PROCEDURE MonthlyTransactionSummary()
BEGIN
    SELECT account_number, YEAR(transaction_date) AS year, 
           MONTH(transaction_date) AS month, SUM(amount) AS total_amt
    FROM transactions 
    GROUP BY account_number, year, month;
END //
DELIMITER ;

call MonthlyTransactionSummary();













