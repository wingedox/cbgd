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
        self.chargedate = None

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
    def toStamp(cls, date):
        stamp = None
        if isinstance(date, datetime):
            stamp = date.strftime('%Y-%m-%d')
        else:
            stamp = isinstance(date, unicode) and\
                    date.encode('utf-8') or date
        return stamp

    @classmethod
    def toDate(cls, stamp):
        date = None
        if isinstance(stamp, datetime):
            date = stamp
        else:
            date = datetime.strptime(stamp, '%Y-%m-%d')
        return date

class w4Snap(object):
    """
    管理一个库房里的一个产品28天的历史库存
    """
    def __init__(self):
        self.w1 = []
        self.w2 = []
        self.w4 = []
        self.currDate = None
        self.w1_in = Decimal()
        self.w1_out = Decimal()
        self.w1_out_cost = Decimal()
        self.w1_profit = Decimal()
        self.w1_sale_forecast = Decimal()
        self.w1_stock_days = Decimal()
        self.w1_stock_product = Decimal()
        self.w1_turnover = Decimal()
        self.w2_in = Decimal()
        self.w2_out = Decimal()
        self.w2_out_cost = Decimal()
        self.w2_profit = Decimal()
        self.w2_sale_forecast = Decimal()
        self.w2_stock_days = Decimal()
        self.w2_stock_product = Decimal()
        self.w2_turnover = Decimal()
        self.w4_in = Decimal()
        self.w4_out = Decimal()
        self.w4_out_cost = Decimal()
        self.w4_profit = Decimal()
        self.w4_sale_forecast = Decimal()
        self.w4_stock_days = Decimal()
        self.w4_stock_product = Decimal()
        self.w4_turnover = Decimal()

    @property
    def valid(self):
        """
        要分开加，有可能 today + product 正负抵消，结果为零
        """
        today = self.w1_in + self.w1_out +\
                  self.w2_in + self.w2_out +\
                  self.w4_in + self.w4_out
        product = self.w1_stock_days +\
                  self.w2_stock_days + self.w4_stock_days
        return product or today

    def addCurrSnap(self, snap):
        self.w1.insert(0, snap)
        self.__addW1(snap)
        self.__addW2(snap)
        self.__addW4(snap)
        self.__setTurnover(snap)
        if self.valid:
            self.__setSnap(snap)
            session.add(snap)

    def __indexInsert(self, arr, snap):
        if not arr:
            arr.append(snap)
        else:
            i = 0
            for i in range(len(arr)):
                if snap.stamp > arr[i].stamp:
                    arr.insert(arr.index(arr[i])+1, snap)
                    break

    def addInitSnap(self, currDate, snap):
        # 初始化时需要调用此方法，不需要计算snap周转数据
        delta = currDate - note.toDate(snap.stamp)
        if delta < timedelta(days=7):
            self.__indexInsert(self.w1, snap)
        elif delta < timedelta(days=14):
            self.__indexInsert(self.w2, snap)
        elif delta < timedelta(days=28):
            self.__indexInsert(self.w4, snap)
        else:
            raise Exception

    def setCurrDate(self, currDate):
        """
        删除7、14、28天缓存中多余的item
        1.w1中7天以外的移到w2
        2.w2中14天以外的移到w4
        3.w4中28天以外的删除
        4.计算剩余的28个snap的周转数据，有有效数据
          新增snap插入w1最开始位置
        """
        self.__currDate =currDate
        if len(self.w1) == 7:
            snap = self.w1.pop()
            self.__subW1(snap)
            self.w2.insert(0, snap)
        # w1 移来后变为 8
        if len(self.w2) == 8:
            snap = self.w2.pop()
            self.__subW2(snap)
            self.w4.insert(0, snap)
        if len(self.w4) == 15:
            snap = self.w4.pop()
            self.__subW4(snap)
        self.len = len(self.w1) + len(self.w2) + len(self.w4)

    def __addW1(self, snap):
        self.w1_out += snap.today_out
        self.w1_stock_product += snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w1_stock_days += 1
        self.w1_in += snap.today_in
        self.w1_out_cost += snap.today_out_cost
        self.w1_profit += snap.today_profit
    def __addW2(self, snap):
        self.w2_out += snap.today_out
        self.w2_stock_product += snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w2_stock_days += 1
        self.w2_in += snap.today_in
        self.w2_out_cost += snap.today_out_cost
        self.w2_profit += snap.today_profit
    def __addW4(self, snap):
        self.w4_out += snap.today_out
        self.w4_stock_product += snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w4_stock_days += 1
        self.w4_in += snap.today_in
        self.w4_out_cost += snap.today_out_cost
        self.w4_profit += snap.today_profit
    def __subW1(self, snap):
        self.w1_out -= snap.today_out
        self.w1_stock_product -= snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w1_stock_days -= 1
        self.w1_in -= snap.today_in
        self.w1_out_cost -= snap.today_out_cost
        self.w1_profit -= snap.today_profit
    def __subW2(self, snap):
        self.w2_out -= snap.today_out
        self.w2_stock_product -= snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w2_stock_days -= 1
        self.w2_in -= snap.today_in
        self.w2_out_cost -= snap.today_out_cost
        self.w2_profit -= snap.today_profit
    def __subW4(self, snap):
        self.w4_out -= snap.today_out
        self.w4_stock_product -= snap.quantity
        if snap.today_out or snap.today_in or snap.quantity:
            self.w4_stock_days -= 1
        self.w4_in -= snap.today_in
        self.w4_out_cost -= snap.today_out_cost
        self.w4_profit -= snap.today_profit
    def __setTurnover(self, snap):
        if self.w1_out:
            self.w1_turnover = self.w1_stock_product/self.w1_out
            self.w1_sale_forecast = snap.quantity * self.w1_stock_days / self.w1_out
        if self.w2_out:
            self.w2_turnover = self.w2_stock_product/self.w2_out
            self.w2_sale_forecast = snap.quantity * self.w2_stock_days / self.w2_out
        if self.w4_out:
            self.w4_turnover = self.w4_stock_product/self.w4_out
            self.w4_sale_forecast = snap.quantity * self.w4_stock_days / self.w4_out
    def __setSnap(self, snap):
        snap.w1_in = self.w1_in
        snap.w1_out = self.w1_out
        snap.w1_out_cost = self.w1_out_cost
        snap.w1_profit = self.w1_profit
        snap.w1_sale_forecast = self.w1_sale_forecast
        snap.w1_stock_days = self.w1_stock_days
        snap.w1_stock_product = self.w1_stock_product
        snap.w1_turnover = self.w1_turnover
        snap.w2_in = self.w2_in
        snap.w2_out = self.w2_out
        snap.w2_out_cost = self.w2_out_cost
        snap.w2_profit = self.w2_profit
        snap.w2_sale_forecast = self.w2_sale_forecast
        snap.w2_stock_days = self.w2_stock_days
        snap.w2_stock_product = self.w2_stock_product
        snap.w2_turnover = self.w2_turnover
        snap.w4_in = self.w4_in
        snap.w4_out = self.w4_out
        snap.w4_out_cost = self.w4_out_cost
        snap.w4_profit = self.w4_profit
        snap.w4_sale_forecast = self.w4_sale_forecast
        snap.w4_stock_days = self.w4_stock_days
        snap.w4_stock_product = self.w4_stock_product
        snap.w4_turnover = self.w4_turnover

    def supplement(self):
        snap = warehouse_snap()
        snap.stamp = note.toStamp(self.__currDate)
        # 拷贝基本字段，不需要拷贝 today 字段
        warehouse_snap.copyBaseFields(self.w1[0], snap)
        warehouse_snap.setSnapDefault(snap)
        warehouse_snap.setTodayDefault(snap)
        self.addCurrSnap(snap)

