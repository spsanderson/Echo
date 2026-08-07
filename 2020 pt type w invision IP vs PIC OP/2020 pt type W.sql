use [sms]


SELECT DISTINCT
n.[Pt_No]
,n.[MRN]
--,n.[Pt_Name]
,ltrim(rtrim(substring(n.[Pt_Name],1,charindex(',',n.[Pt_Name])-1))) as 'Pt_Last_Name'
,ltrim(rtrim(substring(n.[Pt_Name],charindex(',',n.[Pt_Name])+1, LEN(n.[Pt_Name])))) as 'Pt_First_Name'
,isnull(n.[Unit_No],'') as [Unit_No]
--,n.[PA_Ctl_PAA_Xfer_Date]
,n.[Admit_Date]
,n.[Dsch_Date]
,isnull(n.[Unit_Date],'') as [Unit_Date]
,isnull(a.[Pa-pt-type],'') as [Pa-pt-type]
,n.[Acct_Type]
--,ch.[pa-dtl-rev-cd]
,n.[Hosp_Svc]
,isnull([Hosp_Svc_Description],'') as [Hosp_Svc_Description]
,n.[Age_Bucket]
,n.[First_Ins_Bl_Date]
,n.[Balance]
,n.[COB1_Balance]
,n.[Pt_Balance]
,n.[Tot_Chgs]
,n.[Ins_Pay_Amt]
,n.[Tot_Pay_Amt]
--,n.[Ins1_Balance]
--,isnull(n.[Pyr1_Pay_Amt],'0') as [Pyr1_Pay_Amt]
,n.[File]
,n.[FC]
,n.[FC_Description]
,n.[COB_1]
,n.[Ins1_Cd]
,COALESCE(n.[Ins1_Member_ID],n.[Ins1_Pol_No],n.[Ins1_Subscr_Group_ID]) as 'Ins1_Member_ID'
--,isnull(n.[Ins1_Pol_No],'') as [Ins1_Pol_No]
,n.[Ins1_Balance]
,isnull(n.[Pyr1_Pay_Amt],'0') as [Pyr1_Pay_Amt]
--,[Ins1_Subscr_Group_ID]
--,[Ins1_Grp_No],n.[COB_2]
--,isnull(n.[Ins2_Cd],'') as [Ins2_Cd]
--,isnull(COALESCE(n.[Ins2_Member_ID],n.[Ins2_Pol_No],n.[Ins2_Subscr_Group_ID]),'') as 'Ins2_Member_ID'
--,isnull(n.[Ins2_Pol_No],'') as [Ins2_Pol_No]
--,[Ins2_Subscr_Group_ID]
--,[Ins2_Grp_No]
--,n.[Ins2_Balance]
--,[Pyr2_Pay_Amt]
--,isnull(n.[Pyr2_Pay_Amt],'0') as [Pyr2_Pay_Amt]
--,n.[COB_3]
--,[Ins3_Cd]
--,isnull(COALESCE(n.[Ins3_Member_ID],n.[Ins3_Pol_No],n.[Ins3_Subscr_Group_ID]),'') as 'Ins3_Member_ID'
--,isnull(n.[Ins3_Pol_No],'') as [Ins3_Pol_No]
--,[Ins3_Subscr_Group_ID]
--,[Ins3_Grp_No]
--,n.[Ins3_Balance]
--,[Pyr3_Pay_Amt]
--,isnull(n.[Pyr3_Pay_Amt],'0') as [Pyr3_Pay_Amt]
--,n.[COB_4]
--,[Ins4_Cd]
--,isnull(n.[Ins4_Cd],'') as [Ins4_Cd]
--,isnull(COALESCE(n.[Ins4_Member_ID],n.[Ins4_Pol_No],n.[Ins4_Subscr_Group_ID]),'') as 'Ins4_Member_ID'
--,isnull(n.[Ins4_Pol_No],'') as [Ins4_Pol_No]
--,[Ins4_Subscr_Group_ID]
--,[Ins4_Grp_No]
--,n.[Ins4_Balance]
--,[Pyr4_Pay_Amt]
--,isnull(n.[Pyr4_Pay_Amt],'0') as [Pyr4_Pay_Amt]

FROM [Pt_Accounting_Reporting_ALT] n
--left join [Encounters_For_Reporting] b
--on n.[Pt_No] = (CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd] as varchar))

left join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ACTIVE].dbo.PatientDemographics a 
ON n.[Pt_No] = (CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar))

--left join [Charges_For_Reporting] ch
--on n.[Pt_No] = (CAST(ch.[pa-pt-no-woscd] as varchar) + CAST(ch.[pa-pt-no-scd] as varchar))

WHERE 

--[ins1_Cd] IN ('C20','C25','C30','C46','C47','C48','C49','C50','C55','C88','C89','C90','C91','C92','C93','C94','C99')

--AND 

--[Hosp_Svc] IN ('EMR') ---,'EMS','EPX','EMD','EOB')

--AND

n.[Admit_Date] >= '1/1/2020' and n.[Admit_Date] <='12/31/2020'

AND

a.[pa-pt-type] = 'W'

--AND

