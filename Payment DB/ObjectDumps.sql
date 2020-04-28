CREATE PROCEDURE [dbo].[EpaymentStatisticsSP]
AS
    BEGIN
        DECLARE @Epaycount INT;
        DECLARE @EpayAmount MONEY;
        DECLARE @ConsigneeCount INT;
        DECLARE @VerifiedMailID INT;
        DECLARE @PaidByConsignee INT;
        DECLARE @TotalPaidByConsignee MONEY;
        DECLARE @MaxAmount MONEY;
        DECLARE @MInAmount MONEY;    
        --DECLARE @Str VARCHAR(Max)        
        --Count of ePayment Transactions    
        SELECT @Epaycount = COUNT(1)
        FROM OnlinePaymentDetails od
             INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
        WHERE od.StateId = 'Success'
              AND od.TranStpDateTime > '2018-06-22 00:00:00.000';

        --Total Value of ePayment Transaction    
        SELECT @EpayAmount = SUM(od.Amount)
        FROM OnlinePaymentDetails od
             INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
        WHERE od.StateId = 'Success'
              AND od.TranStpDateTime > '2018-06-22 00:00:00.000';

        --Count of distinct consignee for ePayment transactions    
        SELECT @ConsigneeCount = COUNT(DISTINCT(D.ConsigneeId))
        FROM OnlinePaymentDetails od
             INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
        WHERE od.StateId = 'Success'
              AND od.TranStpDateTime > '2018-06-22 00:00:00.000'; --and     
        --od.PaidByType = 'O'    
        -- Count of Verified eTrade Accounts                    
        SELECT @VerifiedMailID = COUNT(DISTINCT Emailid)
        FROM etrade.MobileUser
        WHERE ISNULL(isInternal, 0) = 0
              AND IsEmailVerified = 1;

        -- Count of ePayment Transactions Paid by Consignee    
        SELECT @PaidByConsignee = COUNT(od.OPDetailId)
        FROM OnlinePaymentDetails od
             INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
        WHERE od.StateId = 'Success'
              AND od.TranStpDateTime > '2018-06-22 00:00:00.000'
              AND od.PaidByType = 'O';

        --Total Value of ePayment Transaction paid by consignee    
        SELECT @TotalPaidByConsignee = SUM(Amount)
        FROM OnlinePaymentDetails od
             INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
        WHERE od.StateId = 'Success'
              AND od.TranStpDateTime > '2018-06-22 00:00:00.000'
              AND od.PaidByType = 'O';
        WITH TopTenDesc
             AS (SELECT TOP 10 Amount
                 FROM OnlinePaymentDetails od
                      INNER JOIN Declarations D ON D.DeclarationId = od.DeclarationId
                 WHERE od.StateId = 'Success'
                       AND od.TranStpDateTime > '2018-06-22 00:00:00.000'
                 ORDER BY Amount DESC)
             SELECT @MaxAmount = MAX(Amount), 
                    @MinAmount = MIN(Amount)
             FROM TopTenDesc;

        --Select @Epaycount as Epaycount, @EpayAmount as EpayAmount, @ConsigneeCount as ConsigneeCount,    
        --  @VerifiedMailID  as VerifiedMailID, @PaidByConsignee as PaidByConsignee,     
        --  @TotalPaidByConsignee as  TotalPaidByConsignee, @MaxAmount as MaxAmount, @MInAmount as MInAmount    

        SELECT(N'‎ملخص فنى عن عمليات الدفع الإلكتروني  من 22 يونيو 2018 إلى‎') + SPACE(2) + CONVERT(VARCHAR(25), GETDATE()) AS Header, 
              CAST(@Epaycount AS NVARCHAR(50)) AS Epaycount, 
              CAST(@EpayAmount AS NVARCHAR(50)) AS EpayAmount, 
              CAST(@ConsigneeCount AS NVARCHAR(50)) AS ConsigneeCount, 
              CAST(@VerifiedMailID AS NVARCHAR(50)) AS VerifiedMailID, 
              CAST(@PaidByConsignee AS NVARCHAR(50)) AS PaidByConsignee, 
              CAST(@TotalPaidByConsignee AS NVARCHAR(50)) AS TotalPaidByConsignee, 
              CAST(@MInAmount AS NVARCHAR(50)) AS MinAmount, 
              CAST(@MaxAmount AS NVARCHAR(50)) AS MaxAmount;

        --(N'‏2018‎/01ت‎')  
        /*SET @Str = '[E-Payment Transaction Count] ='    
            + CAST(@Epaycount AS VARCHAR(50)) + SPACE(2)    
            + '[E-Payment Total Amount] =' + CAST(@EpayAmount AS VARCHAR(50))    
            + SPACE(2) + '[Distinct Consignee Count] ='    
            + CAST(@ConsigneeCount AS VARCHAR(50)) + SPACE(2)    
            + '[Total [E-Trade] Verified Accounts ] ='    
            + CAST(@VerifiedMailID AS VARCHAR(50)) + SPACE(2)    
            + '[E-Payment Transactions Count Paid by Consignee] ='    
            + CAST(@PaidByConsignee AS VARCHAR(50)) + SPACE(2)    
            + '[Total Value Paid by Consignee] ='    
            + CAST(@TotalPaidByConsignee AS VARCHAR(50)) + SPACE(2)    
            + '[Top 10 Max Amount] =' + CAST(@MaxAmount AS VARCHAR(50))    
            + SPACE(2) + '[Top 10 Min Amount] ='    
            + CAST(@MInAmount AS VARCHAR(50))     
            PRINT @Str*/

    END;

  
----sp_helptext 'dbo.GetOnlinePaymentDetailsWithToken'      

