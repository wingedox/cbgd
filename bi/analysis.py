#coding=utf-8
from datetime import datetime, timedelta
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
    quantity = Column(Numeric)
    price = Column(Numeric)
    amount = Column(Numeric)
    stamp = Column(String(length=10))
    today_in = Column(Numeric)
    today_out = Column(Numeric)
    today_profit = Column(Numeric)
    today_out_cost = Column(Numeric)
    last_in_date = Column(DateTime)
    last_out_date = Column(DateTime)

class warehouse(Base, _warehouse):
    __tablename__ = 'warehouse'

    wareined = Event()
    wareining = Event()
    wareouted = Event()
    wareouting = Event()

    __items = {}
    __inited = False
    __currDate = None

    @classmethod
    def __init(cls):
        for item in session.query(cls):
            k = cls.__getKey(item)
            cls.__items[k] = item
            if not cls.__currDate:
                cls.__currDate = item.stamp
            elif cls.__currDate <> item.stamp:
                raise Exception
        cls.__inited = True

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
    def __checkDate(cls, stamp):
        cls.__currDate = cls.__currDate or stamp
        if cls.__currDate<>stamp:
            for item in cls.__items.values():
                item.today_in = Decimal()
                item.today_out = Decimal()
                item.today_profit = Decimal()
                item.today_out_cost = Decimal()
                item.stamp = stamp
            cls.__currDate = stamp

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
    def warein(cls, doc):
        if not cls.__inited:cls.__init()
        cls.wareining(doc['notedate'], cls.__items)

        stamp = doc['notedate'].strftime('%Y-%m-%d')
        cls.__checkDate(stamp)
        key = cls.__getKey(doc)
        item = cls.__items.get(key)
        if not item:
            item = cls()
            item.department_id = doc['department_id']
            item.product_id = doc['product_id']
            item.warehouse_id = doc['warehouse_id']
            item.quantity = Decimal()
            item.price = Decimal()
            item.amount = Decimal()
            item.stamp = stamp
            item.today_in = Decimal()
            item.today_out = Decimal()
            item.today_profit = Decimal()
            item.today_out_cost = Decimal()
            cls.__items[key] = item
            session.add(item)
        item.quantity += doc['quantity']
        if item.quantity < 0:
            raise Exception(u'出现负库存！%s' % str(doc))
        amount = doc['quantity'] * doc['price']
        item.amount += amount
        if item.quantity == 0 and item.amount <> 0.0:
            raise Exception(u'零库存成本不为零！%s' % str(doc))
        item.last_in_date = doc['notedate']
        item.today_in += doc['quantity']
        if item.quantity == 0:
            session.delete(item)
            del cls.__items[key]
        else:
            item.price = item.amount / item.quantity
        cls.wareined(doc['notedate'], cls.__items)

    @classmethod
    def wareout(cls, doc):
        if not cls.__inited:cls.__init()
        cls.wareouting(doc['notedate'], cls.__items)

        stamp = doc['notedate'].strftime('%Y-%m-%d')
        cls.__checkDate(stamp)
        key = cls.__getKey(doc)
        item = cls.__items.get(key)
        if not item:
            raise Exception(u'库存没有商品！%s' % str(doc))
        item.quantity -= doc['quantity']
        if item.quantity < 0:
            raise Exception(u'出现负库存！%s' % str(doc))
        cost = doc['quantity'] * item.price
        profit = doc['quantity'] * doc['price'] - cost
        item.amount -= cost
        item.last_out_date = doc['notedate']
        item.today_out += doc['quantity']
        item.today_profit += profit
        item.today_out_cost += cost

        cls.wareouted(doc=doc, stock=item)
        if item.quantity == 0:
            session.delete(item)
            del cls.__items[key]

    def costChange(cls,  department_id, product_id, warehouse_id, changeValue):
        s = cls.getStock(department_id, product_id, warehouse_id)
        if not s:
            raise Exception
        s.amount += changeValue
        s.price = s.amount / s.quantity

