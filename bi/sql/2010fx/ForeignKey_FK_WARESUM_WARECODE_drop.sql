IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARESUM_WARECODE]') AND type = 'F')

ALTER TABLE [WARESUM] DROP CONSTRAINT [FK_WARESUM_WARECODE]