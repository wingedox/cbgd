/****** Object:  Trigger [deptcheckwareinh]    Script Date: 01/14/2012 16:10:55 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[deptcheckwareinh]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)
DROP TRIGGER [deptcheckwareinh]
