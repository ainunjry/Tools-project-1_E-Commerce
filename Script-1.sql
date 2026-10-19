show table;
# Create A View TABLE, prior to split dataset due to uploaded size limitation
CREATE VIEW all_ext AS
    SELECT * FROM ext_1 
    UNION ALL
    SELECT * FROM ext_2
    UNION ALL
    SELECT * FROM ext_3
    UNION ALL
    SELECT * FROM ext_4;
  
#--------------------------------------------------------------------------------------------  
# Query for Business questions No. 1 & 4:
# 1. Which product category has the highest number of purchases?
# 4. Which product category has the highest return and churn rates?

WITH CTE1 AS(           
SELECT          
Product_Category, Transaction_ID,       
COUNT(DISTINCT Transaction_ID) AS Total_Transactions,           
ROUND(AVG(Quantity),2) AS Quantity_On_Average,          
MAX(Product_Price) AS Maximum_Price,            
COUNT(DISTINCT CASE WHEN Returns = 10 THEN Transaction_ID END) AS The_Return,           
COUNT(DISTINCT CASE WHEN Returns = 0 THEN Transaction_ID END) AS Cancel,                
COUNT(DISTINCT CASE WHEN Churn = 1 THEN Transaction_ID END) AS Churn,           
COUNT(DISTINCT CASE WHEN Churn = 0 THEN Transaction_ID END) AS Retain           
FROM all_ext            
GROUP BY Product_Category               
),              
Percentage AS(          
SELECT          
Product_Category, Transaction_ID, Total_Transactions,           
Quantity_On_Average,            
Maximum_Price,          
ROUND(100 * The_Return / SUM(Total_Transactions) OVER(),2) AS Return_rate,              
ROUND(100 * Cancel / SUM(Total_Transactions) OVER(),2) AS Cancel_Return_rate,           
ROUND(100 * Churn / SUM(Total_Transactions) OVER(),2) AS Churn_rate,            
ROUND(100 * Churn / SUM(Total_Transactions) OVER(),2) AS Retain_rate            
FROM CTE1               
)               
SELECT          
Product_Category, Total_Transactions,
Quantity_On_Average,            
Maximum_Price,          
Return_rate,            
Cancel_Return_rate,             
Churn_rate,             
Retain_rate             
FROM Percentage         
GROUP BY Product_Category               
ORDER BY Total_Transactions DESC;

#-----------------------------------------------------------------------------------------------------------
    
# Query for Business questions No.2:
# Are age and gender related to purchase volume and frequency?

WITH CTE1 AS(                                   
    SELECT                                      
        Returns, Churn, Transaction_ID, Customer_ID,    
        CASE
                        WHEN Age >= 18 AND Age <= 28 THEN '18 - 28 Years'
                        WHEN Age >= 29 AND Age <= 39 THEN '29 - 39 Years'
                        WHEN Age >= 40 AND Age <= 50 THEN '40 - 50 Years'
                        WHEN Age >= 51 AND Age <= 60 THEN '51 - 60 Years'
                        WHEN Age >= 61 AND Age <= 70 THEN '61 - 70 Years'       
                        WHEN Age >= 71 THEN 'Above 70 Years'
        ELSE 'Unknown'
        END AS Age_Group,
                COUNT(DISTINCT Transaction_ID)-2 AS Of_Transactions,
        COUNT(DISTINCT CASE WHEN Returns = 10 THEN Transaction_ID END) AS Of_Returns_Trans,     
        COUNT(DISTINCT CASE WHEN Churn = 1 THEN Transaction_ID END) AS Of_Churn_Trans,
        COUNT(DISTINCT CASE WHEN Returns = 10 AND Churn = 1 THEN Transaction_ID END) AS Of_Trans_Returns_Churn,
        COUNT(DISTINCT Customer_ID)-1 AS Of_Customers,
        COUNT(DISTINCT CASE WHEN Returns = 10 THEN Customer_ID END) AS Of_Returns_Cust,
        COUNT(DISTINCT CASE WHEN Churn = 1 THEN Customer_ID END) AS Of_Churn_Cust,              
        COUNT(DISTINCT CASE WHEN Returns = 10 AND Churn = 1 THEN Customer_ID END) AS Of_Cust_Returns_Churn              
FROM all_ext                                    
GROUP BY Age_Group                                      
),                                      
CTE2 AS(                                        
    SELECT                                              
    Returns,Churn,Transaction_ID,Customer_ID,Age_Group,                                 
    Of_Transactions,Of_Returns_Trans,Of_Churn_Trans, Of_Trans_Returns_Churn,                                    
    ROUND(Of_Trans_Returns_Churn/SUM(Of_Transactions)OVER() *100,2) AS Percentage_Trans_Returns_Churn,                                  
    Of_Customers, Of_Returns_Cust,Of_Churn_Cust,Of_Cust_Returns_Churn,                                  
    ROUND(Of_Cust_Returns_Churn/SUM(Of_Customers) OVER() *100,2) AS Percentage_Cust_Returns_Churn                                       
FROM CTE1                                       
)                                       
SELECT Age_Group,                                       
       Of_Transactions,
       Of_Returns_Trans,        
       Of_Churn_Trans
       Percentage_Trans_Returns_Churn,  
       Of_Customers,            
       Of_Returns_Cust,
       Of_Churn_Cust,
       Percentage_Cust_Returns_Churn                    
FROM CTE2                                       
GROUP BY Age_Group;

#------------------------------------------------------------------------------------------------------------

# Business question 7:
# What is the correlation between number of customers, returns, and churn?

