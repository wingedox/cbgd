IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_NEARSALE_WARECODE]') AND parent_object_id = OBJECT_ID(N'[NEARSALE]'))
ALTER TABLE [NEARSALE] DROP CONSTRAINT [FK_NEARSALE_WARECODE]
