/****** Object:  StoredProcedure [getObjScript]    Script Date: 01/13/2012 04:54:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[getObjScript]') AND type in (N'P', N'PC'))
DROP PROCEDURE [getObjScript]
