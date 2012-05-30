/****** Object:  StoredProcedure [getStock]    Script Date: 01/14/2012 16:10:32 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[getStock]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [getStock]
