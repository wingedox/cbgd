IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_NEARSALE_WARECODE]') AND type = 'F')
ALTER TABLE [NEARSALE] DROP CONSTRAINT [FK_NEARSALE_WARECODE]
