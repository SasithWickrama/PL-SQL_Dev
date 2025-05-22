CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PRE_POST_CUTO_ERROR_MAIL IS

    CURSOR PRE_DETAIL IS     
     SELECT COUNT(*)
     FROM CLARITY_ADMIN.PRE_CUTOVER_ERROR_TASKS;
     
    CURSOR POST_DETAIL IS     
     SELECT COUNT(*)
     FROM CLARITY_ADMIN.POST_CUTOVER_ERROR_TASKS;
     
    pre_ren_cnt     NUMBER  ;     
    post_ren_cnt    NUMBER  ;      

    PRE_QRYCTX  DBMS_XMLGEN.CTXHANDLE;
    POST_QRYCTX DBMS_XMLGEN.CTXHANDLE;

    PRE_DEST_LOB  CLOB;
    POST_DEST_LOB CLOB;

    L_BODY VARCHAR2(9900);  

    V_CL  CONSTANT VARCHAR2(2) := CHR(13)||CHR(10);  

    P_SUBJECT VARCHAR(100) := 'Pre & Post Cutover ERROR Tasks';

    PRE_NAME    VARCHAR2(80) := 'PRE_CUTOVER_ERROR_TASKS.xls' ;
    POST_NAME   VARCHAR2(80) := 'POST_CUTOVER_ERROR_TASKS.xls';

    IN_MME_TYPE_A VARCHAR(3) := 'xls';
    IN_MME_TYPE_B VARCHAR(3) := 'xls';

    v_sms_txt   varchar2(200);
    v_mobile    number; 
    v_sms_state varchar2(4000);
    v_ren_CNT number;
    GET_IP_OF_DATABASE VARCHAR2(100) ;
    NODE_1 VARCHAR2(100)  := 'clarityn1';
    NODE_2 VARCHAR2(100)  := 'clarityn2';
    IP_FLAG VARCHAR2(5);

  PROCEDURE send_mail  (p_to                IN VARCHAR2,
                        p_to_A              IN VARCHAR2,
                        p_to_B              IN VARCHAR2,
                        p_to_C              IN VARCHAR2,
                        p_to_D              IN VARCHAR2,
                        p_to_E              IN VARCHAR2,
                        p_to_F              IN VARCHAR2,
                        p_to_G              IN VARCHAR2,
                        p_to_H              IN VARCHAR2,
                        p_to_I              IN VARCHAR2,
                        p_to_J              IN VARCHAR2,
                        p_to_K              IN VARCHAR2,
                        p_to_L              IN VARCHAR2,
                        p_to_M              IN VARCHAR2,
                        p_to_N              IN VARCHAR2,
                     ---   p_to_O              IN VARCHAR2,
                        p_to_P              IN VARCHAR2,
                        p_to_Q              IN VARCHAR2,
                        p_to_R              IN VARCHAR2,
                        p_to_S              IN VARCHAR2,
                        p_to_T              IN VARCHAR2,
                        p_to_U              IN VARCHAR2,
                        p_to_V              IN VARCHAR2,
                        p_to_W              IN VARCHAR2,
                        p_from              IN VARCHAR2,
                        p_subject           IN VARCHAR2,
                        p_text_msg          IN VARCHAR2 DEFAULT NULL,
                        p_attach_name_A     IN VARCHAR2 DEFAULT NULL,
                        p_attach_name_B     IN VARCHAR2 DEFAULT NULL,                        
                        p_attach_mime_A     IN VARCHAR2 DEFAULT NULL,
                        p_attach_mime_B     IN VARCHAR2 DEFAULT NULL,                        
                        p_attach_clob_A     IN CLOB DEFAULT NULL,
                        p_attach_clob_B     IN CLOB DEFAULT NULL,                        
                        p_smtp_host         IN VARCHAR2,
                        p_smtp_port         IN NUMBER )
