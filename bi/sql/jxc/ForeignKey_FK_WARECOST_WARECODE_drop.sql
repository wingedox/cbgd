IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARECOST_WARECODE]') AND type = 'F')
ALTER TABLE [WARECOST] DROP CONSTRAINT [FK_WARECOST_WARECODE]
