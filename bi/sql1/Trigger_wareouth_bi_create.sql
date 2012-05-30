/****** Object:  Trigger [wareouth_bi]    Script Date: 01/13/2012 04:54:36 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[wareouth_bi]'))
EXEC dbo.sp_executesql @statement = N'        create  TRIGGER [wareouth_bi] ON [dbo].[WAREOUTh]

        FOR UPDATE
        AS

        if update(tag)
        begin
            declare @date as datetime,
                    @type as varchar(2)

            set @date = getdate()
            select @type = type0 from inserted

            if @type = ''05''
                insert into bi_jxc
                select @date as notedate, i.noteno, substring(i.custno,1,2) as department, i.custno as partnerno,
                    i.houseno, i.saleman, i.dptno, m.wareno, m.amount, m.price, m.curr,
                    ''XS'' as type, @date as UpdateDate, 0 as computed
                from inserted i inner join wareoutm m on i.noteno = m.noteno and m.curr1 <> 0
            else
                insert into bi_jxc
                select @date as notedate, i.noteno, substring(i.custno,1,2) as department, i.custno as partnerno,
                    i.houseno, i.saleman, i.dptno, m.wareno, 0 as amount, 0 as price, -m.curr1 as curr,
                    ''XG'' as type, @date as UpdateDate, 0 as computed
                from inserted i inner join wareoutm m on i.noteno = m.noteno
        end' 
