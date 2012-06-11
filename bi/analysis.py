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
_Base = declarative_base(metadata=metadata)

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

class note(object):
    def __init__(self):
        self.department_id = None
        self.warehouse_id = None
        self.product_id = None
        self.stamp = None
        self.sales = None
        self.price = None
        self.quantity = None
        self.amount = None
        self.noteno = None
        self.notedate = None
        self.partner_id = None
        self.notetype = None
        self.out_profit = None

    def __str(self, key_dict):
        k = '%s&%s&%s' % (
            key_dict['department_id'],
            key_dict['warehouse_id'],
            key_dict['product_id']
        )
        if key_dict.has_key('stamp'):
            k = '%s&%s' % (k, key_dict['stamp'])
        return k

    def __key(self):
        # 使用adodbapi时返回的数据编码是unicode,str()后
        # 字串形式为u'abc'，导致key不正确
        d = isinstance(self.department_id, unicode) and\
            self.department_id.encode('utf-8') or\
            self.department_id
        w = isinstance(self.warehouse_id, unicode) and\
            self.warehouse_id.encode('utf-8') or\
            self.warehouse_id
        p = isinstance(self.product_id, unicode) and\
            self.product_id.encode('utf-8') or\
            self.product_id
        return {
            'department_id':d,
            'warehouse_id':w,
            'product_id':p
        }
    @property
    def key(self):
        return str(self.__key())

    @property
    def stamp_key(self):
        k = self.__key()
        k['stamp'] = isinstance(self.stamp, unicode) and\
                     self.stamp.encode('utf-8') or self.stamp
        return self.__str(k)

    @classmethod
    def __getNote(cls, stock):
        doc = cls()
        doc.department_id = stock.department_id
        doc.warehouse_id = stock.warehouse_id
        doc.product_id = stock.product_id
        if hasattr(stock, 'stamp'):
            doc.stamp = stock.stamp
        return doc

    @classmethod
    def getKeyByStock(cls, stock):
        doc = cls.__getNote(stock)
        return doc.key

    @classmethod
    def getStampKeyByStock(cls, stock):
        doc = cls.__getNote(stock)
        return doc.stamp_key

    @classmethod
    def getNoteByKey(cls, key):
        doc = cls()
        values = key.split('&')
        doc.department_id = values[0]
        doc.warehouse_id = values[1]
        doc.product_id = values[2]
        if len(values) == 4:
            doc.stamp = values[3]
        return doc

    @classmethod
    def getKeyByStackDate(cls, date, stock):
        doc = cls.__getNote(stock)
        k = doc.__key()
        stamp = cls.dateToStamp(date)
        k['stamp'] = stamp
        return doc.__str(k)

    @classmethod
    def dateToStamp(cls, date):
        stamp = None
        if isinstance(date, datetime):
            stamp = date.strftime('%Y-%m-%d')
        else:
            stamp = isinstance(date, unicode) and\
                    date.encode('utf-8') or date
        return stamp
class _warehouse(_orm_base):
    department_id = Column(String(20))
    warehouse_id = Column(String(20))
    product_id = Column(String(20))
    quantity = Column(Numeric)
    price = Column(Numeric(19,4))
    amount = Column(Numeric(19,4))
    stamp = Column(String(10))
    today_in = Column(Numeric)
    today_out = Column(Numeric)
    today_profit = Column(Numeric(19,4))
    today_out_cost = Column(Numeric(19,4))
    last_in_date = Column(DateTime)
    last_out_date = Column(DateTime)

