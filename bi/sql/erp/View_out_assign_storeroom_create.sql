/****** Object:  View [out_assign_storeroom]    Script Date: 01/14/2012 16:34:17 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[out_assign_storeroom]'))
EXEC dbo.sp_executesql @statement = N'
--create view out_assign_storeroom
CREATE view [dbo].[out_assign_storeroom]
as
select distinct storeroom_id, assign_id ,status from out_store_assign_d


' 
