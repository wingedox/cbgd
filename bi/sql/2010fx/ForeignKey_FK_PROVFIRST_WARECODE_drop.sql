IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_PROVFIRST_WARECODE]') AND type = 'F')

ALTER TABLE [PROVFIRST] DROP CONSTRAINT [FK_PROVFIRST_WARECODE]