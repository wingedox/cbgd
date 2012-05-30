IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_CUSTFIRST_WARECODE]') AND parent_object_id = OBJECT_ID(N'[CUSTFIRST]'))
ALTER TABLE [CUSTFIRST]  WITH CHECK ADD  CONSTRAINT [FK_CUSTFIRST_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_CUSTFIRST_WARECODE]') AND parent_object_id = OBJECT_ID(N'[CUSTFIRST]'))
ALTER TABLE [CUSTFIRST] CHECK CONSTRAINT [FK_CUSTFIRST_WARECODE]
