/****** Object:  Trigger [refundouth_bi]    Script Date: 01/19/2012 02:29:06 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[refundouth_bi]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

DROP TRIGGER [refundouth_bi]