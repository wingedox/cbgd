IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WAREALLOTM_WARECODE]') AND type = 'F')
ALTER TABLE [WAREALLOTM] DROP CONSTRAINT [FK_WAREALLOTM_WARECODE]
