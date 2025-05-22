CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PEND_PEOTV_WO_DETAILS_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     ((SYSDATE), 'MM-DD-YYYY HH:MM:SS')
     FROM DUAL;
     
    CURSOR C_SUMMARY IS
    /* SELECT OWNER,
     COUNT(CASE WHEN (PENDING_WO_DELAY <= 7 ) THEN 'X' ELSE NULL END) "LESS_THAN_7_DAYS",
     COUNT(CASE WHEN (PENDING_WO_DELAY > 7 ) THEN 'X' ELSE NULL END) "MORE_THAN_7_DAYS",
     COUNT(OWNER) "TOTAL"
     FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS
     GROUP BY OWNER
     ORDER BY OWNER;*/
     SELECT OWNER,
     COUNT(CASE WHEN (PENDING_WO_DELAY <= 7 ) THEN 'X' ELSE NULL END) "LESS_THAN_7_DAYS",
     COUNT(CASE WHEN (7 < PENDING_WO_DELAY AND PENDING_WO_DELAY <= 10) THEN 'X' ELSE NULL END) "BETWEEN_7_AND_10_DAYS",
     COUNT(CASE WHEN (PENDING_WO_DELAY > 10) THEN 'X' ELSE NULL END) "MORE_THAN_10_DAYS",
     COUNT(OWNER) "TOTAL"
     FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS
     GROUP BY OWNER
     ORDER BY OWNER;
     
    CURSOR C_PEOTV_WO_COUNT IS
           
    SELECT            
            CASE WHEN 
            (CASE WHEN SUBSTR(REGION,1,2) = 'Z_' THEN SUBSTR(REGION,3) ELSE REGION END) = 'METRO'
            THEN '<tr bgcolor="#CCFFFF"><td> METRO'
            WHEN
            (CASE WHEN SUBSTR(REGION,1,2) = 'Z_' THEN SUBSTR(REGION,3) ELSE REGION END) = 'REGION 1'           
            THEN '<tr bgcolor="#CCFF99"><td> REGION1'    
            WHEN        
            (CASE WHEN SUBSTR(REGION,1,2) = 'Z_' THEN SUBSTR(REGION,3) ELSE REGION END) = 'REGION 2'           
            THEN '<tr bgcolor="#FFFFCC"><td> REGION2' 
            WHEN
            (CASE WHEN SUBSTR(REGION,1,2) = 'Z_' THEN SUBSTR(REGION,3) ELSE REGION END) = 'REGION 3'           
            THEN '<tr bgcolor="#FFCCCC"><td> REGION3'
            ELSE '<tr bgcolor="#FFFF00"><b><td> '|| (CASE WHEN SUBSTR(REGION,1,2) = 'Z_' THEN SUBSTR(REGION,3) ELSE REGION END)
            END AS REGION,
            CASE WHEN SUBSTR(PROVINCE,1,2) = 'Z_' THEN SUBSTR(PROVINCE,3) ELSE PROVINCE END AS PROVINCE,
            CASE WHEN SUBSTR(RTOM,1,2) = 'Z_' THEN SUBSTR(RTOM,3) ELSE RTOM END AS RTOM,
            
            NEW_CON_L,
            NEW_CON_G,
            CREATE_OR_L,
            CREATE_OR_G,
            MOD_LOCATION_L,
            MOD_LOCATION_G,
            MOD_SERVICE_L,
            MOD_SERVICE_G,
            MOD_CPE_L,
            MOD_CPE_G,
            (NEW_CON_L+CREATE_OR_L+MOD_LOCATION_L+MOD_SERVICE_L+MOD_CPE_L) NEW_CONN_SUB_TOTAL_L,
            (NEW_CON_G+CREATE_OR_G+MOD_LOCATION_G+MOD_SERVICE_G+MOD_CPE_G) NEW_CONN_SUB_TOTAL_G,
            REMOVAL_L,
            REMOVAL_G,
            DELETE_OR_L,
            DELETE_OR_G,
            (REMOVAL_L+DELETE_OR_L) DEL_SUB_TOTAL_L,
            (REMOVAL_G+DELETE_OR_G) DEL_SUB_TOTAL_G,
            TOTAL
            FROM
            (

            SELECT 
            CASE WHEN REGION IS NULL THEN 'Z_GRAND TOTAL' ELSE REGION END AS REGION,
            CASE WHEN PROVINCE IS NULL THEN 'Z_SUB TOTAL' ELSE PROVINCE END AS PROVINCE,
            CASE WHEN RTOM IS NULL THEN 'Z_SUB TOTAL' ELSE RTOM END AS RTOM,
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE'  AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "NEW_CON_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE-OR' AND  (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "CREATE_OR_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-LOCATION' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_LOCATION_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-SERVICE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_SERVICE_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-CPE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_CPE_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "REMOVAL_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE-OR' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "DELETE_OR_L",
            
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE'  AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 ) THEN 'X' ELSE NULL END) "NEW_CON_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE-OR' AND  (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "CREATE_OR_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-LOCATION' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_LOCATION_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-SERVICE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_SERVICE_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-CPE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_CPE_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "REMOVAL_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE-OR' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "DELETE_OR_G",
            
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS
            GROUP BY ROLLUP (REGION,PROVINCE,RTOM)
            ORDER BY REGION,PROVINCE,RTOM
            
            ) ;
         CURSOR CLA_PRESENTAGES  IS 
             SELECT
            '<tr bgcolor="#33FF00" ><b><td colspan="3">PERCENTAGE  </td>'||
            '<td>'||ROUND(((NEW_CON_L / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((NEW_CON_G / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((CREATE_OR_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((CREATE_OR_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_LOCATION_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_LOCATION_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_SERVICE_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_SERVICE_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_CPE_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((MOD_CPE_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND((((NEW_CON_L+CREATE_OR_L+MOD_LOCATION_L+MOD_SERVICE_L+MOD_CPE_L)  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND((((NEW_CON_G+CREATE_OR_G+MOD_LOCATION_G+MOD_SERVICE_G+MOD_CPE_G)  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((REMOVAL_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((REMOVAL_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((DELETE_OR_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((DELETE_OR_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND((((REMOVAL_L+DELETE_OR_L)  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND((((REMOVAL_G+DELETE_OR_G)  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((TOTAL  / TOTAL) *100),0) ||'%</td></b></tr>' AS MY_TXT
                    
            FROM         
            (       
            SELECT 
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE'  AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "NEW_CON_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE-OR' AND  (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "CREATE_OR_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-LOCATION' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_LOCATION_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-SERVICE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_SERVICE_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-CPE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "MOD_CPE_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "REMOVAL_L",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE-OR' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 THEN 'X' ELSE NULL END) "DELETE_OR_L",
            
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE'  AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 ) THEN 'X' ELSE NULL END) "NEW_CON_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'CREATE-OR' AND  (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "CREATE_OR_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-LOCATION' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_LOCATION_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-SERVICE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_SERVICE_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'MODIFY-CPE'  AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "MOD_CPE_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "REMOVAL_G",
            COUNT(CASE  WHEN ORDER_TYPE = 'DELETE-OR' AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(ASSIGNED_DATE ,'DD-MON-YY'))) > 7 THEN 'X' ELSE NULL END) "DELETE_OR_G",
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS
            ) ;
     
              
  l_name VARCHAR2(80) := 'PEOTV_Pending_WO_Details.xls';
  l_blob CLOB;
  l_body           VARCHAR2(32700); ---25000
  v_attr_table_html varchar2(20000);  --- 24000
  v_attr_table_1_html varchar2(14000);
  v_get_cal_pres varchar2(2000);
  dest_lob CLOB;
  qryCtx DBMS_XMLGEN.ctxHandle;
   
    l_str   varchar2(3000);
    l_str1  varchar2(3000);
    l_temp  varchar2(3000);
    l_test  varchar2(80);
    V_CL           constant VARCHAR2(2) := CHR(13)||CHR(10);
    v_ren_orders number;
    v_ren_CNT number;
    v_ren_date varchar2(80);
    v_mobile number; 
    v_sms_txt varchar2(400);
    p_ret_msg varchar2(3000);
    v_sms_state varchar2(4000);
    GET_IP_OF_DATABASE VARCHAR2(100) ;
    NODE_1 VARCHAR2(100)  := 'clarityn1';
    NODE_2 VARCHAR2(100)  := 'clarityn2';
    IP_FLAG VARCHAR2(5);
    MY_ATTRI VARCHAR2(30);
  
  
  PROCEDURE send_mail  (p_to          IN VARCHAR2,
                        p_to_A        IN VARCHAR2,
                        p_to_B        IN VARCHAR2,
                        p_to_C        IN VARCHAR2,
                        p_to_D        IN VARCHAR2,
                        p_to_E        IN VARCHAR2,
                        p_to_F        IN VARCHAR2,
                        p_to_G        IN VARCHAR2,
                        p_to_H        IN VARCHAR2,
                        p_to_I        IN VARCHAR2,
                        p_to_J        IN VARCHAR2,
                        p_to_K        IN VARCHAR2,
                        p_to_L        IN VARCHAR2,
                        p_to_M        IN VARCHAR2,
                        p_to_N        IN VARCHAR2,
                        p_to_O        IN VARCHAR2,
                        p_to_P        IN VARCHAR2,
                        p_to_Q        IN VARCHAR2,
                        p_to_R        IN VARCHAR2,
                        p_to_S        IN VARCHAR2,
                        p_to_T        IN VARCHAR2,
                        p_to_U        IN VARCHAR2,
                        p_to_V        IN VARCHAR2,
                        p_to_W        IN VARCHAR2,
                        p_to_X        IN VARCHAR2,
                        p_to_Y        IN VARCHAR2,
                        p_to_Z        IN VARCHAR2,
                        p_to_AA       IN VARCHAR2,
                        p_to_AB       IN VARCHAR2,
                        p_to_AC       IN VARCHAR2,
                        p_to_AD       IN VARCHAR2,
                        p_to_AE       IN VARCHAR2,
                        p_to_AF       IN VARCHAR2,
                        p_to_AG       IN VARCHAR2,
                        p_to_AH       IN VARCHAR2,
                        p_to_AI       IN VARCHAR2,
                        p_to_AJ       IN VARCHAR2,
                        p_to_AK       IN VARCHAR2,
                        p_to_AL       IN VARCHAR2,
                        p_to_AM       IN VARCHAR2,
                        p_to_AN       IN VARCHAR2,
                        p_to_AO       IN VARCHAR2,
                        p_to_AP       IN VARCHAR2,
                        p_to_AQ       IN VARCHAR2,
                        p_to_AR       IN VARCHAR2,
                        p_to_AS       IN VARCHAR2,
                        p_to_AT       IN VARCHAR2,
                        p_to_AU       IN VARCHAR2,
                        p_to_AV       IN VARCHAR2,
                        p_to_AW       IN VARCHAR2,
                        p_to_AX       IN VARCHAR2,
                        p_to_AY       IN VARCHAR2,
                        p_to_AZ       IN VARCHAR2,
                        p_to_BA       IN VARCHAR2,
                        p_to_BB       IN VARCHAR2,
                        p_to_BC       IN VARCHAR2,
                        p_to_BD       IN VARCHAR2,
                        p_to_BE       IN VARCHAR2,
                        p_to_BF       IN VARCHAR2,
                        p_to_BG       IN VARCHAR2,
                        p_to_BH       IN VARCHAR2,
                        p_to_BI       IN VARCHAR2,
                        p_to_BJ       IN VARCHAR2,
                        p_to_BK       IN VARCHAR2,
                        p_to_BL       IN VARCHAR2,
                        p_to_BM       IN VARCHAR2,
                        p_to_BN       IN VARCHAR2,
                        p_to_BO       IN VARCHAR2,
                        p_to_BP       IN VARCHAR2,
                        p_to_BQ       IN VARCHAR2,
                        p_to_BR       IN VARCHAR2,
                        p_to_BS       IN VARCHAR2,
                        p_to_BT       IN VARCHAR2,
                        p_to_BU       IN VARCHAR2,
                        p_to_BV       IN VARCHAR2,
                        p_to_BW       IN VARCHAR2,
                        p_to_BX       IN VARCHAR2,
                        p_to_BY       IN VARCHAR2,
                        p_to_BZ       IN VARCHAR2,
                        p_to_CA       IN VARCHAR2,
                        p_to_CB       IN VARCHAR2,
                        p_to_CC       IN VARCHAR2,
                        p_to_CD       IN VARCHAR2,
                        p_to_CE       IN VARCHAR2,
                        p_to_CF       IN VARCHAR2,
                        p_to_CG       IN VARCHAR2,
                        p_to_CH       IN VARCHAR2,
                        p_to_CI       IN VARCHAR2,
                        p_to_CJ       IN VARCHAR2,
                        p_to_CK       IN VARCHAR2,
                        p_to_CL       IN VARCHAR2,
                        p_to_CM       IN VARCHAR2,
                        p_to_CN       IN VARCHAR2,
                        p_to_CO       IN VARCHAR2,
                        p_to_CP       IN VARCHAR2,
                        p_to_CQ       IN VARCHAR2,
                        p_to_CR       IN VARCHAR2,
                        p_to_CS       IN VARCHAR2,
                        p_to_CT       IN VARCHAR2,
                        p_to_CU       IN VARCHAR2,
                        p_to_CV       IN VARCHAR2,
                        p_to_CW       IN VARCHAR2,
                        p_to_CX       IN VARCHAR2,
                        p_to_CY       IN VARCHAR2,
                        p_to_CZ       IN VARCHAR2,
                        p_to_DA       IN VARCHAR2,
                        p_to_DB       IN VARCHAR2,
                        p_to_DC       IN VARCHAR2,
                        p_to_DD       IN VARCHAR2,
                        p_to_DE       IN VARCHAR2,
                        p_to_DF       IN VARCHAR2,
                        p_to_DG       IN VARCHAR2,
                        p_to_DH       IN VARCHAR2,
                        p_to_DI       IN VARCHAR2,
                        p_to_DJ       IN VARCHAR2,
                        p_to_DK       IN VARCHAR2,
                        p_to_DL       IN VARCHAR2,
                        p_to_DM       IN VARCHAR2,
                        p_to_DN       IN VARCHAR2,
                        p_to_DO       IN VARCHAR2,
                        p_to_DP       IN VARCHAR2,
                        p_to_DQ       IN VARCHAR2,
                        p_to_DR       IN VARCHAR2,
                        p_to_DS       IN VARCHAR2,
                        p_to_DT       IN VARCHAR2,
                        p_to_DU       IN VARCHAR2,
                        p_to_DV       IN VARCHAR2,
                        p_to_DW       IN VARCHAR2,
                        p_to_DX       IN VARCHAR2,
                        p_to_DY       IN VARCHAR2,
                        p_to_DZ       IN VARCHAR2,
                        p_to_EA       IN VARCHAR2,
                        p_to_EB       IN VARCHAR2,
                        p_to_EC       IN VARCHAR2,
                        p_to_ED       IN VARCHAR2,
                        p_to_EE       IN VARCHAR2,
                        p_to_EF       IN VARCHAR2,
                        p_to_EG       IN VARCHAR2,
                        p_to_EH       IN VARCHAR2,
                        p_to_EI       IN VARCHAR2,
                        p_to_EJ       IN VARCHAR2,
                        p_to_EK       IN VARCHAR2,
                        p_to_EL       IN VARCHAR2,
                        p_to_EM       IN VARCHAR2,
                        p_to_EN       IN VARCHAR2,
                        p_to_EO       IN VARCHAR2,
                        p_to_EP       IN VARCHAR2,
                        p_to_EQ       IN VARCHAR2,
                        p_to_ER       IN VARCHAR2,
                        p_to_ES       IN VARCHAR2,
                        p_to_ET       IN VARCHAR2,
                        p_to_EU       IN VARCHAR2,
                        p_to_EV       IN VARCHAR2,
                        p_to_EW       IN VARCHAR2,
                        p_to_EX       IN VARCHAR2,
                        p_to_EY       IN VARCHAR2,
                        p_to_EZ       IN VARCHAR2,
                        p_to_FA       IN VARCHAR2,
                        p_to_FB       IN VARCHAR2,
                        p_to_FC       IN VARCHAR2,
                        p_to_FD       IN VARCHAR2,
                        p_to_FE       IN VARCHAR2,
                        p_to_FF       IN VARCHAR2,
                        p_to_FG       IN VARCHAR2,
                        p_to_FH       IN VARCHAR2,
                        p_to_FI       IN VARCHAR2,
                        p_to_FJ       IN VARCHAR2,
                        p_to_FK       IN VARCHAR2,
                        p_to_FL       IN VARCHAR2,
                        p_to_FM       IN VARCHAR2,
                        p_to_FN       IN VARCHAR2,
                        p_to_FO       IN VARCHAR2,
                        p_to_FP       IN VARCHAR2,
                        p_to_FQ       IN VARCHAR2,
                        p_to_FR       IN VARCHAR2,
                        p_to_FS       IN VARCHAR2,
                        p_to_FT       IN VARCHAR2,
                        p_to_FU       IN VARCHAR2,
                        p_to_FV       IN VARCHAR2,
                        p_to_FW       IN VARCHAR2,
                        p_to_FX       IN VARCHAR2,
                        p_to_FY       IN VARCHAR2,
                        p_to_FZ       IN VARCHAR2,
                        p_to_GA       IN VARCHAR2,
                        p_to_GB       IN VARCHAR2,
                        p_to_GC       IN VARCHAR2,
                        p_to_GD       IN VARCHAR2,
                        p_to_GE       IN VARCHAR2,
                        p_to_GF       IN VARCHAR2,
                        p_to_GG       IN VARCHAR2,
                        p_to_GH       IN VARCHAR2,
                        p_to_GI       IN VARCHAR2,
                        p_from        IN VARCHAR2,
                        p_subject     IN VARCHAR2,
                        p_text_msg    IN VARCHAR2 DEFAULT NULL,
                        p_attach_name IN VARCHAR2 DEFAULT NULL,
                        p_attach_mime IN VARCHAR2 DEFAULT NULL,
                        p_attach_clob IN CLOB DEFAULT NULL,
                        p_smtp_host   IN VARCHAR2,
                        p_smtp_port   IN NUMBER DEFAULT 25)
AS
  l_mail_conn   UTL_SMTP.connection;
  l_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
  l_step        PLS_INTEGER  := 24000; -- make sure you set a multiple of 3 not higher than 24573
  
BEGIN
    

    l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
    UTL_SMTP.helo(l_mail_conn, p_smtp_host);
    UTL_SMTP.mail(l_mail_conn, p_from);
    UTL_SMTP.rcpt(l_mail_conn, p_to);
    UTL_SMTP.rcpt(l_mail_conn, p_to_A);
    UTL_SMTP.rcpt(l_mail_conn, p_to_B);
    UTL_SMTP.rcpt(l_mail_conn, p_to_C);
    UTL_SMTP.rcpt(l_mail_conn, p_to_D);
    UTL_SMTP.rcpt(l_mail_conn, p_to_E);
    UTL_SMTP.rcpt(l_mail_conn, p_to_F);
    UTL_SMTP.rcpt(l_mail_conn, p_to_G);
    UTL_SMTP.rcpt(l_mail_conn, p_to_H);
    UTL_SMTP.rcpt(l_mail_conn, p_to_I);
    UTL_SMTP.rcpt(l_mail_conn, p_to_J);
    UTL_SMTP.rcpt(l_mail_conn, p_to_K);
    UTL_SMTP.rcpt(l_mail_conn, p_to_L);
    UTL_SMTP.rcpt(l_mail_conn, p_to_M);
    UTL_SMTP.rcpt(l_mail_conn, p_to_N);
    UTL_SMTP.rcpt(l_mail_conn, p_to_O);
    UTL_SMTP.rcpt(l_mail_conn, p_to_P);
    UTL_SMTP.rcpt(l_mail_conn, p_to_Q);
    UTL_SMTP.rcpt(l_mail_conn, p_to_R);
    UTL_SMTP.rcpt(l_mail_conn, p_to_S);
    UTL_SMTP.rcpt(l_mail_conn, p_to_T);
    UTL_SMTP.rcpt(l_mail_conn, p_to_U);
    UTL_SMTP.rcpt(l_mail_conn, p_to_V);
    UTL_SMTP.rcpt(l_mail_conn, p_to_W);
    UTL_SMTP.rcpt(l_mail_conn, p_to_X);
    UTL_SMTP.rcpt(l_mail_conn, p_to_Y);
    UTL_SMTP.rcpt(l_mail_conn, p_to_Z);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AR);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AS);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AT);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_AZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BR);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BS);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BT);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_BZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CR);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CS);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CT);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_CZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DR);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DS);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DT);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_DZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_ED);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_ER);
    UTL_SMTP.rcpt(l_mail_conn, p_to_ES);
    UTL_SMTP.rcpt(l_mail_conn, p_to_ET);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_EZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FI);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FJ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FK);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FL);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FM);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FN);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FO);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FP);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FQ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FR);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FS);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FT);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FU);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FV);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FW);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FX);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FY);
    UTL_SMTP.rcpt(l_mail_conn, p_to_FZ);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GA);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GB);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GC);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GD);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GE);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GF);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GG);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GH);
    UTL_SMTP.rcpt(l_mail_conn, p_to_GI);

