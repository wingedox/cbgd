/****** Object:  Trigger [good_return_bill_bi]    Script Date: 01/14/2012 16:34:14 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[good_return_bill_bi]'))
EXEC dbo.sp_executesql @statement = N'create trigger good_return_bill_bi on good_return_bill
for update
as

    declare @date as datetime
    set @date = getdate()

    insert into bi_jxc
    --ÍË¿â
        SELECT a.audit_date as notedate, a.good_return_code as noteno, ''LS'' as department, cast(a.provider_id as varchar(32)) as partnerno,
        cast(a.storeroom_id as varchar(32)) as houseno, NULL as saleman, a.dept_id as deptno, b.id as wareno,
        -b.return_nums AS amount,b.price as price,-b.return_nums * b.price as curr,
        ''CT'' as type, @date as UpdateDate, 0 as computed
    FROM inserted a INNER JOIN
        good_return_bill_d b ON
        a.good_return_id = b.good_return_id
' 
