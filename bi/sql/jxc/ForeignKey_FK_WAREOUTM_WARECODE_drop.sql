IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WAREOUTM_WARECODE]') AND type = 'F')
ALTER TABLE [WAREOUTM] DROP CONSTRAINT [FK_WAREOUTM_WARECODE]