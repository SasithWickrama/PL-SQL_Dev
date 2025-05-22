CREATE OR REPLACE PACKAGE BODY CLARITY_ADMIN.SLT_EVENTS IS
/******************************************************************************
   NAME:       SLT_EVENTS
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        30/07/2015      011192       1. Created this package body.
******************************************************************************/

---- Dinesh Perera 30-07-2015  ----
PROCEDURE FAULT_CREATE_SMS (p_faultnumber IN NUMBER)
   IS
      l_prom_lea  problems.PROM_REGN_CODE%TYPE;     
      l_satt_val   services_attributes.satt_defaultvalue%TYPE;
      l_seoa_val   service_order_attributes.seoa_defaultvalue%TYPE;
      v_sms_txt     varchar2(1000);
      v_sms_txt1    varchar2(1000);
      v_sms_txt2    varchar2(1000);
      v_mobile      number;
      v_circuit     varchar2(100);
      v_service     varchar2(100);
      v_sms_state   varchar2(4000);
      v_from        varchar2(100)  :='94112445966';

      
  BEGIN
  
 
      SELECT '94'||SUBSTR(PROM_REPORTEDCONTACT,-9)
      INTO   v_mobile
      FROM PROBLEMS
      WHERE PROM_NUMBER = p_faultnumber;
      
      SELECT CIRT_DISPLAYNAME, CIRT_SERT_ABBREVIATION
      INTO   v_circuit, v_service
      FROM PROBLEM_LINKS, CIRCUITS
      WHERE PROL_PROM_NUMBER = p_faultnumber
      AND PROL_FOREIGNTYPE = 'CIRCUITS'
      AND PROL_FOREIGNID = CIRT_NAME;
          
    v_sms_txt  := 'Your%20complaint%20on%20'||v_circuit||'%20has%20been%20recorded.%20Reference%20No.%20'||p_faultnumber||'.%20Thank%20you.%20SLT%20Contact%20Center';
    v_sms_txt1 := 'Your%20complaint%20on%20'||v_circuit||'%20has%20been%20recorded.%20Reference%20No.%20'||p_faultnumber||'.%20Thank%20you.%20SLT%20Enterprise%20Help%20Desk';
       ----------------ADSL/IPTV------------------
      IF v_mobile LIKE '947%' AND v_service = 'ADSL' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      ---------------CDMA---------------
      ELSIF v_mobile LIKE '947%' AND v_service = 'CDMA' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      ---------------FTTH---------------
      ELSIF v_mobile LIKE '947%' AND v_service LIKE '%FTTH' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      ---------------LTE---------------------
      ELSIF v_mobile LIKE '947%' AND (v_service = 'V-VOICE' OR v_service = 'BB-INTERNET') THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      --------------PSTN--------------------
      ELSIF v_mobile LIKE '947%' AND v_service = 'PSTN' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      
      --------------DATA--------------------
      ELSIF v_mobile LIKE '947%' AND v_service LIKE 'D-%' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt1||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt1)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','SENT');
      
      ELSIF v_mobile IS NULL THEN
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','NO_NUMBER');
      
      
      ELSIF v_mobile NOT LIKE '947%' THEN
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','NO_MOBILE');
      
      
      ELSIF  v_service != 'ADSL' AND v_service != 'CDMA' AND v_service != 'V-VOICE' AND v_service != 'BB-INTERNET' AND v_service != 'PSTN' AND v_service NOT LIKE '%FTTH' AND v_service NOT LIKE 'D-%' THEN
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CREATE','INVAL_SERV');
  
      END IF;
  

        
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.put_line ('Err: Proc ' || $$plsql_unit || ' Line:' || $$plsql_line);

END;


