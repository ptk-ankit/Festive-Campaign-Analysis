-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- Other Recommended Insights -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Store Performance Analysis
-- Which are the Top 10 Stores in terms of Incremental Revenue (IR) generated from the promotions

 With Summary as
	(Select 
		s.city,
        s.store_id,
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
		dim_stores as s on s.store_id=f.store_id
	)
,
IncreRev as
	(Select
		 city,
         store_id,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as "IR"
	From
		Summary
	)
	
Select
	city,
    store_id,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as "IR in Millions"
From
	IncreRev
Group by
	city,store_id
Order by
	`IR in Millions` desc
Limit
	10
;

-- Which are the bottom 10 stores when it comes to the Incremental Sold Units (ISU) during the promotional Period

With ISU as 
	(Select 
		s.city,
        s.store_id,
        sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) as `ISU`
	From
		dim_stores as s
	Join
		fact_events as f on f.store_id=s.store_id
	Group by 
		s.city,s.store_id
	)
    
Select 
	*,
    rank() over(order by `ISU` desc ) as store_rank
From
	ISU
Order by
	store_rank desc
Limit
	10
;

-- How Does the Performance of stores vary by cities

With Summary as
	(Select 
		s.city,
        s.store_id,
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
		dim_stores as s on s.store_id=f.store_id
	)
,
IncreRev as
	(Select
		 city,
         store_id,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
	
Select 
	city,
    store_id,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as `IR in Millions`,
    rank() over(partition by city order by round(sum(`IR`)/1000000,2) desc) as store_rank
From
	IncreRev
Group by
	city,store_id
;

-- Product and Category Analysis
-- Which Product Categories saw the most significant lift is sales from the promotion (by Incremental Revenue)

  With Summary as
	(Select 
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
		 category,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as "IR"
	From
		Summary
	)
	
Select
	category,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as "IR in Millions",
    (sum(IR)/sum(`TotalRevenue(Before_Promotion)`))*100 as `IR%`
From
	IncreRev
Group by
	category
Order by
	`IR in Millions` desc
;

-- Which Product Categories saw the most significant lift is sales from the promotion (by Incremental Sold Quantity)

Select 
		p.category,
        sum(f.`quantity_sold(before_promo)`) as `Qty sold before promo`,
        sum(f.`quantity_sold(after_promo)`) as `Qty sold after promo`,
        sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) as `ISU`
	From
		dim_products as p
	Join
		fact_events as f on f.product_code=p.product_code
	Group by 
		p.category
	Order by
		`ISU` desc
	;
		
-- Are there specific Products that respond exceptionally well or poorly to promotions

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
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
,
Exception as
	(Select
		product_name,
		category,
		round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
		round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
		round(sum(`IR`)/1000000,2) as `IR in Millions`,
		(sum(`IR`)/sum(`TotalRevenue(Before_Promotion)`))*100 as `IR%`,
		rank() over(order by (sum(IR)/sum(`TotalRevenue(Before_Promotion)`))*100 desc) as product_top_rank,
		rank() over(order by (sum(IR)/sum(`TotalRevenue(Before_Promotion)`))*100 asc) as product_bottom_rank
	From
		IncreRev
	Group by
		product_name,category
	)
Select
	*
From
	Exception
Where
	product_top_rank<=3
    or
    product_bottom_rank<=3
Order by
	`IR%` desc
;

-- What is the Co-relation between product category and promotion type effectiveness (based on ISU)

Select 
		p.category,
        f.promo_type,
        sum(f.`quantity_sold(before_promo)`) as `Qty sold before promo`,
        sum(f.`quantity_sold(after_promo)`) as `Qty sold after promo`,
        sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) as `ISU`,
        rank() over(partition by p.category order by sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) desc) as cat_promo_rank
	From
		dim_products as p
	Join
		fact_events as f on f.product_code=p.product_code
	Group by 
		p.category,f.promo_type
	Order by
    p.category
	;
    
    -- What is the Co-relation between product category and promotion type effectiveness (based on IR)
    
    With Summary as
	(Select 
		p.category,
        f.promo_type,
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
		dim_products as p on f.product_code=p.product_code
	)
,
IncreRev as
	(Select
		 category,
         promo_type,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
	
Select 
	category,
    promo_type,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as `IR in Millions`,
    rank() over(partition by category order by round(sum(`IR`)/1000000,2) desc) as cat_promo_rank
From
	IncreRev
Group by
	category,promo_type
;

-- Promotion Type Analysis
-- What are the top 2 promotion types that resulted in Highest Incremental Revenue

  With Summary as
	(Select 
        f.promo_type,
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
		dim_products as p on f.product_code=p.product_code
	)
,
IncreRev as
	(Select
         promo_type,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
	
Select 
    promo_type,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as `IR in Millions`,
    rank() over(order by round(sum(`IR`)/1000000,2) desc) as promo_rank
From
	IncreRev
Group by
	promo_type
Limit
	2
;

-- What are the bottom 2 promotion types in terms of their impact on Incremental Sold Units 

Select 
        f.promo_type,
        sum(f.`quantity_sold(before_promo)`) as `Qty sold before promo`,
        sum(f.`quantity_sold(after_promo)`) as `Qty sold after promo`,
        sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) as `ISU`,
        rank() over(order by sum(f.`quantity_sold(after_promo)`- f.`quantity_sold(before_promo)`) desc) as cat_promo_rank
	From
		dim_products as p
	Join
		fact_events as f on f.product_code=p.product_code
	Group by 
		f.promo_type
	Order by 
		`ISU` 
	Limit 
		2
;

-- Is there a significant difference between the performance of discount based promotions versun BOGOF or Cashback Promotion

With Summary as
	(Select 
        f.promo_type,
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
		dim_products as p on f.product_code=p.product_code
	)
,
IncreRev as
	(Select
         promo_type,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
	
Select 
    promo_type,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as `IR in Millions`,
    rank() over(order by round(sum(`IR`)/1000000,2) desc) as promo_rank
From
	IncreRev
Group by
	promo_type
;

-- Which Promotions strike the best balance between ISU and maintaining heakthy margins

With Summary as
	(Select 
        f.promo_type,
        f.`quantity_sold(before_promo)`,
        f.`quantity_sold(after_promo)`,
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
		dim_products as p on f.product_code=p.product_code
	)
,
IncreRev as
	(Select
		promo_type,
		`quantity_sold(before_promo)`,
		`quantity_sold(after_promo)`,
		(`quantity_sold(after_promo)`- `quantity_sold(before_promo)`) as `ISU`,
		`TotalRevenue(Before_Promotion)`,
        `TotalRevenue(After_Promotion)`,
		`TotalRevenue(After_Promotion)`-`TotalRevenue(Before_Promotion)` as `IR`
	From
		Summary
	)
	
Select 
    promo_type,
    sum(`quantity_sold(before_promo)`) as `Qty Sold Before Promo`,
    sum(`quantity_sold(after_promo)`) as `Qty Sold After Promo`,
    sum(`ISU`) as `ISU`,
    round(sum(`TotalRevenue(Before_Promotion)`)/1000000,2) as `TotalRevenue(Before_Promotion) in Millions`,
    round(sum(`TotalRevenue(After_Promotion)`)/1000000,2) as`TotalRevenue(After_Promotion) in Millions`,
    round(sum(`IR`)/1000000,2) as `IR in Millions`
From
	IncreRev
Group by
	promo_type
Having 
	`Qty Sold After Promo`>`Qty Sold Before Promo`
    And
    `TotalRevenue(After_Promotion) in Millions`>`TotalRevenue(Before_Promotion) in Millions`
;