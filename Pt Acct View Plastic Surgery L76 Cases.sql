
----------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table for Implant Charges*/

IF OBJECT_ID('tempdb.dbo.#Implant_Chgs','U') IS NOT NULL
DROP TABLE #Implant_Chgs;

CREATE TABLE #Implant_Chgs

(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[implant-charges] MONEY NULL
);

INSERT INTO #Implant_Chgs ([PA-PT-NO],[IMPLANT-CHARGES])
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-amt]) as 'IMPLANT-CHARGES'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-rev-cd] = '278' --Implants; 275=Pacemaker; 279=Other Supplies
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]
UNION
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-amt]) as 'IMPLANT-CHARGES'
FROM [Echo_Active].dbo.DetailInformation
WHERE [pa-dtl-rev-cd] = '278' --Implants; 275=Pacemaker; 279=Other Supplies
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]
----------------------------------------------------------------------------------------------------------------------------------------------------

/*Create Table of OR/ASC Time and Recovery Time*/
IF OBJECT_ID('tempdb.dbo.#OR_Time','U') IS NOT NULL
DROP TABLE #OR_Time;

CREATE TABLE #OR_Time

(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[OR-TIME] decimal(5,0) NULL,
[OR-DOLLARS]MONEY NULL
);

INSERT INTO #OR_Time ([PA-PT-NO],[OR-TIME],[OR-DOLLARS])
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-qty]) as 'OR-TIME',
SUM([pa-dtl-chg-amt]) as 'OR-DOLLARS'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('4047025','2861194')--OR TIME & ASC TIME
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]
UNION
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-qty]) as 'OR-TIME',
SUM([pa-dtl-chg-amt]) as 'OR-DOLLARS'
FROM [Echo_Active].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('4047025','2861194')--OR TIME & ASC TIME
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]


----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Table of OR/ASC Time and Recovery Time*/
IF OBJECT_ID('tempdb.dbo.#OR_Time','U') IS NOT NULL
DROP TABLE #Recovery_Time;

CREATE TABLE #Recovery_Time

(
[PA-PT-NO] VARCHAR(12) NOT NULL,
[RECOVERY-TIME] decimal(5,0) NULL,
[RECOVERY-DOLLARS]MONEY NULL
);

INSERT INTO #Recovery_Time ([PA-PT-NO],[RECOVERY-TIME],[RECOVERY-DOLLARS])
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-qty]) as 'RECOVERY-TIME',
SUM([pa-dtl-chg-amt]) as 'RECOVERY-DOLLARS'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('4060053','2861195')--OR RECOVERY TIME & ASC RECOVERY TIME
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]
UNION
SELECT CAST([pa-pt-no-woscd] as varchar) + CAST([pa-pt-no-scd-1] as varchar) as 'PA-PT-NO',
SUM([pa-dtl-chg-qty]) as 'RECOVERY-TIME',
SUM([pa-dtl-chg-amt]) as 'RECOVERY-DOLLARS'
FROM [Echo_Archive].dbo.DetailInformation
WHERE [pa-dtl-svc-cd-woscd] IN ('4060053','2861195')--OR RECOVERY TIME & ASC RECOVERY TIME
AND [pa-dtl-chg-amt]<>'0'
GROUP BY [pa-pt-no-woscd],[pa-pt-no-scd-1]