class warehouse_snap(Base, _warehouse):
    __tablename__ = 'warehouse_snap'
    w1_in = Column(Numeric)
    w1_out = Column(Numeric)
    w1_out_cost = Column(Numeric)
    w1_profit = Column(Numeric)
    w1_stock_product = Column(Numeric)
    w1_stock_days = Column(Numeric)
    w1_trunover = Column(Numeric)

    w2_in = Column(Numeric)
    w2_out = Column(Numeric)
    w2_out_cost = Column(Numeric)
    w2_profit = Column(Numeric)
    w2_stock_product = Column(Numeric)
    w2_stock_days = Column(Numeric)
    w2_trunover = Column(Numeric)

    w4_in = Column(Numeric)
    w4_out = Column(Numeric)
    w4_out_cost = Column(Numeric)
    w4_profit = Column(Numeric)
    w4_stock_product = Column(Numeric)
    w4_stock_days = Column(Numeric)
    w4_trunover = Column(Numeric)

    __last = None
    __items = {}
    __inited = False

    @classmethod
    def _init(cls):
        #        max_stamp = session.query(func.max(snapcls.stamp).label('max_stamp')).subquery()
        #        session.query(snapcls).join(max_stamp, and_(snapcls.stamp == max_stamp.c.max_stamp))
        max_stamp = session.query(func.max(cls.stamp).label('max_stamp')).one()
        s = max_stamp[0]
        if s:
            m = datetime.strptime(s, '%Y-%m-%d')
            cls.__last = datetime.strptime(s, '%Y-%m-%d')
            for i in range(28):
                stamp = m.strftime('%Y-%m-%d')
                for item in session.query(cls).filter(cls.stamp == stamp):
                    k = str({
                        'stamp':item.stamp,
                        'department_id':item.department_id,
                        'product_id':item.product_id,
                        'warehouse_id':item.warehouse_id
                    })
                    cls.__items[k] = item
                m += timedelta(days=-(i+1))
        cls.__inited = True

    @classmethod
    def __insert_stamp(cls, curr, stocks):
        '''检查是否库存状态连续并插入'''
        for stamp in list(rrule(DAILY, byhour=0, byminute=0, bysecond=0,
            dtstart=cls.__last, until=curr))[1:-1]: # 最后一天未结束不快照
            for stock in stocks:
                cls.__do_stock_snap(stamp, stock)
            cls.__last = stamp + relativedelta(days=+1) # 下次应第二天快照

    @classmethod
    def __getSnaps(cls, item, days):
        items = []
        curr = datetime.strptime(item.stamp, '%Y-%m-%d')
        for i in range(days):
            new = curr + timedelta(days=i+1)
            new = new.strftime('%Y-%m-%d')
            k = str({
                'stamp':new,
                'department_id':item.department_id,
                'product_id':item.product_id,
                'warehouse_id':item.warehouse_id
            })
            o = cls.__items.get(k)
            if o:
                items.append(o)
        return items
    @classmethod
    def __getW1Snaps(cls, item):
        return cls.__getSnaps(item, 6)
    @classmethod
    def __getW2Snaps(cls, item):
        return cls.__getSnaps(item, 13)
    @classmethod
    def __getW4Snaps(cls, item):
        return cls.__getSnaps(item, 27)

    @classmethod
    def __setStockSnap(cls, item):
        items = cls.__getW1Snaps(item)
        w_in = Decimal()
        w_out = Decimal()
        w_out_cost = Decimal()
        w_profit = Decimal()
        w_stock_product = Decimal()
        w_stock_days = Decimal()

        for d in items:
            w_in += d.today_in
            w_out += d.today_out
            w_out_cost += d.today_out_cost
            w_profit += d.today_profit
            w_stock_product += d.quantity
            w_stock_days += 1

        item.w1_in = w_in
        item.w1_out = w_out
        item.w1_out_cost = w_out_cost
        item.w1_profit = w_profit
        item.w1_stock_product = w_stock_product
        item.w1_stock_days = w_stock_days

        items = cls.__getW2Snaps(item)
        w_in = Decimal()
        w_out = Decimal()
        w_out_cost = Decimal()
        w_profit = Decimal()
        w_stock_product = Decimal()
        w_stock_days = Decimal()

        for d in items:
            w_in += d.today_in
            w_out += d.today_out
            w_out_cost += d.today_out_cost
            w_profit += d.today_profit
            w_stock_product += d.quantity
            w_stock_days += 1

        item.w2_in = w_in
        item.w2_out = w_out
        item.w2_out_cost = w_out_cost
        item.w2_profit = w_profit
        item.w2_stock_product = w_stock_product
        item.w2_stock_days = w_stock_days

        items = cls.__getW4Snaps(item)
        w_in = Decimal()
        w_out = Decimal()
        w_out_cost = Decimal()
        w_profit = Decimal()
        w_stock_product = Decimal()
        w_stock_days = Decimal()

        for d in items:
            w_in += d.today_in
            w_out += d.today_out
            w_out_cost += d.today_out_cost
            w_profit += d.today_profit
            w_stock_product += d.quantity
            w_stock_days += 1

        item.w4_in = w_in
        item.w4_out = w_out
        item.w4_out_cost = w_out_cost
        item.w4_profit = w_profit
        item.w4_stock_product = w_stock_product
        item.w4_stock_days = w_stock_days

    @classmethod
    def __do_stock_snap(cls, curr, stock):
        # 保存昨天的快照
        stamp = curr + timedelta(days=-1)
        stamp = datetime.strftime(stamp, '%Y-%m-%d')
        # 构建库存快照实体
        item = cls()
        item.stamp = stamp
        item.department_id = stock.department_id
        item.product_id = stock.product_id
        item.warehouse_id = stock.warehouse_id
        item.quantity = stock.quantity
        item.price = stock.price
        item.amount = stock.amount
        item.last_in_date = stock.last_in_date
        item.last_out_date = stock.last_out_date
        item.today_in = stock.today_in
        item.today_out = stock.today_out
        item.today_out_cost = stock.today_out_cost
        item.today_profit = stock.today_profit
        session.add(item) # 准备保存
        cls.__setStockSnap(item) # 计算并设置字段值
        # 去掉缓存中的4周前的快照记录
        new = curr + timedelta(days=-28)
        new = new.strftime('%Y-%m-%d')
        k = str({
            'stamp':new,
            'department_id':item.department_id,
            'product_id':item.product_id,
            'warehouse_id':item.warehouse_id
        })
        if cls.__items.has_key(k):
            cls.__items.pop(k)

    @classmethod
    def __do_snap(cls, currdate, stocks):
        curr = datetime(currdate.year, currdate.month, currdate.day)
        # 如果是当天不需要处理
        if curr == cls.__last:return
        if not cls.__inited:
            cls._init()
        # 首次运行时 cls.__last 为空，赋予初始值
        cls.__last = cls.__last or curr
        # 插入没有业务记录的库存快照
        cls.__insert_stamp(curr, stocks)
        # 补充缺少天的库存快照后最后日期为当前日期
        cls.__last = curr
        # 逐条将当前库存做快照
        for stock in stocks.values():
            cls.__do_stock_snap(curr, stock)

    @classmethod
    def snapToStock(cls, snap):
        stock = warehouse()
        stock.department_id = snap.department_id
        stock.warehouse_id = snap.warehouse_id
        stock.product_id = snap.product_id
        stock.amount = snap.amount
        stock.quantity = snap.quantity
        stock.price = snap.price
        stock.today_in = snap.today_in
        stock.today_out = snap.today_out
        stock.today_out_cost = snap.today_out_cost
        stock.today_profit = snap.today_profit
        stock.stamp = snap.stamp
        stock.last_in_date = snap.last_in_date
        stock.last_out_date = snap.last_out_date
        return stock

    @classmethod
    def do_snap(cls, currdate, stocks):
        cls.__do_snap(currdate, stocks)

warehouse.wareining += warehouse_snap.do_snap
warehouse.wareouting += warehouse_snap.do_snap

class profit_journal(Base, _orm_base):
    __tablename__ = 'profit_journal'

    department_id = Column(String(20))
    doc_id = Column(String(20))
    warehouse_id = Column(String(20))
    customer_id = Column(String(20))
    product_id = Column(String(20))
    sales_id = Column(String(20))
    quantity = Column(Integer)
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
                  'product_id', 'sales_id', 'quantity', 'amount']:
            setattr(item, k, doc[k])
        item.cost = stock.price * item.quantity
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

    exit()

    keys = ['notedate','department_id', 'product_id', 'warehouse_id',
     'quantity', 'price', 'amount', 'sales_id', 'customer_id', 'doc_id']
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
                  'quantity', 'price', 'amount']:
            print k, ':', getattr(i, k)

    for i in session.query(warehouse_snap):
        for k in ['stamp', 'department_id', 'product_id',  'quantity', 'in_today', 'out_today']:
            print k, ':', getattr(i, k)

    for i in session.query(profit_journal):
        for k in ['department_id', 'product_id',  'quantity', 'profit', 'rate']:
            print k, ':', getattr(i, k)


