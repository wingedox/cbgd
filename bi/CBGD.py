#coding=utf-8

from datetime import datetime, timedelta
from time import sleep
#from adodbapi import adodbapi
import pyodbc
#import pymssql
from sqlalchemy.engine import create_engine
from sqlalchemy.exc import ProgrammingError
from sqlalchemy.orm.session import sessionmaker
from analysis import warehouse, warehouse_snap, note
import analysis

__author__ = 'GaoJun'

_conn = None
_cur = None
_inited = False

_computed_sql = "update bi_jxc set computed=1 where id=%s"
def buildDoc(sql):
    _cur.execute(sql)
    rows = _cur.fetchall()
    if _cur.rowcount==0:raise Exception
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
    _cur.execute(_computed_sql % id)
    _conn.commit()

def qc():
    query = "select * from bi_jxc where notetype='QC' and computed=0"
    _cur.execute(query)
    rows = _cur.fetchall()
    if len(rows)==1:
        query = "select uValue from uparameter where uSection = 'options' and uSymbol = 'beginmonth'"
        _cur.execute(query)
        row = _cur.fetchone()
        beginmonth = row[0].strip()
        query = "select uValue from uparameter where uSection = 'options' and uSymbol = 'beginyear'"
        _cur.execute(query)
        row = _cur.fetchone()
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
        _cur.execute(query)
        rows = _cur.fetchall()
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
        _cur.execute(sql)
        _conn.commit()

def sales(noteno, chargedate=None):
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
    _cur.execute(sql)
    rows = _cur.fetchall()
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
            doc.chargedate = chargedate or doc.notedate
            warehouse.wareout_check(doc)
            docs.append(doc)
        for doc in docs:
            warehouse.wareout(doc)
    except Exception, e:
        raise Exception(u'记帐失败：%s;%s' % (noteno, e.message))

def returnOfSales(noteno, chargedate=None):
    sql = '''
    SELECT h.notedate, m.noteno, SUBSTRING(houseno,1,2) as department, h.custno as partnerno,
    case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno,
    e.Name as saleman, m.wareno, m.amount as amount, m.price as price, m.curr as curr
    FROM REFUNDOUTM m, REFUNDOUTH h, EMPLOYE e
    where h.noteno = m.noteno and h.saleman=e.code and h.noteno = '%s'
    '''
    sql = sql % noteno
    _cur.execute(sql)
    rows = _cur.fetchall()
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
        doc.chargedate = chargedate or doc.notedate
        warehouse.warein(doc)

