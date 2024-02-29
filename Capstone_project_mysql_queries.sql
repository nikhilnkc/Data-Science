-- ************  Capstone Project My SQL Query File  ***************
-- create database Capstone_projectdb;
-- use Capstone_projectdb;

-- Creating a table view which joins bank churn and customer info table to be reused thorugh out the project for simplifying the tasks 


drop view if exists bank_customer_info ;
create view  bank_customer_info as 
select bc.*,c.Surname,c.Age,c.GenderID,c.EstimatedSalary,c.GeographyID,c.BankDOJ from bank_churn bc 
join customerinfo c on bc.CustomerId=c.CustomerId;

-- Q1.	What is the distribution of account balances across different regions?

select g.GeographyLocation,Round(avg(balance),2) Avg_balance
from bank_customer_info c 
join geography g 
on c.geographyid=g.GeographyID
group by 1
order by avg_balance desc;


-- Q.2 	Identify the top 5 customers with the highest number of transactions in the last quarter of the year. (SQL)
--  since there is no specific information availabe on transactions as such , I have assumed no of products purchased 
-- as num of transaction with each purchase counted as distinct transaction and hence follows for further coding 
-- Also total spend is seen as no of product purchased. 

select year,surname,numofproducts as no_of_transactions from 
(
select  distinct year(bankDoj)as year, quarter(bankdoj) as Quarter, customerid,surname,numofproducts,
row_number() over (partition by year(bankDoj) order by numofproducts desc) as raank
from bank_customer_info
where quarter(bankdoj)=4
order by 1,2,5 desc,4
)t 
where raank<=5;

-- Q.3 Calculate the average number of products used by customers who have a credit card. (SQL)

select Round(avg(numofproducts),2) Avg_Num_products_with_credit_card from bank_churn
where HasCrCard=1;

-- Q5.Compare the average credit score of customers who have exited and those who remain. (SQL)

select Round((select avg(creditscore) from bank_churn where exited=1),2) average_credit_score_of_customers_exited,
round((select avg(creditscore) from bank_churn where exited=0),2) average_credit_score_of_customers_remain;

-- Q6.	Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

-- The below Query outputs the gender category with Higher Average salary along with no. of active account
select GenderCategory,Round(avg(EstimatedSalary),2) as Avg_salary,
count(case when c.isactivemember=1 then c.isactivemember end) as Active_acounts
from bank_customer_info c 
left join gender g on c.GenderID=g.genderid
group by GenderCategory
order by avg_salary desc 
limit 1;

-- The below Query ccompares avg salary of different category having active accounts 
select GenderCategory,Round(avg(EstimatedSalary),2) as Avg_salary,
count(case when c.isactivemember=1 then c.isactivemember end) as Active_acounts
from bank_customer_info c 
left join gender g on c.GenderID=g.genderid
group by GenderCategory;
-- Note: 
-- The Female category has higher avg salary(100601.54) than male category(99664.58)
-- but have lesser active accounts (2284) comapred to male category(2867) within the bank.

-- Q7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
-- As per given segments in ppt file the segmentations are done based on following available information
/*
Excellent: 800–850
Very Good: 740–799
Good: 670–739
Fair: 580–669
Poor: 300–579
*/
-- categoring into different segments and also displaying the Num of customers

select Segment,count(CustomerId) No_of_customers from (
select customerid,creditscore,
case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as Segment,exited
from bank_churn)t 
group by segment;

-- identify the segment with the highest exit rate

with segmented as (
select customerid,creditscore,
case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as segment,exited
from bank_churn)

select Segment,count(case when exited=1 then exited end) as Exit_Count from segmented
group by Segment
order by exit_count desc
limit 1;

-- Q8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)

select g.GeographyLocation,count(case when c.isactivemember=1 then c.isactivemember end) Active_Customers from bank_customer_info c 
join geography g 
on c.geographyid=g.GeographyID
where c.tenure>5
group by 1
limit 1;

-- Q.10. For customers who have exited, what is the most common number of products they have used?

select NumOfProducts, count(customerid) NumofCustomers from bank_churn
where exited=1
group by NumOfProducts
order by NumOfcustomers desc;


