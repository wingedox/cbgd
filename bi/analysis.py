#coding=utf-8
from datetime import datetime
from decimal import Decimal
from dateutil.relativedelta import relativedelta
from dateutil.rrule import DAILY, rrule
from sqlalchemy.engine import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm.session import sessionmaker
from sqlalchemy.schema import Column, MetaData
from sqlalchemy.sql.expression import func
from sqlalchemy.types import String, Integer, DateTime, Numeric

__author__ = 'GaoJun'

session = None
metadata = MetaData()
Base = declarative_base(metadata=metadata)

class Event(object):
    __handler = {}
    def __init__(self):
        self.__delegates = []

    def __iadd__(self, callback):
        self.__delegates.append(callback)
        return self

    def __isub__(self, callback):
        for i in range(len(self.__delegates)-1, -1, -1):
            if self.__delegates[i] == callback:
                del self.__delegates[i]
                return self
        return self

    def __call__(self, *args, **kw):
        return [ callback(*args, **kw)
                 for callback in self.__delegates]

    @classmethod
    def attach(cls, name, callback):
        cls.__handler[name] = callback

    @classmethod
    def detach(cls, name):
        del cls.__handler[name]

    @classmethod
    def fire(cls, name, *args, **kw):
        return cls.__handler[name](*args, **kw)

class _orm_base(object):
    id = Column(Integer, primary_key=True)
    created_at = Column(DateTime, default=func.now())

class _warehouse(_orm_base):
    department_id = Column(String(20))
    warehouse_id = Column(String(length=50))
    product_id = Column(String(length=50))
    quatity = Column(Numeric)
    price = Column(Numeric)
    amount = Column(Numeric)
    last_in_date = Column(DateTime)
    last_out_date = Column(DateTime)

class warehouse(Base, _warehouse):
    __tablename__ = 'warehouse'
    in_today = Column(Numeric)
    out_today = Column(Numeric)

    wareined = Event()
    wareining = Event()
    wareouted = Event()
    wareouting = Event()

    __items = {}
    __inited = False

    @classmethod
    def __getKey(cls, item):
        if isinstance(item, dict):
            k = str({'department_id':item['department_id'],
                     'product_id':item['product_id'],
                     'warehouse_id':item['warehouse_id']})
        else:
            k = str({'department_id':item.department_id,
                     'product_id':item.product_id,
                     'warehouse_id':item.warehouse_id})
        return k

    @classmethod
    def __init(cls):
        for item in session.query(cls):
            k = cls.__getKey(item)
            cls.__items[k] = item
        cls.__inited = True

    @classmethod
    def getStock(cls, department_id, product_id, warehouse_id):
        if not cls.__inited:cls.__init()
        d = {
             'department_id':department_id,
             'product_id':product_id,
             'warehouse_id':warehouse_id
        }
        key = cls.__getKey(d)
        return cls.__items.get(key)

    @classmethod
    def warein(cls, **kw):
        if not cls.__inited:cls.__init()
        key = cls.__getKey(kw) # todo:更改__getKey 位置
        item = cls.__items.get(key)
        if not item:
            item = cls()
            for k in ['department_id', 'product_id', 'warehouse_id']:
                setattr(item, k, kw[k])
            item.quatity = Decimal()
            item.price = Decimal()
            item.amount = Decimal()
            k = cls.__getKey(item)
            cls.__items[k] = item
            session.add(item)
        cls.wareining(doc=kw, stock=item)
        item.quatity += kw['quatity']
        if item.quatity < 0:
            raise Exception(u'出现负库存！%s' % str(kw))
        amount = kw['quatity'] * kw['price']
        item.amount += amount
        if item.quatity == 0 and item.amount <> 0.0:
            raise Exception(u'零库存成本不为零！%s' % str(kw))
        if item.quatity == 0:
            session.delete(item)
            del cls.__items[key]
        else:
            item.price = item.amount / item.quatity
        item.last_in_date = kw['notedate']
        cls.wareined(doc=kw, stock=item)

    @classmethod
    def wareout(cls, **kw):
        if not cls.__inited:cls.__init()
        key = cls.__getKey(kw)
        item = cls.__items.get(key)
        if not item:
            raise Exception(u'库存没有商品！%s' % str(kw))
        cls.wareouting(doc=kw, stock=item)
        item.quatity -= kw['quatity']
        if item.quatity < 0:
            raise Exception(u'出现负库存！%s' % str(kw))
        item.amount -= kw['quatity'] * item.price
        item.last_out_date = kw['notedate']
        cls.wareouted(doc=kw, stock=item)
        if item.quatity == 0:
        #            del cls.__items[item]
            session.delete(item)
            del cls.__items[key]

    def costChange(cls,  department_id, product_id, warehouse_id, changeValue):
        s = cls.getStock(department_id, product_id, warehouse_id)
        if not s:
            raise Exception
        s.amount += changeValue
        s.price = s.amount / s.quatity

