SELECT 
    t_curr.user_id,
    MAX(TIMESTAMPDIFF(SECOND, t_curr.pay_date, t_next.pay_date)) / 3600.0 as max_interval_hours
FROM order_items t_curr
JOIN order_items t_next ON t_curr.user_id = t_next.user_id
    AND t_next.pay_date = (
        SELECT MIN(pay_date) 
        FROM order_items 
        WHERE user_id = t_curr.user_id 
          AND pay_date > t_curr.pay_date
          AND pay_date >= '2026-01-01' AND pay_date < '2026-02-01'
    )
WHERE t_curr.pay_date >= '2026-01-01' AND t_curr.pay_date < '2026-02-01'
GROUP BY t_curr.user_id
ORDER BY t_curr.user_id;