def purchase(noteno, chargedate=None):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
    h.provno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, m.wareno,
    m.amount, m.price, m.curr
    FROM WAREINH h, WAREINM m
    WHERE h.noteno=m.noteno and h.noteno='%s'
    '''
    sql = sql % noteno
    _cur.execute(sql)
    rows = _cur.fetchall()
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
        doc.chargedate = chargedate or doc.notedate
        warehouse.warein(doc)

def returnOfPurchase(noteno, chargedate=None):
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
    _cur.execute(sql)
    rows = _cur.fetchall()
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
        doc.chargedate = chargedate or doc.notedate
        warehouse.wareout(doc)

def salesChange(noteno, chargedate=None):pass

def costChange(noteno, chargedate=None):
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
    stockMove(noteno, None, True)

def stockMove(noteno, chargedate=None, check=False):
    sql = '''
    select h.noteno, h.notedate, h.oldhouseno, h.newhouseno,
        m.wareno, m.amount, substring(h.oldhouseno,1,2) as olddept,
        substring(h.newhouseno,1,2) as newdept, m.id
    from warealloth h, wareallotm m
    where h.noteno=m.noteno and h.noteno='%s'
    ''' % noteno
    _cur.execute(sql)
    rows = _cur.fetchall()
    if _cur.rowcount==0:raise Exception
    for row in rows:
        # 移库单明细有可能数量为零，跳过
        if row[5] == 0:
            continue
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
        doc_yc.chargedate = chargedate or doc_yc.notedate
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
        doc_yr.chargedate = chargedate or doc_yr.notedate
        doc_yr.price = s.price
        doc_yr.amount = doc_yr.quantity * doc_yr.price
        warehouse.warein_check(doc_yr)

        if not check:
            warehouse.wareout(doc_yc)
            warehouse.warein(doc_yr)

def processQC():
    sql = "select * from bi_jxc where notetype = 'QC' and computed=0"
    _cur.execute(sql)
    rows = _cur.fetchall()
    if len(rows)==1:
        qc()
    elif len(rows)>1:
        raise Exception(u'不止一条期初数据!')

def dayWarein(day, chargedate=None):
    sql = "select noteno, notetype, id from bi_jxc where notetype in ('CR','XT') and computed=0 and \
    CONVERT(varchar(10), notedate, 120)='%s'" % day
    _cur.execute(sql)
    rows = _cur.fetchall()
    for row in rows:
        n = row[0].strip()
        t = row[1].strip()
        i = row[2]
        if t=='XT':
            returnOfSales(n, chargedate)
        elif t=='CR':
            purchase(n, chargedate)
        save(i)

def dayWaremove(day, chargedate=None):
    # 对于移出库库房没有负库存限制，可能先由A库移到B库，此时A库为负库存
    # 再由C库移到A库。
    errors = []
    for j in range(2):
        sql = "select noteno, notetype, id from bi_jxc where notetype in ('YK') and computed=0 and \
        CONVERT(varchar(10), notedate, 120)='%s' order by notedate, noteno" % day
        _cur.execute(sql)
        rows = _cur.fetchall()
        for row in rows:
            n = row[0].strip()
            i = row[2]
            try:
                # 先检查该移库单所有条目是否都能通过
                checkMove(n)
                stockMove(n, chargedate)
                save(i)
            except Exception, e:
                if i in errors:
                    print (u'移库错误,%s' % e.message)
                else:
                    errors.append(i)
                analysis.session.rollback()
                _conn.rollback()
                continue

def dayWareout(day, chargedate=None):
    sql = "select noteno, notetype, id from bi_jxc where notetype in ('CT','XS') and computed=0 and \
    CONVERT(varchar(10), notedate, 120)='%s' order by notedate" % day
    _cur.execute(sql)
    rows = _cur.fetchall()
    for row in rows:
        try:
            n = row[0].strip()
            t = row[1].strip()
            i = row[2]
            if t=='XS':
                sales(n, chargedate)
            elif t=='XG':
                salesChange(n, chargedate)
            elif t=='CT':
                returnOfPurchase(n, chargedate)
            save(i)
        except Exception, e:
            print e.message

def rollback(backdate):
    analysis.rollback(backdate)
    s = backdate.strftime('%Y-%m-%d')
    sql = "update bi_jxc set computed=0, ChargeDate=NULL "\
          "where ChargeDate>='%s'" % s
    _cur.execute(sql)
    _conn.commit()

def initJXC():
    script = None
    try:
        f = open('sql/Table_bi_jxc_drop_create.sql', 'r')
        script = f.read()
        f.close()
        _cur.execute(script)
        f = open('sql/Table_bi_jxc_copy.sql', 'r')
        script = f.read()
        f.close()
        _cur.execute(script)
        _conn.commit()
        _inited = True
    except Exception, e:
        print e.message
        exit()

def copyJXC(startDay):
    try:
        f = open('sql/Table_bi_jxc_copy_day.sql', 'r')
        script = f.read()
        script = script % startDay.strftime('%Y-%m-%d')
        _cur.execute(script)
        _conn.commit()
    except Exception, e:
        print e.message

def init():
    print 'Init tables...',
    initJXC()
    analysis.metadata.drop_all(bind=_engine)
    analysis.metadata.create_all(bind=_engine)
    qc()
    print 'Down.'

_host = 'localhost'
_pwd = '52311'
_db = 'jxcdata0002'
#_conn = pymssql.connect(host=_host,user='sa',password=_pwd,database=_db)
#constr = r"Provider=SQLOLEDB.1;Initial Catalog=%s;Data Source=%s;user ID=%s;Password=%s;"\
#    % (_db, _host, 'sa', _pwd)
#_conn = adodbapi.connect(constr)
_conn = pyodbc.connect('DRIVER={SQL Server};DATABASE=%s;SERVER=%s;UID=%s;PWD=%s'% (
    _db, _host, 'sa', _pwd))
_cur = _conn.cursor()
#conn_bi = pymssql.connect(host=_host,user='sa',password=_pwd,database='bi')
#cur_bi = conn_bi.cursor()

_s = 'mssql+pyodbc://sa:%s@localhost/%s' % (_pwd, _db)
#s = 'mssql+pymssql://sa:52311@localhost/bi'
_engine = create_engine(_s, echo=False)
_Session = sessionmaker(bind=_engine, expire_on_commit=False)
analysis.session = _Session()
analysis.metadata.create_all(bind=_engine)

def main(rollback_day=True, Init=False):
    last = None
    if Init:
        init()
    else:
        sql = "SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[bi_jxc]') " \
              "AND type in (N'U')"
        _cur.execute(sql)
        row = _cur.fetchone()
        if not (row and row[0]):
            init()
        else:
            last = warehouse_snap.getLast()
    chargedate = None
    if last:
        backdate = last + timedelta(days=1)
        if rollback_day:
            print "rollback to %s..." % backdate.strftime('%Y-%m-%d'),
            rollback(backdate)
            print 'complete!'
        chargedate = backdate

    def charge(day, chargedate=None):
        try:
            dayWarein(day, chargedate)
            dayWaremove(day, chargedate)
            dayWareout(day, chargedate)
        except ProgrammingError, e:
            print e.message.decode('gbk')
            exit()

#    i = 0
    while 1:
        sql = "select min(notedate) from bi_jxc where computed=0"
        if chargedate:
            sql += " and convert(varchar(10), notedate, 120) >= '%s'" % chargedate.strftime('%Y-%m-%d')
        _cur.execute(sql)
        row = _cur.fetchone()
        if not row[0]:
            sleep(10)
            copyJXC(chargedate)
            continue

        day = datetime.strftime(row[0], "%Y-%m-%d")
        print 'charging %s ...' % day,
        charge(day)
        print 'complete!'

        # 处理小于notedate的未计算的单据
        sql = "select notedate from bi_jxc where computed=0 \
            and convert(varchar(10), notedate, 120) < '%s' \
            order by notedate" % day
        _cur.execute(sql)
        rows = _cur.fetchall()
        for row in rows:
            print '\tsupplement %s...' % row[0].strftime('%Y-%m-%d'),
            day = datetime.strftime(row[0], "%Y-%m-%d")
            charge(day, chargedate)
            print 'complete!'
        chargedate = row[0] + timedelta(days=1)
#        i += 1
#        if i>38:break

    _cur.close()
# todo: 库存周转
# todo：利润记账
# todo：更正记账
# todo: 移库不记out
# todo：销售退回冲减利润
# todo：修改为记明细帐再记库存
# todo: rollback 到某天比如8月4日，但原来8月4日补记了8月2日的一张单据，此时8月2日那张单据已经标记为已记帐

#rollback(datetime.strptime('2011-08-01', '%Y-%m-%d'))
#exit()
main(Init=True)
#main()
#import profile
#profile.run('main(Init=True)','prof.txt')
#import pstats
#p = pstats.Stats('prof.txt')
#p.sort_stats('cumulative').print_stats()
#p.sort_stats('time').print_stats()