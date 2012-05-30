/****** Object:  View [erp_goods_info]    Script Date: 01/14/2012 16:34:17 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[erp_goods_info]'))
EXEC dbo.sp_executesql @statement = N'
--create view erp_goods_info
CREATE view [dbo].[erp_goods_info]
as
select a.*,
spec_info=
	case
		when (a.good_spec is null) or (a.good_spec = '''') then a.good_name 
		else a.good_name + ''('' + a.good_spec + '')''
	end, b.unit_name
from goods_info a,good_unit b
where a.unit_id = b.unit_id



' 
