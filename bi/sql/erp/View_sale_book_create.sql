/****** Object:  View [sale_book]    Script Date: 01/14/2012 16:34:18 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[sale_book]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [dbo].[sale_book]
AS
SELECT TOP 100 PERCENT dbo.good_sale_exchange.bill_date AS 单据日期, 
      dbo.dept_info.dept_name AS 销售部门, dbo.emp_info.emp_name AS 销售人员, 
      dbo.goods_info.good_id AS 商品编码, dbo.good_sale_exchange.bill_code AS 单据号, 
      dbo.good_category.category_name AS 商品类别, 
      dbo.good_category.category_name_new AS 商品大类, 
      dbo.good_sale_exchange.good_spec AS 商品名称, 
      dbo.exchange_type.exchange_type_name AS 业务类型, 
      SUM(dbo.good_sale_exchange.sale_good_nums) AS 数量, 
      dbo.good_sale_exchange.price AS 单价, 
      SUM(dbo.good_sale_exchange.sale_good_nums * dbo.good_sale_exchange.price) 
      AS 金额, dbo.good_sale_exchange.cost_price AS 虚拟成本, 
      SUM(dbo.store_goods_exchange.price * dbo.store_goods_exchange.good_nums) 
      / SUM(dbo.store_goods_exchange.good_nums) AS 先进先出成本, 
      dbo.customers.customer_name AS 客户名称, 
      dbo.good_category.category_name_host AS 主机
FROM dbo.good_sale_exchange FULL OUTER JOIN
      dbo.customers INNER JOIN
      dbo.cash_sale_bill ON 
      dbo.customers.customer_id = dbo.cash_sale_bill.customer_id INNER JOIN
      dbo.sale_out_store ON 
      dbo.cash_sale_bill.good_sale_id = dbo.sale_out_store.sale_bill_id INNER JOIN
      dbo.store_goods_exchange INNER JOIN
      dbo.goods_info ON dbo.store_goods_exchange.good_id = dbo.goods_info.id ON 
      dbo.sale_out_store.bill_code = dbo.store_goods_exchange.bill_code RIGHT OUTER JOIN
      dbo.dept_info ON dbo.cash_sale_bill.dept_id = dbo.dept_info.dept_id ON 
      dbo.good_sale_exchange.bill_code = dbo.cash_sale_bill.good_sale_code AND 
      dbo.good_sale_exchange.id = dbo.goods_info.id LEFT OUTER JOIN
      dbo.good_category ON 
      dbo.goods_info.category_id = dbo.good_category.category_id LEFT OUTER JOIN
      dbo.emp_info ON 
      dbo.cash_sale_bill.sale_man = dbo.emp_info.emp_id LEFT OUTER JOIN
      dbo.exchange_type ON 
      dbo.good_sale_exchange.exchange_type_id = dbo.exchange_type.exchange_type_id
WHERE (dbo.cash_sale_bill.status IN (''7'', ''9'', ''10'', ''11'')) AND (dbo.dept_info.is_shop = ''Y'') 
      AND (dbo.emp_info.is_saler = ''Y'')
GROUP BY dbo.dept_info.dept_name, dbo.emp_info.emp_name, dbo.goods_info.good_id, 
      dbo.good_sale_exchange.bill_code, dbo.good_sale_exchange.good_spec, 
      dbo.exchange_type.exchange_type_name, dbo.good_sale_exchange.bill_date, 
      dbo.good_category.category_name, dbo.good_category.category_name_new, 
      dbo.good_sale_exchange.price, dbo.good_sale_exchange.cost_price, 
      dbo.customers.customer_name, dbo.good_category.category_name_host
ORDER BY dbo.good_sale_exchange.bill_date DESC


' 