-- Q11.	Examine the trend of customer exits over time and identify any seasonal patterns (yearly or monthly).
-- Prepare the data through SQL and then visualize it.

select customerid,date_add(bankdoj, interval tenure year) exit_date from bank_customer_info 
where exited=1;

-- Q.12 Analyze the relationship between the number of products and the account balance for customers who have exited.
-- Visualitatin attached in objective answer word file
select numofproducts,round(avg(balance),2) Avg_balance from bank_customer_info
where exited=1
group by numofproducts ;

-- Q15.	Using SQL, write a query to find out the gender-wise average income of males and females
-- in each geography id. Also, rank the gender according to the average value. (SQL)

select *,rank() over (partition by GeographyLocation order by average_salary desc) as Ranking from 
(
select g.GeographyID,g.GeographyLocation,gg.GenderCategory,
Round(avg(estimatedsalary),2) as Average_Salary
from bank_customer_info c 
join geography g 
on c.geographyid=g.GeographyID
join gender gg 
on c.genderid=gg.genderid
group by 1,2,3
order by 1,2,3
)t ;

-- Q16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

select Age_bracket, avg(tenure) as Avg_tenure from
(select Age, tenure,
case  when age between 18 and 30 then '18-30'
	when age between 30 and 50 then '30-50'
    else '50+' 
    end as Age_bracket
from bank_customer_info
where exited=1)t 
group by 1
order by 1;


-- Q19.  Rank each bucket of credit score as per the number of customers who have churned the bank.

with segmented as (
select customerid,creditscore,
case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as segment,exited
from bank_churn)

select segment,no_of_customers , dense_rank() over (order by no_of_customers desc)as Ranking from 
(select segment, count(segment) no_of_customers from segmented 
where exited=1
group by 1)t ;

-- Q20. (A)  According to the age buckets find the number of customers who have a credit card. 

select Age_bracket,count(case when hascrcard=1 then hascrcard end) as Num_Customers_with_CrCard from (
select Age, tenure,hascrcard,
case  when age between 18 and 30 then '18-30'
	when age between 30 and 50 then '30-50'
    else '50+' 
    end as Age_bracket
from bank_customer_info
)t 
group by age_bracket;

-- -----------------------------------------------------------------------------------------------
-- Q.20 (B) Retrieve those buckets who have lesser than average number of credit cards per bucket.
-- -----------------------------------------------------------------------------------------------

with age_bucket as(
select Age_bracket,count(case when hascrcard=1 then hascrcard end) as Num_Customers_with_CrCard 
from(
select Age, tenure,hascrcard,
case  when age between 18 and 30 then '18-30'
	when age between 30 and 50 then '30-50'
    else '50+' 
    end as Age_bracket
from bank_customer_info
)t 
group by age_bracket
)
select Age_bracket,Num_Customers_with_CrCard from age_bucket
where Num_Customers_with_CrCard<( select avg(Num_Customers_with_CrCard) from age_bucket);

-- -----------------------------------------------------------------------------------------------------------------
-- Q21. Rank the Locations as per the number of people who have churned the bank and average balance of the learners.
-- -----------------------------------------------------------------------------------------------------------------


select *, dense_rank() over (order by churned_customers desc,Avg_balance desc) as Ranking from 
(
select g.GeographyLocation,count(case when c.exited=1 then c.exited end) Churned_Customers,Round(avg(c.balance),2) as Avg_Balance
from bank_customer_info c 
join geography g 
on c.geographyid=g.GeographyID
group by 1)t 
;

-- Subjective Q's 9
select customerid,
case  when age between 18 and 30 then '18-30'
	when age between 30 and 50 then '30-50'
    else '50+' 
    end as Age_bracket,
    case when creditscore between 300 and 570 then 'Poor'
	when creditscore between 580 and 669 then 'Fair'
    when creditscore between 670 and 739 then 'Good'
    when creditscore between 740 and 799 then 'Very Good'
	else 'Excellent' 
    end as CreditScore_bracket
from bank_customer_info;
