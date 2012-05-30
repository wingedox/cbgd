CREATE TABLE [dbo].[bi_jxc](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [notedate] [datetime] NOT NULL,
    [noteno] [varchar](32) NULL,
    [department] [varchar](2) NOT NULL,
    [partnerno] [varchar](32) NULL,
    [houseno] [varchar](32) NOT NULL,
    [saleman] [varchar](32) NULL,
    [deptno] [varchar](32) NULL,
    [wareno] [varchar](32) NOT NULL,
    [amount] [int] NULL,
    [price] [money] NULL,
    [curr] [money] NOT NULL,
    [type] [varchar](2) NOT NULL,
    [UpdateDate] [datetime] NOT NULL,
    [computed] [bit] NOT NULL,
 CONSTRAINT [PK_bi_jxc] PRIMARY KEY CLUSTERED
([id] ASC) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF,
    IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON,
    ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]