use bank_data;

select * from branch;
select * from customers;
select * from accounts;
select * from employees;
select * from transactions;

# 1.Write a query to list all customers who haven't made any transactions in the last year. How can we make them active again? 

select c.customer_id,c.first_name,c.last_name from customers c
join accounts a on c.customer_id = a.customer_id
left join transactions t on a.account_number = t.account_number 
where t.transaction_id is null or 
t.transaction_date < date_sub(curdate(),interval 1 year);

# 2. Summarize the total transaction amount per account per month.

SELECT account_number, year(transaction_date) as year , month(transaction_date) as month,sum(amount) as total_amt
from transactions t 
group by account_number, year(transaction_date), month(transaction_date)
order by account_number,year,month;

# 3. Rank branches based on the total amount of deposits made in the last quarter

SELECT a.branch_id,sum(t.amount) , dense_rank() 
over(order by sum(t.amount) desc) as branch_rank
from accounts a inner join transactions t 
using(account_number)
where t.transaction_type="Deposit" and 
t.transaction_date>=date_sub(current_date(),interval 3 
month) group by a.branch_id
order by branch_rank;

#4. Find the name of the customer who  has deposited the highest amount.

SELECT concat(c.first_name," ",c.last_name) as full_name, t.amount 
from customers c 
inner join accounts a on c.customer_id=a.customer_id 
inner join transactions t on t.account_number=a.account_number
where t.transaction_type="Deposit"
order by t.amount desc
limit 1;

# 5. Identify any accounts that have made more than two transactions in a single day, which could indicate fraudulent activity. 

SELECT a.account_number as fraud_accounts,count(t.transaction_id) as no_of_transactions ,day(t.transaction_date) as single_day
from accounts a inner join transactions t 
using(account_number)
group by fraud_accounts,single_day
having no_of_transactions>2;

# 6.Calculate the average number of transactions per customer per account per month over the last year.

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
 
 # 7. Write a query to find the daily transaction volume (total amount of all transactions) for the past month.

SELECT date(transaction_date) as transaction_day,round(sum(amount),3) as trans_volume
from transactions 
where 
transaction_date>=date_sub(current_date(),interval 1 month)
group by transaction_day
order by transaction_day;

# 8.Calculate the total transaction amount performed by each age group in the past year. (Age groups: 0-17, 18-30, 31-60, 60+)

SELECT 
case When floor((datediff(current_date(),c.date_of_birth)/365)) between 0 and 17 then "0-17"
	When floor((datediff(current_date(),c.date_of_birth)/365)) between 18 and 30 then "18-30"
	When floor((datediff(current_date(),c.date_of_birth)/365)) between 31 and 60 then "31-60"
else "60+" 
end as age_group,
sum(t.amount) as total_trans_amt from customers c inner join accounts a on c.customer_id=a.customer_id 
inner join transactions t on t.account_number=a.account_number
where t.transaction_date>=date_sub(current_date(),interval 1 year)
group by age_group;

#9.Find the branch with the highest average account balance.

SELECT branch_id, avg(balance) as avg_bal
from accounts 
group by branch_id
order by avg_bal desc
limit 1;

# 10. Calculate the average balance per customer at the end of each month in last year.

SELECT a.customer_id,year(t.transaction_date) as year,month(t.transaction_date) as month ,round(avg(a.balance),2)as avg_balance 
from accounts a join transactions t 
using(account_number) 
where 
t.transaction_date>=date_sub(current_date,interval 1 year)
group by customer_id,year,month
order by year,month;

# 11. List all inactive accounts (no transactions in the last year).

SELECT a.account_number, c.customer_id, c.first_name, c.last_name
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON a.account_number = t.account_number
WHERE t.transaction_id IS NULL OR t.transaction_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);

# 12. Find the most common transaction type per branch.

SELECT b.branch_id, t.transaction_type, COUNT(*) AS transaction_count
FROM transactions t
JOIN accounts a ON t.account_number = a.account_number
JOIN branch b ON a.branch_id = b.branch_id
GROUP BY b.branch_id, t.transaction_type
ORDER BY b.branch_id, transaction_count DESC;

