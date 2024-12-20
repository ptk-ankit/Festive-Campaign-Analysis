-- Provide a list of products with base price greater than 500 and that are feature in the promo type of "BOGOF" (Buy one get one free)

Select
	Distinct p.product_name,
    f.base_price
From
	fact_events f
Join
	dim_products p on f.product_code=p.product_code
Where
	f.base_price>500 and f.promo_type="BOGOF"
;

-- Provide a report outlining number of stores situated in each city

Select
	s.city,
    count(s.store_id) as total_stores
From
	dim_stores s
Group by
	s.city
Order by
	total_stores desc
;

-- Generate a report that that displays each campaign along with the total revenue generated before and after the campaign

 With SalesSummary as
	(Select 
		c.campaign_name,
		(f.base_price*f.`quantity_sold(before_promo)`) as "TotalRevenue(Before_Promotion)",
        Case
			When f.promo_type="BOGOF" Then f.base_price*f.`quantity_sold(after_promo)`
			When f.promo_type="50% OFF" Then f.base_price*0.5*f.`quantity_sold(after_promo)`
			When f.promo_type="25% OFF" Then f.base_price*0.75*f.`quantity_sold(after_promo)`
			When f.promo_type="33% OFF" Then f.base_price*0.67*f.`quantity_sold(after_promo)`
			When f.promo_type="500 Cashback" Then (f.base_price-500)*f.`quantity_sold(after_promo)`
			end as "TotalRevenue(After_Promotion)"
	From
		fact_events as f 
	Join
		dim_campaigns as c on c.campaign_id=f.campaign_id
	)
  
Select
	campaign_name,
    concat(round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2),"M") as "TotalRevenue(Before_Promotion)",
    concat(round(sum(`TotalRevenue(After_Promotion)`)/1000000,2),"M") as "TotalRevenue(After_Promotion)"
From
	SalesSummary 
Group by 
	campaign_name
Order by
	`TotalRevenue(After_Promotion)` desc
;
       
-- Produce a report thata calculate Incremental Sold Quantity (ISU%) for each category during the Diwali Campaign
-- Additionally, provide rankings for categories based on their ISU's

With ISU as 
	(Select 
		p.category,
        round((sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`)/sum(f.`quantity_sold(before_promo)`))*100,2) as `ISU%`
	From
		dim_products as p
	Join
		fact_events as f on f.product_code=p.product_code
	Join
		dim_campaigns as c on c.campaign_id=f.campaign_id
	Where
		c.campaign_name="Diwali"
	Group by 
		p.category
	)
    
Select 
	*,
    rank() over(order by `ISU%` desc) as category_rank
From
	ISU
;

-- Create a Report featuring TOP 5 Products, ranked by Incremental Revenue Percentage (IR%), across all categories

 With Summary as
	(Select 
		p.product_name,
        p.category,
		(f.base_price*f.`quantity_sold(before_promo)`) as "TotalRevenue(Before_Promotion)",
        Case
			When f.promo_type="BOGOF" Then f.base_price*f.`quantity_sold(after_promo)`
			When f.promo_type="50% OFF" Then f.base_price*0.5*f.`quantity_sold(after_promo)`
			When f.promo_type="25% OFF" Then f.base_price*0.75*f.`quantity_sold(after_promo)`
			When f.promo_type="33% OFF" Then f.base_price*0.67*f.`quantity_sold(after_promo)`
			When f.promo_type="500 Cashback" Then (f.base_price-500)*f.`quantity_sold(after_promo)`
			end as "TotalRevenue(After_Promotion)"
	From
		fact_events as f 
	Join
		dim_products as p on p.product_code=f.product_code
	)
,
IncreRev as
	(Select
		product_name,
		category,
		`TotalRevenue(Before_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as "IR"
	From
		Summary
	)
Select
	product_name,
    category,
    sum(IR) as IR,
    (sum(IR)/sum(`TotalRevenue(Before_Promotion)`))*100 as `IR%`,
    rank() over(order by (sum(IR)/sum(`TotalRevenue(Before_Promotion)`))*100 desc) as product_rank
From
	IncreRev
Group by
	product_name,category
Limit
	5
;
    
    
