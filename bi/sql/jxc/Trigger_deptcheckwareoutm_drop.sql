/****** Object:  Trigger [deptcheckwareoutm]    Script Date: 01/14/2012 16:11:10 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareoutm]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [deptcheckwareoutm]
