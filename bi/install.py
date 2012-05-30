#coding=utf-8
import calendar
import os
from adodbapi import adodbapi
import sys
import datetime

__author__ = 'GaoJun'

jxc_triggers = ['wareouth_bi', 'refundouth_bi', 'refundinh_bi', 'wareinh_bi']
erp_triggers = ['common_in_bill_bi', 'common_out_bill_bi', 'good_in_bill_bi',
                'good_return_bill_bi', 'sale_out_store_bi', 'sale_return_store_bi']

fields = [ 'notedate','noteno','department','partnerno','houseno','saleman','dptno',
         'wareno','amount','price','curr']

###################### 系统安装 ######################

import clr
clr.AddReference("Microsoft.SqlServer.Smo")
from Microsoft.SqlServer.Management.Common import *
from Microsoft.SqlServer.Management.Smo import *
from Microsoft.SqlServer import *

class _scriptor(object):
    @property
    def conn(self):
        raise Exception('conn err')

    def bakupScript(self):
        inst = self.inst
        uid = self.uid
        pwd = self.pwd
        dbname = self.dbname
        tag = self.tag
        s = Server()
        s.ConnectionContext.LoginSecure = False
        s.ConnectionContext.Login = self.uid
        s.ConnectionContext.Password = self.pwd
        s.ConnectionContext.ServerInstance = self.inst

        script = Scripter(s)
        script.Options.ScriptDrops        = True
        script.Options.ScriptSchema       = True
        #script.Options.WithDependencies   = True
        script.Options.DriAllKeys = True
        script.Options.DriClustered = True
        script.Options.DriAllConstraints = True
        script.Options.DriDefaults = True
        script.Options.DriIndexes = True
        script.Options.DriNonClustered = True
        script.Options.DriPrimaryKey = True
        script.Options.DriUniqueKeys = True
        script.Options.AnsiFile = False
        script.Options.ClusteredIndexes = True
        script.Options.IncludeHeaders = True
        script.Options.Indexes = True
        script.Options.SchemaQualify = False
        script.Options.Triggers = True
        script.Options.XmlIndexes = True
        script.Options.ExtendedProperties = True
        script.Options.NoFileGroup = True
        script.Options.NoCollation = True
        script.Options.IncludeIfNotExists = True
        script.Options.NoIdentities = True
        db = s.Databases[self.dbname]

        path = '%s\\sql\\%s' % (sys.path[0], self.tag)
        scripts = []

        def getScriptLines(objs, drop=False):
            urn = [objs[0].Urn]

            script.Options.ScriptDrops = drop
            sqls = script.Script(urn)
            enum = sqls.GetEnumerator()
            lines = []
            while enum.MoveNext():
                lines.append(enum.Current.encode('gb2312'))
                #lines.append('\n')
            return lines

        def saveScript(type, objs):
            if not os.path.exists(path):
                os.makedirs(path)
            name = objs[0].Name
            file = '%s\\%s_%s_create.sql' % (path, type, name)
            if os.path.exists(file):
                os.remove(file)
            f = open(file, 'w+')
            lines = getScriptLines(objs, drop=False)
            f.writelines(lines)
            f.close()

            file = '%s\\%s_%s_drop.sql' % (path, type, name)
            if os.path.exists(file):
                os.remove(file)
            f = open(file, 'w+')
            lines = getScriptLines(objs, drop=True)
            f.writelines(lines)
            f.close()

            scripts.append({'name':name,
                            'createfile':'sql\\%s\\%s_%s_create.sql' % (tag, type, name),
                            'dropfile':'sql\\%s\\%s_%s_drop.sql' % (tag, type, name),
                            'type':type})


        for p in db.StoredProcedures.GetEnumerator():
            if not p.IsSystemObject:
                saveScript('Procedure', [p,])

        for t in db.Tables.GetEnumerator():
            if not t.IsSystemObject:
                for fk in t.ForeignKeys.GetEnumerator():
                    saveScript('ForeignKey', [fk,])
                for tr in t.Triggers.GetEnumerator():
                    saveScript('Trigger', [tr,])

        for fu in db.UserDefinedFunctions.GetEnumerator():
            if not fu.IsSystemObject:
                saveScript('Function', [fu,])

        for v in db.Views.GetEnumerator():
            if not v.IsSystemObject:
                saveScript('View', [v,])

        file = '%s\\scripts.txt' % path
        f = open(file, 'w')
        f.write(str(scripts))
        f.close()

    def restoreScript(self):
        path = '%s\\sql\\%s' % (sys.path[0], self.tag)
        f = open('%s\\scripts.txt' % path, 'r')
        scripts = eval(f.read())

        cur = self.conn.cursor()

        try:
            for item in scripts:
                f = open('%s\\%s' % (path, item['dropfile']), 'r')
                sql = f.read()
                f.close()
                cur.execute(sql)

                f = open('%s\\%s' % (path, item['createfile']), 'r')
                sql = f.read()
                f.close()
                cur.execute(sql)
            self.conn.commit()
            print self.conn
        except Exception, e:
            print e.strerror
            self.conn.rollback()
        finally:
            cur.close()

    def create_bi_jxc_Table(self, drop=False):
        print self.conn
        cur = self.conn.cursor()
        query = "select * from sysobjects where xtype = 'U' and name = 'bi_jxc'"
        cur.execute(query)
        cur.fetchall()
        if cur.rowcount > 0 and drop:
            query = "drop table bi_jxc"
            cur.execute(query)
        elif cur.rowcount > 0:
            cur.close()
            return
        f = open('%s\\sql\\Table_bi_jxc_create.sql' % sys.path[0], 'r')
        query = f.read()
        f.close()
        cur.execute(query)
        self.conn.commit()
        cur.close()

