IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_INCOMECURR_CUSTOMER]') AND parent_object_id = OBJECT_ID(N'[INCOMECURR]'))
ALTER TABLE [INCOMECURR]  WITH CHECK ADD  CONSTRAINT [FK_INCOMECURR_CUSTOMER] FOREIGN KEY([custno])
REFERENCES [CUSTOMER] ([code])
ON UPDATE CASCADE
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[FK_INCOMECURR_CUSTOMER]') AND parent_object_id = OBJECT_ID(N'[INCOMECURR]'))
ALTER TABLE [INCOMECURR] CHECK CONSTRAINT [FK_INCOMECURR_CUSTOMER]