----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No'
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no] as 'MRN'
,a.[pa-pt-name]
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) as 'Age_From_Discharge'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240' THEN '9_240+'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'
ELSE ''
END as 'Age_Bucket'
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,a.[pa-bal-tot-pt-pay-amt] as 'Pt_Pay_Amt'
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money)) as 'Ins_Pay_Amt'
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) as 'Tot_Pay_Amt'
,CASE
WHEN a.[pa-acct-type] in ('0','6','7') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
ELSE ''
END AS 'PtAcct_Type'
,CASE
WHEN a.[pa-acct-type] in ('6','4') THEN 'Bad Debt'
WHEN a.[pa-dsch-date] is not null and a.[pa-acct-type]='1' THEN 'DNFB'
WHEN a.[pa-acct-type] = '1' THEN 'Inhouse'
ELSE 'A/R'
END as 'File'
,[pa-fc] as 'FC'
,CASE
WHEN [pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
WHEN [pa-fc] in ('2','6') THEN 'Bad Debt AG'
WHEN [pa-fc]='3' THEN 'MCS'
WHEN [pa-fc]='4' THEN 'Bad Debt AG Legal'
WHEN [pa-fc]='5' THEN 'Bad Debt POM'
WHEN [pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
WHEN [pa-fc]='9' THEN 'Bad Debt'
WHEN [pa-fc]='A' THEN 'Commercial'
WHEN [pa-fc]='B' THEN 'Blue Cross'
WHEN [pa-fc]='C' THEN 'Champus'
WHEN [pa-fc]='D' THEN 'Medicaid'
WHEN [pa-fc]='E' THEN 'Employee Health Svc'
WHEN [pa-fc]='G' THEN 'Contract Accts'
WHEN [pa-fc]='H' THEN 'Medicare HMO'
WHEN [pa-fc]='I' THEN 'Balance After Ins'
WHEN [pa-fc]='J' THEN 'Managed Care'
WHEN [pa-fc]='K' THEN 'Pending Medicaid'
WHEN [pa-fc]='M' THEN 'Medicare'
WHEN [pa-fc]='N' THEN 'No-Fault'
WHEN [pa-fc]='P' THEN 'Self Pay'
WHEN [pa-fc]='S' THEN 'Special Billing'
WHEN [pa-fc]='U' THEN 'Medicaid Mgd Care'
WHEN [pa-fc]='V' THEN 'First Source'
WHEN [pa-fc]='W' THEN 'Workers Comp'
WHEN [pa-fc]='X' THEN 'Control Accts'
WHEN [pa-fc]='Y' THEN 'MCS'
WHEN [pa-fc]='Z' THEN 'Unclaimed Credits'
ELSE ''
END as 'FC_Description'
,[pa-hosp-svc]
,CASE
WHEN [PA-HOSP-SVC]='ABC' THEN 'Ambulatory Breast Care'
WHEN [PA-HOSP-SVC]='ABD' THEN 'ACC Breast Diagnosis'
WHEN [PA-HOSP-SVC]='ACA' THEN 'Amb Care Admit'
WHEN [PA-HOSP-SVC]='ACP' THEN 'Amb Cancer Provider'
WHEN [PA-HOSP-SVC]='ACU' THEN 'Discontinued AIDS'
WHEN [PA-HOSP-SVC]='ALG' THEN 'Allergy'
WHEN [PA-Hosp-svc]='ALL' THEN 'Allergy Rhematology'
WHEN [pa-hosp-svc]='ALS' THEN 'Amotroph Ltl Sclsis'
WHEN [pa-hosp-svc]='AND' THEN 'Andrology Lab'
WHEN [pa-hosp-svc]='ANT' THEN 'Antepartum Testing'
WHEN [pa-hosp-svc]='AOI' THEN ' Apnea Of Infancy'
WHEN [pa-hosp-svc]='APN' THEN 'Ambulatory Pain'
WHEN [pa-hosp-svc]='APP' THEN 'Ambulatory Pain Proc'
WHEN [pa-hosp-svc]='APV' THEN 'Adult Patient Visit'
WHEN [pa-hosp-svc]='ARI' THEN 'Ambulatory MRI'
WHEN [pa-hosp-svc]='ARP' THEN 'Anal Rectal Phsyiol'
WHEN [pa-hosp-svc]='ARY' THEN 'Ambulatory X-Ray'
WHEN [pa-hosp-svc]='ASC' THEN 'Ambulatory Surgery Center'
WHEN [pa-hosp-svc]='AUC' THEN 'Adult Urgent Care'
WHEN [pa-hosp-svc]='AUD' THEN 'Audiology'
WHEN [pa-hosp-svc]='AUT' THEN 'Autopsy'
WHEN [pa-hosp-svc]='AXP' THEN 'ACC Radiology Procedure'
WHEN [pa-hosp-svc]='BCK' THEN 'Back School'
WHEN [pa-hosp-svc]='BKO' THEN 'Back Other'
WHEN [pa-hosp-svc]='BLD' THEN 'MODQ'
WHEN [pa-hosp-svc]='BMD' THEN 'Osteoporosis'
WHEN [pa-hosp-svc]='BMT' THEN 'Bone Marow Trns'
WHEN [pa-hosp-svc]='BNL' THEN 'Brkhaven Nat Lab'
WHEN [pa-hosp-svc]='BRE' THEN 'Breast Center'
WHEN [pa-hosp-svc]='BRN' THEN 'Burn Center'
WHEN [pa-hosp-svc]='BRP' THEN 'Breast Procedure'
WHEN [pa-hosp-svc]='BRS' THEN 'Breast Surgery'
WHEN [pa-hosp-svc]='BUR' THEN 'Burn Unit For OPBC'
WHEN [pa-hosp-svc]='CAD' THEN 'Cardiology IP'
WHEN [pa-hosp-svc]='CAM' THEN 'Comp Alternative Med'
WHEN [pa-hosp-svc]='CAR' THEN 'Cardiology OP'
WHEN [pa-hosp-svc]='CCF' THEN 'Cleft Cranial Facial'
WHEN [pa-hosp-svc]='CCL' THEN 'Cody Center Life'
WHEN [pa-hosp-svc]='CCP' THEN 'Cody Center Patients'
WHEN [pa-hosp-svc]='CCU' THEN 'Coron ICU'
WHEN [pa-hosp-svc]='CDT' THEN 'Cardiothoracic'
WHEN [pa-hosp-svc]='CDY' THEN 'Cardiology'
WHEN [pa-hosp-svc]='COL' THEN 'Colo-rectal Oncology'
WHEN [pa-hosp-svc]='COU' THEN 'Anticoagulation'
WHEN [pa-hosp-svc]='CPT' THEN 'Cath Pre-Testing'
WHEN [pa-hosp-svc]='CPU' THEN 'Chest Pain Unit'
WHEN [pa-hosp-svc]='CRB' THEN 'Cardiac Rehab'
WHEN [pa-hosp-svc]='CRC' THEN 'GREC Grant OP'
WHEN [pa-hosp-svc]='CRD' THEN 'Cardiology Testing'
WHEN [pa-hosp-svc]='CRS' THEN 'Colorectal Surgery'
WHEN [pa-hosp-svc]='CRU' THEN 'GREC Grant IP'
WHEN [pa-hosp-svc]='CSA' THEN 'Ambulance'
WHEN [pa-hosp-svc]='CSS' THEN 'Short Stay Cardiac'
WHEN [pa-hosp-svc]='CTD' THEN 'Cadaver Donor'
WHEN [pa-hosp-svc]='CTH' THEN 'Cardiac Catheterization'
WHEN [pa-hosp-svc]='CTP' THEN 'Child Tech Park'
WHEN [pa-hosp-svc]='CUC' THEN 'Cardiac Urgent Care'
WHEN [pa-hosp-svc]='CVC' THEN 'Cerebrovascular Center'
WHEN [pa-hosp-svc]='CVU' THEN 'Cardio ICU'
WHEN [pa-hosp-svc]='CYT' THEN 'Cytogenics'
WHEN [pa-hosp-svc]='DBM' THEN 'Donor Bone Marrow'
WHEN [pa-hosp-svc]='DDP' THEN 'Development Disab Pt'
WHEN [pa-hosp-svc]='DEN' THEN 'Dental'
WHEN [pa-hosp-svc]='DER' THEN 'Dermatology'
WHEN [pa-hosp-svc]='DIA' THEN 'Dialysis'
WHEN [pa-hosp-svc]='DIB' THEN 'Diabetes OPD'
WHEN [pa-hosp-svc]='DIH' THEN 'Home Dialysis'
WHEN [pa-hosp-svc]='DIS' THEN 'Disaster Patient'
WHEN [pa-hosp-svc]='DNT' THEN 'Dental'
WHEN [pa-hosp-svc]='DOF' THEN 'Dialysis Outside Fac'
WHEN [pa-hosp-svc]='DON' THEN 'Dental Oncology'
WHEN [pa-hosp-svc]='DPA' THEN 'Dental Pathology'
WHEN [pa-hosp-svc]='DPC' THEN 'Dermatology Procedure'
WHEN [pa-hosp-svc]='DRM' THEN 'Dermatology Module'
WHEN [pa-hosp-svc]='DUV' THEN 'Dermatology UV Therapy'
WHEN [pa-hosp-svc]='ECG' THEN 'ECG'
WHEN [pa-hosp-svc]='ECT' THEN 'Electroconvulsive Therapy'
WHEN [pa-hosp-svc]='EDA' THEN 'ED Admission'
WHEN [pa-hosp-svc]='EDT' THEN 'ED Admissions/Billing'
WHEN [pa-hosp-svc]='EEC' THEN 'EECP Treatments'
WHEN [pa-hosp-svc]='EEG' THEN 'OPEG'
WHEN [pa-hosp-svc]='EHS' THEN 'Emp Health Svc'
WHEN [pa-hosp-svc]='ELC' THEN 'Amb Lung Cancer Eval'
WHEN [pa-hosp-svc]='ELI' THEN 'Eastern Long Island Hosp'
WHEN [pa-hosp-svc]='EMD' THEN 'Emergency Dental'
WHEN [pa-hosp-svc]='EMR' THEN 'Emergency'
WHEN [pa-hosp-svc]='EMS' THEN 'Emergency Med Serv'
WHEN [pa-hosp-svc]='EMT' THEN 'Ambulance'
WHEN [pa-hosp-svc]='ENC' THEN 'Endocrinology'
WHEN [pa-hosp-svc]='END' THEN 'Endocrine'
WHEN [pa-hosp-svc]='ENO' THEN 'Endoscopy'
WHEN [pa-hosp-svc]='ENT' THEN 'ENT'
WHEN [pa-hosp-svc]='EOB' THEN 'ED Observation'
WHEN [pa-hosp-svc]='EPS' THEN 'EP Lab'
WHEN [pa-hosp-svc]='EPX' THEN 'Emergency Spec Proc'
WHEN [pa-hosp-svc]='ESS' THEN 'Endoscopic Swallow Study'
WHEN [pa-hosp-svc]='EYE' THEN 'Eye'
WHEN [pa-hosp-svc]='FAM' THEN 'Family Medicine OP'
WHEN [pa-hosp-svc]='FMD' THEN 'Family Medicine IP'
WHEN [pa-hosp-svc]='FMN' THEN 'Family Med Newborn'
WHEN [pa-hosp-svc]='FMO' THEN 'Family Medicine Obs'
WHEN [pa-hosp-svc]='FMP' THEN 'Family Medicine Patchogue'
WHEN [pa-hosp-svc]='FNA' THEN 'Fine Needle Aspiration'
WHEN [pa-hosp-svc]='FOB' THEN 'FOB Family Med Obs'
WHEN [pa-hosp-svc]='FPD' THEN 'FPD Family Med Ped'
WHEN [pa-hosp-svc]='GAS' THEN 'Gastroenterology'
WHEN [pa-hosp-svc]='GEN' THEN 'General Medicine'
WHEN [pa-hosp-svc]='GER' THEN 'Geriatrics'
WHEN [pa-hosp-svc]='GFL' THEN 'Gift of Life'
WHEN [pa-hosp-svc]='GMA' THEN 'Gen Med Team A'
WHEN [pa-hosp-svc]='GMB' THEN 'Gen Med Team B'
WHEN [pa-hosp-svc]='GMC' THEN 'Gen Med Team C'
WHEN [pa-hosp-svc]='GMD' THEN 'Gen Med Team D'
WHEN [pa-hosp-svc]='GME' THEN 'Gen Med Team E'
WHEN [pa-hosp-svc]='GMF' THEN 'Gen Med Team F'
WHEN [pa-hosp-svc]='GMG' THEN 'Gen Med Team G'
WHEN [pa-hosp-svc]='GMH' THEN 'Gen Med Team H'
WHEN [pa-hosp-svc]='GMK' THEN 'Gen Med Team K'
WHEN [pa-hosp-svc]='GMW' THEN 'Gen Med Team W'
WHEN [pa-hosp-svc]='GMX' THEN 'Gen Med Flex'
WHEN [pa-hosp-svc]='GMY' THEN 'Gen Med Team Y'
WHEN [pa-hosp-svc]='GMZ' THEN 'Gen Med Team Z'
WHEN [pa-hosp-svc]='GNC' THEN 'Gyn-Oncology'
WHEN [pa-hosp-svc]='GNE' THEN 'Gynecology OP'
WHEN [pa-hosp-svc]='GNO' THEN 'Gynecology OP'
WHEN [pa-hosp-svc]='GNP' THEN 'Gyn Patchogue'
WHEN [pa-hosp-svc]='GON' THEN 'Ancology'
WHEN [pa-hosp-svc]='GSG' THEN 'General Surgery'
WHEN [pa-hosp-svc]='GSR' THEN 'General Surgery Red'
WHEN [pa-hosp-svc]='GST' THEN 'Gastroenterology'
WHEN [pa-hosp-svc]='GSW' THEN 'General Surgery White'
WHEN [pa-hosp-svc]='GSX' THEN 'General Surgery X'
WHEN [pa-hosp-svc]='GYN' THEN 'Gynecology'
WHEN [pa-hosp-svc]='HEM' THEN 'Hematology OP'
WHEN [pa-hosp-svc]='HMA' THEN 'Hematology IP'
WHEN [pa-hosp-svc]='HND' THEN 'Hand Surgery'
WHEN [pa-hosp-svc]='HOB' THEN 'Hospital Observation'
WHEN [pa-hosp-svc]='HSC' THEN 'Health Screening Cnt'
WHEN [pa-hosp-svc]='HTY' THEN 'Hand Therapy'
WHEN [pa-hosp-svc]='ICD' THEN 'Islandia Cardiology'
WHEN [pa-hosp-svc]='IGM' THEN 'Islandia General Med'
WHEN [pa-hosp-svc]='IGN' THEN 'Gyn Islip'
WHEN [pa-hosp-svc]='IMM' THEN 'IMM AIDS O/P'
WHEN [pa-hosp-svc]='IMU' THEN 'Discontinued AIDS I/P'
WHEN a.[pa-hosp-svc]='IND' THEN 'Infectious Diseases'
WHEN a.[pa-hosp-svc]='INF' THEN 'Infections Diseases'
WHEN a.[pa-hosp-svc]='INJ' THEN 'Injection'
WHEN a.[pa-hosp-svc]='IOB' THEN 'OB Islip'
WHEN a.[pa-hosp-svc]='IPD' THEN 'Peds Islip'
WHEN a.[pa-hosp-svc]='IPS' THEN 'Psych ER Observation'
WHEN a.[pa-hosp-svc]='IRC' THEN 'Intervent Rad Clinic'
WHEN a.[pa-hosp-svc]='ISC' THEN 'Islandia Congestive'
WHEN a.[pa-hosp-svc]='KAC' THEN 'Medicaid Anesth Pain'
WHEN a.[pa-hosp-svc]='KFM' THEN 'Medicaid Family Medicine'
WHEN a.[pa-hosp-svc]='KGY' THEN 'Medicaid Gynecology'
WHEN a.[pa-hosp-svc]='KMC' THEN 'Medicaid Cardiology'
WHEN a.[pa-hosp-svc]='KMG' THEN 'Medicaid Gastroenterology'
WHEN a.[pa-hosp-svc]='KMR' THEN 'Medicaid General Med'
WHEN a.[pa-hosp-svc]='KMS' THEN 'Medicaid Med Special'
WHEN a.[pa-hosp-svc]='KNE' THEN 'Medicaid Neurology'
WHEN a.[pa-hosp-svc]='KOB' THEN 'Medicaid Obstetrics'
WHEN a.[pa-hosp-svc]='KOP' THEN 'MEdicaid Opthamology'
WHEN a.[pa-hosp-svc]='KPC' THEN 'Medicaid Ped Cody Ct'
WHEN a.[pa-hosp-svc]='KPI' THEN 'Medicaid Ped Islip'
WHEN a.[pa-hosp-svc]='KPM' THEN 'Medicaid Ped E Moriches'
WHEN a.[pa-hosp-svc]='KPN' THEN 'Medicaid Pain'
WHEN a.[pa-hosp-svc]='KPP' THEN 'Medicaid Pain Procedure'
WHEN a.[pa-hosp-svc]='KPT' THEN 'Medicaid Ped Tech Park'
WHEN a.[pa-hosp-svc]='KPY' THEN 'Medicaid Psychiatry'
WHEN a.[pa-hosp-svc]='KSG' THEN 'Medicaid Surgery Service'
WHEN a.[pa-hosp-svc]='KUR' THEN 'Medicaid Urology'
WHEN a.[pa-hosp-svc]='LAB' THEN 'Lab Specimens'
WHEN a.[pa-hosp-svc]='LAD' THEN 'Labor and Delivery'
WHEN a.[pa-hosp-svc]='LCC' THEN 'Life Center at HB'
WHEN a.[pa-hosp-svc]='LCE' THEN 'Lung Cancer Eval'
WHEN a.[pa-hosp-svc]='LGD' THEN 'Lou Gehrigs Disease'
WHEN a.[pa-hosp-svc]='LID' THEN 'LIVH Day Care'
WHEN a.[pa-hosp-svc]='LIQ' THEN 'LI Queens Med Group'
WHEN a.[pa-hosp-svc]='LIV' THEN 'LI Vet Home'
WHEN a.[pa-hosp-svc]='LLT' THEN 'Leukemia Lymp Trnplt'
WHEN a.[pa-hosp-svc]='LRD' THEN 'Liv Rel Donor'
WHEN a.[pa-hosp-svc]='LSA' THEN 'LSARD'
WHEN a.[pa-hosp-svc]='LVD' THEN 'Left Ventric Ass Dev'
WHEN a.[pa-hosp-svc]='LYM' THEN 'Lymphedema Therapy'
WHEN a.[pa-hosp-svc]='MAS' THEN 'Maternity Amb Surgery'
WHEN a.[pa-hosp-svc]='MCU' THEN 'Medical ICU'
WHEN a.[pa-hosp-svc]='MEM' THEN 'Med East Moriches'
WHEN a.[pa-hosp-svc]='MET' THEN 'MTU O/P Research'
WHEN a.[pa-hosp-svc]='MIU' THEN 'Medical ICU 2'
WHEN a.[pa-hosp-svc]='MOL' THEN 'Med Oncology IP'
WHEN a.[pa-hosp-svc]='MON' THEN 'Med Oncology OP'
WHEN a.[pa-hosp-svc]='MOP' THEN 'Medical Oncology Proc'
WHEN a.[pa-hosp-svc]='MOT' THEN 'Motility Lab'
WHEN a.[pa-hosp-svc]='MPC' THEN 'Med Procedure'
WHEN a.[pa-hosp-svc]='MRI' THEN 'MRI'
WHEN a.[pa-hosp-svc]='MSC' THEN 'Misc Income'
WHEN a.[pa-hosp-svc]='MSS' THEN 'Short Stay Medicine'
WHEN a.[pa-hosp-svc]='MST' THEN 'Massage Therapy'
WHEN a.[pa-hosp-svc]='MTU' THEN 'Metabolic Treatment'
WHEN a.[pa-hosp-svc]='MUC' THEN 'Maternity Urgent Care'
WHEN a.[pa-hosp-svc]='NBN' THEN 'Non Burn'
WHEN a.[pa-hosp-svc]='NBS' THEN 'Neck, Back, Spine'
WHEN a.[pa-hosp-svc]='NCU' THEN 'Neurosurgical ICU'
WHEN a.[pa-hosp-svc]='NEP' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NER' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NES' THEN 'Neurosurgery'
WHEN a.[pa-hosp-svc]='NEU' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NEW' THEN 'Newborn'
WHEN a.[pa-hosp-svc]='NEY' THEN 'Neurology OP'
WHEN a.[pa-hosp-svc]='NMD' THEN 'NAtional Marrow Donor'
WHEN a.[pa-hosp-svc]='NNU' THEN 'Neonatal ICU'
WHEN a.[pa-hosp-svc]='NOP' THEN 'Nutrition OP'
WHEN a.[pa-hosp-svc]='NPH' THEN 'Nephrology IP'
WHEN a.[pa-hosp-svc]='NPT' THEN 'Neuro Psycholog Test'
WHEN a.[pa-hosp-svc]='NPY' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NSO' THEN 'Neurosurgery Oncology'
WHEN a.[pa-hosp-svc]='NSP' THEN 'Neuro Special Proced'
WHEN a.[pa-hosp-svc]='NSY' THEN 'Tech PArk Neurosurg'
WHEN a.[pa-hosp-svc]='NTF' THEN 'Nutrit Target Fitnes'
WHEN a.[pa-hosp-svc]='NTN' THEN 'Nutritional Svcs OP'
WHEN a.[pa-hosp-svc]='NTR' THEN 'Non Transplant'
WHEN a.[pa-hosp-svc]='NUS' THEN 'Neurosurgery IP'
WHEN a.[pa-hosp-svc]='NVB' THEN 'Non-Viable Births'
WHEN a.[pa-hosp-svc]='OBE' THEN 'Obstetrics'
WHEN a.[pa-hosp-svc]='OBP' THEN 'OB Patchogue'
WHEN a.[pa-hosp-svc]='OBS' THEN 'Obstetrics IP'
WHEN a.[pa-hosp-svc]='OBT' THEN 'Obstetrics OP'
WHEN a.[pa-hosp-svc]='OCC' THEN 'Occupational Therapy'
WHEN a.[pa-hosp-svc]='OCM' THEN 'Occupational Med'
WHEN a.[pa-hosp-svc]='ODM' THEN 'Dermatology-Oncology'
WHEN a.[pa-hosp-svc]='OEM' THEN 'Outpat East Moriches'
WHEN a.[pa-hosp-svc]='OGN' THEN 'Amb Gyn Oncology'
WHEN a.[pa-hosp-svc]='OLL' THEN 'OP Leukemia Lymphoma'
WHEN a.[pa-hosp-svc]='OLR' THEN 'Otolaryngology'
WHEN a.[pa-hosp-svc]='OMH' THEN 'Ofc of Mental Health'
WHEN a.[pa-hosp-svc]='ONC' THEN 'Amb Surgic Oncolog'
WHEN a.[pa-hosp-svc]='OPH' THEN 'Opthamology'
WHEN a.[pa-hosp-svc]='ORC' THEN 'Orthoped Surg Oncol'
WHEN a.[pa-hosp-svc]='ORG' THEN 'Organ Retrieval'
WHEN a.[pa-hosp-svc]='ORT' THEN 'Orthopedics'





ELSE ''
END AS 'Hosp Svc Description'
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
,(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] as varchar)) as 'Ins1_Cd'
,(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] as varchar)) as 'Ins2_Cd'
,(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar)) as 'Ins3_Cd' 
,(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] as varchar)) as 'Ins4_Cd'
,g.[pa-dx2-code] as 'Prin_Dx'
,h.[pa-proc3-cd] as 'ICD_Prin_Proc'
,a.[pa-disch-dx-cd]
,a.[pa-disch-dx-cd-type]
,a.[pa-disch-dx-date]
,a.[PA-PROC-CD-TYPE(1)]
,a.[PA-PROC-CD(1)]
,a.[PA-PROC-DATE(1)]
,a.[pa-proc-prty(1)]
,a.[PA-PROC-CD-TYPE(2)]
,a.[PA-PROC-CD(2)]
,a.[PA-PROC-DATE(2)]
,a.[pa-proc-prty(2)]
,a.[PA-PROC-CD-TYPE(3)]
,a.[PA-PROC-CD(3)]
,a.[PA-PROC-DATE(3)]
,a.[pa-proc-prty(3)]

