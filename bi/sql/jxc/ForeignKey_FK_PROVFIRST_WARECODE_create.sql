IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_PROVFIRST_WARECODE]') AND type = 'F')
ALTER TABLE [PROVFIRST]  WITH CHECK ADD  CONSTRAINT [FK_PROVFIRST_WARECODE] FOREIGN KEY([wareno])
REFERENCES [WARECODE] ([wareno])
ON UPDATE CASCADE
ON DELETE CASCADE
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_PROVFIRST_WARECODE]') AND type = 'F')
ALTER TABLE [PROVFIRST] CHECK CONSTRAINT [FK_PROVFIRST_WARECODE]
