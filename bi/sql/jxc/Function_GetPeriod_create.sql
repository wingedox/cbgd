/****** Object:  UserDefinedFunction [GetPeriod]    Script Date: 01/14/2012 16:11:13 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetPeriod]') AND xtype in (N'FN', N'IF', N'TF'))
BEGIN
execute dbo.sp_executesql @statement = N'-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetPeriod](@date datetime, @tag varchar(1)) 
RETURNS varchar(10)
AS
BEGIN

	declare @periodDay varchar(2),
			@currentMonth varchar(2),
			@currentYear varchar(4)

	set @periodDay = (select uValue from uParameter where usection=''OPTIONS'' and uSymbol=''ENDDAY'')

	if (day(@date) > @periodDay)
		begin
			set @currentMonth = month(@date)
			set @currentYear = year(@date)
		end
	else
		begin
			set @currentMonth = month(@date) - 1
			if @currentMonth = 0 
				begin
					set @currentYear = year(@date) - 1
					set @currentMonth = 12
				end
			else
				begin
					set @currentYear = year(@date)
				end
		end
	if(@currentMonth < 10)
		begin
			set @currentMonth = '' '' + @currentMonth
		end

	if (@tag = 1)
		begin
			declare @lastDay varchar(2),
					@lastDate datetime
					
			set @lastDay = day(dateadd(dd, -1, dateadd(mm,1,cast((@currentYear + ''-'' + @currentMonth + ''-01'') as datetime))))

			if(@periodDay >= @lastDay)
				begin
					set @lastDate = cast((@currentYear + ''-'' + cast((@currentMonth) as varchar(2)) + ''-'' + @lastDay) as datetime)
				end
			else
				begin
					set @lastDate = cast((@currentYear + ''-'' + cast((@currentMonth) as varchar(2)) + ''-'' + @periodDay) as datetime)
				end

			set @lastDate = dateadd(dd, 1, @lastDate)
			return cast(year(@lastDate) as varchar(4)) + ''-'' + cast(month(@lastDate) as varchar(2)) + ''-'' + cast(day(@lastDate) as varchar(2))
		end
	
	return @currentYear + @currentMonth
END' 
END