WITH CustomerSummary AS (
   SELECT 
       Customer_ID,
       COUNT(CASE WHEN Returns = 10 THEN 1 END) AS total_return,
       MAX(CASE WHEN Churn = 1 THEN 1 ELSE 0 END) AS is_churn
   FROM all_ext
   GROUP BY Customer_ID
)
SELECT 
   COUNT(CASE WHEN total_return = 2 AND is_churn = 1 THEN 1 END) AS customer_2x_return_churn,
   COUNT(CASE WHEN total_return = 3 AND is_churn = 1 THEN 1 END) AS customer_3x_return_churn,
   COUNT(CASE WHEN total_return > 3 AND is_churn = 1 THEN 1 END) AS customer_more_than_3x_return_churn
FROM CustomerSummary;

#-----------------------------------------------------------------------------------------------------------

# Business question 8:
# Does purchase frequency by customer age differ between churned - retained customers and customers who return product and those who don't ?

WITH CTE1 AS(                                   
            SELECT                                      
            Returns, Churn, Transaction_ID, Customer_ID,                
                CASE                    
                        WHEN Age >= 18 AND Age <= 28 THEN '18 - 28 Years'               
                        WHEN Age >= 29 AND Age <= 39 THEN '29 - 39 Years'               
                        WHEN Age >= 40 AND Age <= 50 THEN '40 - 50 Years'               
                        WHEN Age >= 51 AND Age <= 60 THEN '51 - 60 Years'               
                        WHEN Age >= 61 AND Age <= 70 THEN '61 - 70 Years'               
                        WHEN Age >= 71 THEN 'Above 70 Years'            
                        ELSE 'Unknown'          
                END AS Age_Group,                       
            COUNT(DISTINCT Transaction_ID)-2 AS Of_Transactions,                                
            COUNT(DISTINCT CASE WHEN Returns = 10 THEN Transaction_ID END) AS Of_Returns,                       
            COUNT(DISTINCT CASE WHEN Returns = 0 AND Returns <> '' THEN Transaction_ID END) AS Of_Cancel_Returns,                       
            COUNT(DISTINCT CASE WHEN Churn = 1 THEN Transaction_ID END) AS Of_Churn,                    
            COUNT(DISTINCT CASE WHEN Churn = 0 THEN Transaction_ID END) AS Of_Retained,                                 
            COUNT(DISTINCT CASE WHEN Returns = 10 AND Churn = 1 THEN Transaction_ID END) AS Of_Returns_Churn                                    
                                        
FROM all_ext                    
GROUP BY Age_Group                      
),                      
CTE2 AS(                
    SELECT                      
    Returns,Churn,Transaction_ID,Age_Group,                                     
    Of_Transactions,Of_Returns,                 
    ROUND(Of_Returns / SUM(Of_Transactions) OVER() *100,2) AS Of_Returns_rate,                  
    Of_Cancel_Returns,                                  
    ROUND(Of_Cancel_Returns / SUM(Of_Transactions) OVER() *100,2) AS Cancel_Return_rate,                                
    Of_Churn,   
    ROUND(Of_Churn / SUM(Of_Transactions) OVER() *100,2) AS Of_Churn_rate,                                      
    Of_Retained,                        
    ROUND(Of_Retained / SUM(Of_Transactions) OVER() *100,2) AS Retained_rate,                                   
    Of_Returns_Churn,   
    ROUND(Of_Returns_Churn/SUM(Of_Transactions)OVER() *100,2) AS Returns_Churn_rate                                     
FROM CTE1                               
)                               
SELECT  
        Age_Group,                                      
        Of_Transactions,                        
        Of_Returns,                             
        Of_Returns_rate,                                
        Of_Cancel_Returns,                              
        Cancel_Return_rate,                             
        Of_Churn,       
        Of_Churn_rate,          
        Of_Retained,                    
        Retained_rate,          
        Of_Returns_Churn,                       
        Returns_Churn_rate                      
FROM CTE2
GROUP BY Age_Group;

# -----------------------------------------------------------------------------------------------------

# Business question 9:
# How many at-risk customers who had last 45-60 day-transaction to re-engage, grouped by their favourite product?
# CTE combining with Subsquery

WITH Max_p AS(  
SELECT  
    Customer_ID, Customer_name, Purchase_date,  
    DATE_ADD(MAX(Purchase_date), INTERVAL 1 DAY) AS A_day_after_last_PD,        
    Product_Category,   
    COUNT(Transaction_ID) AS Total_transactions 
        
FROM all_ext    
WHERE YEAR(Purchase_date) = 2023 AND MONTH(Purchase_date) >= 7  
GROUP BY Product_Category       
),      
INTV AS(        
SELECT  
    Customer_ID, Customer_name, Purchase_date,  
    A_day_after_last_PD,        
    DATEDIFF('2023-09-13', A_day_after_last_PD) = 45 AS Int_45_days,    
    DATEDIFF('2023-09-13', A_day_after_last_PD) = 60 AS Int_60_days,    
    Product_Category,   
    Total_transactions  
FROM Max_p      
)       
        
SELECT  
    Product_Category,Total_transactions,        
    COUNT(DISTINCT CASE WHEN Int_45_days THEN Customer_ID END) AS of_Customers_last_45_days,    
    COUNT(DISTINCT CASE WHEN Int_60_days THEN Customer_ID END) AS of_Customers_last_60_days     
FROM INTV       
GROUP BY Product_Category       
HAVING Total_transactions < (SELECT AVG(Total_transactions) FROM Max_p) 
ORDER BY of_Customers_last_60_days DESC;
