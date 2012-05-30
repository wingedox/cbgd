__author__ = 'GaoJun'

f = open('jxc/scripts.txt', 'r')
scripts = eval(f.read())
f.close()

for sql in scripts:
    dropfile = sql['createfile']
    (a, b, fn) = dropfile.split('\\')
    sql['createfile'] = '%s_%s' % (sql['type'], fn[3:])

f = open('jxc/scripts.txt', 'w')
f.write(str(scripts))
f.close()

