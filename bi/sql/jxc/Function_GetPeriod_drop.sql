/****** Object:  UserDefinedFunction [GetPeriod]    Script Date: 01/14/2012 16:11:13 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetPeriod]') AND xtype in (N'FN', N'IF', N'TF'))
DROP FUNCTION [GetPeriod]