,c.[pa-bal-ins-pay-amt] as 'Pyr1_Pay_Amt'
,d.[pa-bal-ins-pay-amt] as 'Pyr2_Pay_Amt'
,e.[pa-bal-ins-pay-amt] as 'Pyr3_Pay_Amt'
,f.[pa-bal-ins-pay-amt] as 'Pyr4_Pay_Amt'
,c.[pa-last-ins-bl-date] as 'Pyr1_Last_Ins_Bl_Date'
,d.[pa-last-ins-bl-date] as 'Pyr2_Last_Ins_Bl_Date'
,e.[pa-last-ins-bl-date] as 'Pyr3_Last_Ins_Bl_Date'
,f.[pa-last-ins-bl-date] as 'Pyr4_Last_Ins_Bl_Date'
,a.[pa-last-fc-cng-date]
,i.[implant-charges]
,j.[OR-TIME]
,j.[OR-DOLLARS]
,k.[RECOVERY-TIME]
,K.[RECOVERY-DOLLARS]

FROM [Echo_Archive].dbo.PatientDemographics a left outer join [Echo_Archive].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1]
left outer join [Echo_Archive].dbo.insuranceinformation c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'
left outer join [Echo_Archive].dbo.insuranceinformation d
ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='2'
left outer join [Echo_Archive].dbo.insuranceinformation e
ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='3'
left outer join [Echo_Archive].dbo.insuranceinformation f
ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[pa-ins-prty]='4'
left outer join [Echo_Archive].dbo.diagnosisinformation g
ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
left outer join [Echo_Archive].dbo.ProcedureInformation h
ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd] and h.[pa-proc3-prty]='1' and h.[pa-proc3-cd-type] IN ('0','9')
left outer join dbo.[#Implant_Chgs] i
ON CAST(a.[pa-pt-no-woscd] as varchar)+CAST(a.[pa-pt-no-scd] as varchar)=i.[pa-pt-no]
left outer join dbo.[#OR_Time] j
ON CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd] as varchar)=j.[pa-pt-no]
left outer join dbo.[#Recovery_Time] K
ON CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd] as varchar)=k.[pa-pt-no]
--left outer join dbo.detailinformation c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=c.[pa-pt-no-scd-1]

