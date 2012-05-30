/****** Object:  StoredProcedure [GetReceivableDetailByCustomer]    Script Date: 01/13/2012 04:54:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[GetReceivableDetailByCustomer]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'create  procedure [dbo].[GetReceivableDetailByCustomer](@custno as varchar(15))
as
begin
select notedate as 日期, rtrim(remark) as 单据类型, noteno as 单据号, rtrim(wareno) as 商品编码,
	rtrim(warename) as 商品名称, amount as 数量, price as 单价, curr as 金额,
	paycurr as 付款金额, rtrim(payname) as 付款方式, rtrim(custname) as 客户,
	remark0 as 收款时间, remark1 as 备注
from (
SELECT a.notedate, ''销售出库'' AS remark, a.noteno, b.wareno, c.warename, b.amount, 
      b.price, b.curr, null AS paycurr, '''' AS payname, e.name AS custname, 
      convert(varchar(10), b.remark, 120) AS remark0, a.remark0 AS remark1
FROM WAREOUTH a INNER JOIN
      WAREOUTM b ON a.noteno = b.noteno INNER JOIN
      WARECODE c ON b.wareno = c.wareno INNER JOIN
      CUSTOMER e ON a.custno = e.code
WHERE (a.type0 = ''01'') AND (a.tag = 1) AND (a.custno = @custno)
union all 
SELECT a.notedate, ''销售更正'' AS remark, a.noteno, b.wareno, c.warename, 
	0 AS amount, 0 AS price, - b.curr1 AS curr, 0 AS paycurr, 
      '''' AS payname, e.name AS custname, convert(varchar(10), b.remark, 120) AS remark0, 
      a.remark0 AS remark1
FROM WAREOUTH a INNER JOIN
      WAREOUTM b ON a.noteno = b.noteno INNER JOIN
      WARECODE c ON b.wareno = c.wareno INNER JOIN
      CUSTOMER e ON a.custno = e.code
WHERE (a.type0 = ''05'') AND (a.tag = 1) AND (a.custno = @custno) AND 
      (b.curr1 <> 0)
union all 
SELECT a.notedate, ''销售退货'' AS remark, a.noteno, b.wareno, c.warename, 
	- b.amount AS amount, b.price, - b.curr AS curr, 0 AS paycurr, 
      '''' AS payname, e.name AS custname, rtrim(b.remark) AS remark0, 
      a.remark0 AS remark1
FROM REFUNDOUTH a INNER JOIN
      REFUNDOUTM b ON a.noteno = b.noteno INNER JOIN
      WARECODE c ON b.wareno = c.wareno INNER JOIN
      CUSTOMER e ON a.custno = e.code
WHERE (a.tag = 1) AND (a.custno = @custno)
union all 
SELECT a.date0 AS notedate, a.remark, a.noteno, '''' AS wareno, '''' AS warename, 
      null AS amount, null AS price, null AS curr, a.curr AS paycurr, b.PayName, 
      c.name AS custname, null AS remark0, null AS remark1
FROM INCOMECURR a INNER JOIN
      CUSTOMER c ON a.custno = c.code INNER JOIN
      PAYWAY b ON a.payno = b.PayNo
WHERE (a.custno = @custno) AND (a.type0 = ''0'') AND 
      (a.curr <> 0)
union all 
SELECT a.date0 AS notedate, a.remark, a.noteno, '''' AS wareno, '''' AS warename, 
      null AS amount, null AS price, null AS curr, - a.curr AS paycurr, b.PayName, 
      c.name AS custname, null AS remark0, null AS remark1
FROM INCOMECURR a INNER JOIN
      CUSTOMER c ON a.custno = c.code INNER JOIN
      PAYWAY b ON a.payno = b.PayNo
WHERE (a.custno = @custno) AND (a.type0 = ''1'') AND 
      (a.curr <> 0)
) a order by notedate desc
end
            

' 
END
