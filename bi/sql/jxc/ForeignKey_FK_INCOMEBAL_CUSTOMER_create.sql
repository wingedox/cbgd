IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_INCOMEBAL_CUSTOMER]') AND type = 'F')
ALTER TABLE [INCOMEBAL]  WITH CHECK ADD  CONSTRAINT [FK_INCOMEBAL_CUSTOMER] FOREIGN KEY([code])
REFERENCES [CUSTOMER] ([code])
ON UPDATE CASCADE
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_INCOMEBAL_CUSTOMER]') AND type = 'F')
ALTER TABLE [INCOMEBAL] CHECK CONSTRAINT [FK_INCOMEBAL_CUSTOMER]
