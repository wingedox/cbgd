IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WARESUM_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WARESUM]'))
ALTER TABLE [WARESUM] DROP CONSTRAINT [FK_WARESUM_WARECODE]
