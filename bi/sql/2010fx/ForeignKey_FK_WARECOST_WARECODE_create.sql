IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARECOST_WARECODE]') AND type = 'F')

ALTER TABLE [WARECOST]  WITH CHECK ADD  CONSTRAINT [FK_WARECOST_WARECODE] FOREIGN KEY([wareno])

REFERENCES [WARECODE] ([wareno])

ON UPDATE CASCADE

ON DELETE CASCADEIF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_WARECOST_WARECODE]') AND type = 'F')

ALTER TABLE [WARECOST] CHECK CONSTRAINT [FK_WARECOST_WARECODE]