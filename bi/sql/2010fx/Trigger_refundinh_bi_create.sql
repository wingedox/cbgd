/****** Object:  Trigger [refundinh_bi]    Script Date: 01/19/2012 02:29:03 ******/
SET ANSI_NULLS ONSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[refundinh_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
EXEC dbo.sp_executesql @statement = N'
          create  TRIGGER [refundinh_bi] ON [dbo].[refundinh]

          FOR UPDATE
          AS

          if update(tag)
          begin
          declare @tag as bit
          select @tag = tag from inserted

          if @tag = 0
          delete bi_jxc where department = ''fx'' and
          noteno = (select noteno from deleted) and
          type = ''CT''
          else
          begin
          declare @notedate as datetime,
          @dbname as varchar(50),
          @date as datetime

          select @dbname = db_name(dbid) from master.dbo.sysprocesses
          where spid =  @@spid
          set @date = getdate()

          insert into bi_jxc select @date as notedate, i.noteno, i.provno as partnerno, -m.amount, -m.price, -m.curr, m.wareno,
          ''CT'' as type, ''fx'' as department, rtrim(i.houseno) as stockno, @dbname as dbname, @date as UpdateDate, 0 as computed
          from inserted i inner join refundinm m on i.noteno = m.noteno
          end
          end
          ' 