class warehouse(_Base, _warehouse):
    __tablename__ = 'bi_warehouse'

    wareined = Event()
    wareining = Event()
    wareouted = Event()
    wareouting = Event()

    __items = {}
    __inited = False
    __currDate = None
    __zeroStcoks = []

    @classmethod
    def __init(cls):
        for item in session.query(cls):
            k = note.getKeyByStock(item)
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
    def __checkStock(cls, stamp):
        cls.__currDate = cls.__currDate or stamp
        if cls.__currDate<>stamp:
            for key, item in cls.__items.items():
                item.today_in = Decimal()
                item.today_out = Decimal()
                item.today_profit = Decimal()
                item.today_out_cost = Decimal()
                item.stamp = stamp
                cls.__checkZeroStock(key, item)
            session.commit()
            cls.__currDate = stamp

    @classmethod
    def __checkZeroStock(cls, key, item):
        # 删除不用的库存（数量和成本为零，今天没有出入库的产品）
        if item.quantity == 0 and item.amount == 0 and\
           item.today_in == 0 and item.today_out == 0:
            session.delete(item)
            del cls.__items[key]

    @classmethod
    def getStock(cls, key):
        if not cls.__inited:cls.__init()
        return cls.__items.get(key)

    @classmethod
    def __doc_check(cls, doc):
        if doc.quantity < 1:
            raise Exception(u'单据数量小于1,单号:%s，类型:%s，数量:%s' %
                   (doc.noteno, doc.notetype, doc.quantity))

    @classmethod
    def warein_check(cls, doc, out_error=True):
        cls.__doc_check(doc)
        if not cls.__inited:cls.__init()
        key = doc.key
        item = cls.__items.get(key)
        if item:
            amount = doc.price * doc.quantity
            quantity = item.quantity + doc.quantity
            if item.amount + amount < 0 and out_error:
                print (u'出现库存成本为负！单号:%s,商品:%s,库房:%s,数量:%.4f,成本:%.4f' %
                                (doc.noteno, doc.product_id, doc.warehouse_id,quantity,item.amount+amount))
            if quantity == 0 and\
                item.amount + amount <> 0 and out_error:
                print (u'出现库存为零成本不为零！单号:%s,商品:%s,库房:%s,数量:%.4f,成本:%.4f' %
                       (doc.noteno, doc.product_id, doc.warehouse_id,quantity,item.amount+amount))
        elif doc.price < 0 and out_error:
            print (u'库存没有商品,入库单价为负值：单号:%s,商品:%s,库房:%s' %
                (doc.noteno, doc.product_id, doc.warehouse_id))

    @classmethod
    def warein(cls, doc):
        if not cls.__inited:cls.__init()
        cls.warein_check(doc, False)
        stamp = doc.notedate.strftime('%Y-%m-%d')
        cls.__checkStock(stamp)

        key = doc.key
        item = cls.__items.get(key)
        cls.wareining(doc, item, cls.__items)
        if not item:
            item = cls()
            item.department_id = doc.department_id
            item.product_id = doc.product_id
            item.warehouse_id = doc.warehouse_id
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
        amount = doc.quantity * doc.price
        item.quantity += doc.quantity
        item.amount += amount
        item.last_in_date = doc.notedate
        if doc.notetype == 'CR':
            item.today_in += doc.quantity
        elif doc.notetype == 'XT':
            item.today_out -= doc.quantity
#            item.today_profit =
        item.price = item.amount / item.quantity
        cls.wareined(doc, item, cls.__items)

    @classmethod
    def wareout_check(cls, doc):
        cls.__doc_check(doc)
        if not cls.__inited:cls.__init()
        key = doc.key
        item = cls.__items.get(key)
        if not item:
            raise Exception(u'库存没有商品！单号:%s,商品:%s,库房:%s' %
                            (doc.noteno, doc.product_id, doc.warehouse_id))
        if item.quantity - doc.quantity < 0:
            raise Exception(u'出现库存数量为负！单号:%s,商品:%s,库房:%s' %
                            (doc.noteno, doc.product_id, doc.warehouse_id))

    @classmethod
    def wareout(cls, doc):
        if not cls.__inited:cls.__init()
        cls.wareout_check(doc)
        key = doc.key
        stamp = doc.notedate.strftime('%Y-%m-%d')
        # 一定要在这个位置，因为__checkStock会删除零库存
        cls.__checkStock(stamp)

        item = cls.__items.get(key)
        cls.wareouting(doc, item, cls.__items)
        cost = doc.quantity * item.price
        # 0库存将成本置0，要不然0数量成本不为零的库存会很多
        if item.quantity - doc.quantity == 0:
            cost = item.amount
        profit = doc.quantity * doc.price - cost
        item.quantity -= doc.quantity
        item.amount -= cost
        item.last_out_date = doc.notedate
        item.today_out += doc.quantity
        item.today_profit += profit
        item.today_out_cost += cost
        doc.out_cost = cost
        doc.out_profit = profit
        cls.wareouted(doc, item, cls.__items)

    @classmethod
    def costChange(cls,  department_id, product_id, warehouse_id, changeValue):
        s = cls.getStock(department_id, product_id, warehouse_id)
        if not s:
            raise Exception
        s.amount += changeValue
        s.price = s.amount / s.quantity

    @classmethod
    def rollback(cls, backdate):
        n = backdate + timedelta(days=-1)
        n = n.strftime('%Y-%m-%d')
        session.query(cls).delete()
        for snap in session.query(warehouse_snap).filter(
            warehouse_snap.stamp==n):
            stock = warehouse_snap.snapToStock(snap)
            session.add(stock)

