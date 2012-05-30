/****** Object:  Trigger [deptcheckwareinm]    Script Date: 01/13/2012 04:54:36 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[deptcheckwareinm]'))
DROP TRIGGER [deptcheckwareinm]
