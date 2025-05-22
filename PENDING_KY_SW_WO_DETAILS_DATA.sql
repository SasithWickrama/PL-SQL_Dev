CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDINGE_KY_SW_WO_DETAILS_DATA AS


CURSOR GET_BASE_DATA IS
                    SELECT
                        WORO_AREA_CODE          "LEA", 
                        WORO_SERO_ID            "SERVICE_ORDER", 
                        WORO_ID                 "WORK_ORDER", 
                        CIRT_DISPLAYNAME        "CCT_ID", 
                        CIRT_SERT_ABBREVIATION  "SERVICE_TYPE",
                        WORO_WORG_NAME          "WORK_GROUP", 
                        WORO_ORDT_TYPE          "ORDER_TYPE", 
                        TO_CHAR(WORO_ASSIGNED_DATE,'DD/MM/YYYY HH24:MI:SS')    "ASSIGNED_DATE", 
                        WORO_TASKNAME           "TASK_NAME"

                        FROM
                        WORK_ORDER, 
                        CIRCUITS

                        WHERE
                            WORO_STAS_ABBREVIATION IN ('ASSIGNED','INPROGRESS')
                        AND WORO_WORG_NAME IN ('MT-BKM-SW-BK',
                        'MT-DB-SW-DB',
                        'MT-DB-SW-DBL',
                        'MT-GHN-SW-GI',
                        'MT-GLW-SW-GA',
                        'MT-GLW-SW-GLW',
                        'MT-HBR-SW-HAB',
                        'MT-LG-SW-LL',
                        'MT-MT-SW-MA',
                        'MT-MT-SW-AVR',
                        'MT-MT-SW-GI',
                        'MT-MT-SW-ME',
                        'MT-MT-SW-NAL',
                        'MT-MT-SW-PLP',
                        'MT-MT-SW-PLW',
                        'MT-MT-SW-TEJ',
                        'MT-MT-SW-UDA',
                        'MT-MT-SW-WAL',
                        'MT-MT-SW-WER',
                        'MT-NL-SW-NL',
                        'MT-POL-SW-POL',
                        'MT-RX-MT-RT',
                        'MT-SIG-SW-SIG',
                        'MT-UK-SW-UW',
                        'MT-UK-SW-UKW',
                        'MT-UK-SW-AWG',
                        'MT-WIL-SW-WIL',
                        'GP-NT-SW-NT',
                        'GP-TP-SW-TP',
                        'GP-DC-SW-DO',
                        'GP-HS-SW-HAN',
                        'GP-PN-SW-PN',
                        'GP-PV-SW-PV',
                        'GP-GH-SW-GH ',
                        'GP-GO-SW-GY',
                        'GP-MUR-SW-MUR',
                        'GP-GP-SW-GP',
                        'KY-AKU-SW-AU',
                        'KY-DIN-SW-DG',
                        'KY-GG-SW-GG ',
                        'KY-HKT-SW-HKT',
                        'KY-MN-SW-MAD',
                        'KY-MMN-SW-MMN',
                        'KY-RKL-SW-RI',
                        'KY-RA-SW-RA',
                        'KY-PKL-SW-PKL',
                        'KY-KY-SW-KY',
                        'GP-GO-SW-WGL',
                        'KY-KY-SW-XK',
                        'GP-GP-PML-PMT',
                        'GP-GP-PML-PMW',
                        'KY-KY-SW-MRS',
                        'KY-TTY-SW-TT')
                        AND WORO_CIRT_NAME = CIRT_NAME;


GET_BASE_DATA_REC             GET_BASE_DATA%ROWTYPE;

BEGIN

DELETE FROM CLARITY_ADMIN.PENDING_KY_WO_DETAILS;

OPEN GET_BASE_DATA;

LOOP 

FETCH GET_BASE_DATA INTO GET_BASE_DATA_REC ;

EXIT WHEN GET_BASE_DATA%NOTFOUND;

INSERT INTO CLARITY_ADMIN.PENDING_KY_WO_DETAILS
(
LEA,
SERVICE_ORDER,
WORK_ORDER,
CCT_ID,
SERVICE_TYPE,
WORK_GROUP,
ORDER_TYPE,
ASSIGNED_DATE,
TASK_NAME
)
VALUES
(
GET_BASE_DATA_REC.LEA,
GET_BASE_DATA_REC.SERVICE_ORDER,
GET_BASE_DATA_REC.WORK_ORDER,
GET_BASE_DATA_REC.CCT_ID,
GET_BASE_DATA_REC.SERVICE_TYPE,
GET_BASE_DATA_REC.WORK_GROUP,
GET_BASE_DATA_REC.ORDER_TYPE,
GET_BASE_DATA_REC.ASSIGNED_DATE,
GET_BASE_DATA_REC.TASK_NAME
);

END LOOP;

CLOSE GET_BASE_DATA;

COMMIT;

END PENDINGE_KY_SW_WO_DETAILS_DATA;

---- Sasith 11-03-2014 -----
/
