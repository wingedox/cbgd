/****** Object:  StoredProcedure [CopyJXC]    Script Date: 01/19/2012 02:28:51 ******/

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[CopyJXC]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)

DROP PROCEDURE [CopyJXC]