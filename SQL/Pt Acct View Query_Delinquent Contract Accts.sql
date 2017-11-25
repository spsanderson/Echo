USE [Echo_ACTIVE];

----------------------------------------------------------------------------------------------------------------------------------------------------
/*Create Temp Table With Last Ins Payment Date*/


IF OBJECT_ID('tempdb.dbo.#LastPaymentDates', 'U') IS NOT NULL
  DROP TABLE #LastPaymentDates; 
GO

CREATE TABLE #LastPaymentDates
(
[PA-PT-NO-WOSCD] DECIMAL(11,0) NOT NULL,
[PA-PT-NO-SCD] CHAR(1) NOT NULL,
[PA-INS-PRTY] DECIMAL(1,0) NULL,
[PA-INS-PLAN] CHAR(10) NULL,
[PA-LAST-INS-PAY-DATE] DATETIME NULL,
[LAST-INS-PAY-AMT] MONEY NULL, 
[RANK1] CHAR(1) NULL
);

INSERT INTO #LastPaymentDates([PA-PT-NO-WOSCD],[PA-PT-NO-SCD],[PA-INS-PRTY],[PA-INS-PLAN],[PA-LAST-INS-PAY-DATE],[LAST-INS-PAY-AMT],[RANK1])

SELECT A.[PA-PT-NO-WOSCD],
A.[PA-PT-NO-SCD-1],
B.[PA-INS-PRTY],
(LTRIM(RTRIM(B.[pa-ins-co-cd])) + CAST(LTRIM(RTRIM(B.[pa-ins-plan-no])) as char)) AS 'PA-INS-PLAN',
B.[PA-LAST-INS-PAY-DATE],
B.[PA-BAL-INS-PAY-AMT],
RANK() OVER (PARTITION BY A.[PA-PT-NO-WOSCD] ORDER BY B.[PA-LAST-INS-PAY-DATE] DESC) AS 'RANK1'

FROM DBO.PATIENTDEMOGRAPHICS A LEFT OUTER JOIN DBO.INSURANCEINFORMATION B
ON A.[PA-PT-NO-WOSCD]=B.[PA-PT-NO-WOSCD]

WHERE [PA-BAL-INS-PAY-AMT]<> '0';



