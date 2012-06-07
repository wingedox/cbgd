#coding=utf-8

from datetime import datetime, timedelta
from time import sleep
from adodbapi import adodbapi
import pyodbc
import pymssql
from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import sessionmaker
from analysis import warehouse, warehouse_snap, note
import analysis

__author__ = 'GaoJun'

_conn = None
cur = None
conn_bi = None
cur_bi = None

computed_sql = "update bi_jxc set computed=1 where id=%s"
def init():pass

def buildDoc(sql):
    cur.execute(sql)
    rows = cur.fetchall()
    if cur.rowcount==0:raise Exception
    docs = []
    for r in rows:
        doc = {
            'department_id':r[2].strip(),
            'doc_id': r[1].strip(),
            'notedate': r[0],
            'product_id': r[7].strip(),
            'partner_id': r[3].strip(),
            'price': abs(r[9]),
            'quantity': abs(r[8]),
            'warehouse_id': r[4].strip(),
            'sales_id':r[5] and r[5].strip()
        }
        docs.append(doc)
    return docs

def save(id):
    analysis.commit()
    cur.execute(computed_sql % id)
    _conn.commit()

def qc():
    query = "select * from bi_jxc where notetype='QC' and computed=0"
    cur.execute(query)
    rows = cur.fetchall()
    if len(rows)==1:
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
    #    begindate = datetime.date(int(beginyear), int(beginmonth),
    #                              calendar.monthrange(int(beginyear), int(beginmonth))[1])
        query = u'''
                select SUBSTRING(houseno,1,2) as department, houseno, wareno,
                sum(amount) as amount, sum(curr)/sum(amount) as price,
                sum(curr) as curr, 'QC' as type
                from waresum where period = '%(period)s' and amount <> 0 group by wareno, houseno
        '''
        query = query % {'period':period}
        cur.execute(query)
        rows = cur.fetchall()
        for row in rows:
            doc = {
                'department_id':row['department'],
                'warehouse_id':row['houseno'],
                'product_id':row['wareno'],
                'quantity':row['amount'],
                'price':row['price'],
            }
            warehouse.warein(doc)
        analysis.session.commit()
        sql ="update bi_jxc set computed=1 where notetype='QC'"
        cur.execute(sql)
        _conn.commit()

def sales(noteno):
    # ltrim(h.noteno) 自编号的单据号可能被人为在前加入空格，noteno已经去掉前后空格，导致查询为空
    sql = u'''
    SELECT h.notedate, RTRIM(h.noteno) as noteno, SUBSTRING(h.houseno,1,2) as department,
    h.custno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno,e.Name as saleman, m.wareno,
    m.amount, m.price, m.curr
    FROM WAREOUTM m, WAREOUTH h, EMPLOYE e
    WHERE rtrim(ltrim(h.noteno))='%s' AND m.noteno=h.noteno and h.saleman=e.code
    '''
    sql = sql % noteno
    cur.execute(sql)
    rows = cur.fetchall()
    docs = []
    try:
        for r in rows:
            doc = note()
            doc.notedate = r[0]
            doc.noteno = r[1].strip()
            doc.department_id = r[2]
            doc.partner_id = r[3].strip()
            doc.warehouse_id = r[4].strip()
            doc.sales = r[5] and r[5].strip()
            doc.product_id = r[6] and r[6].strip()
            doc.quantity = r[7]
            doc.price = r[8]
            doc.amount = r[9]
            doc.notetype = 'XS'
            warehouse.wareout_check(doc)
            docs.append(doc)
        for doc in docs:
            warehouse.wareout(doc)
    except Exception, e:
        raise Exception(u'记帐失败：%s;%s' % (noteno, e.message))

