
WITH PAY_PERIOD AS(
SELECT
MIN(TO_CHAR(PTP.START_DATE,'YYYY/MM/DD')) PTP_START_DATE,
MAX(TO_CHAR(PTP.END_DATE,'YYYY/MM/DD')) PTP_END_DATE,
PPASG.HR_ASSIGNMENT_ID
FROM
PAY_TIME_PERIODS  PTP,
PAY_ALL_PAYROLLS_F PAP,
PAY_PAYROLL_ASSIGNMENTS PPASG
WHERE 1=1
AND PTP.PAYROLL_ID = PAP.PAYROLL_ID
AND TRUNC(SYSDATE) BETWEEN PAP.EFFECTIVE_START_DATE AND PAP.EFFECTIVE_END_DATE
AND PTP.PERIOD_CATEGORY = 'E'
AND PTP.START_DATE BETWEEN TRUNC(SYSDATE)-84 AND TRUNC(SYSDATE)+28
GROUP BY PPASG.HR_ASSIGNMENT_ID
),

MEM_GRP AS (select grp1.group_name,

mem1.effective_end_date,
paam1.assignment_id,
paam1.effective_start_date asg_start_date,
paam1.person_id
from 
PER_ASSIGNMENT_SECURED_LIST_V paam1,
hwm_grp_members_f mem1,
hwm_grps_vl grp1
where
paam1.person_id = mem1.member_id
and grp1.grp_id = mem1.grp_id
and paam1.assignment_type in ('E') 
and TRUNC(paam1.effective_end_date) between mem1.effective_start_date and mem1.effective_end_date   /*Wave 3 Change*/
and trunc(paam1.last_update_date) = TRUNC(SYSDATE)
and paam1.effective_start_date = (select max(p.effective_start_date) from PER_ASSIGNMENT_SECURED_LIST_V p 
where paam1.assignment_id = p.assignment_id 
and p.effective_start_date <> ( select max(effective_start_date) from PER_ASSIGNMENT_SECURED_LIST_V 
where assignment_id = p.assignment_id and assignment_type in ('E'))
)

UNION
select grp2.group_name,
mem2.effective_end_date,
paam2.assignment_id,
paam2.effective_start_date asg_start_date,
paamNew.person_id
from 
PER_ASSIGNMENT_SECURED_LIST_V paam2,
hwm_grp_members_f mem2,
hwm_grps_vl grp2,
PER_ASSIGNMENT_SECURED_LIST_V paamNew
where
paamNew.person_id = paam2.person_id
and grp2.grp_id = mem2.grp_id
and TRUNC(paamNew.last_update_date) = TRUNC(SYSDATE)
and paam2.assignment_status_type = 'ACTIVE'
and paam2.assignment_type in ('E') /*Wave 3 Change*/
and paamNew.action_code IN  ('ABC_GLOBAL_TRANSFER_NO_PAY_CHG','ABC_GLOBAL_TRANSFER_PAY_CHANGE', 'REHIRE' ,'HIRE','HIRE_ADD_WORK_RELATION')
and paam2.effective_start_date = (select max(p.effective_start_date) from PER_ASSIGNMENT_SECURED_LIST_V p where paam2.person_id = p.person_id 
and p.assignment_type in ('E') and  p.assignment_status_type = 'ACTIVE' /*Wave 3 Change*/
and paamNew.EFFECTIVE_START_DATE >= p.effective_start_date
and paamNew.EFFECTIVE_START_DATE >= p.effective_end_date
)
and paamNew.EFFECTIVE_START_DATE >= paam2.effective_start_date
and paamNew.EFFECTIVE_START_DATE >= paam2.effective_end_date
and paamNew.assignment_type in ('E')
and paam2.person_id = mem2.member_id
/* and TRUNC(mem2.effective_end_date) between paam2.effective_start_date and paam2.effective_end_date */
and TRUNC(paam2.effective_end_date) between mem2.effective_start_date and mem2.effective_end_date  /*Wave 3 Change*/
AND paamNew.assignment_status_type = 'ACTIVE'
)


SELECT  