SELECT cast(a.[PA-PT-NO-WOSCD] AS VARCHAR) + cast(a.[PA-PT-NO-SCD] AS VARCHAR) AS 'Pt_No'
,b.[PA-UNIT-NO]
,a.[pa-med-rec-no] as 'MRN'
,a.[pa-pt-name]
,COALESCE(DATEADD(DAY,1,EOMONTH(b.[pa-unit-date],-1)),[pa-adm-date]) as 'Admit_Date'
,CASE WHEN a.[pa-acct-type]<> 1 THEN COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date])
ELSE a.[pa-dsch-date]
END as 'Dsch_Date'
,b.[pa-unit-date]
,CASE 
WHEN a.[pa-acct-type]<>'1' THEN datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) 
ELSE ''
END as 'Age_From_Discharge'
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
,a.[pa-acct-type]
,COALESCE(b.[pa-unit-op-first-ins-bl-date],a.[pa-final-bill-date],a.[pa-op-first-ins-bl-date]) as '1st_Bl_Date'
,COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) as 'Balance'
,COALESCE(b.[pa-unit-pt-bal],a.[pa-bal-pt-bal]) as 'Pt_Balance'
,COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) as 'Tot_Chgs'
,a.[pa-bal-tot-pt-pay-amt] 
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
WHEN [pa-fc]='9' THEN 'Kopp-Bad Debt'
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
WHEN [pa-fc]='R' THEN 'Aergo Commercial'
WHEN [pa-fc]='T' THEN 'RTR WC NF'
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
WHEN a.[pa-hosp-svc]='OSR' THEN 'Ortho Surgery'
WHEN a.[pa-hosp-svc]='OTH' THEN 'Orthopedics'
WHEN a.[pa-hosp-svc]='OTP' THEN 'Tech Park Orthopedic'
WHEN a.[pa-hosp-svc]='OUR' THEN 'Amb Urology Oncology'
WHEN a.[pa-hosp-svc]='OUT' THEN 'OP Lab Testing'
WHEN a.[pa-hosp-svc]='PAT' THEN 'Preadmit Test'
WHEN a.[pa-hosp-svc]='PCH' THEN 'OP Psychiatry'
WHEN a.[pa-hosp-svc]='PCT' THEN 'Pediatric Cardiac IP'
WHEN a.[pa-hosp-svc]='PCU' THEN 'Pediatric ICU'
WHEN a.[pa-hosp-svc]='PCY' THEN 'OP Child Psych'
WHEN a.[pa-hosp-svc]='PDP' THEN 'OP Peds Patchogue'
WHEN a.[pa-hosp-svc]='PDS' THEN 'OP Pediatrics'
WHEN a.[pa-hosp-svc]='PEA' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PED' THEN 'IP Pediatrics'
WHEN a.[pa-hosp-svc]='PEM' THEN 'Peds East Moriches'
WHEN a.[pa-hosp-svc]='PES' THEN 'Psych ER'
WHEN a.[pa-hosp-svc]='PET' THEN 'Psych Ed Admit/Bill'
WHEN a.[pa-hosp-svc]='PFM' THEN 'TP Family Med'
WHEN a.[pa-hosp-svc]='PFT' THEN 'OPPF'
WHEN a.[pa-hosp-svc]='PGM' THEN 'TP General Med'
WHEN a.[pa-hosp-svc]='PGY' THEN 'TP OB/Gyn Med'
WHEN a.[pa-hosp-svc]='PHO' THEN 'IP Ped Hematology/Oncology'
WHEN a.[pa-hosp-svc]='PHU' THEN 'Ped Hematology Int C'
WHEN a.[pa-hosp-svc]='PHY' THEN 'Physical Therapy'
WHEN a.[pa-hosp-svc]='PIC' THEN 'IP Pulmonary Inter Care'
WHEN a.[pa-hosp-svc]='PIM' THEN 'OP Ped AIDS Visit'
WHEN a.[pa-hosp-svc]='PIN' THEN 'Pediatric Trasfus/Infus'
WHEN a.[pa-hosp-svc]='PLB' THEN 'OP Ped Pulmonary'
WHEN a.[pa-hosp-svc]='PLM' THEN 'IP Pulmonary'
WHEN a.[pa-hosp-svc]='PLY' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='PMA' THEN 'Pain Management Anes'
WHEN a.[pa-hosp-svc]='PMM' THEN 'Ped AIDS OP'
WHEN a.[pa-hosp-svc]='PSG' THEN 'IP Pediatric Surgery'
WHEN a.[pa-hosp-svc]='PSP' THEN 'Pediatric Special Procedures'
WHEN a.[pa-hosp-svc]='PSR' THEN 'Pediatric Surgery OP'
WHEN a.[pa-hosp-svc]='PSS' THEN 'Pediatric Short Stay OP'
WHEN a.[pa-hosp-svc]='PST' THEN 'Pre-Surgical Test'
WHEN a.[pa-hosp-svc]='PSY' THEN 'IP Psychiatry'
WHEN a.[pa-hosp-svc]='PTP' THEN 'Peds Tech Park'
WHEN a.[pa-hosp-svc]='PTR' THEN 'Post Transplant'
WHEN a.[pa-hosp-svc]='PUC' THEN 'OP Ped Urgent Care'
WHEN a.[pa-hosp-svc]='PUL' THEN 'OP Pulmonary'
WHEN a.[pa-hosp-svc]='RAD' THEN 'Radiation IP'
WHEN a.[pa-hosp-svc]='RAN' THEN 'Radiology Anesthesia OP'
WHEN a.[pa-hosp-svc]='RAS' THEN 'Research Anesthesia OP'
WHEN a.[pa-hosp-svc]='RCA' THEN 'Research Cancer OP'
WHEN a.[pa-hosp-svc]='RCM' THEN 'Radiology Commack OP'
WHEN a.[pa-hosp-svc]='RCP' THEN 'Research Child Psych OP'
WHEN a.[pa-hosp-svc]='RCV' THEN 'Rad Consult Visit'
WHEN a.[pa-hosp-svc]='RDA' THEN 'Rad Onc Amb Cancer Center'
WHEN a.[pa-hosp-svc]='RDM' THEN 'Research Dermatology'
WHEN a.[pa-hosp-svc]='RDO' THEN 'OP Rad Oncology'
WHEN a.[pa-hosp-svc]='REH' THEN 'IP Rehab'
WHEN a.[pa-hosp-svc]='RFM' THEN 'Research Family Medicine'
WHEN a.[pa-hosp-svc]='RHU' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RHY' THEN 'Rheumatology'
WHEN a.[pa-hosp-svc]='RIS' THEN 'IP Radiology Inverventional Svc'
WHEN a.[pa-hosp-svc]='RME' THEN 'Research Medicine'
WHEN a.[pa-hosp-svc]='RNE' THEN 'Research Neurology'
WHEN a.[pa-hosp-svc]='RNS' THEN 'Research Neurosurgery'
WHEN a.[pa-hosp-svc]='ROG' THEN 'Research OB/GYN'
WHEN a.[pa-hosp-svc]='ROP' THEN 'Research Opthamology'
WHEN a.[pa-hosp-svc]='ROR' THEN 'Research Orthopedics'
WHEN a.[pa-hosp-svc]='RPC' THEN 'OP Radiology Procedure'
WHEN a.[pa-hosp-svc]='RPE' THEN 'Research Pediatrics'
WHEN a.[pa-hosp-svc]='RPF' THEN 'Research Pulmonary Function'
WHEN a.[pa-hosp-svc]='RPM' THEN 'Research Preventative Medicine'
WHEN a.[pa-hosp-svc]='RPS' THEN 'Research Psych'
WHEN a.[pa-hosp-svc]='RRC' THEN 'Risk Reduction Center'
WHEN a.[pa-hosp-svc]='RRD' THen 'Research Radiology'
WHEN a.[pa-hosp-svc]='RSH' THEN 'Research'
WHEN a.[pa-hosp-svc]='RSR' THEN 'Research Surgery'
WHEN a.[pa-hosp-svc]='RTP' THEN 'Referred to TP'
WHEN a.[pa-hosp-svc]='RTR' THEN 'IP Recipient'
WHEN a.[pa-hosp-svc]='RUM' THEN 'IP Reheumatology'
WHEN a.[pa-hosp-svc]='RUR' THEN 'OP Research Urology'
WHEN a.[pa-hosp-svc]='SAT' THEN 'Satellite Lab'
WHEN a.[pa-hosp-svc]='SBC' Then 'Survivor Breast Center'
WHEN a.[pa-hosp-svc]='SBR' THEN 'OP Stony Brook Radiology'
WHEN a.[pa-hosp-svc]='SBS' THEN 'Skull Based Sur'
WHEN a.[pa-hosp-svc]='SCT' THEN 'Stem Cell Transplant'
WHEN a.[pa-hosp-svc]='SCU' THEN 'Surgical ICU'
WHEN a.[pa-hosp-svc]='SDA' THEN 'SDS Admit OP'
WHEN a.[pa-hosp-svc]='SDO' THEN 'Sleep Disorders'
WHEN a.[pa-hosp-svc]='SDS' THEN 'Amb Surgery'
WHEN a.[pa-hosp-svc]='SDZ' THEN 'Sleep Disorder Study'
WHEN a.[pa-hosp-svc]='SED' THEN 'OP Sedation'
WHEN a.[pa-hosp-svc]='SGP' THEN 'OP Surgery Ped'
WHEN a.[pa-hosp-svc]='SGY' THEN 'OP Surgery'
WHEN a.[pa-hosp-svc]='SHH' THEN 'OP Southampton'
WHEN a.[pa-hosp-svc]='SKL' THEN 'Skull'
WHEN a.[pa-hosp-svc]='SLM' THEN 'OP Sleep Medicine'
WHEN a.[pa-hosp-svc]='SLP' THEN 'Speech Lang Path'
WHEN a.[pa-hosp-svc]='SON' THEN 'Surgical Oncology'
WHEN a.[pa-hosp-svc]='SOP' THEN 'OP Surg Oncology Procedure'
WHEN a.[pa-hosp-svc]='SPC' THEN 'Special Surgery'
WHEN a.[pa-hosp-svc]='SPF' THEN 'Surgical Pathology FNA'
WHEN a.[pa-hosp-svc]='SPP' THEN 'Sched Preadmit Proc'
WHEN a.[pa-hosp-svc]='SPS' THEN 'Stony Brook Psych OP'
WHEN a.[pa-hosp-svc]='SRG' THEN 'Outpatient Surgery'
WHEN a.[pa-hosp-svc]='SRP' THEN 'Surgery Patchogue'
WHEN a.[pa-hosp-svc]='SRY' THEN 'Spine X-Ray'
WHEN a.[pa-hosp-svc]='SSD' THEN 'Surgical Step Down'
WHEN a.[pa-hosp-svc]='SSG' THEN 'Sleep Surgery OP'
WHEN a.[pa-hosp-svc]='SSS' THEN 'Short Stay Surgery OP'
WHEN a.[pa-hosp-svc]='STU' THEN 'SHSC'
WHEN a.[pa-hosp-svc]='STY' THEN 'Spine Therapy OP'
WHEN a.[pa-hosp-svc]='SWS' THEN 'Social Worker OP'
WHEN a.[pa-hosp-svc]='TCU' THEN 'Trauma Adult IC'
WHEN a.[pa-hosp-svc]='TEE' THEN 'Transesophageal Echo'
WHEN a.[pa-hosp-svc]='TEG' THEN 'T.P. Elect Encarogram'
WHEN a.[pa-hosp-svc]='TGS' THEN 'Tech Park Gastroenterology'
WHEN a.[pa-hosp-svc]='TIP' THEN 'Transfusion/Infusion'
WHEN a.[pa-hosp-svc]='TIS' THEN 'OP Tissue Types'
WHEN a.[pa-hosp-svc]='TNS' THEN 'Trauma Neurosurgery'
WHEN a.[pa-hosp-svc]='TOR' THEN 'Trauma Orthopedics'
WHEN a.[pa-hosp-svc]='TPD' THEN 'Trauma Pediatrics'
WHEN a.[pa-hosp-svc]='TPL' THEN 'Tech Park Plast Surg'
WHEN a.[pa-hosp-svc]='TPN' THEN 'Tech Park Pain'
WHEN a.[pa-hosp-svc]='TPS' THEN 'Tech Park Psych'
WHEN a.[pa-hosp-svc]='TPT' THEN 'Tech Park Therapy'
WHEN a.[pa-hosp-svc]='TPU' THEN 'Trauma Ped I.C.'
WHEN a.[pa-hosp-svc]='TSB' THEN 'Trauma Surgery Blue'
WHEN a.[pa-hosp-svc]='TSG' THEN 'Trauma Surgery Green'
WHEN a.[pa-hosp-svc]='TSR' THEN 'Trauma Surgery'
WHEN a.[pa-hosp-svc]='TST' THEN 'Prod Testing Service'
WHEN a.[pa-hosp-svc]='TTS' THEN 'Transplant Test Svc'
WHEN a.[pa-hosp-svc]='TUR' THEN 'Urology'
WHEN a.[pa-hosp-svc]='ULT' THEN 'Unrelat Living Donor IP'
WHEN a.[pa-hosp-svc]='URL' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URO' THEN 'Urology'
WHEN a.[pa-hosp-svc]='URP' THEN 'Urology Patchogue'
WHEN a.[pa-hosp-svc]='VAS' THEN 'Vascular'
WHEN a.[pa-hosp-svc]='VCL' THEN 'Virtual Colonoscopy'
WHEN a.[pa-hosp-svc]='VPL' THEN 'Pulmonary Vent IP'
WHEN a.[pa-hosp-svc]='VSG' THEN 'Vascular Surgery'
WHEN a.[pa-hosp-svc]='VSP' THEN 'Vascular Special Procedure OP'
WHEN a.[pa-hosp-svc]='WLS' THEN 'Weight Loss Surgery IP'
WHEN a.[pa-hosp-svc]='XPC' THEN 'Radiology Procedures OP'
WHEN a.[pa-hosp-svc]='XRY' THEN 'X-Ray'
WHEN a.[pa-hosp-svc]='YOG' THEN 'Yoga Instruction'
WHEN a.[pa-hosp-svc]='ZOO' THEN 'Outpatient Offsite'
ELSE ''
END AS 'Hosp Svc Description'
,a.[pa-acct-sub-type]  --D=Discharged; I=In House
,(c.[pa-ins-co-cd] + CAST(c.[pa-ins-plan-no] as varchar)) as 'Ins1_Cd'
,(d.[pa-ins-co-cd] + CAST(d.[pa-ins-plan-no] as varchar)) as 'Ins2_Cd'
,(e.[pa-ins-co-cd] + CAST(e.[pa-ins-plan-no] as varchar)) as 'Ins3_Cd' 
,(f.[pa-ins-co-cd] + CAST(f.[pa-ins-plan-no] as varchar)) as 'Ins4_Cd'
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
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money)) as 'Ins_Pay_Amt'
,(CAST(ISNULL(c.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(d.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(e.[pa-bal-ins-pay-amt],0) as money) + CAST(ISNULL(f.[pa-bal-ins-pay-amt],0) as money))+ CAST(ISNULL(a.[pa-bal-tot-pt-pay-amt],0) as money) as 'Tot_Pay_Amt'
,a.[pa-last-fc-cng-date]
--,h.[pa-cwi-seg-create-date] as 'CW_Post_Date'
--,(h.[pa-cwi-pyr-co-cd] + CAST([pa-cwi-pyr-plan-no] as varchar)) as 'CWI_Pyr_Cd'
--,h.[pa-cwi-last-wklst-id] as 'CW_Last_Worklist'
----,CASE
----WHEN h.[pa-cwi-last-actv-date]='1900-01-01 00:00:00.000' THEN ''
----ELSE 
--,h.[pa-cwi-last-actv-date] 
----END AS 'CW_Last_Activty_Date'
--,h.[pa-cwi-last-actv-cd] as 'CW_Last_Actvity_Cd'
--,h.[pa-cwi-last-actv-coll-id] as 'CW_Last_Collector_ID'
--,h.[pa-cwi-next-fol-date] as 'CW_Next_Followup_Date'
--,h.[pa-cwi-next-wklst-id] as 'CW_Next_Wrklst_ID'
,a.[pa-pt-representative] as 'Rep_Code'
,a.[pa-resp-cd] as 'Resp_Code'
,a.[pa-cr-rating] as 'Credit Rating'
,a.[pa-courtesy-allow]
,a.[pa-last-actv-date] as 'Last_Charge_Svc_Date'
,a.[pa-last-pt-pay-date]
,c.[pa-last-ins-pay-date]
,a.[pa-no-of-cwi] as 'No_Of_CW_Segments'
,a.[pa-pay-scale]
,a.[pa-stmt-cd]
,a.[pa-ctrct-ind]
,a.[pa-ctrct-amt]
,a.[pa-ctrct-date]
,j.*



FROM dbo.PatientDemographics a left outer join dbo.unitizedaccounts b
ON a.[pa-pt-no-woscd]=b.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=b.[pa-pt-no-scd-1] 
left outer join dbo.insuranceinformation c
ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and c.[pa-ins-prty]='1'
left outer join dbo.insuranceinformation d
ON a.[pa-pt-no-woscd]=d.[pa-pt-no-woscd] and d.[pa-ins-prty]='2'
left outer join dbo.insuranceinformation e
ON a.[pa-pt-no-woscd]=e.[pa-pt-no-woscd] and e.[pa-ins-prty]='3'
left outer join dbo.insuranceinformation f
ON a.[pa-pt-no-woscd]=f.[pa-pt-no-woscd] and f.[pa-ins-prty]='4'
left outer join dbo.diagnosisinformation g
ON a.[pa-pt-no-woscd]=g.[pa-pt-no-woscd] and g.[pa-dx2-prio-no]='1' and g.[pa-dx2-type1-type2-cd]='DF'
left outer join dbo.[#LastPaymentDates] j
ON a.[pa-pt-no-woscd]=j.[pa-pt-no-woscd] and j.[rank1]='1'
--left outer join 
--(SELECT [pa-pt-no-woscd],[pa-cwi-seg-create-date],[pa-cwi-pyr-co-cd],[pa-cwi-pyr-plan-no],[pa-cwi-last-wklst-id],[pa-cwi-last-dmnd-fol-date],[pa-cwi-last-actv-date],[pa-cwi-last-actv-cd],[pa-cwi-last-actv-coll-id],[pa-cwi-next-fol-date],[pa-cwi-next-wklst-id]
--FROM dbo.CollectorWorkStation aa
--WHERE [pa-cwi-seg-create-date]=(select max([pa-cwi-seg-create-date]) FROM dbo.CollectorWorkStation bb WHERE aa.[pa-pt-no-woscd]=bb.[pa-pt-no-woscd])
--) h
--ON a.[pa-pt-no-woscd]=h.[pa-pt-no-woscd]
 
--left outer join dbo.detailinformation c
--ON a.[pa-pt-no-woscd]=c.[pa-pt-no-woscd] and a.[pa-pt-no-scd]=c.[pa-pt-no-scd-1]

WHERE 
---(a.[pa-pt-representative] is not null AND not(a.[pa-pt-representative] IN ('','000'))
 --a.[pa-acct-type] NOT IN ('4','6')
 --AND a.[pa-op-first-ins-bl-date] > '5/26/2017'
 a.[pa-ctrct-ind] IN ('D','1','2')
 AND [pa-ctrct-amt] > '0'
 --c.[pa-ins-co-cd]='J'
-- AND c.[pa-ins-plan-no]='18'
--AND COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal])<> '0'
AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) <> '0'
AND COALESCE(b.[pa-unit-tot-chg-amt],a.[pa-bal-tot-chg-amt]) <> '0'
--AND a.[pa-pt-representative] NOT IN ('530','531','532')
--AND a.[pa-fc] NOT IN ('V','Y')
--AND a.[pa-pt-no-woscd]='1009394875'
----a.[pa-fc]='D'
----AND a.[pa-acct-type]='0'--(a.[pa-acct-type] NOT IN ('4','6','7','8')--Active A/R; Excludes Bad Debt & Historic
--a.[pa-acct-type] IN ('6','4')--('0','2')--,'7','8') --AND --('0','2','7','8') AND 
--AND a.[pa-fc]='9'
--a.[pa-fc] IN ('V','Y')
--AND c.[pa-ins-co-cd]='M'
--AND (d.[pa-ins-co-cd]='A' OR e.[pa-ins-co-cd]='A' OR f.[pa-ins-co-cd]='A')
--AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) > '240'
--AND c.[pa-ins-co-cd]='L'
--AND c.[pa-ins-plan-no]='76'
--AND COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) > '99999.99'
--[pa-stmt-cd]='N'
--COALESCE((b.[pa-unit-ins1-bal] + b.[pa-unit-ins2-bal] + b.[pa-unit-ins3-bal]+b.[pa-unit-ins4-bal]+b.[pa-unit-pt-bal]),a.[pa-bal-acct-bal]) <> '0.00'
--AND c.[pa-ins-co-cd] is null--AND (datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) >'365' 
--a.[pa-fc]='X'
--AND datediff(day,COALESCE(b.[pa-unit-date],a.[pa-dsch-date],a.[pa-adm-date]),getdate()) < '731') 
--AND LEFT(a.[pa-pt-no-woscd],5)<>'99999'
--AND a.[PA-PT-NO-WOSCD]='1006669858'
--WHERE a.[pa-pt-no-woscd] in ('01010920323','01010876959','01010892099','01010902101','01010917335')
--WHERE [pa-unit-sts]='2'

--ORDER BY COALESCE(ISNULL(c.[pa-bal-ins-pay-amt],0)+ ISNULL(d.[pa-bal-ins-pay-amt],0) + ISNULL(e.[pa-bal-ins-pay-amt],0) + ISNULL(f.[pa-bal-ins-pay-amt],0)+ ISNULL(a.[pa-bal-tot-pt-pay-amt],0),a.[pa-bal-acct-bal]) desc--a.[pa-bal-acct-bal] desc 

ORDER BY [pa-pt-name]