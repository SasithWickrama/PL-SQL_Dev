CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.NOTIFY_TASK_INPROGRESS_DELAY IS
    
    CURSOR C_COUNT IS 
     SELECT COUNT(*)
     FROM AQ.AQ$SO_QTAB
     WHERE MSG_STATE = 'READY';
     
    CURSOR C_DATE IS     
     SELECT TO_CHAR
     (SYSDATE, 'MM-DD-YYYY@HH24:MI:SS')
     FROM DUAL;
     
     /*addtion by sudheera */
 /*   CURSOR GET_BLOCKING_USER_G IS
    SELECT S1.USERNAME || '@' || S1.MACHINE
    || ' ( SID=' || S1.SID || ', INST_ID='||S1.INST_ID||' )  is blocking '
    || S2.USERNAME || '@' || S2.MACHINE || ' ( SID=' || S2.SID || ', INST_ID='||S2.INST_ID||' ) ' AS BLOCKING_STATUS
    FROM GV$LOCK L1, GV$SESSION S1, GV$LOCK L2, GV$SESSION S2
    WHERE S1.SID=L1.SID AND S2.SID=L2.SID
    AND L1.BLOCK=1 AND L2.REQUEST > 0
    AND L1.ID1 = L2.ID1
    AND L1.ID2 = L2.ID2;*/
    
    CURSOR GET_BLOCKING_USER_V IS
    SELECT S1.USERNAME || '@' || S1.MACHINE
    || ' ( SID=' || S1.SID || ' )  is blocking '
    || S2.USERNAME || '@' || S2.MACHINE || ' ( SID=' || S2.SID || ' ) ' AS BLOCKING_STATUS
    FROM V$LOCK L1, V$SESSION S1, V$LOCK L2, V$SESSION S2
    WHERE S1.SID=L1.SID AND S2.SID=L2.SID
    AND L1.BLOCK=1 AND L2.REQUEST > 0
    AND L1.ID1 = L2.ID1
    AND L1.ID2 = L2.ID2;

    CURSOR GET_QTAB_COUNT IS
    SELECT COUNT(*) FROM AQ.SO_QTAB ;
    
    CURSOR GET_LOCK_DETILS IS
    SELECT 
    B.INST_ID,USERNAME,SID,LOCKWAIT,LOGON_TIME,EXECUTIONS,USERS_EXECUTING,
    USERS_OPENING,PARSE_CALLS,DISK_READS,BUFFER_GETS,ROWS_PROCESSED,CPU_TIME,MACHINE,A.MODULE,SQL_TEXT
    FROM 
    GV$SQLAREA A, GV$SESSION B
    WHERE 
        SQL_ADDRESS = ADDRESS
    AND SQL_HASH_VALUE = HASH_VALUE AND USERS_OPENING > 0
    AND STATUS = 'ACTIVE'
    AND USERNAME IS NOT NULL
    AND LOCKWAIT IS NOT NULL
    ORDER BY CPU_TIME DESC;
    
  --  TEMP_USER_INFO VARCHAR2(4000) := NULL;
    TEMP_USER_INFO_V VARCHAR2(4000) := NULL;
    N_QTAB_COUNT NUMBER := 0;    
    
     /* end of addition*/
                      
      
  l_body           VARCHAR2(9900);  --- 9900
  v_attr_table_html varchar2(1000);  ---1000  ---- 9000
  dest_lob CLOB;
  qryCtx DBMS_XMLGEN.ctxHandle;
   
    l_str   varchar2(3000);
    l_str1  varchar2(3000);
    l_temp  varchar2(3000);
    l_test  varchar2(80);
    V_CL            constant VARCHAR2(2) := CHR(13)||CHR(10);
    v_ren_orders number;
    v_ren_CNT number;
    v_ren_date varchar2(120);
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

  v_sms_txt := 'Clarity%20Task%20INPROGRESS%20is%20delay.%20Queue%20count%20is%20' || v_ren_CNT || '%20as%20@%20' || v_ren_date || '%20Hrs.%20Please%20check.';

    v_mobile:='94716834441';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

    v_mobile:='94714307510';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94715364902';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94714220285';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94711300064';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94714515357';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94712617797';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94716901805';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94777555001';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94772276390';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94774190002';
    select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
    'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
    
    v_mobile:='94716837706';
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
  
        
        open C_COUNT;
        fetch C_COUNT INTO v_ren_CNT; 
        close C_COUNT;
        
        open C_DATE;
        fetch C_DATE INTO v_ren_date; 
        close C_DATE;
        
      
    IF v_ren_CNT >200 THEN 
       
      begin
      l_body := '<html><head><title>Clarity Task Inprogress Delay'
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
         || ' Clarity tasks INPROGRESS is Delaying.'
         || '<br>'
         || ' Queue count is ' 
         || v_ren_CNT
         || '.'
         || '<br>'
         || 'Please make arrangements to correct the issue.'
         || v_cl
         || v_cl
         || v_cl
         || v_cl
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || v_cl
         || '<br><br><i>Best regards'
         || v_cl
         || v_cl
         || '<br>Business Solution Division'
         || v_cl
         || v_cl
         || '</i></p></span></body></html>';
         dbms_output.put_line('@5') ;
         end;
         
  
  
      dbms_output.put_line('@1') ;
      send_mail(p_to          => 'pasan@slt.com.lk',
                p_to_A        => 'ram@slt.com.lk', 
                p_to_B        => 'cdinesh@slt.com.lk',  
                p_to_C        => 'indikad@slt.com.lk',
                p_to_D        => 'sjayakody@slt.com.lk',
                p_to_E        => 'sagara@slt.com.lk', 
                p_to_F        => 'migaraa@slt.com.lk',
                p_to_G        => 'mithila@slt.com.lk', 
                p_to_H        => 'charles@slt.com.lk',       
                p_from        => 'oss@slt.com.lk',
                p_subject     => 'Clarity Task Inprogress Delay',
                p_text_msg    => l_body,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
    /*addtion by sudheera */
   /* 
    FOR GET_BLOCKING_USER_R IN GET_BLOCKING_USER_G LOOP
    
    TEMP_USER_INFO := TEMP_USER_INFO||GET_BLOCKING_USER_R.BLOCKING_STATUS;
    
    TEMP_USER_INFO := TEMP_USER_INFO||' , ';

    END LOOP;
    */
    FOR GET_BLOCKING_USER_RR IN GET_BLOCKING_USER_V LOOP
    
    TEMP_USER_INFO_V := TEMP_USER_INFO_V||GET_BLOCKING_USER_RR.BLOCKING_STATUS;
    
    TEMP_USER_INFO_V := TEMP_USER_INFO_V||' , ';

    END LOOP;
    
    OPEN  GET_QTAB_COUNT;
    FETCH GET_QTAB_COUNT INTO N_QTAB_COUNT;
    CLOSE GET_QTAB_COUNT;
    
    INSERT INTO CLARITY_ADMIN.BLOCKING_LOCK_DATA_TEMP
    (QTAB_COUNT,BLOCKING_LOCK_INFO,EXECUTION_TIME)
    VALUES
    (N_QTAB_COUNT,TEMP_USER_INFO_V,SYSDATE);
    
    FOR GET_LOCK_DETILS_R IN GET_LOCK_DETILS LOOP
    
    INSERT INTO CLARITY_ADMIN.BLOCKING_LOCK_DETAIL_TEMP 
    VALUES (
    GET_LOCK_DETILS_R.INST_ID,
    GET_LOCK_DETILS_R.USERNAME,
    GET_LOCK_DETILS_R.SID,
    GET_LOCK_DETILS_R.LOCKWAIT,
    GET_LOCK_DETILS_R.LOGON_TIME,
    GET_LOCK_DETILS_R.EXECUTIONS,
    GET_LOCK_DETILS_R.USERS_EXECUTING,
    GET_LOCK_DETILS_R.USERS_OPENING,
    GET_LOCK_DETILS_R.PARSE_CALLS,
    GET_LOCK_DETILS_R.DISK_READS,
    GET_LOCK_DETILS_R.BUFFER_GETS,
    GET_LOCK_DETILS_R.ROWS_PROCESSED,
    GET_LOCK_DETILS_R.CPU_TIME,
    GET_LOCK_DETILS_R.MACHINE,
    GET_LOCK_DETILS_R.MODULE,
    GET_LOCK_DETILS_R.SQL_TEXT,
    SYSDATE);
    
    END LOOP;
    
     /* end of addition*/
    
  END IF; 
    
END NOTIFY_TASK_INPROGRESS_DELAY;

---- Dinesh Perera 10-08-2015 -----
/
