
CREATE TABLE EPaymentTokens(
	[EPTokenId] BIGINT IDENTITY(1,1) NOT NULL,
	[EPToken] [nvarchar](1000) NULL,
	[PaymentMetaData] [varchar](3000) NULL,
	[MerchantId] bigint NULL,
	[InvoiceId] [bigint] NULL,
	[Amount] [decimal](18, 3) NULL,
	[PortalLoginId] int NULL,
	[Paidby] [nvarchar](200) NULL,--Anonymous payer 
	--[OPDetailId] [int] NULL,
	[CreatedTime] [datetime] NULL,
	--[DateCompleted] [datetime] NULL,
	[ExpiryTime] [datetime] NULL
	)

    
Create Table EPaymentFeeConfigurations
(
	[EPaymentFeeConfigId] [int] IDENTITY(1,1) NOT NULL,
	[ServiceName] [decimal](18, 3) NULL,
	FeeAmount int null,
	[Status] bit DEFAULT 0
	)

    
CREATE TABLE EPaymentTransactions
(--Fields with Auth as prefix is Electronic Authorizer like KNET,VISA MC Responses
	[EPaymentTranId] [int] NOT NULL,
	[TransId] [bigint] NULL,
	[AuthEPaymentId] [bigint] NULL,
	[Status] [varchar](20) NULL,--Success, Cancelled, Failed
	[InvoiceId] [bigint] NULL,
	[TranStartTime] [datetime] NULL,
	[TranEndTime] [datetime] NULL,
	[ClientIPAddress] [varchar](15) NULL,
	[SessionId] [varchar](100) NULL,
	--[LogInPortId] [int] NULL,
	[Amount] [decimal](18, 3) NULL,
	[BankId] [bigint] NULL,
	[Error] [varchar](500) NULL,
	[AuthResponse] [varchar](500) NULL,
	[MerchantId] bigint NULL,
	--[Result] [varchar](50) NULL,
	--[PostDate] [datetime] NULL,
	[AuthByBank] [varchar](200) NULL,
	[RefByBank] [varchar](200) NULL,
	[PortalLoginId] int NULL,
	[Paidby] [nvarchar](200) NULL,--Anonymous payer 
	--[PaymentFor] [varchar](50) NULL,
	--[PaidByType] [char](1) NULL,
	--[TempDeclNumber] [varchar](50) NULL,
	[CheckId] [int] NULL,
	[AuthTranId] [int] NULL,
	[TranDate] [datetime] NULL,
	--[CreatedBy] [varchar](30) NULL,
	[DateModified] [datetime] NULL,
	[ModifiedBy] [varchar](30) NULL,
	--[OwnerLocId] [int] NULL,
	--[OwnerOrgId] [int] NULL,
	--[PaymentId] [int] NULL,
	--[ReceiptId] [int] NULL,
	--[BrPaymentTransactionId] [int] NULL,
	[EPTokenId]  BIGINT NULL,
	--[ReferenceId] [int] NULL,
	--[ReferenceType] [varchar](50) NULL,
	)

