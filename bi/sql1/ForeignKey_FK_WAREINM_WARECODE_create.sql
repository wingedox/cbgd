IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WAREINM_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WAREINM]'))
ALTER TABLE [WAREINM]  WITH CHECK ADD  CONSTRAINT [FK_WAREINM_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WAREINM_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WAREINM]'))
ALTER TABLE [WAREINM] CHECK CONSTRAINT [FK_WAREINM_WARECODE]