ALTER PROC [dbo].[GetOnlinePaymentDetailsWithToken](@TokenId BIGINT)
AS
    BEGIN            
        -- Sample Query String                                        
        -- DeclarationId=7672570&TempDeclNumber=TIM/19167/KWI17&Amount=413.68&PortalLoginId=broker.kwi                                        
        --  &LogInPortId=8998&OrganizationId=44676&PaymentFor=1&PaidByType=B&lang=eng&CheckId=4073678                                        
        DECLARE @Delimit CHAR(1);
        SET @Delimit = '~';
        DECLARE @QryStr VARCHAR(2000), @ExpTime DATETIME, @PostDate DATETIME;
        DECLARE @DeclId INT, @TDeclNo VARCHAR(20), @Amt NUMERIC(18, 3), @PrtLgnId VARCHAR(20), @LgnPrtId INT, @OrgId INT, @Pay4 CHAR(1), @PaidBy CHAR(10), @lang VARCHAR(3), @chkId INT, @PayId INT, @CustomsDuty VARCHAR(20), @HandlingCharges VARCHAR(20), @Storage VARCHAR(20), @Penalties VARCHAR(20), @Others VARCHAR(20), @Certificates VARCHAR(20), @Printing VARCHAR(20), @Guarantees VARCHAR(20), @ReceiptId INT, @TotalAmount NUMERIC(18, 3), @KGACService NUMERIC(18, 3), @GCSService NUMERIC(18, 3), @KNETAccType VARCHAR(20), @BrPaymentTransactionId INT, @OLTransId VARCHAR(20), @PayeeMailId VARCHAR(50), @PayUserMailid VARCHAR(50)= '', @BankAuth VARCHAR(20), @UserId VARCHAR(50), @RedirectURL VARCHAR(500), @OnlineReciptNo VARCHAR(20), @PaymentId BIGINT, @OLPaymentId BIGINT, @OPDetId INT, @eServiceUserEmailId VARCHAR(500)= NULL;
        DECLARE @OrgName NVARCHAR(100), @OrgNameAra NVARCHAR(100);
        DECLARE @TranStat VARCHAR(30), @AllowGet CHAR(1);
        DECLARE @PaidByTypeNameCase NVARCHAR(500);-- NEWLY ADDED TO HANDLE PAID BY NAME FOR ESERVICES  

        SET @AllowGet = 'n';
        DECLARE @DateNow DATETIME;
        SET @DateNow = GETDATE();
        DECLARE @MyReferenceType VARCHAR(50)= NULL;
        SELECT @MyReferenceType = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'ReferenceType=%';
        SELECT @QryStr = QueryString, 
               @ExpTime = ExpiryTime, 
               @RedirectURL = RedirectURL, 
               @OPDetId = OPDetailId
        FROM OnlinePaymentTokens
        WHERE TokenId = @TokenId;

        -- get the initiated values                          
        SELECT @Pay4 = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'PaymentFor=%';
        SELECT @DeclId = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'DeclarationId=%';

        -- cahnged by azhar                    
        IF @MyReferenceType IS NOT NULL
           AND @MyReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS')
            BEGIN
                PRINT(@Delimit);
                SELECT @Amt = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReceiptAmount=%';
        END;
            ELSE
            BEGIN
                SELECT @Amt = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Amount=%';
        END;
        SELECT @PaidBy = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'PaidBy=%';
        SELECT @eServiceUserEmailId = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'eServiceUserEmailId=%';
        DECLARE @nDeclId INT, @nAmt NUMERIC(18, 3), @nPay4 CHAR(1);
        PRINT 'checking @TranStat';
        PRINT @nDeclId;
        PRINT @nAmt;
        PRINT @nPay4;
        PRINT 'checking @TranStat';

        -- Retrieve the old successfully paid values.              
        SELECT @OLPaymentId = OLPaymentId, 
               @chkId = CheckId, 
               @TranStat = StateId            
        -- , @nAmt = Amount, @nPay4 = PaymentFor                           
        -- @nTDeclNo=TempDeclNumber                          
        FROM OnlinePaymentDetails
        WHERE DeclarationId = @nDeclId
              AND Amount = @nAmt
              AND PaymentFor = @nPay4;
        PRINT 'checking @TranStat';
        PRINT @TranStat;
        PRINT 'checking @TranStat';

        -- OPDetailId = @OPDetId                            
        -- select  from OnlinePaymentDetails where OLPaymentId = @PaymentId                            
        IF @TranStat = 'Success' -- Success allow retrieving the details.                    
            BEGIN
                SET @AllowGet = 'n';
        END;

        -- If Expired transaction and not allowed and expiry time is not found ... DO NOT proceed.                            
        IF((DATEDIFF(n, @DateNow, @ExpTime) < 0
            AND @AllowGet = 'n')
           AND @PaidBy = 'B') -- Expiry Date Time is updated during Token creation with 10 mins.                              
            BEGIN
                PRINT 'Token Expired.....'; -- added to handle Token Time out!!!!                              

                IF @AllowGet = 'n'
                    EXEC UpdatePaymentDetailsCanceledOrFailed 
                         @CheckId = @chkId, 
                         @TranStatus = 'Expired', 
                         @TranStpDateTime = @DateNow, 
                         @PaymentId = @OLPaymentId, 
                         @error = 'Expired';
                RETURN -1;
        END;
        DECLARE @ReferenceType VARCHAR(50)= NULL;
        SELECT @ReferenceType = dbo.Split(items, '=', 2)
        FROM SplitToTable(@QryStr, @Delimit)
        WHERE items LIKE 'ReferenceType=%';
        PRINT '@ReferenceType';
        PRINT @ReferenceType;
        IF(@ReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS'))
            BEGIN
                PRINT 'new addition to get state';
                SELECT @TranStat = StateId
                FROM Onlinepaymentdetails
                WHERE opdetailid =
                (
                    SELECT opdetailid
                    FROM OnlinePaymentTokens
                    WHERE Tokenid = @TokenId
                );--3483338421784853758--            

                PRINT @TranStat;
        END;
        IF @ReferenceType IS NOT NULL
           AND @ReferenceType IN('SettlementForm', 'Manifests', 'SuppManifests', 'TransferPaymentRequest', 'BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS', 'MCReExportPenalty')
            BEGIN
                DECLARE @tempuser NVARCHAR(200);
                DECLARE @PaymentMethod INT= NULL;
                DECLARE @BankId INT= NULL;
                DECLARE @BankBranch NVARCHAR(100)= NULL;
                DECLARE @PaymentTypeId INT= 0;
                DECLARE @ChequeNumber NVARCHAR(30)= NULL;
                DECLARE @DrawerAccountNumber BIGINT= NULL;
                DECLARE @Amount DECIMAL(18, 3)= NULL;
                DECLARE @ReceiptNumber VARCHAR(50)= NULL;
                DECLARE @ReceiptDate VARCHAR(50)= NULL;
                DECLARE @PaidFor INT= NULL;
                DECLARE @AccountNumber VARCHAR(50)= NULL;
                DECLARE @ReferenceId INT= NULL;
                DECLARE @ReferenceNumber VARCHAR(50)= NULL;
                DECLARE @PaidByType CHAR(1)= NULL;
                DECLARE @OwnerLocid INT= NULL;
                DECLARE @OwnOrgId INT= NULL;
                DECLARE @MCPaymentId INT;
                DECLARE @RequestedFrom VARCHAR(50)= NULL;
                DECLARE @FromDate VARCHAR(50)= NULL;
                DECLARE @ToDate VARCHAR(50)= NULL;
                DECLARE @ContractPaymentType NVARCHAR(200)= NULL;
                DECLARE @ForTheperiod NVARCHAR(200)= NULL;
                DECLARE @PaidByNameAra NVARCHAR(500)= NULL;
                DECLARE @PaidByName NVARCHAR(200)= NULL;
                DECLARE @PayeeUserId VARCHAR(50)= NULL;
                SELECT @FromDate = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'FromDate=%';
                SELECT @ToDate = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ToDate=%';
                SELECT @PaymentMethod = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaymentMode=%';
                SELECT @BankId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'BankId=%';
                SELECT @BankBranch = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'BankBranch=%';
                SELECT @PaymentTypeId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaymentTypeId=%';
                SELECT @ChequeNumber = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'CheckNumber=%';
                SELECT @DrawerAccountNumber = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'DrawerAccountNumber=%';
                SELECT @Amount = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReceiptAmount=%';
                SELECT @ReceiptNumber = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReceiptNo=%';
                SELECT @ReceiptDate = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReceiptDate=%';
                SELECT @PaidFor = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaidFor=%';
                SELECT @AccountNumber = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'AccountNumber=%';
                SELECT @ReferenceId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReferenceId=%';
                SELECT @PaidByType = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaidByType=%';
                SELECT @OwnerLocid = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'OwnerLocId=%';
                SELECT @UserId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'UserId=%';
                SELECT @OwnOrgId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'OwnerOrgId=%';
                SELECT @lang = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'lang=%';
                PRINT 'Printing PaidByType and PaidBy ....';
                PRINT @PaidByType;
                PRINT @PaidBy;
                IF(@ReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS'))
                    BEGIN
                        SET @UserId = @UserId;     
                        --SET @UserId=@eServiceUserEmailId   
                END;
                    ELSE
                    BEGIN
                        PRINT(@PaidByType);
                        SELECT @OwnOrgId =
                        (
                            SELECT organizationid
                            FROM Users
                            WHERE UserId = @UserId
                        );
                        SELECT @PaidBy = @PaidByType;

                        --IF (@lang LIKE '%ar%')            
                        --BEGIN            
                        -- PRINT (@lang);            
                        -- SELECT @UserId = (            
                        --   SELECT cast(isnull(FirstName, '') + ' ' + isnull(LastName, '') AS nVARCHAR(500))            
                        --   FROM People            
                        --   WHERE PersonalId IN (      
                        --     SELECT PersonalId            
                        --     FROM Users            
                        --     WHERE userid = @UserId            
                        --     )            
                        --   );         
                        -- PRINT (@UserId);            
                        -- PRINT ('latest');            
                        --END            
                        --ELSE            
                        --BEGIN            
                        -- SELECT @UserId = (            
                        --   SELECT cast(isnull(FirstName, '') + ' ' + isnull(LastName, '') AS nVARCHAR(500))           
                        --   FROM People            
                        --   WHERE PersonalId IN (            
                        --     SELECT PersonalId            
                        --     FROM Users            
                        --     WHERE userid = @UserId            
                        --     )            
                        --   );            
                        --END            

                END;
                SELECT @RequestedFrom = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'RequestedFrom=%';
                SELECT @MCPaymentId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'MCPaymentId=%';
                SELECT @ReferenceNumber = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReferenceNumber=%';
                SELECT @Pay4 = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaymentFor=%';
                SELECT @ReceiptNumber = ReceiptNumber
                FROM MCPayments
                WHERE MCPaymentId = @MCPaymentId;
                IF(@ReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS'))
                    BEGIN
                        PRINT('1');            
                        --3483338421784853758            
                        SELECT @OLPaymentId = OLPaymentId, 
                               @BankAuth = AuthByBank, 
                               @PostDate = PostDate, 
                               @OLTransId = ISNULL(RefByBank, 0), 
                               @UserId = @UserId
                        FROM OnlinePaymentDetails OPD
                             INNER JOIN OnlinePaymentTokens OPT ON OPD.OPDetailId = OPT.OPDetailId
                        WHERE OPT.TokenId = @TokenId;

                        --select * FROM OnlinePaymentDetails WHERE TokenId=3483338421784853758            

                        SELECT @ReceiptNumber = KNetReceiptNo
                        FROM etrade.EServiceRequests
                        WHERE EServiceRequestId = @ReferenceId;
                END;
                    ELSE
                    BEGIN
                        PRINT('2');
                        PRINT ' checking... transtat';
                        SELECT @OLTransId = ISNULL(RefByBank, 0), --- ??? doubtfull                            
                               @PostDate = ISNULL(PostDate, GETDATE()), 
                               @BankAuth = AuthByBank, 
                               @UserId = PortalLoginId, 
                               @OLPaymentId = OLPaymentId, 
                               @TranStat = Result
                        FROM OnlinePaymentDetails
                        WHERE TokenId = @TokenId;
                        PRINT @TranStat;
                END;

                --if @OLTransId = 0                              
                --begin                                    
                --  set @OLTransId = abs(CAST(CRYPT_GEN_RANDOM(6) AS INT))                            
                --  update OnlinePaymentDetails set PaymentTransactionId = @OLTransId where TokenId = @TokenId                                   
                --end                               
                SELECT @OrgNameAra = ISNULL(LocalDescription, NAME), 
                       @OrgName = NAME
                FROM Organizations
                WHERE OrganizationId = @OwnOrgId;
                IF @ReferenceType = 'TransferPaymentRequest'
                    BEGIN
                        DECLARE @Contract INT;
                        DECLARE @PaymentType INT;
                        DECLARE @ContractName NVARCHAR(200)= '';
                        DECLARE @ContractName_ara NVARCHAR(200)= '';
                        DECLARE @PaymentTypeName NVARCHAR(200)= '';
                        DECLARE @PaymentTypeName_ara NVARCHAR(200)= '';
                        IF @ReceiptNumber IS NULL
                           OR @ReceiptNumber = ''
                            BEGIN
                                SELECT @ReceiptNumber = ReceiptNumber
                                FROM MCPayments
                                WHERE MCPaymentId = @MCPaymentId;
                        END;
                        IF(@PaidBy IS NOT NULL
                           AND @PaidBy <> '')
                            BEGIN
                                SELECT @PaidByName = T.NAME, 
                                       @PaidByNameAra = T_Ara.NAME
                                FROM Types T
                                     INNER JOIN Types_ara T_Ara ON T.TypeId = T_Ara.TypeId
                                WHERE T.TypeId = @PaidBy;
                        END;
                        SELECT @Contract = Contract, 
                               @PaymentType = PaymentType
                        FROM TransferPaymentRequest
                        WHERE TransferPaymentRequestId = @ReferenceId;
                        SELECT @ContractName = T.NAME, 
                               @ContractName_ara = T_Ara.NAME
                        FROM Types T
                             INNER JOIN Types_ara T_Ara ON T.TypeId = T_Ara.TypeId
                        WHERE T.TypeId = @Contract;
                        SELECT @PaymentTypeName = T.NAME, 
                               @PaymentTypeName_ara = T_Ara.NAME
                        FROM Types T
                             INNER JOIN Types_ara T_Ara ON T.TypeId = T_Ara.TypeId
                        WHERE T.TypeId = @PaymentType;
                        SET @ContractPaymentType = @ContractName_ara + N' <br/> ' + @PaymentTypeName_ara; -- + N'<br/>'+ @ContractName+N' '+@PaymentTypeName                        
                        SET @ForTheperiod = ISNULL(@FromDate, '') + ' - ' + ISNULL(@ToDate, '');
                END;

                /* Payee Mail Id Retrieval Starts*/

                IF @PaidBy = 'O'
                    BEGIN
                        SELECT @OrgId = OrganizationId
                        FROM OnlinePaymentDetails
                        WHERE ReferenceId = @ReferenceId;
                END;
                IF @OrgId > 0
                   OR @OwnOrgId > 0
                    BEGIN
                        IF(@ReferenceType IN('Manifests', 'SuppManifests', 'Settlementform'))
                            BEGIN --Get User's Email              
                                PRINT 'Get Users Email ';
                                PRINT @PayeeMailId;
                                SELECT @PayeeMailId = ISNULL(Email, '--')
                                FROM Contacts
                                WHERE ParentId =
                                (
                                    SELECT PersonalId
                                    FROM Users
                                    WHERE UserId = @UserId
                                );
                        END; --Get User's Email                  

                        PRINT '@PayeeMailId';
                        PRINT @PayeeMailId;
                        PRINT '@ReferenceType';
                        PRINT @ReferenceType;
                        SET @PayeeMailId = ISNULL(@PayeeMailId, '--');
                        IF(@PayeeMailId = '--')
                            BEGIN
                                PRINT 'Get Users Email --';
                                PRINT @PayeeMailId;
                                SELECT @PayeeMailId = ISNULL(Email, '--')
                                FROM Contacts
                                WHERE ParentId = CASE
                                                     WHEN @OrgId > 0
                                                     THEN ISNULL(@OrgId, 0)
                                                     ELSE @OwnOrgId
                                                 END;
                                PRINT 'Get Users Email --after';
                                PRINT @PayeeMailId;
                        END;
                        IF(@PayeeMailId = '--')
                            BEGIN
                                SET @PayeeMailId = ISNULL(@eServiceUserEmailId, '--');
                        END;
                        IF(@ReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS'))
                            BEGIN
                                SET @PayeeMailId = ISNULL(@eServiceUserEmailId, '--');
                                SET @PAIDBYNAME =
                                (
                                    SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                                    FROM etrade.mobileuser
                                    WHERE emailid = @eServiceUserEmailId
                                );
                                SET @PAIDBYNAMEARA =
                                (
                                    SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                                    FROM etrade.mobileuser
                                    WHERE emailid = @eServiceUserEmailId
                                );
                        END;
                END;
                IF(@ReferenceType IN('BRSERenewalDocs', 'PrintLostIdCard', 'WhomItConcernsLetterService', 'BRSISSUANCEDOCS', 'BRStransferDOCS'))
                    BEGIN
                        SET @PayeeMailId = ISNULL(@eServiceUserEmailId, '--');
                        SET @PAIDBYNAME =
                        (
                            SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                            FROM etrade.mobileuser
                            WHERE emailid = @eServiceUserEmailId
                        );
                        SET @PAIDBYNAMEARA =
                        (
                            SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                            FROM etrade.mobileuser
                            WHERE emailid = @eServiceUserEmailId
                        );
                END;
                IF(@eServiceUserEmailId IS NOT NULL)
                    BEGIN
                        SET @PaidByTypeNameCase =
                        (
                            SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                            FROM etrade.mobileuser
                            WHERE emailid = @eServiceUserEmailId
                        );
                END;
                    ELSE
                    BEGIN
                        SET @PaidByTypeNameCase = CASE
                                                      WHEN @PaidByType = 'B'
                                                      THEN N'المخلص  / Broker'
                                                      ELSE N'المستفيد / Consignee'
                                                  END + N' <BR /> ' + ISNULL(@OrgNameAra, @OrgName);
                END;
                PRINT 'checking @PayeeMailId' + @PayeeMailId;

                /* Payee Mail Id Retrieval Ends*/

                SELECT @PaymentMethod AS PaymentMethod, 
                       @BankId AS BankId, 
                       @BankBranch AS BankBranch, 
                       @PaymentTypeId AS PaymentTypeId, 
                       @ChequeNumber AS ChequeNumber, 
                       @DrawerAccountNumber AS DrawerAccountNumber, 
                       @Amount AS Amount, 
                       @ReceiptNumber AS ReceiptNumber, 
                       @ReceiptDate AS ReceiptDate, 
                       @PaidFor AS PaidFor, 
                       @PaidBy AS PaidBy, 
                       @AccountNumber AS AccountNumber, 
                       @ReferenceId AS ReferenceId, 
                       @ReferenceNumber AS ReferenceNumber, 
                       @ReferenceType AS ReferenceType, 
                       RTRIM(@PaidByType) AS PaidByType, 
                       @OwnerLocid AS OwnerLocid, 
                       @UserId AS UserId, 
                       @OwnOrgId AS OwnOrgId, 
                       @MCPaymentId AS MCPaymentId, 
                       @lang AS lang, 
                       @PayeeMailId AS PayeeMailId, 
                       @RedirectURL AS RedirectURL, 
                       @ReferenceNumber AS TempDeclNumber, 
                       @Pay4 AS PaymentFor,


              
                  
                  
                    
                  
                  
                  
   WHEN @PAY4 = 2 THEN N'الإيداع <BR /> Deposits'                        
                  
                  
                  
                    
                  
                  
                  
   WHEN @PAY4 = 3                        
                  
                  
                  
                    
                  
                  
                  
   THEN N'حساب الإيرادات <BR /> Customs Revenue Account'                       
                  
                  
                  
                    
             
                  
                  
 else '' end PaymentForRcpt,                       
                  
                  
                  
 */

                       -- BELOW FIELDS ARE ADDED FOR THE KNET MAILING..... 04-04-2018                         
                       CASE
                           WHEN @Pay4 = 1
                           THEN N'رسوم جمركية <BR /> Customs Duty'
                           WHEN @PAY4 = 2
                           THEN N'الإيداع <BR /> Deposits'
                           WHEN @PAY4 = 3
                           THEN N'حساب الإيرادات <BR /> Revenue Account'
                           ELSE ''
                       END PaymentForMail, 
                       @BankAuth BankAuthNo
                       ,            
                       --,CASE             
                       -- WHEN @PaidByType = 'B'            
                       --  THEN N'المخلص  / Broker'            
                       -- ELSE N'المستفيد / Consignee'            
                       -- END + N' <BR /> ' + ISNULL(@OrgNameAra, @OrgName) AS PaidByTypeName     
                       @PaidByTypeNameCase PaidByTypeName, 
                       N'دفع الكتروني <BR /> e-Payment ' PaymentTypeMail, 
                       @OLPaymentId PaymentId, 
                       @ReceiptNumber OnlineReceiptNo
                       , -- corrected by gh.mani 26Mar                     
                       @PostDate PostDate,            
                       -- broker orgname is broker name                    
                       @TokenId AS TokenId, 
                       @OLTransId AS OLTransId,            
                       --       -- Added by Gopinath, 13-jun-2018  ///// REVERTED.                            
                       @ReferenceId AS CheckId, 
                       0 AS DeclarationId, 
                       @UserId AS PortalLoginId
                       ,            
                       --,Case when   @eServiceUserEmailId is not null then @eServiceUserEmailId--(SELECT cast(isnull(FirstName, '') + ' ' + isnull(LastName, '') AS nVARCHAR(50)) from etrade.mobileuser where emailid=  @eServiceUserEmailId)      
                       --else   @PrtLgnId end as  PortalLoginId       
                       @LgnPrtId AS LogInPortId, 
                       @OwnOrgId AS OrganizationId, 
                       '' AS PayId, 
                       0 AS CustomsDuty, 
                       0 AS HandlingCharges, 
                       0 AS Storage, 
                       0 AS Penalties, 
                       0 AS Others, 
                       0 AS Certificates, 
                       0 AS Printing, 
                       0 AS Guarantees, 
                       ISNULL(@OrgName, '--') OrgName, 
                       ISNULL(@OrgNameAra, '--') OrgNameAra, 
                       @FromDate AS FromDate, 
                       @ToDate AS ToDate, 
                       @ContractPaymentType AS ContractPaymentType, 
                       @ForTheperiod AS ForTheperiod, 
                       @PaidByNameAra AS PaidByNameAra, 
                       @PaidByName AS PaidByName, 
                       @ReceiptId AS ReceiptId, 
                       @BrPaymentTransactionId BrPaymentTransactionId, 
                       @TranStat Result;
        END;
            ELSE
            BEGIN
                SELECT @DeclId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'DeclarationId=%';
                SELECT @TDeclNo = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'TempDeclNumber=%';
                SELECT @Amt = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Amount=%';
                SELECT @PrtLgnId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PortalLoginId=%';
                SELECT @LgnPrtId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'LogInPortId=%';
                IF @LgnPrtId = ''
                    SELECT @LgnPrtId = dbo.Split(items, '=', 2)
                    FROM SplitToTable(@QryStr, @Delimit)
                    WHERE items LIKE 'OwnerLocId=%';
                SELECT @chkId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'CheckId=%';

                -- Correction done as Tokens table is holding wrong org id of the transaction, so taking it from ONLPdetails                            
                SELECT @OrgId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'OrganizationId=%';
                SELECT @PaidBy = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaidByType=%';
                IF @PaidBy = 'O'
                    BEGIN
                        SELECT @OrgId = OrganizationId
                        FROM OnlinePaymentDetails
                        WHERE CheckId = @chkId;
                END;
                IF @OrgId > 0
                    BEGIN
                        SELECT @PayeeMailId = ISNULL(Email, '--')
                        FROM Contacts
                        WHERE ParentId = @OrgId;

                        -- if @PaidBy = 'B'                             
                        -- begin                            
                        --select @PayeeMailId = ISNULL( Email,'--') from Contacts where ParentId=@OrgId                            
                        -- end                            
                        -- else                            
                        IF @PaidBy = 'O'
                            BEGIN
                                PRINT @OrgId; -- PayUser Mail Id is configured to receive CC mail.                            

                                SELECT @PayUserMailid = EmailId
                                FROM etrade.MobileUser mu
                                     INNER JOIN etrade.MobileUserOrgMaps muom ON mu.UserId = muom.UserId
                                WHERE muom.OrganizationId = @OrgId;
                        END;
                        SELECT @OrgNameAra = ISNULL(LocalDescription, NAME), 
                               @OrgName = NAME
                        FROM Organizations
                        WHERE OrganizationId = @OrgId;
                END;
                SELECT @Pay4 = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PaymentFor=%';
                SELECT @lang = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'lang=%';
                SELECT @PayId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'PayId=%';
                SELECT @CustomsDuty = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'CustomsDuty=%';
                SELECT @HandlingCharges = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'HandlingCharges=%';
                SELECT @Storage = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Storage=%';
                SELECT @Penalties = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Penalties=%';
                SELECT @Others = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Others=%';
                SELECT @Certificates = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Certificates=%';
                SELECT @Printing = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Printing=%';
                SELECT @Guarantees = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'Guarantees=%';
                SELECT @ReceiptId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'ReceiptId=%';
                SELECT @TotalAmount = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'TotalAmount=%';
                SELECT @KGACService = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'KGACService=%';
                SELECT @GCSService = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'GCSService=%';
                SELECT @KNETAccType = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'KNETAccType=%';
                SELECT @BrPaymentTransactionId = dbo.Split(items, '=', 2)
                FROM SplitToTable(@QryStr, @Delimit)
                WHERE items LIKE 'BrPaymentTransactionId=%';
                SELECT            
                -- @OLTransId = paymentTransactionid,                            
                @OLTransId = RefByBank, 
                @PostDate = ISNULL(PostDate, GETDATE()), 
                @BankAuth = AuthByBank, 
                @UserId = PortalLoginId, 
                @OLPaymentId = OLPaymentId, 
                @TranStat = StateId            
                --@OrgId = OrganizationId                            
                FROM OnlinePaymentDetails OPD
                     INNER JOIN OnlinePaymentTokens OPT ON OPD.OPDetailId = OPT.OPDetailId
                WHERE OPT.TokenId = @TokenId;
                PRINT 'final checking';
                PRINT @TranStat;

                --CheckId = @chkId -- check id is unique id for each transaction                                
                --if @OLTransId = 0 -- check if it is zero (Track Id) as this is being called before the log initial payment details.                            
                --begin                            
                -- set @OLTransId = abs(CAST(CRYPT_GEN_RANDOM(6) AS INT))                            
                -- update OnlinePaymentDetails set PaymentTransactionId = @OLTransId where CheckId=@chkId                            
                --end                            
                SELECT @OnlineReciptNo = ReceiptNumber
                FROM Checks
                WHERE CheckId = @chkId;
                PRINT '@eServiceUserEmailId';
                PRINT @eServiceUserEmailId;
                IF(@eServiceUserEmailId IS NOT NULL)
                    BEGIN
                        SET @PaidByTypeNameCase =
                        (
                            SELECT CAST(ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '') AS NVARCHAR(50))
                            FROM etrade.mobileuser
                            WHERE emailid = @eServiceUserEmailId
                        );
                END;
                    ELSE
                    BEGIN
                        SET @PaidByTypeNameCase = CASE
                                                      WHEN @PaidBy = 'B'
                                                      THEN N'المخلص  / Broker'
                                                      ELSE N'المستفيد / Consignee'
                                                  END + N' <BR /> ' + ISNULL(@OrgNameAra, @OrgName);
                END;
                SELECT @DeclId DeclarationId, 
                       @TDeclNo TempDeclNumber, 
                       @Amt Amount, 
                       @PrtLgnId PortalLoginId
                       ,         
                       --,Case when   @eServiceUserEmailId is not null then @eServiceUserEmailId--(SELECT cast(isnull(FirstName, '') + ' ' + isnull(LastName, '') AS nVARCHAR(50)) from etrade.mobileuser where emailid=  @eServiceUserEmailId)      
                       -- else   @PrtLgnId end as  PortalLoginId       
                       @LgnPrtId LogInPortId, 
                       @OrgId OrganizationId, 
                       @Pay4 PaymentFor, 
                       RTRIM(@PaidBy) PaidByType, 
                       @lang lang, 
                       @chkId CheckId, 
                       @PayId PayId
                       ,            
                       -- abs(CAST(CRYPT_GEN_RANDOM(6) AS INT))  -- corrected to return the bank ref number for transaction                             
                       ISNULL(@OLTransId, '0') OLTransId, 
                       @CustomsDuty CustomsDuty, 
                       @HandlingCharges HandlingCharges, 
                       @Storage Storage, 
                       @Penalties Penalties, 
                       @Others Others, 
                       @Certificates Certificates, 
                       @Printing Printing, 
                       @Guarantees Guarantees, 
                       @ReceiptId ReceiptId, 
                       @TotalAmount TotalAmount, 
                       @KGACService KGACService, 
                       @GCSService GCSService, 
                       @KNETAccType KNETAccType, 
                       @BrPaymentTransactionId BrPaymentTransactionId, 
                       @PostDate PostDate, 
                       @PayeeMailId PayeeMailId
                       , -- Organization Mail Id of Broker & Consignee                             
                       @PayUserMailid PayerMailId
                       , -- Mail id used to pay through eTrade / eSolutions                             
                       ISNULL(@OrgName, '--') OrgName, 
                       ISNULL(@OrgNameAra, '--') OrgNameAra, 
                       @TDeclNo AS ReferenceNumber, 
                       @OnlineReciptNo AS ReceiptNumber
                       ,            
                       -- BELOW FIELDS ARE ADDED FOR THE KNET MAILING..... 04-04-2018                            
                       CASE
                           WHEN @Pay4 = 1
                           THEN N'رسوم جمركية <BR /> Customs Duty'
                           WHEN @PAY4 = 2
                           THEN N'الإيداع <BR /> Deposits'
                           WHEN @PAY4 = 3
                           THEN N'غرامة <BR /> Penality'
                           ELSE ''
                       END PaymentForMail, 
                       @BankAuth BankAuthNo, 
                       @UserId UserId, 
                       @UserId UserId, 
                       @chkId ReferenceId
                       ,            
                       --,CASE             
                       -- WHEN @PaidBy = 'B'            
                       --  THEN N'المخلص  / Broker'            
                       -- ELSE N'المستفيد / Consignee'            
                       -- END + N' <BR /> ' + ISNULL(@OrgNameAra, @OrgName) AS PaidByTypeName      
                       @PaidByTypeNameCase PaidByTypeName, 
                       @RedirectURL RedirectURL, 
                       N'دفع الكتروني <BR /> e-Payment ' PaymentTypeMail, 
                       @OLPaymentId PaymentId, 
                       @OnlineReciptNo OnlineReceiptNo, 
                       'Declarations' ReferenceType, 
                       @TranStat Result;
        END
    END






--Alter table [OnlinePaymentDetailsGCSReceiptsKnet]  
--add  MobileNum varchar(100),CustEmail varchar(100) ,AppSource varchar(100)  
--SELECT * FROM OnlinePaymentDetailsGCSReceiptsKnet  
ALTER PROCEDURE [dbo].[LogInitialPaymentDetailsGCSReceiptsKnet] @ReferenceId            BIGINT         = 0, 
                                                                @TranSttDateTime        DATETIME, 
                                                                @ClientIPAddress        VARCHAR(15)    = NULL, 
                                                                @SessionId              VARCHAR(100)   = NULL, 
                                                                @LogInPortId            INT            = 0, 
                                                                @Amount                 DECIMAL(18, 3)  = 0, 
                                                                @TranStatus             VARCHAR(20)    = '', 
                                                                @PortalLoginId          VARCHAR(100)   = '', 
                                                                @OrganizationId         INT            = 0, 
                                                                @PaymentFor             VARCHAR(50)    = '', 
                                                                @ReferenceNumber        VARCHAR(50)    = '', 
                                                                @ReferenceType          VARCHAR(10)    = '', 
                                                                @PaidByType             CHAR(1)        = '', 
                                                                @error                  VARCHAR(500)   = '', 
                                                                @response               VARCHAR(500)   = '', 
                                                                @TokenId                VARCHAR(50)    = '', 
                                                                @OLPaymentId            BIGINT         = 0
                                                                ,  
                                                                --,@OLTransId BIGINT = 0 --cc   
                                                                @TrackId                BIGINT         = 0
                                                                , --cc   
                                                                @ReceiptId              INT            = 0, 
                                                                @BrPaymentTransactionId INT            = 0, 
                                                                @CreatorsOwnerOrgId     INT            = 0, 
                                                                @ETokenId               BIGINT         = 0, 
                                                                @MobileNum              VARCHAR(100)   = ''
                                                                ,--cc - Siraj   
                                                                @CustEmail              VARCHAR(100)   = ''
                                                                ,--cc - Siraj   
                                                                @AppSource              VARCHAR(100)   = ''
                                                                ,--cc - Siraj   
                                                                @ErrorCode              VARCHAR(50)    = '' OUTPUT
AS
    BEGIN
        SET @ErrorCode = '';  
        --IF (  
        --      Isnull(@PaidByType, '') = 'O'  
        --      AND EXISTS (  
        --          SELECT 1  
        --          FROM dbo.OnlinePaymentDetailsGCSReceiptsKnet  
        --          WHERE ReferenceId = @ReferenceId  
        --              AND @PaymentFor = @PaymentFor  
        --              AND Isnull(PaidByType, '') = 'O'  
        --              AND StateId = 'Started'  
        --          )  
        --      ) --Transfer to consignee duplication check              
        --BEGIN  
        --  SET @ErrorCode = 'ErrEpay001' -- Payment Already Transferd to consignee               
        --END  
        --ELSE  
        BEGIN
            DECLARE @CVS INT;
            DECLARE @OnlPDetailId INT;
            DECLARE @LocationId INT;
            SELECT @LocationId = LocationId
            FROM Receipts
            WHERE ReceiptId = @ReceiptId;
            EXEC usp_MCPKCounters 
                 'OnlinePaymentDetailsGCSReceiptsKnet', 
                 1, 
                 @CVS, 
                 @OnlPDetailId OUTPUT;
            INSERT INTO dbo.OnlinePaymentDetailsGCSReceiptsKnet
            (OPDetailId, 
             ReferenceId, 
             StateId, 
             TranSttDateTime, 
             ClientIPAddress, 
             SessionId, 
             PortalLoginId, 
             Amount, 
             OrganizationId, 
             PaymentFor, 
             ReferenceNumber, 
             ReferenceType, 
             PaidByType, 
             LogInPortId, 
             error, 
             response, 
             ReceiptId, 
             DateCreated, 
             CreatedBy, 
             OLPaymentId, 
             BrPaymentTransactionId
             , -- added on 17th Jan 18 to show as                    
             OwnerOrgId, 
             OwnerLocId, 
             TrackId, 
             TokenId, 
             MobileNum, 
             CustEmail, 
             AppSource
            ) --Output Inserted.OPDetailId                          
            -- PaymentTransactionId will contain the merchant Track id.                  
            VALUES
            (@OnlPDetailId, 
             @ReferenceId, 
             @TranStatus, 
             @TranSttDateTime, 
             @ClientIPAddress, 
             @SessionId, 
             @PortalLoginId, 
             @Amount, 
             @OrganizationId, 
             @PaymentFor, 
             @ReferenceNumber, 
             @ReferenceType, 
             @PaidByType
             ,  
             --,cast(dbo.fn_GetBWHBayanBasePort(@LogInPortId) AS INT)   --cc   
             @LocationId
             ,  --cc   
             @error, 
             @response, 
             @ReceiptId, 
             GETDATE(), 
             @PortalLoginId, 
             @OLPaymentId, 
             @BrPaymentTransactionId, 
             @CreatorsOwnerOrgId
             ,  
             --,cast(dbo.fn_GetBWHBayanBasePort(@LogInPortId) AS INT)  --cc   
             @LocationId
             ,  --cc  
             --,@OLTransId      --cc     
             @TrackId
             ,  --cc   
             @ETokenId, 
             @MobileNum, 
             @CustEmail, 
             @AppSource
            ); -- added by Gh.mani as it is available.    
            -- audit trail added by azhar 07012018  
            INSERT INTO dbo.[$OnlinePaymentDetailsGCSReceiptsKnet]
            ([$AuditTrailId], 
             [$UserId], 
             [$Operation], 
             [$DateTime], 
             [$DataProfileClassId], 
             OPDetailId, 
             ReferenceId, 
             StateId, 
             TranSttDateTime, 
             ClientIPAddress, 
             SessionId, 
             PortalLoginId, 
             Amount, 
             OrganizationId, 
             PaymentFor, 
             ReferenceNumber, 
             ReferenceType, 
             PaidByType, 
             LogInPortId, 
             error, 
             response, 
             ReceiptId, 
             DateCreated, 
             CreatedBy, 
             OLPaymentId, 
             BrPaymentTransactionId
             , -- added on 17th Jan 18 to show as                    
             OwnerOrgId, 
             OwnerLocId, 
             TrackId, 
             TokenId
            ) --Output Inserted.OPDetailId                          
            -- PaymentTransactionId will contain the merchant Track id.                  
            VALUES
            (NEWID(), 
             @PortalLoginId, 
             '0', 
             GETDATE(), 
             'OnlinePaymentDetailsGCSReceiptsKnet', 
             @OnlPDetailId, 
             @ReferenceId, 
             @TranStatus, 
             @TranSttDateTime, 
             @ClientIPAddress, 
             @SessionId, 
             @PortalLoginId, 
             @Amount, 
             @OrganizationId, 
             @PaymentFor, 
             @ReferenceNumber, 
             @ReferenceType, 
             @PaidByType
             ,  
             --,cast(dbo.fn_GetBWHBayanBasePort(@LogInPortId) AS INT)  --cc     
             @LocationId
             , --cc   
             @error, 
             @response, 
             @ReceiptId, 
             GETDATE(), 
             @PortalLoginId, 
             @OLPaymentId, 
             @BrPaymentTransactionId, 
             @CreatorsOwnerOrgId
             ,  
             --,cast(dbo.fn_GetBWHBayanBasePort(@LogInPortId) AS INT)       
             @LocationId
             ,    
             --,@OLTransId         
             @TrackId, 
             @ETokenId
            );
            DECLARE @TokenValidTime INT;
            SET @TokenValidTime = 10;

/*  
        on discussion with mohan*/

            PRINT '1';
            IF @BrPaymentTransactionId > 0 -- Update Reference based on the BrPaymentTransactionId                  
                BEGIN
                    PRINT 2;
                    UPDATE OnlinePaymentTokensGCSReceiptsKnet
                      SET 
                          OPDetailId = @OnlPDetailId
                          , --@lastid         
                          ExpiryTime = DATEADD(MINUTE, @TokenValidTime, DateCreated)
                    WHERE QueryString LIKE '%~BrPaymentTransactionId=' + CONVERT(VARCHAR, @BrPaymentTransactionId) + '~%';  
                    --TokenId=@TokenId  
            END;

            --Alter table [OnlinePaymentDetailsGCSReceiptsKnet]  
            --drop column    MobileNum   
            --Alter table [OnlinePaymentDetailsGCSReceiptsKnet]  
            --add  MobileNum varchar(100),CustEmail varchar(100) ,AppSource varchar(100)  
        /*IF @ReceiptId > 0  
        BEGIN  
        Print 3  
            UPDATE OnlinePaymentTokensGCSReceiptsKnet  
            SET OPDetailId = @OnlPDetailId --@lastid        
                ,ExpiryTime = DATEAdd(MINUTE, @TokenValidTime, DateCreated)  
            WHERE QueryString LIKE '%~ReceiptId=' + convert(VARCHAR, @ReceiptId) + '~%'  
        END*/

        END;
    END;




	
ALTER PROCEDURE [dbo].[UpdatePaymentDetailsGCSReceiptsKnet] @TranStatus                         VARCHAR(20)  = '', 
                                                            @TranStpDateTime                    DATETIME     = NULL, 
                                                            @PaymentId                          BIGINT       = 0, 
                                                            @error                              VARCHAR(200) = '', 
                                                            @response                           VARCHAR(200) = '', 
                                                            @TransId                            BIGINT       = 0, 
                                                            @ReferenceId                        BIGINT       = 0, 
                                                            @result                             VARCHAR(50)  = '', 
                                                            @PostDate                           DATETIME     = NULL, 
                                                            @AuthByBank                         VARCHAR(200) = '', 
                                                            @RefByBank                          VARCHAR(200) = '', 
                                                            @PaymentFor                         CHAR(1)      = 0, 
                                                            @ReceiptId                          VARCHAR(50)  = '', 
                                                            @BrPaymentTransactionId             VARCHAR(50)  = '', 
                                                            @RcptNum                            VARCHAR(50)  = '' OUTPUT, 
                                                            @ETokenId                           BIGINT       = 0, 
                                                            @ReceiptAutoSubmitFromPaymentWizard BIT          = 0 --cc - Siraj
--,@test VARCHAR(2000) = '' OUTPUT
AS
    BEGIN
        PRINT 'entry' + @ReceiptId;
        DECLARE @Amount DECIMAL(18, 3), @ownerLocid INT, @UserId VARCHAR(50), @PaidBy CHAR(1), @PayFor CHAR(1);
        DECLARE @OwnOrgId VARCHAR(15);

        /* Start - Broker Transaction Details*/

        IF(@PaymentFor IN(3, 4))
            BEGIN
                PRINT '1';
                DECLARE @PortSites INT;
                SELECT @PortSites = OwnerLocId
                FROM Receipts
                WHERE ReceiptId = @ReceiptId;
                UPDATE dbo.OnlinePaymentDetailsGCSReceiptsKnet
                  SET 
                      OLPaymentId = @PaymentId, 
                      error = @error, 
                      response = @response, 
                      StateId = @TranStatus, 
                      TranStpDateTime = @TranStpDateTime, 
                      TransId = @TransId, 
                      result = @result, 
                      PostDate = @PostDate, 
                      AuthByBank = @AuthByBank, 
                      RefByBank = @RefByBank, 
                      DateModified = GETDATE(), 
                      TokenId = @ETokenId
                WHERE ReceiptId = @ReceiptId
                      AND BrPaymentTransactionId = @BrPaymentTransactionId
                      AND ReferenceId = @ReferenceId;
                INSERT INTO dbo.[$OnlinePaymentDetailsGCSReceiptsKnet]
                ([$AuditTrailId], 
                 [$UserId], 
                 [$Operation], 
                 [$DateTime], 
                 [$DataProfileClassId], 
                 OPDetailId, 
                 TransId, 
                 ReferenceId, 
                 StateId, 
                 TranSttDateTime, 
                 ClientIPAddress, 
                 SessionId, 
                 PortalLoginId, 
                 Amount, 
                 OrganizationId, 
                 PaymentFor, 
                 ReferenceNumber, 
                 ReferenceType, 
                 PaidByType, 
                 LogInPortId, 
                 error, 
                 response, 
                 result, 
                 PostDate, 
                 AuthByBank, 
                 DateModified, 
                 RefByBank, 
                 ReceiptId, 
                 DateCreated, 
                 CreatedBy, 
                 OLPaymentId, 
                 BrPaymentTransactionId
                 , -- added on 17th Jan 18 to show as                    
                 OwnerOrgId, 
                 OwnerLocId, 
                 TrackId, 
                 TokenId, 
                 MobileNum, 
                 CustEmail, 
                 AppSource
                ) --Output Inserted.OPDetailId                          
                       -- PaymentTransactionId will contain the merchant Track id.                  
                       SELECT NEWID(), 
                              PortalLoginId, 
                              '1', 
                              GETDATE(), 
                              'OnlinePaymentDetailsGCSReceiptsKnet', 
                              OPDetailId, 
                              @TransId, 
                              ReferenceId, 
                              @TranStatus, 
                              @TranStpDateTime, 
                              ClientIPAddress, 
                              SessionId, 
                              PortalLoginId, 
                              Amount, 
                              OrganizationId, 
                              PaymentFor, 
                              ReferenceNumber, 
                              ReferenceType, 
                              PaidByType, 
                              LogInPortId, 
                              @error, 
                              @response, 
                              @result, 
                              @PostDate, 
                              @AuthByBank, 
                              GETDATE(), 
                              @RefByBank, 
                              ReceiptId, 
                              DateCreated, 
                              CreatedBy, 
                              @PaymentId, 
                              BrPaymentTransactionId
                              , -- added on 17th Jan 18 to show as                    
                              OwnerOrgId, 
                              OwnerLocId, 
                              TrackId, 
                              TokenId, 
                              MobileNum, 
                              CustEmail, 
                              AppSource
                       FROM OnlinePaymentDetailsGCSReceiptsKnet
                       WHERE ReceiptId = @ReceiptId
                             AND BrPaymentTransactionId = @BrPaymentTransactionId
                             AND ReferenceId = @ReferenceId;
                PRINT 'OnlinePaymentDetailsGCSReceiptsKnet are updated !!!!';
                PRINT '2';
                SELECT @ownerLocid = LogInPortId, 
                       @UserId = PortalLoginId, 
                       @OwnOrgId = OrganizationId, 
                       @Amount = Amount
                FROM OnlinePaymentDetailsGCSReceiptsKnet
                WHERE ReceiptId = @ReceiptId
                      AND BrPaymentTransactionId = @BrPaymentTransactionId
                      AND ReferenceId = @ReferenceId;
                PRINT @Amount;
                DECLARE @RcptNo1 VARCHAR(50), @OwnerLCode VARCHAR(5);
                SELECT @RcptNo1 = ISNULL(ReferenceNumber, '')
                FROM BrPaymentTransactions
                WHERE ReceiptId = @ReceiptId
                      AND BrPaymentTransactionId = @BrPaymentTransactionId;
                SELECT @OwnerLCode = locationcode
                FROM Locations
                --WHERE Locationid = cast(dbo.fn_GetBWHBayanBasePort(@OwnerLocId) AS INT)--@ownerLocid    
                WHERE Locationid = @PortSites;
                IF(EXISTS
                (
                    SELECT TOP 1 1
                    FROM dbo.OnlinePaymentDetailsGCSReceiptsKnet
                    WHERE ReceiptId = @ReceiptId -- added newly
                          AND BrPaymentTransactionId = @BrPaymentTransactionId
                          AND Appsource LIKE '%-PaymentWizard%'
                ))
                    BEGIN
                        SET @ReceiptAutoSubmitFromPaymentWizard = 1;
                END;

                --  IF  (( @RcptNo1 IS not NULL OR @RcptNo1 != '') AND @ReceiptAutoSubmitFromPaymentWizard=1 )-- added newly
                --  BEGIN
                --  DELETE FROM   BrPaymentTransactions
                --        WHERE ReceiptId = @ReceiptId
                --            AND BrPaymentTransactionId = @BrPaymentTransactionId
                --SET @RcptNo1=''
                --  end

                PRINT @ReceiptId;
                PRINT @BrPaymentTransactionId;
                PRINT 'Trastatus ' + @TranStatus;
                PRINT 'RCPTNO' + @RcptNo1;
                IF((@RcptNo1 IS NULL
                    OR @RcptNo1 = '')
                   AND @TranStatus = 'Success') -- Upon Successfull payment of KNet by Broker                                                      
                    BEGIN
                        -- Generating the Receipt Number                                                      
                        DECLARE @CounterName1 VARCHAR(100), @PaymentNo1 VARCHAR(20);
                        SET @CounterName1 = @OwnerLCode + 'GCSReceiptsKnetRcptNo';
                        EXEC [dbo].[usp_MCCounters] 
                             @Counter = @CounterName1, 
                             @CounterValue = @PaymentNo1 OUTPUT;
                        SET @RcptNo1 = 'GR/' + CONVERT(VARCHAR, @PaymentNo1) + '/' + RIGHT(@OwnerLCode, 3) + RIGHT(DATEPART(year, GETDATE()), 2);
                        PRINT 'New Receipt No : ' + @RcptNo1;
                        PRINT '3';
                        DECLARE @ActualAmount DECIMAL(18, 3);

                        --SET @ActualAmount = (cast(@Amount AS DECIMAL(18, 3)) - (cast(dbo.KWConstantfn('GBL_Types.Charges.KNET') AS DECIMAL(18, 3)) + cast(dbo.KWConstantfn('GBL_Types.Charges.Online') AS DECIMAL(18, 3))))

/*		 IF(@ReceiptAutoSubmitFromPaymentWizard=1)-- Indicates that the update is from Paymentwizard.. so not considering the payment fee 
		 BEGIN
		  SET @ActualAmount=cast(@Amount AS DECIMAL(18, 3))
		 END
		 ELSE-- Existing Calculation
		 BEGIN
		 SET @ActualAmount = (cast(@Amount AS DECIMAL(18, 3)) - (cast(dbo.KWConstantfn('GBL_Types.Charges.KNET') AS DECIMAL(18, 3)) + cast(dbo.KWConstantfn('GBL_Types.Charges.Online') AS DECIMAL(18, 3))))  
		 END
 */

                        SET @ActualAmount = (CAST(@Amount AS DECIMAL(18, 3)) - (CAST(dbo.KWConstantfn('GBL_Types.Charges.KNET') AS DECIMAL(18, 3)) + CAST(dbo.KWConstantfn('GBL_Types.Charges.Online') AS DECIMAL(18, 3))));
                        PRINT @ActualAmount;
                        PRINT '4';
                        --alter table [$BrPaymentTransactions] alter column paymentid bigint   
                        INSERT INTO [BrPaymentTransactions]
                        (BrPaymentTransactionId, 
                         ReceiptId, 
                         PaymentID, 
                         PaymentType, 
                         AccountId, 
                         KNETServiceCharge, 
                         OnlineServiceCharge, 
                         ReferenceNumber, 
                         TotalAmount, 
                         DateCreated, 
                         CreatedBy, 
                         DateModified, 
                         ModifiedBy, 
                         StateId, 
                         OwnerOrgId, 
                         OwnerLocId, 
                         ReferenceId, 
                         Amount, 
                         KGACAmount, 
                         GCSAmount, 
                         PaymentAccountType
                        )
                        VALUES
                        (CAST(@BrPaymentTransactionId AS INT), 
                         @ReceiptId, 
                         @PaymentId, 
                         dbo.KWConstantfn('GBL_PaymentTypes.BANKINTEGRATION'), 
                         1275, 
                         CAST(dbo.KWConstantfn('GBL_Types.Charges.KNET') AS DECIMAL(18, 3)), 
                         CAST(dbo.KWConstantfn('GBL_Types.Charges.Online') AS DECIMAL(18, 3)), 
                         @RcptNo1, 
                         @Amount, 
                         GETDATE(), 
                         @UserId, 
                         GETDATE(), 
                         @UserId, 
                         'BrPaymentTransactionsCreatedState', 
                         @OwnOrgId, 
                         @ownerLocid, 
                         @ReferenceId, 
                         @ActualAmount,
                         CASE
                             WHEN @PaymentFor = '4'
                         --THEN @ActualAmount        
                             THEN @Amount
                             ELSE NULL
                         END,
                         CASE
                             WHEN @PaymentFor = '3'
                         --THEN @ActualAmount        
                             THEN @Amount
                             ELSE NULL
                         END,
                         CASE
                             WHEN @PaymentFor = '3'
                             THEN dbo.KWConstantfn('GBL_Types.AccountTypes.GCS')
                             ELSE dbo.KWConstantfn('GBL_Types.AccountTypes.KGAC')
                         END
                        );
                        PRINT 'BrPayment Transaction is created...';
                        INSERT INTO [$BrPaymentTransactions]
                        ([$UserId], 
                         [$Operation], 
                         [$SessionId], 
                         [$IPId], 
                         [$DateTime], 
                         [$DataProfileClassId], 
                         BrPaymentTransactionId, 
                         ReceiptId, 
                         PaymentID, 
                         PaymentType, 
                         AccountId, 
                         KNETServiceCharge, 
                         OnlineServiceCharge, 
                         ReferenceNumber, 
                         TotalAmount, 
                         DateCreated, 
                         CreatedBy, 
                         StateId, 
                         OwnerOrgId, 
                         OwnerLocId, 
                         ReferenceId, 
                         Amount, 
                         KGACAmount, 
                         GCSAmount, 
                         PaymentAccountType, 
                         [$ActionDescription]
                        )
                               SELECT 'system', 
                                      0, 
                                      NULL, 
                                      NULL, 
                                      GETDATE(), 
                                      'BrPaymentTransactions', 
                                      br.BrPaymentTransactionId, 
                                      Br.ReceiptId, 
                                      BR.PaymentID, 
                                      Br.PaymentType, 
                                      BR.AccountId, 
                                      BR.KNETServiceCharge, 
                                      Br.OnlineServiceCharge, 
                                      Br.ReferenceNumber, 
                                      BR.TotalAmount, 
                                      BR.DateCreated, 
                                      BR.CreatedBy, 
                                      BR.StateId, 
                                      BR.OwnerOrgId, 
                                      BR.OwnerLocId, 
                                      BR.ReferenceId, 
                                      Br.Amount, 
                                      BR.KGACAmount, 
                                      BR.GCSAmount, 
                                      BR.PaymentAccountType, 
                                      NULL
                               FROM BrPaymentTransactions br
                               WHERE br.BrPaymentTransactionId = @BrPaymentTransactionId;
                        DECLARE @sTransId VARCHAR(150);
                        SELECT @sTransId = COALESCE(@sTransId + ',', '') + CONVERT(VARCHAR, TransId)
                        FROM OnlinePaymentDetailsGCSReceiptsKnet
                        WHERE ReceiptId = @ReceiptId
                              AND BrPaymentTransactionId = @BrPaymentTransactionId
                              AND ReferenceId = @ReferenceId;
                        UPDATE R
                        --SET Balance = Balance - @ActualAmount    
                          SET 
                              Balance = CASE
                                            WHEN ISNULL((Balance - @ActualAmount), 0) > 0.000
                                            THEN(Balance - @ActualAmount)
                                            ELSE 0.000
                                        END, 
                              ChqNo = @sTransId, 
                              PaymentMethod = dbo.KWConstantfn('GBL_PaymentTypes.BANKINTEGRATION'), 
                              KGACAmount = CASE
                                               WHEN @PaymentFor = 4
                                           --THEN (ISNULL(KGACAmount, 0.000) + ISNULL(@ActualAmount, 0.000))        
                                           --THEN (ISNULL(KGACAmount, 0.000) + ISNULL(@Amount, 0.000))
                                               THEN(ISNULL(@ActualAmount, 0.000))
                                               ELSE R.KGACAmount
                                           END, 
                              GCSAmount = CASE
                                              WHEN @PaymentFor = 3
                                          --THEN (ISNULL(GCSAmount, 0.000) + ISNULL(@ActualAmount, 0.000))        
                                          --THEN (ISNULL(GCSAmount, 0.000) + ISNULL(@Amount, 0.000))
                                              THEN(ISNULL(@ActualAmount, 0.000))
                                              ELSE R.GCSAmount
                                          END, 
                              Amount = @ActualAmount --@Amount
                        FROM Receipts R
                        WHERE R.ReceiptId = @ReceiptId;
                        DECLARE @ReferenceType CHAR(1);
                        DECLARE @ReferenceNo VARCHAR(20);
                        DECLARE @ReceiptFor INT;
                        SELECT @ReferenceType = RefType, 
                               @ReferenceNo = ReferenceNumber, 
                               @ReceiptFor = ReceiptFor, 
                               @PortSites = PortSites
                        FROM Receipts
                        WHERE ReceiptId = @ReceiptId;

                        /** Commented on 30Aug2018 based on GCS want to remove the integrations fees(0.210) from receipt details*/
/*EXEC usp_AutoInsertKNETPaymentServices @ReferenceId
                ,@ReceiptId
                ,@PortSites
                ,@ReferenceType
                ,@ReferenceNo
                ,@ReceiptFor*/

                        INSERT INTO [$REceipts]
                        ([$UserId], 
                         [$Operation], 
                         [$DateTime], 
                         [$DataProfileClassId], 
                         ReceiptId, 
                         ReceiptNumber, 
                         ReceiptDate, 
                         OrganizationId, 
                         LocationId, 
                         Amount, 
                         Remarks, 
                         CreatedBy, 
                         DateCreated, 
                         ModifiedBy, 
                         DateModified, 
                         OwnerLocId, 
                         StateId, 
                         OwnerOrgId, 
                         ChqNo, 
                         ChqDate, 
                         BankId, 
                         ReceivedFrom, 
                         PayeeType, 
                         PayeeTypeId, 
                         ReceiptFor, 
                         PortSites, 
                         ReceiptCreatedDate, 
                         PrintCount, 
                         RePrintReasonId, 
                         PaymentMethod, 
                         CurrencyId, 
                         ExchangeRate, 
                         AmountInKD, 
                         [$IPId], 
                         [$SessionId], 
                         SubmittedDate, 
                         ReferenceId, 
                         Balance, 
                         KGACAmount, 
                         GCSAmount, 
                         TempReceiptNumber, 
                         RefType, 
                         ReferenceNumber, 
                         MobileNum, 
                         CustEmail
                        )
                               SELECT 'system', 
                                      '1', 
                                      GETDATE(), 
                                      'BrReceipts', 
                                      R.ReceiptId, 
                                      R.ReceiptNumber, 
                                      R.ReceiptDate, 
                                      R.OrganizationId, 
                                      R.LocationId, 
                                      R.Amount, 
                                      R.Remarks, 
                                      R.CreatedBy, 
                                      R.DateCreated, 
                                      R.ModifiedBy, 
                                      R.DateModified, 
                                      R.OwnerLocId, 
                                      R.StateId, 
                                      R.OwnerOrgId, 
                                      R.ChqNo, 
                                      R.ChqDate, 
                                      R.BankId, 
                                      R.ReceivedFrom, 
                                      R.PayeeType, 
                                      R.PayeeTypeId, 
                                      R.ReceiptFor, 
                                      R.PortSites, 
                                      R.ReceiptCreatedDate, 
                                      R.PrintCount, 
                                      R.RePrintReasonId, 
                                      R.PaymentMethod, 
                                      R.CurrencyId, 
                                      R.ExchangeRate, 
                                      R.AmountInKD, 
                                      '127.0.0.1', 
                                      NULL, 
                                      R.SubmittedDate, 
                                      R.ReferenceId, 
                                      R.Balance, 
                                      R.KGACAmount, 
                                      R.GCSAmount, 
                                      R.TempReceiptNumber, 
                                      R.RefType, 
                                      R.ReferenceNumber, 
                                      MobileNum, 
                                      CustEmail
                               FROM Receipts R
                               WHERE ReceiptId = @ReceiptId;
                        PRINT 'Receipt No ' + @RcptNo1 + ' generated successfully !!!';

                        --============
                        --set @test='==== @ReceiptAutoSubmitFromPaymentWizard start'
                        /* start AutoSubmit Receipts for 3 step payment*/

                        --DECLARE @AppSource nvarchar(100)='' -- assign value only when its a auto submit receipt , so that TDR number will be used as Online recipt number instead of GR****
                        IF(@ReceiptAutoSubmitFromPaymentWizard = 1)
                            BEGIN
                                --SET @AppSource='OpenPayment'
                                --set @test='=== @ReceiptAutoSubmitFromPaymentWizard true' +CONVERT(varchar(100), @ReceiptId)
                                PRINT '@ReceiptAutoSubmitFromPaymentWizard';
                                --SELECT TOP 10 * FROM Receipts
                                DECLARE @sCounterType VARCHAR(10), @sCounterPrefix VARCHAR(50), @OwnerLocCode VARCHAR(250), -- @Locationid bigint,
                                @CounterName VARCHAR(250), @NewRcptNo VARCHAR(100), @ReceiptNumber VARCHAR(100);
                                PRINT @ReceiptFor;
                                --set @test='=== @ReceiptAutoSubmitFromPaymentWizard @ReceiptFor' +CONVERT(varchar(100), @ReceiptFor)
                                SET @sCounterType = CASE
                                                        WHEN @ReceiptFor = 30
                                                        THEN 'E'
                                                        ELSE ''
                                                    END; -- E-EXPORT ,  FOR IMPORT AND OTHERS THERE IS NO COUNTER TYPE 
                                SET @sCounterPrefix = CASE
                                                          WHEN @ReceiptFor = 30
                                                          THEN 'ERC/'
                                                          ELSE 'IRC/'
                                                      END;
                                SELECT @OwnerLocCode = RIGHT(LocationCode, 3)
                                FROM Locations
                                WHERE Locationid = @ownerLocid;--  @Locationid
                                SET @CounterName = RTRIM('GeG' + @OwnerLocCode + @sCounterType) + 'ReceiptCount';
                                EXEC [dbo].[usp_MCCounters] 
                                     @Counter = @CounterName, 
                                     @CounterValue = @NewRcptNo OUTPUT;
                                SET @ReceiptNumber = @sCounterPrefix + CONVERT(VARCHAR, @NewRcptNo) + '/e' + @OwnerLocCode + RIGHT(YEAR(GETDATE()), 2); --(YEAR(GETDATE()) % 100)
                                --sp_helptext usp_MCCounters GCSReceiptsKnetRcptNo
                                --select *
                                --from Counters     
                                --where Counters.Name like '%ReceiptCount%' --'%GCSReceiptsKnetRcptNo%'    
                                -- select * from Receipts where StateId like '%submi%' --ReceiptSubmittedState
                                --BrReceiptSubmittedState
                                PRINT 'NXT ====' + @ReceiptNumber + ' = ==== = ' + @ReceiptId;
                                --NXT ====IRC/1/eKWI18 = ==== = 13431050
                                --set @test='=== @ReceiptAutoSubmitFromPaymentWizard '+' NXT ===='+ CONVERT(varchar, @ReceiptNumber) +' = ==== = '+ CONVERT(varchar, @ReceiptId)
                                DECLARE @Datetime DATETIME= GETDATE();
                                UPDATE REceipts
                                  SET 
                                      StateId = 'ReceiptSubmittedState', 
                                      ReceiptNumber = @ReceiptNumber, 
                                      SubmittedDate = @Datetime, 
                                      DateCreated = @Datetime, 
                                      ReceiptDate = CONVERT(DATE, @Datetime), 
                                      DateModified = @Datetime
                                WHERE ReceiptId = @ReceiptId;

                                --set @test='=== @ReceiptAutoSubmitFromPaymentWizard after update'

                                INSERT INTO [$REceipts]
                                ([$UserId], 
                                 [$Operation], 
                                 [$DateTime], 
                                 [$DataProfileClassId], 
                                 ReceiptId, 
                                 ReceiptNumber, 
                                 ReceiptDate, 
                                 OrganizationId, 
                                 LocationId, 
                                 Amount, 
                                 Remarks, 
                                 CreatedBy, 
                                 DateCreated, 
                                 ModifiedBy, 
                                 DateModified, 
                                 OwnerLocId, 
                                 StateId, 
                                 OwnerOrgId, 
                                 ChqNo, 
                                 ChqDate, 
                                 BankId, 
                                 ReceivedFrom, 
                                 PayeeType, 
                                 PayeeTypeId, 
                                 ReceiptFor, 
                                 PortSites, 
                                 ReceiptCreatedDate, 
                                 PrintCount, 
                                 RePrintReasonId, 
                                 PaymentMethod, 
                                 CurrencyId, 
                                 ExchangeRate, 
                                 AmountInKD, 
                                 [$IPId], 
                                 [$SessionId], 
                                 SubmittedDate, 
                                 ReferenceId, 
                                 Balance, 
                                 KGACAmount, 
                                 GCSAmount, 
                                 TempReceiptNumber, 
                                 RefType, 
                                 ReferenceNumber, 
                                 MobileNum, 
                                 CustEmail
                                )
                                       SELECT 'system', 
                                              '1', 
                                              GETDATE(), 
                                              'BrReceipts', 
                                              R.ReceiptId, 
                                              R.ReceiptNumber, 
                                              R.ReceiptDate, 
                                              R.OrganizationId, 
                                              R.LocationId, 
                                              R.Amount, 
                                              R.Remarks, 
                                              R.CreatedBy, 
                                              R.DateCreated, 
                                              R.ModifiedBy, 
                                              R.DateModified, 
                                              R.OwnerLocId, 
                                              R.StateId, 
                                              R.OwnerOrgId, 
                                              R.ChqNo, 
                                              R.ChqDate, 
                                              R.BankId, 
                                              R.ReceivedFrom, 
                                              R.PayeeType, 
                                              R.PayeeTypeId, 
                                              R.ReceiptFor, 
                                              R.PortSites, 
                                              R.ReceiptCreatedDate, 
                                              R.PrintCount, 
                                              R.RePrintReasonId, 
                                              R.PaymentMethod, 
                                              R.CurrencyId, 
                                              R.ExchangeRate, 
                                              R.AmountInKD, 
                                              '127.0.0.1', 
                                              NULL, 
                                              R.SubmittedDate, 
                                              R.ReferenceId, 
                                              R.Balance, 
                                              R.KGACAmount, 
                                              R.GCSAmount, 
                                              R.TempReceiptNumber, 
                                              R.RefType, 
                                              R.ReferenceNumber, 
                                              R.MobileNum, 
                                              R.CustEmail
                                       FROM Receipts R
                                       WHERE ReceiptId = @ReceiptId;
                                --set @test='=== @ReceiptAutoSubmitFromPaymentWizard after insert'
                                --print @test
                        END;

                        /* end AutoSubmit Receipts for 3 step payment*/

                        --=============
                        PRINT 'gonna send mail';
                        PRINT @UserId;
                        SET @RcptNum = @RcptNo1;
                        DECLARE @ToEmailId VARCHAR(500)= '';
                        -- SET @ToEmailId = 'mkaliappan@agility.com, jprincily@agility.com, shahmad@agility.com, welbastawisi@agility.com'
                        SELECT @ToEmailId = email
                        FROM Contacts
                        WHERE parentid =
                        (
                            SELECT personalid
                            FROM Users
                            WHERE Userid = @UserId
                        );
                        IF(@ToEmailId NOT LIKE '%@%')
                            BEGIN
                                PRINT 'invalid mail' + @ToEmailId;
                                DECLARE @OrganizationId INT, @ReceivedFromUserId VARCHAR(200);
                                SELECT @OrganizationId = OrganizationId
                                FROM Receipts
                                WHERE ReceiptId = @ReceiptId;
                                SELECT @ReceivedFromUserId = ReceivedFrom
                                FROM Receipts
                                WHERE ReceiptId = @ReceiptId;
                                PRINT @ReceiptId;
                                PRINT @OrganizationId;
                                PRINT @ReceivedFromUserId;
                                IF(@OrganizationId IS NOT NULL)
                                    BEGIN
                                        SELECT @ToEmailId = Contacts.Email
                                        FROM Organizations
                                             INNER JOIN Contacts ON Organizations.OrganizationId = Contacts.ParentId
                                        WHERE contacts.ParentId = @OrganizationId;
                                        PRINT 'mail from @OrganizationId' + @ToEmailId;
                                END;
                                    ELSE
                                    BEGIN
                                        PRINT 'mail from receivedfrom' + @ToEmailId;
                                        SELECT @ToEmailId = CONT.EMail--,CONT.ParentType,*
                                        FROM People PE
                                             LEFT OUTER JOIN Contacts CONT ON CONT.ParentId = PE.PersonalId -- and  CONT.ParentType !=null
                                             INNER JOIN Users u ON u.PersonalId = CONT.ParentId
                                        WHERE U.USERID = @ReceivedFromUserId;
                                END;
                        END;
                        DECLARE @PaymentFormEmailId VARCHAR(500)= '';

                        --     IF (@ToEmailId NOT LIKE '%@%')
                        --BEGIN
                        SELECT @PaymentFormEmailId = CustEmail
                        FROM Receipts
                        WHERE ReceiptId = @ReceiptId;
                        PRINT 'mail from CUSTEMAIL RECEIPT' + @ToEmailId;
                        --end

                        PRINT 'final email ' + @ToEmailId;
                        IF(@ToEmailId IS NOT NULL
                           OR @PaymentFormEmailId IS NOT NULL)--@ToEmailId NOT LIKE '%@%')
                            BEGIN
                                INSERT INTO [KGACEmailOutSyncQueue]
                                ([Sync], 
                                 [MsgType], 
                                 [UserId], 
                                 [TOEmailAddress], 
                                 [CCEmailAddress], 
                                 [BCCEmailAddress], 
                                 [SampleRequestNo], 
                                 [DateCreated], 
                                 [DateModified], 
                                 [Status], 
                                 [MailPriority]
                                --,AppSource
                                )
                                VALUES
                                (0, 
                                 'GCSPaymentSuccess', 
                                 @UserId, 
                                 ISNULL(@ToEmailId, '') + ', ' + ISNULL(@PaymentFormEmailId, ''), 
                                 '', 
                                 '', 
                                 @BrPaymentTransactionId, 
                                 GETDATE(), 
                                 GETDATE(), 
                                 'Created', 
                                 'Normal'
                                --,@AppSource
                                );
                        END;
                        RETURN;
                END;
        END;

        /* End - Broker Transaction Details*/

    END;







	
ALTER PROCEDURE [dbo].[UpdatePaymentDetailsGCSReceiptsKnetCanceledOrFailed] @TranStatus             VARCHAR(20)  = '', 
                                                                            @TranStpDateTime        DATETIME     = NULL, 
                                                                            @PaymentId              BIGINT       = 0, 
                                                                            @error                  VARCHAR(200) = '', 
                                                                            @response               VARCHAR(200) = '', 
                                                                            @TransId                BIGINT       = 0, 
                                                                            @ReferenceId            BIGINT       = 0
                                                                            ,  
                                                                            --,@ReferenceNumber VARCHAR(50) = ''     
                                                                            --,@ReferenceType VARCHAR(10) = ''          
                                                                            @result                 VARCHAR(50)  = '', 
                                                                            @PostDate               DATETIME     = NULL, 
                                                                            @AuthByBank             VARCHAR(200) = '', 
                                                                            @RefByBank              VARCHAR(200) = '', 
                                                                            @PaymentFor             CHAR(1)      = 0, 
                                                                            @ReceiptId              VARCHAR(50)  = '', 
                                                                            @BrPaymentTransactionId VARCHAR(50)  = ''
                                                                            ,  
                                                                            -- ,@RcptNum VARCHAR(50) = '' OUTPUT      
                                                                            @ETokenId               BIGINT       = 0
AS
    BEGIN
        UPDATE OnlinePaymentDetailsGCSReceiptsKnet
          SET 
              OLPaymentId = @PaymentId, 
              error = @error, 
              response = @response, 
              StateId = @TranStatus, 
              TranStpDateTime = @TranStpDateTime, 
              TransId = @TransId, 
              result = @result, 
              PostDate = @PostDate, 
              AuthByBank = @AuthByBank, 
              RefByBank = @RefByBank, 
              TokenId = @ETokenId
        WHERE BrPaymentTransactionId = @BrPaymentTransactionId
              AND ReferenceId = @ReferenceId
              AND StateId != 'Success';
        DECLARE @ToEmailId VARCHAR(500), @UserId VARCHAR(50);
        SELECT @UserId = PortalLoginId
        FROM OnlinePaymentDetailsGCSReceiptsKnet
        WHERE BrPaymentTransactionId = @BrPaymentTransactionId
              AND ReferenceId = @ReferenceId
              AND StateId != 'Success';
        SELECT @ToEmailId = email
        FROM Contacts
        WHERE parentid =
        (
            SELECT personalid
            FROM Users
            WHERE Userid = @UserId
        );  
        -- SET @ToEmailId = 'mkaliappan@agility.com, jprincily@agility.com, shahmad@agility.com, WElbastawisi@agility.com'  

        IF(@ToEmailId LIKE '%@%')
            BEGIN
                IF(@TranStatus = 'Failed')
                    BEGIN
                        INSERT INTO [KGACEmailOutSyncQueue]
                        ([Sync], 
                         [MsgType], 
                         [UserId], 
                         [TOEmailAddress], 
                         [CCEmailAddress], 
                         [BCCEmailAddress], 
                         [SampleRequestNo], 
                         [DateCreated], 
                         [DateModified], 
                         [Status]
                        )
                        VALUES
                        (0, 
                         'GCSPaymentFailure', 
                         @UserId, 
                         @ToEmailId, 
                         '', 
                         '', 
                         @BrPaymentTransactionId, 
                         GETDATE(), 
                         GETDATE(), 
                         'Created'
                        );
                END;
                    ELSE
                    IF(@TranStatus = 'Cancelled')
                        BEGIN
                            INSERT INTO [KGACEmailOutSyncQueue]
                            ([Sync], 
                             [MsgType], 
                             [UserId], 
                             [TOEmailAddress], 
                             [CCEmailAddress], 
                             [BCCEmailAddress], 
                             [SampleRequestNo], 
                             [DateCreated], 
                             [DateModified], 
                             [Status], 
                             [MailPriority]
                            )
                            VALUES
                            (0, 
                             'GCSPaymentCancelled', 
                             @UserId, 
                             @ToEmailId, 
                             '', 
                             'gmani@agility.com', 
                             @BrPaymentTransactionId, 
                             GETDATE(), 
                             GETDATE(), 
                             'Created', 
                             'Normal'
                            );
                    END;
        END;

        -- audit trails done by azhar  
        INSERT INTO dbo.[$OnlinePaymentDetailsGCSReceiptsKnet]
        ([$AuditTrailId], 
         [$UserId], 
         [$Operation], 
         [$DateTime], 
         [$DataProfileClassId], 
         OPDetailId, 
         TransId, 
         ReferenceId, 
         StateId, 
         TranSttDateTime, 
         ClientIPAddress, 
         SessionId, 
         PortalLoginId, 
         Amount, 
         OrganizationId, 
         PaymentFor, 
         ReferenceNumber, 
         ReferenceType, 
         PaidByType, 
         LogInPortId, 
         error, 
         response, 
         result, 
         PostDate, 
         AuthByBank, 
         DateModified, 
         RefByBank, 
         ReceiptId, 
         DateCreated, 
         CreatedBy, 
         OLPaymentId, 
         BrPaymentTransactionId
         , -- added on 17th Jan 18 to show as                    
         OwnerOrgId, 
         OwnerLocId, 
         TrackId, 
         TokenId
        ) --Output Inserted.OPDetailId                          
               -- PaymentTransactionId will contain the merchant Track id.                  
               SELECT NEWID(), 
                      PortalLoginId, 
                      '1', 
                      GETDATE(), 
                      'OnlinePaymentDetailsGCSReceiptsKnet', 
                      OPDetailId, 
                      @TransId, 
                      ReferenceId, 
                      @TranStatus, 
                      @TranStpDateTime, 
                      ClientIPAddress, 
                      SessionId, 
                      PortalLoginId, 
                      Amount, 
                      OrganizationId, 
                      PaymentFor, 
                      ReferenceNumber, 
                      ReferenceType, 
                      PaidByType, 
                      LogInPortId, 
                      @error, 
                      @response, 
                      @result, 
                      @PostDate, 
                      @AuthByBank, 
                      GETDATE(), 
                      @RefByBank, 
                      ReceiptId, 
                      DateCreated, 
                      CreatedBy, 
                      @PaymentId, 
                      BrPaymentTransactionId
                      , -- added on 17th Jan 18 to show as                    
                      OwnerOrgId, 
                      OwnerLocId, 
                      TrackId, 
                      TokenId
               FROM OnlinePaymentDetailsGCSReceiptsKnet
               WHERE BrPaymentTransactionId = @BrPaymentTransactionId
                     AND ReferenceId = @ReferenceId;
    END