WHERE 

--a.[pa-fc]='D'
--AND a.[pa-acct-type]='0'--(a.[pa-acct-type] NOT IN ('4','6','7','8')--Active A/R; Excludes Bad Debt & Historic
a.[pa-acct-type] IN ('0','2','7','8') --AND --('0','2','7','8') AND 
--and a.[pa-fc] IN ('V','Y')
--AND c.[pa-ins-co-cd]='M'
--AND (d.[pa-ins-co-cd]='A' OR e.[pa-ins-co-cd]='A' OR f.[pa-ins-co-cd]='A')
--datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240' AND
AND ((c.[pa-ins-co-cd]='L'AND c.[pa-ins-plan-no]='76')
OR (d.[pa-ins-co-cd]='L' AND d.[pa-ins-plan-no]='76')
OR (e.[pa-ins-co-cd]='L' AND e.[pa-ins-plan-no]='76')
OR (f.[pa-ins-co-cd]='L' AND f.[pa-ins-plan-no]='76'))
AND a.[pa-adm-date] > '2013-12-31 23:59:59.000'
--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])='0'
--AND LEFT(a.[pa-pt-no-woscd],5)='99999'
--AND a.[PA-PT-NO-WOSCD]='1006669858'
--WHERE a.[pa-pt-no-woscd] in ('01010920323','01010876959','01010892099','01010902101','01010917335')
--WHERE [pa-unit-sts]='2'