class warehouse_snap(_Base, _warehouse):
    __tablename__ = 'bi_warehouse_snap'
    w1_in = Column(Numeric)
    w1_out = Column(Numeric)
    w1_out_cost = Column(Numeric(19,4))
    w1_profit = Column(Numeric(19,4))
    w1_stock_product = Column(Numeric)
    w1_stock_days = Column(Numeric)
    w1_turnover = Column(Numeric(19,4))
    w1_sale_forecast = Column(Numeric(19,4))

    w2_in = Column(Numeric)
    w2_out = Column(Numeric)
    w2_out_cost = Column(Numeric(19,4))
    w2_profit = Column(Numeric(19,4))
    w2_stock_product = Column(Numeric)
    w2_stock_days = Column(Numeric)
    w2_turnover = Column(Numeric(19,4))
    w2_sale_forecast = Column(Numeric(19,4))

    w4_in = Column(Numeric)
    w4_out = Column(Numeric)
    w4_out_cost = Column(Numeric(19,4))
    w4_profit = Column(Numeric(19,4))
    w4_stock_product = Column(Numeric)
    w4_stock_days = Column(Numeric)
    w4_turnover = Column(Numeric(19,4))
    w4_sale_forecast = Column(Numeric(19,4))

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
            # 缓存过去4周每天的库存
            s_stamp = (m + timedelta(days=-27)).strftime('%Y-%m-%d')
            cls.__last = m
            for item in session.query(cls).filter(cls.stamp >= s_stamp):
                k = note.getStampKeyByStock(item)
                cls.__items[k] = item
        cls.__inited = True

    @classmethod
    def __insert_stamp(cls, curr, stocks):
        '''检查是否库存状态连续并插入'''
        for stamp in list(rrule(DAILY, byhour=0, byminute=0, bysecond=0,
            dtstart=cls.__last, until=curr))[1:-1]: # 最后一天未结束不快照
            for stock in stocks.values():
                cls.__do_stock_snap(stamp, stock)
            cls.__last = stamp

    @classmethod
    def __getSnaps(cls, item, days):
        items = []
        curr = datetime.strptime(item.stamp, '%Y-%m-%d')
        items.append(item)
        for i in range(days-1):
            curr = curr + timedelta(days=-1)
            k = note.getKeyByStackDate(curr, item)
            o = cls.__items.get(k)
            if o:
                items.append(o)
        return items

    @classmethod
    def __getW1Snaps(cls, item):
        return cls.__getSnaps(item, 7)
    @classmethod
    def __getW2Snaps(cls, item):
        return cls.__getSnaps(item, 14)
    @classmethod
    def __getW4Snaps(cls, item):
        return cls.__getSnaps(item, 28)

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
            if d.quantity<>0 or d.today_in<>0 or \
                d.today_out<>0:
                w_stock_days += 1

        item.w1_in = w_in
        item.w1_out = w_out
        item.w1_out_cost = w_out_cost
        item.w1_profit = w_profit
        item.w1_stock_product = w_stock_product
        item.w1_stock_days = w_stock_days
        if w_out:
            item.w1_turnover = w_stock_product/w_out
            item.w1_sale_forecast = item.quantity * w_stock_days / w_out

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
        if w_out:
            item.w2_turnover = w_stock_product/w_out
            item.w2_sale_forecast = item.quantity * w_stock_days / w_out

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
        if w_out:
            item.w4_turnover = w_stock_product/w_out
            item.w4_sale_forecast = item.quantity * w_stock_days / w_out

    @classmethod
    def __delSnap(cls, currdate):
        start = currdate + timedelta(days=-28)
        stamp = note.dateToStamp(start)
        for key in cls.__items.keys():
            if stamp in key:
                cls.__items.pop(key)

    @classmethod
    def __do_stock_snap(cls, stockdate, stock):
        stamp = datetime.strftime(stockdate, '%Y-%m-%d')
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
        cls.__setStockSnap(item) # 计算并设置字段值
        k = note.getKeyByStackDate(stockdate, item)
        cls.__items[k] = item
        session.add(item) # 准备保存
        # 去掉缓存中的4周前的快照记录
        cls.__delSnap(stockdate)

    @classmethod
    def __do_snap(cls, currdate, stocks):
        curr = datetime(currdate.year, currdate.month, currdate.day)
        if not cls.__inited:
            cls._init()
        # 首次运行时 cls.__last 为空，赋予初始值
        cls.__last = cls.__last or curr
        # 如果昨天已快照不需要处理
        last_stamp = curr + timedelta(days=-1)
        if cls.__last >= last_stamp:return
        # 插入没有业务记录的库存快照
        cls.__insert_stamp(curr, stocks)

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
    def do_snap(cls, doc, stock, stocks):
        cls.__do_snap(doc.notedate, stocks)

    @classmethod
    def getLast(cls):
        if not cls.__inited:
            cls._init()
        return cls.__last

    @classmethod
    def rollback(cls, backdate):
        s = backdate.strftime('%Y-%m-%d')
        session.query(warehouse_snap).filter(warehouse_snap.stamp>=s).delete()

