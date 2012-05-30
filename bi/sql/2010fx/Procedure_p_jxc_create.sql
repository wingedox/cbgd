/****** Object:  StoredProcedure [p_jxc]    Script Date: 01/19/2012 02:28:52 ******/
SET ANSI_NULLS OFFSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[p_jxc]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE    PROCEDURE p_jxc  AS



SELECT cost.notedate AS 日期, cost.noteno AS 单据号, cost.wareno AS 商品编码, 
      WARECODE.warename AS 商品名称, cost.amount AS 数量, cost.price AS 单价, 
      cost.curr AS 金额, cost.Profit AS 利润, cost.resource AS 运作资源, 
      cost.accprofit AS 核算利润, 
      CASE WHEN cost.type = ''XS'' THEN ''销售'' WHEN cost.type = ''XG'' THEN ''销售更正'' WHEN
       Cost.type = ''CR'' THEN ''采购入库'' WHEN Cost.type = ''CG'' THEN ''进价更正'' WHEN Cost.type
       = ''XT'' THEN ''销售退回'' WHEN cost.type = ''CT'' THEN ''采购退回'' WHEN cost.type = ''QC'' THEN
      ''期初'' END AS 单据类型, 
      cost.balanceAmount AS 结存数量, cost.balancePrice AS 结存单价, 
      cost.balanceSum AS 结存金额, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN customer.name WHEN cost.type = ''XT'' THEN cust_xt.name WHEN
       cost.type = ''CR'' OR
      cost.type = ''CG'' THEN provide.name WHEN cost.type = ''CT'' THEN provd_ct.name END
       AS 单位名称,
CASE WHEN substring(warecode.wareno, 1, 2) = ''01'' OR
      substring(warecode.wareno, 1, 2) = ''03'' OR
      substring(warecode.wareno, 1, 3) = ''041'' THEN ''主机'' WHEN substring(warecode.wareno, 1, 2) 
      = ''02'' THEN ''显示器'' ELSE ''其他'' END AS 产品属性,
      CASE WHEN substring(warecode.wareno, 1, 2) = ''01'' OR
      substring(warecode.wareno, 1, 2) = ''02'' OR
      substring(warecode.wareno, 1, 4) = ''0501'' OR
      substring(warecode.wareno, 1, 4) = ''0502'' OR
      substring(warecode.wareno, 1, 4) = ''0503'' THEN ''台机'' WHEN substring(warecode.wareno, 1, 4) 
      = ''0507'' OR
      substring(warecode.wareno, 1, 2) = ''04'' THEN ''服务器'' WHEN substring(warecode.wareno, 1, 2) 
      = ''03'' OR
      substring(warecode.wareno, 1, 4) = ''0504'' OR
      substring(warecode.wareno, 1, 4) = ''0505'' OR
      substring(warecode.wareno, 1, 4) = ''0506'' THEN ''笔记本'' WHEN substring(warecode.wareno, 1, 4) 
      = ''0508'' THEN ''其他促销品'' WHEN substring(warecode.wareno, 1, 2) 
      = ''06'' THEN ''其他'' END AS 产品分类,
          (SELECT rtrim(warename)
         FROM warecode w
         WHERE substring(warecode.wareno, 1, 4) = w.wareno AND lastnode = ''0'') AS 产品系列,
          (SELECT rtrim(warename)
         FROM warecode w
         WHERE substring(warecode.wareno, 1, 5) = w.wareno AND lastnode = ''0'') AS 产品子系列, 
      CASE WHEN SUBSTRING(warecode.wareno, 1, 3) = ''012'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0502'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0504'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0506'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0507'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''031'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''022'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''023'' OR
      SUBSTRING(warecode.wareno, 1, 2) = ''04'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''033'' THEN ''大客户'' WHEN substring(warecode.wareno, 1, 
      3) = ''011'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''021'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''034'' OR
      SUBSTRING(warecode.wareno, 1, 4) = ''0501'' THEN ''商用'' WHEN substring(warecode.wareno, 1, 
      3) = ''013'' OR
      substring(warecode.wareno, 1, 3) = ''024'' OR
      substring(warecode.wareno, 1, 3) = ''032'' OR
      substring(warecode.wareno, 1, 4) = ''0503'' OR
      substring(warecode.wareno, 1, 4) = ''0505'' THEN ''消费'' ELSE ''其他'' END as 产品组,
 CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 2) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 2) = cust.code) 
      END AS 大区, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 3) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 3) = cust.code) 
      END AS 客户类型, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 5) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 5) = cust.code) 
      END AS 客户三级分类
FROM CostAccounting.dbo.jxc cost INNER JOIN
      WARECODE ON WARECODE.wareno = cost.wareno LEFT OUTER JOIN
      PROVIDE provd_ct INNER JOIN
      REFUNDINH ON provd_ct.code = REFUNDINH.provno ON 
      cost.noteno = REFUNDINH.noteno LEFT OUTER JOIN
      CUSTGROUPH cust_groph_xt INNER JOIN
      CUSTGROUPM cust_gropm_xt ON 
      cust_groph_xt.groupno = cust_gropm_xt.groupno RIGHT OUTER JOIN
      CUSTOMER CUST_XT INNER JOIN
      REFUNDOUTH ON CUST_XT.code = REFUNDOUTH.custno ON 
      cust_gropm_xt.code = CUST_XT.code ON 
      cost.noteno = REFUNDOUTH.noteno LEFT OUTER JOIN
      WAREOUTH INNER JOIN
      CUSTOMER ON WAREOUTH.custno = CUSTOMER.code LEFT OUTER JOIN
      CUSTGROUPH INNER JOIN
      CUSTGROUPM ON CUSTGROUPH.groupno = CUSTGROUPM.groupno ON 
      CUSTOMER.code = CUSTGROUPM.code ON 
      cost.noteno = WAREOUTH.noteno LEFT OUTER JOIN
      PROVIDE INNER JOIN
      WAREINH ON PROVIDE.code = WAREINH.provno ON 
      cost.noteno = WAREINH.noteno
ORDER BY cost.notedate DESC


' 
END