def returnOfSales(noteno):
    sql = '''
    SELECT h.notedate, m.noteno, SUBSTRING(houseno,1,2) as department, h.custno as partnerno,
    case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno,
    e.Name as saleman, m.wareno, m.amount as amount, m.price as price, m.curr as curr
    FROM REFUNDOUTM m, REFUNDOUTH h, EMPLOYE e
    where h.noteno = m.noteno and h.saleman=e.code and h.noteno = '%s'
    '''
    sql = sql % noteno
    cur.execute(sql)
    rows = cur.fetchall()
    for r in rows:
        doc = note()
        doc.notedate = r[0]
        doc.noteno = r[1].strip()
        doc.department_id = r[2]
        doc.partner_id = r[3].strip()
        doc.warehouse_id = r[4].strip()
        doc.sales = r[5] and r[5].strip()
        doc.product_id = r[6] and r[6].strip()
        doc.quantity = r[7]
        doc.price = r[8]
        doc.amount = r[9]
        doc.notetype = 'XT'
        warehouse.warein(doc)

def purchase(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
    h.provno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, m.wareno,
    m.amount, m.price, m.curr
    FROM WAREINH h, WAREINM m
    WHERE h.noteno=m.noteno and h.noteno='%s'
    '''
    sql = sql % noteno
    cur.execute(sql)
    rows = cur.fetchall()
    for r in rows:
        doc = note()
        doc.notedate = r[0]
        doc.noteno = r[1].strip()
        doc.department_id = r[2]
        doc.partner_id = r[3].strip()
        doc.warehouse_id = r[4].strip()
        doc.sales = r[5] and r[5].strip()
        doc.product_id = r[6] and r[6].strip()
        doc.quantity = r[7]
        doc.price = r[8]
        doc.amount = r[9]
        doc.notetype = 'CR'
        warehouse.warein(doc)

def returnOfPurchase(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department, h.provno as partnerno,
    case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, m.wareno,
    m.amount as amount,
    m.price as price, m.curr as curr
    FROM REFUNDINH h, REFUNDINM m
    WHERE h.noteno=m.noteno and h.noteno = '%s'
    '''
    sql = sql % noteno
    cur.execute(sql)
    rows = cur.fetchall()
    for r in rows:
        doc = note()
        doc.notedate = r[0]
        doc.noteno = r[1].strip()
        doc.department_id = r[2]
        doc.partner_id = r[3].strip()
        doc.warehouse_id = r[4].strip()
        doc.sales = r[5] and r[5].strip()
        doc.product_id = r[6] and r[6].strip()
        doc.quantity = r[7]
        doc.price = r[8]
        doc.amount = r[9]
        doc.notetype = 'CT'
        warehouse.wareout(doc)

def salesChange(noteno):pass

def costChange(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
    h.provno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, m.wareno,
    null as amount, null as price, m.curr1 as curr
    FROM WAREINH h, WAREINM m
    WHERE h.noteno=m.noteno and h.noteno = '%s'
    ''' % noteno
    docs = buildDoc(sql)
    for doc in docs:
        warehouse.costChange(doc['department'],
            doc['wareno'], doc['houseno'], doc['curr'])

def checkMove(noteno):
    stockMove(noteno, True)

def stockMove(noteno, check=False):
    sql = '''
    select h.noteno, h.notedate, h.oldhouseno, h.newhouseno,
        m.wareno, m.amount, substring(h.oldhouseno,1,2) as olddept,
        substring(h.newhouseno,1,2) as newdept, m.id
    from warealloth h, wareallotm m
    where h.noteno=m.noteno and h.noteno='%s'
    ''' % noteno
    cur.execute(sql)
    rows = cur.fetchall()
    if cur.rowcount==0:raise Exception
    for row in rows:
        old = row[2].strip()
        new = row[3].strip()
        if old in ('FX010101','FX01010103','FX01010104') and\
            new in ('FX010101','FX01010103','FX01010104'):
            continue
        if old in ('FX01010103','FX01010104'):
            old = 'FX010101'
        if new in ('FX01010103','FX01010104'):
            new = 'FX010101'
        doc_yc = note()
        doc_yc.noteno = row[0]
        doc_yc.notedate = row[1]
        doc_yc.department_id = row[6].strip()
        doc_yc.warehouse_id = old
        doc_yc.product_id = row[4].strip()
        doc_yc.quantity = row[5]
        doc_yc.notetype = 'YC'
        s = warehouse.getStock(doc_yc.key)
        if not s:
            raise Exception(u'没有库存。%s,%s,%s' % (doc_yc.noteno, doc_yc.product_id,doc_yc.warehouse_id))
        doc_yc.price = s.price
        doc_yc.amount = doc_yc.quantity * doc_yc.price
        warehouse.wareout_check(doc_yc)

        doc_yr = note()
        doc_yr.noteno = row[0]
        doc_yr.notedate = row[1]
        doc_yr.department_id = row[7].strip()
        doc_yr.warehouse_id = new
        doc_yr.product_id = row[4].strip()
        doc_yr.quantity = row[5]
        doc_yr.notetype = 'YR'
        doc_yr.price = s.price
        doc_yr.amount = doc_yr.quantity * doc_yr.price
        warehouse.warein_check(doc_yr)

        if not check:
            warehouse.wareout(doc_yc)
            warehouse.warein(doc_yr)

def dayWarein(day):
    sql = "select noteno, notetype, id from bi_jxc where notetype in ('CR','XT') and computed=0 and \
    CONVERT(varchar(10), notedate, 120)='%s'" % day
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        n = row[0].strip()
        t = row[1].strip()
        i = row[2]
        if t=='XT':
            returnOfSales(n)
        elif t=='CR':
            purchase(n)
        save(i)

def dayWaremove(day):
    # 对于移出库库房没有负库存限制，可能先由A库移到B库，此时A库为负库存
    # 再由C库移到A库。
    errors = []
    for j in range(2):
        sql = "select noteno, notetype, id from bi_jxc where notetype in ('YK') and computed=0 and \
        CONVERT(varchar(10), notedate, 120)='%s' order by notedate, noteno" % day
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            n = row[0].strip()
            i = row[2]
            try:
                # 先检查该移库单所有条目是否都能通过
                checkMove(n)
                stockMove(n)
                save(i)
            except Exception, e:
                if i in errors:
                    print (u'移库错误,%s' % e.message)
                else:
                    errors.append(i)
                analysis.session.rollback()
                _conn.rollback()
                continue

def dayWareout(day):
    sql = "select noteno, notetype, id from bi_jxc where notetype in ('CT','XS') and computed=0 and \
    CONVERT(varchar(10), notedate, 120)='%s' order by notedate" % day
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        try:
            n = row[0].strip()
            t = row[1].strip()
            i = row[2]
            if t=='XS':
                sales(n)
            elif t=='XG':
                salesChange(n)
            elif t=='CT':
                returnOfPurchase(n)
            save(i)
        except Exception, e:
            try:
                print e.message
            except :
                print e.message.encode('utf-8')

def rollback(backdate):
    analysis.rollback(backdate)
    s = backdate.strftime('%Y-%m-%d')
    sql = "update bi_jxc set computed=0 "\
          "where CONVERT(varchar(10), notedate, 120)>='%s'" % s
    cur.execute(sql)
    _conn.commit()

_host = 'localhost'
_pwd = '52311'
_db = 'jxcdata0002'
#_conn = pymssql.connect(host=_host,user='sa',password=_pwd,database=_db)
constr = r"Provider=SQLOLEDB.1;Initial Catalog=%s;Data Source=%s;user ID=%s;Password=%s;"\
    % (_db, _host, 'sa', _pwd)
_conn = adodbapi.connect(constr)
#_conn = pyodbc.connect('DRIVER={SQL Server};DATABASE=%s;SERVER=%s;UID=%s;PWD=%s'% (_db, _host, 'sa', _pwd))
cur = _conn.cursor()

#conn_bi = pymssql.connect(host=_host,user='sa',password=_pwd,database='bi')
#cur_bi = conn_bi.cursor()

s = 'mssql+pyodbc://sa:52311@localhost/bi'
engine = create_engine(s, echo=False)
Session = sessionmaker(bind=engine)
analysis.session = Session()
analysis.metadata.create_all(bind=engine)

#rollback(datetime.strptime('2011-10-20', '%Y-%m-%d'))
#exit()

sql = "select * from bi_jxc where notetype = 'QC' and computed=0"
cur.execute(sql)
rows = cur.fetchall()
if len(rows)==1:
    qc()
elif len(rows)>1:
    raise Exception(u'不止一条期初数据!')

def main():
    last = warehouse_snap.getLast()
    notedate = None
    if last:
        backdate = last + timedelta(days=1)
        rollback(backdate)
        notedate = backdate

    def charge(day):
        dayWarein(day)
        dayWaremove(day)
        dayWareout(day)

    while 1:
        sql = "select min(notedate) from bi_jxc where computed=0"
        if notedate:
            sql += " and convert(varchar(10), notedate, 120) >= '%s'" % notedate.strftime('%Y-%m-%d')
        cur.execute(sql)
        row = cur.fetchone()
        if not row:
            sleep(10)
            continue

        day = datetime.strftime(row[0], "%Y-%m-%d")
        print '\rcharging %s ...' % day,
        charge(day)
        print '\rcomplete %s.' % day,
        notedate = row[0] + timedelta(days=1)

        # 处理小于notedate的未计算的单据
        sql = "select notedate from bi_jxc where computed=0 \
            and convert(varchar(10), notedate, 120)<'%s' \
            order by notedate" % day
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            print '\rsupplement %s...' % row[0],
            day = datetime.strftime(row[0], "%Y-%m-%d")
            charge(day)
            print '\rsupplement complete.',

    cur.close()

import sys, codecs
#sys.stdout = codecs.getwriter('utf-8')(sys.stdout)
reload(sys)
sys.setdefaultencoding("utf-8")
main()
#import profile
#profile.run('main()','prof.txt')
#import pstats
#p = pstats.Stats('prof.txt')
#p.sort_stats('cumulative').print_stats()

#def main():
##    constr = r"Provider=SQLOLEDB.1;Initial Catalog=JXCDATA0002;Data Source=localhost;Integrated Security=SSPD;"
#    constr = r"Provider=SQLOLEDB.1;Initial Catalog=JXCDATA0002;Data Source=localhost;user ID=sa;Password=52311"
#    conn = adodbapi.connect(constr)
#
#    sql = '''
#    select top 10
#        SUBSTRING(h.custno,1,2) as department_id,
#        h.noteno,h.notedate,m.wareno,h.custno,
#        m.price,m.amount,h.houseno,h.saleman
#    from WAREOUTH h, WAREOUTM m
#    WHERE h.noteno=m.noteno and
#        (h.tag = 1) AND
#        (h.type0 = '01' OR h.type0 = '05')
#    '''
#    sql='''
#    select DEPARTMENT, noteno, notedate, wareno,
#        partnerno, price, amount, houseno, saleman, type, id
#    from bi_jxc
#    where wareno <> '31016666' and computed = 0
#    order by notedate
#    '''
#    c = conn.cursor()
#    c.execute(sql)
#    rows = c.fetchall()
#    sql = 'update bi_jxc set computed=1 where id = %s'
#    for r in rows:
#        doc = {'department_id':r[0].strip().encode('utf-8'),
#               'doc_id': r[1].strip().encode('utf-8'),
#               'notedate': r[2],
#               'product_id': r[3].strip().encode('utf-8'),
#               'customer_id': r[4].strip().encode('utf-8'),
#               'price': abs(r[5]),
#               'quatity': abs(r[6]),
#               'warehouse_id': r[7].strip().encode('utf-8'),
#               'sales_id':r[8] and r[8].strip().encode('utf-8')}
#        t = r[9].strip().encode('utf-8')
#        if t in ('CR','XT'):
#            warehouse.warein(**doc)
#        elif t in ('XS','CT'):
#            warehouse.wareout(**doc)
#        session.commit()
#        c.execute(sql % r[10])
#        conn.commit()
#    c.close()