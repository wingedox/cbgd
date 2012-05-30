/****** Object:  Trigger [deptcheckwareinh]    Script Date: 01/13/2012 04:54:35 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[deptcheckwareinh]'))
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