--ORDER BY COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) desc--a.[pa-bal-acct-bal] desc 



UNION


SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No'
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no] as 'MRN'
,a.[pa-pt-name]
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) as 'Age_From_Discharge'
,CASE
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '0' and '30' THEN '1_0-30'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '31' and '60' THEN '2_31-60'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '61' and '90' THEN '3_61-90'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '91' and '120' THEN '4_91-120'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '121' and '150' THEN '5_121-150'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '151' and '180' THEN '6_151-180'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '181' and '210' THEN '7_181-210'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) between '211' and '240' THEN '8_211-240'
WHEN a.[pa-acct-type]<> 1 AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240' THEN '9_240+'
WHEN a.[pa-acct-type]= 1 THEN 'In House/DNFB'
ELSE ''
END as 'Age_Bucket'
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,a.[pa-bal-tot-pt-pay-amt] as 'Pt_Pay_Amt'
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money)) as 'Ins_Pay_Amt'
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) as 'Tot_Pay_Amt'

,CASE
WHEN a.[pa-acct-type] in ('0','2','4','6','7','8') THEN 'OP' --0=OP; 6=OP BAD DEBT; 7=OP HISTORIC
WHEN a.[pa-acct-type] in ('1','2','4','8') THEN 'IP'  --1=IP; 2=A/R; 4=I/P BAD DEBT; 8=I/P HISTORIC
ELSE ''
END AS 'PtAcct_Type'
,CASE
WHEN a.[pa-acct-type] in ('6','4') THEN 'Bad Debt'
WHEN a.[pa-dsch-date] is not null and a.[pa-acct-type]='1' THEN 'DNFB'
WHEN a.[pa-acct-type] = '1' THEN 'Inhouse'
ELSE 'A/R'
END as 'File'
,[pa-fc] as 'FC'
,CASE
WHEN [pa-fc]='1' THEN 'Bad Debt Medicaid Pending'
WHEN [pa-fc] in ('2','6') THEN 'Bad Debt AG'
WHEN [pa-fc]='3' THEN 'MCS'
WHEN [pa-fc]='4' THEN 'Bad Debt AG Legal'
WHEN [pa-fc]='5' THEN 'Bad Debt POM'
WHEN [pa-fc]='8' THEN 'Bad Debt AG Exchange Plans'
WHEN [pa-fc]='9' THEN 'Bad Debt'
WHEN [pa-fc]='A' THEN 'Commercial'
WHEN [pa-fc]='B' THEN 'Blue Cross'
WHEN [pa-fc]='C' THEN 'Champus'
WHEN [pa-fc]='D' THEN 'Medicaid'
WHEN [pa-fc]='E' THEN 'Employee Health Svc'
WHEN [pa-fc]='G' THEN 'Contract Accts'
WHEN [pa-fc]='H' THEN 'Medicare HMO'
WHEN [pa-fc]='I' THEN 'Balance After Ins'
WHEN [pa-fc]='J' THEN 'Managed Care'
WHEN [pa-fc]='K' THEN 'Pending Medicaid'
WHEN [pa-fc]='M' THEN 'Medicare'
WHEN [pa-fc]='N' THEN 'No-Fault'
WHEN [pa-fc]='P' THEN 'Self Pay'
WHEN [pa-fc]='S' THEN 'Special Billing'
WHEN [pa-fc]='U' THEN 'Medicaid Mgd Care'
WHEN [pa-fc]='V' THEN 'First Source'
WHEN [pa-fc]='W' THEN 'Workers Comp'
WHEN [pa-fc]='X' THEN 'Control Accts'
WHEN [pa-fc]='Y' THEN 'MCS'
WHEN [pa-fc]='Z' THEN 'Unclaimed Credits'
ELSE ''
END as 'FC_Description'
,[pa-hosp-svc]
,CASE
WHEN [PA-HOSP-SVC]='ABC' THEN 'Ambulatory Breast Care'
WHEN [PA-HOSP-SVC]='ABD' THEN 'ACC Breast Diagnosis'
WHEN [PA-HOSP-SVC]='ACA' THEN 'Amb Care Admit'
WHEN [PA-HOSP-SVC]='ACP' THEN 'Amb Cancer Provider'
WHEN [PA-HOSP-SVC]='ACU' THEN 'Discontinued AIDS'
WHEN [PA-HOSP-SVC]='ALG' THEN 'Allergy'
WHEN [PA-Hosp-svc]='ALL' THEN 'Allergy Rhematology'
WHEN [pa-hosp-svc]='ALS' THEN 'Amotroph Ltl Sclsis'
WHEN [pa-hosp-svc]='AND' THEN 'Andrology Lab'
WHEN [pa-hosp-svc]='ANT' THEN 'Antepartum Testing'
WHEN [pa-hosp-svc]='AOI' THEN ' Apnea Of Infancy'
WHEN [pa-hosp-svc]='APN' THEN 'Ambulatory Pain'
WHEN [pa-hosp-svc]='APP' THEN 'Ambulatory Pain Proc'
WHEN [pa-hosp-svc]='APV' THEN 'Adult Patient Visit'
WHEN [pa-hosp-svc]='ARI' THEN 'Ambulatory MRI'
WHEN [pa-hosp-svc]='ARP' THEN 'Anal Rectal Phsyiol'
WHEN [pa-hosp-svc]='ARY' THEN 'Ambulatory X-Ray'
WHEN [pa-hosp-svc]='ASC' THEN 'Ambulatory Surgery Center'
WHEN [pa-hosp-svc]='AUC' THEN 'Adult Urgent Care'
WHEN [pa-hosp-svc]='AUD' THEN 'Audiology'
WHEN [pa-hosp-svc]='AUT' THEN 'Autopsy'
WHEN [pa-hosp-svc]='AXP' THEN 'ACC Radiology Procedure'
WHEN [pa-hosp-svc]='BCK' THEN 'Back School'
WHEN [pa-hosp-svc]='BKO' THEN 'Back Other'
WHEN [pa-hosp-svc]='BLD' THEN 'MODQ'
WHEN [pa-hosp-svc]='BMD' THEN 'Osteoporosis'
WHEN [pa-hosp-svc]='BMT' THEN 'Bone Marow Trns'
WHEN [pa-hosp-svc]='BNL' THEN 'Brkhaven Nat Lab'
WHEN [pa-hosp-svc]='BRE' THEN 'Breast Center'
WHEN [pa-hosp-svc]='BRN' THEN 'Burn Center'
WHEN [pa-hosp-svc]='BRP' THEN 'Breast Procedure'
WHEN [pa-hosp-svc]='BRS' THEN 'Breast Surgery'
WHEN [pa-hosp-svc]='BUR' THEN 'Burn Unit For OPBC'
WHEN [pa-hosp-svc]='CAD' THEN 'Cardiology IP'
WHEN [pa-hosp-svc]='CAM' THEN 'Comp Alternative Med'
WHEN [pa-hosp-svc]='CAR' THEN 'Cardiology OP'
WHEN [pa-hosp-svc]='CCF' THEN 'Cleft Cranial Facial'
WHEN [pa-hosp-svc]='CCL' THEN 'Cody Center Life'
WHEN [pa-hosp-svc]='CCP' THEN 'Cody Center Patients'
WHEN [pa-hosp-svc]='CCU' THEN 'Coron ICU'
WHEN [pa-hosp-svc]='CDT' THEN 'Cardiothoracic'
WHEN [pa-hosp-svc]='CDY' THEN 'Cardiology'
WHEN [pa-hosp-svc]='COL' THEN 'Colo-rectal Oncology'
WHEN [pa-hosp-svc]='COU' THEN 'Anticoagulation'
WHEN [pa-hosp-svc]='CPT' THEN 'Cath Pre-Testing'
WHEN [pa-hosp-svc]='CPU' THEN 'Chest Pain Unit'
WHEN [pa-hosp-svc]='CRB' THEN 'Cardiac Rehab'
WHEN [pa-hosp-svc]='CRC' THEN 'GREC Grant OP'
WHEN [pa-hosp-svc]='CRD' THEN 'Cardiology Testing'
WHEN [pa-hosp-svc]='CRS' THEN 'Colorectal Surgery'
WHEN [pa-hosp-svc]='CRU' THEN 'GREC Grant IP'
WHEN [pa-hosp-svc]='CSA' THEN 'Ambulance'
WHEN [pa-hosp-svc]='CSS' THEN 'Short Stay Cardiac'
WHEN [pa-hosp-svc]='CTD' THEN 'Cadaver Donor'
WHEN [pa-hosp-svc]='CTH' THEN 'Cardiac Catheterization'
WHEN [pa-hosp-svc]='CTP' THEN 'Child Tech Park'
WHEN [pa-hosp-svc]='CUC' THEN 'Cardiac Urgent Care'
WHEN [pa-hosp-svc]='CVC' THEN 'Cerebrovascular Center'
WHEN [pa-hosp-svc]='CVU' THEN 'Cardio ICU'
WHEN [pa-hosp-svc]='CYT' THEN 'Cytogenics'
WHEN [pa-hosp-svc]='DBM' THEN 'Donor Bone Marrow'
WHEN [pa-hosp-svc]='DDP' THEN 'Development Disab Pt'
WHEN [pa-hosp-svc]='DEN' THEN 'Dental'
WHEN [pa-hosp-svc]='DER' THEN 'Dermatology'
WHEN [pa-hosp-svc]='DIA' THEN 'Dialysis'
WHEN [pa-hosp-svc]='DIB' THEN 'Diabetes OPD'
WHEN [pa-hosp-svc]='DIH' THEN 'Home Dialysis'
WHEN [pa-hosp-svc]='DIS' THEN 'Disaster Patient'
WHEN [pa-hosp-svc]='DNT' THEN 'Dental'
WHEN [pa-hosp-svc]='DOF' THEN 'Dialysis Outside Fac'
WHEN [pa-hosp-svc]='DON' THEN 'Dental Oncology'
WHEN [pa-hosp-svc]='DPA' THEN 'Dental Pathology'
WHEN [pa-hosp-svc]='DPC' THEN 'Dermatology Procedure'
WHEN [pa-hosp-svc]='DRM' THEN 'Dermatology Module'
WHEN [pa-hosp-svc]='DUV' THEN 'Dermatology UV Therapy'
WHEN [pa-hosp-svc]='ECG' THEN 'ECG'
WHEN [pa-hosp-svc]='ECT' THEN 'Electroconvulsive Therapy'
WHEN [pa-hosp-svc]='EDA' THEN 'ED Admission'
WHEN [pa-hosp-svc]='EDT' THEN 'ED Admissions/Billing'
WHEN [pa-hosp-svc]='EEC' THEN 'EECP Treatments'
WHEN [pa-hosp-svc]='EEG' THEN 'OPEG'
WHEN [pa-hosp-svc]='EHS' THEN 'Emp Health Svc'
WHEN [pa-hosp-svc]='ELC' THEN 'Amb Lung Cancer Eval'
WHEN [pa-hosp-svc]='ELI' THEN 'Eastern Long Island Hosp'
WHEN [pa-hosp-svc]='EMD' THEN 'Emergency Dental'
WHEN [pa-hosp-svc]='EMR' THEN 'Emergency'
WHEN [pa-hosp-svc]='EMS' THEN 'Emergency Med Serv'
WHEN [pa-hosp-svc]='EMT' THEN 'Ambulance'
WHEN [pa-hosp-svc]='ENC' THEN 'Endocrinology'
WHEN [pa-hosp-svc]='END' THEN 'Endocrine'
WHEN [pa-hosp-svc]='ENO' THEN 'Endoscopy'
WHEN [pa-hosp-svc]='ENT' THEN 'ENT'
WHEN [pa-hosp-svc]='EOB' THEN 'ED Observation'
WHEN [pa-hosp-svc]='EPS' THEN 'EP Lab'
WHEN [pa-hosp-svc]='EPX' THEN 'Emergency Spec Proc'
WHEN [pa-hosp-svc]='ESS' THEN 'Endoscopic Swallow Study'
WHEN [pa-hosp-svc]='EYE' THEN 'Eye'
WHEN [pa-hosp-svc]='FAM' THEN 'Family Medicine OP'
WHEN [pa-hosp-svc]='FMD' THEN 'Family Medicine IP'
WHEN [pa-hosp-svc]='FMN' THEN 'Family Med Newborn'
WHEN [pa-hosp-svc]='FMO' THEN 'Family Medicine Obs'
WHEN [pa-hosp-svc]='FMP' THEN 'Family Medicine Patchogue'
WHEN [pa-hosp-svc]='FNA' THEN 'Fine Needle Aspiration'
WHEN [pa-hosp-svc]='FOB' THEN 'FOB Family Med Obs'
WHEN [pa-hosp-svc]='FPD' THEN 'FPD Family Med Ped'
WHEN [pa-hosp-svc]='GAS' THEN 'Gastroenterology'
WHEN [pa-hosp-svc]='GEN' THEN 'General Medicine'
WHEN [pa-hosp-svc]='GER' THEN 'Geriatrics'
WHEN [pa-hosp-svc]='GFL' THEN 'Gift of Life'
WHEN [pa-hosp-svc]='GMA' THEN 'Gen Med Team A'
WHEN [pa-hosp-svc]='GMB' THEN 'Gen Med Team B'
WHEN [pa-hosp-svc]='GMC' THEN 'Gen Med Team C'
WHEN [pa-hosp-svc]='GMD' THEN 'Gen Med Team D'
WHEN [pa-hosp-svc]='GME' THEN 'Gen Med Team E'
WHEN [pa-hosp-svc]='GMF' THEN 'Gen Med Team F'
WHEN [pa-hosp-svc]='GMG' THEN 'Gen Med Team G'
WHEN [pa-hosp-svc]='GMH' THEN 'Gen Med Team H'
WHEN [pa-hosp-svc]='GMK' THEN 'Gen Med Team K'
WHEN [pa-hosp-svc]='GMW' THEN 'Gen Med Team W'
WHEN [pa-hosp-svc]='GMX' THEN 'Gen Med Flex'
WHEN [pa-hosp-svc]='GMY' THEN 'Gen Med Team Y'
WHEN [pa-hosp-svc]='GMZ' THEN 'Gen Med Team Z'
WHEN [pa-hosp-svc]='GNC' THEN 'Gyn-Oncology'
WHEN [pa-hosp-svc]='GNE' THEN 'Gynecology OP'
WHEN [pa-hosp-svc]='GNO' THEN 'Gynecology OP'
WHEN [pa-hosp-svc]='GNP' THEN 'Gyn Patchogue'
WHEN [pa-hosp-svc]='GON' THEN 'Ancology'
WHEN [pa-hosp-svc]='GSG' THEN 'General Surgery'
WHEN [pa-hosp-svc]='GSR' THEN 'General Surgery Red'
WHEN [pa-hosp-svc]='GST' THEN 'Gastroenterology'
WHEN [pa-hosp-svc]='GSW' THEN 'General Surgery White'
WHEN [pa-hosp-svc]='GSX' THEN 'General Surgery X'
WHEN [pa-hosp-svc]='GYN' THEN 'Gynecology'
WHEN [pa-hosp-svc]='HEM' THEN 'Hematology OP'
WHEN [pa-hosp-svc]='HMA' THEN 'Hematology IP'
WHEN [pa-hosp-svc]='HND' THEN 'Hand Surgery'
WHEN [pa-hosp-svc]='HOB' THEN 'Hospital Observation'
WHEN [pa-hosp-svc]='HSC' THEN 'Health Screening Cnt'
WHEN [pa-hosp-svc]='HTY' THEN 'Hand Therapy'
WHEN [pa-hosp-svc]='ICD' THEN 'Islandia Cardiology'
WHEN [pa-hosp-svc]='IGM' THEN 'Islandia General Med'
WHEN [pa-hosp-svc]='IGN' THEN 'Gyn Islip'
WHEN [pa-hosp-svc]='IMM' THEN 'IMM AIDS O/P'
WHEN [pa-hosp-svc]='IMU' THEN 'Discontinued AIDS I/P'
WHEN a.[pa-hosp-svc]='IND' THEN 'Infectious Diseases'
WHEN a.[pa-hosp-svc]='INF' THEN 'Infections Diseases'
WHEN a.[pa-hosp-svc]='INJ' THEN 'Injection'
WHEN a.[pa-hosp-svc]='IOB' THEN 'OB Islip'
WHEN a.[pa-hosp-svc]='IPD' THEN 'Peds Islip'
WHEN a.[pa-hosp-svc]='IPS' THEN 'Psych ER Observation'
WHEN a.[pa-hosp-svc]='IRC' THEN 'Intervent Rad Clinic'
WHEN a.[pa-hosp-svc]='ISC' THEN 'Islandia Congestive'
WHEN a.[pa-hosp-svc]='KAC' THEN 'Medicaid Anesth Pain'
WHEN a.[pa-hosp-svc]='KFM' THEN 'Medicaid Family Medicine'
WHEN a.[pa-hosp-svc]='KGY' THEN 'Medicaid Gynecology'
WHEN a.[pa-hosp-svc]='KMC' THEN 'Medicaid Cardiology'
WHEN a.[pa-hosp-svc]='KMG' THEN 'Medicaid Gastroenterology'
WHEN a.[pa-hosp-svc]='KMR' THEN 'Medicaid General Med'
WHEN a.[pa-hosp-svc]='KMS' THEN 'Medicaid Med Special'
WHEN a.[pa-hosp-svc]='KNE' THEN 'Medicaid Neurology'
WHEN a.[pa-hosp-svc]='KOB' THEN 'Medicaid Obstetrics'
WHEN a.[pa-hosp-svc]='KOP' THEN 'MEdicaid Opthamology'
WHEN a.[pa-hosp-svc]='KPC' THEN 'Medicaid Ped Cody Ct'
WHEN a.[pa-hosp-svc]='KPI' THEN 'Medicaid Ped Islip'
WHEN a.[pa-hosp-svc]='KPM' THEN 'Medicaid Ped E Moriches'
WHEN a.[pa-hosp-svc]='KPN' THEN 'Medicaid Pain'
WHEN a.[pa-hosp-svc]='KPP' THEN 'Medicaid Pain Procedure'
WHEN a.[pa-hosp-svc]='KPT' THEN 'Medicaid Ped Tech Park'
WHEN a.[pa-hosp-svc]='KPY' THEN 'Medicaid Psychiatry'
WHEN a.[pa-hosp-svc]='KSG' THEN 'Medicaid Surgery Service'
WHEN a.[pa-hosp-svc]='KUR' THEN 'Medicaid Urology'
WHEN a.[pa-hosp-svc]='LAB' THEN 'Lab Specimens'
WHEN a.[pa-hosp-svc]='LAD' THEN 'Labor and Delivery'
WHEN a.[pa-hosp-svc]='LCC' THEN 'Life Center at HB'
WHEN a.[pa-hosp-svc]='LCE' THEN 'Lung Cancer Eval'
WHEN a.[pa-hosp-svc]='LGD' THEN 'Lou Gehrigs Disease'
WHEN a.[pa-hosp-svc]='LID' THEN 'LIVH Day Care'
WHEN a.[pa-hosp-svc]='LIQ' THEN 'LI Queens Med Group'
WHEN a.[pa-hosp-svc]='LIV' THEN 'LI Vet Home'
WHEN a.[pa-hosp-svc]='LLT' THEN 'Leukemia Lymp Trnplt'
WHEN a.[pa-hosp-svc]='LRD' THEN 'Liv Rel Donor'
WHEN a.[pa-hosp-svc]='LSA' THEN 'LSARD'
WHEN a.[pa-hosp-svc]='LVD' THEN 'Left Ventric Ass Dev'
WHEN a.[pa-hosp-svc]='LYM' THEN 'Lymphedema Therapy'
WHEN a.[pa-hosp-svc]='MAS' THEN 'Maternity Amb Surgery'
WHEN a.[pa-hosp-svc]='MCU' THEN 'Medical ICU'
WHEN a.[pa-hosp-svc]='MEM' THEN 'Med East Moriches'
WHEN a.[pa-hosp-svc]='MET' THEN 'MTU O/P Research'
WHEN a.[pa-hosp-svc]='MIU' THEN 'Medical ICU 2'
WHEN a.[pa-hosp-svc]='MOL' THEN 'Med Oncology IP'
WHEN a.[pa-hosp-svc]='MON' THEN 'Med Oncology OP'
WHEN a.[pa-hosp-svc]='MOP' THEN 'Medical Oncology Proc'
WHEN a.[pa-hosp-svc]='MOT' THEN 'Motility Lab'
WHEN a.[pa-hosp-svc]='MPC' THEN 'Med Procedure'
WHEN a.[pa-hosp-svc]='MRI' THEN 'MRI'
WHEN a.[pa-hosp-svc]='MSC' THEN 'Misc Income'
WHEN a.[pa-hosp-svc]='MSS' THEN 'Short Stay Medicine'
WHEN a.[pa-hosp-svc]='MST' THEN 'Massage Therapy'
WHEN a.[pa-hosp-svc]='MTU' THEN 'Metabolic Treatment'
WHEN a.[pa-hosp-svc]='MUC' THEN 'Maternity Urgent Care'
WHEN a.[pa-hosp-svc]='NBN' THEN 'Non Burn'
WHEN a.[pa-hosp-svc]='NBS' THEN 'Neck, Back, Spine'
WHEN a.[pa-hosp-svc]='NCU' THEN 'Neurosurgical ICU'
WHEN a.[pa-hosp-svc]='NEP' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NER' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NES' THEN 'Neurosurgery'
WHEN a.[pa-hosp-svc]='NEU' THEN 'Neurology'
WHEN a.[pa-hosp-svc]='NEW' THEN 'Newborn'
WHEN a.[pa-hosp-svc]='NEY' THEN 'Neurology OP'
WHEN a.[pa-hosp-svc]='NMD' THEN 'NAtional Marrow Donor'
WHEN a.[pa-hosp-svc]='NNU' THEN 'Neonatal ICU'
WHEN a.[pa-hosp-svc]='NOP' THEN 'Nutrition OP'
WHEN a.[pa-hosp-svc]='NPH' THEN 'Nephrology IP'
WHEN a.[pa-hosp-svc]='NPT' THEN 'Neuro Psycholog Test'
WHEN a.[pa-hosp-svc]='NPY' THEN 'Nephrology OP'
WHEN a.[pa-hosp-svc]='NSO' THEN 'Neurosurgery Oncology'
WHEN a.[pa-hosp-svc]='NSP' THEN 'Neuro Special Proced'
WHEN a.[pa-hosp-svc]='NSY' THEN 'Tech PArk Neurosurg'
WHEN a.[pa-hosp-svc]='NTF' THEN 'Nutrit Target Fitnes'
WHEN a.[pa-hosp-svc]='NTN' THEN 'Nutritional Svcs OP'
WHEN a.[pa-hosp-svc]='NTR' THEN 'Non Transplant'
WHEN a.[pa-hosp-svc]='NUS' THEN 'Neurosurgery IP'
WHEN a.[pa-hosp-svc]='NVB' THEN 'Non-Viable Births'
WHEN a.[pa-hosp-svc]='OBE' THEN 'Obstetrics'
WHEN a.[pa-hosp-svc]='OBP' THEN 'OB Patchogue'
WHEN a.[pa-hosp-svc]='OBS' THEN 'Obstetrics IP'
WHEN a.[pa-hosp-svc]='OBT' THEN 'Obstetrics OP'
WHEN a.[pa-hosp-svc]='OCC' THEN 'Occupational Therapy'
WHEN a.[pa-hosp-svc]='OCM' THEN 'Occupational Med'
WHEN a.[pa-hosp-svc]='ODM' THEN 'Dermatology-Oncology'
WHEN a.[pa-hosp-svc]='OEM' THEN 'Outpat East Moriches'
WHEN a.[pa-hosp-svc]='OGN' THEN 'Amb Gyn Oncology'
WHEN a.[pa-hosp-svc]='OLL' THEN 'OP Leukemia Lymphoma'
WHEN a.[pa-hosp-svc]='OLR' THEN 'Otolaryngology'
WHEN a.[pa-hosp-svc]='OMH' THEN 'Ofc of Mental Health'
WHEN a.[pa-hosp-svc]='ONC' THEN 'Amb Surgic Oncolog'
WHEN a.[pa-hosp-svc]='OPH' THEN 'Opthamology'
WHEN a.[pa-hosp-svc]='ORC' THEN 'Orthoped Surg Oncol'
WHEN a.[pa-hosp-svc]='ORG' THEN 'Organ Retrieval'
WHEN a.[pa-hosp-svc]='ORT' THEN 'Orthopedics'





