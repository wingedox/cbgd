/****** Object:  StoredProcedure [getObjScript]    Script Date: 01/14/2012 16:10:31 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[getObjScript]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [getObjScript]
