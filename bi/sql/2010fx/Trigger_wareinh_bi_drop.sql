/****** Object:  Trigger [wareinh_bi]    Script Date: 01/19/2012 02:29:12 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[wareinh_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

DROP TRIGGER [wareinh_bi]