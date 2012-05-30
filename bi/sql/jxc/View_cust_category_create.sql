/****** Object:  View [cust_category]    Script Date: 01/14/2012 16:11:13 ******/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[cust_category]') AND OBJECTPROPERTY(id, N'IsView') = 1)
EXEC dbo.sp_executesql @statement = N'CREATE VIEW dbo.cust_category
AS
SELECT     c.code AS �ͻ�����, c.name AS �ͻ�����, CASE WHEN substring(c.code, 1, 2) = ''fx'' THEN ''����'' WHEN substring(c.code, 1, 2) 
                      = ''HY'' THEN ''�ͻ�'' WHEN substring(c.code, 1, 2) = ''ZX'' THEN ''��ҵ'' END AS ����, CASE WHEN SUBSTRING(c.code, 1, 4) 
                      = ''FX01'' THEN ''����'' WHEN SUBSTRING(c.code, 1, 4) = ''fx05'' THEN ''����'' WHEN SUBSTRING(c.code, 1, 4) = ''fx12'' THEN ''����'' WHEN substring(c.code, 1, 2) IN (''hy'', 
                      ''zx'') THEN rtrim(t .name) END AS �г�, CASE WHEN SUBSTRING(c.code, 1, 2) = ''fx'' THEN
                          (SELECT     rtrim(name)
                            FROM          CUSTOMER
                            WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 6)) END AS ����, CASE WHEN SUBSTRING(c.code, 1, 2) IN (''hy'', ''zx'') THEN
                          (SELECT     rtrim(name)
                            FROM          CUSTOMER
                            WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 4)) END AS ��ҵ, CASE WHEN SUBSTRING(c.code, 1, 2) IN (''hy'', ''zx'') THEN
                          (SELECT     rtrim(name)
                            FROM          CUSTOMER
                            WHERE      lastnode = 0 AND code = SUBSTRING(c.code, 1, 6)) END AS ����ҵ, RTRIM(a.accountname) AS ͨ·, CASE WHEN substring(c.code, 1, 2) IN (''fx'') 
                      THEN rtrim(t .name) END AS ����
FROM         dbo.CUSTOMER AS c INNER JOIN
                      dbo.ACCOUNT AS a ON c.accno = a.accountno LEFT OUTER JOIN
                      dbo.CUSTTYPE AS t ON c.ClassID = t.code
WHERE     (c.lastnode = 1)
' 
IF NOT EXISTS (SELECT * FROM ::fn_listextendedproperty(N'MS_DiagramPane1' , N'USER',N'dbo', N'VIEW',N'cust_category', NULL,NULL))
EXEC dbo.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[35] 4[20] 2[28] 3) )"
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
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 180
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "a"
            Begin Extent = 
               Top = 6
               Left = 218
               Bottom = 95
               Right = 371
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 13
               Left = 457
               Bottom = 102
               Right = 599
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
         Alias = 1290
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
' , @level0type=N'USER',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'cust_category'
IF NOT EXISTS (SELECT * FROM ::fn_listextendedproperty(N'MS_DiagramPaneCount' , N'USER',N'dbo', N'VIEW',N'cust_category', NULL,NULL))
EXEC dbo.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'USER',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'cust_category'