dbms_output.put_line('@3') ;
  UTL_SMTP.open_data(l_mail_conn);
  
    UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_A || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_B || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_C || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_D || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_E || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_F || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_G || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_H || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_I || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_J || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_K || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_L || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_M || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_N || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_O || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_P || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_Q || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_R || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_S || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_T || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_U || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_V || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_W || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_X || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_Y || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_Z || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AR || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AS || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AT || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BR || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BS || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BT || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CR || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CS || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CT || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_CZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DR || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DS || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DT || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_DZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_ED || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_EQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_ER || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_ES || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_ET || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_EZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FJ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FK || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FL || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FM || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_FN || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FO || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FP || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FQ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FR || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FS || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FT || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FU || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FV || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FW || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FX || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FY || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_FZ || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GA || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GB || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GC || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GD || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GE || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GF || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GG || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_GH || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Bcc: ' || p_to_GI || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
  dbms_output.put_line('@5') ;
  IF p_text_msg IS NOT NULL THEN
   UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
   UTL_SMTP.write_data(l_mail_conn, 'Content-type:text/html;charset=iso-8859-1' || UTL_TCP.crlf || UTL_TCP.crlf);
   UTL_SMTP.write_data(l_mail_conn, p_text_msg);
   UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
