/****** Object:  StoredProcedure [erp_storecategoryaccount]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_storecategoryaccount]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_storecategoryaccount
CREATE procedure [dbo].[erp_storecategoryaccount]
	@storeroomID integer,--库房编号,可以限制查询某一个库房的应付帐,null或者-1表示操作人权限范围内的所有库房
	@operator integer,--当前操作人编号，用于确定所能查询的库房的范围
	@date_s datetime,
	@date_e datetime,
	@goodCode_i varchar(32),
	@goodName varchar(128),
	@categoryScope varchar(2048),--商品分类范围
	@categoryID varchar(32),--商品分类
	@summaryID integer,
	@custName varchar(64),
	@sortColNo int,
	@sortType varchar(16),
	@flag char(1) --0获取明细数据,1获取所有金额统计数据
as


declare @goodID int
declare @goodCode varchar(32)
declare @goodSpec varchar(256)
declare @unitName varchar(8)
declare @goodNums int

declare @success int

declare @colName nvarchar(64)
declare @sql nvarchar(4000)
declare @sql1 nvarchar(4000)
declare @condition nvarchar(2000)
declare @sqlStoreRoomScope nvarchar(2000) --操作人所能够查询到的库房的范围对应的查询语句

set @sqlStoreRoomScope = '' select storeroom_id ''+
	                 '' from storeroom_user ''+
	                 '' where emp_id='' + CAST(@operator as varchar)

--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''good_code''
if(@sortColNo=2) set @colName = ''good_spec''
if(@sortColNo=3) set @colName = ''exchange_type_name''
if(@sortColNo=4) set @colName = ''good_nums''


--定义游标，从数据库中汇总出商品的销售情况
--结果集包括：商品流水编号、商品编号、品名规格、计量单位、数量、金额
set @sql ='' select c.good_id,''+
		'' c.exchange_type_id, ''+
		'' f.exchange_type_name, '' +
		''d.good_id as good_code,''+
		''d.spec_info as good_spec, ''+
		''e.unit_name, ''+
		''c.good_nums ''+
	'' from ( ''+
		'' select aa.good_id,aa.exchange_type_id,sum(aa.good_nums*cc.stock_change) as good_nums ''+
		'' from store_goods_exchange aa,erp_goods_info bb, store_exchange_type cc''+
		'' where aa.good_id = bb.id and ''+
			'' aa.exchange_type_id = cc.exchange_type_id ''+
			'' and (aa.storeroom_id in ( '' +@sqlStoreRoomScope + '')) '' --显示操作人所能够查询库房应付帐的范围


set @condition=''''

if(@categoryScope is not null and @categoryScope <> '''')
	set @condition = @condition + '' and bb.category_id in ('' +  @categoryScope + '') ''

if(@categoryID is not null and @categoryID <> '''')
	set @condition = @condition + '' and bb.category_id like ''''''  + @categoryID  + ''%'''' ''

if(@date_s is not null)
	set @condition = @condition + '' and bill_date >= '''''' +  cast(@date_s as varchar) + '''''' ''

if(@date_e is not null)
	set @condition = @condition + '' and bill_date <= ''''''  + cast(@date_e as varchar)  + '''''' ''

if(@custName is not null and @custName <> '''')
	set @condition = @condition + '' and aa.cust_name like ''''%''  + @custName  + ''%'''' ''

if(@goodCode_i is not null and @goodCode_i <> '''')
	set @condition = @condition + '' and bb.good_id like ''''%''  + @goodCode_i  + ''%'''' ''

if(@goodName is not null and @goodName <> '''')
	set @condition = @condition + '' and bb.spec_info like ''''%''  + @goodName  + ''%'''' ''

if(@storeroomID is not null and  @storeroomID <> -1)
	set @condition = @condition + '' and aa.storeroom_id = ''  + CAST(@storeroomID as varchar)

if(@summaryID is not null and @summaryID <> -1)
	set @condition = @condition + '' and aa.exchange_type_id = ''  + CAST(@summaryID as varchar)


set @sql = @sql + @condition + ''group by aa.good_id,aa.exchange_type_id,cc.exchange_type_name ''+
		      '') c, erp_goods_info d,good_unit e,store_exchange_type f ''+
			'' where c.good_id = d.id and ''+
			'' d.unit_id = e.unit_id and ''+
			'' c.exchange_type_id = f.exchange_type_id ''

set @sql = @sql + '' order by '' + @colName + '' '' + @sortType + '',f.order_no''

print @sql

set @sql1 = '' select sum(aa.good_nums*cc.stock_change) as total_good_nums ''+
		'' from store_goods_exchange aa,erp_goods_info bb, store_exchange_type cc ''+
		'' where aa.good_id = bb.id and ''+
		'' aa.exchange_type_id = cc.exchange_type_id ''
set @sql1 = @sql1 + @condition


--只统计汇总数据
if(@flag=''1'')
begin
	set @sql = @sql1
end

execute(@sql)




' 
END
