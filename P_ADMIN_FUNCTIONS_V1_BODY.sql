CREATE OR REPLACE PACKAGE BODY CLARITY_ADMIN.P_ADMIN_FUNCTIONS_V1 AS
/******************************************************************************
   NAME:       P_ADMIN_FUNCTIONS_V1
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        14/07/2015      011192       1. Created this package body.
******************************************************************************/


-- 19-06-2013 Samankula Owitipan
-- process function
PROCEDURE IPTV_TITANIUM_PKG_OPMC_EMAIL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


SENDER          constant VARCHAR2(80) := 'oss@slt.com.lk';MAILHOST        constant VARCHAR2(80) := '172.25.2.205';
mail_conn utl_smtp.connection;V_CL            constant VARCHAR2(2) := CHR(13)||CHR(10);
l_rcpt           VARCHAR2(80) := 'kalanass@slt.com.lk';l_cc_recipient   VARCHAR2(80) := 'rukshanj@slt.com.lk';
l_bcc_recipient  VARCHAR2(80) := 'kalanass@slt.com.lk';l_subject        VARCHAR2(100) := 'PeoTV Titanium Package has been requested for PSTN ID: ';
l_mesg           VARCHAR2(9900);l_body           VARCHAR2(9000);v_servic_type varchar2(100);
v_order_type varchar2(100);v_cr_no varchar2(100);v_ac_no varchar2(100);v_cus_name varchar2(300);v_sms_state varchar2(4000);
v_cct_name varchar2(100);v_so_id varchar2(100);v_attr_table_html varchar2(1000);v_error_1 varchar2(4000);v_adsl_id varchar2(100);
v_error_2 varchar2(4000);v_rtom varchar2(10);v_lea varchar2(10);v_pstn_id varchar2(100);v_mobile number; v_sms_txt varchar2(200);
CURSOR c_so_customer_data is
SELECT ar.AREA_AREA_CODE,ar.AREA_CODE,so.sero_id,so.SERO_SERT_ABBREVIATION,so.SERO_ORDT_TYPE,so.SERO_CUSR_ABBREVIATION,so.SERO_ACCT_NUMBER,cu.CUSR_NAME
FROM SERVICE_ORDERS SO,customer cu,areas ar
WHERE so.SERO_CUSR_ABBREVIATION = cu.CUSR_ABBREVIATION
and so.SERO_AREA_CODE = ar.AREA_CODE
AND so.SERO_ID = p_sero_id;
CURSOR c_so_attribute_data is 
SELECT SOA.SEOA_NAME,SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA 
WHERE SOA.SEOA_SERO_ID = p_sero_id AND SOA.SEOA_NAME IN
( 'SA_PSTN_NUMBER','IPTV_PACKAGE','SA_SO_INITIATOR','ADSL_CIRCUIT_ID','SERVICE_SPEED','SA_PACKAGE_NAME');
CURSOR c_so_pstn_number is 
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA 
WHERE SOA.SEOA_SERO_ID = p_sero_id AND SOA.SEOA_NAME IN
( 'SA_PSTN_NUMBER');
CURSOR c_so_adsl_number is 
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA 
WHERE SOA.SEOA_SERO_ID = p_sero_id AND SOA.SEOA_NAME IN
( 'ADSL_CIRCUIT_ID');
BEGIN
open c_so_customer_data; fetch c_so_customer_data into v_rtom,v_lea,v_so_id,v_servic_type,v_order_type,v_cr_no,v_ac_no,v_cus_name;
close c_so_customer_data;
open c_so_pstn_number; fetch c_so_pstn_number into v_pstn_id;
close c_so_pstn_number;
open c_so_adsl_number; fetch c_so_adsl_number into v_adsl_id;
close c_so_adsl_number;
IF (v_rtom = 'R-ND' OR v_rtom = 'R-RM') THEN
l_rcpt:= 'karawita@slt.com.lk';
ELSIF (v_rtom = 'R-WT' OR v_rtom = 'R-MD') THEN
l_rcpt:= 'sarath@slt.com.lk';
ELSIF (v_rtom = 'R-HK' OR v_rtom = 'R-CEN' OR v_rtom = 'R-KX') THEN
l_rcpt:= 'kasun@slt.com.lk';
ELSIF (v_rtom = 'R-KY' OR v_rtom = 'R-GP' OR v_rtom = 'R-MT') THEN
l_rcpt:= 'anuruddha@slt.com.lk';
ELSIF (v_rtom = 'R-KG' OR v_rtom = 'R-CW' OR v_rtom = 'R-AD' OR v_rtom = 'R-PR') THEN
l_rcpt:= 'banduladw@slt.com.lk';
ELSIF (v_rtom = 'R-GQ' OR v_rtom = 'R-NG') THEN
l_rcpt:= 'rasitha@slt.com.lk';
ELSIF (v_rtom = 'R-GL' OR v_rtom = 'R-MH' OR v_rtom = 'R-HB') THEN
l_rcpt:= 'dineshg@slt.com.lk';
ELSIF (v_rtom = 'R-BD' OR v_rtom = 'R-BW' OR v_rtom = 'R-HT' OR v_rtom = 'R-NW') THEN
l_rcpt:= 'samantha@slt.com.lk';
ELSIF (v_rtom = 'R-KE' OR v_rtom = 'R-RN' OR v_rtom = 'R-AW') THEN
l_rcpt:= 'sanjaya@slt.com.lk';
ELSIF (v_rtom = 'R-KT' OR v_rtom = 'R-PH') THEN
l_rcpt:= 'weli@slt.com.lk';
ELSIF (v_rtom = 'R-KL' OR v_rtom = 'R-BC' OR v_rtom = 'R-TC' OR v_rtom = 'R-AP') THEN
l_rcpt:= 'mpathma@slt.com.lk';
ELSIF (v_rtom = 'R-JA' OR v_rtom = 'R-MB' OR v_rtom = 'R-VA') THEN
l_rcpt:= 'kirupa@slt.com.lk';
END IF; FOR d_so_attribute_data IN c_so_attribute_data LOOP
v_attr_table_html := v_attr_table_html || '<tr><td>' || d_so_attribute_data.seoa_name || '</td><td>'|| d_so_attribute_data.seoa_defaultvalue ||'</td></tr>';
END LOOP;mail_conn := utl_smtp.open_connection(mailhost, 25) ;utl_smtp.helo(mail_conn, MAILHOST) ;
--dbms_output.put_line('Sending Email to : ' || d_contractor.email ) ;
l_body :=  '<html><head><title>PeoTV Titanium Package has been requested for PSTN ID:' || v_pstn_id || '</title></head><body>'||v_cl||v_cl||
 '<table width="100%" cellpadding="10" cellspacing="0">'||v_cl||v_cl||
 '<tr>'||v_cl||v_cl||
 '<span style=''color:Blue;font-family:Calibri,Arial,Helvetica,sans-serif''>'||v_cl||v_cl||
 '<p>Dear '|| 'Sir' ||'/'|| 'Madam' ||','||v_cl||v_cl||
 '<br><br><b>' || v_so_id || '</b>' || ' PeoTV Titanium Package has been requested for PSTN ID: ' || v_pstn_id || '. Please make arrangements to complete the installation within 24 hours.' || v_cl||v_cl ||
 '<span style=''color:black''>'||v_cl||v_cl||
 '<ul><u>Customer details</u>'||v_cl||v_cl||
 '<li>Customer Name: ' || v_cus_name ||v_cl||v_cl||
 '<li>CR No: ' || v_cr_no ||v_cl||v_cl||
 '<li>Account No: ' || v_ac_no ||v_cl||v_cl||
 '<li>RTOM: ' || v_rtom ||v_cl||v_cl||
 '<li>LEA: ' || v_lea ||v_cl||v_cl||
 '</ul></span><span style=''font-weight:bold; color:Red; font-family:Cambria,Calibri,Arial,Helvetica,sans-serif''>'||v_cl||v_cl||
 '<p>Service Order Details</span>'||v_cl||v_cl||
 ' <table cellpadding="10" cellspacing="1" border="1">' ||v_cl||v_cl||
 '<tr><td>SERVICE TYPE</td> <td>' || v_servic_type ||'</td></tr>'||v_cl||v_cl||
 '<tr><td>ORDER TYPE</td><td>'|| v_order_type ||'</td></tr>' ||v_cl||v_cl||
 '</td></tr>' || v_attr_table_html ||v_cl||v_cl||
 '</table>'||v_cl||v_cl||
 '<br><br><i>Best wishes'||v_cl||v_cl||
 '<br><br>Operation Support System Division'||v_cl||v_cl||
 '</i></p></span></table></body></html>' ;l_mesg := 'Date: '||TO_CHAR(sysdate,'dd Mon yy hh24:mi:ss')||V_CL||