warehouse.wareining += warehouse_snap.do_snap
warehouse.wareouting += warehouse_snap.do_snap

class ware_journal(_Base, _orm_base):
    __tablename__ = 'bi_ware_journal'

    doc_id = Column(String(20))
    doc_type = Column(String(10))
    doc_date = Column(DateTime)
    warehouse_id = Column(String(20))
    department_id = Column(String(20))
    partner_id = Column(String(20))
    sales = Column(String(20))
    product_id = Column(String(20))
    in_quantity = Column(Numeric)
    in_price = Column(Numeric(19,4))
    in_amount = Column(Numeric(19,4))
    out_quantity = Column(Numeric)
    out_price = Column(Numeric(19,4))
    out_amount = Column(Numeric(19,4))
    out_cost = Column(Numeric(19,4))
    out_profit = Column(Numeric(19,4))
    stock_quantity = Column(Numeric)
    stock_price = Column(Numeric(19,4))
    stock_amount = Column(Numeric(19,4))
#    stamp = Column(String(10))

    @classmethod
    def charge(cls, doc, stock, stocks):
        item = cls()
        item.department_id = doc.department_id
        item.product_id = doc.product_id
        item.warehouse_id = doc.warehouse_id
        item.partner_id = doc.partner_id
        item.sales = doc.sales
        item.doc_id = doc.noteno
        item.doc_type = doc.notetype
        item.doc_date = doc.notedate
        if doc.notetype in ('CR','XT','YR'):
            item.in_amount = doc.amount
            item.in_price = doc.price
            item.in_quantity = doc.quantity
        elif doc.notetype in ('CT','XS','YC'):
            item.out_amount = doc.amount
            item.out_price = doc.price
            item.out_quantity = doc.quantity
            item.out_profit = doc.out_profit
            item.out_cost = doc.out_cost
        item.stock_amount = stock.amount
        item.stock_price = stock.price
        item.stock_quantity = stock.quantity
        session.add(item)

    @classmethod
    def rollback(cls, backdate):
        s = backdate
        session.query(cls).filter(cls.doc_date>=s).delete()

warehouse.wareined += ware_journal.charge
warehouse.wareouted += ware_journal.charge

class profit_journal(_Base, _orm_base):
    __tablename__ = 'profit_journal'

    department_id = Column(String(20))
    doc_id = Column(String(20))
    warehouse_id = Column(String(20))
    customer_id = Column(String(20))
    product_id = Column(String(20))
    sales_id = Column(String(20))
    quantity = Column(Numeric)
    amount = Column(Numeric(19,4))
    cost = Column(Numeric(19,4))
    profit = Column(Numeric(19,4))
    rate = Column(Numeric(19,4))

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

def rollback(backdate):
    warehouse_snap.rollback(backdate)
    warehouse.rollback(backdate)
    ware_journal.rollback(backdate)
    session.commit()

def commit():
    try:
        session.commit()
    except Exception, e:
        print e.message

import sys, decimal
reload(sys)
sys.setdefaultencoding("utf-8")
decimal.getcontext().prec = 18