'1' AS KEY,
HGT.GROUP_NAME  HCM_GROUP,
TO_CHAR(HGMF.EFFECTIVE_START_DATE, 'YYYY/MM/DD') MEM_EFFECTIVE_START_DATE,
TO_CHAR(HGMF.EFFECTIVE_END_DATE, 'YYYY/MM/DD') MEM_EFFECTIVE_END_DATE,
HGMF.LAST_UPDATED_BY,
TO_CHAR(HGMF.LAST_UPDATE_DATE,'YYYY/MM/DD') LAST_UPDATE_DATE,
HSPTL_PROCC_PRFL.NAME WORKER_TIME_PROCESSING_PROFILE,
HSPTL_TIMEENTRY_PRFL.NAME WORKER_TIME_ENTRY_PROFILE,
PAPF.PERSON_ID PERSON_ID,
PAPF.PERSON_NUMBER PERSON_NUMBER,
PPNF.FULL_NAME EMPLOYEE_NAME,
PAAF.EMPLOYMENT_CATEGORY EMPLOYMENT_CATEGORY,
TO_CHAR(PPOS.DATE_START, 'YYYY/MM/DD') HIRE_DATE,
TO_CHAR(PPOS.ACTUAL_TERMINATION_DATE, 'YYYY/MM/DD') TERMINATION_DATE,
HL1.MEANING UNION_MEMBER,
PJF.JOB_CODE JOB_CODE,
PJFTL.NAME JOB_NAME,
PD.NAME DEPARTMENT_NAME,
POIF.ORG_INFORMATION1 DEPT_AUT_NON_AUT,
PASTL.USER_STATUS ASSIGNMENT_STATUS,
PAAF.BARGAINING_UNIT_CODE BARGAINING_UNIT_CODE,
PAAF.ASSIGNMENT_ID ASSIGNMENT_ID,
DECODE(PAAF.ASSIGNMENT_TYPE, 'E', 'Employee', PAAF.ASSIGNMENT_TYPE) ASSIGNMENT_TYPE,
PAAF.FULL_PART_TIME FULL_PART_TIME,
PAAF.ASSIGNMENT_NUMBER ASSIGNMENT_NUMBER,
HL2.MEANING MANAGER_FLAG,
FVB.DESCRIPTION CLERICAL_PHYSICAL,
HL.MEANING HOURLY_SALARIED_CODE,
LOCATIONS.LOCATION_NAME LOCATION_NAME,
LOCATIONS.INTERNAL_LOCATION_CODE LOCATION_CODE,
LOCATIONS.REGION_2 LOCATION_STATE,
BU.BU_NAME BUSINESS_UNIT_NAME,
PGFTL.NAME GRADE_NAME,
PLE.NAME LEGAL_EMPLOYER_NAME,
PAY_PERIOD.PTP_START_DATE PTP_START_DATE,
PAY_PERIOD.PTP_END_DATE PTP_END_DATE,
CASE WHEN ( select max(TE_TM_REC_ID) from HWM_TM_RPT_ENTRY_V htre where
htre.resource_id = PAAF.person_id
and trunc(htre.TE_START_TIME) between MEM_GRP.asg_start_date and PAAF.effective_end_date
and (TC_DELETE_FLAG ='N' ) AND (TC_LATEST_VERSION = 'Y')
and ANC_LATEST_VERSION = 'Y' AND ANC_DELETE_FLAG = 'N'
AND (TE_DELETE_FLAG ='N') AND (TE_LATEST_VERSION = 'Y' )   
) is NOT NULL then 'Y' else 'N' end TimeCard_Available,
PAP.PAYROLL_NAME, /*Wave 3 Change*/
PJF.ATTRIBUTE2 UNION_GROUP /*Wave 3 Change*/
FROM 
PER_PERSON_SECURED_LIST_V PAPF,
PER_ASSIGNMENT_SECURED_LIST_V PAAF,
PER_PERSON_NAMES_F PPNF,
PER_PERIODS_OF_SERVICE PPOS,
PER_JOBS_F PJF,
PER_JOBS_F_TL PJFTL,
PER_DEPARTMENTS PD,
HR_ORGANIZATION_INFORMATION_F POIF,
FUSION.FUN_ALL_BUSINESS_UNITS_V BU,
HR_LOCATIONS_ALL_F_VL LOCATIONS,
PER_LEGAL_EMPLOYERS PLE,
PER_GRADES_F PGF,
PER_GRADES_F_TL PGFTL,
PER_ASSIGNMENT_STATUS_TYPES_TL PASTL,
HWM_GRP_MEMBERS_F HGMF,
HCM_LOOKUPS HL,
HCM_LOOKUPS HL1,
HCM_LOOKUPS HL2,
FND_VS_VALUE_SETS FVS,
FND_VS_VALUES_VL FVB,
HWM_GRPS_TL HGT, 
HXT_SETUP_PROFILES_B HSPB_PROCC_PRFL,
HXT_SETUP_PROFILES_TL HSPTL_PROCC_PRFL,
HXT_SETUP_PROFILES_B HSPB_TIMEENTRY_PRFL,
HXT_SETUP_PROFILES_TL HSPTL_TIMEENTRY_PRFL,
HXT_SETUP_PROFILE_ASGS HSPA_PROCC,
HXT_SETUP_PROFILE_ASGS HSPA_TIMEENTRY,
PAY_PERIOD PAY_PERIOD,
MEM_GRP,
PAY_ASSIGNED_PAYROLLS_DN PAPDN, /*Wave 3 Change*/
PAY_PAYROLL_ASSIGNMENTS PPA, /*Wave 3 Change*/
PAY_ALL_PAYROLLS_F PAP /*Wave 3 Change*/
-- FND_VS_VALUE_SETS FVS1, /*Wave 3 Change*/
-- FND_VS_VALUES_VL FVB1 /*Wave 3 Change*/



