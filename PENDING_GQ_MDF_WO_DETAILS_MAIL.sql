CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PEND_GQ_MDF_WO_DETAILS_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.GQ_WG_RELATED_X_CONN_INFO;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     (SYSDATE, 'MM-DD-YYYY')
     FROM DUAL;
     
    CURSOR C_RG_WO_COUNT IS
    
    SELECT DECODE(RPT_WORO_WORG_NAME,NULL,'TOTAL',RPT_WORO_WORG_NAME) RPT_WORO_WORG_NAME,NEW_CON,CREATE_OR,REMOVAL,DEL_OR,
                  MOD_LOC,MOD_SVS,MOD_CPE,TOTAL
                  FROM (
                    SELECT RPT_WORO_WORG_NAME,
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'CREATE' THEN 'X' ELSE NULL END) "NEW_CON",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'CREATE-OR' THEN 'X' ELSE NULL END) "CREATE_OR",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'DELETE' THEN 'X' ELSE NULL END) "REMOVAL",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'DELETE-OR' THEN 'X' ELSE NULL END) "DEL_OR",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'MODIFY-LOCATION' THEN 'X' ELSE NULL END) "MOD_LOC",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'MODIFY-SERVICE' THEN 'X' ELSE NULL END) "MOD_SVS",
                    COUNT(CASE RPT_WORO_ORDT_TYPE WHEN 'MODIFY-CPE' THEN 'X' ELSE NULL END) "MOD_CPE",
                    COUNT(*) "TOTAL"
                    FROM  CLARITY_ADMIN.GQ_WG_RELATED_X_CONN_INFO
                    GROUP BY ROLLUP (RPT_WORO_WORG_NAME)
                    ORDER BY RPT_WORO_WORG_NAME);    
              
  l_name VARCHAR2(80) := 'GQ_OSP_Pending_WO_Details.xls';
  l_blob CLOB;
  l_body           VARCHAR2(9900);
  v_attr_table_html varchar2(4000);
  dest_lob CLOB;
  qryCtx DBMS_XMLGEN.ctxHandle;
   
    l_str   varchar2(3000);
    l_str1  varchar2(3000);
    l_temp  varchar2(3000);
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
                      /*  p_to_C        IN VARCHAR2,
                        p_to_D        IN VARCHAR2,
                        p_to_E        IN VARCHAR2,
                        p_to_F        IN VARCHAR2, */
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
  l_step        PLS_INTEGER  := 12000; -- make sure you set a multiple of 3 not higher than 24573
  
BEGIN
    

  l_mail_conn := UTL_SMTP.open_connection(p_smtp_host, p_smtp_port);
  UTL_SMTP.helo(l_mail_conn, p_smtp_host);
  UTL_SMTP.mail(l_mail_conn, p_from);
  UTL_SMTP.rcpt(l_mail_conn, p_to);
  UTL_SMTP.rcpt(l_mail_conn, p_to_A);
  UTL_SMTP.rcpt(l_mail_conn, p_to_B);
/*  UTL_SMTP.rcpt(l_mail_conn, p_to_C);
  UTL_SMTP.rcpt(l_mail_conn, p_to_D);
  UTL_SMTP.rcpt(l_mail_conn, p_to_E);
  UTL_SMTP.rcpt(l_mail_conn, p_to_F); */
