
CREATE TABLE [etrade].[UserActivityAudit](
	[UserActivityAuditId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	-- [LogOnTime] [datetime] NULL,
	-- [LogOutTime] [datetime] NULL,
	[UserId] [varchar](100) NULL,
	-- [SessionId] [varchar](100) NULL,
	[IPAddress] [varchar](100) NULL,
	-- [McUserOrgId] [int] NULL,
	-- [McUsername] [varchar](200) NULL,
	-- [legalEntity] [varchar](200) NULL,
	-- [ClearingAgentService] [bit] NULL,
	-- [OrganizationService] [bit] NULL,
	[ActivityPerformed] [varchar](200) NULL,
	[Datetime] [datetime] NULL,
	-- [LogInPortId] [varchar](50) NULL,
	-- [SignInSignOut] [varchar](5) NULL,
	-- [ServiceId] [varchar](50) NULL,
	[OtherAdditionalinfo] [nvarchar](4000) NULL,
    [GeographicalLocation] [nvarchar](250) NULL,
	[DeviceType] [nvarchar](250) NULL,
	[BrowserIP] [varchar](250) NULL,
	[DeviceVersion] [varchar](250) NULL,
	[DeviceManufacturer] [varchar](250) NULL,
	[DeviceSerial] [varchar](250) NULL,
	[DeviceModel] [varchar](250) NULL,
    [MacId] [varchar](100) NULL
) ON [SECONDARY]
GO
