/****** Object:  Trigger [deptcheckwareinm]    Script Date: 01/14/2012 16:10:57 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareinm]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareinm
on dbo.WAREINM
for insert,update
as
begin
--检查入库单约束
declare @deptcust as varchar(2),
	@depthouse as varchar(2),
	@dept as varchar(2),
	@noteno as varchar(15),
	@oldnoteno as varchar(15),
	@newnoteno as varchar(15),
	@maxnoteno as varchar(15),
	@maxno as int

select @noteno=noteno from inserted

select @depthouse=substring(houseno,1,2),@dept=substring(dptno,1,2) 
from wareinh where noteno=@noteno

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