WHERE 1=1 

-- /* -- ASSIGNMENT_DETAILS --- */
AND PAPF.PERSON_ID = PAAF.PERSON_ID
AND PPNF.PERSON_ID = PAPF.PERSON_ID
AND PPNF.NAME_TYPE = 'GLOBAL'
AND PAAF.PRIMARY_FLAG = 'Y' 
AND PAAF.ASSIGNMENT_TYPE IN ('E') 
AND PAAF.EFFECTIVE_LATEST_CHANGE = 'Y'
AND	PAAF.ASSIGNMENT_STATUS_TYPE = 'ACTIVE'
AND TRUNC(PAAF.LAST_UPDATE_DATE) = TRUNC(SYSDATE)
AND TRUNC(PAAF.EFFECTIVE_START_DATE) <> TRUNC(PAAF.LAST_UPDATE_DATE)
AND PAAF.PERSON_ID = MEM_GRP.PERSON_ID
AND TRUNC(SYSDATE) BETWEEN PAPF.EFFECTIVE_START_DATE AND PAPF.EFFECTIVE_END_DATE
AND TRUNC(SYSDATE) BETWEEN PPNF.EFFECTIVE_START_DATE AND PPNF.EFFECTIVE_END_DATE
AND TRUNC(SYSDATE) BETWEEN PAAF.EFFECTIVE_START_DATE AND PAAF.EFFECTIVE_END_DATE

/* -- Hourly Salaried -- */
AND PAAF.HOURLY_SALARIED_CODE  = HL.LOOKUP_CODE (+)
AND HL.LOOKUP_TYPE (+) = 'HOURLY_SALARIED_CODE'

/* -- Clerical/Physical -- */
and FVB.VALUE_SET_ID(+)=FVS.VALUE_SET_ID
AND FVS.VALUE_SET_CODE(+)='Clerical-Physical'
AND FVB.VALUE(+)=PJF.ATTRIBUTE2

/* -- Flags -- */
AND HL1.LOOKUP_CODE(+)=PAAF.LABOUR_UNION_MEMBER_FLAG
AND HL1.LOOKUP_TYPE(+)='HRC_YES_NO'

AND HL2.LOOKUP_CODE(+)=PAAF.MANAGER_FLAG
AND HL2.LOOKUP_TYPE(+)='HRC_YES_NO'