dbms_output.put_line('@6') ;
  IF p_attach_name IS NOT NULL THEN
    UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_attach_mime || '; name="' || p_attach_name || '"' || UTL_TCP.crlf);
    UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_attach_name || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
 dbms_output.put_line('@7') ;
    FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_attach_clob) - 1 )/l_step) LOOP
      UTL_SMTP.write_data(l_mail_conn, DBMS_LOB.substr(p_attach_clob, l_step, i * l_step + 1));
    END LOOP;

    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
  dbms_output.put_line('@8') ;
  UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || '--' || UTL_TCP.crlf);
  UTL_SMTP.close_data(l_mail_conn);

  UTL_SMTP.quit(l_mail_conn);

 v_sms_txt := 'Dear%20All%20PEOTV%20pending%20WO%20detail%20report%20as%20@%20today%20contain%20' ||v_ren_CNT|| '%20records.%20Please%20check%20your%20mails. ';
        v_mobile:='716834441'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='0714290391';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
           
END send_mail;

  
  
BEGIN

      SELECT HOST_NAME INTO GET_IP_OF_DATABASE FROM V$INSTANCE;

        IF ((GET_IP_OF_DATABASE = NODE_1) OR (GET_IP_OF_DATABASE = NODE_2)) THEN 
        IP_FLAG := 'Y';
        ELSE 
        IP_FLAG := 'N';
        END IF ;

        IF IP_FLAG = 'Y' THEN
        DELETE FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS;
        CLARITY_ADMIN.PEND_PEOTV_WO_DETAILS_DATA;
        END IF;
        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
        
        open C_DATE;
        fetch C_DATE INTO v_ren_date; 
        close C_DATE;
      
    IF v_ren_CNT >=0 THEN
    
    FOR D_SUMMARY IN C_SUMMARY 
        LOOP
            v_attr_table_1_html := v_attr_table_1_html
            || '<tr bgcolor="#CCFFFF"><td><b>'
            || D_SUMMARY.OWNER  
            || '</td><td>'
            || D_SUMMARY.LESS_THAN_7_DAYS
            || '</td><td>'
            || D_SUMMARY.BETWEEN_7_AND_10_DAYS
            || '</td><td>'
            || D_SUMMARY.MORE_THAN_10_DAYS
            || '</td><td>'
            || D_SUMMARY.TOTAL
            ||'</td></tr>';
        END LOOP;
        
    FOR D_PEOTV_WO_COUNT IN C_PEOTV_WO_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html
            || D_PEOTV_WO_COUNT.REGION 
            || '</td><td>'
            || D_PEOTV_WO_COUNT.PROVINCE
            || '</td><td>'
            || D_PEOTV_WO_COUNT.RTOM
            || '</td><td>'
            || D_PEOTV_WO_COUNT.NEW_CON_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.NEW_CON_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.CREATE_OR_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.CREATE_OR_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_LOCATION_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_LOCATION_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_SERVICE_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_SERVICE_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_CPE_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.MOD_CPE_G
            || '</td><td bgcolor="#66FFFF">'
            || D_PEOTV_WO_COUNT.NEW_CONN_SUB_TOTAL_L
            || '</td><td bgcolor="#66FFFF">'
            || D_PEOTV_WO_COUNT.NEW_CONN_SUB_TOTAL_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.REMOVAL_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.REMOVAL_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.DELETE_OR_L
            || '</td><td>'
            || D_PEOTV_WO_COUNT.DELETE_OR_G
            || '</td><td bgcolor="#CC99FF">'
            || D_PEOTV_WO_COUNT.DEL_SUB_TOTAL_L
            || '</td><td bgcolor="#CC99FF">'
            || D_PEOTV_WO_COUNT.DEL_SUB_TOTAL_G
            || '</td><td>'
            || D_PEOTV_WO_COUNT.TOTAL
            || '</td></tr>';
        END LOOP;
        
        open CLA_PRESENTAGES;
        fetch CLA_PRESENTAGES INTO v_get_cal_pres; 
        close CLA_PRESENTAGES;
        
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>PEOTV Pending WO Details'
         || '</title></head><body>'
         || v_cl
         || v_cl
         || '<table style ="width:100%" ; cellpadding:"3" ; cellspacing:"0">'
         || v_cl
         || v_cl
         || '<tr>'
         || v_cl
         || v_cl
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || '<p>Dear '
         || 'All,'
         || v_cl
         || v_cl
         || '<br><br>'
         || 'Please find the Pending PEOTV WO Detail Report as from 1st January 2014 to '
         || v_ren_date
         || 'Hrs.'
         || '<br>'
         || 'Report contain '
         || v_ren_CNT
         || ' Work Orders.'
         || '<br>'
         || 'PENDING_PEOTV_WO_SUMMARY'
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || '<tr bgcolor="#33FF00">'
         || '<th>OWNER</th>'
         || '<th>LESS_THAN_7_DAYS</th>'
         || '<th>BETWEEN_7_AND_10_DAYS</th>'
         || '<th>MORE_THAN_10_DAYS</th>'
         || '<th>TOTAL</th>'
         || '</tr>'
         || v_cl
         || v_attr_table_1_html
         || v_cl
         || v_cl
         || '</table>'
         || '<br>'
         || '<br>'
         || '<br><br>'
         || 'PENDING_PEOTV_WO_DETAILS'
         || '<table cellpadding="3" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl 
         || '<tr bgcolor="#33FF00">'
         || '<th ROWSPAN="2">REGION</th>'
         || '<th ROWSPAN="2">PROVINCE</th>'
         || '<th ROWSPAN="2">RTOM</th>'
         || '<th COLSPAN="2">CREATE </th>'
         || '<th COLSPAN="2">CREATE OR</th>'
         || '<th COLSPAN="2">MOD LOCATION</th>'
         || '<th COLSPAN="2">MOD SERVICE</th>'
         || '<th COLSPAN="2">MOD CPE</th>'
         || '<th COLSPAN="2">NEW CON SUB TOTAL</th>'
         || '<th COLSPAN="2">DELETE</th>'
         || '<th COLSPAN="2">DELETE OR</th>'
         || '<th COLSPAN="2">DEL SUB TOTAL</th>' 
         || '<th ROWSPAN="2">TOTAL</th>'
         || '</tr>'
         || '<tr bgcolor="#33FF00">'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th><= 7 </th>'
         || '<th>> 7 </th>'
         || '<th> <= 7 </th>'
         || '<th>>7 </th>'
         || '<th><= 7 </th>'
         || '<th>>7 </th>'
         || '<th><= 7 </th>' 
         || '<th>> 7 </th>'  
         || '</tr>'
         || v_cl
         || v_cl
         || v_cl
         || v_attr_table_html
         || v_get_cal_pres
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || '</table>'
         || v_cl
         || v_cl
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || '<br><br><i>Best regards'
         || v_cl
         || v_cl
         || '<br>Dinesh Perera.'
         || '<br>Engineer - Solution Design & Implementation'
         || '<br>Direct         011-2445966'
         || '<br>Mobile         071-6834441'
         || '<br>Facsimile      011-2393093'
         || '<br>E-mail         cdinesh@slt.com.lk'
         || v_cl
         || v_cl
         || '</i></p></span></table></body></html>';
         dbms_output.put_line('@5') ;
         end;
         
  
  
      dbms_output.put_line('@1') ;
      send_mail(p_to          => 'chinwije@slt.com.lk',
                p_to_A        => 'smjm@slt.com.lk',
                p_to_B        => 'subhashini@slt.com.lk',
                p_to_C        => 'nalith@slt.com.lk',
                p_to_D        => 'kumuduniperera@slt.com.lk',
                p_to_E        => 'risthy@slt.com.lk',
                p_to_F        => 'aja@slt.com.lk',
                p_to_G        => 'sugandi@slt.com.lk',
                p_to_H        => 'asoka@slt.com.lk',
                p_to_I        => 'baba@slt.com.lk',
                p_to_J        => 'chandimam@slt.com.lk',
                p_to_K        => 'cwijeweera@slt.com.lk',
                p_to_L        => 'damunu@slt.com.lk',
                p_to_M        => 'dspl@slt.com.lk',
                p_to_N        => 'jayatilake@slt.com.lk',
                p_to_O        => 'kogularajah@slt.com.lk',
                p_to_P        => 'mahes@slt.com.lk',
                p_to_Q        => 'malkanthi@slt.com.lk',
                p_to_R        => 'manula@slt.com.lk',
                p_to_S        => 'munaz@slt.com.lk',
                p_to_T        => 'nandananb@slt.com.lk',
                p_to_U        => 'navani@slt.com.lk',
                p_to_V        => 'nazeer@slt.com.lk',
                p_to_W        => 'nihal@slt.com.lk',
                p_to_X        => 'palithapw@slt.com.lk',
                p_to_Y        => 'purodha@slt.com.lk',
                p_to_Z        => 'saliya@slt.com.lk',
                p_to_AA        => 'sundaram@slt.com.lk',
                p_to_AB        => 'venura69@slt.com.lk',
                p_to_AC        => 'wije@slt.com.lk',
                p_to_AD        => 'wnafernando@slt.com.lk',
                p_to_AE        => 'gssampath@slt.com.lk',
                p_to_AF        => 'rajivw@slt.com.lk',
                p_to_AG        => 'dushyantha@slt.com.lk',
                p_to_AH        => 'sachitha@slt.com.lk',
                p_to_AI        => 'arunar@slt.com.lk',
                p_to_AJ        => 'bandaradjms@slt.com.lk',
                p_to_AK        => 'cpssdal@slt.com.lk',
                p_to_AL        => 'dhanushkam@slt.com.lk',
                p_to_AM        => 'dilum@slt.com.lk',
                p_to_AN        => 'jeevasiri@slt.com.lk',
                p_to_AO        => 'maldani@slt.com.lk',
                p_to_AP        => 'nowzath@slt.com.lk',
                p_to_AQ        => 'ratna@slt.com.lk',
                p_to_AR        => 'sanath@slt.com.lk',
                p_to_AS        => 'shiromia@slt.com.lk',
                p_to_AT        => 'sunethra@slt.com.lk',
                p_to_AU        => 'vimalarupan@slt.com.lk',
                p_to_AV        => 'wasanthak@slt.com.lk',
                p_to_AW        => 'wathsala_s@slt.com.lk',
                p_to_AX        => 'wijayananda@slt.com.lk',
                p_to_AY        => 'kjana@slt.com.lk',
                p_to_AZ        => 'chandran@slt.com.lk',
                p_to_BA        => 'anubalasuriya@slt.com.lk',
                p_to_BB        => 'basnayake@slt.com.lk',
                p_to_BC        => 'chamarae@slt.com.lk',
                p_to_BD        => 'jsuranga@slt.com.lk',
                p_to_BE        => 'kelump@slt.com.lk',
                p_to_BF        => 'mala_k@slt.com.lk',
                p_to_BG        => 'sakeen@slt.com.lk',
                p_to_BH        => 'sljude@slt.com.lk',
                p_to_BI        => 'sspriyat@slt.com.lk',
                p_to_BJ        => 'wasank@slt.com.lk',
                p_to_BK        => 'wsnperera@slt.com.lk',
                p_to_BL        => 'shirazm@slt.com.lk',
                p_to_BM        => 'malisandya@slt.com.lk',
                p_to_BN        => 'akmnilam@slt.com.lk',
                p_to_BO        => 'geenadi@slt.com.lk',
                p_to_BP        => 'ashokak@slt.com.lk',
                p_to_BQ        => 'asitha@slt.com.lk',
                p_to_BR        => 'chandrakumara@slt.com.lk',
                p_to_BS        => 'chandic@slt.com.lk',
                p_to_BT        => 'chandranim@slt.com.lk',
                p_to_BU        => 'lathad@slt.com.lk',
                p_to_BV        => 'ilangad@slt.com.lk',
                p_to_BW        => 'dmsenavi@slt.com.lk',
                p_to_BX        => 'gagarinie@slt.com.lk',
                p_to_BY        => 'gaminih@slt.com.lk',
                p_to_BZ        => 'geethanjalie@slt.com.lk',
                p_to_CA        => 'joyce@slt.com.lk',
                p_to_CB        => 'hubert@slt.com.lk',
                p_to_CC        => 'rexyp@slt.com.lk',
                p_to_CD        => 'wijesinghe@slt.com.lk',
                p_to_CE        => 'malasinghe@slt.com.lk',
                p_to_CF        => 'priyanganee@slt.com.lk',
                p_to_CG        => 'manelm@slt.com.lk',
                p_to_CH        => 'melani@slt.com.lk',
                p_to_CI        => 'nalikajaya@slt.com.lk',
                p_to_CJ        => 'ndnayana@slt.com.lk',
                p_to_CK        => 'costa@slt.com.lk',
                p_to_CL        => 'rkwickrama@slt.com.lk',
                p_to_CM        => 'ranjeewa@slt.com.lk',
                p_to_CN        => 'ranmini@slt.com.lk',
                p_to_CO        => 'ruwanm@slt.com.lk',
                p_to_CP        => 'sumanalatha@slt.com.lk',
                p_to_CQ        => 'skarunarathna@slt.com.lk',
                p_to_CR        => 'sandyak@slt.com.lk',
                p_to_CS        => 'sarathb@slt.com.lk',
                p_to_CT        => 'subangani@slt.com.lk',
                p_to_CU        => 'shanthaksr@slt.com.lk',
                p_to_CV        => 'udithas@slt.com.lk',
                p_to_CW        => 'nilupul@slt.com.lk',
                p_to_CX        => 'vincentp@slt.com.lk',
                p_to_CY        => 'jayawardhana@slt.com.lk',
                p_to_CZ        => 'aselaj@slt.com.lk',
                p_to_DA        => 'mneahmed@slt.com.lk',
                p_to_DB        => 'ahamed@slt.com.lk',
                p_to_DC        => 'ajanfas@slt.com.lk',
                p_to_DD        => 'kasune@slt.com.lk',
                p_to_DE        => 'supunuj@slt.com.lk',
                p_to_DF        => 'ssaman@slt.com.lk',
                p_to_DG        => 'cperera@slt.com.lk',
                p_to_DH        => 'dhammith@slt.com.lk',
                p_to_DI        => 'gobinath@slt.com.lk',
                p_to_DJ        => 'hasaranga@slt.com.lk',
                p_to_DK        => 'hemanthaw@slt.com.lk',
                p_to_DL        => 'kasp@slt.com.lk',
                p_to_DM        => 'medhavi@slt.com.lk',
                p_to_DN        => 'minoo@slt.com.lk',
                p_to_DO        => 'mohanku@slt.com.lk',
                p_to_DP        => 'muditha@slt.com.lk',
                p_to_DQ        => 'nalin@slt.com.lk',
                p_to_DR        => 'nilankam@slt.com.lk',
                p_to_DS        => 'pradeepk@slt.com.lk',
                p_to_DT        => 'rangaj@slt.com.lk',
                p_to_DU        => 'rangar@slt.com.lk',
                p_to_DV        => 'rasitha@slt.com.lk',
                p_to_DW        => 'sivananthan@slt.com.lk',
                p_to_DX        => 'vijayantha@slt.com.lk',
                p_to_DY        => 'uiananda@slt.com.lk',
                p_to_DZ        => 'wmupali@slt.com.lk',
                p_to_EA        => 'yoges@slt.com.lk',
                p_to_EB        => 'senarathna@slt.com.lk',
                p_to_EC        => 'ineshm@slt.com.lk',
                p_to_ED        => 'puveehan@slt.com.lk',
                p_to_EE        => 'sklal@slt.com.lk',
                p_to_EF        => 'abrames@slt.com.lk',
                p_to_EG        => 'asbamila@slt.com.lk',
                p_to_EH        => 'bandaransa@slt.com.lk',
                p_to_EI        => 'kapilakn@slt.com.lk',
                p_to_EJ        => 'manju@slt.com.lk',
                p_to_EK        => 'kishanthan@slt.com.lk',
                p_to_EL        => 'laksirip@slt.com.lk',
                p_to_EM        => 'lidira@slt.com.lk',
                p_to_EN        => 'manel@slt.com.lk',
                p_to_EO        => 'palan@slt.com.lk',
                p_to_EP        => 'shermin@slt.com.lk',
                p_to_EQ        => 'thanuja@slt.com.lk',
                p_to_ER        => 'gayanis@slt.com.lk',
                p_to_ES        => 'aamara@slt.com.lk',
                p_to_ET        => 'yasindul@slt.com.lk',
                p_to_EU        => 'kirupa@slt.com.lk',
                p_to_EV        => 'iblinel@slt.com.lk',
                p_to_EW        => 'imantha@slt.com.lk',
                p_to_EX        => 'samank@slt.com.lk',
                p_to_EY        => 'sisirap@slt.com.lk',
                p_to_EZ        => 'anuruddha@slt.com.lk',
                p_to_FA        => 'banduladw@slt.com.lk',
                p_to_FB        => 'chethana@slt.com.lk',
                p_to_FC        => 'dineshg@slt.com.lk',
                p_to_FD        => 'iroshan@slt.com.lk',
                p_to_FE        => 'karawita@slt.com.lk',
                p_to_FF        => 'mangala_b@slt.com.lk',
                p_to_FG        => 'mpathma@slt.com.lk',
                p_to_FH        => 'navani@slt.com.lk',
                p_to_FI        => 'samantha@slt.com.lk',
                p_to_FJ        => 'sanjaya@slt.com.lk',
                p_to_FK        => 'sarath@slt.com.lk',
                p_to_FL        => 'weli@slt.com.lk',
                p_to_FM        => 'yasith@slt.com.lk',
                p_to_FN        => 'arunam@slt.com.lk',
                p_to_FO        => 'sagas@slt.com.lk',
                p_to_FP        => 'athulal@slt.com.lk',
                p_to_FQ        => 'keerthisinghe@slt.com.lk',
                p_to_FR        => 'jayakody@slt.com.lk',
                p_to_FS        => 'lakshij@slt.com.lk',
                p_to_FT        => 'apjaya@slt.com.lk',
                p_to_FU        => 'malraj@slt.com.lk',
                p_to_FV        => 'ruchiraw@slt.com.lk',
                p_to_FW        => 'kaminda@slt.com.lk',
                p_to_FX        => 'amilal@slt.com.lk',
                p_to_FY        => 'amilap@slt.com.lk',
                p_to_FZ        => 'sampath@slt.com.lk',
                p_to_GA        => 'shyamalik@slt.com.lk',
                p_to_GB        => 'madhushasr@slt.com.lk',
                p_to_GC        => 'sudayasiri@slt.com.lk',
                p_to_GD        => 'sspriyat@slt.com.lk',
                p_to_GE        => 'chandig@slt.com.lk',
                p_to_GF        => 'rtom@slt.com.lk',
                p_to_GG        => 'nihal@slt.com.lk',
                p_to_GH        => 'srnathan@slt.com.lk',
                p_to_GI        => 'cdinesh@slt.com.lk',
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'PEOTV Pending WO Details',
                p_text_msg    => l_body,
                p_attach_name => 'PEOTV_Pending_WO_Details.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_PEOTV_WO_DETAILS;
    
END PEND_PEOTV_WO_DETAILS_MAIL;

---- Sasith 11-11-2014 -----
/
