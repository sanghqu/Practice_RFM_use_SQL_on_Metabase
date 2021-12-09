WITH rfm_metric AS(
                SELECT customer_id, (MAX(adjusted_created_at)::date) AS last_active,
                (CURRENT_DATE - MAX(adjusted_created_at)::date) AS frequency,
                COUNT(DISTINCT sales_id) AS recency,
                SUM( net_sales) AS monetary
                FROM sales_adjusted
                WHERE adjusted_created_at >= CURRENT_DATE - INTERVAL '1 YEAR'
                GROUP BY customer_id
                )
,rfm_percent_rank AS (
                SELECT * , PERCENT_RANK() OVER( ORDER BY frequency) AS frequency_percent_rank
                        ,PERCENT_RANK() OVER( ORDER BY monetary) AS monetary_percent_rank
                FROM rfm_metric
                            )
, rfm_rank AS (                
SELECT * 
        , CASE
        WHEN recency between 0 and 100 THEN 1
        WHEN recency between 100 and 200 THEN 2
        WHEN recency between 200 and 370 THEN 3
         END
         AS recency_rank
        ,CASE
        WHEN frequency_percent_rank between 0.8 and 1 THEN 3
        WHEN frequency_percent_rank between 0.5 and 0.8 THEN 2 
        WHEN frequency_percent_rank between 0 and 0.5 THEN 1 
        ELSE 0
        END
        AS frequencyrank 
        , CASE
        WHEN monetary_percent_rank between 0.8 and 1 THEN 3 
        WHEN monetary_percent_rank between 0.5 and 0.8 THEN 2 
        WHEN monetary_percent_rank  between 0 and 0.5 THEN 1 
        ELSE 0 
        END
        AS monetary_rank

FROM rfm_percent_rank
)
, rfm_rank_concat AS
(SELECT *, CONCAT(frequencyrank, recency_rank, monetary_rank) AS rfm_rank FROM rfm_rank)
SELECT * ,CASE
        WHEN recency_rank=1 THEN '1-churned'
        WHEN recency_rank=2 THEN '2-churing'
        WHEN recency_rank=3 THEN '3-active'
        END AS recency_segment
        ,CASE
        WHEN frequencyrank =1 THEN '1-leastfrequency'
        WHEN frequencyrank=2 THEN '2-frequnt'
        WHEN frequencyrank=3 THEN 'most frequency'
        END AS frequency_Segment
        ,CASE
        WHEN monetary_rank=1 THEN '1-least spend'
        WHEN monetary_rank=2 THEN '2-normal spend'
        WHEN monetary_rank=3 THEN '3-most spend'
        END AS monetary_segment
        ,CASE
        WHEN rfm_rank in('333','323') THEN 'VIP'
        WHEN rfm_rank in('313') THEN 'VIP, high purchasing'
        END AS rfm_segment
FROM rfm_rank_concat