dbms_output.put_line('@3') ;
  UTL_SMTP.open_data(l_mail_conn);
  
  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_A || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_B || UTL_TCP.crlf);
 /* UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_C || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_D || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_E || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Bcc: ' || p_to_F || UTL_TCP.crlf); */
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

  v_sms_txt := 'Dear%20All%20GQ%20OSP%20pending%20WO%20detail%20report%20as%20@%20today%20contain%20' ||v_ren_CNT|| '%20records.%20Please%20check%20your%20mails. ';
        v_mobile:='716834441'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='0710119775';
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
            DECLARE

            BEGIN

            CLARITY_ADMIN.UPD_RPT_GQ_INFO_TABLE;

            END;
            
       END IF;
        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
        
        open C_DATE;
        fetch C_DATE INTO v_ren_date; 
        close C_DATE;
      
    IF v_ren_CNT >=0 THEN
    
    FOR D_RG_MDF_COUNT IN C_RG_WO_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html 
            || '<tr bgcolor="#CCFFFF"><td><b>'
            || D_RG_MDF_COUNT.RPT_WORO_WORG_NAME 
            || '</td><td>'
            || D_RG_MDF_COUNT.NEW_CON
            || '</td><td>'
            || D_RG_MDF_COUNT.CREATE_OR
            || '</td><td>'
            || D_RG_MDF_COUNT.REMOVAL
            || '</td><td>'
            || D_RG_MDF_COUNT.DEL_OR
            || '</td><td>'
            || D_RG_MDF_COUNT.MOD_LOC
            || '</td><td>'
            || D_RG_MDF_COUNT.MOD_SVS
            || '</td><td>'
            || D_RG_MDF_COUNT.MOD_CPE
            || '</td><td>'
            || D_RG_MDF_COUNT.TOTAL
            || '</td></tr>';
        END LOOP;
        
      qryCtx := DBMS_XMLGEN.newContext('SELECT RPT_SLTA_RH "REGION",RPT_SLTA_HP "PROVINCE",RPT_SLTA_MTCE_AREA "OPMC_AREA",RPT_SLTA_MTCE_CATEGORY "OPMC_TYPE",RPT_AREA_AREA_CODE "RTOM",RPT_WORO_AREA_CODE "LEA",RPT_WORO_SERO_ID "SO_ID",RPT_WORO_ID "WO_ID",RPT_CIRT_DISPLAYNAME "CCT_ID",RPT_WORO_ORDT_TYPE "ORDER_TYPE",RPT_WORO_TASKNAME "TASK_NAME",RPT_WORO_WORG_NAME "WORK_GROUP",RPT_WORO_STAS_ABBREVIATION "WO_STATUS",RPT_SERO_DATECREATED "SO_CREATE_DATE",RPT_WORO_ASSIGNED_DATE "WO_ASSIGNED_DATE",RPT_WORO_DELAY "TOTAL_DELAY",RPT_CUSR_ABBREVIATION "CR",RPT_CUSR_NAME "CUSTOMER_NAME",RPT_CUSR_CUTP_TYPE "CUS_TYPE",RPT_SERO_ATTRI_CONTACT "CUS_CONTACT",RPT_EQUP_LOCN_TTNAME "EQ_LOCATION",RPT_EQUP_EQUT_ABBREVIATION "EQ_TYPE",RPT_EQUP_INDEX "EQ_INDEX",RPT_EQUP_IPADDRESS "EQ_IP",RPT_EQUP_MANR_ABBREVIATION "EQ_MANUFACTURER",RPT_EQUP_EQUM_MODEL "EQ_MODEL",RPT_PORT_CARD_SLOT "CARD_SLOT",RPT_PORT_NAME "PORT",RPT_FRAC_LOCN_TTNAME_MDF "MDF_LOCATION",RPT_FRAC_INDEX_MDF "MDF_INDEX",RPT_FRAU_NAME_MDF "MDF_NAME",RPT_FRAA_POSITION_MDF "UG_POSITION",RPT_FRAC_LOCN_TTNAME_CAB "CAB_LOCATION",RPT_FRAC_INDEX_CAB "CAB_INDEX",RPT_FRAC_NAME_CAB "CAB_NAME",RPT_FRAU_NAME_CAB "CAB_POSITION",RPT_FRAC_LOCN_TTNAME_DP "DP_LOCATION",RPT_FRAC_INDEX_DP "DP_INDEX",RPT_FRAC_NAME_DP "DP_NAME",RPT_FRAA_POSITION_DP "DP_LOOP",RPT_ADDE_STREETNUMBER "HOUSE_NO",RPT_ADDE_STRN_NAMEANDTYPE "STREET",RPT_ADDE_SUBURB "SUBURB",RPT_ADDE_CITY "CITY",RPT_ADDE_POSC_CODE "POSTAL_CODE",RPT_WOOC_TEXT "COMMENT" FROM CLARITY_ADMIN.GQ_WG_RELATED_X_CONN_INFO');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>GQ OSP Pending WO Details'
         || '</title></head><body>'
         || v_cl
         || v_cl
         || '<table width="100%" cellpadding="10" cellspacing="0">'
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
         || 'Please find the Gampaha OSP Pending WO Detail Report AS @ '
         || v_ren_date
         || '.'
         || '<br>'
         || 'Report contain '
         || v_ren_CNT
         || ' Work Orders.'
         || '<br>'
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || '<tr bgcolor="#33FF00">'  ----C0C0C0
         || '<th>'
         || 'WORK_GROUP</th>'
         || '<th>'
         || 'CREATE</th>'
         || '<th>'
         || 'CREATE_OR</th>'
         || '<th>'
         || 'DELETE</th>'
         || '<th>'
         || 'DELETE_OR</th>'
         || '<th>'
         || 'MODIFY_LOCATION</th>'
         || '<th>'
         || 'MODIFY_SERVICE</th>'
         || '<th>'
         || 'MODIFY_CPE</th>'
         || '<th>'
         || 'WORK_ORDER_COUNT</th>'
         || v_cl
         || v_cl
         || v_attr_table_html
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
         || '<br>Engineer - Solution Design & Development'
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
      send_mail(p_to          => 'lakshij@slt.com.lk',
                p_to_A        => 'sepalirg@slt.com.lk', 
                p_to_B        => 'smar@slt.com.lk',
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'GQ OSP Pending WO Details',
                p_text_msg    => l_body,
                p_attach_name => 'GQ_OSP_Pending_WO_Details.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
  
    DELETE FROM CLARITY_ADMIN.GQ_WG_RELATED_X_CONN_INFO;
    
END PEND_GQ_MDF_WO_DETAILS_MAIL;

---- Sasith 12-03-2015 -----
/
