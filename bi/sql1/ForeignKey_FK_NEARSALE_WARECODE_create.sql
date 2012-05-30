IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_NEARSALE_WARECODE]') AND parent_object_id = OBJECT_ID(N'[NEARSALE]'))
ALTER TABLE [NEARSALE]  WITH CHECK ADD  CONSTRAINT [FK_NEARSALE_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_NEARSALE_WARECODE]') AND parent_object_id = OBJECT_ID(N'[NEARSALE]'))
ALTER TABLE [NEARSALE] CHECK CONSTRAINT [FK_NEARSALE_WARECODE]