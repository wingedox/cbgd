#coding='utf-8'
__author__ = 'GaoJun'

def _create_dim_view(conn):
    cur = conn.cursor()
    # 客户维度视图
    sql = u'''
        SELECT     c.code AS 客户编码, c.name AS 客户名称, CASE WHEN substring(c.code, 1, 2) = 'fx' THEN '分销' WHEN substring(c.code, 1, 2)
                              = 'HY' THEN '客户' WHEN substring(c.code, 1, 2) = 'ZX' THEN '行业' END AS 部门, CASE WHEN SUBSTRING(c.code, 1, 4)
                              = 'FX01' THEN '市区' WHEN SUBSTRING(c.code, 1, 4) = 'fx05' THEN '地州' WHEN SUBSTRING(c.code, 1, 4) = 'fx12' THEN '其他' WHEN substring(c.code, 1, 2) IN ('hy',
                              'zx') THEN rtrim(t .name) END AS 市场, CASE WHEN SUBSTRING(c.code, 1, 2) = 'fx' THEN
                                  (SELECT     rtrim(name)
                                    FROM          CUSTOMER
                                    WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 6)) END AS 城市, CASE WHEN SUBSTRING(c.code, 1, 2) IN ('hy', 'zx') THEN
                                  (SELECT     rtrim(name)
                                    FROM          CUSTOMER
                                    WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 4)) END AS 行业, CASE WHEN SUBSTRING(c.code, 1, 2) IN ('hy', 'zx') THEN
                                  (SELECT     rtrim(name)
                                    FROM          CUSTOMER
                                    WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 6)) END AS 子行业, RTRIM(a.accountname) AS 通路, CASE WHEN substring(c.code, 1, 2) IN ('fx')
                              THEN rtrim(t .name) END AS 区域
        FROM         dbo.CUSTOMER AS c INNER JOIN
                              dbo.ACCOUNT AS a ON c.accno = a.accountno LEFT OUTER JOIN
                              dbo.CUSTTYPE AS t ON c.ClassID = t.code
        WHERE     (c.lastnode = 1)
    '''

    cur.execute(sql)