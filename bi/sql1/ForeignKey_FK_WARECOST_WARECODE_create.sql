IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WARECOST_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WARECOST]'))
ALTER TABLE [WARECOST]  WITH CHECK ADD  CONSTRAINT [FK_WARECOST_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WARECOST_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WARECOST]'))
ALTER TABLE [WARECOST] CHECK CONSTRAINT [FK_WARECOST_WARECODE]
