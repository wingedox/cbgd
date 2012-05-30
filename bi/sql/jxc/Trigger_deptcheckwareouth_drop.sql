/****** Object:  Trigger [deptcheckwareouth]    Script Date: 01/14/2012 16:11:04 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareouth]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [deptcheckwareouth]
