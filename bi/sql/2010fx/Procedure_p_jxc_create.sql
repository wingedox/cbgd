/****** Object:  StoredProcedure [p_jxc]    Script Date: 01/19/2012 02:28:52 ******/
SET ANSI_NULLS OFFSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[p_jxc]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE    PROCEDURE p_jxc  AS



SELECT cost.notedate AS ����, cost.noteno AS ���ݺ�, cost.wareno AS ��Ʒ����, 
      WARECODE.warename AS ��Ʒ����, cost.amount AS ����, cost.price AS ����, 
      cost.curr AS ���, cost.Profit AS ����, cost.resource AS ������Դ, 
      cost.accprofit AS ��������, 
      CASE WHEN cost.type = ''XS'' THEN ''����'' WHEN cost.type = ''XG'' THEN ''���۸���'' WHEN
       Cost.type = ''CR'' THEN ''�ɹ����'' WHEN Cost.type = ''CG'' THEN ''���۸���'' WHEN Cost.type
       = ''XT'' THEN ''�����˻�'' WHEN cost.type = ''CT'' THEN ''�ɹ��˻�'' WHEN cost.type = ''QC'' THEN
      ''�ڳ�'' END AS ��������, 
      cost.balanceAmount AS �������, cost.balancePrice AS ��浥��, 
      cost.balanceSum AS �����, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN customer.name WHEN cost.type = ''XT'' THEN cust_xt.name WHEN
       cost.type = ''CR'' OR
      cost.type = ''CG'' THEN provide.name WHEN cost.type = ''CT'' THEN provd_ct.name END
       AS ��λ����,
CASE WHEN substring(warecode.wareno, 1, 2) = ''01'' OR
      substring(warecode.wareno, 1, 2) = ''03'' OR
      substring(warecode.wareno, 1, 3) = ''041'' THEN ''����'' WHEN substring(warecode.wareno, 1, 2) 
      = ''02'' THEN ''��ʾ��'' ELSE ''����'' END AS ��Ʒ����,
      CASE WHEN substring(warecode.wareno, 1, 2) = ''01'' OR
      substring(warecode.wareno, 1, 2) = ''02'' OR
      substring(warecode.wareno, 1, 4) = ''0501'' OR
      substring(warecode.wareno, 1, 4) = ''0502'' OR
      substring(warecode.wareno, 1, 4) = ''0503'' THEN ''̨��'' WHEN substring(warecode.wareno, 1, 4) 
      = ''0507'' OR
      substring(warecode.wareno, 1, 2) = ''04'' THEN ''������'' WHEN substring(warecode.wareno, 1, 2) 
      = ''03'' OR
      substring(warecode.wareno, 1, 4) = ''0504'' OR
      substring(warecode.wareno, 1, 4) = ''0505'' OR
      substring(warecode.wareno, 1, 4) = ''0506'' THEN ''�ʼǱ�'' WHEN substring(warecode.wareno, 1, 4) 
      = ''0508'' THEN ''��������Ʒ'' WHEN substring(warecode.wareno, 1, 2) 
      = ''06'' THEN ''����'' END AS ��Ʒ����,
          (SELECT rtrim(warename)
         FROM warecode w
         WHERE substring(warecode.wareno, 1, 4) = w.wareno AND lastnode = ''0'') AS ��Ʒϵ��,
          (SELECT rtrim(warename)
         FROM warecode w
         WHERE substring(warecode.wareno, 1, 5) = w.wareno AND lastnode = ''0'') AS ��Ʒ��ϵ��, 
      CASE WHEN SUBSTRING(warecode.wareno, 1, 3) = ''012'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0502'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0504'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0506'' OR
               SUBSTRING(warecode.wareno, 1, 4) = ''0507'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''031'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''022'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''023'' OR
      SUBSTRING(warecode.wareno, 1, 2) = ''04'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''033'' THEN ''��ͻ�'' WHEN substring(warecode.wareno, 1, 
      3) = ''011'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''021'' OR
      SUBSTRING(warecode.wareno, 1, 3) = ''034'' OR
      SUBSTRING(warecode.wareno, 1, 4) = ''0501'' THEN ''����'' WHEN substring(warecode.wareno, 1, 
      3) = ''013'' OR
      substring(warecode.wareno, 1, 3) = ''024'' OR
      substring(warecode.wareno, 1, 3) = ''032'' OR
      substring(warecode.wareno, 1, 4) = ''0503'' OR
      substring(warecode.wareno, 1, 4) = ''0505'' THEN ''����'' ELSE ''����'' END as ��Ʒ��,
 CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 2) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 2) = cust.code) 
      END AS ����, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 3) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 3) = cust.code) 
      END AS �ͻ�����, CASE WHEN cost.type = ''XS'' OR
      cost.type = ''XG'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(customer.code, 1, 5) = cust.code) 
      WHEN cost.type = ''XT'' THEN
          (SELECT rtrim(name)
         FROM customer cust
         WHERE cust.lastnode = ''0'' AND substring(cust_xt.code, 1, 5) = cust.code) 
      END AS �ͻ���������
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