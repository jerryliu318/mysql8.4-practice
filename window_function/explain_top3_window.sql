EXPLAIN ANALYZE SELECT
    category,
    user_id,
    total_spent,
    ranking
FROM (
    SELECT 
        category,
        user_id,
        SUM(price) as total_spent,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY SUM(price) DESC) as ranking
    FROM 
        order_items
    GROUP BY 
        category, user_id
) as ranked_sales
WHERE 
    ranking <= 3
ORDER BY 
    category, ranking \G
