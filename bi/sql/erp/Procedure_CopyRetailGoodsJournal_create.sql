/****** Object:  StoredProcedure [CopyRetailGoodsJournal]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[CopyRetailGoodsJournal]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create   PROCEDURE [dbo].[CopyRetailGoodsJournal] AS

if not exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[RetailGoodsJournal]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
	CREATE TABLE [dbo].[RetailGoodsJournal] (
		[BillDate] [datetime] NULL ,
		[ProductID] [int] not null,
		[ProductCode] [varchar] (16) NULL, 
		[ProductName] [varchar] (130) COLLATE Chinese_PRC_CI_AS NULL ,
		[LogisticsType] [varchar] (32) COLLATE Chinese_PRC_CI_AS NULL ,
		[StoreName] [varchar] (64) COLLATE Chinese_PRC_CI_AS NULL ,
		[BillCode] [varchar] (32) COLLATE Chinese_PRC_CI_AS NULL ,
		[InStoreQuantity] [int] NULL ,
		[InStorePrice] [numeric](12, 4) NULL ,
		[InStoreMoney] [numeric](23, 4) NULL ,
		[OutStoreQuantity] [int] NULL ,
		[OutStorePrice] [numeric](12, 4) NULL ,
		[OutStoreMoney] [numeric](23, 4) NULL ,
		[StocksQuantity] [int] NULL ,
		[StocksMoney] [numeric](12, 4) NULL ,
		[ViewURL] [varchar] (8000) COLLATE Chinese_PRC_CI_AS NULL ,
		[ProductSeries] [varchar] (80) COLLATE Chinese_PRC_CI_AS NOT NULL ,
		[ProductMainCategory] [varchar] (80) COLLATE Chinese_PRC_CI_AS NULL ,
		[HostClass] [varchar] (80) COLLATE Chinese_PRC_CI_AS NULL 
	) ON [PRIMARY]

if not exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[RetailGoodsDayStocks]'') and OBJECTPROPERTY(id, N''IsUserTable'') = 1)
	CREATE TABLE [dbo].[RetailGoodsDayStocks] (
		[aDay] [datetime] NULL ,
		[ProductID] [int] not null,
		[ProductCode] [varchar] (16) NULL, 
		[ProductName] [varchar] (130) COLLATE Chinese_PRC_CI_AS NULL ,
		[Quantity] [int] NOT NULL ,
		[PurchaseQuantity] [int] NULL ,
		[SaleQuantity] [int] NULL ,
	) ON [PRIMARY]
declare @StartDate as datetime,
        @CurrentDate as datetime

select @StartDate = max(BillDate) from RetailGoodsJournal

if @StartDate is null
    begin
        set @StartDate = ''2009/2/28''
    end
else
    begin
        delete from RetailGoodsJournal where BillDate = @StartDate
    end
INSERT INTO RetailGoodsJournal
      (BillDate, ProductID, ProductCode, ProductName, LogisticsType, StoreName, BillCode, InStoreQuantity, 
      InStorePrice, InStoreMoney, OutStoreQuantity, OutStorePrice, OutStoreMoney, 
      StocksQuantity, StocksMoney, ProductSeries, ProductMainCategory, 
      HostClass, ViewURL)
SELECT TOP 100 PERCENT a.bill_date AS BillDate, d.id, d.good_id AS ProductCode, 
      CASE WHEN (d.good_spec IS NULL) OR
      (d.good_spec = '''') 
      THEN d.good_name ELSE d.good_name + ''('' + d.good_spec + '')'' END AS ProductName,
       b.exchange_type_name AS LogisticsType, c.storeroom_name AS StoreName, 
      a.bill_code AS BillCode, a.in_nums AS InStoreQuantity, a.price AS InStorePrice, 
      a.in_nums * a.price AS InStoreMoney, a.out_nums AS OutStoreQuantity, 
      a.price AS OutStorePrice, a.out_nums * a.price AS OutStoreMoney, 
      a.stock_nums AS StocksQuantity, a.stock_money AS StocksMoney, 
      e.category_name AS ProductSeries, e.category_name_new AS ProductMainCategory, 
      e.category_name_host AS HostClass, 
      ''https://2009erp.e-site.com.cn:8443/erp/'' + REPLACE(b.view_url, ''<%billID%>'', 
      a.bill_id) AS ViewURL
FROM store_goods_exchange a INNER JOIN
      store_exchange_type b ON 
      a.exchange_type_id = b.exchange_type_id INNER JOIN
      storeroom c ON a.storeroom_id = c.storeroom_id INNER JOIN
      goods_info d ON a.good_id = d.id INNER JOIN
      good_category e ON d.category_id = e.category_id
where a.bill_date >= @StartDate

select @StartDate = max(aDay) from RetailGoodsDayStocks
if @StartDate is null
    begin
        set @StartDate = ''2009/2/28''
    end
else
    begin
        delete from RetailGoodsDayStocks where aDay = @StartDate
    end


set @CurrentDate = getdate()
while @StartDate <= @CurrentDate
    begin
	insert into RetailGoodsDayStocks (aDay, ProductID, ProductCode, ProductName, Quantity, PurchaseQuantity, SaleQuantity)
	select @StartDate as aDay, ProductID, ProductCode, ProductName, sum(InStoreQuantity) - sum(OutStoreQuantity) as Quantity, 
		(select sum(InStoreQuantity) from RetailGoodsJournal a
		 where a.BillDate = @StartDate and a.ProductCode = b.ProductCode) as PurchaseQuantity,
		(select sum(OutStoreQuantity) from RetailGoodsJournal a
		 where a.BillDate = @StartDate and a.ProductCode = b.ProductCode) as SaleQuantity
	from RetailGoodsJournal b
	where BillDate <= @StartDate
	group by productid, productcode, productname
	having (sum(InStoreQuantity) - sum(OutStoreQuantity)) <> 0
	set @StartDate = dateadd(day, 1, @StartDate)
    end



-- select sum(quantity) from (
-- 	select ''2009/9/8'' as aDay, ProductCode, ProductName, sum(InStoreQuantity) - sum(OutStoreQuantity) as Quantity, 
-- 		(select sum(InStoreQuantity) from RetailGoodsJournal a
-- 		 where a.BillDate = ''2009/9/8'' and a.ProductCode = b.ProductCode) as PurchaseQuantity,
-- 		(select sum(OutStoreQuantity) from RetailGoodsJournal a
-- 		 where a.BillDate = ''2009/9/8'' and a.ProductCode = b.ProductCode) as SaleQuantity
-- 	from RetailGoodsJournal b
-- 	where BillDate <= ''2009/9/8'' 
-- 	group by productcode, productname
-- 	having (sum(InStoreQuantity) - sum(OutStoreQuantity)) <> 0
-- ) a
-- 
-- select aday, sum(quantity) from RetailGoodsDayStocks group by aDay order by aday desc

--select count(*) from RetailGoodsJournal




' 
END
