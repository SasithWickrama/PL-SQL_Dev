CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_ES_WO_DATA AS


CURSOR GET_BASE_DATA IS
                   SELECT
                        SLTA_RH                                                     "REGION",
                        SLTA_HP                                                     "PROVINCE",
                        AREA_AREA_CODE                                              "RTOM",
                        SERO_AREA_CODE                                              "LEA",
                        SERO_SERT_ABBREVIATION                                      "SERVICE_TYPE",
                        SEIT_SERO_ID                                                "SERO_ID",
                        CIRT_DISPLAYNAME                                            "CCT_ID",
                        SEIT_TASKNAME                                               "TASK_NAME",
                        CUSR_NAME                                                   "CUSTOMER",
                        CUSR_CUTP_TYPE                                              "CUS_TYPE",
                        TO_CHAR(SEIT_ACTUAL_START_DATE,'DD/MM/YYYY HH24:MI:SS')     "ASSIGNED_DATE",
                        TO_CHAR(SEIT_ACTUAL_END_DATE, 'DD/MM/YYYY HH24:MI:SS')      "COMPLETED_DATE",
                        TRUNC(SEIT_ACTUAL_END_DATE) - TRUNC(SEIT_ACTUAL_START_DATE) "DURATION"
                        FROM SERVICE_IMPLEMENTATION_TASKS,
                        SERVICE_ORDERS,
                        SLT_AREAS,
                        AREAS,
                        CIRCUITS,
                        CUSTOMER
                        WHERE SEIT_TASKNAME = 'IDENTIFY FACILITIES'
                        AND SEIT_SERO_ID = SERO_ID
                        AND SERO_AREA_CODE = SLTA_LEA
                        AND SLTA_LEA = AREA_CODE
                        AND SERO_CIRT_NAME = CIRT_NAME
                        AND CIRT_SERT_ABBREVIATION LIKE 'D-%'
                        AND CIRT_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                        AND CUSR_CUTP_TYPE IN ('BUSINESS', 'GOVERNMENT OFFICIAL')
                        AND TRUNC(SEIT_ACTUAL_END_DATE) BETWEEN TRUNC(SYSDATE - 8) AND TRUNC(SYSDATE - 1)
                        GROUP BY (SLTA_RH,
                        SLTA_HP,
                        AREA_AREA_CODE,
                        SERO_AREA_CODE,
                        SERO_SERT_ABBREVIATION,
                        SEIT_SERO_ID,
                        CIRT_DISPLAYNAME,
                        SEIT_TASKNAME,
                        CUSR_NAME,
                        CUSR_CUTP_TYPE,
                        SEIT_ACTUAL_START_DATE,
                        SEIT_ACTUAL_END_DATE);

GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN


OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDING_ES_WO
(
REGION,
PROVINCE,
RTOM,
LEA,
SERVICE_TYPE,
SERO_ID,
CCT_ID,
TASK_NAME,
CUSTOMER,
CUS_TYPE,
ASSIGNED_DATE,
COMPLETED_DATE,
DURATION
)
VALUES
(
GET_BASE_DATA_REC.REGION,
GET_BASE_DATA_REC.PROVINCE,
GET_BASE_DATA_REC.RTOM,
GET_BASE_DATA_REC.LEA,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.SERO_ID,
GET_BASE_DATA_REC.CCT_ID,
GET_BASE_DATA_REC.TASK_NAME,
GET_BASE_DATA_REC.CUSTOMER,
GET_BASE_DATA_REC.CUS_TYPE,
GET_BASE_DATA_REC.ASSIGNED_DATE,
GET_BASE_DATA_REC.COMPLETED_DATE,
GET_BASE_DATA_REC.DURATION
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PENDING_ES_WO_DATA;

---- Sasith 26-01-2016 -----
/