ELSE ''
END AS 'Hosp Svc Description'
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
,(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] as varchar)) as 'Ins1_Cd'
,(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] as varchar)) as 'Ins2_Cd'
,(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar)) as 'Ins3_Cd' 
,(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] as varchar)) as 'Ins4_Cd'
,g.[pa-dx2-code] as 'Prin_Dx'
,h.[pa-proc3-cd] as 'ICD_Prin_Proc'
,a.[pa-disch-dx-cd]
,a.[pa-disch-dx-cd-type]
,a.[pa-disch-dx-date]
,a.[PA-PROC-CD-TYPE(1)]
,a.[PA-PROC-CD(1)]
,a.[PA-PROC-DATE(1)]
,a.[pa-proc-prty(1)]
,a.[PA-PROC-CD-TYPE(2)]
,a.[PA-PROC-CD(2)]
,a.[PA-PROC-DATE(2)]
,a.[pa-proc-prty(2)]
,a.[PA-PROC-CD-TYPE(3)]
,a.[PA-PROC-CD(3)]
,a.[PA-PROC-DATE(3)]
,a.[pa-proc-prty(3)]
,c.[pa-bal-ins-pay-amt] as 'Pyr1_Pay_Amt'
,d.[pa-bal-ins-pay-amt] as 'Pyr2_Pay_Amt'
,e.[pa-bal-ins-pay-amt] as 'Pyr3_Pay_Amt'
,f.[pa-bal-ins-pay-amt] as 'Pyr4_Pay_Amt'

