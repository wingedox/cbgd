IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_INCOMECURR_CUSTOMER]') AND parent_object_id = OBJECT_ID(N'[INCOMECURR]'))
ALTER TABLE [INCOMECURR] DROP CONSTRAINT [FK_INCOMECURR_CUSTOMER]