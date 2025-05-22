CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_FTTH_WO_DATA AS


CURSOR GET_BASE_DATA IS
                   ( (SELECT
                        DISTINCT(CIRT_DISPLAYNAME)          "CIRCUIT",
                        SLTA_RH                             "REGION",
                        SLTA_HP                             "PROVINCE",
                        AREA_AREA_CODE                      "RTOM",
                        SLTA_LEA                            "LEA",
                       (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'REGISTRATION ID')  "REGISTRATION_ID",
                        (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'OH CONTRACTOR')    "CONTRACTOR_NAME",
                        WORO_SERO_ID                        "SO",
                        WORO_ID                             "WO", 
                        SERO_SERT_ABBREVIATION              "SERVICE_TYPE",
                        SERO_ORDT_TYPE                      "ORDER_TYPE",
                        WORO_TASKNAME                       "TASK_NAME",
                        WORO_WORG_NAME                      "WORK_GROUP",
                        'OPMC'                              "OWNER",
                        SERO_DATECREATED                    "SO_CREATE_DATE",
                        WORO_ASSIGNED_DATE                  "WO_ASSIGNED_DATE", 
                        ROUND(SYSDATE - WORO_ASSIGNED_DATE) "PENDING_WO_DELAY", 
                        WORO_STAS_ABBREVIATION              "WO_STATUS",
                        SERO_CUSR_ABBREVIATION              "CR", 
                        CUSR_NAME                           "CUS_NAME",
                        CUSR_CUTP_TYPE                      "CUS_TYPE", 
                        CIRT_LOCN_AEND                      "OLT_LOCATION", 
                        CIRT_LOCN_BEND                      "ONT_LOCATION", 
                        ('OR'||SUBSTR(SERO_OEID,1,9))       "CRM_OR"
                    FROM WORK_ORDER, SERVICE_ORDERS, SERVICE_IMPLEMENTATION_TASKS, CIRCUITS, CUSTOMER, AREAS, SLT_AREAS
                    WHERE WORO_STAS_ABBREVIATION NOT IN ('CANCELLED','CLOSED')
                    AND WORO_SERO_ID = SERO_ID
                    AND SERO_SERT_ABBREVIATION IN ('AB-FTTH','BB-INTERNET FTTH','V-VOICE FTTH','E-IPTV FTTH')
                    AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                    AND WORO_SERO_ID = SEIT_SERO_ID
                    AND WORO_CIRT_NAME = CIRT_NAME (+)
                    AND SERO_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                    AND WORO_AREA_CODE = AREA_CODE
                    AND AREA_CODE = SLTA_LEA
                    AND ((WORO_WORG_NAME LIKE '%-OSP-%') OR (WORO_WORG_NAME LIKE '%-NC%'))
                    AND SERO_CUSR_ABBREVIATION != 'CR002447053')
                    
                    UNION
                    
                   (SELECT
                        DISTINCT(CIRT_DISPLAYNAME)          "CIRCUIT",
                        SLTA_RH                             "REGION",
                        SLTA_HP                             "PROVINCE",
                        AREA_AREA_CODE                      "RTOM",
                        SLTA_LEA                            "LEA",
                        (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'REGISTRATION ID')    "REGISTRATION_ID",
                        (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'OH CONTRACTOR')    "CONTRACTOR_NAME",
                        WORO_SERO_ID                        "SO",
                        WORO_ID                             "WO", 
                        SERO_SERT_ABBREVIATION              "SERVICE_TYPE",
                        SERO_ORDT_TYPE                      "ORDER_TYPE",
                        WORO_TASKNAME                       "TASK_NAME",
                        WORO_WORG_NAME                      "WORK_GROUP",
                        'CSU'                               "OWNER",
                        SERO_DATECREATED                    "SO_CREATE_DATE",
                        WORO_ASSIGNED_DATE                  "WO_ASSIGNED_DATE", 
                        ROUND(SYSDATE - WORO_ASSIGNED_DATE) "PENDING_WO_DELAY", 
                        WORO_STAS_ABBREVIATION              "WO_STATUS",
                        SERO_CUSR_ABBREVIATION              "CR", 
                        CUSR_NAME                           "CUS_NAME",
                        CUSR_CUTP_TYPE                      "CUS_TYPE", 
                        CIRT_LOCN_AEND                      "OLT_LOCATION", 
                        CIRT_LOCN_BEND                      "ONT_LOCATION",
                        ('OR'||SUBSTR(SERO_OEID,1,9))       "CRM_OR"
                    FROM WORK_ORDER, SERVICE_ORDERS, SERVICE_IMPLEMENTATION_TASKS, CIRCUITS, CUSTOMER, AREAS, SLT_AREAS
                    WHERE WORO_STAS_ABBREVIATION NOT IN ('CANCELLED','CLOSED')
                    AND WORO_SERO_ID = SERO_ID
                    AND SERO_SERT_ABBREVIATION IN ('AB-FTTH','BB-INTERNET FTTH','V-VOICE FTTH','E-IPTV FTTH')
                    AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                    AND WORO_SERO_ID = SEIT_SERO_ID
                    AND WORO_CIRT_NAME = CIRT_NAME (+)
                    AND SERO_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                    AND WORO_AREA_CODE = AREA_CODE
                    AND AREA_CODE = SLTA_LEA
                    AND ((WORO_WORG_NAME LIKE '%-CSU%') OR (WORO_WORG_NAME LIKE '%-TELESHOP%') OR (WORO_WORG_NAME LIKE '%-RTOFFICE%'))
                    AND SERO_CUSR_ABBREVIATION != 'CR002447053')
                    
                    UNION
                    
                    (SELECT
                        DISTINCT(CIRT_DISPLAYNAME)          "CIRCUIT",
                        SLTA_RH                             "REGION",
                        SLTA_HP                             "PROVINCE",
                        AREA_AREA_CODE                      "RTOM",
                        SLTA_LEA                            "LEA",
                        (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'REGISTRATION ID')    "REGISTRATION_ID",
                        (SELECT SEOA_DEFAULTVALUE
                        FROM SERVICE_ORDER_ATTRIBUTES
                        WHERE SEOA_SERO_ID = SERO_ID
                        AND SEOA_NAME = 'OH CONTRACTOR')    "CONTRACTOR_NAME",
                        WORO_SERO_ID                        "SO",
                        WORO_ID                             "WO", 
                        SERO_SERT_ABBREVIATION              "SERVICE_TYPE",
                        SERO_ORDT_TYPE                      "ORDER_TYPE",
                        WORO_TASKNAME                       "TASK_NAME",
                        WORO_WORG_NAME                      "WORK_GROUP",
                        'HQ_TEAM'                           "OWNER",
                        SERO_DATECREATED                    "SO_CREATE_DATE",
                        WORO_ASSIGNED_DATE                  "WO_ASSIGNED_DATE", 
                        ROUND(SYSDATE - WORO_ASSIGNED_DATE) "PENDING_WO_DELAY", 
                        WORO_STAS_ABBREVIATION              "WO_STATUS",
                        SERO_CUSR_ABBREVIATION              "CR", 
                        CUSR_NAME                           "CUS_NAME",
                        CUSR_CUTP_TYPE                      "CUS_TYPE", 
                        CIRT_LOCN_AEND                      "OLT_LOCATION", 
                        CIRT_LOCN_BEND                      "ONT_LOCATION",
                        ('OR'||SUBSTR(SERO_OEID,1,9))       "CRM_OR"
                    FROM WORK_ORDER, SERVICE_ORDERS, SERVICE_IMPLEMENTATION_TASKS, CIRCUITS, CUSTOMER, AREAS, SLT_AREAS
                    WHERE WORO_STAS_ABBREVIATION NOT IN ('CANCELLED','CLOSED')
                    AND WORO_SERO_ID = SERO_ID
                    AND SERO_SERT_ABBREVIATION IN ('AB-FTTH','BB-INTERNET FTTH','V-VOICE FTTH','E-IPTV FTTH')
                    AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                    AND WORO_SERO_ID = SEIT_SERO_ID
                    AND WORO_CIRT_NAME = CIRT_NAME (+)
                    AND SERO_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                    AND WORO_AREA_CODE = AREA_CODE
                    AND AREA_CODE = SLTA_LEA
                    AND (WORO_WORG_NAME NOT LIKE '%-CSU%')
                    AND (WORO_WORG_NAME NOT LIKE '%-TELESHOP%')
                    AND (WORO_WORG_NAME NOT LIKE '%-RTOFFICE%')
                    AND (WORO_WORG_NAME NOT LIKE '%-OSP-%')
                    AND (WORO_WORG_NAME NOT LIKE '%-NC%')
                    AND SERO_CUSR_ABBREVIATION != 'CR002447053'));

GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN

DELETE FROM CLARITY_ADMIN.PENDING_FTTH_WO;

OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDING_FTTH_WO
(
CIRCUIT,
REGION,
PROVINCE,
RTOM,
LEA,
REGISTRATION_ID,
CONTRACTOR_NAME,
SO,
WO,
SERVICE_TYPE,
ORDER_TYPE,
TASK_NAME,
WORK_GROUP,
OWNER,
SO_CREATE_DATE,
WO_ASSIGNED_DATE,
PENDING_WO_DELAY,
WO_STATUS,
CR,
CUS_NAME,
CUS_TYPE,
OLT_LOCATION,
ONT_LOCATION,
CRM_OR
)
VALUES
(
GET_BASE_DATA_REC.CIRCUIT,
GET_BASE_DATA_REC.REGION,
GET_BASE_DATA_REC.PROVINCE,
GET_BASE_DATA_REC.RTOM,
GET_BASE_DATA_REC.LEA,
GET_BASE_DATA_REC.REGISTRATION_ID,
GET_BASE_DATA_REC.CONTRACTOR_NAME,
GET_BASE_DATA_REC.SO,
GET_BASE_DATA_REC.WO,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.ORDER_TYPE,
GET_BASE_DATA_REC.TASK_NAME,
GET_BASE_DATA_REC.WORK_GROUP,
GET_BASE_DATA_REC.OWNER,
GET_BASE_DATA_REC.SO_CREATE_DATE,
GET_BASE_DATA_REC.WO_ASSIGNED_DATE,
GET_BASE_DATA_REC.PENDING_WO_DELAY,
GET_BASE_DATA_REC.WO_STATUS,
GET_BASE_DATA_REC.CR,
GET_BASE_DATA_REC.CUS_NAME,
GET_BASE_DATA_REC.CUS_TYPE,
GET_BASE_DATA_REC.OLT_LOCATION,
GET_BASE_DATA_REC.ONT_LOCATION,
GET_BASE_DATA_REC.CRM_OR
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PENDING_FTTH_WO_DATA;

---- Sasith 22-08-2014 -----
/
