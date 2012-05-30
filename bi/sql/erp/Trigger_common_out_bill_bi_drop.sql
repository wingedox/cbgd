/****** Object:  Trigger [common_out_bill_bi]    Script Date: 01/14/2012 16:34:13 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[common_out_bill_bi]'))
DROP TRIGGER [common_out_bill_bi]
