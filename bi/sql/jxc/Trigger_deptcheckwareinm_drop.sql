/****** Object:  Trigger [deptcheckwareinm]    Script Date: 01/14/2012 16:10:59 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareinm]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [deptcheckwareinm]