'From: oss@slt.com.lk < '||SENDER||'>'||V_CL||
'Subject: '||l_subject || v_pstn_id ||V_CL||
'To: '|| l_rcpt ||v_cl||
'Cc: ' || l_cc_recipient || v_cl ||
--              'Bcc: ' || l_bcc_recipient || v_cl ||
'MIME-Version: 1.0'||V_CL||
'Content-type:text/html;charset=iso-8859-1'||V_CL||
''||v_cl||l_body ;utl_smtp.mail(mail_conn, SENDER) ;utl_smtp.rcpt(mail_conn, l_rcpt) ;utl_smtp.rcpt(mail_conn, l_cc_recipient);
--          utl_smtp.rcpt(mail_conn, l_bcc_recipient);
utl_smtp.data(mail_conn, l_mesg) ;utl_smtp.quit(mail_conn) ;
v_mobile:='94718840329';
v_sms_txt := 'PeoTV%20Titanium%20Pkg%20request%20for%20PSTN:%20' || v_pstn_id || '%20ADSL:%20' || v_adsl_id || '%20SO:%20' || v_so_id ||
'%20Install%20within%20One%20Day.';
select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=94112494949&' ||
'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
EXCEPTION
WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
p_ret_msg := 'SMTP Transient or permanent error'|| TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');        
WHEN OTHERS THEN
p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');            
END IPTV_TITANIUM_PKG_OPMC_EMAIL;
-- 19-06-2013 Samankula Owitipan

END P_ADMIN_FUNCTIONS_V1;
/
