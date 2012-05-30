/****** Object:  Trigger [good_in_bill_bi]    Script Date: 01/14/2012 16:34:13 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[good_in_bill_bi]'))
EXEC dbo.sp_executesql @statement = N'create trigger good_in_bill_bi on good_in_bill
for update
as
    declare @date as datetime
    set @date = getdate()

    insert into bi_jxc
    --Èë¿â
        SELECT a.audit_date as notedate, a.good_in_code as noteno, ''LS'' as department, cast(a.provider_id as varchar(32)) as partnerno,
        cast(a.storeroom_id as varchar(32)) as houseno, NULL as saleman, a.dept_id as deptno, b.good_id as wareno,
        b.good_nums AS amount,b.in_price as price,b.good_nums * b.in_price as curr,
        ''CR'' as type, @date as UpdateDate, 0 as computed
    FROM good_in_bill_d b INNER JOIN
        inserted a ON b.good_in_id = a.good_in_id
' 
