/****** Object:  StoredProcedure [erp_customersale]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_customersale]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_customersale
CREATE procedure [dbo].[erp_customersale]
	@sortColNo int,
	@sortType varchar(16),
	@saleDate_s datetime,
	@saleDate_e datetime,
	@custCode varchar(30),
	@custName varchar(64),
	@dept_id varchar(1024),--部门范围
	@flag char(1) ---标志：0列出所有客户的消费明细；1只计算客户消费汇总数据
as

declare @customerID int
declare @customerCode varchar(30)
declare @customerName varchar(128)
declare @address varchar(128)
declare @contact varchar(64)
declare @tel varchar(32)
declare @receiveType char(1)
declare @saleBillType char(1)
declare @shouldPay numeric(12,4)
declare @havepay numeric(12,4)

declare @success int

declare @colName nvarchar(64)
declare @sql nvarchar(2048)

--@success为0表示成功、为非0表示失败
set @success = 0

--创建保存店面销售汇总的临时表
create table #customersale
(
	customer_id int,
	customer_code varchar(30),
	customer_name varchar(128),
	address varchar(128),
	contact varchar(64),
	tel varchar(32),
	total_money numeric(12,4),--总金额
	cash_money numeric(12,4),--现金
	should_pay numeric(12,4),--应收帐
	have_pay numeric(12,4),--已付款金额
	not_pay numeric(12,4),--欠款
	return_money numeric(12,4),--退货金额
	sale_money numeric(12,4) --销售额
)

--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''customer_code''
if(@sortColNo=2) set @colName = ''customer_name''
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
	--结果集包括：客户流水号、客户编号、客户名称、客户地址、联系方式、收款方式、销售单类型、现金总额、应收帐总额
	set @sql = ''declare customer_salelist_cursor cursor for ''+
		''select a.customer_id,b.customer_code,b.customer_name,b.address,b.contact,b.tel,''+
		''a.receiveType,sale_bill_type,a.sum_total_money,a.sum_receive_money ''+
		''from (select customer_id,sale_bill_type,ISNULL(receive_type,0)as receiveType,sum(total_money) as sum_total_money, ''+
		      		''ISNULL(sum(receive_money),0) as sum_receive_money  ''+
		      ''from cash_sale_bill  ''+
		      ''where status in(''''7'''',''''9'''',''''11'''',''''31'''',''''40'''')  ''

	if(@saleDate_s is not null)
		set @sql = @sql + '' and sale_date >= '''''' +  cast(@saleDate_s as varchar) + ''''''''

	if(@saleDate_e is not null)
		set @sql = @sql + '' and sale_date <= ''''''  + cast(@saleDate_e as varchar)  + ''''''''
	if(@dept_id is not null)
		set @sql = @sql + '' and dept_id in ('' +  @dept_id + '') ''



	set @sql = @sql +  '' group by customer_id,sale_bill_type,receive_type ''+
		      	'') a, customers b '' +
		''where a.customer_id = b.customer_id ''

	if(@custCode is not null)
		set @sql = @sql + '' and b.customer_code like ''''%''  + @custCode  + ''%''''''

	if(@custName is not null)
		set @sql = @sql + '' and b.customer_name like ''''%''  + @custName  + ''%''''''

	set @sql = @sql + ''order by b.customer_id ''

	--动态创建游标
	execute(@sql)

	open customer_salelist_cursor
	
	while(1=1)
	begin
		--从游标结果集中检索数据
		fetch next from customer_salelist_cursor into @customerID,@customerCode,@customerName,@address,@contact,@tel,
					@receiveType,@saleBillType,@shouldPay,@havePay
		
		if(@@FETCH_STATUS<>0) break
		
		--判断是否存在该员工的记录，如果不存在就在数据库中增加一条员工记录
		if(select count(customer_id) from #customersale where customer_id=@customerID)=0
		begin
			insert into #customersale(customer_id,customer_code,customer_name,address,contact,tel,
				total_money,cash_money,should_pay,have_pay,not_pay,return_money,sale_money) 
			values(@customerID,@customerCode,@customerName,@address,@contact,@tel,0,0,0,0,0,0,0)
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
			update #customersale set return_money=return_money+@shouldPay where customer_id=@customerID
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
				update #customersale set cash_money=cash_money+@shouldPay where customer_id=@customerID 
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
					update #customersale set should_pay=should_pay+@shouldPay,have_pay=have_pay+@havePay where customer_id=@customerID 
					if(@@ERROR<>0)
					begin
						set @success = @@ERROR
						break
					end
				end
			end
		end
	end
	
	close customer_salelist_cursor
	deallocate customer_salelist_cursor
	
end

--最后计算出总金额，欠款金额
update #customersale
set total_money = isnull(cash_money,0) + isnull(should_pay,0),
	not_pay=isnull(should_pay,0) - isnull(have_pay,0),
	sale_money = cash_money + should_pay - return_money --销售额=现金+应收帐-退货金额

--决定是否提交数据
if(@success=0)
	commit
else
	rollback

set @sql = ''select customer_id,customer_code,customer_name,address,contact,tel,isnull(total_money,0) as total_money,''+
	''isnull(cash_money,0) as cash_money,isnull(should_pay,0) as should_pay, ''+
	''isnull(have_pay,0) as have_pay,isnull(not_pay,0) as not_pay,return_money,sale_money ''+
	''from #customersale order by '' + @colName + '' '' + @sortType

--构造获取统计数据的SQL
if(@flag=''1'')
	set @sql = ''select sum(total_money) as total_money,''+
		''sum(cash_money) as cash_money,sum(should_pay) as should_pay, ''+
		''sum(have_pay) as have_pay,sum(not_pay) as not_pay,sum(return_money) as return_money, ''+
		''sum(sale_money) as sale_money ''+
		''from #customersale ''


execute(@sql)

--删除临时表
drop table #customersale



' 
END
