CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_OSS_PE_TASKS_DATA_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_OSS_PE_TASKS;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     (SYSDATE, 'MM-DD-YYYY HH24:MI:SS')
     FROM DUAL;
    
    CURSOR C_WO_COUNT IS
        SELECT DECODE(WO_TASKNAME,NULL,'TOTAL',WO_TASKNAME) WO_TASKNAME,TOTAL
                    FROM (
                    SELECT WO_TASKNAME,
                        COUNT(CASE WORKGROUP WHEN 'WO_TASKNAME' THEN 'X' ELSE NULL END) "WO_COUNT",
                        COUNT(*) "TOTAL"
                    FROM  CLARITY_ADMIN.PENDING_OSS_PE_TASKS
                    GROUP BY ROLLUP (WO_TASKNAME)
                    );
         
  l_name VARCHAR2(80) := 'PE_Pending_OSS_Tasks.xls';
  l_blob CLOB;
  l_body           VARCHAR2(9900);
  v_attr_table_html varchar2(1000);
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
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_M || UTL_TCP.crlf);
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

  v_sms_txt := 'Dear%20All%20PE%20pending%20OSS%20tasks%20report%20sent.%20Report%20contain%20' ||v_ren_CNT|| '%20work%20orders.%20Please%20check%20your%20mails. ';
        v_mobile:='714307510'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='716834441';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
         v_mobile:='715364902';
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
        PENDING_OSS_PE_TASKS_DATA ;
        END IF;
        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
        
        open C_DATE;
        fetch C_DATE INTO v_ren_date; 
        close C_DATE;
      
    IF v_ren_CNT >0 THEN
    
    FOR D_PE_COUNT IN C_WO_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html 
            || '<tr bgcolor="#CCFFFF"><td><b>' 
            || D_PE_COUNT.WO_TASKNAME 
            || '</td><td>'
            || D_PE_COUNT.TOTAL
            || '</td></tr>';
        END LOOP;
        
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_OSS_PE_TASKS');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>PE Pending OSS Tasks'
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
         || 'Please find the PE Pending OSS Tasks Report AS @ '
         || v_ren_date
         || '.'
         || v_cl
         || '<br>'
         || 'Report contain'
         || v_cl
         || v_ren_CNT
         || v_cl
         || 'Work Orders.'
         || '<br>'
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || '<tr bgcolor="#33FF00">'  ----C0C0C0
         || '<th>'
         || 'WO_TASKNAME</th>'
         || '<th>'
         || 'WO_COUNT</th>'
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
         || '<br>Dinesh Perera.'
         || v_cl
         || v_cl
         || '</i></p></span></table></body></html>';
         dbms_output.put_line('@5') ;
         end;
         
  
  
      dbms_output.put_line('@1') ;
      send_mail(p_to          => 'pasan@slt.com.lk',
                p_to_A        => 'indikad@slt.com.lk',
                p_to_B        => 'cdinesh@slt.com.lk',
                p_to_C        => 'ram@slt.com.lk',
                p_to_D        => 'keerthim@slt.com.lk',
                p_to_E        => 'upendrika@slt.com.lk',
                p_to_F        => 'dampiya@slt.com.lk',
                p_to_G        => 'nilanthaw@slt.com.lk',
                p_to_H        => 'pampay@slt.com.lk',
                p_to_I        => 'rajithav@slt.com.lk',
                p_to_J        => 'chandi@slt.com.lk',
                p_to_K        => 'prabodha@slt.com.lk',
                p_to_L        => 'dhanushkal@slt.com.lk',
                p_to_M        => 'kumudinis@slt.com.lk',
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'PE Pending OSS Tasks',
                p_text_msg    => l_body,
                p_attach_name => 'PE_Pending_OSS_Tasks.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_OSS_PE_TASKS;
    
END PENDING_OSS_PE_TASKS_DATA_MAIL;

---- Sasith 21-02-2014 -----
/
