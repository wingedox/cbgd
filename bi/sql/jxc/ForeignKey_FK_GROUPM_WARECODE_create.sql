IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_GROUPM_WARECODE]') AND type = 'F')
ALTER TABLE [GROUPM]  WITH CHECK ADD  CONSTRAINT [FK_GROUPM_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_GROUPM_WARECODE]') AND type = 'F')
ALTER TABLE [GROUPM] CHECK CONSTRAINT [FK_GROUPM_WARECODE]