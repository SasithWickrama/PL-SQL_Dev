CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_ENTERPRICE_DATA_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT COUNT(*)
     FROM CLARITY_ADMIN.PENDING_ETHERNET_DATA;
         
  l_name VARCHAR2(80) := 'Pending_Data_Services.xls';
  l_blob CLOB;
  l_blob2 CLOB;
  l_body           VARCHAR2(9900);
  dest_lob CLOB;
  qryCtx DBMS_XMLGEN.ctxHandle;
   
    l_str   varchar2(3000);
    l_str1  varchar2(3000);
    l_temp  varchar2(3000);
    l_test  varchar2(80);
    V_CL            constant VARCHAR2(2) := CHR(13)||CHR(10);
    v_ren_orders number;
    v_ren_CNT number;
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
                    ----    p_to_B        IN VARCHAR2,
                        p_to_C        IN VARCHAR2,
                        p_to_D        IN VARCHAR2,
                        p_to_E        IN VARCHAR2,
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
----  UTL_SMTP.rcpt(l_mail_conn, p_to_B);
  UTL_SMTP.rcpt(l_mail_conn, p_to_C);
  UTL_SMTP.rcpt(l_mail_conn, p_to_D);
  UTL_SMTP.rcpt(l_mail_conn, p_to_E);
dbms_output.put_line('@3') ;
  UTL_SMTP.open_data(l_mail_conn);
  
  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_A || UTL_TCP.crlf);
----  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_B || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_C || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_D || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Bcc: ' || p_to_E || UTL_TCP.crlf);
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
  
      
     v_sms_txt := 'Pending%20DATA%20Services%20Report%20contain%20' || v_ren_CNT || '%20records.%20Please%20check%20your%20mails. ';
      
        v_mobile:='716834441';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='714856402';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
        v_mobile:='714307510';
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
        PENDING_ENTERPRICE_DATA ;
        END IF;
                        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
      
    IF v_ren_CNT >0 THEN
      qryCtx := DBMS_XMLGEN.newContext('SELECT SO_ID,DATA_CCT,SERVICE_SPEED,CUSTOMER_NAME,SERVICE_TYPE,ORDER_TYPE,SO_STATUS,SO_DATE_CREATED,ACTUAL_START_DATE,SERVICE_REQUIRED_DATE,DELAY_OF_SERVICE_REQUIRED_DATE,OVERALL_SO_AGE,INPROGRESS_TASK,TASK_STATUS,TASK_WG,PENDING_WO_DURATION,SERVICE_CATEGORY,SECTION_HANDLED_BY,ACCESS_MEDIUM,ACCMAN_NAME,SERVICE_PRIORITY,WO_TIMESTAMP,WO_ACTIVITY_NAME,WO_ACTIVITY_WG,WO_ACTIVITY_DURATION,WO_ACTIVITY_STATUS,WO_COMMENT FROM CLARITY_ADMIN.PENDING_ETHERNET_DATA');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>Pending Data Services Detail Report'
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
         || 'Sir'
         || '/'
         || 'Madam'
         || ','
         || v_cl
         || v_cl
         || '<br><br>'
         || 'Today Pending Data Services Report contain '
         || v_ren_CNT
         || ' records.'
         || '<br>'
         || 'Please find the attached Detail Report.'
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || '</table>'
         || v_cl
         || v_cl
         || '<br><br><i>Best regards'
         || v_cl
         || '<br>Business Solution Division'
         || v_cl
         || v_cl
         || '</i></p></span></table></body></html>';
         dbms_output.put_line('@5') ;
         end;
         
  
  
      dbms_output.put_line('@1') ;
      send_mail(p_to          => 'kosalak@slt.com.lk',
                p_to_A        => 'pasan@slt.com.lk',
              ----  p_to_B        => 'cdinesh@slt.com.lk',
                p_to_C        => 'nimal@slt.com.lk',
                p_to_D        => 'yasith@slt.com.lk',
                p_to_E        => 'darshanis@slt.com.lk',
                p_from        => 'oss@slt.com.lk',
                p_subject     => 'Pending Data Services Detail Report',
                p_text_msg    => l_body,
                p_attach_name => 'Pending_Data_Services.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;

    DELETE FROM CLARITY_ADMIN.PENDING_ETHERNET_DATA;

END PENDING_ENTERPRICE_DATA_MAIL;

 ---- Sasith 15-12-2013 -----
/
