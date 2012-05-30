/****** Object:  StoredProcedure [RetailStockTurnover]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[RetailStockTurnover]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
create      PROCEDURE [dbo].[RetailStockTurnover] AS

exec CopyRetailGoodsJournal
declare @StartDate as datetime
declare @EndDate as datetime,
	@StartWeekDate as datetime
select @EndDate = max(aDay) from RetailGoodsDayStocks
set @StartDate = dateadd(day, -30, @EndDate)
set @StartWeekDate = dateadd(day, -7, @EndDate)


select aa.productID as 商品编码, aa.ProductName as 商品名称, aa.stockquantity as 库存数量, aa.weekquantity as 周销售,
	aa.salequantity as 上月销售, aa.stockdays as 库存天数, aa.avgstock as 平均库存, 
	case when (aa.salequantity is null) or (aa.salequantity = 0) then null else 
		(aa.stockdays * aa.avgstock)/(cast(aa.salequantity as money)) end as 周转天数,
	(select max(billdate) from retailgoodsjournal where productid = aa.productid and logisticstype = ''采购入库'') as 上次采购,
	(select max(billdate) from retailgoodsjournal where productid = aa.productid and logisticstype = ''销售出库'') as 上次销售,
	cc.category_name as 商品系列, cc.category_name_new as 商品分类, cc.category_name_host as 主机 
from (
	select case when sale.productid is null then stock.productid else sale.productid end as productID,
		case when sale.productcode is null then stock.productcode else sale.productcode end as producticode,
		case when sale.productname is null then stock.productname else sale.productname end as productName,
		stock.stockquantity, sale.salequantity, weeksale.salequantity as weekquantity, avgstock.stockdays, avgstock.avgstock
	from
		-- 月销售表
	       (select  b.id as productid, c.good_id as productcode, 
			case when ltrim(c.good_spec) = '''' then c.good_name else c.good_name + ''('' + c.good_spec + '')'' end as productname,
			 sum(b.sale_good_nums) as SaleQuantity 
		from cash_sale_bill a 
			inner join good_sale_exchange b on a.good_sale_code = b.bill_code 
			inner join goods_info c on b.id = c.id
		where a.status in (''7'',''9'',''11'',''31'',''40'') and a.sale_date > @StartDate
		group by b.id, c.good_id, c.good_name, c.good_spec) sale

		full outer join
		-- 周销售表
	       (select  b.id as productid, sum(b.sale_good_nums) as SaleQuantity 
		from cash_sale_bill a 
			inner join good_sale_exchange b on a.good_sale_code = b.bill_code 
		where a.status in (''7'',''9'',''11'',''31'',''40'') and a.sale_date > @StartWeekDate
		group by b.id) weeksale
		on sale.productid = weeksale.productid
	
		full outer join
		-- 平均库存表
		(select productid, productcode, productname, COUNT(Quantity) AS stockDays, 
		        AVG(cast(Quantity as money)) AS avgStock from retailgoodsdaystocks 
		where aday > @Startdate
		group by productid, productcode, productname) avgStock
		on sale.productid = avgstock.productid 

		full outer join
		-- 库存表
		(select productid, productcode, productname, quantity as stockquantity 
		from retailgoodsdaystocks 
		where aday = @enddate) stock 
		on avgstock.productid = stock.productid
	) aa 
	inner join goods_info bb on aa.productid = bb.id
	inner join good_category cc on bb.category_id = cc.category_id





' 
END
