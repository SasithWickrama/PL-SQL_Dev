CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PEND_KY_MDF_WO_DETAILS_DATA AS


CURSOR GET_BASE_DATA IS
                    (SELECT
                        AREA_AREA_CODE          "RTOM",
                        WORO_AREA_CODE          "LEA", 
                        WORO_SERO_ID            "SERVICE_ORDER", 
                        WORO_ID                 "WORK_ORDER", 
                        CIRT_DISPLAYNAME        "CCT_ID", 
                        SERO_SERT_ABBREVIATION  "SERVICE_TYPE",
                        WORO_WORG_NAME          "WORK_GROUP", 
                        WORO_ORDT_TYPE          "ORDER_TYPE", 
                        WORO_TASKNAME           "TASK_NAME",
                        WORO_STAS_ABBREVIATION  "WO_STATUS", 
                        WORO_USERUPDATED        "UPDATED_BY",
                        TO_CHAR(SERO_DATECREATED,'DD/MM/YYYY HH24:MI:SS') "SO_CREATE_DATE",
                        TO_CHAR(WORO_ASSIGNED_DATE,'DD/MM/YYYY HH24:MI:SS') "WO_ASSIGNED_DATE"
                        FROM WORK_ORDER, SERVICE_ORDERS, CIRCUITS, AREAS
                        WHERE WORO_STAS_ABBREVIATION = 'INPROGRESS'
                        AND WORO_WORG_NAME IN ('KY-AKU-MDF',
                        'KY-DIN-MDF',
                                    'KY-GG-MDF',
                                    'KY-HKT-MDF',
                                    'KY-KS-MDF',
                                    'KY-KY-MDF',
                                    'KY-MMN-MDF',
                                    'KY-MN-MDF',
                                    'KY-PKL-MDF',
                                    'KY-RA-MDF',
                                    'KY-RKL-MDF',
                                    'KY-TTY-MDF',
                                    'KY-WH-MDF',
                                    'GP-DC-MDF',
                                    'GP-DOL-MDF',
                                    'GP-GH-MDF',
                                    'GP-GO-MDF',
                                    'GP-GP-MDF',
                                    'GP-HS-MDF',
                                    'GP-KAD-MDF',
                                    'GP-MUR-MDF',
                                    'GP-NT-MDF',
                                    'GP-PML-MDF',
                                    'GP-PN-MDF',
                                    'GP-PV-MDF',
                                    'GP-TP-MDF',
                                    'MT-BKM-MDF',
                                    'MT-DB-MDF',
                                    'MT-GHN-MDF',
                                    'MT-GLW-MDF',
                                    'MT-HBR-MDF',
                                    'MT-LG-MDF',
                                    'MT-MT-MDF',
                                    'MT-NL-MDF',
                                    'MT-POL-MDF',
                                    'MT-RX-MDF',
                                    'MT-SIG-MDF',
                                    'MT-UK-MDF',
                                    'MT-WIL-MDF',
                                    'KY-AKU-OSP-NC',
                                    'KY-DIN-OSP-NC',
                                    'KY-GG-OSP-NC',
                                    'KY-HKT-OSP-NC',
                                    'KY-KS-OSP-NC',
                                    'KY-KY-OSP-NC',
                                    'KY-MMN-OSP-NC',
                                    'KY-MN-OSP-NC',
                                    'KY-PKL-OSP-NC',
                                    'KY-RA-OSP-NC',
                                    'KY-RKL-OSP-NC',
                                    'KY-TTY-OSP-NC',
                                    'KY-WH-OSP-NC',
                                    'MT-BKM-OSP-NC',
                                    'MT-DB-OSP-NC',
                                    'MT-GHN-OSP-NC',
                                    'MT-GLW-OSP-NC',
                                    'MT-HBR-OSP-NC',
                                    'MT-LG-OSP-NC',
                                    'MT-MT-OSP-NC',
                                    'MT-NL-OSP-NC',
                                    'MT-POL-OSP-NC',
                                    'MT-RX-OSP-NC',
                                    'MT-SIG-OSP-NC',
                                    'MT-UK-OSP-NC',
                                    'MT-WIL-OSP-NC',
                                    'GP-DC-OSP-NC',
                                    'GP-DOL-OSP-NC',
                                    'GP-GH-OSP-NC',
                                    'GP-GO-OSP-NC',
                                    'GP-GP-OSP-NC',
                                    'GP-HS-OSP-NC',
                                    'GP-KAD-OSP-NC',
                                    'GP-MUR-OSP-NC',
                                    'GP-NT-OSP-NC',
                                    'GP-PML-OSP-NC',
                                    'GP-PN-OSP-NC',
                                    'GP-PV-OSP-NC',
                                    'GP-TP-OSP-NC')
                        AND WORO_ORDT_TYPE = 'CREATE'
                        AND WORO_SERO_ID = SERO_ID
                        AND SERO_SERT_ABBREVIATION = 'PSTN'
                        AND WORO_CIRT_NAME = CIRT_NAME
                        AND WORO_AREA_CODE = AREA_CODE)
                     UNION
                    (SELECT
                        AREA_AREA_CODE          "RTOM",
                        WORO_AREA_CODE          "LEA", 
                        WORO_SERO_ID            "SERVICE_ORDER", 
                        WORO_ID                 "WORK_ORDER", 
                        CIRT_DISPLAYNAME        "CCT_ID", 
                        SERO_SERT_ABBREVIATION  "SERVICE_TYPE",
                        WORO_WORG_NAME          "WORK_GROUP", 
                        WORO_ORDT_TYPE          "ORDER_TYPE", 
                        WORO_TASKNAME           "TASK_NAME",
                        WORO_STAS_ABBREVIATION  "WO_STATUS", 
                        WORO_USERUPDATED        "UPDATED_BY",
                        TO_CHAR(SERO_DATECREATED,'DD/MM/YYYY HH24:MI:SS') "SO_CREATE_DATE",
                        TO_CHAR(WORO_ASSIGNED_DATE,'DD/MM/YYYY HH24:MI:SS') "WO_ASSIGNED_DATE"
                        FROM WORK_ORDER, SERVICE_ORDERS, CIRCUITS, AREAS
                        WHERE WORO_STAS_ABBREVIATION = 'ASSIGNED'
                        AND WORO_WORG_NAME IN ('KY-AKU-MDF',
                                    'KY-DIN-MDF',
                                    'KY-GG-MDF',
                                    'KY-HKT-MDF',
                                    'KY-KS-MDF',
                                    'KY-KY-MDF',
                                    'KY-MMN-MDF',
                                    'KY-MN-MDF',
                                    'KY-PKL-MDF',
                                    'KY-RA-MDF',
                                    'KY-RKL-MDF',
                                    'KY-TTY-MDF',
                                    'KY-WH-MDF',
                                    'GP-DC-MDF',
                                    'GP-DOL-MDF',
                                    'GP-GH-MDF',
                                    'GP-GO-MDF',
                                    'GP-GP-MDF',
                                    'GP-HS-MDF',
                                    'GP-KAD-MDF',
                                    'GP-MUR-MDF',
                                    'GP-NT-MDF',
                                    'GP-PML-MDF',
                                    'GP-PN-MDF',
                                    'GP-PV-MDF',
                                    'GP-TP-MDF',
                                    'MT-BKM-MDF',
                                    'MT-DB-MDF',
                                    'MT-GHN-MDF',
                                    'MT-GLW-MDF',
                                    'MT-HBR-MDF',
                                    'MT-LG-MDF',
                                    'MT-MT-MDF',
                                    'MT-NL-MDF',
                                    'MT-POL-MDF',
                                    'MT-RX-MDF',
                                    'MT-SIG-MDF',
                                    'MT-UK-MDF',
                                    'MT-WIL-MDF',
                                    'KY-AKU-OSP-NC',
                                    'KY-DIN-OSP-NC',
                                    'KY-GG-OSP-NC',
                                    'KY-HKT-OSP-NC',
                                    'KY-KS-OSP-NC',
                                    'KY-KY-OSP-NC',
                                    'KY-MMN-OSP-NC',
                                    'KY-MN-OSP-NC',
                                    'KY-PKL-OSP-NC',
                                    'KY-RA-OSP-NC',
                                    'KY-RKL-OSP-NC',
                                    'KY-TTY-OSP-NC',
                                    'KY-WH-OSP-NC',
                                    'MT-BKM-OSP-NC',
                                    'MT-DB-OSP-NC',
                                    'MT-GHN-OSP-NC',
                                    'MT-GLW-OSP-NC',
                                    'MT-HBR-OSP-NC',
                                    'MT-LG-OSP-NC',
                                    'MT-MT-OSP-NC',
                                    'MT-NL-OSP-NC',
                                    'MT-POL-OSP-NC',
                                    'MT-RX-OSP-NC',
                                    'MT-SIG-OSP-NC',
                                    'MT-UK-OSP-NC',
                                    'MT-WIL-OSP-NC',
                                    'GP-DC-OSP-NC',
                                    'GP-DOL-OSP-NC',
                                    'GP-GH-OSP-NC',
                                    'GP-GO-OSP-NC',
                                    'GP-GP-OSP-NC',
                                    'GP-HS-OSP-NC',
                                    'GP-KAD-OSP-NC',
                                    'GP-MUR-OSP-NC',
                                    'GP-NT-OSP-NC',
                                    'GP-PML-OSP-NC',
                                    'GP-PN-OSP-NC',
                                    'GP-PV-OSP-NC',
                                    'GP-TP-OSP-NC')
                        AND WORO_ORDT_TYPE = 'CREATE'
                        AND WORO_SERO_ID = SERO_ID
                        AND SERO_SERT_ABBREVIATION = 'PSTN'
                        AND WORO_CIRT_NAME = CIRT_NAME
                        AND WORO_AREA_CODE = AREA_CODE);


GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN

DELETE FROM CLARITY_ADMIN.PENDINGE_KY_MDF_WO_DETAILS;

OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDINGE_KY_MDF_WO_DETAILS
(
RTOM,
LEA,
SERVICE_ORDER,
WORK_ORDER,
CCT_ID,
SERVICE_TYPE,
WORK_GROUP,
ORDER_TYPE,
TASK_NAME,
WO_STATUS,
UPDATED_BY,
SO_CREATE_DATE,
WO_ASSIGNED_DATE
)
VALUES
(
GET_BASE_DATA_REC.RTOM,
GET_BASE_DATA_REC.LEA,
GET_BASE_DATA_REC.SERVICE_ORDER,
GET_BASE_DATA_REC.WORK_ORDER,
GET_BASE_DATA_REC.CCT_ID,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.WORK_GROUP,
GET_BASE_DATA_REC.ORDER_TYPE,
GET_BASE_DATA_REC.TASK_NAME,
GET_BASE_DATA_REC.WO_STATUS,
GET_BASE_DATA_REC.UPDATED_BY,
GET_BASE_DATA_REC.SO_CREATE_DATE,
GET_BASE_DATA_REC.WO_ASSIGNED_DATE
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PEND_KY_MDF_WO_DETAILS_DATA;

---- Sasith 05-06-2014 -----
/
