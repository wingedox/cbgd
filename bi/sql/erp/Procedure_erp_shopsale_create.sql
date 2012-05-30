/****** Object:  StoredProcedure [erp_shopsale]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_shopsale]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_shopsale
CREATE procedure [dbo].[erp_shopsale]
	@sortColNo int,
	@sortType varchar(16),
	@saleDate_s datetime,
	@saleDate_e datetime,
	@dept_id varchar(32),--���ű��,�������Ʋ�ѯĳһ�����ŵ�Ӧ����,null����-1��ʾ������Ȩ�޷�Χ�ڵ����в���
	@operator integer --��ǰ�����˱�ţ�����ȷ�����ܲ�ѯ�Ŀⷿ�ķ�Χ
as

declare @deptID varchar(30)
declare @deptName varchar(128)
declare @receiveType char(1)
declare @saleBillType char(1)
declare @shouldPay numeric(12,4)
declare @havepay numeric(12,4)
declare @success int

declare @colName nvarchar(64)
declare @sql nvarchar(2048)
declare @sqlDeptScope nvarchar(2000) --���������ܹ���ѯ���Ĳ��ŵķ�Χ��Ӧ�Ĳ�ѯ���

set @sqlDeptScope = '' select dept_id ''+
	            '' from dept_user ''+
	            '' where emp_id='' + CAST(@operator as varchar)

--@successΪ0��ʾ�ɹ���Ϊ��0��ʾʧ��
set @success = 0

--��������������ۻ��ܵ���ʱ��
create table #shopsale
(
	shop_id varchar(30),
	shop_name varchar(128),
	total_money numeric(12,4),--�ܽ��
	cash_money numeric(12,4),--�ֽ�
	should_pay numeric(12,4),--Ӧ����
	have_pay numeric(12,4),--�Ѹ�����
	not_pay numeric(12,4),--Ƿ��
	return_money numeric(12,4),--�˻����
	sale_money numeric(12,4) --���۶�
)

--��ʼһ������
begin transaction

--��������������ۻ��ܵ���ʱ��
--�������۵���
--����������������š���������
set @sql = '' declare deptInfo_cursor cursor for ''+
	'' select dept_id,dept_name from dept_info where is_shop=''''Y''''''+
	'' and dept_id in ( '' +@sqlDeptScope + '') '' --��ʾ���������ܹ���ѯ�ⷿӦ���ʵķ�Χ

--��ѯĳһ���ض��ĵ���(����)
if((@dept_id is not null) and @dept_id <> ''-1'')
	set @sql = @sql + '' and dept_id ='''''' +  @dept_id + ''''''''

--��̬�����α�
execute(@sql)

open deptInfo_cursor

while(1=1)
begin
	--���α������м�������
	fetch next from deptInfo_cursor into @deptID,@deptName
	
	if(@@FETCH_STATUS<>0) break
	
	insert into #shopsale(shop_id,shop_name,total_money,cash_money,should_pay,have_pay,not_pay,return_money) 
	values(@deptID,@deptName,0,0,0,0,0,0)
	
	--��������г���
	if(@@ERROR<>0)
	begin
		set @success = @@ERROR
		break
	end;
	
	
end

close deptInfo_cursor
deallocate deptInfo_cursor


--�����������б�ŵĶ��ձ�
if(@sortColNo=1) set @colName = ''shop_id''
if(@sortColNo=2) set @colName = ''shop_name''
if(@sortColNo=3) set @colName = ''total_money''
if(@sortColNo=4) set @colName = ''cash_money''
if(@sortColNo=5) set @colName = ''should_pay''
if(@sortColNo=6) set @colName = ''have_pay''
if(@sortColNo=7) set @colName = ''not_pay''
if(@sortColNo=8) set @colName = ''return_money''
if(@sortColNo=9) set @colName = ''sale_money''

if(@success=0)
begin
	--�����α꣬�����ݿ��л��ܳ�������������
	--����������������š��������ơ��տʽ�����۵����͡��ֽ��ܶӦ�����ܶ�
	set @sql = ''declare shopsalelist_cursor cursor for ''+
		''select b.dept_id,b.dept_name, a.receiveType,sale_bill_type,a.sum_total_money,a.sum_receive_money ''+
		''from (select dept_id,sale_bill_type,ISNULL(receive_type,0)as receiveType,sum(total_money) as sum_total_money, ''+
		      		''ISNULL(sum(receive_money),0) as sum_receive_money  ''+
			'' from cash_sale_bill  ''+
			'' where status in(''''7'''',''''9'''',''''11'''',''''31'''',''''40'''') ''+
			'' and dept_id in ( '' +@sqlDeptScope + '') '' --��ʾ���������ܹ���ѯ�ⷿӦ���ʵķ�Χ

	if(@saleDate_s is not null)
		set @sql = @sql + '' and sale_date >= '''''' +  cast(@saleDate_s as varchar) + ''''''''

	if(@saleDate_e is not null)
		set @sql = @sql + '' and sale_date <= ''''''  + cast(@saleDate_e as varchar)  + ''''''''

	--��ѯĳһ���ض��ĵ���(����)
	if((@dept_id is not null) and @dept_id <> ''-1'')
		set @sql = @sql + '' and dept_id ='''''' +  @dept_id + ''''''''

	set @sql = @sql +  '' group by dept_id,sale_bill_type,receive_type ''+
		      	'') a, dept_info b '' +
		''where a.dept_id = b.dept_id  ''+
		''order by b.dept_name ''

	--��̬�����α�
	execute(@sql)
	
	open shopsalelist_cursor
	
	while(1=1)
	begin
		--���α������м�������
		fetch next from shopsalelist_cursor into @deptID,@deptName,@receiveType,@saleBillType,@shouldPay,@havePay		
		if(@@FETCH_STATUS<>0) break
		
	
		--����������д��#shopsale��ʱ����
		--�˻����������˻������		
		if(@saleBillType=''4'')
		begin
			update #shopsale set return_money=return_money+@shouldPay where shop_id=@deptID
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end
		else
		begin
			--�ֽ�
			if(@receiveType=''0'')
			begin
				update #shopsale set cash_money=cash_money+@shouldPay where shop_id=@deptID
				if(@@ERROR<>0)
				begin
					set @success = @@ERROR
					break
				end
			end
			else
			begin
				--��Ӧ����
				if(@receiveType=''1'')
				begin		
					update #shopsale set should_pay=should_pay+@shouldPay,have_pay=have_pay+@havePay where shop_id=@deptID
					if(@@ERROR<>0)
					begin
						set @success = @@ERROR
						break
					end
				end
			end
		end
	end
	
	close shopsalelist_cursor
	deallocate shopsalelist_cursor
	
end

--��������ܽ�Ƿ����
update #shopsale
set total_money = isnull(cash_money,0) + isnull(should_pay,0),
	not_pay=isnull(should_pay,0) - isnull(have_pay,0),
	sale_money = cash_money + should_pay - return_money --���۶�=�ֽ�+Ӧ����-�˻����

--�����Ƿ��ύ����
if(@success=0)
	commit
else
	rollback

set @sql = ''select shop_id,shop_name,isnull(total_money,0) as total_money,''+
	''isnull(cash_money,0) as cash_money,isnull(should_pay,0) as should_pay, ''+
	''isnull(have_pay,0) as have_pay,isnull(not_pay,0) as not_pay,return_money,sale_money ''+
	''from #shopsale order by '' + @colName + '' '' + @sortType

--execute sp_executesql @sql
execute(@sql)

--ɾ����ʱ��
drop table #shopsale



' 
END
