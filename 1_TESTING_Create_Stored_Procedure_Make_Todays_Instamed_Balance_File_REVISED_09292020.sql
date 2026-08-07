USE [SMS]
GO

/****** Object:  StoredProcedure [dbo].[sp_Todays_Instamed_Balance_File]    Script Date: 8/17/2020 2:51:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Author:  Mathesie, Scott>
-- Create date: <August 17, 2020>
-- Description:	<Creates a Table Containing Todays Changed Patient Balances To Instamed for the Patient Online Payment Portal
-- =============================================


--CREATE PROCEDURE sp_Todays_Instamed_Balance_File


--AS


SET NOCOUNT ON;

IF OBJECT_ID('tempdb.dbo.#Todays_Pt_Balances_1', 'U') IS NOT NULL
  DROP TABLE [#Todays_Pt_Balances_1]; 
GO

CREATE TABLE dbo.[#Todays_Pt_Balances_1]
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[Pt_No] CHAR(12) NOT NULL,
[PA-PT-BAL] MONEY NULL
);

INSERT INTO DBO.[#Todays_Pt_Balances_1]([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[Pt_No],[pa-pt-bal])

SELECT [PA-PT-NO-WOSCD],
[pa-pt-no-scd-1],
cast([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
[pa-bal-pt-bal]



FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] 

WHERE [pa-dunning-msg-lvl] >= '1'
and [pa-bal-pt-bal] >= '0'

UNION

SELECT [pa-pt-no-woscd],
[pa-pt-no-scd-1],
CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'Pt_No',
[pa-bal-pt-bal]

FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics]

WHERE [pa-dunning-msg-lvl] ='0'
and [pa-bal-pt-bal] >= '0'
AND [pa-pt-no-woscd] IN

(
SELECT DISTINCT([pa-pt-no-woscd]) 
FROM [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[DetailInformation]
WHERE [pa-dtl-chg-amt] <> '0'
AND [pa-dtl-gl-no] IN ('102','257','258')
AND [pa-dtl-post-date] = DATEADD(day, -1, convert(date, GETDATE()))
)



;


GO


/*Create Temp Table [#Todays_Changed_Pt_Bal_Encounters]*/


