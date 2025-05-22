CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PEND_MEGALINE_WO_DATA AS


CURSOR GET_BASE_DATA IS
             ((SELECT 
                DISTINCT(CIRT_DISPLAYNAME)              "CCT_ID",
                SLTA_RH                                 "REGION",
                SLTA_HP                                 "PROVINCE",
                AREA_AREA_CODE                          "RTOM",
                WORO_AREA_CODE                          "LEA",
                WORO_SERO_ID                            "SO",
                WORO_ID                                 "WO",
                SERO_DATECREATED                        "SO_INITIATE_DATE",
                (SELECT MAX(SEOA_DEFAULTVALUE) 
                FROM SERVICE_ORDER_ATTRIBUTES 
                WHERE SEOA_SERO_ID = WORO_SERO_ID 
                AND SEOA_NAME= 'SA_SO_INITIATOR')       "SO_INITIATOR",
                SERO_SERT_ABBREVIATION                  "SERVICE_TYPE",
                SERO_ORDT_TYPE                          "ORDER_TYPE",
                SEIT_TASKNAME                           "TASK_NAME",
                WORO_WORG_NAME                          "WORK_GROUP",
                'OPMC'                                  "OWNER",
                WORO_ASSIGNED_DATE                      "ASSIGNED_DATE",
                WORO_STAS_ABBREVIATION                  "WO_STATUS",
                ROUND(SYSDATE - WORO_ASSIGNED_DATE)     "PENDING_WO_DELAY",
                CUSR_NAME                               "CUSTOMER_NAME", 
                ((SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER CONTACT NO')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER_CONTACT_NUMBER')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'IPTV_CONTACT_PHONE')) "CONTACT_NO",
                CUSR_CUTP_TYPE                          "CUS_TYPE",
                (PORT_CARD_SLOT|| '-' ||PORT_NAME)      "PORT",
                EQUP_LOCN_TTNAME                        "EQ_LOCATION",
                EQUP_EQUT_ABBREVIATION                  "EQ_TYPE",
                EQUP_INDEX                              "EQ_INDEX",
                EQUP_IPADDRESS                          "EQ_IP",
                EQUP_MANR_ABBREVIATION                  "EQ_MANUFACTURER",
                EQUP_EQUM_MODEL                         "EQ_MODEL",
                (ADDE_STREETNUMBER || ', ' || ADDE_STRN_NAMEANDTYPE || ', ' || ADDE_SUBURB || ', ' || ADDE_CITY || ', ' || ADDE_POSC_CODE) AS "ADDRESS",
                (SELECT WOOC_TEXT FROM WORK_ORDER_COMMENTS WC WHERE WOOC_WORO_ID = WORO_ID AND WC.WOOC_ID=(SELECT MAX(WOOC_ID)CID FROM WORK_ORDER_COMMENTS WHERE WOOC_WORO_ID=WC.WOOC_WORO_ID)) AS "COMMENTS"
                FROM CIRCUITS, PORT_LINKS, PORT_LINK_PORTS, PORTS, EQUIPMENT, SERVICES_ADDRESS, ADDRESSES, CUSTOMER, SERVICE_IMPLEMENTATION_TASKS,
                 WORK_ORDER, SERVICE_ORDER_ATTRIBUTES, AREAS, SERVICE_ORDERS, SLT_AREAS
                WHERE CIRT_NAME = WORO_CIRT_NAME
                AND SEIT_TASKNAME IN ('WO FOR OSP','WO FOR MDF')
                AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                AND SEIT_ID = WORO_SEIT_ID
                AND CIRT_NAME = PORL_CIRT_NAME
                AND PORL_ID = POLP_PORL_ID
                AND POLP_FRAA_ID IS NULL
                AND POLP_PORT_ID = PORT_ID
                AND PORT_NAME NOT LIKE 'POTS-OUT-%'
                AND PORT_NAME NOT LIKE 'DSL-IN-%'
                AND EQUP_EQUT_ABBREVIATION IN ('MSAN-OG','MSAN-IG','MSAN-IW','MSAN-OP','MSAN-OW','DSLAM-HUAWEI','DSLAM-ZTE')
                AND PORT_EQUP_ID = EQUP_ID
                AND CIRT_SERV_ID = SADD_SERV_ID
                AND SADD_ADDE_ID = ADDE_ID
                AND SADD_TYPE = 'BEND'
                AND CIRT_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                AND WORO_SERO_ID = SEOA_SERO_ID
                AND SEOA_NAME = 'CUSTOMER CONTACT NO'
                AND WORO_AREA_CODE = AREA_CODE
                AND WORO_SERO_ID = SERO_ID
                AND WORO_AREA_CODE = SLTA_LEA
                AND ((WORO_WORG_NAME LIKE '%-OSP-%') OR (WORO_WORG_NAME LIKE '%-NC%'))
                AND TO_CHAR(SERO_DATECREATED,'YYYY-MM-DD')>'2013-12-31')
                
                UNION
                
                (SELECT 
                DISTINCT(CIRT_DISPLAYNAME)              "CCT_ID",
                SLTA_RH                                 "REGION",
                SLTA_HP                                 "PROVINCE",
                AREA_AREA_CODE                          "RTOM",
                WORO_AREA_CODE                          "LEA",
                WORO_SERO_ID                            "SO",
                WORO_ID                                 "WO",
                SERO_DATECREATED                        "SO_INITIATE_DATE",
                (SELECT MAX(SEOA_DEFAULTVALUE) 
                FROM SERVICE_ORDER_ATTRIBUTES 
                WHERE SEOA_SERO_ID = WORO_SERO_ID 
                AND SEOA_NAME= 'SA_SO_INITIATOR')       "SO_INITIATOR",
                SERO_SERT_ABBREVIATION                  "SERVICE_TYPE",
                SERO_ORDT_TYPE                          "ORDER_TYPE",
                SEIT_TASKNAME                           "TASK_NAME",
                WORO_WORG_NAME                          "WORK_GROUP",
                'CSU'                                   "OWNER",
                WORO_ASSIGNED_DATE                      "ASSIGNED_DATE",
                WORO_STAS_ABBREVIATION                  "WO_STATUS",
                ROUND(SYSDATE - WORO_ASSIGNED_DATE)     "PENDING_WO_DELAY",
                CUSR_NAME                               "CUSTOMER_NAME", 
                ((SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER CONTACT NO')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER_CONTACT_NUMBER')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'IPTV_CONTACT_PHONE')) "CONTACT_NO",
                CUSR_CUTP_TYPE                          "CUS_TYPE",
                (PORT_CARD_SLOT|| '-' ||PORT_NAME)      "PORT",
                EQUP_LOCN_TTNAME                        "EQ_LOCATION",
                EQUP_EQUT_ABBREVIATION                  "EQ_TYPE",
                EQUP_INDEX                              "EQ_INDEX",
                EQUP_IPADDRESS                          "EQ_IP",
                EQUP_MANR_ABBREVIATION                  "EQ_MANUFACTURER",
                EQUP_EQUM_MODEL                         "EQ_MODEL",
                (ADDE_STREETNUMBER || ', ' || ADDE_STRN_NAMEANDTYPE || ', ' || ADDE_SUBURB || ', ' || ADDE_CITY || ', ' || ADDE_POSC_CODE) AS "ADDRESS",
                (SELECT WOOC_TEXT FROM WORK_ORDER_COMMENTS WC WHERE WOOC_WORO_ID = WORO_ID AND WC.WOOC_ID=(SELECT MAX(WOOC_ID)CID FROM WORK_ORDER_COMMENTS WHERE WOOC_WORO_ID=WC.WOOC_WORO_ID)) AS "COMMENTS"
                FROM CIRCUITS, PORT_LINKS, PORT_LINK_PORTS, PORTS, EQUIPMENT, SERVICES_ADDRESS, ADDRESSES, CUSTOMER, SERVICE_IMPLEMENTATION_TASKS,
                 WORK_ORDER, SERVICE_ORDER_ATTRIBUTES, AREAS, SERVICE_ORDERS, SLT_AREAS
                WHERE CIRT_NAME = WORO_CIRT_NAME
                AND SEIT_TASKNAME IN ('WO FOR OSP','WO FOR MDF')
                AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                AND SEIT_ID = WORO_SEIT_ID
                AND CIRT_NAME = PORL_CIRT_NAME
                AND PORL_ID = POLP_PORL_ID
                AND POLP_FRAA_ID IS NULL
                AND POLP_PORT_ID = PORT_ID
                AND PORT_NAME NOT LIKE 'POTS-OUT-%'
                AND PORT_NAME NOT LIKE 'DSL-IN-%'
                AND EQUP_EQUT_ABBREVIATION IN ('MSAN-OG','MSAN-IG','MSAN-IW','MSAN-OP','MSAN-OW','DSLAM-HUAWEI','DSLAM-ZTE')
                AND PORT_EQUP_ID = EQUP_ID
                AND CIRT_SERV_ID = SADD_SERV_ID
                AND SADD_ADDE_ID = ADDE_ID
                AND SADD_TYPE = 'BEND'
                AND CIRT_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                AND WORO_SERO_ID = SEOA_SERO_ID
                AND SEOA_NAME = 'CUSTOMER CONTACT NO'
                AND WORO_AREA_CODE = AREA_CODE
                AND WORO_SERO_ID = SERO_ID
                AND WORO_AREA_CODE = SLTA_LEA
                AND ((WORO_WORG_NAME LIKE '%-CSU%') OR (WORO_WORG_NAME LIKE '%-TELESHOP%') OR (WORO_WORG_NAME LIKE '%-RTOFFICE%'))
                AND TO_CHAR(SERO_DATECREATED,'YYYY-MM-DD')>'2013-12-31')
                
                UNION
                
                (SELECT 
                DISTINCT(CIRT_DISPLAYNAME)              "CCT_ID",
                SLTA_RH                                 "REGION",
                SLTA_HP                                 "PROVINCE",
                AREA_AREA_CODE                          "RTOM",
                WORO_AREA_CODE                          "LEA",
                WORO_SERO_ID                            "SO",
                WORO_ID                                 "WO",
                SERO_DATECREATED                        "SO_INITIATE_DATE",
                (SELECT MAX(SEOA_DEFAULTVALUE) 
                FROM SERVICE_ORDER_ATTRIBUTES 
                WHERE SEOA_SERO_ID = WORO_SERO_ID 
                AND SEOA_NAME= 'SA_SO_INITIATOR')       "SO_INITIATOR",
                SERO_SERT_ABBREVIATION                  "SERVICE_TYPE",
                SERO_ORDT_TYPE                          "ORDER_TYPE",
                SEIT_TASKNAME                           "TASK_NAME",
                WORO_WORG_NAME                          "WORK_GROUP",
                'HQ_TEAM'                               "OWNER",
                WORO_ASSIGNED_DATE                      "ASSIGNED_DATE",
                WORO_STAS_ABBREVIATION                  "WO_STATUS",
                ROUND(SYSDATE - WORO_ASSIGNED_DATE)     "PENDING_WO_DELAY",
                CUSR_NAME                               "CUSTOMER_NAME", 
                ((SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER CONTACT NO')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'CUSTOMER_CONTACT_NUMBER')||'/ '||
                (SELECT MAX (A.SEOA_DEFAULTVALUE) FROM SERVICE_ORDER_ATTRIBUTES A WHERE A.SEOA_SERO_ID = SERO_ID  AND SEOA_NAME = 'IPTV_CONTACT_PHONE')) "CONTACT_NO",
                CUSR_CUTP_TYPE                          "CUS_TYPE",
                (PORT_CARD_SLOT|| '-' ||PORT_NAME)      "PORT",
                EQUP_LOCN_TTNAME                        "EQ_LOCATION",
                EQUP_EQUT_ABBREVIATION                  "EQ_TYPE",
                EQUP_INDEX                              "EQ_INDEX",
                EQUP_IPADDRESS                          "EQ_IP",
                EQUP_MANR_ABBREVIATION                  "EQ_MANUFACTURER",
                EQUP_EQUM_MODEL                         "EQ_MODEL",
                (ADDE_STREETNUMBER || ', ' || ADDE_STRN_NAMEANDTYPE || ', ' || ADDE_SUBURB || ', ' || ADDE_CITY || ', ' || ADDE_POSC_CODE) AS "ADDRESS",
                (SELECT WOOC_TEXT FROM WORK_ORDER_COMMENTS WC WHERE WOOC_WORO_ID = WORO_ID AND WC.WOOC_ID=(SELECT MAX(WOOC_ID)CID FROM WORK_ORDER_COMMENTS WHERE WOOC_WORO_ID=WC.WOOC_WORO_ID)) AS "COMMENTS"
                FROM CIRCUITS, PORT_LINKS, PORT_LINK_PORTS, PORTS, EQUIPMENT, SERVICES_ADDRESS, ADDRESSES, CUSTOMER, SERVICE_IMPLEMENTATION_TASKS,
                 WORK_ORDER, SERVICE_ORDER_ATTRIBUTES, AREAS, SERVICE_ORDERS, SLT_AREAS
                WHERE CIRT_NAME = WORO_CIRT_NAME
                AND SEIT_TASKNAME IN ('WO FOR OSP','WO FOR MDF')
                AND SEIT_STAS_ABBREVIATION = 'INPROGRESS'
                AND SEIT_ID = WORO_SEIT_ID
                AND CIRT_NAME = PORL_CIRT_NAME
                AND PORL_ID = POLP_PORL_ID
                AND POLP_FRAA_ID IS NULL
                AND POLP_PORT_ID = PORT_ID
                AND PORT_NAME NOT LIKE 'POTS-OUT-%'
                AND PORT_NAME NOT LIKE 'DSL-IN-%'
                AND EQUP_EQUT_ABBREVIATION IN ('MSAN-OG','MSAN-IG','MSAN-IW','MSAN-OP','MSAN-OW','DSLAM-HUAWEI','DSLAM-ZTE')
                AND PORT_EQUP_ID = EQUP_ID
                AND CIRT_SERV_ID = SADD_SERV_ID
                AND SADD_ADDE_ID = ADDE_ID
                AND SADD_TYPE = 'BEND'
                AND CIRT_CUSR_ABBREVIATION = CUSR_ABBREVIATION
                AND WORO_SERO_ID = SEOA_SERO_ID
                AND SEOA_NAME = 'CUSTOMER CONTACT NO'
                AND WORO_AREA_CODE = AREA_CODE
                AND WORO_SERO_ID = SERO_ID
                AND WORO_AREA_CODE = SLTA_LEA
                AND (WORO_WORG_NAME NOT LIKE '%-CSU%')
                AND (WORO_WORG_NAME NOT LIKE '%-TELESHOP%')
                AND (WORO_WORG_NAME NOT LIKE '%-RTOFFICE%')
                AND (WORO_WORG_NAME NOT LIKE '%-OSP-%')
                AND (WORO_WORG_NAME NOT LIKE '%-NC%')
                AND TO_CHAR(SERO_DATECREATED,'YYYY-MM-DD')>'2013-12-31'));


GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN

DELETE FROM CLARITY_ADMIN.PENDING_MEGALINE_WO_DETAILS;

OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDING_MEGALINE_WO_DETAILS
(
CCT_ID,
REGION,
PROVINCE,
RTOM,
LEA,
SO,
WO,
SO_INITIATE_DATE,
SO_INITIATOR,
SERVICE_TYPE,
ORDER_TYPE,
TASK_NAME,
WORK_GROUP,
OWNER,
ASSIGNED_DATE,
WO_STATUS,
PENDING_WO_DELAY,
CUSTOMER_NAME,
CONTACT_NO,
CUS_TYPE,
PORT,
EQ_LOCATION,
EQ_TYPE,
EQ_INDEX,
EQ_IP,
EQ_MANUFACTURER,
EQ_MODEL,
ADDRESS,
COMMENTS
)
VALUES
(
GET_BASE_DATA_REC.CCT_ID,
GET_BASE_DATA_REC.REGION,
GET_BASE_DATA_REC.PROVINCE,
GET_BASE_DATA_REC.RTOM,
GET_BASE_DATA_REC.LEA,
GET_BASE_DATA_REC.SO,
GET_BASE_DATA_REC.WO,
GET_BASE_DATA_REC.SO_INITIATE_DATE,
GET_BASE_DATA_REC.SO_INITIATOR,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.ORDER_TYPE,
GET_BASE_DATA_REC.TASK_NAME,
GET_BASE_DATA_REC.WORK_GROUP,
GET_BASE_DATA_REC.OWNER,
GET_BASE_DATA_REC.ASSIGNED_DATE,
GET_BASE_DATA_REC.WO_STATUS,
GET_BASE_DATA_REC.PENDING_WO_DELAY,
GET_BASE_DATA_REC.CUSTOMER_NAME,
GET_BASE_DATA_REC.CONTACT_NO,
GET_BASE_DATA_REC.CUS_TYPE,
GET_BASE_DATA_REC.PORT,
GET_BASE_DATA_REC.EQ_LOCATION,
GET_BASE_DATA_REC.EQ_TYPE,
GET_BASE_DATA_REC.EQ_INDEX,
GET_BASE_DATA_REC.EQ_IP,
GET_BASE_DATA_REC.EQ_MANUFACTURER,
GET_BASE_DATA_REC.EQ_MODEL,
GET_BASE_DATA_REC.ADDRESS,
GET_BASE_DATA_REC.COMMENTS
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PEND_MEGALINE_WO_DATA;

---- Sasith 16-11-2014 -----
/
