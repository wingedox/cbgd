/****** Object:  Trigger [checkexpense]    Script Date: 01/19/2012 02:29:16 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[checkexpense]') AND OBJECTPROPERTY(id, N'IsTrigger') = 1)

DROP TRIGGER [checkexpense]