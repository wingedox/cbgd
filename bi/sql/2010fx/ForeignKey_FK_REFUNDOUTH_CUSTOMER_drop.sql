IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_REFUNDOUTH_CUSTOMER]') AND type = 'F')

ALTER TABLE [REFUNDOUTH] DROP CONSTRAINT [FK_REFUNDOUTH_CUSTOMER]