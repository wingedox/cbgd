IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WAREOUTH_CUSTOMER]') AND type = 'F')

ALTER TABLE [WAREOUTH] DROP CONSTRAINT [FK_WAREOUTH_CUSTOMER]