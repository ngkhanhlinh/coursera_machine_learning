WITH transactions_2016 AS
(
	SELECT 	*
	FROM analytics_revenue.stripe_revenues
	WHERE date_trunc('month', '2016-01-01'::date) = date_trunc('month', transaction_date)
	AND amount_gross = 0
),

transactions_2017 AS
(
	SELECT *
	FROM analytics_revenue.stripe_revenues
	WHERE date_trunc('month', '2017-01-01'::date) = date_trunc('month', transaction_date)
),

combined_transactions AS 
(
	SELECT 
		a.user_id,
		a.transaction_date AS transaction_date_2016,
		a.valid_until AS valid_until_2016,
		a.amount_gross_after_refund AS paid_amount_2016,
		CASE WHEN 
			a.valid_until::date < getdate()::date 
		THEN
			CASE WHEN 
				b.transaction_date IS NOT NULL 
			THEN true
			ELSE false
			END
		ELSE 
			NULL
		END as did_renew_in_2017,
		CASE WHEN 
			b.transaction_date IS NOT NULL AND 
			a.valid_until::date < getdate()::date 
		THEN
			CASE WHEN 
				b.refunded_at IS NOT NULL AND 
				b.amount_gross_after_refund = 0 
			THEN
				true
			ELSE
				false
			END 
		ELSE 
			NULL
		END as renewal_got_fully_refunded,
		b.transaction_date AS transaction_date_2017,
		b.valid_until AS valid_until_date_2017,
		b.amount_gross AS amount_gross_2017
	FROM 
		transactions_2016 a
	LEFT JOIN
		transactions_2017 b
	ON a.user_id = b.user_id
)

SELECT *
FROM combined_transactions
ORDER BY transaction_date_2016 ASC