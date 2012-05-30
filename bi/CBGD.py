#coding=utf-8

from datetime import datetime
import pymssql
from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import sessionmaker
from analysis import warehouse
import analysis

__author__ = 'GaoJun'

_conn = None
cur = None
conn_bi = None
cur_bi = None

computed_sql = "update bi_jxc set computed=1 where id=%s"
def init():pass

#f = open('log.txt', 'w')
#def log(msg, doc=None, noteno=None, s=None):
#    if msg=='\t':
#        if doc['product_id']=='040120001' and doc['warehouse_id']=='FX010101':
#            f.write('%s:,%s,%s\n' % (noteno, s and s.quatity, str(doc)))

def __getKey(item):
    if isinstance(item, dict):
        k = str({'department_id':item['department_id'],
                 'product_id':item['product_id'],
                 'warehouse_id':item['warehouse_id']})
    else:
        k = str({'department_id':item.department_id,
                 'product_id':item.product_id,
                 'warehouse_id':item.warehouse_id})
    return k

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
            'quatity': abs(r[8]),
            'warehouse_id': r[4].strip(),
            'sales_id':r[5] and r[5].strip()
        }
        docs.append(doc)
    return docs

def save(id):
    analysis.session.commit()
    cur.execute(computed_sql % id)
    _conn.commit()

def qc():
    query = "select * from bi_jxc where notetype='QC' and computed=0"
    cur.execute(query)
    cur.fetchall()
    if cur.rowcount==1:
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
        query = query.encode('cp936')
        cur.execute(query)
        rows = cur.fetchall()
        for row in rows:
            doc = {
                'department_id':row['department'],
                'warehouse_id':row['houseno'],
                'product_id':row['wareno'],
                'quatity':row['amount'],
                'price':row['price'],
            }
            key = __getKey(doc)
            warehouse.warein(doc)
        analysis.session.commit()
        sql ="update bi_jxc set computed=1 where notetype='QC'"
        cur.execute(sql)
        _conn.commit()

def sales(noteno):
    sql = u'''
    SELECT h.notedate, RTRIM(h.noteno) as noteno, SUBSTRING(h.houseno,1,2) as department,
    h.custno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno,e.Name as saleman,NULL as dptno, m.wareno,
    m.amount, m.price, m.curr
    FROM WAREOUTM m, WAREOUTH h, EMPLOYE e
    -- ltrim(h.noteno) 自编号的单据号可能被人为在前加入空格，noteno已经去掉前后空格，导致查询为空
    WHERE rtrim(ltrim(h.noteno))='%s' AND m.noteno=h.noteno and h.saleman=e.code
    '''
    sql = sql % noteno
    docs = buildDoc(sql.encode('cp936'))
    for doc in docs:
        if doc['product_id'] <> '31016666':
#            s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
#            log('\t', doc, noteno, s)
            warehouse.wareout(**doc)

def returnOfSales(noteno):
    sql = '''
    SELECT h.notedate, m.noteno, SUBSTRING(houseno,1,2) as department, h.custno as partnerno,
    case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno,
    e.Name, NULL as dptno, m.wareno, m.amount as amount, m.price as price, m.curr as curr
    FROM REFUNDOUTM m, REFUNDOUTH h, EMPLOYE e
    where h.noteno = m.noteno and h.saleman=e.code and h.noteno = '%s'
    '''
    sql = sql % noteno
    docs = buildDoc(sql)
    for doc in docs:
#        s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
#        log('\t', doc, noteno, s)
        warehouse.warein(**doc)

