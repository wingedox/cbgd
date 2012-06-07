delete bi_jxc

update JXCDATA0002..WAREOUTH set notedate='2011-08-04 12:00:00'
where noteno='X108010302'

insert bi_jxc (account, dbname, 
	notetype, notedate, noteno, updatedate, computed) values
	('JXC','jxcdata0002','QC','2011-3-31','00000'
	,getdate(),0)
insert into bi_jxc 
select 'JXC' as account, 'jxcdata0002' as dbname, notetype, 
	notedate, noteno, GETDATE() as UpdateDate, 0 as computed
from (
-- 销售退回
SELECT DISTINCT notedate, h.noteno, 'XT' as notetype
FROM REFUNDOUTH h, REFUNDOUTM m
where tag = 1 and h.noteno=m.noteno and m.wareno<>'31016666'
union all
-- 销售、销更
SELECT DISTINCT notedate, h.noteno, 
CASE WHEN type0 = '05' THEN 'XG' ELSE 'XS' END as notetype
FROM WAREOUTH h, WAREOUTM m
WHERE (tag = 1) AND (type0 = '01' OR type0 = '05')
and h.noteno=m.noteno and m.wareno<>'31016666'
union all
-- 采购、进价更正
SELECT DISTINCT notedate, h.noteno,
CASE WHEN type0 = '05' THEN 'CG' ELSE 'CR' END as notetype
FROM WAREINH h, WAREINM m
WHERE (tag = 1) AND (type0 = '01' or type0='05')
and h.noteno=m.noteno and m.wareno<>'31016666'
union all
-- 采购退回
SELECT DISTINCT notedate, h.noteno, 'CT' as notetype
FROM REFUNDINH h, REFUNDINM m
WHERE tag = 1 and h.noteno=m.noteno and m.wareno<>'31016666'
union all
-- 移库
select notedate, noteno, 'YK' as notetype
from WAREALLOTH
where tag = 1
) note