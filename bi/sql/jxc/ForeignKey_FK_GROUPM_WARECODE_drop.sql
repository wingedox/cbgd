IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_GROUPM_WARECODE]') AND type = 'F')
ALTER TABLE [GROUPM] DROP CONSTRAINT [FK_GROUPM_WARECODE]