/* --- ASSIGNMENT_STATUS_DETAILS ---- */
AND PAAF.ASSIGNMENT_STATUS_TYPE_ID = PASTL.ASSIGNMENT_STATUS_TYPE_ID
AND PASTL.LANGUAGE = 'US'
AND PASTL.USER_STATUS NOT IN ('Active - No Payroll')

/* --- PERIOD_OF_SERVICE_DETAILS ---*/
AND PPOS.PERIOD_OF_SERVICE_ID = PAAF.PERIOD_OF_SERVICE_ID 


-- /* --- JOB_DETAILS ----*/
AND PJF.JOB_ID = PAAF.JOB_ID
AND PJF.JOB_ID = PJFTL.JOB_ID
AND PJFTL.LANGUAGE(+) = 'US'
AND TRUNC(SYSDATE) BETWEEN PJF.EFFECTIVE_START_DATE AND PJF.EFFECTIVE_END_DATE
AND TRUNC(SYSDATE) BETWEEN PJFTL.EFFECTIVE_START_DATE AND PJFTL.EFFECTIVE_END_DATE
/* --- DEPARTMENT_DETAILS --- */
AND PD.ORGANIZATION_ID(+) = PAAF.ORGANIZATION_ID
AND TRUNC(SYSDATE) BETWEEN PD.EFFECTIVE_START_DATE(+) AND PD.EFFECTIVE_END_DATE(+)
AND POIF.ORGANIZATION_ID(+) = PD.ORGANIZATION_ID
AND POIF.ORG_INFORMATION_CONTEXT(+) = 'ABC Department Automated/Non-Automated'
AND TRUNC(SYSDATE) BETWEEN POIF.EFFECTIVE_START_DATE(+) AND POIF.EFFECTIVE_END_DATE(+)
/* ---- BUSINESS_UNIT_DETAILS ---- */
AND BU.BU_ID= PAAF.BUSINESS_UNIT_ID
AND  SYSDATE BETWEEN BU.DATE_FROM AND BU.DATE_TO
/* ---- LOCATION_DETAILS ---- */
AND LOCATIONS.LOCATION_ID = PAAF.LOCATION_ID
AND TRUNC(SYSDATE) BETWEEN LOCATIONS.EFFECTIVE_START_DATE AND LOCATIONS.EFFECTIVE_END_DATE
/* --- LEGAL_EMPLOYER_DETAILS ---- */
AND PAAF.LEGAL_ENTITY_ID = PLE.ORGANIZATION_ID
AND TRUNC(SYSDATE) BETWEEN PLE.EFFECTIVE_START_DATE AND PLE.EFFECTIVE_END_DATE
/* ---- GRADE_DETAILS --- */
AND PGF.GRADE_ID(+) = PAAF.GRADE_ID
AND PGF.GRADE_ID = PGFTL.GRADE_ID(+)
AND PGFTL.LANGUAGE(+) = 'US'
AND TRUNC(SYSDATE) BETWEEN PGF.EFFECTIVE_START_DATE(+) AND PGF.EFFECTIVE_END_DATE(+)
AND TRUNC(SYSDATE) BETWEEN PGFTL.EFFECTIVE_START_DATE(+) AND PGFTL.EFFECTIVE_END_DATE(+)



-- /* --- HCM_GROUP_DETAILS --- */

AND HGT.GRP_ID = HGMF.GRP_ID
AND HGT.LANGUAGE = 'US'
AND PAPF.PERSON_ID = HGMF.MEMBER_ID

/*  --- WORKER_TIME_PROCESSING_PROFILE_DETAILS --- */
AND HSPTL_PROCC_PRFL.SETUP_PROFILE_ID=HSPB_PROCC_PRFL.SETUP_PROFILE_ID
AND HSPTL_PROCC_PRFL.LANGUAGE ='US'
AND HSPA_PROCC.SETUP_PROFILE_ID=HSPTL_PROCC_PRFL.SETUP_PROFILE_ID
AND HSPA_PROCC.OBJECT_ID=HGMF.GRP_ID
AND HSPB_PROCC_PRFL.PRODUCT_AREA='CORE'
AND HSPA_PROCC.ASSIGN_TO='GROUP'
AND TRUNC(SYSDATE) BETWEEN HGMF.EFFECTIVE_START_DATE AND HGMF.EFFECTIVE_END_DATE
AND HGT.GROUP_NAME <> MEM_GRP.group_name

