/****** Object:  Trigger [checkexpense]    Script Date: 01/19/2012 02:29:14 ******/

SET ANSI_NULLS ONSET QUOTED_IDENTIFIER ONIF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[checkexpense]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

EXEC dbo.sp_executesql @statement = N'create trigger checkexpense on wareouth

for update

as



declare @tag as bit,

	@dept as varchar(15),

	@noteno as varchar(15)

select @tag = tag, @dept = dptno, @noteno = noteno from inserted



if update(tag)

	if @tag = 1

	  begin

	    if substring(@dept, 1, 2) = ''01''

	      begin

	        declare @wareno as varchar(15)

	        declare	c cursor SCROLL_LOCKS for select wareno from wareoutm where noteno = @noteno

		

		open c

		fetch c into @wareno

	

		while @@fetch_status = 0

	          if not exists(select * from expenseallocation2010 where ���ñ��� = @wareno)

		    declare @warename as varchar(50), @msg as varchar(100)

		    select @warename = rtrim(warename) from warecode where wareno = @wareno

		    select @msg = ''ƽ̨���ܱ���"'' + @warename + ''"''

		    close c

		    deallocate c

	            raiserror(@msg, 16, 1)

	          fetch c into @wareno

    	        close c

	        deallocate c

	      end

	  end



' 