AS
  l_mail_conn   UTL_SMTP.connection;
  l_boundary    VARCHAR2(50) := '----=*#abc1234321cba#*=';
  l_step        PLS_INTEGER  := 12000;

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
 --- UTL_SMTP.rcpt(l_mail_conn, p_to_O);
  UTL_SMTP.rcpt(l_mail_conn, p_to_P);
  UTL_SMTP.rcpt(l_mail_conn, p_to_Q);
  UTL_SMTP.rcpt(l_mail_conn, p_to_R);
  UTL_SMTP.rcpt(l_mail_conn, p_to_S);
  UTL_SMTP.rcpt(l_mail_conn, p_to_T);
  UTL_SMTP.rcpt(l_mail_conn, p_to_U);
  UTL_SMTP.rcpt(l_mail_conn, p_to_V);
  UTL_SMTP.rcpt(l_mail_conn, p_to_W);  
  
  DBMS_OUTPUT.PUT_LINE('@3') ;
  UTL_SMTP.open_data(l_mail_conn);
  
  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_A || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_B || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_C || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_D || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_E || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_F || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_G || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_H || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_I || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_J || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_K || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_L || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_M || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_N || UTL_TCP.crlf);
 --- UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_O || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_P || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_Q || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_R || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_S || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_T || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_U || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_V || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Cc: ' || p_to_W || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'From: ' || p_from || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Reply-To: ' || p_from || UTL_TCP.crlf);  
  UTL_SMTP.write_data(l_mail_conn, 'MIME-Version: 1.0' || UTL_TCP.crlf);  
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: multipart/mixed; boundary="' || l_boundary || '"' || UTL_TCP.crlf || UTL_TCP.crlf);  
  DBMS_OUTPUT.PUT_LINE('@5') ;  
  IF p_text_msg IS NOT NULL THEN
   UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
   UTL_SMTP.write_data(l_mail_conn, 'Content-type:text/html;charset=iso-8859-1' || UTL_TCP.crlf || UTL_TCP.crlf);
   UTL_SMTP.write_data(l_mail_conn, p_text_msg);
   UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
