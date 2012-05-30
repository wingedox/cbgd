/****** Object:  StoredProcedure [GetStockTurnover]    Script Date: 01/19/2012 02:28:52 ******/
SET ANSI_NULLS ONSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetStockTurnover]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'









CREATE           procedure GetStockTurnover
as
exec costaccounting..costcaculate
SELECT stock.wareno AS 商品编码, wareInfo.warename AS 商品名称, 
      stock.balanceamount AS 库存数量, stock.balanceprice AS 单价, 
      stock.monthsale AS 上月销量, lastOUT.notedate AS 最后销售, 
      lastIN.notedate AS 最后入库, stock.avgamount AS 平均库存,
      stock.trunover AS 库存周转, stock.stockDays as 库存天数, CASE WHEN stock.avgamount = 0 OR
      stock.trunover = 0 THEN NULL 
      ELSE stock.balanceamount / (stock.avgamount / stock.trunover) 
      END AS 销售预测, w.产品属性, w.产品分类, w.产品系列, w.产品组, w.运作属性
FROM (SELECT a.wareno, a.balanceAmount, a.balancePrice, a.balanceSum, t.monthSale, 
      t.stockDays, t.avgAmount, t.Trunover
FROM (SELECT j.balanceAmount, j.wareno, j.balancePrice, j.balanceSum
        FROM CostAccounting.dbo.jxc j INNER JOIN
                  (SELECT wareno, MAX(caculateIndex) AS caculateIndex
                 FROM costaccounting..jxc
                 GROUP BY wareno) i ON j.wareno = i.wareno AND 
              (CASE WHEN i.caculateindex IS NULL THEN j.type END = ''QC'' OR
              j.caculateindex = i.caculateindex)) a RIGHT OUTER JOIN
          (SELECT wareno, SUM(saleAmount) AS monthSale, COUNT(amount) AS stockDays, 
               AVG(amount) AS avgAmount, CASE WHEN SUM(saleamount) = 0 THEN NULL 
               ELSE COUNT(amount) * AVG(amount) / SUM(cast(saleAmount AS money)) 
               END AS Trunover
         FROM CostAccounting.dbo.DayBalanceAmount
         WHERE (aDay > CONVERT(char(10), DATEADD(dd, - 30, GETDATE()), 120))
         GROUP BY wareno) t ON a.wareno = t.wareno) stock INNER JOIN
      WARECODE wareInfo ON stock.wareno = wareInfo.wareno LEFT OUTER JOIN
          (SELECT m.wareno, MAX(h.notedate) AS notedate
         FROM jxcdata0002..wareoutm m INNER JOIN
               jxcdata0002..wareouth h ON m.noteno = h.noteno
         GROUP BY m.wareno) lastOUT ON 
      stock.wareno = lastOUT.wareno LEFT OUTER JOIN
          (SELECT m.wareno, MAX(h.notedate) AS notedate
         FROM WAREINM m INNER JOIN
               WAREINH h ON m.noteno = h.noteno
         GROUP BY m.wareno) lastIN ON stock.wareno = lastIN.wareno inner join bi..fx_ware_class w on w.产品编码 = stock.wareno
WHERE (stock.monthsale <> 0 or stock.balanceamount <> 0)
order by stock.wareno









' 
END