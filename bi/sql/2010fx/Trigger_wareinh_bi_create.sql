/****** Object:  Trigger [wareinh_bi]    Script Date: 01/19/2012 02:29:11 ******/
SET ANSI_NULLS ONSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[wareinh_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
EXEC dbo.sp_executesql @statement = N'
          create   TRIGGER [wareinh_bi] ON [dbo].[WAREINH]

          FOR UPDATE
          AS

          if update(tag)
          begin
          declare @tag as bit
          select @tag = tag from inserted

          if @tag = 0
          delete bi_jxc where department = ''fx'' and
          noteno = (select noteno from deleted) and
          (type = ''CR'' or type = ''CG'')
          else
          begin
          declare @notedate as datetime,
          @dbname as varchar(50),
          @date as datetime,
          @type as varchar(2)

          select @dbname = db_name(dbid) from master.dbo.sysprocesses
          where spid =  @@spid
          set @date = getdate()

          select @type = type0 from inserted

          if @type = ''05''
          insert into bi_jxc select @date as notedate, i.noteno, i.provno as partnerno, 0 as amount, 0 as price, -m.curr1 as curr,
          m.wareno as wareno, ''CG'' as type, ''fx'' as department, rtrim(i.houseno) as stockno, @dbname as dbname, @date as UpdateDate,
          0 as computed
          from inserted i inner join wareinm m on i.noteno = m.noteno and m.curr1 <> 0
          else
          insert into bi_jxc select @date as notedate, i.noteno, i.provno as partnerno, m.amount, m.price, m.curr, m.wareno,
          ''CR'' as type, ''fx'' as department, rtrim(i.houseno) as stockno, @dbname as dbname, @date as UpdateDate, 0 as computed
          from inserted i inner join wareinm m on i.noteno = m.noteno
          end
          end
          ' 