---- Dinesh Perera 12-08-2015  ----
PROCEDURE FAULT_STATUS_CHANGE_SMS (p_faultNumber IN NUMBER, p_statusCode IN VARCHAR, p_prouId IN VARCHAR)
   IS
      l_prom_lea  problems.PROM_REGN_CODE%TYPE;     
      l_satt_val   services_attributes.satt_defaultvalue%TYPE;
      l_seoa_val   service_order_attributes.seoa_defaultvalue%TYPE;
      v_sms_txt     varchar2(1000);
      v_sms_txt1    varchar2(1000);
      v_sms_txt2    varchar2(1000);
      v_mobile      number;
      v_circuit     varchar2(100);
      v_service     varchar2(100);
      v_sms_state   varchar2(4000);
      v_from        varchar2(100)  :='94112445966';

      
  BEGIN
  
  IF p_faultNumber IS NOT NULL  THEN
 
      SELECT '94'||SUBSTR(PROM_REPORTEDCONTACT,-9)
      INTO   v_mobile
      FROM PROBLEMS
      WHERE PROM_NUMBER = p_faultnumber;
      
      SELECT CIRT_DISPLAYNAME, CIRT_SERT_ABBREVIATION
      INTO   v_circuit, v_service
      FROM PROBLEM_LINKS, CIRCUITS
      WHERE PROL_PROM_NUMBER = p_faultnumber
      AND PROL_FOREIGNTYPE = 'CIRCUITS'
      AND PROL_FOREIGNID = CIRT_NAME;
      
  v_sms_txt  := 'Your%20complaint%20on%20'||v_circuit||'%20(Reference%20No.%20'||p_faultnumber||')%20has%20been%20resolved.%20Thank%20you.%20SLT%20Contact%20Center%20(1212)';
  v_sms_txt1 := 'Your%20complaint%20on%20'||v_circuit||'%20(Reference%20No.%20'||p_faultnumber||')%20has%20been%20resolved.%20Thank%20you.%20SLT%20Enterprise%20Help%20Desk';
      ----------------ADSL/IPTV------------------
      IF v_mobile LIKE '947%' AND v_service = 'ADSL' AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '|| v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');   
      
      
      ----------------CDMA------------------
      ELSIF v_mobile LIKE '947%' AND v_service = 'CDMA' AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '|| v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');
      
      
      ---------------FTTH-----------------
      ELSIF v_mobile LIKE '947%' AND v_service LIKE '%FTTH' AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '|| v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual;
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');
      
      
      ----------------LTE------------------
      ELSIF v_mobile LIKE '947%' AND (v_service = 'V-VOICE' OR v_service = 'BB-INTERNET') AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');
      
      
      --------------PSTN--------------------
      ELSIF v_mobile LIKE '947%' AND v_service = 'PSTN' AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');
      
      
      --------------DATA--------------------
      ELSIF v_mobile LIKE '947%' AND v_service LIKE 'D-%' AND p_statusCode = '1003' THEN
      
      DBMS_OUTPUT.PUT_LINE(v_sms_txt1||' '||v_mobile);
      select utl_http.request('http://10.68.2.9:8081/sendsms?username=http1&' || 'password=http&' || 'from=' || v_from || '&' ||
      'to=' || v_mobile || '&' || 'msg=' || v_sms_txt1)into v_sms_state from dual; 
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','SENT');
      
       
      ELSIF v_mobile IS NULL AND p_statusCode = '1003' THEN
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','NO_NUMBER');
      
      
      ELSIF v_mobile NOT LIKE '947%' AND p_statusCode = '1003' THEN
      
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','NO_MOBILE');
      
      
      ELSIF v_service != 'ADSL' AND v_service != 'CDMA' AND v_service != 'V-VOICE' AND v_service != 'BB-INTERNET' AND v_service != 'PSTN' AND v_service NOT LIKE '%FTTH' AND v_service NOT LIKE 'D-%' AND p_statusCode = '1003' THEN
  
      INSERT INTO CLARITY_ADMIN.FAULT_SMS_LOG VALUES 
      (p_faultnumber,v_circuit,v_mobile,SYSDATE,v_service,'CLEARED','INV_SERV');
  
      END IF;
      
      
  END IF; 
      
    EXCEPTION
    WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.put_line ('Err: Proc ' || $$plsql_unit || ' Line:' || $$plsql_line);
    
END;

END SLT_EVENTS;
/