--n.[Balance] > '0'
--and n.[Pt_No]='10149016015'



UNION

SELECT DISTINCT
n.[Pt_No]
,n.[MRN]
--,n.[Pt_Name]
,ltrim(rtrim(substring(n.[Pt_Name],1,charindex(',',n.[Pt_Name])-1))) as 'Pt_Last_Name'
,ltrim(rtrim(substring(n.[Pt_Name],charindex(',',n.[Pt_Name])+1, LEN(n.[Pt_Name])))) as 'Pt_First_Name'
,isnull(n.[Unit_No],'') as [Unit_No]
--,n.[PA_Ctl_PAA_Xfer_Date]
,n.[Admit_Date]
,n.[Dsch_Date]
,isnull(n.[Unit_Date],'') as [Unit_Date]
,isnull(a.[Pa-pt-type],'') as [Pa-pt-type]
,n.[Acct_Type]
--,ch.[pa-dtl-rev-cd]
,n.[Hosp_Svc]
,isnull([Hosp_Svc_Description],'') as [Hosp_Svc_Description]
,n.[Age_Bucket]
,n.[First_Ins_Bl_Date]
,n.[Balance]
,n.[COB1_Balance]
,n.[Pt_Balance]
,n.[Tot_Chgs]
,n.[Ins_Pay_Amt]
,n.[Tot_Pay_Amt]
--,n.[Ins1_Balance]
--,isnull(n.[Pyr1_Pay_Amt],'0') as [Pyr1_Pay_Amt]
,n.[File]
,n.[FC]
,n.[FC_Description]
,n.[COB_1]
,n.[Ins1_Cd]
,COALESCE(n.[Ins1_Member_ID],n.[Ins1_Pol_No],n.[Ins1_Subscr_Group_ID]) as 'Ins1_Member_ID'
--,isnull(n.[Ins1_Pol_No],'') as [Ins1_Pol_No]
,n.[Ins1_Balance]
,isnull(n.[Pyr1_Pay_Amt],'0') as [Pyr1_Pay_Amt]
--,[Ins1_Subscr_Group_ID]
--,[Ins1_Grp_No],n.[COB_2]
--,isnull(n.[Ins2_Cd],'') as [Ins2_Cd]
--,isnull(COALESCE(n.[Ins2_Member_ID],n.[Ins2_Pol_No],n.[Ins2_Subscr_Group_ID]),'') as 'Ins2_Member_ID'
--,isnull(n.[Ins2_Pol_No],'') as [Ins2_Pol_No]
--,[Ins2_Subscr_Group_ID]
--,[Ins2_Grp_No]
--,n.[Ins2_Balance]
--,[Pyr2_Pay_Amt]
--,isnull(n.[Pyr2_Pay_Amt],'0') as [Pyr2_Pay_Amt]
--,n.[COB_3]
--,[Ins3_Cd]
--,isnull(COALESCE(n.[Ins3_Member_ID],n.[Ins3_Pol_No],n.[Ins3_Subscr_Group_ID]),'') as 'Ins3_Member_ID'
--,isnull(n.[Ins3_Pol_No],'') as [Ins3_Pol_No]
--,[Ins3_Subscr_Group_ID]
--,[Ins3_Grp_No]
--,n.[Ins3_Balance]
--,[Pyr3_Pay_Amt]
--,isnull(n.[Pyr3_Pay_Amt],'0') as [Pyr3_Pay_Amt]
--,n.[COB_4]
--,[Ins4_Cd]
--,isnull(n.[Ins4_Cd],'') as [Ins4_Cd]
--,isnull(COALESCE(n.[Ins4_Member_ID],n.[Ins4_Pol_No],n.[Ins4_Subscr_Group_ID]),'') as 'Ins4_Member_ID'
--,isnull(n.[Ins4_Pol_No],'') as [Ins4_Pol_No]
--,[Ins4_Subscr_Group_ID]
--,[Ins4_Grp_No]
--,n.[Ins4_Balance]
--,[Pyr4_Pay_Amt]
--,isnull(n.[Pyr4_Pay_Amt],'0') as [Pyr4_Pay_Amt]


FROM [Pt_Accounting_Reporting_ALT] n
--left join [Encounters_For_Reporting] b
--on n.[Pt_No] = (CAST(b.[pa-pt-no-woscd] as varchar) + CAST(b.[pa-pt-no-scd] as varchar))

left join [ECHOLOADERDBP.UHMC.SBUH.STONYBROOK.EDU].[Echo_ARchIVE].dbo.PatientDemographics a 
ON n.[Pt_No] = (CAST(a.[pa-pt-no-woscd] as varchar) + CAST(a.[pa-pt-no-scd-1] as varchar))

--left join [Charges_For_Reporting] ch
--on n.[Pt_No] = (CAST(ch.[pa-pt-no-woscd] as varchar) + CAST(ch.[pa-pt-no-scd] as varchar))

WHERE 


n.[Admit_Date] >= '1/1/2017' --and n.[Admit_Date] <='12/31/2020'

AND

a.[pa-pt-type] = 'W'

--and n.[Pt_No]='10149016015'


