EXPLAIN ANALYZE SELECT
    t1.category,
    t1.user_id,
    t1.total_spent
FROM 
    (SELECT category, user_id, SUM(price) as total_spent
     FROM order_items
     GROUP BY category, user_id) AS t1
WHERE 
    (
        SELECT COUNT(*)
        FROM 
            (SELECT category, user_id, SUM(price) as total_spent
             FROM order_items
             GROUP BY category, user_id) AS t2
        WHERE 
            t2.category = t1.category 
            AND t2.total_spent > t1.total_spent
    ) < 3
ORDER BY 
    t1.category, 
    t1.total_spent DESC \G
