/****** Object:  UserDefinedFunction [GetLastSellOfReceivable]    Script Date: 01/13/2012 04:54:36 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[GetLastSellOfReceivable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'


create   FUNCTION [dbo].[GetLastSellOfReceivable]
	(@cust_no as varchar(20), 
	@rec_curr as money,
	@end_time as datetime) 
RETURNS datetime
AS
BEGIN

declare c cursor for
	select * from (
	SELECT a.notedate, SUM(c.curr) AS curr
	FROM WAREOUTH a INNER JOIN
	      WAREOUTM c ON a.noteno = c.noteno
	WHERE (a.tag = 1) AND (a.type0 = ''01'') AND a.custno = @cust_no
	GROUP BY a.custno, a.notedate
	union all
	--����
	SELECT a.notedate, - SUM(c.curr1) AS curr
	FROM WAREOUTH a INNER JOIN
	      WAREOUTM c ON a.noteno = c.noteno
	WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (c.curr1 <> 0)
	       AND a.custno = @cust_no
	GROUP BY a.custno, a.notedate
	union all
	--�˿�
	SELECT a.notedate, - SUM(c.curr) AS curr
	FROM REFUNDOUTH a INNER JOIN
	      REFUNDOUTM c ON a.noteno = c.noteno
	WHERE (a.tag = 1) AND a.custno = @cust_no
	GROUP BY a.custno, a.notedate
	) a
	where a.notedate < @end_time
	order by a.notedate desc

open c

declare @temp_curr as money,
	@total_curr as money,
	@notedate as datetime

fetch next from c into @notedate, @temp_curr

--��ʼֵΪ�㣬����null ���κ�ֵ��Ϊnull
set @total_curr = 0

while @@fetch_status = 0
  begin
    set @total_curr = @total_curr + @temp_curr
    if @total_curr >= @rec_curr
      begin
        set @notedate = @notedate
        break
      end
    fetch next from c into @notedate, @temp_curr
  end

close c
DEALLOCATE c

return @notedate
end


' 
END

