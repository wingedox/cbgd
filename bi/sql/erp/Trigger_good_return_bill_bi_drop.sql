/****** Object:  Trigger [good_return_bill_bi]    Script Date: 01/14/2012 16:34:14 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[good_return_bill_bi]'))
DROP TRIGGER [good_return_bill_bi]
