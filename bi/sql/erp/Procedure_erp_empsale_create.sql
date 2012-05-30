/****** Object:  StoredProcedure [erp_empsale]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_empsale]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_empsale
CREATE procedure [dbo].[erp_empsale]
	@sortColNo int,
	@sortType varchar(16),
	@saleDate_s datetime,
	@saleDate_e datetime,
	@dept_id varchar(1024),--部门范围
	@emp_name varchar(64),
	@flag char(1) ---标志：0列出所有客户的消费明细；1只计算客户消费汇总数据
as

declare @empID varchar(30)
declare @empName varchar(16)
declare @deptID varchar(30)
declare @deptName varchar(128)
declare @receiveType char(1)
declare @saleBillType char(1)	--销售单类型
declare @shouldPay numeric(12,4)
declare @havepay numeric(12,4)
declare @success int

declare @colName nvarchar(64)
declare @sql nvarchar(2048)

--@success为0表示成功、为非0表示失败
set @success = 0

--创建保存店面销售汇总的临时表
create table #empsale
(
	emp_id int,
	emp_name varchar(16),
	dept_id varchar(30),	--部门编号
	dept_name varchar(128),	--部门名称
	total_money numeric(12,4),--总金额
	cash_money numeric(12,4),--现金
	should_pay numeric(12,4),--应收帐
	have_pay numeric(12,4),--已付款金额
	not_pay numeric(12,4),--欠款
	return_money numeric(12,4),--退货金额
	sale_money numeric(12,4) --销售额
)

--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''emp_id''
if(@sortColNo=2) set @colName = ''emp_name''
if(@sortColNo=3) set @colName = ''total_money''
if(@sortColNo=4) set @colName = ''cash_money''
if(@sortColNo=5) set @colName = ''should_pay''
if(@sortColNo=6) set @colName = ''have_pay''
if(@sortColNo=7) set @colName = ''not_pay''
if(@sortColNo=8) set @colName = ''return_money''
if(@sortColNo=9) set @colName = ''sale_money''

--开始一个事务
begin transaction


if(@success=0)
begin
	--定义游标，从数据库中汇总出员工的销售情况
	--结果集包括：员工编号、员工姓名、收款方式、收款方式、销售单类型、现金总额、应收帐总额
	set @sql = ''declare emp_salelist_cursor cursor for ''+
		''select b.emp_id,b.emp_name,c.dept_id,c.dept_name,a.receiveType,sale_bill_type,''+
		''a.sum_total_money,a.sum_receive_money ''+
		''from (select sale_man as emp_id,dept_id,sale_bill_type,ISNULL(receive_type,0)as receiveType,sum(total_money) as sum_total_money, ''+
		      		''ISNULL(sum(receive_money),0) as sum_receive_money  ''+
		      ''from cash_sale_bill  ''+
		      ''where status in(''''7'''',''''9'''',''''11'''',''''31'''',''''40'''') ''

	if(@saleDate_s is not null)
		set @sql = @sql + '' and sale_date >= '''''' +  cast(@saleDate_s as varchar) + ''''''''

	if(@saleDate_e is not null)
		set @sql = @sql + '' and sale_date <= ''''''  + cast(@saleDate_e as varchar)  + ''''''''

	if(@dept_id is not null)
		set @sql = @sql + '' and dept_id in ('' +  @dept_id + '') ''


	set @sql = @sql +  '' group by sale_man,dept_id,sale_bill_type,receive_type ''+
		      	'') a, emp_info b,dept_info c '' +
		''where a.emp_id = b.emp_id  and a.dept_id = c.dept_id ''

	if(@emp_name is not null)
		set @sql = @sql + '' and b.emp_name like ''''%''  + @emp_name  + ''%'''' ''

	set @sql = @sql + ''order by b.emp_id ''

	--动态创建游标
	execute(@sql)

	open emp_salelist_cursor
	
	while(1=1)
	begin
		--从游标结果集中检索数据
		fetch next from emp_salelist_cursor into @empID,@empName,@deptID,@deptName,@receiveType,
				@saleBillType,@shouldPay,@havePay
		
		if(@@FETCH_STATUS<>0) break
		
		--判断是否存在该员工的记录，如果不存在就在数据库中增加一条员工记录
		if((select count(emp_id) from #empsale where emp_id=@empID and dept_id=@deptID)=0)
		begin
			insert into #empsale(emp_id,emp_name,dept_id,dept_name,total_money,cash_money,
				should_pay,have_pay,not_pay,return_money,sale_money) 
			values(@empID,@empName,@deptID,@deptName,0,0,0,0,0,0,0)
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end

		--将汇总数据写入#empsale临时表中
		--退货单，记入退货金额中		
		if(@saleBillType=''4'')
		begin
			--是退货单，将金额加到退货金额栏位
			update #empsale set return_money=return_money+@shouldPay where emp_id=@empID and dept_id=@deptID
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end
		else
		begin
			--现金
			if(@receiveType=''0'')
			begin
				update #empsale set cash_money=cash_money+@shouldPay where emp_id=@empID and dept_id=@deptID
				if(@@ERROR<>0)
				begin
					set @success = @@ERROR
					break
				end
			end
			else
			begin
				--挂应收帐
				if(@receiveType=''1'')
				begin		
					update #empsale set should_pay=should_pay+@shouldPay,have_pay=have_pay+@havePay where emp_id=@empID and dept_id=@deptID
					if(@@ERROR<>0)
					begin
						set @success = @@ERROR
						break
					end
				end
			end
		end	
	end
	
	close emp_salelist_cursor
	deallocate emp_salelist_cursor
	
end

--最后计算出总金额，欠款金额
update #empsale
set total_money = isnull(cash_money,0) + isnull(should_pay,0),
	not_pay=isnull(should_pay,0) - isnull(have_pay,0),
	sale_money = cash_money + should_pay - return_money --销售额=现金+应收帐-退货金额

--决定是否提交数据
if(@success=0)
	commit
else
	rollback

set @sql = ''select emp_id,emp_name,dept_id,dept_name,isnull(total_money,0) as total_money,''+
	''isnull(cash_money,0) as cash_money,isnull(should_pay,0) as should_pay, ''+
	''isnull(have_pay,0) as have_pay,isnull(not_pay,0) as not_pay,return_money,sale_money ''+
	''from #empsale order by '' + @colName + '' '' + @sortType


--构造获取统计数据的SQL
if(@flag=''1'')
	set @sql = ''select sum(total_money) as total_money,''+
		''sum(cash_money) as cash_money,sum(should_pay) as should_pay, ''+
		''sum(have_pay) as have_pay,sum(not_pay) as not_pay,sum(return_money) as return_money, ''+
		''sum(sale_money) as sale_money ''+
		''from #empsale ''

execute(@sql)

--删除临时表
drop table #empsale



' 
END
