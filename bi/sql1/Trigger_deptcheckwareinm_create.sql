/****** Object:  Trigger [deptcheckwareinm]    Script Date: 01/13/2012 04:54:36 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[deptcheckwareinm]'))
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareinm
on dbo.WAREINM
for insert,update
as
begin
--�����ⵥԼ��
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
    raiserror(''�ֿ�Ͳ��Ų���'',16,1)
    return
  end 

select @oldnoteno=noteno from deleted
select @newnoteno=noteno from inserted
if @oldnoteno <> @newnoteno
    raiserror(''�״��޸Ĳ��ɹ�����ȡ�������޸ģ�'',16,1)
end
' 
