/****** Object:  StoredProcedure [erp_goodsale]    Script Date: 01/14/2012 16:34:07 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[erp_goodsale]') AND type in (N'P', N'PC'))
DROP PROCEDURE [erp_goodsale]
