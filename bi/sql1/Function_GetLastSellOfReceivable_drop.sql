/****** Object:  UserDefinedFunction [GetLastSellOfReceivable]    Script Date: 01/13/2012 04:54:36 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[GetLastSellOfReceivable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [GetLastSellOfReceivable]
