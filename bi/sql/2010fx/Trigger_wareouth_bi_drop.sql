/****** Object:  Trigger [wareouth_bi]    Script Date: 01/19/2012 02:29:17 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[wareouth_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

DROP TRIGGER [wareouth_bi]