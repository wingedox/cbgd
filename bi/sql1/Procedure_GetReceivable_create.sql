/****** Object:  StoredProcedure [GetReceivable]    Script Date: 01/13/2012 04:54:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[GetReceivable]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE procedure [dbo].[GetReceivable]
(@dept as varchar(4) = ''all'')
as
begin

if not @dept in (''hy'', ''bc'', ''fx'', ''all'')
	raiserror(''@dept ����'', 1,1)

declare @curr_year as varchar(4),
	@curr_month as varchar(2),
	@pre_month as varchar(2),
	@pre_year as varchar(4),
	@sql as varchar(500)
	

select @curr_year = uValue from uParameter where usection=''OPTIONS'' and uSymbol=''CURRENTYEAR''


select @curr_month = uValue from uParameter where usection=''OPTIONS'' and uSymbol=''CURRENTMONTH''

if @curr_month = ''1''
  begin
    set @pre_year = cast((cast(@curr_year as int) - 1) as varchar(4))
    set @pre_month = ''12''
  end
else
  begin
    --���������ǵڼ���
    set @pre_year = @curr_year
    set @pre_month = cast((cast(@curr_month as int) - 1) as varchar(2))
  end

--select * from uParameter where usection=''OPTIONS'' and uSymbol=''ENDDAY''


--�������
set @sql = ''SELECT a.code, rtrim(b.name) name, SUM(a.curr'' + @pre_month + '') AS curr
FROM INCOMEBAL a INNER JOIN
      CUSTOMER b ON a.code = b.code
WHERE (a.period = '''''' + @pre_year + '''''') AND (a.curr'' + @pre_month + '' <> 0)
GROUP BY a.code, b.name''

-- select @pre_month,@pre_year
-- select @sql

--����Ӧ����ʱ��
create table #receivable(
	code varchar(20),
	name varchar(50),
	curr money)

--��ѯ��������ʱ��
insert into #receivable(code, name, curr) exec(@sql)

declare @start_time as datetime,
	@end_time as datetime

--�õ���ǰ�ڼ��һ��
set @start_time = dateadd(mm, datediff(mm, 0, @curr_year + ''-'' 
	+ @curr_month + ''-1''), 0)
set @end_time = dateadd(mm, 1, @start_time)

--��ѯ�������ݲ���Ӧ����ʱ��
--���ڷ��������/����/�˿�
insert into #receivable(code, name, curr)
SELECT a.custno AS code, rtrim(b.name) name, SUM(c.curr) AS curr
FROM WAREOUTH a INNER JOIN
      CUSTOMER b ON a.custno = b.code INNER JOIN
      WAREOUTM c ON a.noteno = c.noteno
WHERE (a.tag = 1) AND (a.type0 = ''01'') AND (a.notedate >= @start_time) AND 
      (a.notedate < @end_time)
GROUP BY a.custno, b.name
union all
--����
SELECT a.custno AS code, rtrim(b.name) name, - SUM(c.curr1) AS curr
FROM WAREOUTH a INNER JOIN
      CUSTOMER b ON a.custno = b.code INNER JOIN
      WAREOUTM c ON a.noteno = c.noteno
WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (a.notedate >= @start_time) AND 
      (a.notedate < @end_time) AND (c.curr1 <> 0)
GROUP BY a.custno, b.name
union all
--�˿�
SELECT a.custno AS code, rtrim(b.name) name, - SUM(c.curr) AS curr
FROM REFUNDOUTH a INNER JOIN
      CUSTOMER b ON a.custno = b.code INNER JOIN
      REFUNDOUTM c ON a.noteno = c.noteno
WHERE (a.tag = 1) AND (a.notedate >= @start_time) AND 
      (a.notedate < @end_time)
GROUP BY a.custno, b.name
union all
--�տ�
SELECT a.custno AS code, rtrim(b.name) name, - SUM(a.curr) AS curr
FROM INCOMECURR a INNER JOIN
      CUSTOMER b ON a.custno = b.code
WHERE (a.date0 >= @start_time) AND (a.date0 < @end_time) AND 
      (a.type0 = ''0'')
GROUP BY a.custno, b.name
union all
--�˿�
SELECT a.custno AS code, rtrim(b.name) name, SUM(a.curr) AS curr
FROM INCOMECURR a INNER JOIN
      CUSTOMER b ON a.custno = b.code
WHERE (a.date0 >= @start_time) AND (a.date0 < @end_time) AND 
      (a.type0 = ''1'')
GROUP BY a.custno, b.name

if @dept=''fx'' or @dept=''all''
	begin
		--������ȥ15�����۱�
		create table #last15sell(
			code varchar(20),
			curr money)

		set @end_time = getdate()
		set @start_time = cast(convert(varchar(10), dateadd(d, -15, @end_time), 120) as datetime)

		--��ѯ�����ȥ15����������
		insert into #last15sell(code, curr)
		select s.custno as code, sum(s.curr) from
			(SELECT a.custno, SUM(c.curr) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''01'') 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--����
			SELECT a.custno, - SUM(c.curr1) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (c.curr1 <> 0) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--�˿�
			SELECT a.custno, - SUM(c.curr) AS curr
			FROM REFUNDOUTH a INNER JOIN
				  REFUNDOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno) s 
		where s.custno in (select code from #receivable group by code having sum(curr) <> 0)
		group by s.custno

		--������ȥ25�����۱�
		create table #last25sell(
			code varchar(20),
			curr money)

		set @end_time = getdate()
		set @start_time = cast(convert(varchar(10), dateadd(d, -25, @end_time), 120) as datetime)

		--��ѯ�����ȥ25����������
		insert into #last25sell(code, curr)
		select s.custno as code, sum(s.curr) from
			(SELECT a.custno, SUM(c.curr) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''01'') 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--����
			SELECT a.custno, - SUM(c.curr1) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (c.curr1 <> 0) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--�˿�
			SELECT a.custno, - SUM(c.curr) AS curr
			FROM REFUNDOUTH a INNER JOIN
				  REFUNDOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno) s 
		where s.custno in (select code from #receivable group by code having sum(curr) <> 0)
		group by s.custno
	end

if @dept=''hy'' or @dept=''bc'' or @dept=''fx'' or @dept=''all''
	begin
		--������ȥ30�����۱�
		create table #last30sell(
			code varchar(20),
			curr money)

		set @end_time = getdate()
		set @start_time = cast(convert(varchar(10), dateadd(d, -30, @end_time), 120) as datetime)

		--��ѯ�����ȥ30����������
		insert into #last30sell(code, curr)
		select s.custno as code, sum(s.curr) from
			(SELECT a.custno, SUM(c.curr) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''01'') 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--����
			SELECT a.custno, - SUM(c.curr1) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (c.curr1 <> 0) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--�˿�
			SELECT a.custno, - SUM(c.curr) AS curr
			FROM REFUNDOUTH a INNER JOIN
				  REFUNDOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno) s 
		where s.custno in (select code from #receivable group by code having sum(curr) <> 0)
		group by s.custno
	end

if @dept=''bc'' or @dept=''hy'' or @dept=''all''
	begin
		--������ȥ45�����۱�
		create table #last45sell(
			code varchar(20),
			curr money)

		set @end_time = getdate()
		set @start_time = cast(convert(varchar(10), dateadd(d, -45, @end_time), 120) as datetime)

		--��ѯ�����ȥ45����������
		insert into #last45sell(code, curr)
		select s.custno as code, sum(s.curr) from
			(SELECT a.custno, SUM(c.curr) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''01'') 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--����
			SELECT a.custno, - SUM(c.curr1) AS curr
			FROM WAREOUTH a INNER JOIN
				  WAREOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) AND (a.type0 = ''05'') AND (c.curr1 <> 0) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno
			union all
			--�˿�
			SELECT a.custno, - SUM(c.curr) AS curr
			FROM REFUNDOUTH a INNER JOIN
				  REFUNDOUTM c ON a.noteno = c.noteno
			WHERE (a.tag = 1) 
				AND a.notedate >= @start_time AND a.notedate < @end_time
			GROUP BY a.custno) s 
		where s.custno in (select code from #receivable group by code having sum(curr) <> 0)
		group by s.custno
	end

--��ѯ���
if @dept=''fx''
	begin
		select r.code as ����, r.name as ����, r.curr as Ӧ�����, s.curr as ����30��,
			case when r.curr > 0 and s15.curr is null then r.curr
				 when r.curr > 0 and r.curr - s15.curr > 0 then r.curr - s15.curr
				 else null end as ��15��,
			case when r.curr > 0 and s25.curr is null then r.curr
				 when r.curr > 0 and r.curr - s25.curr > 0 then r.curr - s25.curr
				 else null end as ��25��,
			case when r.curr > 0 and s.curr is null then
				 dbo.getlastsellofreceivable(r.code, r.curr, @start_time)
				 when r.curr > 0 and r.curr - s.curr > 0 then 
				 dbo.getlastsellofreceivable(r.code, r.curr - s.curr, @start_time) 
			else null end as �������, c.�г� as �г�, c.���� as ����, c.����
		from 
			(select v.code, v.name, sum(v.curr) as curr from #receivable v 
			group by v.code, v.name having sum(v.curr) <> 0) r 
			left join #last15sell s15 on r.code = s15.code left join
			#last25sell s25 on r.code=s25.code left join
			#last30sell s on r.code=s.code left join
			cust_category c on r.code = c.�ͻ�����
		where c.���� = ''����''
	end
	
if @dept=''hy''
	begin
		select r.code as ����, r.name as ����, r.curr as Ӧ�����, s.curr as ����30��,
			case when r.curr > 0 and s.curr is null then r.curr
				 when r.curr > 0 and r.curr - s.curr > 0 then r.curr - s.curr
				 else null end as ��30��,
			case when r.curr > 0 and s45.curr is null then r.curr
				 when r.curr > 0 and r.curr - s45.curr > 0 then r.curr - s45.curr
				 else null end as ��45��,
			dbo.getlastsellofreceivable(r.code, r.curr, @start_time) as �������, 
			c.��ҵ as ��ҵ, c.����ҵ as ����ҵ
		from 
			(select v.code, v.name, sum(v.curr) as curr from #receivable v 
			group by v.code, v.name having sum(v.curr) <> 0) r 
			left join #last30sell s on r.code = s.code left join
			#last45sell s45 on r.code=s45.code left join
			cust_category c on r.code = c.�ͻ�����
		where c.���� = ''��ҵ''
	end
	
if @dept=''bc''
	begin
		select r.code as ����, r.name as ����, r.curr as Ӧ�����, s.curr as ����30��,
			case when r.curr > 0 and s.curr is null then r.curr
				 when r.curr > 0 and r.curr - s.curr > 0 then r.curr - s.curr
				 else null end as ��30��,
			case when r.curr > 0 and s45.curr is null then r.curr
				 when r.curr > 0 and r.curr - s45.curr > 0 then r.curr - s45.curr
				 else null end as ��45��,
			dbo.getlastsellofreceivable(r.code, r.curr, @start_time) as �������, 
			c.��ҵ as ��ҵ, c.����ҵ as ����ҵ
		from 
			(select v.code, v.name, sum(v.curr) as curr from #receivable v 
			group by v.code, v.name having sum(v.curr) <> 0) r 
			left join #last30sell s on r.code = s.code left join
			#last45sell s45 on r.code=s45.code left join
			cust_category c on r.code = c.�ͻ�����
		where c.���� = ''�ͻ�''
	end
	
if @dept=''all''
	begin
		select r.code as ����, r.name as ����, r.curr as Ӧ�����, s.curr as ����30��,
			case when r.curr > 0 and s15.curr is null then r.curr
				 when r.curr > 0 and r.curr - s15.curr > 0 then r.curr - s15.curr
				 else null end as ��15��,
			case when r.curr > 0 and s25.curr is null then r.curr
				 when r.curr > 0 and r.curr - s25.curr > 0 then r.curr - s25.curr
				 else null end as ��25��,
			case when r.curr > 0 and s.curr is null then r.curr
				 when r.curr > 0 and r.curr - s.curr > 0 then r.curr - s.curr
				 else null end as ��30��,
			case when r.curr > 0 and s45.curr is null then r.curr
				 when r.curr > 0 and r.curr - s45.curr > 0 then r.curr - s45.curr
				 else null end as ��45��,
			dbo.getlastsellofreceivable(r.code, r.curr, @start_time) as �������, 
			c.�г� as �г�, c.���� as ����, c.��ҵ as ��ҵ, c.����ҵ as ����ҵ, c.����
		from 
			(select v.code, v.name, sum(v.curr) as curr from #receivable v 
			group by v.code, v.name having sum(v.curr) <> 0) r 
			left join #last15sell s15 on r.code = s15.code left join
			#last25sell s25 on r.code=s25.code left join
			#last30sell s on r.code = s.code left join
			#last45sell s45 on r.code=s45.code left join
			cust_category c on r.code = c.�ͻ�����
	end

drop table #receivable
if @dept = ''fx'' or @dept=''all''
begin
drop table #last15sell
drop table #last25sell
end
drop table #last30sell
if @dept = ''hy'' or @dept=''bc'' or @dept=''all''
begin
drop table #last45sell
end
end' 
END