class historySnaps(dict):
    def __init__(self):
        self.__keys = []
        self.last = None
        self.inited = False
        super(historySnaps, self).__init__()

    def init(self):
        max_stamp = session.query(func.max(warehouse_snap.stamp).label('max_stamp')).one()
        if  max_stamp[0]:
            m = datetime.strptime( max_stamp[0], '%Y-%m-%d')
            # 缓存过去4周每天的库存
            s_stamp = (m - timedelta(days=28)).strftime('%Y-%m-%d')
            self.last = m
            for item in session.query(warehouse_snap).filter(warehouse_snap.stamp > s_stamp):
                key = note.getKeyByStock(item)
                self.addInitSnap(key, m, item)
        self.inited = True

    def beginDay(self, currDate):
        """
        缓存所有 snaps 的键值，处理一条库存后从缓存中
        移出该库存的键值，处理完库存后再根据剩余的键
        值条用endDay()处理插入新snap
        """
        curr = note.toDate(currDate)
        self.len_item = 0
        for v in self.values():
            # 根据日期移动缓存的snap到w2或w4
            v.setCurrDate(curr)
            self.len_item += v.len
        self.__keys = self.keys()
        self.len_key = len(self.__keys)
        self.last = curr

    def endDay(self):
        """
        处理完库存的快照后，缓存中的28天历史snap中还有
        有效数据的snap需要快照
        删除28天内无有效数据的snap
        """
        for k in self.__keys:
            snaps = self[k]
            if not snaps.valid:
                self.pop(k)
            else:
                snaps.supplement()

    def addCurrSnap(self, key, item):
        snaps = self.setdefault(key, w4Snap())
        snaps.addCurrSnap(item)
        # 初次运行时 self.__keys 没有值，导致异常
        try:
            self.__keys.remove(key)
        except Exception:
            pass
    def addInitSnap(self, key, currDate, item):
        snaps = self.setdefault(key, w4Snap())
        snaps.addInitSnap(currDate, item)
        try:
            self.__keys.remove(key)
        except Exception:
            pass

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

    dateChange = Event()
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
        """
        如果日期变化触发 dateChange 事件
        所有库存 today 相关字段置零
        删除零库存
        """
        cls.__currDate = cls.__currDate or stamp
        if cls.__currDate<>stamp:
            cls.dateChange(datetime.strptime(stamp, '%Y-%m-%d'),
                datetime.strptime(cls.__currDate, '%Y-%m-%d'),cls.__items)
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
        stamp = doc.chargedate.strftime('%Y-%m-%d')
        cls.__checkStock(stamp)

        key = doc.key
        item = cls.__items.get(key)
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
        stamp = doc.chargedate.strftime('%Y-%m-%d')
        cls.__checkStock(stamp)

        key = doc.key
        item = cls.__items.get(key)
        cost = doc.quantity * item.price
        # 0库存将成本置0，要不然0数量成本不为零的库存会很多
        if item.quantity - doc.quantity == 0:
            cost = item.amount
        profit = doc.quantity * doc.price - cost
        item.quantity -= doc.quantity
        item.amount -= cost
        item.last_out_date = doc.notedate
        if doc.notetype == 'XS':
            item.today_out += doc.quantity
            item.today_profit += profit
            item.today_out_cost += cost
        if doc.notetype == 'CT':
            item.today_in -= doc.quantity
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
    __inited = False
    __items = historySnaps()
    __currDate = None

    @classmethod
    def _init(cls):
        cls.__items.init()
        cls.__last = cls.__items.last
        cls.__inited = True

    @classmethod
    def __insert_stamp(cls, currDate, stocks):
        """检查是否库存状态连续并插入
        rrule 返回两个日期中间的日期列表，包含头和尾
        """
        for stampDate in list(rrule(DAILY, byhour=0, byminute=0, bysecond=0,
            dtstart=cls.__items.last, until=currDate))[1:]:
            # 设置缓存的当前日期并去掉缓存中多余的快照记录
            stamp = note.toStamp(stampDate)

            cls.__items.beginDay(stampDate)
            print 'stamp:%s,len_key:%s,len_item:%s' % (note.toStamp(stampDate),
                cls.__items.len_key, cls.__items.len_item)
            # 逐条将库存做 snap
            # 速度优化,局部变量更容易查找
            stockToSnap = cls.__stockToSnap
            addCurrSnap = cls.__items.addCurrSnap
            for key, stock in stocks.items():
                item = stockToSnap(stamp, stock)
                addCurrSnap(key, item)
            cls.__items.endDay()
            cls.__last = stampDate
            print 'Snap OK!,'

    @classmethod
    def copyBaseFields(cls, source, target):
        target.department_id = source.department_id
        target.product_id = source.product_id
        target.warehouse_id = source.warehouse_id
        target.quantity = source.quantity
        target.price = source.price
        target.amount = source.amount
        target.last_in_date = source.last_in_date
        target.last_out_date = source.last_out_date
    @classmethod
    def copyTodayFields(cls, source, target):
        target.today_in = source.today_in
        target.today_out = source.today_out
        target.today_out_cost = source.today_out_cost
        target.today_profit = source.today_profit
    @classmethod
    def setTodayDefault(cls, snap):
        snap.today_in = Decimal()
        snap.today_out = Decimal()
        snap.today_out_cost = Decimal()
        snap.today_profit = Decimal()
    @classmethod
    def setSnapDefault(cls, snap):
        snap.w1_in = Decimal()
        snap.w1_out = Decimal()
        snap.w1_out_cost = Decimal()
        snap.w1_profit = Decimal()
        snap.w1_sale_forecast = Decimal()
        snap.w1_stock_days = Decimal()
        snap.w1_stock_product = Decimal()
        snap.w1_turnover = Decimal()
        snap.w2_in = Decimal()
        snap.w2_out = Decimal()
        snap.w2_out_cost = Decimal()
        snap.w2_profit = Decimal()
        snap.w2_sale_forecast = Decimal()
        snap.w2_stock_days = Decimal()
        snap.w2_stock_product = Decimal()
        snap.w2_turnover = Decimal()
        snap.w4_in = Decimal()
        snap.w4_out = Decimal()
        snap.w4_out_cost = Decimal()
        snap.w4_profit = Decimal()
        snap.w4_sale_forecast = Decimal()
        snap.w4_stock_days = Decimal()
        snap.w4_stock_product = Decimal()
        snap.w4_turnover = Decimal()

    @classmethod
    def __stockToSnap(cls, stamp, stock):
        # 构建库存快照实体
        item = cls()
        item.stamp = stamp
        cls.copyBaseFields(stock, item)
        cls.copyTodayFields(stock, item)
        cls.setSnapDefault(item)
        return item

    @classmethod
    def snapToStock(cls, snap):
        stock = warehouse()
        stock.stamp = snap.stamp
        cls.copyBaseFields(snap, stock)
        cls.copyTodayFields(snap, stock)
        return stock

    @classmethod
    def __do_snap(cls, currDate, stocks):
        """
        cls.__last 记录的是快照的最后一天，如 5月1日，那么currDate
        是 5月2日结束后 5月3日开始时才需要做 5月2日的快照
        """
        if not cls.__inited:
            cls._init()
            # cls.__last 设置为昨天
            cls.__items.last = cls.__items.last or currDate - timedelta(days=1)
            cls.__insert_stamp(currDate, stocks)
            return
            # 如果昨天已快照不需要处理
        elif cls.__items.last < currDate:
            # 插入没有业务记录的库存快照
            cls.__insert_stamp(currDate, stocks)
        else:
            return

    @classmethod
    def do_snap(cls, currDate, oldDate, stocks):
        cls.__do_snap(oldDate, stocks)

    @classmethod
    def getLast(cls):
        if not cls.__inited:
            cls._init()
        return cls.__last

    @classmethod
    def rollback(cls, backdate):
        s = backdate.strftime('%Y-%m-%d')
        session.query(warehouse_snap).filter(warehouse_snap.stamp>=s).delete()

    def copySnap(self, stamp):
        snap = warehouse_snap()
        warehouse_snap.__copyFields(self, snap)
        snap.today_in = Decimal()
        snap.today_out = Decimal()
        snap.today_out_cost = Decimal()
        snap.today_profit = Decimal()
        snap.stamp = note.toStamp(stamp)
        warehouse_snap.setSnapDefault(snap)
        return snap

warehouse.dateChange += warehouse_snap.do_snap

class ware_journal(_Base, _orm_base):
    __tablename__ = 'bi_ware_journal'

    doc_id = Column(String(20))
    doc_type = Column(String(10))
    doc_date = Column(DateTime)
    charge_date = Column(DateTime)
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
        item.charge_date = doc.chargedate
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
    charge = Column(DateTime)

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
