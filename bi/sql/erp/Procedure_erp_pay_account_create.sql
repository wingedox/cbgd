/****** Object:  StoredProcedure [erp_pay_account]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_pay_account]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_pay_account
CREATE procedure [dbo].[erp_pay_account]
	@sortColNo int,
	@sortType varchar(16),
	@provider_code varchar(32),
	@provider_name varchar(64),--客户名称，支持模糊查询
	@storeroom_id integer,--库房编号,可以限制查询某一个库房的应付帐,null或者-1表示操作人权限范围内的所有库房
	@operator integer,--当前操作人编号，用于确定所能查询的库房的范围
	@record_date datetime,--日期
	@pay_status int,--付款情况：-1全部、0已经付清所有帐款、1没有付清帐款
	@flag char(1) --0表示去汇总数据；1仅去客户应收汇总的统计值
as

declare @providerID int
declare @providerCode varchar(32)
declare @providerName varchar(128)
declare @address varchar(128)
declare @tel varchar(30)
declare @contact varchar(40)
declare @payTypeID int
declare @thisTimeMoney numeric(12,4)


declare @success int
declare @colName nvarchar(64)
declare @sql nvarchar(4000)
declare @sqlStoreRoomScope nvarchar(2000) --操作人所能够查询到的库房的范围对应的查询语句

set @sqlStoreRoomScope = '' select storeroom_id ''+
	                 '' from storeroom_user ''+
	                 '' where emp_id='' + CAST(@operator as varchar)


--@success为0表示成功、为非0表示失败
set @success = 0


--创建保存应收帐汇总的临时表
create table #pay_account
(
	provider_id int,
	provider_code varchar(32),
	provider_name varchar(128),
	address varchar(128),
	contact varchar(30),
	tel varchar(30),
	should_pay numeric(12,4),
	have_pay numeric(12,4),
	return_money numeric(12,4),
	not_pay numeric(12,4)
)

--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''provider_code''
if(@sortColNo=2) set @colName = ''provider_name''
if(@sortColNo=3) set @colName = ''should_pay''
if(@sortColNo=4) set @colName = ''have_pay''
if(@sortColNo=5) set @colName = ''return_money''
if(@sortColNo=6) set @colName = ''not_pay''

begin transaction

if(@success=0)
begin
	--定义游标，从数据库中汇总出店面的销售情况
	--结果集包括：供应商流水号、供应商编号、供应商名称、地址、联系人、联系电话、交易摘要、金额
	set @sql = ''declare pay_account_cursor cursor for ''+
		''select a.provider_id,a.provider_code,a.provider_name,a.address,a.contact,a.tel,''+
		''b.pay_type_id,this_time_money ''+
		''from goods_provider a,''+
			'' (select aa.provider_id,aa.pay_type_id,sum(aa.this_time_money) as this_time_money ''+
			'' from pay_account_detail aa,goods_provider bb ''+
			'' where aa.provider_id = bb.provider_id '' +
			'' and isnull(aa.del_flag,0)=0 '' + 
			'' and (aa.storeroom_id in ( '' +@sqlStoreRoomScope + '') or isnull(aa.storeroom_id,0)=0)'' --显示操作人所能够查询库房应付帐的范围

	if(@record_date is not null)
		set @sql = @sql + '' and aa.record_date <= '''''' +  cast(@record_date as varchar) + ''''''''

	if((@provider_code is not null) and @provider_code <> '''')
		set @sql = @sql + '' and bb.provider_code like ''''%'' +  @provider_code + ''%''''''

	if((@provider_name is not null) and @provider_name <> '''')
		set @sql = @sql + '' and bb.provider_name like ''''%'' +  @provider_name + ''%''''''

	--查询某一个特定的库房
	if((@storeroom_id is not null) and @storeroom_id <> ''-1'')
		set @sql = @sql + '' and aa.storeroom_id ='' +  CAST(@storeroom_id as varchar)
	

	set @sql = @sql + ''group by aa.provider_id,aa.pay_type_id) b ''+
		''where a.provider_id = b.provider_id order by a.provider_id''

	--动态创建游标
	execute(@sql)
	
	open pay_account_cursor
	
	while(1=1)
	begin
		--从游标结果集中检索数据
		fetch next from pay_account_cursor into @providerID,@providerCode,@providerName,
			@address,@contact,@tel,@payTypeID,@thisTimeMoney		
		if(@@FETCH_STATUS<>0) break
		
		--判断是否存在该供应商的记录，如果不存在就在数据库中增加一条供应商记录
		if((select count(provider_id) from #pay_account where provider_id=@providerID)=0)
		begin
			insert into #pay_account(provider_id,provider_code,provider_name,address,contact,tel,
				should_pay,have_pay,return_money,not_pay) 
			values(@providerID,@providerCode,@providerName,@address,@contact,@tel,0,0,0,0)
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end

		--0期初金额，1应付帐两种情况之和记为应付帐
		if(@payTypeID in(0,1))
		begin
			update #pay_account set should_pay=should_pay+@thisTimeMoney where provider_id=@providerID
			if(@@ERROR<>0)
			begin
				set @success = @@ERROR
				break
			end
		end
		else
		begin
			if(@payTypeID = 2) --采购付款
			begin
				update #pay_account set have_pay=have_pay+@thisTimeMoney where provider_id=@providerID
				if(@@ERROR<>0)
				begin
					set @success = @@ERROR
					break
				end
			end
			else
			begin
				if(@payTypeID = 3) --退货冲应付
				begin
					update #pay_account set return_money=return_money+@thisTimeMoney where provider_id=@providerID
					if(@@ERROR<>0)
					begin
						set @success = @@ERROR
						break
					end
				end
			end
		end

	end
	
	close pay_account_cursor
	deallocate pay_account_cursor
	
end

--最后计算出总金额，欠款金额
update #pay_account
set not_pay=should_pay-have_pay-return_money

--决定是否提交数据
if(@success=0)
	commit
else
	rollback

set @sql = '' select provider_id,provider_code,provider_name,address,contact,tel,''+
	'' should_pay,have_pay,return_money,not_pay ''+
	'' from #pay_account ''

if(@pay_status=0)--已经清帐
	set @sql = @sql + '' where not_pay<=0 ''
else if(@pay_status=1)--还没有清帐
	set @sql = @sql + '' where not_pay>0 ''

set @sql = @sql + '' order by '' + @colName + '' '' + @sortType

--构造获取统计数据的SQL
if(@flag=''1'')
begin
	set @sql = ''select sum(should_pay) as should_pay,''+
		''sum(have_pay) as have_pay,sum(return_money) as return_money, ''+
		''sum(not_pay) as not_pay ''+
		''from #pay_account ''

	if(@pay_status=0)--已经清帐
		set @sql = @sql + '' where not_pay<=0 ''
	else if(@pay_status=1)--还没有清帐
		set @sql = @sql + '' where not_pay>0 ''
end

execute(@sql)

--删除临时表
drop table #pay_account



' 
END
