/****** Object:  StoredProcedure [erp_goodsale]    Script Date: 01/14/2012 16:34:07 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_goodsale]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--create procedure erp_goodsale
CREATE procedure [dbo].[erp_goodsale]
	@sortColNo int,
	@sortType varchar(16),
	@saleDate_s datetime,
	@saleDate_e datetime,
	@goodCode_i varchar(32),
	@goodName varchar(128),
	@categoryScope varchar(2048),--商品分类范围
	@categoryID varchar(32),--商品分类
	@deptID varchar(1024),
	@custCode varchar(30),
	@custName varchar(64),
	@flag char(1) --0获取明细数据,1获取所有金额统计数据
as

declare @goodID int
declare @goodCode varchar(32)
declare @goodSpec varchar(256)
declare @unitName varchar(8)
declare @goodNums int
declare @price numeric(12,4)

declare @success int

declare @colName nvarchar(64)
declare @sql nvarchar(4000)
declare @sql1 nvarchar(4000)
declare @condition nvarchar(2000)


--构造列名和列编号的对照表
if(@sortColNo=1) set @colName = ''good_code''
if(@sortColNo=2) set @colName = ''good_spec''
if(@sortColNo=3) set @colName = ''good_nums''
if(@sortColNo=4) set @colName = ''price''


--定义游标，从数据库中汇总出商品的销售情况
--结果集包括：商品流水编号、商品编号、品名规格、计量单位、数量、金额
set @sql =''select c.good_id,''+
		''d.good_id as good_code,''+
		''good_spec=''+
		''case  ''+
		''when (d.good_spec is null) or (d.good_spec = '''''''') then d.good_name ''+
		''else d.good_name + ''''('''' + d.good_spec + '''')'''' ''+
		''end, ''+
		''e.unit_name, ''+
		''c.good_nums, ''+
		''c.price ''+
	''from ( ''+
		''select b.id as good_id,sum(b.sale_good_nums) as good_nums,''+
		''sum(b.sale_good_nums*b.price) as price ''+
		''from cash_sale_bill a,good_sale_exchange b,customers cc ''+
		''where a.good_sale_code = b.bill_code and ''+
			''a.customer_id = cc.customer_id and '' +
			''a.status in(''''7'''',''''9'''',''''11'''',''''31'''',''''40'''') ''

set @condition=''''

if(@deptID is not null)
	set @condition = @condition + '' and dept_id in ('' +  @deptID + '') ''

if(@saleDate_s is not null)
	set @condition = @condition + '' and sale_date >= '''''' +  cast(@saleDate_s as varchar) + '''''' ''

if(@saleDate_e is not null)
	set @condition = @condition + '' and sale_date <= ''''''  + cast(@saleDate_e as varchar)  + '''''' ''

if(@custCode is not null)
	set @condition = @condition + '' and cc.customer_code like ''''%''  + @custCode  + ''%'''' ''

if(@custName is not null)
	set @condition = @condition + '' and cc.customer_name like ''''%''  + @custName  + ''%'''' ''


set @sql = @sql + @condition + ''group by b.id ''+
		      '') c, goods_info d,good_unit e ''+
		''where c.good_id = d.id and ''+
			''d.unit_id = e.unit_id  ''

if(@goodCode_i is not null)
	set @sql = @sql + '' and d.good_id like ''''%''  + @goodCode_i  + ''%'''' ''

if(@goodName is not null)
	set @sql = @sql + '' and d.good_name like ''''%''  + @goodName  + ''%'''' ''

if(@categoryScope is not null and @categoryScope <> '''')
	set @sql = @sql + '' and d.category_id in ('' +  @categoryScope + '') ''

if(@categoryID is not null and @categoryID <> '''')
	set @sql = @sql + '' and d.category_id like ''''''  + @categoryID  + ''%'''' ''

set @sql = @sql + '' order by '' + @colName + '' '' + @sortType



set @sql1 = ''select sum(b.sale_good_nums) as good_nums,sum(b.sale_good_nums*b.price) as total_money ''+
		''from cash_sale_bill a,good_sale_exchange b,customers cc,goods_info dd ''+
		''where a.good_sale_code = b.bill_code and ''+
			''a.customer_id = cc.customer_id and '' +
			''b.id = dd.id and '' +
			''a.status in(''''7'''',''''9'''',''''11'''',''''31'''',''''40'''') ''
set @sql1 = @sql1 + @condition
if(@goodCode_i is not null)
	set @sql1 = @sql1 + '' and dd.good_id like ''''%''  + @goodCode_i  + ''%'''' ''

if(@goodName is not null)
	set @sql1 = @sql1 + '' and dd.good_name like ''''%''  + @goodName  + ''%'''' ''

if(@categoryScope is not null and @categoryScope <> '''')
	set @sql1 = @sql1 + '' and dd.category_id in ('' +  @categoryScope + '') ''

if(@categoryID is not null or @categoryID <> '''')
	set @sql1 = @sql1 + '' and dd.category_id like ''''''  + @categoryID  + ''%'''' ''



--只统计汇总数据
if(@flag=''1'')
begin
	set @sql = @sql1
end

execute(@sql)




' 
END