class jxc(_scriptor):
    def __init__(self):
        self.inst = '192.168.0.3'
        self.uid = 'sa'
        self.pwd = '1109.hans'
        self.dbname = 'jxcdata0002'
        self.tag = 'jxc'
        self.__conn = None
        super(jxc, self).__init__()

    @property
    def conn(self):
        if not self.__conn:
            connstr = r"Provider=SQLOLEDB.1;Initial Catalog=%s;Data Source=%s;user ID=%s;Password=%s"\
            % (self.dbname, self.inst, self.uid, self.pwd)
            self.__conn = adodbapi.connect(connstr)
        return self.__conn

    def copy_jxc(self):
        conn = self.conn
        cur = conn.cursor()
        query = "select uValue from uparameter where uSection = 'options' and uSymbol = 'beginmonth'"
        cur.execute(query)
        row = cur.fetchone()
        beginmonth = row[0].strip()
        query = "select uValue from uparameter where uSection = 'options' and uSymbol = 'beginyear'"
        cur.execute(query)
        row = cur.fetchone()
        beginyear = row[0].strip()
        if int(beginmonth) < 10 and beginmonth != '1':
            beginmonth = ' ' + str(int(beginmonth) - 1)
        elif beginmonth == '1':
            beginyear = str(int(beginyear) - 1)
            beginmonth = 12
        period = beginyear + beginmonth
        begindate = datetime.date(int(beginyear), int(beginmonth),
            calendar.monthrange(int(beginyear), int(beginmonth))[1])
        query = u'''
            declare @date as datetime
            set @date = getdate()

            insert into bi_jxc
            select *, @date as UpdateDate, 0 as computed from (
            --期初库存
            select '%(begindate)s' as notedate, null as noteno, SUBSTRING(houseno,1,2) as department, NULL as partnerno,
            houseno, NULL as saleman, NULL as dptno, wareno, sum(amount) as amount, sum(curr)/sum(amount) as price,
            sum(curr) as curr, 'QC' as type
            from waresum where period = '%(period)s' and amount <> 0 group by wareno, houseno
            union all
            -- 销售退回
            SELECT h.notedate, m.noteno, SUBSTRING(houseno,1,2) as department, h.custno as partnerno, h.houseno,
            e.Name, NULL as dptno, m.wareno, -m.amount as amount, m.price as price,- m.curr as curr, 'XT' as type
            FROM REFUNDOUTM m, REFUNDOUTH h, EMPLOYE e
            where h.noteno = m.noteno and h.tag = 1 and h.saleman=e.code
            union all
            -- 销售、销更
            SELECT h.notedate, RTRIM(h.noteno) as noteno, SUBSTRING(h.houseno,1,2) as department, h.custno as partnerno,
            h.houseno,e.Name as saleman,NULL as dptno, m.wareno,
            CASE WHEN h.type0 = '05' THEN NULL ELSE m.amount END as amount,
            CASE WHEN h.type0 = '05' THEN NULL ELSE m.price END as price,
            CASE WHEN h.type0 = '05' THEN - m.curr1 WHEN h.type0 = '01'
            THEN m.curr END as curr,
            CASE WHEN h.type0 = '05' THEN 'XG' ELSE 'XS' END as type
            FROM WAREOUTM m,
            WAREOUTH h, EMPLOYE e
            WHERE (h.tag = 1) AND (h.type0 = '01' OR
            h.type0 = '05') AND m.noteno=h.noteno and h.saleman=e.code and
            (CASE WHEN h.type0 = '05' THEN - m.curr1 WHEN h.type0 = '01'
            THEN m.curr END <> 0)
            union all
            -- 采购、进价更正
            SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
            h.provno as partnerno, h.houseno, NULL as saleman, NULL as dptno, m.wareno,
            CASE WHEN h.type0 = '05' THEN NULL ELSE m.amount END as amount,
            CASE WHEN h.type0 = '05' THEN NULL ELSE m.price END as price,
            CASE WHEN h.type0 = '05' THEN - m.curr1 WHEN h.type0 = '01'
            THEN m.curr END as curr,
            CASE WHEN h.type0 = '05' THEN 'CG' ELSE 'CR' END as type
            FROM WAREINH h, WAREINM m
            WHERE (h.tag = 1) AND (h.type0 = '01' or h.type0='05') and h.noteno=m.noteno
            union all
            -- 采购退回
            SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department, h.provno as partnerno,
            h.houseno, NULL as saleman, NULL as deptno, m.wareno, -m.amount as amount,
            -m.price as price, -m.curr as curr, 'CT' as type
            FROM REFUNDINH h, REFUNDINM m
            WHERE h.tag = 1 and h.noteno=m.noteno
            ) a
              '''
        query = query % {'period':period, 'begindate':begindate}
        query = query.encode('cp936')

        cur.execute(query)
        conn.commit()

