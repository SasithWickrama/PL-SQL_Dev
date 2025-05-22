CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_CDMA_WO_DATA AS


CURSOR GET_BASE_DATA IS
                    SELECT
                        DISTINCT(CIRT_DISPLAYNAME)          "CIRCUIT",
                        SLTA_RH                             "REGION",
                        SLTA_HP                             "PROVINCE",
                        AREA_AREA_CODE                      "RTOM",
                        SLTA_LEA                            "LEA",
                        WORO_SERO_ID                        "SO",
                        WORO_ID                             "WO", 
                        SERO_SERT_ABBREVIATION              "SERVICE_TYPE",
                        WORO_TASKNAME                       "TASK_NAME",
                        WORO_WORG_NAME                      "WORK_GROUP",
                        SERO_DATECREATED                    "SO_CREATE_DATE",
                        WORO_ASSIGNED_DATE                  "WO_ASSIGNED_DATE", 
                        ROUND(SYSDATE - WORO_ASSIGNED_DATE) "PENDING_WO_DELAY", 
                        WORO_STAS_ABBREVIATION              "WO_STATUS",
                        SERO_CUSR_ABBREVIATION              "CR", 
                        CUSR_NAME                           "CUS_NAME",
                        CUSR_CUTP_TYPE                      "CUS_TYPE", 
                        ('OR'||SUBSTR(SERO_OEID,1,9))       "CRM_OR"
                    FROM WORK_ORDER, SERVICE_ORDERS, SERVICE_IMPLEMENTATION_TASKS, CIRCUITS, CUSTOMER, AREAS, SLT_AREAS
                    WHERE WORO_STAS_ABBREVIATION NOT IN ('CANCELLED','CLOSED')
                    AND WORO_SERO_ID = SERO_ID
                    AND SERO_SERT_ABBREVIATION IN ('CDMA')
                    AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                    AND WORO_SERO_ID = SEIT_SERO_ID
                    AND WORO_CIRT_NAME = CIRT_NAME (+)
                    AND SERO_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                    AND WORO_AREA_CODE = AREA_CODE
                    AND AREA_CODE = SLTA_LEA;

GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN


OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDING_CDMA_WO
(
CIRCUIT,
REGION,
PROVINCE,
RTOM,
LEA ,
SO,
WO,
SERVICE_TYPE,
TASK_NAME,
WORK_GROUP,
SO_CREATE_DATE,
WO_ASSIGNED_DATE,
PENDING_WO_DELAY,
WO_STATUS,
CR,
CUS_NAME,
CUS_TYPE,
CRM_OR
)
VALUES
(
GET_BASE_DATA_REC.CIRCUIT,
GET_BASE_DATA_REC.REGION,
GET_BASE_DATA_REC.PROVINCE,
GET_BASE_DATA_REC.RTOM,
GET_BASE_DATA_REC.LEA ,
GET_BASE_DATA_REC.SO,
GET_BASE_DATA_REC.WO,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.TASK_NAME,
GET_BASE_DATA_REC.WORK_GROUP,
GET_BASE_DATA_REC.SO_CREATE_DATE,
GET_BASE_DATA_REC.WO_ASSIGNED_DATE,
GET_BASE_DATA_REC.PENDING_WO_DELAY,
GET_BASE_DATA_REC.WO_STATUS,
GET_BASE_DATA_REC.CR,
GET_BASE_DATA_REC.CUS_NAME,
GET_BASE_DATA_REC.CUS_TYPE,
GET_BASE_DATA_REC.CRM_OR
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PENDING_CDMA_WO_DATA;

---- Dinesh Perera 16-11-2015 -----
/
