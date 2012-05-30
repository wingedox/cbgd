/****** Object:  StoredProcedure [getSaleDetail]    Script Date: 01/13/2012 04:54:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[getSaleDetail]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[getSaleDetail]
	@dept varchar(4) = ''all''
AS
BEGIN
if @dept=''fx''
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS 数量, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS 单价, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS 金额, rtrim(e.Name) AS 销售员, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.客户编码 and
		  m.wareno=p.产品编码 and c.部门=''分销'' and p.产品编码<>''31016666''
	union all
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  - m.amount AS 数量, - m.price AS 单价, 
		  - m.curr AS 金额, rtrim(e.Name) AS 销售员, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.客户编码 and
		m.wareno=p.产品编码 and c.部门=''分销'' and p.产品编码<>''31016666''
if @dept=''hy''
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS 数量, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS 单价, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS 金额, rtrim(e.Name) AS 销售员, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.客户编码 and
		  m.wareno=p.产品编码 and c.部门=''行业'' and p.产品编码<>''31016666''
	union all
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  - m.amount AS 数量, - m.price AS 单价, 
		  - m.curr AS 金额, rtrim(e.Name) AS 销售员, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.客户编码 and
		m.wareno=p.产品编码 and c.部门=''行业'' and p.产品编码<>''31016666''
if @dept=''bc''
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS 数量, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS 单价, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS 金额, rtrim(e.Name) AS 销售员, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.客户编码 and
		  m.wareno=p.产品编码 and c.部门=''客户'' and p.产品编码<>''31016666''
	union all
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  - m.amount AS 数量, - m.price AS 单价, 
		  - m.curr AS 金额, rtrim(e.Name) AS 销售员, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.客户编码 and
		m.wareno=p.产品编码 and c.部门=''客户'' and p.产品编码<>''31016666''
if @dept=''all''
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS 数量, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS 单价, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS 金额, rtrim(e.Name) AS 销售员, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.客户编码 and
		  m.wareno=p.产品编码 and p.产品编码<>''31016666''
	union all
	SELECT c.*, h.notedate AS 销售日期, RTRIM(h.noteno) AS 单据号, 
		  - m.amount AS 数量, - m.price AS 单价, 
		  - m.curr AS 金额, rtrim(e.Name) AS 销售员, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.客户编码 and
		m.wareno=p.产品编码 and p.产品编码<>''31016666''
END
' 
END
