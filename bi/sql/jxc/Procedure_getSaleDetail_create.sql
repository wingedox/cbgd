/****** Object:  StoredProcedure [getSaleDetail]    Script Date: 01/14/2012 16:10:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[getSaleDetail]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
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
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS ���, rtrim(e.Name) AS ����Ա, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.�ͻ����� and
		  m.wareno=p.��Ʒ���� and c.����=''����'' and p.��Ʒ����<>''31016666''
	union all
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  - m.amount AS ����, - m.price AS ����, 
		  - m.curr AS ���, rtrim(e.Name) AS ����Ա, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.�ͻ����� and
		m.wareno=p.��Ʒ���� and c.����=''����'' and p.��Ʒ����<>''31016666''
if @dept=''hy''
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS ���, rtrim(e.Name) AS ����Ա, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.�ͻ����� and
		  m.wareno=p.��Ʒ���� and c.����=''��ҵ'' and p.��Ʒ����<>''31016666''
	union all
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  - m.amount AS ����, - m.price AS ����, 
		  - m.curr AS ���, rtrim(e.Name) AS ����Ա, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.�ͻ����� and
		m.wareno=p.��Ʒ���� and c.����=''��ҵ'' and p.��Ʒ����<>''31016666''
if @dept=''bc''
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS ���, rtrim(e.Name) AS ����Ա, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.�ͻ����� and
		  m.wareno=p.��Ʒ���� and c.����=''�ͻ�'' and p.��Ʒ����<>''31016666''
	union all
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  - m.amount AS ����, - m.price AS ����, 
		  - m.curr AS ���, rtrim(e.Name) AS ����Ա, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.�ͻ����� and
		m.wareno=p.��Ʒ���� and c.����=''�ͻ�'' and p.��Ʒ����<>''31016666''
if @dept=''all''
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  CASE WHEN h.type0 = ''05'' THEN NULL 
		  ELSE m.amount END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN NULL ELSE m.price END AS ����, 
		  CASE WHEN h.type0 = ''05'' THEN - m.curr1 WHEN h.type0 = ''01''
		   THEN m.curr END AS ���, rtrim(e.Name) AS ����Ա, p.*      
	FROM WAREOUTH h, WAREOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) AND (h.type0 = ''01'' OR
		  h.type0 = ''05'') and
		  h.noteno=m.noteno and
		  h.saleman=e.code and
		  h.custno=c.�ͻ����� and
		  m.wareno=p.��Ʒ���� and p.��Ʒ����<>''31016666''
	union all
	SELECT c.*, h.notedate AS ��������, RTRIM(h.noteno) AS ���ݺ�, 
		  - m.amount AS ����, - m.price AS ����, 
		  - m.curr AS ���, rtrim(e.Name) AS ����Ա, p.*
	FROM REFUNDOUTH h, REFUNDOUTM m, EMPLOYE e, cust_category c, product_category p
	WHERE (h.tag = 1) and h.noteno=m.noteno and
		h.saleman=e.code and
		h.custno=c.�ͻ����� and
		m.wareno=p.��Ʒ���� and p.��Ʒ����<>''31016666''
END
' 
END