/* --- WORKER_TIME_ENTRY_PROFILE_DETAILS --- */
AND HSPTL_TIMEENTRY_PRFL.SETUP_PROFILE_ID=HSPB_TIMEENTRY_PRFL.SETUP_PROFILE_ID
AND HSPTL_TIMEENTRY_PRFL.LANGUAGE ='US'
AND HSPA_TIMEENTRY.SETUP_PROFILE_ID=HSPTL_TIMEENTRY_PRFL.SETUP_PROFILE_ID
AND HSPB_TIMEENTRY_PRFL.PRODUCT_AREA='WORKER_TIMECARD'
AND HSPA_TIMEENTRY.ASSIGN_TO='GROUP'
AND HSPA_TIMEENTRY.OBJECT_ID=HGMF.GRP_ID

/* --- PayTime Period Range --- */
 AND PAAF.ASSIGNMENT_ID = PAY_PERIOD.HR_ASSIGNMENT_ID
AND ( 
(HGMF.EFFECTIVE_START_DATE >= PAY_PERIOD.PTP_START_DATE)
OR ((HGMF.EFFECTIVE_END_DATE <= PAY_PERIOD.PTP_END_DATE) AND (PAY_PERIOD.PTP_START_DATE BETWEEN HGMF.EFFECTIVE_START_DATE AND HGMF.EFFECTIVE_END_DATE))
OR (PAY_PERIOD.PTP_END_DATE BETWEEN HGMF.EFFECTIVE_START_DATE AND HGMF.EFFECTIVE_END_DATE)
) 

/* --- TimeCard Availablity --- */
 AND EXISTS ( select TC_TM_REC_GRP_ID from HWM_TM_RPT_ENTRY_V htre where
htre.resource_id = PAAF.person_id
and trunc(htre.tc_start_time) between MEM_GRP.asg_start_date and PAAF.effective_end_date
and (TC_DELETE_FLAG ='N' ) AND (TC_LATEST_VERSION = 'Y')
and ANC_LATEST_VERSION = 'Y' AND ANC_DELETE_FLAG = 'N'
AND (TE_DELETE_FLAG ='N') AND (TE_LATEST_VERSION = 'Y' )
) 
AND(
HGT.GROUP_NAME IN (:P_HCM_GROUP) 
OR ( COALESCE (NULL, :P_HCM_GROUP) IS NULL )
)

AND(
PAPF.PERSON_ID IN (:P_EMPLOYEE_NUMBER) 
OR 'All' IN (:P_EMPLOYEE_NUMBER || 'All')
) 

/*Wave 3 Change Starts*/
/* --- Payroll Name --- */

AND PAAF.ASSIGNMENT_ID = PPA.HR_ASSIGNMENT_ID(+)
AND TRUNC(SYSDATE) BETWEEN PPA.START_DATE AND PPA.END_DATE
AND PPA.PAYROLL_TERM_ID = PAPDN.PAYROLL_TERM_ID
AND TRUNC(SYSDATE) BETWEEN PAPDN.START_DATE AND NVL(PAPDN.LSED,PAPDN.END_DATE)
AND PAPDN.PAYROLL_ID = PAP.PAYROLL_ID
AND TRUNC(SYSDATE) BETWEEN PAP.EFFECTIVE_START_DATE AND PAP.EFFECTIVE_END_DATE
AND (TRIM(PAYROLL_NAME) IN (:PAYROLL_NAME) OR LEAST (:PAYROLL_NAME) IS NULL)

/* -- Union Group -- */
-- AND FVB1.VALUE_SET_ID(+)=FVS1.VALUE_SET_ID
-- AND FVS1.VALUE_SET_CODE(+)='ABC NVE Union Group'
-- AND FVB1.VALUE(+)=PJF.ATTRIBUTE2

/*Wave 3 Change ends*/

ORDER BY PAPF.PERSON_NUMBER, 
HGT.GROUP_NAME