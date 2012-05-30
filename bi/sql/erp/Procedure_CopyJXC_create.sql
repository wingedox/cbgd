/****** Object:  StoredProcedure [CopyJXC]    Script Date: 01/19/2012 02:16:25 ******/
SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[CopyJXC]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE CopyJXC
(@reCaculate bit = 0)
AS

-----------------------------------------
--
--  计算最后时间
--
-----------------------------------------
declare @endCaculate datetime

if @reCaculate = 1
    begin
	delete from CostAccounting..jxc
    end

select @endCaculate = notedate from CostAccounting..jxc order by notedate

set @endCaculate = isnull(@endCaculate, ''2007-4-1'')

-----------------------------------------

--  生成业务数据表

-----------------------------------------

insert CostAccounting..jxc select *, null, null, null, null, null, null, null from
(
-- 销售退回
SELECT REFUNDOUTH.notedate, REFUNDOUTM.noteno, -REFUNDOUTM.amount as amount, - REFUNDOUTM.price as price, 
      - REFUNDOUTM.curr as curr, REFUNDOUTM.wareno, ''XT'' as type
      
FROM REFUNDOUTM INNER JOIN
      REFUNDOUTH ON REFUNDOUTM.noteno = REFUNDOUTH.noteno
union all
-- 销售、销更
SELECT WAREOUTH.notedate, RTRIM(WAREOUTH.noteno), 
      CASE WHEN wareouth.type0 = ''05'' THEN NULL ELSE wareoutm.amount END as amount, 
      CASE WHEN wareouth.type0 = ''05'' THEN NULL ELSE wareoutm.price END as price, 
      CASE WHEN wareouth.type0 = ''05'' THEN - wareoutm.curr1 WHEN wareouth.type0 = ''01''
       THEN wareoutm.curr END as curr, WAREOUTM.wareno,
      CASE WHEN wareouth.type0 = ''05'' THEN ''XG'' ELSE ''XS'' END as type 
FROM WAREOUTM INNER JOIN
      WAREOUTH ON WAREOUTM.noteno = WAREOUTH.noteno
WHERE (WAREOUTH.tag = 1) AND (WAREOUTH.type0 = ''01'' OR
      WAREOUTH.type0 = ''05'') AND 
      (CASE WHEN wareouth.type0 = ''05'' THEN - wareoutm.curr1 WHEN wareouth.type0 = ''01''
       THEN wareoutm.curr END <> 0)
union all
-- 采购、进价更正
SELECT WAREINH.notedate, WAREINH.noteno,
      CASE WHEN wareinh.type0 = ''05'' THEN NULL ELSE wareinm.amount END as amount, 
      CASE WHEN wareinh.type0 = ''05'' THEN NULL ELSE wareinm.price END as price, 
      CASE WHEN wareinh.type0 = ''05'' THEN - wareinm.curr1 WHEN wareinh.type0 = ''01''
       THEN wareinm.curr END as curr, WAREINM.wareno,
      CASE WHEN wareinh.type0 = ''05'' THEN ''CG'' ELSE ''CR'' END as type
FROM WAREINH INNER JOIN
      WAREINM ON WAREINH.noteno = WAREINM.noteno
WHERE (WAREINH.tag = 1) AND (WAREINH.type0 = ''01'' or wareinh.type0=''05'')
union all
-- 采购退回
SELECT REFUNDINH.notedate, REFUNDINH.noteno, -REFUNDINM.amount as amount, 
      -REFUNDINM.price as price, -REFUNDINM.curr as curr, REFUNDINM.wareno, ''CT'' as type
FROM REFUNDINH INNER JOIN
      REFUNDINM ON REFUNDINH.noteno = REFUNDINM.noteno
WHERE (REFUNDINH.tag = 1)) jxc where notedate > @endCaculate' 
END
