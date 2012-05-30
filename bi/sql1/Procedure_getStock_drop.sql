/****** Object:  StoredProcedure [getStock]    Script Date: 01/13/2012 04:54:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[getStock]') AND type in (N'P', N'PC'))
DROP PROCEDURE [getStock]