DBMS_OUTPUT.PUT_LINE('@6') ;

  IF p_attach_name_A IS NOT NULL THEN  
  UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_attach_mime_A || '; name="' || p_attach_name_A || '"' || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_attach_name_A || '"' || UTL_TCP.crlf || UTL_TCP.crlf);  
 DBMS_OUTPUT.PUT_LINE('@7') ;  
    FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_attach_clob_A) - 1 )/l_step) LOOP
      UTL_SMTP.write_data(l_mail_conn, DBMS_LOB.substr(p_attach_clob_A, l_step, i * l_step + 1));
    END LOOP;  
  UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
  
  IF p_attach_name_B IS NOT NULL THEN
  UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || UTL_TCP.crlf);  
  UTL_SMTP.write_data(l_mail_conn, 'Content-Type: ' || p_attach_mime_B || '; name="' || p_attach_name_B || '"' || UTL_TCP.crlf);  
  UTL_SMTP.write_data(l_mail_conn, 'Content-Disposition: attachment; filename="' || p_attach_name_B || '"' || UTL_TCP.crlf || UTL_TCP.crlf);
 DBMS_OUTPUT.PUT_LINE('@8') ;  
    FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_attach_clob_B) - 1 )/l_step) LOOP
      UTL_SMTP.write_data(l_mail_conn, DBMS_LOB.substr(p_attach_clob_B, l_step, i * l_step + 1));
    END LOOP;  
    UTL_SMTP.write_data(l_mail_conn, UTL_TCP.crlf || UTL_TCP.crlf);
  END IF;
 
   dbms_output.put_line('@9') ;
 UTL_SMTP.write_data(l_mail_conn, '--' || l_boundary || '--' || UTL_TCP.crlf); 
 UTL_SMTP.close_data(l_mail_conn);
 UTL_SMTP.quit(l_mail_conn);
 
  v_sms_txt := 'Dear%20All%20' || pre_ren_cnt || '%20Pre%20cutover%20error%20tasks%20and%20'|| post_ren_cnt ||'%20Post%20cutover%20error%20tasks%20remaining.%20Please%20check%20your%20mails. ';
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
        POST_CUTOVER_ERROR_TASKS_DATA ;
        PRE_CUTOVER_ERROR_TASKS_DATA  ;
        END IF;

        OPEN PRE_DETAIL;
        FETCH PRE_DETAIL INTO pre_ren_cnt; 
        CLOSE PRE_DETAIL;
        
        OPEN POST_DETAIL;
        FETCH POST_DETAIL INTO post_ren_cnt; 
        CLOSE POST_DETAIL; 
        
    IF pre_ren_cnt >= 0 THEN     
        PRE_QRYCTX := DBMS_XMLGEN.NEWCONTEXT('SELECT * FROM CLARITY_ADMIN.PRE_CUTOVER_ERROR_TASKS');
        PRE_DEST_LOB := DBMS_XMLGEN.GETXML(PRE_QRYCTX);
        DBMS_XMLGEN.CLOSECONTEXT(PRE_QRYCTX);
    END IF;
        
    IF post_ren_cnt >= 0 THEN
        POST_QRYCTX := DBMS_XMLGEN.NEWCONTEXT('SELECT * FROM CLARITY_ADMIN.POST_CUTOVER_ERROR_TASKS');
        POST_DEST_LOB := DBMS_XMLGEN.GETXML(POST_QRYCTX);
        DBMS_XMLGEN.CLOSECONTEXT(POST_QRYCTX);        
    END IF;
    
    L_BODY :='<html>'
         || '<head><title>Pre & Post Cutover ERROR Tasks</title></head>'
         || '<body>'
         || V_CL
         || V_CL
         || '<table width="100%" cellpadding="10" cellspacing="0">'
         || V_CL
         || V_CL
         || '<tr>'
         || V_CL
         || V_CL
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || V_CL
         || V_CL
         || '<p>Dear '
         || 'All,'
         || V_CL
         || V_CL
         || '<br><br>'
         || 'There are '
         || pre_ren_cnt
         || ' Pre cutover error tasks & '
         || post_ren_cnt
         || ' Post cutover error tasks.'
         || '<br>'
         || 'Please find the attached Detail Reports.'
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || V_CL
         || '</table>'
         || V_CL
         || V_CL
         || '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || V_CL
         || V_CL
         || '<br><br><i>Best regards'
         || V_CL
         || '<br>Dinesh Perera.'
         || V_CL
         || V_CL
         || '</i></p></span></table>'
         || '</body></html>';
         
         DBMS_OUTPUT.PUT_LINE('@5') ;
         
         DBMS_OUTPUT.PUT_LINE('@1') ;
         
      send_mail(p_to                => 'pasan@slt.com.lk',
                p_to_A              => 'indikad@slt.com.lk',
                p_to_B              => 'cdinesh@slt.com.lk',
                p_to_C              => 'ram@slt.com.lk',
                p_to_D              => 'sjayakody@slt.com.lk',
                p_to_E              => 'keerthim@slt.com.lk',
                p_to_F              => 'achini@slt.com.lk',
                p_to_G              => 'sumudup@slt.com.lk',
                p_to_H              => 'thanu@slt.com.lk',
                p_to_I              => 'nishanis@slt.com.lk',
                p_to_J              => 'kumudinis@slt.com.lk',
                p_to_K              => 'rajitham@slt.com.lk',
                p_to_L              => 'tharini@slt.com.lk',
                p_to_M              => 'kalanab@slt.com.lk',
                p_to_N              => 'krishanh@slt.com.lk',
               --- p_to_O              => 'kalanass@slt.com.lk',
                p_to_P              => 'prabodha@slt.com.lk',
                p_to_Q              => 'dhanushkal@slt.com.lk',
                p_to_R              => 'dampiya@slt.com.lk',
                p_to_S              => 'pampay@slt.com.lk',
                p_to_T              => 'nilanthaw@slt.com.lk',
                p_to_U              => 'rajithav@slt.com.lk',
                p_to_V              => 'chandi@slt.com.lk',
                p_to_W              => 'upendrika@slt.com.lk',
                p_from              => 'cdinesh@slt.com.lk',
                p_subject           => P_SUBJECT,
                p_text_msg          => L_BODY,
                p_attach_name_A     => PRE_NAME,
                p_attach_name_B     => POST_NAME,
                p_attach_mime_A     => IN_MME_TYPE_A,
                p_attach_mime_B     => IN_MME_TYPE_B,                
                p_attach_clob_A     => PRE_DEST_LOB,
                p_attach_clob_B     => POST_DEST_LOB,                
                p_smtp_host         => '172.25.2.207',
                p_smtp_port         => '25'
                );
                
                DBMS_OUTPUT.PUT_LINE('@2') ;      

DELETE FROM CLARITY_ADMIN.PRE_CUTOVER_ERROR_TASKS  WHERE SERO_ID IS NOT NULL;
DELETE FROM CLARITY_ADMIN.POST_CUTOVER_ERROR_TASKS WHERE SERO_ID IS NOT NULL;   

END PRE_POST_CUTO_ERROR_MAIL ;
---- Dinesh Perera 24-02-2014 -----
/
