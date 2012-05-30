/****** Object:  View [good_sale_exchange]    Script Date: 01/14/2012 16:34:17 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[good_sale_exchange]'))
EXEC dbo.sp_executesql @statement = N'
--计算产品金额、本次获取积分、积分付款的视图
--create view good_sale_exchange
CREATE view [dbo].[good_sale_exchange]
as

select  b.*,
	d.good_id as good_code,
	good_spec=
	case
		when (d.good_spec is null) or (d.good_spec = '''') then d.good_name 
		else d.good_name + ''('' + d.good_spec + '')''
	end, 
	c.unit_name,
	a.sale_bill_type,
	sale_bill_type_name=
	case
		when a.sale_bill_type=''0'' then ''积分销售单'' 
		when a.sale_bill_type=''1'' then ''非积分销售单'' 
		when a.sale_bill_type=''2'' then ''积分销售冲销单'' 
		when a.sale_bill_type=''3'' then ''非积分销售冲销单'' 
		when a.sale_bill_type=''4'' then ''销售退货单'' 
	end,
	sale_good_nums=
	case
		when (a.sale_bill_type in(''0'',''1'',''2'',''3'')) then b.good_nums
		when (a.sale_bill_type in(''4'')) then -b.good_nums
		else 0
	end,
	pay_money=
	case
		when b.consume_type=''0'' then b.good_nums*b.price
		else 0
	end,
	get_score=
	case
		--是积分单(包括冲销单)并且是用现金购买产品
		when (a.sale_bill_type in(''0'',''2'',''4'')) and b.consume_type=''0'' then b.good_nums*b.score_num
		else 0
	end,
	pay_score=
	case
		--是积分单(包括冲销单)并且是用现金购买产品
		when (a.sale_bill_type in(''0'',''2'',''4'')) and b.consume_type=''1'' then b.good_nums*b.score_price
		else 0
	end
from cash_sale_bill a,goods_exchange b,good_unit c,goods_info d
where a.good_sale_code = b.bill_code and
	b.unit_id = c.unit_id and
	b.id = d.id


' 
