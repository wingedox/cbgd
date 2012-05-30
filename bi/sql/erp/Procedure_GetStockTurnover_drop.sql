/****** Object:  StoredProcedure [GetStockTurnover]    Script Date: 01/19/2012 02:16:26 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetStockTurnover]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
DROP PROCEDURE [GetStockTurnover]
