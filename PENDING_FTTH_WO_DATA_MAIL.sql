CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_FTTH_WO_DATA_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_FTTH_WO;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     (SYSDATE, 'MM-DD-YYYY@HH24:MI:SS')
     FROM DUAL;
     
    CURSOR C_SUMMARY IS
     SELECT OWNER,
     COUNT(CASE WHEN (PENDING_WO_DELAY <= 7 ) THEN 'X' ELSE NULL END) "LESS_THAN_7",
     COUNT(CASE WHEN (7 < PENDING_WO_DELAY AND PENDING_WO_DELAY <= 14) THEN 'X' ELSE NULL END) "BETWEEN_7_TO_14",
     COUNT(CASE WHEN (14 < PENDING_WO_DELAY AND PENDING_WO_DELAY <= 21) THEN 'X' ELSE NULL END) "BETWEEN_14_TO_21",
     COUNT(CASE WHEN (PENDING_WO_DELAY > 21) THEN 'X' ELSE NULL END) "MORE_THAN_21",
     COUNT(OWNER) "TOTAL"
     FROM CLARITY_ADMIN.PENDING_FTTH_WO
     GROUP BY OWNER
     ORDER BY OWNER;
     
    CURSOR C_FTTH_WO_COUNT IS
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
            CASE WHEN SUBSTR(OWNER,1,2) = 'Z_' THEN SUBSTR(OWNER,3) ELSE OWNER END AS OWNER,           
            AB_FTTH_L,
            AB_FTTH_M,
            AB_FTTH_N,
            AB_FTTH_G,
            BB_INTERNET_FTTH_L,
            BB_INTERNET_FTTH_M,
            BB_INTERNET_FTTH_N,
            BB_INTERNET_FTTH_G,
            E_IPTV_FTTH_L,
            E_IPTV_FTTH_M,
            E_IPTV_FTTH_N,
            E_IPTV_FTTH_G,
            V_VOICE_FTTH_L,
            V_VOICE_FTTH_M,
            V_VOICE_FTTH_N,
            V_VOICE_FTTH_G,
            ORDER_COUNT,
            TOTAL
            FROM
            (
            SELECT 
            CASE WHEN REGION IS NULL THEN 'Z_GRAND TOTAL' ELSE REGION END AS REGION,
            CASE WHEN PROVINCE IS NULL THEN 'Z_SUB TOTAL' ELSE PROVINCE END AS PROVINCE,
            CASE WHEN RTOM IS NULL THEN 'Z_SUB TOTAL' ELSE RTOM END AS RTOM,
            CASE WHEN OWNER IS NULL THEN 'Z_SUB TOTAL' ELSE OWNER END AS OWNER,
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "AB_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_L",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 14 ) THEN 'X' ELSE NULL END) "AB_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_M",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <=21 ) THEN 'X' ELSE NULL END) "AB_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_N",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "AB_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_G",
            
            COUNT(DISTINCT(CRM_OR)) "ORDER_COUNT",
            
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_FTTH_WO
            GROUP BY ROLLUP (REGION,PROVINCE,RTOM,OWNER)
            ORDER BY REGION,PROVINCE,RTOM,OWNER 
            );
            
         CURSOR CLA_PRESENTAGES  IS 
             SELECT
            '<tr bgcolor="#33FF00" ><b><td colspan="4">PERCENTAGE  </td>'||
            '<td>'||ROUND(((AB_FTTH_L / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((AB_FTTH_M / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((AB_FTTH_N / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((AB_FTTH_G / TOTAL) *100),0)||'%</td>'||
            '<td>'||ROUND(((BB_INTERNET_FTTH_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((BB_INTERNET_FTTH_M  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((BB_INTERNET_FTTH_N  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((BB_INTERNET_FTTH_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((E_IPTV_FTTH_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((E_IPTV_FTTH_M  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((E_IPTV_FTTH_N  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((E_IPTV_FTTH_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((V_VOICE_FTTH_L  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((V_VOICE_FTTH_M  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((V_VOICE_FTTH_N  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||ROUND(((V_VOICE_FTTH_G  / TOTAL) *100),0) ||'%</td>'||
            '<td>'||''||
            '<td>'||ROUND(((TOTAL  / TOTAL) *100),0) ||'%</td></b></tr>' AS MY_TXT
                    
            FROM         
            (       
            SELECT 
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "AB_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_L",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 7 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_L",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <= 14 ) THEN 'X' ELSE NULL END) "AB_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_M",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND (7<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=14 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_M",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) <=21 ) THEN 'X' ELSE NULL END) "AB_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_N",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND (14<(TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) AND (TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY')))<=21 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_N",
            
            COUNT(CASE WHEN SERVICE_TYPE = 'AB-FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "AB_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'BB-INTERNET FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "BB_INTERNET_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'E-IPTV FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "E_IPTV_FTTH_G",
            COUNT(CASE WHEN SERVICE_TYPE = 'V-VOICE FTTH' AND ((TRUNC(SYSDATE) - TRUNC(TO_DATE(WO_ASSIGNED_DATE ,'DD-MON-YY'))) >21 ) THEN 'X' ELSE NULL END) "V_VOICE_FTTH_G",
            COUNT(DISTINCT(CRM_OR)) "ORDER_COUNT",
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_FTTH_WO
            ) ;
         
  l_name VARCHAR2(80) := 'FTTH_Pending_WO_Details.xls';
  l_blob CLOB;
  l_body            VARCHAR2(32767);  ---- 14000
  v_attr_table_html varchar2(32767);  ---  12000 20000
  v_attr_table_1_html varchar2(32767);  ---- 32767
  v_get_cal_pres    varchar2(20000);   ----- 2000
  dest_lob CLOB;
  qryCtx DBMS_XMLGEN.ctxHandle;
   
    l_str   varchar2(3000); 
    l_str1  varchar2(3000);
    l_temp  varchar2(10000);   ---- 6000
    l_test  varchar2(80);
    V_CL            constant VARCHAR2(2) := CHR(13)||CHR(10);
    v_ren_orders number;
    v_ren_CNT number;
    v_ren_date varchar2(80);
    v_mobile number; 
    v_sms_txt varchar2(200);
    p_ret_msg varchar2(3000);
    v_sms_state varchar2(4000);
    GET_IP_OF_DATABASE VARCHAR2(100) ;
    NODE_1 VARCHAR2(100)  := 'clarityn1';
    NODE_2 VARCHAR2(100)  := 'clarityn2';
    IP_FLAG VARCHAR2(5);
  
  
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
  l_boundary    VARCHAR2(100) := '----=*#abc1234321cba#*='; ----- 50
  l_step        PLS_INTEGER  := 18000; -- make sure you set a multiple of 3 not higher than 24573  --- 12000
  
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
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_V || UTL_TCP.crlf);
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

  v_sms_txt := 'Dear%20All%20FTTH%20Pending%20WO%20detail%20report%20as%20@%20'||v_ren_date||'%20Hrs%20contain%20'||v_ren_CNT||'%20records.%20Please%20check%20your%20mails.';
  
        v_mobile:='94714102000'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='94714728503';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
        v_mobile:='94714311725';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
        v_mobile:='94716834441';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
           
END send_mail;

    FUNCTION GET_VAL(IN_VAL IN VARCHAR2) 
    RETURN VARCHAR2
    IS
        RT_VAL VARCHAR2(100);
    BEGIN
       IF 'OPMC' = IN_VAL THEN
            RT_VAL := ' bgcolor=#90EE90';
       ELSIF 'CSU' = IN_VAL THEN
            RT_VAL := ' bgcolor=#FFB6C1';
       ELSIF 'HQ_TEAM' = IN_VAL THEN
            RT_VAL := ' bgcolor=#87CEFA';
       END IF;

       RETURN RT_VAL;
    END;

  
BEGIN

      DELETE FROM CLARITY_ADMIN.PENDING_FTTH_WO;
       
       SELECT HOST_NAME INTO GET_IP_OF_DATABASE FROM V$INSTANCE;

        IF ((GET_IP_OF_DATABASE = NODE_1) OR (GET_IP_OF_DATABASE = NODE_2)) THEN 
        IP_FLAG := 'Y';
        ELSE 
        IP_FLAG := 'N';
        END IF ;

        IF IP_FLAG = 'Y' THEN
        CLARITY_ADMIN.PENDING_FTTH_WO_DATA;
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
            || D_SUMMARY.LESS_THAN_7
            || '</td><td>'
            || D_SUMMARY.BETWEEN_7_TO_14
            || '</td><td>'
            || D_SUMMARY.BETWEEN_14_TO_21
            || '</td><td>'
            || D_SUMMARY.MORE_THAN_21
            || '</td><td>'
            || D_SUMMARY.TOTAL
            ||'</td></tr>';
        END LOOP;
    
     /* FOR D_FTTH_WO_COUNT IN C_FTTH_WO_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html 
            || D_FTTH_WO_COUNT.REGION 
            || '</td><td>'
            || D_FTTH_WO_COUNT.PROVINCE 
            || '</td><td>'
            || D_FTTH_WO_COUNT.RTOM
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.OWNER
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.AB_FTTH_L
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.AB_FTTH_M
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.AB_FTTH_N
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.AB_FTTH_G
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.BB_INTERNET_FTTH_L
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.BB_INTERNET_FTTH_M
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.BB_INTERNET_FTTH_N
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.BB_INTERNET_FTTH_G
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.E_IPTV_FTTH_L
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.E_IPTV_FTTH_M
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.E_IPTV_FTTH_N
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.E_IPTV_FTTH_G
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.V_VOICE_FTTH_L
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.V_VOICE_FTTH_M
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.V_VOICE_FTTH_N
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.V_VOICE_FTTH_G
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.ORDER_COUNT
            || '</td><td'||GET_VAL(D_FTTH_WO_COUNT.OWNER)||'>'
            || D_FTTH_WO_COUNT.TOTAL 
            ||'</td></tr>';
        END LOOP;
        
        open CLA_PRESENTAGES;
        fetch CLA_PRESENTAGES INTO v_get_cal_pres; 
        close CLA_PRESENTAGES;      */
         
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_FTTH_WO');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      
      begin
      l_body := '<html><head><title>FTTH Pending WO Details'
         || '</title></head><body>'
         || '<table width="20%" cellpadding="1" cellspacing="0">'
         || v_cl
         || '<tr>'
         || v_cl
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || '<p>Dear '
         || 'All,'
         || '<br><br>'
         || 'Please find the FTTH Pending Work Order Detail Report AS @ '
         || v_ren_date 
         || 'Hrs.'
         || '<br>'
         || 'Report contain '
         || v_ren_CNT
         || ' Work Orders.'
         || '<br>'
         || '<br>'
         || '<br>'
         || 'FTTH_WO_SUMMARY'
         || '<table cellpadding="1" cellspacing="0.05" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || '<tr bgcolor="#33FF00">'
         || '<th>OWNER</th>'
         || '<th>LESS_THAN_7</th>'
         || '<th>BETWEEN_7_TO_14</th>'
         || '<th>BETWEEN_14_TO_21</th>'
         || '<th>MORE_THAN_21</th>'
         || '<th>TOTAL</th>'
         || '</tr>'
         || v_attr_table_1_html
         || '</table>' 
         || '<br>'
         || '<br>'
         || v_cl
       /*  || 'FTTH_WO_DETAILS'
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || '<tr bgcolor="#33FF00">'
         || '<th ROWSPAN="2">REGION</th>'
         || '<th ROWSPAN="2">PROVINCE</th>'
         || '<th ROWSPAN="2">RTOM</th>'
         || '<th ROWSPAN="2">OWNER</th>'
         || '<th COLSPAN="2">AB_FTTH </th>'
         || '<th COLSPAN="2">BB_INTERNET_FTTH</th>'
         || '<th COLSPAN="2">E_IPTV_FTTH</th>'
         || '<th COLSPAN="2">V_VOICE_FTTH</th>'
         || '<th ROWSPAN="2">ORDER_COUNT</th>'
         || '<th ROWSPAN="2">TOTAL</th>'
         || '</tr>'
         || '<tr bgcolor="#33FF00">'
         || '<th>D<=7 </th>'
         || '<th>7>D<=14 </th>'
         || '<th>14>D<=21 </th>'
         || '<th>D>21 </th>'
         || '<th>D<=7 </th>'
         || '<th>7>D<=14 </th>'
         || '<th>14>D<=21 </th>'
         || '<th>D>21 </th>'
         || '<th>D<=7 </th>'
         || '<th>7>D<=14 </th>'
         || '<th>14>D<=21 </th>'
         || '<th>D>21 </th>'
         || '<th>D<=7 </th>'
         || '<th>7>D<=14 </th>'
         || '<th>14>D<=21 </th>'
         || '<th>D>21 </th>'
         || '</tr>'
         || v_cl
         || v_attr_table_html
         || v_get_cal_pres
         || v_cl
         || '</table>'*/
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || '<br><br><i>Best regards'
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
      send_mail(p_to          => 'chinwije@slt.com.lk',  ---- chinwije
                p_to_A        => 'manjula@slt.com.lk',
                p_to_B        => 'lal@slt.com.lk',
                p_to_C        => 'sampath@slt.com.lk',
                p_to_D        => 'yasith@slt.com.lk',
                p_to_E        => 'iroshan@slt.com.lk',
                p_to_F        => 'priyanjana@slt.com.lk',
                p_to_G        => 'dspl@slt.com.lk',
                p_to_H        => 'vitharanage@slt.com.lk',
                p_to_I        => 'nkalhari@slt.com.lk',
                p_to_J        => 'chandimam@slt.com.lk',
                p_to_K        => 'damunu@slt.com.lk',
                p_to_L        => 'muzamils@slt.com.lk',
                p_to_M        => 'indirau@slt.com.lk',
                p_to_N        => 'ruwanij@slt.com.lk',
                p_to_O        => 'hemanthe@slt.com.lk',
                p_to_P        => 'arunas@slt.com.lk',
                p_to_Q        => 'ajithv@slt.com.lk',
                p_to_R        => 'rubini@slt.com.lk',
                p_to_S        => 'kanthig@slt.com.lk',
                p_to_T        => 'sundararany@slt.com.lk',
                p_to_U        => 'vimaladevi@slt.com.lk',
                p_to_V        => 'damayanthif@slt.com.lk',
                p_to_W        => 'cdinesh@slt.com.lk',
                p_to_X        => 'anuruddha@slt.com.lk',
                p_to_Y        => 'banduladw@slt.com.lk ',
                p_to_Z        => 'chethana@slt.com.lk ',
                p_to_AA       => 'dineshg@slt.com.lk',
                p_to_AB       => 'iroshan@slt.com.lk ',
                p_to_AC       => 'karawita@slt.com.lk ',
                p_to_AD       => 'mangala_b@slt.com.lk ',
                p_to_AE       => 'mpathma@slt.com.lk ',
                p_to_AF       => 'navani@slt.com.lk ',
                p_to_AG       => 'samantha@slt.com.lk ',
                p_to_AH       => 'sanjaya@slt.com.lk ',
                p_to_AI       => 'sarath@slt.com.lk',
                p_to_AJ       => 'weli@slt.com.lk',
                p_to_AK       => 'smjm@slt.com.lk ',
                p_to_AL       => 'sklal@slt.com.lk',
                p_to_AM       => 'nalith@slt.com.lk',
                p_to_AN       => 'sachitha@slt.com.lk',
                p_to_AO       => 'abrames@slt.com.lk ',
                p_to_AP       => 'asbamila@slt.com.lk ',
                p_to_AQ       => 'baba@slt.com.lk ',
                p_to_AR       => 'bandaransa@slt.com.lk ',
                p_to_AS       => 'jayatilake@slt.com.lk ',
                p_to_AT       => 'kapilakn@slt.com.lk ',
                p_to_AU       => 'kishanthan@slt.com.lk ',
                p_to_AV       => 'laksirip@slt.com.lk ',
                p_to_AW       => 'lidira@slt.com.lk ',
                p_to_AX       => 'mahes@slt.com.lk ',
                p_to_AY       => 'manel@slt.com.lk ',
                p_to_AZ       => 'nandananb@slt.com.lk ',
                p_to_BA       => 'nazeer@slt.com.lk ',
                p_to_BB       => 'palan@slt.com.lk ',
                p_to_BC       => 'shermin@slt.com.lk',
                p_to_BD       => 'thanuja@slt.com.lk',
                p_to_BE       => 'dushyantha@slt.com.lk',
                p_to_BF       => 'manchanayake@slt.com.lk',
                p_to_BG       => 'chandig@slt.com.lk',
                p_to_BH       => 'sumal@slt.com.lk',
                p_to_BI       => 'sanjee@slt.com.lk',
                p_to_BJ       => 'cpou@slt.com.lk',
                p_to_BK       => 'lakshij@slt.com.lk',
                p_to_BL       => 'subhashini@slt.com.lk',
                p_to_BM       => 'rangaj@slt.com.lk',
                p_to_BN       => 'vijayantha@slt.com.lk',
                p_to_BO       => 'chamilams@slt.com.lk',
                p_to_BP       => 'medhavi@slt.com.lk',
                p_to_BQ       => 'jeevasiri@slt.com.lk',
                p_to_BR       => 'senarathna@slt.com.lk',
                p_to_BS       => 'dhammith@slt.com.lk',
                p_to_BT       => 'chathurid@slt.com.lk',
                p_to_BU       => 'ialahakoon@slt.com.lk',
                p_to_BV       => 'rasangika@slt.com.lk',
                p_to_BW       => 'rushana@slt.com.lk',
                p_to_BX       => 'surangawsl@slt.com.lk',
                p_to_BY       => 'kalyani@slt.com.lk',
                p_to_BZ       => 'pani@slt.com.lk',
                p_to_CA       => 'sspriyat@slt.com.lk',
                p_to_CB       => 'chandig@slt.com.lk',
                p_to_CC       => 'lakmal@slt.com.lk',
                p_to_CD       => 'sisirap@slt.com.lk',
                p_to_CE       => 'samank@slt.com.lk',
                p_to_CF       => 'iblinel@slt.com.lk',
                p_to_CG       => 'imantha@slt.com.lk',
                p_to_CH       => 'kirupa@slt.com.lk',
                p_to_CI       => 'rtom@slt.com.lk',
                p_to_CJ       => 'nihal@slt.com.lk',
                p_to_CK       => 'srnathan@slt.com.lk',
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'FTTH Pending WO Details',
                p_text_msg    => l_body,
                p_attach_name => 'FTTH_Pending_WO_Details.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
          
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_FTTH_WO;
    
END PENDING_FTTH_WO_DATA_MAIL;

---- Dinesh Perera 24-08-2014 -----
---- Dinesh Perera Edited 26-01-2016 ----
/
