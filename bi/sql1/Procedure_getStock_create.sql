/****** Object:  StoredProcedure [getStock]    Script Date: 01/13/2012 04:54:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[getStock]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE getStock
(@endDate as datetime=null,
@dept as varchar(4)=null)
AS
BEGIN
declare @period as varchar(6),
	@startDate as datetime

if (@endDate is null)
 begin
	set @endDate = getdate()
 end
 if @dept is null
	set @dept=''all''

set @period = dbo.GetPeriod(@endDate, 0)
set @startDate = dbo.GetPeriod(@endDate, 1)


select h.*, s.amount 数量, p.* from (
	select stock.houseno, stock.wareno, sum(stock.amount) amount from (
		SELECT s.houseno, s.wareno, SUM(s.amount) AS amount
		FROM WARESUM s
		WHERE (s.period = @period)
		group by s.wareno, s.houseno
		having SUM(s.amount) <> 0
		UNION ALL
		SELECT h.houseno, m.wareno, SUM(m.amount) AS amount
		FROM WAREINH h, WAREINM m
		WHERE (h.tag = 1) AND (h.type0 = ''01'') AND 
			  (h.notedate >= @startDate) AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.houseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.houseno, m.wareno, - SUM(m.amount) AS amount
		FROM REFUNDINH h, REFUNDINM m
		WHERE (h.notedate <= @endDate) AND (h.tag = 1) 
			  AND (h.notedate >= @startDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.houseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.newhouseno houseno, m.wareno, SUM(m.amount) AS amount
		FROM WAREALLOTH h,
			  WAREALLOTM m
		WHERE (h.notedate >= @startDate) AND 
			  (h.tag = 1) AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.newhouseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.houseno, m.wareno, - SUM(m.amount) AS amount
		FROM WAREOUTH h,
			  WAREOUTM m
		WHERE (h.notedate >= @startDate) AND (h.tag = 1) 
			  AND (h.type0 = ''01'') AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.houseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.houseno, m.wareno, SUM(m.amount) AS amount
		FROM REFUNDOUTH h,REFUNDOUTM m
		WHERE (h.notedate >= @startDate) AND 
			  (h.tag = 1) AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.houseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.oldhouseno houseno, m.wareno, - SUM(m.amount) AS amount
		FROM WAREALLOTH h, WAREALLOTM m
		WHERE (h.notedate >= @startDate) AND 
			  (h.tag = 1) AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.oldhouseno
		having SUM(m.amount) <> 0
		UNION ALL
		SELECT h.houseno, m.wareno, SUM(m.amount) AS amount
		FROM WARECHECKH h, WARECHECKM m
		WHERE (h.notedate >= @startDate) AND 
			  (h.tag = 1) AND (m.amount <> 0) AND 
			  (h.notedate <= @endDate) and
			  h.noteno=m.noteno
		group by m.wareno, h.houseno
		having SUM(m.amount) <> 0
		) stock
	group by stock.wareno, stock.houseno
	having sum(stock.amount)<>0
) s, product_category p, warehouse_category h
where p.产品编码=s.wareno and
	s.houseno=h.仓库编码

END
' 
END
