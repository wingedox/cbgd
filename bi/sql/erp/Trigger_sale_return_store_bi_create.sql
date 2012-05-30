/****** Object:  Trigger [sale_return_store_bi]    Script Date: 01/14/2012 16:34:14 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[sale_return_store_bi]'))
EXEC dbo.sp_executesql @statement = N'create trigger sale_return_store_bi on sale_return_store
for insert, update
as
    declare @date as datetime
    set @date = getdate()

    insert into bi_jxc
    --œ˙ €ÕÀø‚
        SELECT a.operate_date as notedate, a.bill_code as noteno, ''LS'' as department, cast(c.customer_id as varchar(32)) as partnerno,
            cast(a.storeroom_id as varchar(32)) as houseno, NULL as saleman, a.dept_id as deptno, b.good_id as wareno,
            -b.good_nums AS amount,b.sale_price as price,-b.good_nums * b.sale_price as curr,
            ''XT'' as type, @date as UpdateDate, 0 as computed
        FROM inserted a INNER JOIN
            sale_return_store_d b ON
            a.bill_id = b.bill_id inner join cash_sale_bill c on
            a.sale_bill_id = c.good_sale_id' 