class warehouse_snap(Base, _warehouse):
    __tablename__ = 'warehouse_snap'
    stamp = Column(String(length=50))
    in_today = Column(Numeric)
    out_today = Column(Numeric)

    __last = None
    __items = {}
    __inited = False

    @classmethod
    def __getKey(cls, item):
        if isinstance(item, dict):
            k = str({'department_id':item['department_id'],
                     'product_id':item['product_id'],
                     'warehouse_id':item['warehouse_id']})
        else:
            k = str({'department_id':item.department_id,
                     'product_id':item.product_id,
                     'warehouse_id':item.warehouse_id})
        return k

    @classmethod
    def getstock(cls, **kw):
        k = cls.__getKey(kw)
        if cls.__items.has_key(k):
            return cls.__items[k]
        else:
            return None

    @classmethod
    def _init(cls):
        #        max_stamp = session.query(func.max(snapcls.stamp).label('max_stamp')).subquery()
        #        session.query(snapcls).join(max_stamp, and_(snapcls.stamp == max_stamp.c.max_stamp))
        max_stamp = session.query(func.max(cls.stamp).label('max_stamp')).one()
        s = max_stamp[0]
        if s:
            for item in session.query(cls).filter(cls.stamp == s):
                k = cls.__getKey(item)
                cls.__items[k] = item
            cls.__last = datetime.strptime(s, '%Y-%m-%d')
        cls.__inited = True

    @classmethod
    def getstock(cls, **kw):
        k = cls.__getKey(kw)
        if cls.__items.has_key(k):
            return cls.__items[k]
        else:
            return None

    @classmethod
    def __insert_stamp(cls, *args, **kw):
        '''检查是否库存状态连续并插入'''
        curr = kw['doc']['notedate']
        for stamp in list(rrule(DAILY, byhour=0, byminute=0, bysecond=0,
            dtstart=cls.__last, until=curr))[1:-1]: # 最后一天未结束不快照
            cls.__items = {}
            for item in session.query(warehouse).all():
                stock = cls()
                stock.warehouse_id = item.warehouse_id
                stock.department_id = item.department_id
                stock.product_id = item.product_id
                stock.quatity = item.quatity
                stock.stamp = datetime.strftime(stamp, '%Y-%m-%d')
                stock.in_today = 0
                stock.out_today = 0
                k = cls.__getKey(stock)
                cls.__items[k] = stock
                session.add(stock)
            cls.__last = stamp + relativedelta(days=+1) # 下次应第二天快照

    @classmethod
    def do_snap_in(cls, *args, **kw):
        cls.__do_snap('in', *args, **kw)

    @classmethod
    def do_snap_out(cls, *args, **kw):
        cls.__do_snap('out', *args, **kw)

    @classmethod
    def __do_snap(cls, type, *args, **kw):
        if not cls.__inited:
            cls._init()
        doc = kw['doc']
        curr = doc['notedate']
        curr = datetime(curr.year, curr.month, curr.day)
        # 首次运行时 cls.__last 为空，赋予初始值
        cls.__last = cls.__last or curr
        if curr < cls.__last:
            raise Exception(u'单据时间已经过期！%s' % str(kw))
        # 插入没有业务记录的库存快照
        cls.__insert_stamp(*args, **kw)
        cls.__last = curr
        stamp = datetime.strftime(curr, '%Y-%m-%d')
        f = {}
        for k in ['department_id', 'product_id', 'warehouse_id']:
            f[k] = doc[k]
        item = cls.getstock(**f)
        if not item:
            item = cls()
            item.stamp = stamp
            item.department_id = doc['department_id']
            item.product_id = doc['product_id']
            item.warehouse_id = doc['warehouse_id']
            item.quatity = 0
            item.in_today = 0
            item.out_today = 0
            k = cls.__getKey(item)
            cls.__items[k] = item
            session.add(item)
        elif not item.stamp == stamp:
            t = cls()
            t.stamp = stamp
            t.department_id = item.department_id
            t.product_id = item.product_id
            t.warehouse_id = item.warehouse_id
            t.quatity = item.quatity
            t.in_today = 0
            t.out_today = 0
            k = cls.__getKey(item)
            cls.__items.pop(k)
            k = cls.__getKey(t)
            cls.__items[k] = t
            session.add(t)
            item = t
        if type == 'in':
            item.quatity +=  doc['quatity']
            item.in_today += doc['quatity'] # todo：在warehouse 中增加 in_today out_today
        elif type == 'out':
            item.quatity -= doc['quatity']
            item.out_today += doc['quatity']

