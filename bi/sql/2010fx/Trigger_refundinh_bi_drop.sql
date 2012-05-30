/****** Object:  Trigger [refundinh_bi]    Script Date: 01/19/2012 02:29:03 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[refundinh_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

DROP TRIGGER [refundinh_bi]