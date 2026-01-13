
SELECT 
    user_id,
    MAX(TIMESTAMPDIFF(SECOND, pay_date, next_pay_date)) / 3600.0 as max_interval_hours
FROM (
    SELECT 
        user_id,
        pay_date,
        LEAD(pay_date) OVER (PARTITION BY user_id ORDER BY pay_date) as next_pay_date
    FROM order_items
    WHERE pay_date >= '2026-01-01' AND pay_date < '2026-02-01'
) t
GROUP BY user_id
ORDER BY user_id;