warehouse.wareining += warehouse_snap.do_snap_in
warehouse.wareouting += warehouse_snap.do_snap_out

class profit_journal(Base, _orm_base):
    __tablename__ = 'profit_journal'

    department_id = Column(String(20))
    doc_id = Column(String(20))
    warehouse_id = Column(String(20))
    customer_id = Column(String(20))
    product_id = Column(String(20))
    sales_id = Column(String(20))
    quatity = Column(Integer)
    amount = Column(Numeric)
    cost = Column(Numeric)
    profit = Column(Numeric)
    rate = Column(Numeric)

    @classmethod
    def tally(cls, *args, **kw):
        item = cls()
        doc = kw['doc']
        stock = kw['stock']

        for k in ['department_id', 'warehouse_id', 'customer_id',
                  'product_id', 'sales_id', 'quatity', 'amount']:
            setattr(item, k, doc[k])
        item.cost = stock.price * item.quatity
        item.profit = item.amount - item.cost
        item.rate = item.profit / item.amount
        session.add(item)

#warehouse.wareouting += profit_journal.tally
if __name__ == '__main__':
#    global session
    s = 'sqlite:///:memory:'
    s = 'mssql+pymssql://sa:52311@localhost/bi'
    engine = create_engine(s, echo=False)
    Session = sessionmaker(bind=engine)
    session = Session()
    metadata.create_all(bind=engine)

    main()
    exit()

    keys = ['notedate','department_id', 'product_id', 'warehouse_id',
     'quatity', 'price', 'amount', 'sales_id', 'customer_id', 'doc_id']
    doc1 = dict(zip(keys,[datetime.strptime('2011-12-20 12:12:23', '%Y-%m-%d %H:%M:%S'),
                          '001','1','1',2,100,200,'1','1','1']))
    doc2 = dict(zip(keys,[datetime.strptime('2011-12-25 12:12:23', '%Y-%m-%d %H:%M:%S'),
                          '001','1','1',3,200,600,'1','1','1']))
    doc3 = dict(zip(keys,[datetime.strptime('2011-12-31 12:12:23', '%Y-%m-%d %H:%M:%S'),
                          '001','1','1',3,200,600,'1','1','1']))

    warehouse.warein(**doc1)
    session.commit()
    warehouse.warein(**doc2)
    session.commit()
#    warehouse.wareout(**doc1)
#    session.commit()
    warehouse.wareout(**doc3)
    session.commit()

    for i in session.query(warehouse):
        for k in ['department_id', 'product_id', 'warehouse_id',
                  'quatity', 'price', 'amount']:
            print k, ':', getattr(i, k)

    for i in session.query(warehouse_snap):
        for k in ['stamp', 'department_id', 'product_id',  'quatity', 'in_today', 'out_today']:
            print k, ':', getattr(i, k)

    for i in session.query(profit_journal):
        for k in ['department_id', 'product_id',  'quatity', 'profit', 'rate']:
            print k, ':', getattr(i, k)


