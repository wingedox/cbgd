IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_CUSTGROUPM_CUSTOMER]') AND type = 'F')
ALTER TABLE [CUSTGROUPM]  WITH CHECK ADD  CONSTRAINT [FK_CUSTGROUPM_CUSTOMER] FOREIGN KEY([code])
REFERENCES [CUSTOMER] ([code])
ON UPDATE CASCADE
IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[FK_CUSTGROUPM_CUSTOMER]') AND type = 'F')
ALTER TABLE [CUSTGROUPM] CHECK CONSTRAINT [FK_CUSTGROUPM_CUSTOMER]