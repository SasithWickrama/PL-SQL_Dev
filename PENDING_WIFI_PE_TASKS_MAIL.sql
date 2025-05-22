CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_WIFI_PE_TASKS_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_WIFI_PE_TASKS;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     ((SYSDATE), 'MM-DD-YYYY')
     FROM DUAL;
   
    CURSOR C_PE_COUNT IS
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
            SPECIFY_SITE_DETAIL_OP,
            SPECIFY_SITE_DETAIL_PROJ,
            DESIGN_SOLUTION,
            APPROVE_PE,
            SITE_AGREEMENT,
            INITIATE_SO_BHL,
            ISSUE_LOI_OP,
            ISSUE_LOI_PROJ,
            SET_UP_LAN,
            SITE_READINESS,
            WAIT_FOR_BHL,
            ACTIVATE_WIFI_APS,
            INSTALL_WIFI_APS,
            CONDUCT_PAT,
            INVOLVE_IN_PAT,
            TOTAL
            FROM
            (
            SELECT 
            CASE WHEN REGION IS NULL THEN 'Z_GRAND TOTAL' ELSE REGION END AS REGION,
            CASE WHEN PROVINCE IS NULL THEN 'Z_SUB TOTAL' ELSE PROVINCE END AS PROVINCE,
            CASE WHEN RTOM IS NULL THEN 'Z_SUB TOTAL' ELSE RTOM END AS RTOM,
            COUNT(CASE TASK_NAME WHEN 'SPECIFY SITE DETAIL.' THEN 'X' ELSE NULL END) "SPECIFY_SITE_DETAIL_OP",
            COUNT(CASE TASK_NAME WHEN 'SPECIFY SITE DETAIL' THEN 'X' ELSE NULL END) "SPECIFY_SITE_DETAIL_PROJ",
            COUNT(CASE TASK_NAME WHEN 'DESIGN SOLUTION' THEN 'X' ELSE NULL END) "DESIGN_SOLUTION",
            COUNT(CASE TASK_NAME WHEN 'APPROVE PE.' THEN 'X' ELSE NULL END) "APPROVE_PE",
            COUNT(CASE TASK_NAME WHEN 'SITE AGREEMENT' THEN 'X' ELSE NULL END) "SITE_AGREEMENT",
            COUNT(CASE TASK_NAME WHEN 'INITIATE SO BHL' THEN 'X' ELSE NULL END) "INITIATE_SO_BHL",
            COUNT(CASE TASK_NAME WHEN 'ISSUE  LOI' THEN 'X' ELSE NULL END) "ISSUE_LOI_OP",
            COUNT(CASE TASK_NAME WHEN 'ISSUE LOI' THEN 'X' ELSE NULL END) "ISSUE_LOI_PROJ",
            COUNT(CASE TASK_NAME WHEN 'SET UP LAN' THEN 'X' ELSE NULL END) "SET_UP_LAN",
            COUNT(CASE TASK_NAME WHEN 'SITE READINESS' THEN 'X' ELSE NULL END) "SITE_READINESS",
            COUNT(CASE TASK_NAME WHEN 'WAIT FOR BHL' THEN 'X' ELSE NULL END) "WAIT_FOR_BHL",
            COUNT(CASE TASK_NAME WHEN 'ACTIVATE WI-FI APS' THEN 'X' ELSE NULL END) "ACTIVATE_WIFI_APS",
            COUNT(CASE TASK_NAME WHEN 'INSTALL WI-FI APS' THEN 'X' ELSE NULL END) "INSTALL_WIFI_APS",
            COUNT(CASE TASK_NAME WHEN 'CONDUCT PAT' THEN 'X' ELSE NULL END) "CONDUCT_PAT",
            COUNT(CASE TASK_NAME WHEN 'INVOLVE IN PAT' THEN 'X' ELSE NULL END) "INVOLVE_IN_PAT", 
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_WIFI_PE_TASKS
            GROUP BY ROLLUP (REGION,PROVINCE,RTOM)
            ORDER BY REGION,PROVINCE,RTOM 
            ) ;                    
      
  l_name VARCHAR2(80) := 'Pending_WIFI_PE_Tasks.xls';
  l_blob CLOB;
  l_body           VARCHAR2(20000);  --- 14000
  v_attr_table_html varchar2(16000);  ---12000  ---- 9000
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
  UTL_SMTP.write_data(l_mail_conn, 'Bcc: ' || p_to_K || UTL_TCP.crlf);
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

  v_sms_txt := 'Dear%20All%20pending%20WIFI%20PE%20tasks%20report%20sent.%20Report%20contain%20' ||v_ren_CNT|| '%20work%20orders.%20Please%20check%20your%20mails. ';
        v_mobile:='716834441'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

        v_mobile:='715352059';
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
        PENDING_WIFI_PE_TASKS_DATA ;
        END IF; 
        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
        
        open C_DATE;
        fetch C_DATE INTO v_ren_date; 
        close C_DATE;
      
    IF v_ren_CNT >0 THEN
    
    FOR D_PE_COUNT IN C_PE_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html 
            || D_PE_COUNT.REGION 
            || '<td><b>'
            || D_PE_COUNT.PROVINCE
            || '</td><td>'
            || D_PE_COUNT.RTOM            
            || '</td><td>'            
            || D_PE_COUNT.SPECIFY_SITE_DETAIL_OP
            || '</td><td>'
            || D_PE_COUNT.SPECIFY_SITE_DETAIL_PROJ
            || '</td><td>'
            || D_PE_COUNT.DESIGN_SOLUTION
            || '</td><td>'
            || D_PE_COUNT.APPROVE_PE
            || '</td><td>'
            || D_PE_COUNT.SITE_AGREEMENT
            || '</td><td>'
            || D_PE_COUNT.INITIATE_SO_BHL
            || '</td><td>'
            || D_PE_COUNT.ISSUE_LOI_OP
            || '</td><td>'
            || D_PE_COUNT.ISSUE_LOI_PROJ
            || '</td><td>'
            || D_PE_COUNT.SET_UP_LAN
            || '</td><td>'
            || D_PE_COUNT.SITE_READINESS
            || '</td><td>'
            || D_PE_COUNT.WAIT_FOR_BHL
            || '</td><td>'
            || D_PE_COUNT.ACTIVATE_WIFI_APS
            || '</td><td>'
            || D_PE_COUNT.INSTALL_WIFI_APS
            || '</td><td>'
            || D_PE_COUNT.CONDUCT_PAT
            || '</td><td>'
            || D_PE_COUNT.INVOLVE_IN_PAT
            || '</td><td>'
            || D_PE_COUNT.TOTAL
            ||'</td></tr>';
        END LOOP;
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_WIFI_PE_TASKS');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>Pending WIFI PE Tasks'
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
         || 'Please find the Pending WIFI PE Tasks Report AS @ '
         || v_ren_date
         || ' .'
         || '<br>'
         || v_cl
         || 'Report contain'
         || v_cl
         || v_ren_CNT
         || v_cl
         || 'Work orders.'
         || v_cl
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || v_cl
         || '<tr bgcolor="#33FF00">'   ---- C0C0C0
         || '<th>'
         || 'REGION</th>'
         || '<th>'
         || 'PROVINCE</th>'
         || '<th>'
         || 'RTOM</th>'
         || '<th>'
         || 'SPECIFY_SITE_DETAIL_OP</th>'
         || '<th>'
         || 'SPECIFY_SITE_DETAIL_PROJ</th>'
         || '<th>'
         || 'DESIGN_SOLUTION</th>'
         || '<th>'
         || 'APPROVE_PE</th>'
         || '<th>'
         || 'SITE_AGREEMENT</th>'
         || '<th>'
         || 'INITIATE_SO_BHL</th>'
         || '<th>'
         || 'ISSUE_LOI_OP</th>'
         || '<th>'
         || 'ISSUE_LOI_PROJ</th>'
         || '<th>'
         || 'SET_UP_LAN</th>'
         || '<th>'
         || 'SITE_READINESS</th>'
         || '<th>'
         || 'WAIT_FOR_BHL</th>'
         || '<th>'
         || 'ACTIVATE_WIFI_APS</th>'
         || '<th>'
         || 'INSTALL_WIFI_APS</th>'
         || '<th>'
         || 'CONDUCT_PAT</th>'
         || '<th>'
         || 'INVOLVE_IN_PAT</th>'
         || '<th>'
         || 'TOTAL</th>'
         || v_cl
         || v_attr_table_html
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
      send_mail(p_to          => 'aruna@slt.com.lk',
                p_to_A        => 'prasadb@slt.com.lk',
                p_to_B        => 'ruwanreko@slt.com.lk',
                p_to_C        => 'sisirap@slt.com.lk',
                p_to_D        => 'samank@slt.com.lk',
                p_to_E        => 'imantha@slt.com.lk',
                p_to_F        => 'kirupa@slt.com.lk',
                p_to_G        => 'lakmal@slt.com.lk',
                p_to_H        => 'samantha@slt.com.lk',
                p_to_I        => 'indika@slt.com.lk',
                p_to_J        => 'asela@slt.com.lk',
                p_to_K        => 'cdinesh@slt.com.lk',       
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'Pending WIFI PE Tasks',
                p_text_msg    => l_body,
                p_attach_name => 'Pending_WIFI_PE_Tasks.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_WIFI_PE_TASKS;
    
END PENDING_WIFI_PE_TASKS_MAIL;

---- Sasith 23-07-2015 -----
/
