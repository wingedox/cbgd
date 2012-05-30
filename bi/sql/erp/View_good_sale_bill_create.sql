/****** Object:  View [good_sale_bill]    Script Date: 01/14/2012 16:34:17 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[good_sale_bill]'))
EXEC dbo.sp_executesql @statement = N'
--create view good_sale_bill
CREATE view [dbo].[good_sale_bill]
as
select a.*,
	sale_money =
		--������ǰ����ؽ��˻���ʹ���˳������ܽ��г���,Ϊ�˺���ǰ����,����Ҫ��������
		case when a.sale_bill_type=''4'' then 
				(a.total_money)*(-1)
			else a.total_money
	end,
	receive_money_type=
		case when a.sale_bill_type=''4'' then a.return_money_type
		else a.receive_type
	end,
	year(sale_date) year,
	month(sale_date) month,
	day(sale_date) day,
	datename(yyyy,sale_date) + datename(mm,sale_date) year_month_info
from cash_sale_bill a


' 
