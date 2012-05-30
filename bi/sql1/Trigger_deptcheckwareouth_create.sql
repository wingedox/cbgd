/****** Object:  Trigger [deptcheckwareouth]    Script Date: 01/13/2012 04:54:36 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[deptcheckwareouth]'))
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareouth
on dbo.wareouth
for insert,update
as
begin
declare @deptcust as varchar(2),
	@depthouse as varchar(2),
	@dept as varchar(2)

select @deptcust=substring(custno,1,2),@depthouse=substring(houseno,1,2),@dept=substring(dptno,1,2) from inserted
if @deptcust <> @dept
  begin
    raiserror(''客户和部门不符'',16,1)
    return
  end

if @depthouse <> @dept
  begin
    raiserror(''仓库和部门不符'',16,1)
    return
  end 

end
' 
