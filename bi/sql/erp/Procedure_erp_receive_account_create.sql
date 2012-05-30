/****** Object:  StoredProcedure [erp_receive_account]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_receive_account]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_receive_account
CREATE procedure [dbo].[erp_receive_account]
	@sortColNo int,
	@sortType varchar(16),
	@customer_code varchar(32),
	@customer_name varchar(64),--�ͻ����ƣ�֧��ģ����ѯ
	@dept_id varchar(32),--���ű��,�������Ʋ�ѯĳһ�����ŵ�Ӧ����,null����-1��ʾ������Ȩ�޷�Χ�ڵ����в���
	@operator integer,--��ǰ�����˱�ţ�����ȷ�����ܲ�ѯ�Ŀⷿ�ķ�Χ
	@record_date datetime,--����
	@pay_status int,--���������-1ȫ����0�Ѿ����������ʿ1û�и����ʿ�
	@flag char(1) --0��ʾȥ�������ݣ�1��ȥ�ͻ�Ӧ�ջ��ܵ�ͳ��ֵ
as

declare @customerID int
declare @customerCode varchar(32)
declare @customerName varchar(128)
declare @address varchar(128)
declare @tel varchar(30)
declare @contact varchar(40)
declare @operationTypeID int
declare @thisTimeMoney numeric(12,4)


declare @success int
declare @colName nvarchar(64)
declare @sql nvarchar(2048)
declare @sqlDeptScope nvarchar(2000) --���������ܹ���ѯ���Ĳ��ŵķ�Χ��Ӧ�Ĳ�ѯ���

set @sqlDeptScope = '' select dept_id ''+
	            '' from dept_user ''+
	            '' where emp_id='' + CAST(@operator as varchar)


--@successΪ0��ʾ�ɹ���Ϊ��0��ʾʧ��
set @success = 0


--��������Ӧ���ʻ��ܵ���ʱ��
create table #receive_account
(
	customer_id int,
	customer_code varchar(32),
	customer_name varchar(128),
	address varchar(128),
	contact varchar(30),
	tel varchar(30),
	should_receive numeric(12,4),
	have_receive numeric(12,4),
	return_money numeric(12,4),
	not_receive numeric(12,4)
)

--�����������б�ŵĶ��ձ�
if(@sortColNo=1) set @colName = ''customer_code''
if(@sortColNo=2) set @colName = ''customer_name''
if(@sortColNo=3) set @colName = ''should_receive''
if(@sortColNo=4) set @colName = ''have_receive''
if(@sortColNo=5) set @colName = ''return_money''
if(@sortColNo=6) set @colName = ''not_receive''

begin transaction

if(@success=0)
begin
	--�����α꣬�����ݿ��л��ܳ�������������
	--����������������š��������ơ��տʽ�����۵����͡��ֽ��ܶӦ�����ܶ�
	set @sql = ''declare receive_account_cursor cursor for ''+
		''select a.customer_id,a.customer_code,a.customer_name,a.address,a.contact,a.tel,''+
		''b.operation_type_id,this_time_money ''+
		''from customers a,''+
			''(select aa.customer_id,aa.operation_type_id,sum(aa.this_time_money) as this_time_money ''+
			''from receive_account_detail aa,customers bb ''+
			''where aa.customer_id = bb.customer_id ''+
			'' and isnull(aa.del_flag,0)=0 '' + 
			'' and (aa.dept_id in ( '' +@sqlDeptScope + '') or isnull(aa.dept_id,''''-1'''')=''''-1'''') '' --��ʾ���������ܹ���ѯ�ⷿӦ���ʵķ�Χ

	if(@record_date is not null)
		set @sql = @sql + '' and aa.record_date <= '''''' +  cast(@record_date as varchar) + ''''''''

	if((@customer_code is not null) and @customer_code <> '''')
		set @sql = @sql + '' and bb.customer_code like ''''%'' +  @customer_code + ''%''''''

	if((@customer_name is not null) and @customer_name <> '''')
		set @sql = @sql + '' and bb.customer_name like ''''%'' +  @customer_name + ''%''''''

	--��ѯĳһ���ض��ĵ���(����)
	if((@dept_id is not null) and @dept_id <> ''-1'')
		set @sql = @sql + '' and aa.dept_id ='''''' +  @dept_id + ''''''''

	set @sql = @sql + ''group by aa.customer_id,aa.operation_type_id) b ''+
		''where a.customer_id = b.customer_id order by a.customer_id''

	--��̬�����α�
	execute(@sql)
	
	open receive_account_cursor
	
	while(1=1)
	begin
		--���α������м�������
		fetch next from receive_account_cursor into @customerID,@customerCode,@customerName,
			@address,@contact,@tel,@operationTypeID,@thisTimeMoney		
		if(@@FETCH_STATUS<>0) break
		
		--�ж��Ƿ���ڸ�Ա���ļ�¼����������ھ������ݿ�������һ��Ա����¼
		if((select count(customer_id) from #receive_account where customer_id=@customerID)=0)
		begin
			insert into #receive_account(customer_id,customer_code,customer_name,address,contact,tel,
				should_receive,have_receive,return_money,not_receive) 
			values(@customerID,@customerCode,@customerName,@address,@contact,@tel,0,0,0,0)
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end

		--0�ڳ�������1Ӧ�����������֮�ͼ�ΪӦ����
		if(@operationTypeID in(0,1))
		begin
			update #receive_account set should_receive=should_receive+@thisTimeMoney where customer_id=@customerID
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end
		else
		begin
			if(@operationTypeID = 2) --�����տ�
			begin
				update #receive_account set have_receive=have_receive+@thisTimeMoney where customer_id=@customerID
				if(@@ERROR<>0)
				begin
					set @success = @@ERROR
					break
				end
			end
			else
			begin
				if(@operationTypeID = 3) --�˻���Ӧ��
				begin
					update #receive_account set return_money=return_money+@thisTimeMoney where customer_id=@customerID
					if(@@ERROR<>0)
					begin
						set @success = @@ERROR
						break
					end
				end
			end
		end

	end
	
	close receive_account_cursor
	deallocate receive_account_cursor
	
end

--��������ܽ�Ƿ����
update #receive_account
set not_receive=should_receive-have_receive-return_money

--�����Ƿ��ύ����
if(@success=0)
	commit
else
	rollback


set @sql = ''select customer_id,customer_code,customer_name,address,contact,tel,''+
	''should_receive,have_receive,return_money,not_receive ''+
	''from #receive_account ''

if(@pay_status=0)--�Ѿ�����
	set @sql = @sql + '' where not_receive<=0 ''
else if(@pay_status=1)--��û������
	set @sql = @sql + '' where not_receive>0 ''

set @sql = @sql + '' order by '' + @colName + '' '' + @sortType




--�����ȡͳ�����ݵ�SQL
if(@flag=''1'')
begin
	set @sql = ''select sum(should_receive) as should_receive,''+
		''sum(have_receive) as have_receive,sum(return_money) as return_money, ''+
		''sum(not_receive) as not_receive ''+
		''from #receive_account ''

	if(@pay_status=0)--�Ѿ�����
		set @sql = @sql + '' where not_receive<=0 ''
	else if(@pay_status=1)--��û������
		set @sql = @sql + '' where not_receive>0 ''
end

execute(@sql)

--ɾ����ʱ��
drop table #receive_account



' 
END