# 13. Find accounts that have only withdrawals and no deposits.

SELECT account_number
FROM transactions
GROUP BY account_number
HAVING SUM(CASE WHEN transaction_type = 'deposit' THEN 1 ELSE 0 END) = 0;

# 14.  Get the average number of transactions per branch per month.

SELECT b.branch_id, YEAR(t.transaction_date) AS year, MONTH(t.transaction_date) AS month,
       COUNT(t.transaction_id) / COUNT(DISTINCT t.account_number) AS avg_transactions
FROM branch b
JOIN accounts a ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_number = t.account_number
GROUP BY b.branch_id, year, month;

# 15. Find the running total of transactions per account.

SELECT account_number, transaction_date, amount,
       SUM(amount) OVER (PARTITION BY account_number ORDER BY transaction_date) AS running_total
FROM transactions;

# 16. Find the previous transaction amount for each transaction.

SELECT account_number, transaction_id, transaction_date, amount,
       LAG(amount, 1, 0) OVER (PARTITION BY account_number ORDER BY transaction_date) AS previous_transaction
FROM transactions;

# 17. Find customers whose account balance is below the average balance of their branch.

SELECT c.customer_id, c.first_name, c.last_name, a.account_number, a.balance, branch_avg.avg_balance
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
JOIN (
    SELECT branch_id, AVG(balance) AS avg_balance
    FROM accounts
    GROUP BY branch_id
) branch_avg ON a.branch_id = branch_avg.branch_id
WHERE a.balance < branch_avg.avg_balance;

# 18. Calculate the moving average of transactions per account over the last 3 transactions.

SELECT account_number, transaction_id, transaction_date, amount,
       AVG(amount) OVER (PARTITION BY account_number ORDER BY transaction_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg
FROM transactions;

# 19. Find the difference between each transaction amount and the account’s average transaction amount.

SELECT account_number, transaction_id, transaction_date, amount,
       amount - AVG(amount) OVER (PARTITION BY account_number) AS difference_from_avg
FROM transactions;

# 20.  Find the first and last transaction date for each account using window functions.

SELECT account_number, transaction_id, transaction_date, amount,
       FIRST_VALUE(transaction_date) OVER (PARTITION BY account_number ORDER BY transaction_date) AS first_transaction,
       LAST_VALUE(transaction_date) OVER (PARTITION BY account_number ORDER BY transaction_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_transaction
FROM transactions;

# 21. Find which branch has the highest total deposit amount.

SELECT b.branch_id, b.branch_name, SUM(t.amount) AS total_deposits
FROM branch b
JOIN accounts a ON b.branch_id = a.branch_id
JOIN transactions t ON a.account_number = t.account_number
WHERE t.transaction_type = 'deposit'
GROUP BY b.branch_id, b.branch_name
ORDER BY total_deposits DESC
LIMIT 1;

# 22. Find customers who have made the highest number of transactions.

SELECT c.customer_id, c.first_name, c.last_name, COUNT(t.transaction_id) AS total_transactions
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN transactions t ON a.account_number = t.account_number
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_transactions DESC
LIMIT 10;

# Stored Procedure

# Get Inactive Customers (1 Year No Transaction)

DELIMITER //
CREATE PROCEDURE GetInactiveCustomers()
BEGIN
    SELECT c.customer_id, c.first_name, c.last_name 
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN transactions t ON a.account_number = t.account_number 
    WHERE t.transaction_id IS NULL 
      OR t.transaction_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);
END //
DELIMITER ;

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

# Transactions Per Customer Calculation

CREATE TABLE customer_transactions (
    customer_id INT PRIMARY KEY,
    total_transactions INT
);

DELIMITER //
CREATE PROCEDURE CalculateCustomerTransactions()
BEGIN
    INSERT INTO customer_transactions (customer_id, total_transactions)
    SELECT a.customer_id, COUNT(t.transaction_id) AS total_transactions
    FROM transactions t
    JOIN accounts a ON t.account_number = a.account_number
    GROUP BY a.customer_id
    ON DUPLICATE KEY UPDATE total_transactions = VALUES(total_transactions);
END //
DELIMITER ;