IF OBJECT_ID('tempdb.dbo.#Todays_Changed_Pt_Bal_Encounters_1', 'U') IS NOT NULL
  DROP TABLE [#Todays_Changed_Pt_Bal_Encounters_1]; 
GO

CREATE TABLE dbo.[#Todays_Changed_Pt_Bal_Encounters_1]
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[Pt_No] CHAR(12) NOT NULL,
[PA-PT-BAL] MONEY NULL
);

INSERT INTO DBO.[#Todays_Changed_Pt_Bal_Encounters_1]([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[Pt_No],[pa-pt-bal])




(SELECT *
FROM [SMS].dbo.[Yesterdays_Pt_Balances_1] 

EXCEPT

SELECT *  FROM [#Todays_Pt_Balances_1])



UNION


(SELECT *  FROM [#Todays_Pt_Balances_1]




EXCEPT

SELECT *  FROM [SMS].dbo.[Yesterdays_Pt_Balances_1])



;

GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



IF OBJECT_ID('tempdb.dbo.#Todays_Changed_Pt_Bal_Encounters_Grouped_1', 'U') IS NOT NULL
  DROP TABLE [#Todays_Changed_Pt_Bal_Encounters_Grouped_1]; 
GO

SELECT [pa-pt-no-woscd],
[Pt_No]

INTO [#Todays_Changed_Pt_Bal_Encounters_Grouped_1]

FROM [#Todays_Changed_Pt_Bal_Encounters_1]

GROUP BY [pa-pt-no-woscd],[pt_no]
;

GO

IF OBJECT_ID('SMS.dbo.Todays_Instamed_Balance_File_1', 'U') IS NOT NULL
DROP TABLE [SMS].dbo.[Todays_Instamed_Balance_File_1];
GO

CREATE TABLE [SMS].dbo.[Todays_Instamed_Balance_File_1]

(
[RecordID] CHAR(10) NOT NULL,
[PatientAccountNumber] CHAR(12) NOT NULL,
[PatientLastName] CHAR(30) NULL,
[PatientFirstName] CHAR(30) NULL,
[PatientMiddleName] CHAR(30) NULL,
[PatientPrefix] CHAR(3) NULL,
[PatientSuffix] CHAR(30) NULL,
[PatientDateOfBirth] CHAR(10) NULL,
[PatientGender] CHAR(1) NULL,
[PatientStreet1] CHAR(30) NULL,
[PatientStreet2] CHAR(30) NULL,
[PatientCity] CHAR(30) NULL,
[PatientState] CHAR(30) NULL,
[PatientZip1] CHAR(5) NULL,
[PatientZip2] CHAR(4) NULL,
[PatientPhoneNumber] CHAR(15) NULL,
[InsuranceRank] CHAR(1) NULL,
[InsuranceName] CHAR(1) NULL,
[InsuranceIDQualifier] CHAR(1) NULL,
[InsuranceID] CHAR(1) NULL ,
[InsuranceType] CHAR(1) NULL,
[InsuranceFilingIndicator] CHAR(1) NULL,
[InsuranceStreet1] CHAR(1) NULL,
[InsuranceStreet2] CHAR(1) NULL,
[InsuranceCity] CHAR(1) NULL,
[InsuranceState] CHAR(1) NULL,
[GroupID] CHAR(1) NULL,
[InsuranceZip] CHAR(1) NULL,
[InsurancePhoneNumber] CHAR(1) NULL,
[RelationshipToPatient] CHAR(1) NULL,
[PolicyNumber] CHAR(1) NULL,
[GroupNumber] CHAR(1) NULL,
[SubscriberLastName] CHAR(1) NULL,
[SubscriberFirstName] CHAR(1) NULL,
[SubscriberMiddleName] CHAR(1) NULL,
[SubscriberPrefix] CHAR(1) NULL,
[SubscriberSuffix] CHAR(1) NULL,
[SubscriberDateOfBirth] CHAR(1) NULL,
[SubscriberGender] CHAR(1) NULL,
[SubscriberStreet1] CHAR(1) NULL,
[SubscriberStreet2] CHAR(1) NULL,
[SubscriberCity] CHAR(1) NULL,
[SubscriberState] CHAR(1) NULL,
[SubscriberZip1] CHAR(1) NULL,
[SubscriberZip2] CHAR(1) NULL,
[SubscriberPhoneNumber] CHAR(1) NULL,
[Active Flag] CHAR(1) NULL,
[PatientBalanceDue] MONEY NULL,
[PatientBalanceDueEffectiveDate] CHAR(10) NULL,
[MedicalRecordNumber] CHAR(12) NULL,
[PatientEmailAddress] CHAR(1) NULL,
[GuarantorID] CHAR(1) NULL,
[GuarantorFirstName] CHAR(1) NULL,
[GuarantorLastName] CHAR(1) NULL,
[AdditionalField6] CHAR(1) NULL,
[AdditionalField7] CHAR(1) NULL,
[AdditionalField8] CHAR(1) NULL,
[AdditionalField9] CHAR(1) NULL,
[AdditionalField10] CHAR(1) NULL,
[RecipientFirstName] CHAR(1) NULL,
[RecipientLastName] CHAR(1) NULL,
[RecipientMiddleName] CHAR(1) NULL,
[RecipientStreet1] CHAR(1) NULL,
[RecipientStreet2] CHAR(1) NULL,
[Recipient City] CHAR(1) NULL,
[RecipientState] CHAR(1) NULL,
[RecipientZip1] CHAR(1) NULL,
[RecipientZip2] CHAR(1) NULL,
[GuarantorID2] CHAR(1) NULL,
[GuarantorFirstName2] CHAR(1) NULL,
[GuarantorLastName2] CHAR(1) NULL,
[MasterPatientAccountID] CHAR(1) NULL
);

INSERT INTO [SMS].DBO.[Todays_Instamed_Balance_File_1]([RecordID],[PatientAccountNumber],[PatientLastName],[PatientFirstName],[PatientMiddleName],[PatientPrefix],[PatientSuffix],[PatientDateOfBirth],[PatientGender],[PatientStreet1],[PatientStreet2],[PatientCity],[PatientState],
[PatientZip1],[PatientZip2],[PatientPhoneNumber],[InsuranceRank],[InsuranceName],[InsuranceIDQualifier],[InsuranceID],[InsuranceType],[InsuranceFilingIndicator],[InsuranceStreet1],[InsuranceStreet2],[InsuranceCity],[InsuranceState],[GroupID],
[InsuranceZip],[InsurancePhoneNumber],[RelationshipToPatient],[PolicyNumber],[GroupNumber],[SubscriberLastName],[SubscriberFirstName],[SubscriberMiddleName],[SubscriberPrefix],[SubscriberSuffix],[SubscriberDateOfBirth],[SubscriberGender],[SubscriberStreet1],
[SubscriberStreet2],[SubscriberCity],[SubscriberState],[SubscriberZip1],[SubscriberZip2],[SubscriberPhoneNumber],[Active Flag],[PatientBalanceDue],[PatientBalanceDueEffectiveDate],[MedicalRecordNumber],[PatientEmailAddress],[GuarantorID],[GuarantorFirstName],
[GuarantorLastName],[AdditionalField6],[AdditionalField7],[AdditionalField8],[AdditionalField9],[AdditionalField10],[RecipientFirstName],[RecipientLastName],[RecipientMiddleName],[RecipientStreet1],[RecipientStreet2],[Recipient City],[RecipientState],
[RecipientZip1],[RecipientZip2],[GuarantorID2],[GuarantorFirstName2],[GuarantorLastName2],[MasterPatientAccountID])



SELECT 'IMPAT11' as 'RecordID',
LTRIM(RTRIM(a.[Pt_No])) as 'PatientAccountNumber',
LTRIM(RTRIM(COALESCE(c.[pa-nad-last-or-orgz-name],e.[pa-nad-last-or-orgz-name]))) as 'PatientLastName',
LTRIM(RTRIM(COALESCE(c.[pa-nad-first-or-orgz-cntc],e.[pa-nad-first-or-orgz-cntc]))) as 'PatientFirstName',
LTRIM(RTRIM(COALESCE(c.[pa-nad-mi-name],e.[pa-nad-mi-name]))) 'PatientMiddleName',
'' as 'PatientPrefix',
LTRIM(RTRIM(COALESCE(c.[pa-nad-sfx-last-name],e.[pa-nad-sfx-last-name]))) as 'PatientSuffix',
LTRIM(RTRIM(convert(varchar, COALESCE(b.[pa-birth-date],d.[pa-birth-date]), 112))) as 'PatientDateOfBirth',
'' as 'PatientGender',
'' as 'PatientStreet1',
'' as 'PatientStreet2',
'' as 'PatientCity',
'' as 'PatientState',
'' as 'PatientZip1',
'' as 'PatientZip2',
'' as 'PatientPhoneNumber',
'' 'InsuranceRank',
'' as 'InsuranceName',
'' as 'InsuranceIDQualifier',
''  as 'InsuranceID' ,
'' as 'InsuranceType',
'' as 'InsuranceFilingIndicator',
'' as 'InsuranceStreet1',
'' as 'InsuranceStreet2',
'' as 'InsuranceCity',
'' as 'InsuranceState',
'' as 'GroupID',
'' as 'InsuranceZip',
'' as 'InsurancePhoneNumber',
'' as 'RelationshipToPatient',
'' as 'PolicyNumber',
'' as 'GroupNumber',
'' as 'SubscriberLastName',
'' as 'SubscriberFirstName',
'' as 'SubscriberMiddleName',
'' as 'SubscriberPrefix',
'' as 'SubscriberSuffix',
'' as 'SubscriberDateOfBirth',
'' as 'SubscriberGender',
'' as 'SubscriberStreet1',
'' as 'SubscriberStreet2',
'' as 'SubscriberCity',
'' as 'SubscriberState',
'' as 'SubscriberZip1',
'' as 'SubscriberZip2',
'' as 'SubscriberPhoneNumber',
'' as 'Active Flag',
LTRIM(RTRIM(COALESCE(b.[pa-bal-pt-bal],d.[pa-bal-pt-bal]))) as 'PatientBalanceDue',
LTRIM(RTRIM(CONVERT(varchar,getdate(),112))) as 'PatientBalanceDueEffective Date',
LTRIM(RTRIM(COALESCE(b.[pa-med-rec-no],d.[pa-med-rec-no]))) as 'MedicalRecordNumber',
'' as 'PatientEmailAddress',
'' as 'GuarantorID',
'' as 'GuarantorFirstName',
'' as 'GuarantorLastName',
'' as 'AdditionalField6',
'' as 'AdditionalField7',
'' as 'AdditionalField8',
'' as 'AdditionalField9',
'' as 'AdditionalField10',
'' as 'RecipientFirstName',
'' as 'RecipientLastName',
'' as 'RecipientMiddleName',
'' as 'RecipientStreet1',
'' as 'RecipientStreet2',
'' as 'Recipient City',
'' as 'RecipientState',
'' as 'RecipientZip1',
'' as 'RecipientZip2',
'' as 'GuarantorID2',
'' as 'GuarantorFirstName2',
'' as 'GuarantorLastName2',
'' as 'MasterPatientAccountID'






FROM [#Todays_Changed_Pt_Bal_Encounters_Grouped_1] a left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[PatientDemographics] b 
ON a.[pa-pt-no-woscd] = b.[pa-pt-no-woscd]
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Active].dbo.[NADInformation] c
ON a.[pa-pt-no-woscd] = c.[pa-pt-no-woscd] and c.[pa-nad-cd] = 'PTADD'
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[PatientDemographics] d
ON a.[pa-pt-no-woscd] = d.[pa-pt-no-woscd]
left outer join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_Archive].dbo.[NADInformation] e
ON a.[pa-pt-no-woscd] = e.[pa-pt-no-woscd] and e.[pa-nad-cd] = 'PTADD'


--SELECT *

--FROM [SMS].dbo.[Yesterdays_Pt_Balances]


--where [Pt_No] = '436416739'