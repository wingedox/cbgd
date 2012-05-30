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
	@customer_name varchar(64),--客户名称，支持模糊查询
	@dept_id varchar(32),--部门编号,可以限制查询某一个部门的应收帐,null或者-1表示操作人权限范围内的所有部门
	@operator integer,--当前操作人编号，用于确定所能查询的库房的范围
	@record_date datetime,--日期
	@pay_status int,--付款情况：-1全部、0已经付清所有帐款、1没有付清帐款
	@flag char(1) --0表示去汇总数据；1仅去客户应收汇总的统计值
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
declare @sqlDeptScope nvarchar(2000) --操作人所能够查询到的部门的范围对应的查询语句

set @sqlDeptScope = '' select dept_id ''+
	            '' from dept_user ''+
	            '' where emp_id='' + CAST(@operator as varchar)


--@success为0表示成功、为非0表示失败
set @success = 0


--创建保存应收帐汇总的临时表
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

--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''customer_code''
if(@sortColNo=2) set @colName = ''customer_name''
if(@sortColNo=3) set @colName = ''should_receive''
if(@sortColNo=4) set @colName = ''have_receive''
if(@sortColNo=5) set @colName = ''return_money''
if(@sortColNo=6) set @colName = ''not_receive''

begin transaction

if(@success=0)
begin
	--定义游标，从数据库中汇总出店面的销售情况
	--结果集包括：店面编号、店面名称、收款方式、销售单类型、现金总额、应收帐总额
	set @sql = ''declare receive_account_cursor cursor for ''+
		''select a.customer_id,a.customer_code,a.customer_name,a.address,a.contact,a.tel,''+
		''b.operation_type_id,this_time_money ''+
		''from customers a,''+
			''(select aa.customer_id,aa.operation_type_id,sum(aa.this_time_money) as this_time_money ''+
			''from receive_account_detail aa,customers bb ''+
			''where aa.customer_id = bb.customer_id ''+
			'' and isnull(aa.del_flag,0)=0 '' + 
			'' and (aa.dept_id in ( '' +@sqlDeptScope + '') or isnull(aa.dept_id,''''-1'''')=''''-1'''') '' --显示操作人所能够查询库房应收帐的范围

	if(@record_date is not null)
		set @sql = @sql + '' and aa.record_date <= '''''' +  cast(@record_date as varchar) + ''''''''

	if((@customer_code is not null) and @customer_code <> '''')
		set @sql = @sql + '' and bb.customer_code like ''''%'' +  @customer_code + ''%''''''

	if((@customer_name is not null) and @customer_name <> '''')
		set @sql = @sql + '' and bb.customer_name like ''''%'' +  @customer_name + ''%''''''

	--查询某一个特定的店面(部门)
	if((@dept_id is not null) and @dept_id <> ''-1'')
		set @sql = @sql + '' and aa.dept_id ='''''' +  @dept_id + ''''''''

	set @sql = @sql + ''group by aa.customer_id,aa.operation_type_id) b ''+
		''where a.customer_id = b.customer_id order by a.customer_id''

	--动态创建游标
	execute(@sql)
	
	open receive_account_cursor
	
	while(1=1)
	begin
		--从游标结果集中检索数据
		fetch next from receive_account_cursor into @customerID,@customerCode,@customerName,
			@address,@contact,@tel,@operationTypeID,@thisTimeMoney		
		if(@@FETCH_STATUS<>0) break
		
		--判断是否存在该员工的记录，如果不存在就在数据库中增加一条员工记录
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

		--0期初数量，1应收帐两种情况之和记为应收帐
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
			if(@operationTypeID = 2) --销售收款
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
				if(@operationTypeID = 3) --退货充应收
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

--最后计算出总金额，欠款金额
update #receive_account
set not_receive=should_receive-have_receive-return_money

--决定是否提交数据
if(@success=0)
	commit
else
	rollback


set @sql = ''select customer_id,customer_code,customer_name,address,contact,tel,''+
	''should_receive,have_receive,return_money,not_receive ''+
	''from #receive_account ''

if(@pay_status=0)--已经清帐
	set @sql = @sql + '' where not_receive<=0 ''
else if(@pay_status=1)--还没有清帐
	set @sql = @sql + '' where not_receive>0 ''

set @sql = @sql + '' order by '' + @colName + '' '' + @sortType




--构造获取统计数据的SQL
if(@flag=''1'')
begin
	set @sql = ''select sum(should_receive) as should_receive,''+
		''sum(have_receive) as have_receive,sum(return_money) as return_money, ''+
		''sum(not_receive) as not_receive ''+
		''from #receive_account ''

	if(@pay_status=0)--已经清帐
		set @sql = @sql + '' where not_receive<=0 ''
	else if(@pay_status=1)--还没有清帐
		set @sql = @sql + '' where not_receive>0 ''
end

execute(@sql)

--删除临时表
drop table #receive_account



' 
END
