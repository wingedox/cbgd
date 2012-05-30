/****** Object:  Trigger [deptcheckwareoutm]    Script Date: 01/13/2012 04:54:36 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[deptcheckwareoutm]'))
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareoutm
on dbo.WAREOUTM
for insert,update
as
begin
--检查出库约束
declare @deptcust as varchar(2),
	@depthouse as varchar(2),
	@dept as varchar(2),
	@noteno as varchar(15),
	@oldnoteno as varchar(15),
	@newnoteno as varchar(15)

select @noteno=noteno from inserted

select @deptcust=substring(custno,1,2),@depthouse=substring(houseno,1,2),@dept=substring(dptno,1,2) 
from wareouth where noteno=@noteno

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

select @oldnoteno=noteno from deleted
select @newnoteno=noteno from inserted
if @oldnoteno <> @newnoteno
    raiserror(''首次修改不成功，请取消重新修改！'',16,1)

end
' 
