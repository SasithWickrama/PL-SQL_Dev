CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_FIBER_PE_TASKS_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_FIBER_PE_TASKS;
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     (SYSDATE, 'MM-DD-YYYY@HH24:MI:SS')
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
            SPECIFY_DESIGN_DETAILS,
            APPROVE_PE,
            PREPARE_DETAIL_ESTIMATION,
            ASSIGN_WORK,
            DRAW_FIBER,
            UPLOAD_FIBER_IN_OSS,
            CONFIRM_FIBER_DETAILS,
            CONDUCT_FIBER_PAT,
            UPLOAD_DRAWING,
            TOTAL
            FROM
            (
            SELECT 
            CASE WHEN REGION IS NULL THEN 'Z_GRAND TOTAL' ELSE REGION END AS REGION,
            CASE WHEN PROVINCE IS NULL THEN 'Z_SUB TOTAL' ELSE PROVINCE END AS PROVINCE,
            CASE WHEN RTOM IS NULL THEN 'Z_SUB TOTAL' ELSE RTOM END AS RTOM,
            COUNT(CASE TASK_NAME WHEN 'SPECIFY DESIGN_DETAI' THEN 'X' ELSE NULL END) "SPECIFY_DESIGN_DETAILS",
            COUNT(CASE TASK_NAME WHEN 'APPROVE PE' THEN 'X' ELSE NULL END) "APPROVE_PE",
            COUNT(CASE TASK_NAME WHEN 'PREPARE_DETAILED EST' THEN 'X' ELSE NULL END) "PREPARE_DETAIL_ESTIMATION",
            COUNT(CASE TASK_NAME WHEN 'ASSIGN_WORK' THEN 'X' ELSE NULL END) "ASSIGN_WORK",
            COUNT(CASE TASK_NAME WHEN 'DRAW FIBER' THEN 'X' ELSE NULL END) "DRAW_FIBER",
            COUNT(CASE TASK_NAME WHEN 'UPLOAD FIBER_IN_OSS' THEN 'X' ELSE NULL END) "UPLOAD_FIBER_IN_OSS",
            COUNT(CASE TASK_NAME WHEN 'CONFIRM FIBER_DETAIL' THEN 'X' ELSE NULL END) "CONFIRM_FIBER_DETAILS",
            COUNT(CASE TASK_NAME WHEN 'CONDUCT FIBER_PAT' THEN 'X' ELSE NULL END) "CONDUCT_FIBER_PAT",
            COUNT(CASE TASK_NAME WHEN 'UPLOAD DRAWING' THEN 'X' ELSE NULL END) "UPLOAD_DRAWING",
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_FIBER_PE_TASKS
            GROUP BY ROLLUP (REGION,PROVINCE,RTOM)
            ORDER BY REGION,PROVINCE,RTOM 
            ) ;                    
      
  l_name VARCHAR2(80) := 'Pending_FIBER_PE_Tasks.xls';
  l_blob CLOB;
  l_body           VARCHAR2(14000);  --- 9900
  v_attr_table_html varchar2(12000);  ---1000  ---- 9000
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
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_AE || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AF || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_AG || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_AH || UTL_TCP.crlf);
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

  v_sms_txt := 'Dear%20All%20pending%20FIBER%20PE%20tasks%20report%20sent.%20Report%20contain%20' ||v_ren_CNT|| '%20work%20orders.%20Please%20check%20your%20mails. ';
        v_mobile:='716834441'; 
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
        PENDING_FIBER_PE_TASKS_DATA ;
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
            || D_PE_COUNT.SPECIFY_DESIGN_DETAILS
            || '</td><td>'
            || D_PE_COUNT.APPROVE_PE
            || '</td><td>'
            || D_PE_COUNT.PREPARE_DETAIL_ESTIMATION
            || '</td><td>'
            || D_PE_COUNT.ASSIGN_WORK
            || '</td><td>'
            || D_PE_COUNT.DRAW_FIBER
            || '</td><td>'
            || D_PE_COUNT.UPLOAD_FIBER_IN_OSS
            || '</td><td>'
            || D_PE_COUNT.CONFIRM_FIBER_DETAILS
            || '</td><td>'
            || D_PE_COUNT.CONDUCT_FIBER_PAT
            || '</td><td>'
            || D_PE_COUNT.UPLOAD_DRAWING
            || '</td><td>'
            || D_PE_COUNT.TOTAL
            ||'</td></tr>';
        END LOOP;
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_FIBER_PE_TASKS');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>Pending FIBER PE Tasks'
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
         || 'Please find the Pending FIBER PE Tasks Report AS @ '
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
         || 'SPECIFY_DESIGN_DETAILS</th>'
         || '<th>'
         || 'APPROVE_PE</th>'
         || '<th>'
         || 'PREPARE_DETAIL_ESTIMATION</th>'
         || '<th>'
         || 'ASSIGN_WORK</th>'
         || '<th>'
         || 'DRAW_FIBER</th>'
         || '<th>'
         || 'UPLOAD_FIBER_IN_OSS</th>'
         || '<th>'
         || 'CONFIRM_FIBER_DETAILS</th>'
         || '<th>'
         || 'CONDUCT_FIBER_PAT</th>'
         || '<th>'
         || 'UPLOAD_DRAWING</th>'
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
      send_mail(p_to          => 'chinwije@slt.com.lk',
                p_to_A        => 'fernandez@slt.com.lk',
                p_to_B        => 'wijeweera@slt.com.lk',
                p_to_C        => 'kirupa@slt.com.lk',
                p_to_D        => 'iblinel@slt.com.lk',
                p_to_E        => 'imantha@slt.com.lk',
                p_to_F        => 'samank@slt.com.lk',
                p_to_G        => 'sisirap@slt.com.lk',
                p_to_H        => 'abey10@slt.com.lk',
                p_to_I        => 'nsbr@slt.com.lk',
                p_to_J        => 'nawela@slt.com.lk',
                p_to_K        => 'palisam@slt.com.lk',
                p_to_L        => 'vigna@slt.com.lk',
                p_to_M        => 'asiri@slt.com.lk',
                p_to_N        => 'nalaka@slt.com.lk',
                p_to_O        => 'mangala@slt.com.lk',
                p_to_P        => 'anuruddha@slt.com.lk',
                p_to_Q        => 'banduladw@slt.com.lk',
                p_to_R        => 'chethana@slt.com.lk',
                p_to_S        => 'dineshg@slt.com.lk',
                p_to_T        => 'iroshan@slt.com.lk',
                p_to_U        => 'karawita@slt.com.lk',
                p_to_V        => 'mangala_b@slt.com.lk',
                p_to_W        => 'mpathma@slt.com.lk',
                p_to_X        => 'navani@slt.com.lk',
                p_to_Y        => 'samantha@slt.com.lk',
                p_to_Z        => 'sanjaya@slt.com.lk',
                p_to_AA       => 'sarath@slt.com.lk',
                p_to_AB       => 'weli@slt.com.lk',
                p_to_AC       => 'badwim@slt.com.lk',
                p_to_AD       => 'ashton@slt.com.lk',
                p_to_AE       => 'pasan@slt.com.lk',
                p_to_AF       => 'madhawam@slt.com.lk',
                p_to_AG       => 'jagodage@slt.com.lk',
                p_to_AH       => 'cdinesh@slt.com.lk',
                p_to_AI       => 'b_kahawita@slt.com.lk',
                p_to_AJ       => 'surendra@slt.com.lk',
                p_to_AK       => 'manoras@slt.com.lk',
                p_to_AL       => 'damitha@slt.com.lk',
                p_to_AM       => 'rifnaz@slt.com.lk',
                p_to_AN       => 'vishvajith@slt.com.lk',
                p_to_AO       => 'kishanthan@slt.com.lk',
                p_to_AP       => 'wasantha@slt.com.lk',
                p_to_AQ       => 'chamilas@slt.com.lk',
                p_to_AR       => 'nalith@slt.com.lk',
                p_to_AS       => 'gunal@slt.com.lk',
                p_to_AT       => 'mahes@slt.com.lk',      
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'Pending FIBER PE Tasks',
                p_text_msg    => l_body,
                p_attach_name => 'Pending_FIBER_PE_Tasks.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_FIBER_PE_TASKS;
    
END PENDING_FIBER_PE_TASKS_MAIL;

---- Sasith 14-08-2015 -----
/
