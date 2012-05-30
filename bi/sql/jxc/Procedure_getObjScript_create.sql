/****** Object:  StoredProcedure [getObjScript]    Script Date: 01/14/2012 16:10:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[getObjScript]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
BEGIN
EXEC dbo.sp_executesql @statement = N'--C：检查约束。
--D：默认的约束
--F：外键约束
--L：日志
--P：存储过程
--PK：主键约束
--RF：复制过滤存储过程
--S：系统表格
--TR：触发器
--U：用于表格。
--UQ：独特的约束。
--V：视图
--X：被扩展的存储过程

--select * from sysobjects where xtype not in(''S'',''PK'',''D'',''X'',''L'',''U'') 
create procedure [dbo].[getObjScript]
	(@servername varchar(50) --服务器名 
	,@userid varchar(50) --用户名,如果为nt验证方式,则为空 
	,@password varchar(50) --密码 
	,@databasename varchar(50)--数据库名称 
	,@objectname varchar(250)--对象名
	,@script varchar(8000) output --返回脚本 
	)
as 

declare @srvid int,@dbsid int --定义服务器、数据库集id 
declare @dbid int,@tbid int --数据库、表id 

--创建sqldmo对象 
exec sp_oacreate ''sqldmo.sqlserver'',@srvid output 

--连接服务器 
if isnull(@userid,'''')='''' --如果是 Nt验证方式 
begin 
	exec sp_oasetproperty @srvid,''loginsecure'',1 
	exec sp_oamethod @srvid,''connect'',null,@servername 
end 
else 
	exec sp_oamethod @srvid,''connect'',null,@servername,@userid,@password 

--获取数据库集 
exec sp_oagetproperty @srvid,''databases'',@dbsid output 
--获取要取得脚本的数据库id 
exec sp_oamethod @dbsid,''Item'',@dbid output,@databasename 
--获取要取得脚本的对象id 
exec sp_oamethod @dbid,''getobjectbyname'',@tbid output,@objectname
--取得脚本 
exec sp_oamethod @tbid,''script'',@script output 

' 
END
