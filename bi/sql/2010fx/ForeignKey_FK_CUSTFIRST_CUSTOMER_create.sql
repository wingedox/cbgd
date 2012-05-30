IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_CUSTFIRST_CUSTOMER]') AND type = 'F')

ALTER TABLE [CUSTFIRST]  WITH CHECK ADD  CONSTRAINT [FK_CUSTFIRST_CUSTOMER] FOREIGN KEY([code])

REFERENCES [CUSTOMER] ([code])

ON UPDATE CASCADEIF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_CUSTFIRST_CUSTOMER]') AND type = 'F')

ALTER TABLE [CUSTFIRST] CHECK CONSTRAINT [FK_CUSTFIRST_CUSTOMER]