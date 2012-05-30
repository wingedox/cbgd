/****** Object:  UserDefinedFunction [GetPeriod]    Script Date: 01/19/2012 02:29:19 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetPeriod]') AND xtype in (N'FN', N'IF', N'TF'))

DROP FUNCTION [GetPeriod]