/****** Object:  Trigger [deptcheckwareouth]    Script Date: 01/14/2012 16:11:02 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareouth]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
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
