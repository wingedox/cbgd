/****** Object:  Trigger [refundinh_bi]    Script Date: 01/13/2012 04:54:35 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[refundinh_bi]'))
EXEC dbo.sp_executesql @statement = N'        create  TRIGGER [refundinh_bi] ON [dbo].[refundinh]

        FOR UPDATE
        AS

        if update(tag)
        begin
            declare @date as datetime
            set @date = getdate()

            insert into bi_jxc
            select @date as notedate, i.noteno, substring(i.houseno,1,2) as department, i.provno as partnerno,
                i.houseno, NULL as saleman, i.dptno, m.wareno, -m.amount, -m.price, -m.curr,
                ''CT'' as type, @date as UpdateDate, 0 as computed
            from inserted i inner join refundinm m on i.noteno = m.noteno
        end' 
