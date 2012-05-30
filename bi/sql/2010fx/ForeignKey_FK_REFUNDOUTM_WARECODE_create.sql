IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_REFUNDOUTM_WARECODE]') AND type = 'F')

ALTER TABLE [REFUNDOUTM]  WITH CHECK ADD  CONSTRAINT [FK_REFUNDOUTM_WARECODE] FOREIGN KEY([wareno])

REFERENCES [WARECODE] ([wareno])

ON UPDATE CASCADE

ON DELETE CASCADEIF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_REFUNDOUTM_WARECODE]') AND type = 'F')

ALTER TABLE [REFUNDOUTM] CHECK CONSTRAINT [FK_REFUNDOUTM_WARECODE]