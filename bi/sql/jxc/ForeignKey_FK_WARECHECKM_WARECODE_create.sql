IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARECHECKM_WARECODE]') AND type = 'F')
ALTER TABLE [WARECHECKM]  WITH CHECK ADD  CONSTRAINT [FK_WARECHECKM_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARECHECKM_WARECODE]') AND type = 'F')
ALTER TABLE [WARECHECKM] CHECK CONSTRAINT [FK_WARECHECKM_WARECODE]