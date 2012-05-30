/****** Object:  UserDefinedFunction [GetLastSellOfReceivable]    Script Date: 01/14/2012 16:11:13 ******/
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[GetLastSellOfReceivable]') AND xtype in (N'FN', N'IF', N'TF'))
DROP FUNCTION [GetLastSellOfReceivable]
