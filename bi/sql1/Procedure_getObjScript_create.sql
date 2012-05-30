/****** Object:  StoredProcedure [getObjScript]    Script Date: 01/13/2012 04:54:31 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[getObjScript]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'--C�����Լ����
--D��Ĭ�ϵ�Լ��
--F�����Լ��
--L����־
--P���洢����
--PK������Լ��
--RF�����ƹ��˴洢����
--S��ϵͳ���
--TR��������
--U�����ڱ��
--UQ�����ص�Լ����
--V����ͼ
--X������չ�Ĵ洢����

--select * from sysobjects where xtype not in(''S'',''PK'',''D'',''X'',''L'',''U'') 
create procedure [dbo].[getObjScript]
	(@servername varchar(50) --�������� 
	,@userid varchar(50) --�û���,���Ϊnt��֤��ʽ,��Ϊ�� 
	,@password varchar(50) --���� 
	,@databasename varchar(50)--���ݿ����� 
	,@objectname varchar(250)--������
	,@script varchar(8000) output --���ؽű� 
	)
as 

declare @srvid int,@dbsid int --��������������ݿ⼯id 
declare @dbid int,@tbid int --���ݿ⡢��id 

--����sqldmo���� 
exec sp_oacreate ''sqldmo.sqlserver'',@srvid output 

--���ӷ����� 
if isnull(@userid,'''')='''' --����� Nt��֤��ʽ 
begin 
	exec sp_oasetproperty @srvid,''loginsecure'',1 
	exec sp_oamethod @srvid,''connect'',null,@servername 
end 
else 
	exec sp_oamethod @srvid,''connect'',null,@servername,@userid,@password 

--��ȡ���ݿ⼯ 
exec sp_oagetproperty @srvid,''databases'',@dbsid output 
--��ȡҪȡ�ýű������ݿ�id 
exec sp_oamethod @dbsid,''Item'',@dbid output,@databasename 
--��ȡҪȡ�ýű��Ķ���id 
exec sp_oamethod @dbid,''getobjectbyname'',@tbid output,@objectname
--ȡ�ýű� 
exec sp_oamethod @tbid,''script'',@script output 

' 
END
