/****** Object:  View [storebilllist]    Script Date: 01/14/2012 16:34:18 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[storebilllist]'))
EXEC dbo.sp_executesql @statement = N'
--create view storebilllist
CREATE view [dbo].[storebilllist]
as
select a.good_in_id as ID,a.good_in_code as billCode,a.in_date as date,b.storeroom_name  as storeRoomName,''采购入库单'' as billType,
c.emp_name as empName,d.dept_name as deptName,'''' as view_url,a.storeroom_id 
from good_in_bill a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.order_man = c.emp_id and a.dept_id = d.dept_id and a.status=1
union
select a.bill_id as ID,a.bill_code as billCode,a.move_date as date,
(''从[''+(select storeroom_name from storeroom where storeroom_id=a.out_storeroom_id)+ '']至[''+
(select storeroom_name from storeroom where storeroom_id=a.in_storeroom_id) + '']'') as storeRoomName,
''库房调拨单'' as billType,b.emp_name as empName,c.dept_name as deptName,'''' as view_url,a.out_storeroom_id as storeroom_id
from good_move_bill a,emp_info b,dept_info c
where a.handle_man = b.emp_id and a.dept_id = c.dept_id  and a.status=1
union
select a.good_return_id as ID,a.good_return_code as billCode,a.return_date as date,b.storeroom_name  as storeRoomName,''采购退货单'' as billType,
c.emp_name as empName,d.dept_name as deptName,'''' as view_url,a.storeroom_id
from good_return_bill a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.order_man = c.emp_id and a.dept_id = d.dept_id  and a.status=1
union
select a.bill_id as ID,a.bill_code as billCode,a.bill_date as date,b.storeroom_name  as storeRoomName,''其它入库单'' as billType,
c.emp_name as empName,d.dept_name as deptName,''commoninbillauditshow?bill_id=<%billID%>'' as view_url,a.storeroom_id
from common_in_bill a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.handle_man = c.emp_id and a.dept_id = d.dept_id  and a.status=1
union
select a.bill_id as ID,a.bill_code as billCode,a.bill_date as date,b.storeroom_name  as storeRoomName,''其它出库单'' as billType,
c.emp_name as empName,d.dept_name as deptName,''commonoutbillauditshow?bill_id=<%billID%>'' as view_url,a.storeroom_id
from common_out_bill a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.handle_man = c.emp_id and a.dept_id = d.dept_id  and a.status=1
union
select a.bill_id as ID,a.bill_code as billCode,a.bill_date as date,b.storeroom_name  as storeRoomName,''供应商铺货单'' as billType,
c.emp_name as empName,d.dept_name as deptName,''deposit.depositbillauditmod?bill_id=<%billID%>'' as view_url,a.storeroom_id
from deposit_bill_m a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.handle_man = c.emp_id and a.dept_id = d.dept_id  and a.status=1 and a.bill_type=1
union
select a.bill_id as ID,a.bill_code as billCode,a.bill_date as date,b.storeroom_name  as storeRoomName,''供应商铺退回'' as billType,
c.emp_name as empName,d.dept_name as deptName,''deposit.depositreturnbillauditmod?bill_id=<%billID%>'' as view_url,a.storeroom_id
from deposit_bill_m a,storeroom b,emp_info c,dept_info d
where a.storeroom_id = b.storeroom_id and a.handle_man = c.emp_id and a.dept_id = d.dept_id  and a.status=1 and a.bill_type=-1


' 
