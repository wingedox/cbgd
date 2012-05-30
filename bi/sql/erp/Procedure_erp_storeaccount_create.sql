/****** Object:  StoredProcedure [erp_storeaccount]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_storeaccount]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_storeaccount
CREATE procedure [dbo].[erp_storeaccount]
	@storeroom_scope varchar(1024),
	@storeroom_id varchar(30),
	@date_s datetime,
	@date_e datetime,
	@good_code varchar(32),
	@good_name varchar(128),
	@categoryScope varchar(2048),--商品分类范围
	@categoryID varchar(32)--商品分类
as

declare @goodID int
declare @goodCode varchar(32)
declare @goodSpec varchar(256)
declare @unitName varchar(8)
declare @initNums int
declare @initMoney numeric(12,4)
declare @inNums int
declare @inMoney numeric(12,4)
declare @outNums int
declare @outMoney numeric(12,4)
declare @stockNums int
declare @stockMoney numeric(12,4)


declare @success int

declare @sql nvarchar(4000)
declare @sql1 nvarchar(4000)

--创建保库存总帐的临时表
create table #storeaccount
(
	good_id int,
	good_code varchar(32),
	good_spec varchar(256),
	unit_name varchar(32),
	init_nums int,
	init_money numeric(12,4),
	in_nums int,
	in_money numeric(12,4),
	out_nums int,
	out_money numeric(12,4),
	stock_nums int,
	stock_money numeric(12,4)
)

set @success = 0

--开始一个事务
begin transaction

set @sql = ''declare storeaccount_cursor cursor for ''
set @sql = @sql + ''select b.id as good_id,b.good_id as good_code,''+
           ''b.spec_info as good_spec,b.unit_name,''+
           ''isnull(a.in_nums,0) as in_nums,''+
           ''isnull(a.in_money,0) as in_money,''+
           ''isnull(a.out_nums,0) as out_nums,''+
           ''isnull(a.out_money,0) as out_money ''+
           ''from ''+
           ''(select aa.good_id,sum(aa.in_nums) as in_nums, ''+
           	''sum(aa.in_nums*aa.price) as in_money,''+
           	''sum(aa.out_nums) as out_nums,''+
           	''sum(aa.out_nums*aa.price) as out_money ''+
           	''from store_goods_exchange aa,goods_info bb where aa.good_id=bb.id ''

if((@date_s is not null) and (@date_s<>''''))
	set @sql = @sql + '' and aa.bill_date >= '''''' +  cast(@date_s as varchar) + ''''''''

if((@date_e is not null) and (@date_e<>''''))
	set @sql = @sql + '' and aa.bill_date <= ''''''  + cast(@date_e as varchar)  + ''''''''

if(@categoryScope is not null and @categoryScope <> '''')
	set @sql = @sql + '' and bb.category_id in ('' +  @categoryScope + '') ''

if(@categoryID is not null and @categoryID <> '''')
	set @sql = @sql + '' and bb.category_id like ''''''  + @categoryID  + ''%'''' ''

--set @sql = @sql + '' and storeroom_id in ('' + @storeroom_scope + '') ''
--if((@storeroom_id <> ''000000'') and (@storeroom_id <> ''''))
	set @sql = @sql + '' and aa.storeroom_id ='' + @storeroom_id

set @sql = @sql + '' group by aa.good_id ) a,erp_goods_info b,''

set @sql = @sql + '' (select distinct good_id from store_day_check where 1=1 ''
if((@date_e is not null) and (@date_e<>''''))
	set @sql = @sql + '' and check_date<=''''''  + cast(@date_e as varchar)  + ''''''''

--限定操作人所能查询的库房范围
--set @sql = @sql + '' and storeroom_id in ('' + @storeroom_scope + '') ''
--if((@storeroom_id <> ''000000'') and (@storeroom_id <> ''''))
	set @sql = @sql + '' and storeroom_id ='' + @storeroom_id

set @sql = @sql + '' ) d ''+
	''where d.good_id = b.id and ''+
	''d.good_id *= a.good_id ''

if(@good_code != '''')
	set @sql = @sql + '' and b.good_id like ''''%'' + @good_code + ''%'''' '';
if(@good_name != '''')
	set @sql = @sql + '' and b.good_name like ''''%'' + @good_name + ''%'''' '';

--动态创建游标
execute(@sql)

set @sql1 = ''declare init_cursor cursor for ''
set @sql1 = @sql1 + '' select top 1 stock_nums as init_nums,stock_money as init_money from store_day_check '';
if((@date_s is not null) and (@date_s<>''''))
	set @sql1 = @sql1 + '' where check_date < '''''' +  cast(@date_s as varchar) + '''''' ''
else
	set @sql1 = @sql1 + '' where check_date < (select min(check_date) from store_day_check) ''

--限定操作人所能查询的库房范围
--set @sql1 = @sql1 + '' and storeroom_id in ('' + @storeroom_scope + '') ''
--if((@storeroom_id <> ''000000'') and (@storeroom_id <> ''''))
	set @sql1 = @sql1 + '' and storeroom_id ='' + @storeroom_id


--打开游标
open storeaccount_cursor

while(1=1)
begin
	--从游标结果集中检索数据
	fetch next from storeaccount_cursor into @goodID,@goodCode,@goodSpec,
			@unitName,@inNums,@inMoney,@outNums,@outMoney
	if(@@FETCH_STATUS<>0) break

	set @sql = @sql1 + '' and good_id = '' + cast(@goodID as varchar) + '' order by check_date desc ''
	print @sql
	--动态创建游标
	execute(@sql)

	--打开游标
	open init_cursor
	
	fetch next from init_cursor into @initNums,@initMoney
	if(@@FETCH_STATUS<>0)
	begin
		set @initNums = 0
		set @initMoney = 0
	end
	
	set @stockNums = @initNums + @inNums - @outNums
	set @stockMoney = @initMoney + @inMoney - @outMoney
	insert into #storeaccount(good_id,good_code,good_spec,unit_name,init_nums,init_money,in_nums,in_money,
				out_nums,out_money,stock_nums,stock_money) 
	values(@goodID,@goodCode,@goodSpec,@unitName,@initNums,@initMoney,@inNums,@inMoney,@outNums,
		@outMoney,@stockNums,@stockMoney)
	if(@@ERROR<>0)
	begin
		set @success = @@ERROR
		break
	end
	
	close init_cursor
	deallocate init_cursor
end

close storeaccount_cursor
deallocate storeaccount_cursor

delete from #storeaccount where init_nums=0 and in_nums=0 and out_nums=0

--决定是否提交数据
if(@success=0)
	commit
else
	rollback

select * from #storeaccount order by good_spec

--删除临时表
drop table #storeaccount




' 
END