class erp(_scriptor):
    def __init__(self):
        self.inst = '192.168.0.3,4433'
        self.uid = 'sa'
        self.pwd = '1109.hans'
        self.dbname = 'retail07'
        self.tag = 'erp'
        super(erp, self).__init__()

    def copy_erp(self):
        conn = self.conn
        cur = conn.cursor()
        query = u'''
            declare @dbname as varchar(50), @date as datetime
            set @date = getdate()

            insert into bi_jxc
            --其他入库
            select *, @date as UpdateDate, 0 as computed from(
            SELECT a.audit_date as notedate, a.bill_code as noteno, 'ls' as department, a.customer_id as partnerno,
            a.storeroom_id as houseno, NULL as saleman, a.dept_id as deptno, good_id as wareno, b.good_nums AS amount,
            b.in_price as price, b.good_nums * b.in_price as curr,
            'QR' as type
            FROM common_in_bill a INNER JOIN
            common_in_bill_d b ON a.bill_id = b.bill_id
            WHERE (a.status = 9)
            union all
            --入库
            SELECT a.audit_date as notedate, a.good_in_code as noteno, 'ls' as department, a.provider_id as partnerno,
            a.storeroom_id as houseno, NULL as saleman, a.dept_id as deptno, b.good_id as wareno, b.good_nums AS amount,
            b.in_price as price, b.good_nums * b.in_price as curr,
            'CR' as type
            FROM good_in_bill_d b INNER JOIN
            good_in_bill a ON b.good_in_id = a.good_in_id
            WHERE (a.status = 9)
            union all
            --退库
            SELECT a.audit_date as notedate, a.good_return_code as noteno, 'ls' as department, a.provider_id as partnerno,
            a.storeroom_id as houseno, NULL as saleman, a.dept_id as deptno, b.id as wareno,
            -b.return_nums AS amount, b.price as price, -b.return_nums * b.price as curr,
            'CT' as type
            FROM good_return_bill a INNER JOIN
            good_return_bill_d b ON
            a.good_return_id = b.good_return_id
            WHERE (a.status = 9)
            union all
            --其他出库
            SELECT a.audit_date as notedate, a.bill_code as noteno, 'ls' as department, a.customer_id as partnerno,
            a.storeroom_id as houseno, e.emp_name as saleman, a.dept_id as deptno, good_id as wareno,
            b.good_nums AS amount, b.price as price, b.good_nums * b.price as curr,
            'QX' as type
            FROM common_out_bill a INNER JOIN
            common_out_bill_d b ON
            a.bill_id = b.bill_id inner join emp_info e on a.handle_man=e.emp_id
            where (a.status = 9)
            union all
            --销售出库
            SELECT a.operate_date as notedate, a.bill_code as noteno, 'ls' as department, c.customer_id as partnerno,
            a.storeroom_id as houseno, e.emp_name as saleman, a.dept_id as deptno, good_id as wareno, b.good_nums AS amount,
            b.sale_price as price, b.good_nums * b.sale_price as curr,
            'XS' as type
            FROM sale_out_store a INNER JOIN
            sale_out_store_d b ON a.bill_id = b.bill_id inner join
            cash_sale_bill c on c.good_sale_id = a.sale_bill_id inner join
            emp_info e on a.operator=e.emp_id
            WHERE (a.status = 9)
            union all
            --销售退库
            SELECT a.operate_date as notedate, a.bill_code as noteno, 'ls' as department, c.customer_id as partnerno,
            a.storeroom_id as houseno, e.emp_name as saleman, a.dept_id as deptno, good_id as wareno, -b.good_nums AS amount,
            b.sale_price as price, -b.good_nums * b.sale_price as curr,
            'XT' as type
            FROM sale_return_store a INNER JOIN
            sale_return_store_d b ON
            a.bill_id = b.bill_id inner join
            cash_sale_bill c on a.sale_bill_id = c.good_sale_id inner join
            emp_info e on a.handle_man=e.emp_id
            WHERE (a.status = 9)
            ) a
          '''
        query = query.encode('cp936')

        cur.execute(query)
        conn.commit()

def init_2011():
    e = erp()
    e.restoreScript()
    e.create_bi_jxc_Table(True)
    e.copy_erp()

    j = jxc()
    j.restoreScript()
    j.create_bi_jxc_Table(True)
    j.copy_jxc()

if __name__ == '__main__':
    localIp = '192.168.154.130'
    pwd = '52311'

#    e = erp()
#    e.inst = localIp
#    e.pwd = pwd
#    e.restoreScript()
#    e.create_bi_jxc_Table(True)
#    e.copy_erp()

    j = jxc()
    j.inst = localIp
    j.pwd = pwd
#    j.restoreScript()
#    j.create_bi_jxc_Table(True)
    j.copy_jxc()

#    constr = r"Provider=SQLOLEDB.1;Initial Catalog=JXCDATA0002;Data Source=192.168.0.3;" \
#              "user ID=sa;Password=1109.hans"
#    adoconn = adodbapi.connect(constr)
