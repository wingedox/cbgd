/****** Object:  View [product_category]    Script Date: 01/13/2012 04:54:38 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[product_category]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW dbo.product_category
AS
SELECT     w.wareno AS 产品编码, RTRIM(w.warename) AS 产品名称, CASE WHEN SUBSTRING(w.wareno, 1, 2) IN (''05'', ''06'') OR
                      SUBSTRING(w.wareno, 1, 4) IN (''0101'', ''0102'', ''0401'', ''0402'', ''0404'', ''0405'', ''0B01'', ''0B04'') THEN ''台机'' WHEN SUBSTRING(w.wareno, 1, 2) IN (''02'', ''07'', ''08'', ''0B06'') 
                      THEN ''笔记本'' WHEN SUBSTRING(w.wareno, 1, 2) IN (''03'', ''0A'') OR
                      SUBSTRING(w.wareno, 1, 4) IN (''0403'', ''0B07'') THEN ''服务器'' WHEN SUBSTRING(w.wareno, 1, 2) IN (''09'') OR
                      SUBSTRING(w.wareno, 1, 4) IN (''0B02'', ''0B03'') THEN ''移动'' WHEN SUBSTRING(w.wareno, 1, 4) IN (''0103'') OR
                      SUBSTRING(w.wareno, 1, 2) = ''16'' THEN ''外设'' WHEN SUBSTRING(w.wareno, 1, 4) IN (''0B05'') THEN ''消费选件'' WHEN SUBSTRING(w.wareno, 1, 4) IN (''0B08'') 
                      THEN ''服务'' ELSE
                          (SELECT     RTRIM(warename) name
                            FROM          WARECODE
                            WHERE      wareno = SUBSTRING(w.wareno, 1, 2) AND lastnode = 0) END AS 类别, CASE WHEN SUBSTRING(w.wareno, 1, 2) IN (''01'', ''02'', ''03'', ''04'', ''05'', ''06'', ''07'', 
                      ''08'', ''09'') THEN
                          (SELECT     RTRIM(warename)
                            FROM          WARECODE
                            WHERE      wareno = SUBSTRING(w.wareno, 1, 5) AND lastnode = 0) ELSE
                          (SELECT     RTRIM(warename)
                            FROM          WARECODE
                            WHERE      wareno = SUBSTRING(w.wareno, 1, 4) AND lastnode = 0) END AS 大类, CASE WHEN SUBSTRING(w.wareno, 1, 2) IN (''01'', ''02'', ''03'') THEN
                          (SELECT     RTRIM(warename)
                            FROM          WARECODE
                            WHERE      wareno = SUBSTRING(w.wareno, 1, 6) AND lastnode = 0) END AS 小类, CASE WHEN SUBSTRING(w.wareno, 1, 2) IN (''01'', ''02'', ''03'', ''05'', ''06'', ''07'', ''08'', 
                      ''09'', ''0A'') THEN ''主机'' WHEN SUBSTRING(w.wareno, 1, 2) IN (''04'') THEN ''显示器'' WHEN SUBSTRING(w.wareno, 1, 2) IN (''0B'') THEN ''配件'' END AS 主机, 
                      CASE WHEN SUBSTRING(w.wareno, 1, 4) IN (''0101'', ''0102'', ''0401'', ''0403'', ''0B02'', ''0B03'', ''0B07'', ''0B08'') OR
                      SUBSTRING(w.wareno, 1, 2) IN (''02'', ''03'', ''0A'', ''09'') THEN ''大客户'' WHEN SUBSTRING(w.wareno, 1, 4) IN (''0404'') OR
                      SUBSTRING(w.wareno, 1, 2) IN (''06'', ''08'') THEN ''商用'' WHEN SUBSTRING(w.wareno, 1, 4) IN (''0402'', ''0B05'') OR
                      SUBSTRING(w.wareno, 1, 2) IN (''07'', ''05'') THEN ''消费'' END AS 产品组, CASE WHEN SUBSTRING(w.wareno, 1, 5) IN (''01013'', ''01022'', ''01033'', ''01034'') OR
                      SUBSTRING(w.wareno, 1, 4) IN (''0602'', ''0502'') THEN ''一体机'' END AS 一体机, RTRIM(b.Brandname) AS 品牌, RTRIM(t.typename) AS 属性
FROM         dbo.WARECODE AS w INNER JOIN
                      dbo.WARETYPE AS t ON w.typeno = t.typeno INNER JOIN
                      dbo.BRAND AS b ON w.BrandNo = b.Brandno
WHERE     (w.lastnode = 1)
' 
IF NOT EXISTS (SELECT * FROM ::fn_listextendedproperty(N'MS_DiagramPane1' , N'SCHEMA',N'dbo', N'VIEW',N'product_category', NULL,NULL))
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "w"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 193
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 231
               Bottom = 95
               Right = 373
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 6
               Left = 411
               Bottom = 95
               Right = 554
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'product_category'
IF NOT EXISTS (SELECT * FROM ::fn_listextendedproperty(N'MS_DiagramPaneCount' , N'SCHEMA',N'dbo', N'VIEW',N'product_category', NULL,NULL))
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'product_category'