def purchase(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
    h.provno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, NULL as dptno, m.wareno,
    m.amount, m.price, m.curr
    FROM WAREINH h, WAREINM m
    WHERE h.noteno=m.noteno and h.noteno='%s'
    '''
    sql = sql % noteno
    docs = buildDoc(sql)
    for doc in docs:
#        s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
#        log('\t', doc, noteno, s)
        warehouse.warein(**doc)

def returnOfPurchase(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department, h.provno as partnerno,
    case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, NULL as deptno, m.wareno,
    m.amount as amount,
    m.price as price, m.curr as curr
    FROM REFUNDINH h, REFUNDINM m
    WHERE h.noteno=m.noteno and h.noteno = '%s'
    '''
    sql = sql % noteno
    docs = buildDoc(sql)
    for doc in docs:
#        s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
#        log('\t', doc, noteno, s)
        warehouse.wareout(**doc)

def salesChange(noteno):pass

def costChange(noteno):
    sql = '''
    SELECT h.notedate, h.noteno, SUBSTRING(h.houseno,1,2) as department,
    h.provno as partnerno, case when h.houseno in ('FX010101','FX01010103','FX01010104')
    then 'FX010101' else h.houseno end as houseno, NULL as saleman, NULL as dptno, m.wareno,
    null as amount, null as price, m.curr1 as curr
    FROM WAREINH h, WAREINM m
    WHERE h.noteno=m.noteno and h.noteno = '%s'
    ''' % noteno
    docs = buildDoc(sql)
    for doc in docs:
        warehouse.costChange(doc['department'],
            doc['wareno'], doc['houseno'], doc['curr'])

def stockMove(noteno):
    sql = '''
    select h.noteno, h.notedate, h.oldhouseno, h.newhouseno,
        m.wareno, m.amount, substring(h.oldhouseno,1,2) as olddept,
        substring(h.newhouseno,1,2) as newdept
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
        doc = {
            'notedate':row[1],
            'department_id':row[6].strip(),
            'warehouse_id':old,
            'product_id':row[4].strip(),
            'quatity':row[5]
        }

        s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
        if not s:
            raise Exception(u'没有库存。%s' % str(doc))
#        log('\t', doc, noteno, s)
        warehouse.wareout(**doc)
        doc = {
            'notedate':row[1],
            'department_id':row[7].strip(),
            'warehouse_id':new,
            'product_id':row[4].strip(),
            'quatity':row[5],
            'price':s.price,
        }
#        s = warehouse.getStock(doc['department_id'],doc['product_id'],doc['warehouse_id'])
#        log('\t', doc, noteno, s)
        warehouse.warein(**doc)

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
    # 再由C库移到A库。因此先查询出C移到A的记录做处理
#    sql = '''
#    select a.noteno, 'YK' as notetype, a.id from
#    (SELECT h.*, m.wareno, j.id
#    FROM WAREALLOTH h,WAREALLOTM m,bi_jxc j where h.noteno = m.noteno
#    and h.noteno=j.noteno and j.notetype='YK' and j.computed=0 and
#    CONVERT(varchar(10), j.notedate, 120) = '%s') a,
#    (SELECT h.*, m.wareno, j.id
#    FROM WAREALLOTH h,WAREALLOTM m,bi_jxc j where h.noteno = m.noteno
#    and h.noteno=j.noteno and j.notetype='YK' and j.computed=0 and
#    CONVERT(varchar(10), j.notedate, 120) = '%s') b
#    where a.NewHouseno=b.Oldhouseno and a.wareno=b.wareno
#    ''' % (day, day)
#    cur.execute(sql)
#    rows = cur.fetchall()
#    for row in rows:
#        n = row[0].strip()
#        t = row[1].strip()
#        i = row[2]
#        if t=='YK':
#            stockMove(n)
#        save(i)
    for i in range(2):
        sql = "select noteno, notetype, id from bi_jxc where notetype in ('YK') and computed=0 and \
        CONVERT(varchar(10), notedate, 120)='%s' order by notedate, noteno" % day
        cur.execute(sql)
        rows = cur.fetchall()
        for row in rows:
            n = row[0].strip()
            t = row[1].strip()
            i = row[2]
            try:
                stockMove(n)
                save(i)
            except :
                analysis.session.rollback()
                _conn.rollback()
                continue

def dayWareout(day):
    sql = "select noteno, notetype, id from bi_jxc where notetype in ('CT','XS') and computed=0 and \
    CONVERT(varchar(10), notedate, 120)='%s' order by notedate" % day
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
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

_host = 'localhost'
_pwd = '52311'
_db = 'jxcdata0002'
_conn = pymssql.connect(host=_host,user='sa',password=_pwd,database=_db)
cur = _conn.cursor()

conn_bi = pymssql.connect(host=_host,user='sa',password=_pwd,database='bi')
cur_bi = conn_bi.cursor()

s = 'mssql+pyodbc://sa:52311@localhost/bi'
engine = create_engine(s, echo=False)
Session = sessionmaker(bind=engine)
analysis.session = Session()
analysis.metadata.create_all(bind=engine)

sql = "select * from bi_jxc where notetype = 'QC' and computed=0"
cur.execute(sql)
cur.fetchall()
if cur.rowcount==1:
    qc()
elif cur.rowcount<>0:
    raise Exception(u'不止一条期初数据!')

while 1:
    sql = "select min(notedate) from bi_jxc where computed=0"
    cur.execute(sql)
    row = cur.fetchone()
    if not row:break
    notedate = datetime.strftime(row[0], "%Y-%m-%d")

    dayWarein(notedate)
    dayWaremove(notedate)
    dayWareout(notedate)
#    analysis.session.commit()
#    cur.execute(computed_sql % notedate)
#    _conn.commit()

#    try:
#        dayWarein(notedate)
#        dayWaremove(notedate)
#        dayWareout(notedate)
#        analysis.session.commit()
#        cur.execute(computed_sql % notedate)
#        _conn.commit()
#    except Exception, e:
#        analysis.session.rollback()
#        _conn.rollback()
#        print e.message.encode('utf-8')
#        break

    print '\r%s' % notedate,
cur.close()
cur_bi.close()
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