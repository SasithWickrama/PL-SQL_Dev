CREATE OR REPLACE PROCEDURE CLARITY_ADMIN.PENDING_CDMA_WO_DATA_MAIL IS

    CURSOR C_DETAIL IS     
     SELECT count(*)
     FROM CLARITY_ADMIN.PENDING_CDMA_WO;
     
    CURSOR C_CDMA_WO_COUNT IS
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
            TOTAL
            FROM
            (
            SELECT 
            CASE WHEN REGION IS NULL THEN 'Z_GRAND TOTAL' ELSE REGION END AS REGION,
            CASE WHEN PROVINCE IS NULL THEN 'Z_SUB TOTAL' ELSE PROVINCE END AS PROVINCE,
            CASE WHEN RTOM IS NULL THEN 'Z_SUB TOTAL' ELSE RTOM END AS RTOM,
            COUNT(*) "TOTAL"
            FROM  CLARITY_ADMIN.PENDING_CDMA_WO
            GROUP BY ROLLUP (REGION,PROVINCE,RTOM)
            ORDER BY REGION,PROVINCE,RTOM 
            ) ;
         
  l_name VARCHAR2(80) := 'CDMA_Pending_WO_Details.xls';
  l_blob CLOB;
  l_body           VARCHAR2(9900);
  v_attr_table_html varchar2(9000);  ---  4000
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
                     /*   p_to_E        IN VARCHAR2,
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
                        p_to_BK       IN VARCHAR2,*/
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
/*  UTL_SMTP.rcpt(l_mail_conn, p_to_E);
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
  UTL_SMTP.rcpt(l_mail_conn, p_to_BK);*/
  
dbms_output.put_line('@3') ;
  UTL_SMTP.open_data(l_mail_conn);
  
  UTL_SMTP.write_data(l_mail_conn, 'Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_A || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_B || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_C || UTL_TCP.crlf);
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_D || UTL_TCP.crlf);
/*  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_E || UTL_TCP.crlf);
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
  UTL_SMTP.write_data(l_mail_conn, 'To: ' || p_to_BK || UTL_TCP.crlf);*/
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

  v_sms_txt := 'Dear%20All%20CDMA%20Pending%20WO%20detail%20report%20as%20@%20today%20contain%20' ||v_ren_CNT|| '%20records.%20Please%20check%20your%20mails. ';
        v_mobile:='0716834441'; 
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;

       /* v_mobile:='0714728503';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
        v_mobile:='0714311725';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
        
        v_mobile:='0716834441';
        select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112441156&' ||
        'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;*/
        
           
END send_mail;
  
  
BEGIN

       SELECT HOST_NAME INTO GET_IP_OF_DATABASE FROM V$INSTANCE;

        IF ((GET_IP_OF_DATABASE = NODE_1) OR (GET_IP_OF_DATABASE = NODE_2)) THEN 
        IP_FLAG := 'Y';
        ELSE 
        IP_FLAG := 'N';
        END IF ;

        IF IP_FLAG = 'Y' THEN
        CLARITY_ADMIN.PENDING_CDMA_WO_DATA;
        END IF;
        
        open C_DETAIL;
        fetch C_DETAIL INTO v_ren_CNT; 
        close C_DETAIL;
        
      
    IF v_ren_CNT >=0 THEN
    
      FOR D_CDMA_WO_COUNT IN C_CDMA_WO_COUNT 
        LOOP
            v_attr_table_html := v_attr_table_html 
            || D_CDMA_WO_COUNT.REGION 
            || '</td><td>'
            || D_CDMA_WO_COUNT.PROVINCE 
            || '</td><td>'
            || D_CDMA_WO_COUNT.RTOM
            || '</td><td>'
            || D_CDMA_WO_COUNT.TOTAL 
            ||'</td></tr>';
        END LOOP;
          
      qryCtx := DBMS_XMLGEN.newContext('SELECT * FROM CLARITY_ADMIN.PENDING_CDMA_WO');
      dest_lob := DBMS_XMLGEN.getXML(qryCtx);
      DBMS_XMLGEN.closeContext(qryCtx);
      begin
      l_body := '<html><head><title>CDMA Pending WO Details'
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
         || 'Please find the CDMA Pending Work Order Detail Report AS @ today.'
         || '<br>'
         || 'Report contain '
         || v_ren_CNT
         || ' Work Orders.'
         || '<br>'
         || '<table cellpadding="10" cellspacing="1" border="1"> <span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'
         || v_cl
         || '<tr bgcolor="#33FF00">'
         || '<th>'
         || 'REGION</th>'
         || '<th>'
         || 'PROVINCE</th>'
         || '<th>'
         || 'RTOM</th>'
         || '<th>'
         || 'TOTAL</th>'
         || v_cl
         || v_attr_table_html
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
      send_mail(p_to          => 'vijayantha@slt.com.lk',
                p_to_A        => 'ineshm@slt.com.lk',
                p_to_B        => 'cdinesh@slt.com.lk',
                p_to_C        => 'nihal@slt.com.lk',
                p_to_D        => 'srnathan@slt.com.lk',
              /*  p_to_E        => 'iroshan@slt.com.lk',
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
                p_to_AL       => 'udithag@slt.com.lk ',
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
                p_to_BK       => 'lakshij@slt.com.lk',*/
                p_from        => 'cdinesh@slt.com.lk',
                p_subject     => 'CDMA Pending WO Details',
                p_text_msg    => l_body,
                p_attach_name => 'CDMA_Pending_WO_Details.xls',
                p_attach_mime => 'xls',
                p_attach_clob => dest_lob,
                p_smtp_host   => '172.25.2.205');
                dbms_output.put_line('@2') ;
            
    END IF;
    
 DELETE FROM CLARITY_ADMIN.PENDING_CDMA_WO;
    
END PENDING_CDMA_WO_DATA_MAIL;

---- Sasith 16-11-2015 -----
/
