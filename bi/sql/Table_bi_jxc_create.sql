USE [JXCDATA0002]
GO

/****** Object:  Table [dbo].[bi_jxc]    Script Date: 05/22/2012 17:19:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[bi_jxc](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[account] [varchar](32) NOT NULL,
	[dbname] [varchar](32) NOT NULL,
	[notetype] [varchar](10) NOT NULL,
	[notedate] [datetime] NOT NULL,
	[noteno] [varchar](32) NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
	[computed] [bit] NOT NULL,
 CONSTRAINT [PK_bi_jxc] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[bi_jxc] ADD  CONSTRAINT [DF_bi_jxc_UpdateDate]  DEFAULT (getdate()) FOR [UpdateDate]
GO

ALTER TABLE [dbo].[bi_jxc] ADD  CONSTRAINT [DF_bi_jxc_computed]  DEFAULT ((0)) FOR [computed]
