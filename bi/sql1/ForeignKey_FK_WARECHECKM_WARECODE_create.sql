IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WARECHECKM_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WARECHECKM]'))
ALTER TABLE [WARECHECKM]  WITH CHECK ADD  CONSTRAINT [FK_WARECHECKM_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_WARECHECKM_WARECODE]') AND parent_object_id = OBJECT_ID(N'[WARECHECKM]'))
ALTER TABLE [WARECHECKM] CHECK CONSTRAINT [FK_WARECHECKM_WARECODE]