,c.[pa-last-ins-bl-date] as 'Pyr1_Last_Ins_Bl_Date'
,d.[pa-last-ins-bl-date] as 'Pyr2_Last_Ins_Bl_Date'
,e.[pa-last-ins-bl-date] as 'Pyr3_Last_Ins_Bl_Date'
,f.[pa-last-ins-bl-date] as 'Pyr4_Last_Ins_Bl_Date'
,a.[pa-last-fc-cng-date]
,i.[implant-charges]
,j.[OR-TIME]
,j.[OR-DOLLARS]
,k.[RECOVERY-TIME]
,k.[RECOVERY-DOLLARS]


FROM [Echo_Active].dbo.PatientDemographics a left outer join [Echo_Archive].dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1]
left outer join [Echo_Active].dbo.insuranceinformation c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'
left outer join [Echo_Active].dbo.insuranceinformation d
ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='2'
left outer join [Echo_Active].dbo.insuranceinformation e
ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='3'
left outer join [Echo_Active].dbo.insuranceinformation f
ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[pa-ins-prty]='4'
left outer join [Echo_Active].dbo.diagnosisinformation g
ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
left outer join [Echo_Active].dbo.ProcedureInformation h
ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd] and h.[pa-proc3-prty]='1' and h.[pa-proc3-cd-type] IN ('0','9')
left outer join dbo.[#Implant_Chgs] i
ON CAST(a.[pa-pt-no-woscd] as varchar)+CAST(a.[pa-pt-no-scd] as varchar)=i.[pa-pt-no]
left outer join dbo.[#OR_Time] j
ON CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd] as varchar)=j.[pa-pt-no]
left outer join dbo.[#Recovery_Time] K
ON CAST(a.[pa-pt-no-woscd] as varchar) +CAST(a.[pa-pt-no-scd] as varchar)=k.[pa-pt-no]
--left outer join dbo.detailinformation c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=c.[pa-pt-no-scd-1]

WHERE 

--a.[pa-fc]='D'
--AND a.[pa-acct-type]='0'--(a.[pa-acct-type] NOT IN ('4','6','7','8')--Active A/R; Excludes Bad Debt & Historic
a.[pa-acct-type] IN ('0','2','4','6','7','8') --AND --('0','2','7','8') AND 
--and a.[pa-fc] IN ('V','Y')
--AND c.[pa-ins-co-cd]='M'
--AND (d.[pa-ins-co-cd]='A' OR e.[pa-ins-co-cd]='A' OR f.[pa-ins-co-cd]='A')
--datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240' AND
AND ((c.[pa-ins-co-cd]='L'AND c.[pa-ins-plan-no]='76')
OR (d.[pa-ins-co-cd]='L' AND d.[pa-ins-plan-no]='76')
OR (e.[pa-ins-co-cd]='L' AND e.[pa-ins-plan-no]='76')
OR (f.[pa-ins-co-cd]='L' AND f.[pa-ins-plan-no]='76'))
AND a.[pa-adm-date] > '2013-12-31 23:59:59.000'
--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])='0'
--AND LEFT(a.[pa-pt-no-woscd],5)='99999'
--AND a.[PA-PT-NO-WOSCD]='1006669858'
--WHERE a.[pa-pt-no-woscd] in ('01010920323','01010876959','01010892099','01010902101','01010917335')
--WHERE [pa-unit-sts]='2'

--ORDER BY COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) desc--a.[pa-bal-acct-bal] desc 


