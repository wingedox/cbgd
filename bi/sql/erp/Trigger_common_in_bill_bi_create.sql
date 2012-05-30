/****** Object:  Trigger [common_in_bill_bi]    Script Date: 01/14/2012 16:34:13 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[common_in_bill_bi]'))
EXEC dbo.sp_executesql @statement = N'create trigger common_in_bill_bi on common_in_bill
for update
as

if update(status)
begin
    declare @date as datetime
    set @date = getdate()

    insert into bi_jxc
    --∆‰À˚»Îø‚
    SELECT a.audit_date as notedate, a.bill_code as noteno, ''LS'' as department, cast(a.customer_id as varchar(32)) as partnerno,
        cast(a.storeroom_id as varchar(32)) as houseno, NULL as saleman, a.dept_id as deptno, b.good_id as wareno,
        b.good_nums AS amount,b.in_price as price,b.good_nums * b.in_price as curr,
        ''QR'' as type, @date as UpdateDate, 0 as computed
    FROM inserted a INNER JOIN
    common_in_bill_d b ON a.bill_id = b.bill_id
end' 
