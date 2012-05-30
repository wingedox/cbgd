/****** Object:  Trigger [deptcheckwareinh]    Script Date: 01/14/2012 16:10:53 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareinh]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareinh
on dbo.wareinh
for update
as
begin
declare @depthouse as varchar(2),
	@dept as varchar(2)

select @depthouse=substring(houseno,1,2),@dept=substring(dptno,1,2) from inserted

if @depthouse <> @dept
  begin
    raiserror(''仓库和部门不符'',16,1)
    return
  end 

end
' 
