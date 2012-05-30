/****** Object:  StoredProcedure [GetStock]    Script Date: 01/19/2012 02:28:52 ******/
SET ANSI_NULLS ONSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetStock]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'
--exec GetStock ''2009-05-02''

CREATE   PROCEDURE [dbo].[GetStock]
(
@endDate as datetime = null
)
 AS
declare @period as varchar(6),
	@startDate as datetime
--	@endDate as datetime

if (@endDate is null)
 begin
	set @endDate = getdate()
 end

set @period = dbo.GetPeriod(@endDate, 0)
set @startDate = dbo.GetPeriod(@endDate, 1)

--set @endDate = getdate()


SELECT WARECODE.wareno as 产品编码, WARECODE.warename as 产品名称, sum(stock.amount) as 数量,
          (SELECT rtrim(warename)
         FROM warecode
         WHERE substring(stock.wareno, 1, 2) = wareno AND lastnode = ''0'') AS 产品分类,
          (SELECT rtrim(warename)
         FROM warecode
         WHERE substring(stock.wareno, 1, 3) = wareno AND lastnode = ''0'') AS 产品组,
          (SELECT rtrim(warename)
         FROM warecode
         WHERE substring(stock.wareno, 1, 4) = wareno AND lastnode = ''0'') AS 产品系列,
          (SELECT rtrim(warename)
         FROM warecode
         WHERE substring(stock.wareno, 1, 6) = wareno AND lastnode = ''0'') 
      AS 模式
FROM (SELECT WARESUM.wareno, SUM(WARESUM.amount) AS amount
        FROM WARESUM INNER JOIN
              WARECODE ON WARESUM.wareno = WARECODE.wareno INNER JOIN
              WAREHOUSE ON WARESUM.houseno = WAREHOUSE.houseno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WARESUM.period = @period)
        GROUP BY WARESUM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT WAREINM.wareno, SUM(WAREINM.amount) AS amount
        FROM WAREINH INNER JOIN
              WAREINM ON WAREINH.noteno = WAREINM.noteno INNER JOIN
              WARECODE ON WAREINM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WAREINH.tag = 1) AND (WAREINH.type0 = ''01'') AND 
              (WAREINH.notedate >= @startDate) AND 
              (WAREINH.notedate <= @endDate)
        GROUP BY WAREINM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT REFUNDINM.wareno, - SUM(REFUNDINM.amount) AS amount
        FROM REFUNDINH INNER JOIN
              REFUNDINM ON REFUNDINH.noteno = REFUNDINM.noteno INNER JOIN
              WARECODE ON REFUNDINM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (REFUNDINH.notedate <= @endDate) AND (REFUNDINH.tag = 1) 
              AND (REFUNDINH.notedate >= @startDate)
        GROUP BY REFUNDINM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT WAREALLOTM.wareno, SUM(WAREALLOTM.amount) AS amount
        FROM WAREALLOTH INNER JOIN
              WAREALLOTM ON WAREALLOTH.noteno = WAREALLOTM.noteno INNER JOIN
              WARECODE ON WAREALLOTM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WAREALLOTH.notedate >= @startDate) AND 
              (WAREALLOTH.tag = 1) AND 
              (WAREALLOTH.notedate <= @endDate)
        GROUP BY WAREALLOTM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT WAREOUTM.wareno, - SUM(WAREOUTM.amount) AS amount
        FROM WAREOUTH INNER JOIN
              WAREOUTM ON WAREOUTH.noteno = WAREOUTM.noteno INNER JOIN
              WARECODE ON WAREOUTM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WAREOUTH.notedate >= @startDate) AND (WAREOUTH.tag = 1) 
              AND (WAREOUTH.type0 = ''01'') AND 
              (WAREOUTH.notedate <= @endDate)
        GROUP BY WAREOUTM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT REFUNDOUTM.wareno, SUM(REFUNDOUTM.amount) AS amount
        FROM REFUNDOUTH INNER JOIN
              REFUNDOUTM ON 
              REFUNDOUTH.noteno = REFUNDOUTM.noteno INNER JOIN
              WARECODE ON REFUNDOUTM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (REFUNDOUTH.notedate >= @startDate) AND 
              (REFUNDOUTH.tag = 1) AND 
              (REFUNDOUTH.notedate <= @endDate)
        GROUP BY REFUNDOUTM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT WAREALLOTM.wareno, - SUM(WAREALLOTM.amount) AS amount
        FROM WAREALLOTH INNER JOIN
              WAREALLOTM ON WAREALLOTH.noteno = WAREALLOTM.noteno INNER JOIN
              WARECODE ON WAREALLOTM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WAREALLOTH.notedate >= @startDate) AND 
              (WAREALLOTH.tag = 1) AND 
              (WAREALLOTH.notedate <= @endDate)
        GROUP BY WAREALLOTM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname
        UNION ALL
        SELECT WARECHECKM.wareno, SUM(WARECHECKM.amount) AS amount
        FROM WARECHECKH INNER JOIN
              WARECHECKM ON 
              WARECHECKH.noteno = WARECHECKM.noteno INNER JOIN
              WARECODE ON WARECHECKM.wareno = WARECODE.wareno INNER JOIN
              BRAND ON WARECODE.BrandNo = BRAND.Brandno
        WHERE (WARECHECKH.notedate >= @startDate) AND 
              (WARECHECKH.tag = 1) AND (WARECHECKM.amount <> 0) AND 
              (WARECHECKH.notedate <= @endDate)
        GROUP BY WARECHECKM.wareno, WARECODE.typeno, WARECODE.BrandNo, 
              WARECODE.warename, WARECODE.units, WARECODE.model, 
              WARECODE.EnterSale, WARECODE.costprice, WARECODE.MaxAmt, 
              WARECODE.MinAmt, BRAND.Brandname) stock INNER JOIN
      WARECODE ON 
      stock.wareno COLLATE Chinese_PRC_CI_AS = WARECODE.wareno
group by warecode.wareno, warecode.warename, stock.wareno having sum(amount)<>0





' 
END