delete bi_jxc
insert bi_jxc (account, dbname, 
	notetype, notedate, noteno, updatedate, computed) values
	('JXC','jxcdata0002','QC','2011-3-31','00000'
	,getdate(),0)
insert into bi_jxc 
select 'JXC' as account, 'jxcdata0002' as dbname, notetype, 
	notedate, noteno, GETDATE() as UpdateDate, 0 as computed
from (
-- 销售退回
SELECT notedate, noteno, 'XT' as notetype
FROM REFUNDOUTH
where tag = 1
union all
-- 销售、销更
SELECT notedate, noteno, 
CASE WHEN type0 = '05' THEN 'XG' ELSE 'XS' END as notetype
FROM WAREOUTH
WHERE (tag = 1) AND (type0 = '01' OR type0 = '05')
union all
-- 采购、进价更正
SELECT notedate, noteno,
CASE WHEN type0 = '05' THEN 'CG' ELSE 'CR' END as notetype
FROM WAREINH
WHERE (tag = 1) AND (type0 = '01' or type0='05')
union all
-- 采购退回
SELECT notedate, noteno, 'CT' as notetype
FROM REFUNDINH
WHERE tag = 1
union all
-- 移库
select notedate, noteno, 'YK' as notetype
from WAREALLOTH
where tag = 1
) note