/****** Object:  Trigger [deptcheckwareoutm]    Script Date: 01/14/2012 16:11:09 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareoutm]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
EXEC dbo.sp_executesql @statement = N'create trigger deptcheckwareoutm
on dbo.WAREOUTM
for insert,update
as
begin
--������Լ��
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
    raiserror(''�ͻ��Ͳ��Ų���'',16,1)
    return
  end

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
