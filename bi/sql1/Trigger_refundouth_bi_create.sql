/****** Object:  Trigger [refundouth_bi]    Script Date: 01/13/2012 04:54:35 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[refundouth_bi]'))
EXEC dbo.sp_executesql @statement = N'        create  TRIGGER [refundouth_bi] ON [dbo].[refundouth]

        FOR UPDATE
        AS

        if update(tag)
        begin
            declare @date as datetime
            set @date = getdate()

            insert into bi_jxc
            select @date as notedate, i.noteno, substring(i.custno,1,2) as department, i.custno as partnerno,
                i.houseno, i.saleman, i.dptno, m.wareno, -m.amount, -m.price, -m.curr,
                ''XT'' as type, @date as UpdateDate, 0 as computed
            from inserted i inner join refundoutm m on i.noteno = m.noteno
        end
' 
