CREATE OR REPLACE PACKAGE BODY
/*-------------------------------------------------------------------------------
--  Package:
--  Author: chaerry @ Synchronoss Techonology Inc
--  Date: May 1, 2015
--  Versioning:
--        1.0     March 8, 2015    ch        - initial development
--        2.0  June 3, 2015   ch      - modify procedure FaultType_Handler to support
--                                    Network Fault
---------------------------------------------------------------------------------*/
                                                                                                                                              CLARITY.slt_event_handler
IS
   PROCEDURE faulttype_handler (p_faultnumber IN NUMBER, p_linkentityid IN VARCHAR, p_linkentitytype IN VARCHAR)
   IS
      l_count      NUMBER                    := -1;
      l_prol       problem_links%ROWTYPE;
      l_serv_id    services.serv_id%TYPE;
      l_prom_type  problems.prom_type%TYPE;      
      l_satt_val   services_attributes.satt_defaultvalue%TYPE;
      l_seoa_val   service_order_attributes.seoa_defaultvalue%TYPE;
      l_prom_add   VARCHAR2(1000);
      v_circuit    VARCHAR2(100);
      v_service    VARCHAR2(100);
      v_swport     VARCHAR2(100);
      v_dploop     VARCHAR2(100);
      l_cus_name   VARCHAR2(1000);
      l_ser_pkg    VARCHAR2(100);
      TEMP_DATA    VARCHAR2(200) := NULL;
      
      CURSOR GET_SER_ATTRI_VALUE ( IN_SERV_ID VARCHAR2, IN_ATTRI_VAL VARCHAR2 ) IS
      SELECT SATT_DEFAULTVALUE
      FROM SERVICES_ATTRIBUTES 
      WHERE SATT_SERV_ID = IN_SERV_ID
      AND SATT_ATTRIBUTE_NAME = IN_ATTRI_VAL;
      
      CURSOR GET_SO_OR_ATT_VALUE (IN_SERV_IDD VARCHAR2, IN_ATTRIB_NME VARCHAR2 ) IS
      SELECT SEOA_DEFAULTVALUE
      FROM SERVICE_ORDER_ATTRIBUTES
      WHERE SEOA_SERO_ID IN
        (SELECT SERO_ID 
        FROM SERVICE_ORDERS 
        WHERE SERO_SERV_ID = IN_SERV_IDD
        AND SERO_STAS_ABBREVIATION NOT IN ('CLOSED','CANCELLED'))
      AND SEOA_NAME = IN_ATTRIB_NME;
      
      CURSOR CHILD_CCT_LOOP ( IN_PROBLEM VARCHAR2 ) IS
        SELECT FRAU_NAME||' / '||FRAA_POSITION
        FROM PROBLEMS, PROBLEM_LINKS,CIRCUITS, PORT_LINKS, PORT_LINK_PORTS, FRAME_APPEARANCES, FRAME_UNITS, FRAME_CONTAINERS
        WHERE PROM_NUMBER = IN_PROBLEM
        AND PROL_PROM_NUMBER = PROM_NUMBER
        AND PROL_FOREIGNTYPE = 'CIRCUITS'
        AND PROL_FOREIGNID = CIRT_NAME
        AND CIRT_STATUS IN ('INSERVICE','PROPOSED','COMMISSIONED')
        AND PORL_CIRT_NAME = CIRT_NAME
        AND PORL_ID = POLP_PORL_ID
        AND POLP_COMMONPORT = 'F'
        AND POLP_FRAA_ID IS NOT NULL
        AND FRAA_ID = POLP_FRAA_ID
        AND FRAA_FRAU_ID = FRAU_ID
        AND FRAU_FRAC_ID = FRAC_ID
        AND FRAC_FRAN_NAME = 'DP';

      CURSOR PARENT_CCT_LOOP ( IN_PROBLEM VARCHAR2 ) IS
        SELECT FRAU_NAME||' / '||FRAA_POSITION
        FROM PORT_LINKS, PORT_LINK_PORTS, FRAME_APPEARANCES, FRAME_UNITS, FRAME_CONTAINERS
        WHERE PORL_ID = POLP_PORL_ID
        AND POLP_COMMONPORT = 'F'
        AND POLP_FRAA_ID IS NOT NULL
        AND FRAA_ID = POLP_FRAA_ID
        AND FRAA_FRAU_ID = FRAU_ID
        AND FRAU_FRAC_ID = FRAC_ID
        AND FRAC_FRAN_NAME = 'DP'
        AND PORL_CIRT_NAME =
        (SELECT CIRH_PARENT
        FROM CIRCUIT_HIERARCHY
        WHERE CIRH_CHILD =
        (SELECT CIRT_NAME
        FROM PROBLEMS, PROBLEM_LINKS,CIRCUITS
        WHERE PROM_NUMBER = IN_PROBLEM
        AND PROL_PROM_NUMBER = PROM_NUMBER
        AND PROL_FOREIGNTYPE = 'CIRCUITS'
        AND PROL_FOREIGNID = CIRT_NAME
        AND CIRT_STATUS IN ('INSERVICE','PROPOSED','COMMISSIONED')));

      PROCEDURE validateupdate (p_regexpr IN VARCHAR2)
      IS
      BEGIN
         SELECT COUNT (1)
         INTO   l_count
         FROM   problem_links
         WHERE  prol_prom_number = p_faultnumber AND REGEXP_LIKE (prol_foreigntype, p_regexpr);
      END;

   BEGIN
      SELECT prom_type
      INTO   l_prom_type
      FROM   problems
      WHERE  prom_number = p_faultnumber;

      -- update applicable only for SERVICES, CIRCUITS and EQUIPMENT link type
      -- other link type will not be handled
      IF p_linkentitytype = 'SERVICES' AND l_prom_type <> 'SRT' THEN
         validateupdate ('(CIRCUITS|EQUIPMENT)');
      ELSIF p_linkentitytype = 'CIRCUITS' AND l_prom_type <> 'CRT' THEN
         validateupdate ('(SERVICES|EQUIPMENT)');
      ELSIF p_linkentitytype = 'EQUIPMENT' AND l_prom_type <> 'NWK' THEN
         validateupdate ('(SERVICES|CIRCUITS)');
      END IF;

      -- update fault type based on link type
      -- SERVICES -> SRT, CIRCUIT -> CRT, EQUIPMENT -> NWK
      IF l_count = 0 THEN
         UPDATE problems
         SET prom_type = (CASE p_linkentitytype
                             WHEN 'SERVICES' THEN 'SRT'
                             WHEN 'CIRCUITS' THEN 'CRT'
                             ELSE 'NWK'
                          END)
         WHERE  prom_number = p_faultnumber;
      END IF;

      -- additional check for if link type = CIRCUITS
      -- link the circuit service to the fault as well
      IF p_linkentitytype = 'CIRCUITS' THEN
         validateupdate ('SERVICES');
      END IF;

      IF l_count = 0 THEN
         BEGIN
            SELECT cirt_serv_id
            INTO   l_serv_id
            FROM   circuits
            WHERE  cirt_name = p_linkentityid;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               l_serv_id := NULL;
         END;

         IF (l_serv_id IS NOT NULL) THEN
            l_prol.prol_prom_number := p_faultnumber;
            l_prol.prol_foreignid := l_serv_id;
            l_prol.prol_foreigntype := 'SERVICES';

            INSERT INTO problem_links
            VALUES      l_prol;
         END IF;
      END IF;
      
      -- additional check for if link type = SERVICES
      -- Load sla and restoration time fault attributes from service attributes
      IF p_linkentitytype = 'SERVICES' THEN
      
         l_count := 1;
         INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'SLA_WINDOW',NULL,'NONE','14','CHAR'); 
         INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'RESTORATION_TIME',NULL,'NONE','15','CHAR');
         
         OPEN GET_SER_ATTRI_VALUE(p_linkentityid,'SLA_MAINTENANCE_WINDOW');
         FETCH GET_SER_ATTRI_VALUE INTO l_satt_val;
             IF GET_SER_ATTRI_VALUE%FOUND THEN
                 UPDATE PROBLEM_ATTRIBUTES 
                 SET PRAT_VALUE = l_satt_val
                 WHERE PRAT_PROM_NUMBER = p_faultnumber
                 AND PRAT_PRAL_NAME = 'SLA_WINDOW';
             ELSE
                 l_count := 0;
             END IF;
         CLOSE GET_SER_ATTRI_VALUE;
         
         l_satt_val := null;         
            
         OPEN GET_SER_ATTRI_VALUE(p_linkentityid,'RESTORATION_TIME');
         FETCH GET_SER_ATTRI_VALUE INTO l_satt_val;
             IF GET_SER_ATTRI_VALUE%FOUND THEN
                 UPDATE PROBLEM_ATTRIBUTES 
                 SET PRAT_VALUE = l_satt_val
                 WHERE PRAT_PROM_NUMBER = p_faultnumber
                 AND PRAT_PRAL_NAME = 'RESTORATION_TIME';
             ELSE
                 l_count := 0;
             END IF;
         CLOSE GET_SER_ATTRI_VALUE;     
         
         l_satt_val := null;   
        
         IF l_count = 0 THEN 
        
            OPEN GET_SO_OR_ATT_VALUE(p_linkentityid,'SLA_MAINTENANCE_WINDOW');
            FETCH GET_SO_OR_ATT_VALUE INTO l_seoa_val;
              IF GET_SO_OR_ATT_VALUE%FOUND THEN
                 UPDATE PROBLEM_ATTRIBUTES 
                 SET PRAT_VALUE = l_seoa_val
                 WHERE PRAT_PROM_NUMBER = p_faultnumber
                 AND PRAT_PRAL_NAME = 'SLA_WINDOW';              
              ELSE
                l_count := 0;    
              END IF;
            CLOSE GET_SO_OR_ATT_VALUE;
            
            l_seoa_val := null;
        
            OPEN GET_SO_OR_ATT_VALUE(p_linkentityid,'RESTORATION_TIME');
            FETCH GET_SO_OR_ATT_VALUE INTO l_seoa_val;
              IF GET_SO_OR_ATT_VALUE%FOUND THEN
                 UPDATE PROBLEM_ATTRIBUTES 
                 SET PRAT_VALUE = l_seoa_val
                 WHERE PRAT_PROM_NUMBER = p_faultnumber
                 AND PRAT_PRAL_NAME = 'RESTORATION_TIME';
              ELSE
                l_count := 0;    
              END IF;
            CLOSE GET_SO_OR_ATT_VALUE;      
            
            l_seoa_val := null;
                  
         END IF;
      END IF;
    
       OPEN CHILD_CCT_LOOP (p_faultnumber);
            FETCH CHILD_CCT_LOOP INTO TEMP_DATA;
            CLOSE CHILD_CCT_LOOP;

            IF TEMP_DATA IS NULL THEN 
            OPEN PARENT_CCT_LOOP(p_faultnumber);
            FETCH PARENT_CCT_LOOP INTO TEMP_DATA;
            CLOSE PARENT_CCT_LOOP;
            END IF;
       
       v_dploop := TEMP_DATA;
           
       SELECT CIRT_DISPLAYNAME, CIRT_SERT_ABBREVIATION
            INTO   v_circuit, v_service
            FROM PROBLEM_LINKS, CIRCUITS
            WHERE PROL_PROM_NUMBER = p_faultnumber
            AND PROL_FOREIGNTYPE = 'CIRCUITS'
            AND PROL_FOREIGNID = CIRT_NAME;
      
      
       SELECT ADDE_STREETNUMBER||', '||ADDE_STRN_NAMEANDTYPE||', '||ADDE_SUBURB||', '||ADDE_CITY||', '||ADDE_COUNTRY
          INTO   l_prom_add
          FROM PROBLEMS, PROBLEM_LINKS, SERVICES_ADDRESS, ADDRESSES
          WHERE PROM_NUMBER = p_faultnumber
          AND PROL_PROM_NUMBER = PROM_NUMBER
          AND PROL_FOREIGNTYPE = 'SERVICES'
          AND PROL_FOREIGNID = SADD_SERV_ID
          AND SADD_TYPE = 'BEND'
          AND ADDE_ID = SADD_ADDE_ID;
          
       SELECT CUSR_NAME
          INTO l_cus_name
          FROM SERVICES, PROBLEM_LINKS, CUSTOMER
          WHERE SERV_ID = PROL_FOREIGNID
          AND PROL_PROM_NUMBER = p_faultnumber
          AND PROL_FOREIGNTYPE = 'SERVICES'
          AND CUSR_ABBREVIATION = SERV_CUSR_ABBREVIATION;
       
       SELECT SATT_DEFAULTVALUE
          INTO l_ser_pkg
          FROM SERVICES, PROBLEM_LINKS, CUSTOMER, SERVICES_ATTRIBUTES
          WHERE SERV_ID = PROL_FOREIGNID
          AND PROL_PROM_NUMBER = p_faultnumber
          AND PROL_FOREIGNTYPE = 'SERVICES'
          AND CUSR_ABBREVIATION = SERV_CUSR_ABBREVIATION
          AND SATT_ATTRIBUTE_NAME = 'SA_PACKAGE_NAME'
          AND SATT_SERV_ID = SERV_ID;
       
       IF v_service IN ('D-VALUE VPN','D-ETHERNET VPN','ADSL') THEN
        -----  ADSL / BIZ-DSL / VALUE-VPN  Service -----        
        SELECT REPLACE(EQUP_LOCN_TTNAME,'-NODE','')||'_'||REPLACE(EQUP_EQUM_MODEL,'-ISL','')||'_'||SUBSTR(EQUP_INDEX,2)||' / '||PORT_CARD_SLOT||'-'||REPLACE(PORT_NAME,'DSL-IN-','')
        INTO v_swport
        FROM PROBLEMS, PROBLEM_LINKS,CIRCUITS, PORTS, EQUIPMENT
        WHERE PROM_NUMBER = p_faultnumber
        AND PROL_PROM_NUMBER = PROM_NUMBER
        AND PROL_FOREIGNTYPE = 'CIRCUITS'
        AND PROL_FOREIGNID = CIRT_NAME
        AND PORT_CIRT_NAME = CIRT_NAME
        AND PORT_NAME LIKE 'DSL-IN-%'
        AND PORT_EQUP_ID = EQUP_ID;

       ELSIF v_service = 'PSTN' THEN
        -----  PSTN  Service -----        
        SELECT REPLACE(EQUP_LOCN_TTNAME,'-NODE','')||'_'||REPLACE(EQUP_EQUM_MODEL,'-ISL','')||'_'||SUBSTR(EQUP_INDEX,2)||' / '||PORT_CARD_SLOT||'-'||REPLACE(PORT_NAME,'POTS-IN-','')
        INTO v_swport
        FROM PROBLEMS, PROBLEM_LINKS,CIRCUITS, PORTS, EQUIPMENT
        WHERE PROM_NUMBER = p_faultnumber
        AND PROL_PROM_NUMBER = PROM_NUMBER
        AND PROL_FOREIGNTYPE = 'CIRCUITS'
        AND PROL_FOREIGNID = CIRT_NAME
        AND PORT_CIRT_NAME = CIRT_NAME
        AND PORT_NAME LIKE 'POTS-IN-%'
        AND PORT_EQUP_ID = EQUP_ID;
       
       ELSE
       
       v_swport := NULL;
       
       END IF;
          
          
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'ADDRESS',NULL,'NONE','19','CHAR');
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'DP_LOOP',NULL,'NONE','20','CHAR');
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'SW_PORT',NULL,'NONE','21','CHAR');
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'SERVICE_TYPE',NULL,'NONE','22','CHAR');
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'CUSTOMER_NAME',NULL,'NONE','23','CHAR');
      INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'PACKAGE',NULL,'NONE','24','CHAR');
      
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_prom_add
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'ADDRESS';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = v_dploop
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'DP_LOOP';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = v_swport
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'SW_PORT';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = v_service
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'SERVICE_TYPE';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_cus_name
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'CUSTOMER_NAME';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_ser_pkg
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'PACKAGE';
   
    
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         DBMS_OUTPUT.put_line ('Err: Proc ' || $$plsql_unit || ' Line:' || $$plsql_line);
   END;


---- Dinesh Perera 27-07-2015  ----
---- Contact_number added  08-10-2015  ----
PROCEDURE FAULT_LEA_UPDATE (p_faultnumber IN NUMBER)
   IS
      l_prom_lea        problems.PROM_REGN_CODE%TYPE;     
      l_satt_val        services_attributes.satt_defaultvalue%TYPE;
      l_seoa_val        service_order_attributes.seoa_defaultvalue%TYPE;
      l_prom_contact    problems.PROM_REPORTEDCONTACT%TYPE;
   --   l_prom_add        VARCHAR2(1000);

      
  BEGIN
      SELECT PROM_REGN_CODE, PROM_REPORTEDCONTACT
      INTO   l_prom_lea, l_prom_contact
      FROM PROBLEMS
      WHERE PROM_NUMBER = p_faultnumber;
      
    /*  SELECT ADDE_STREETNUMBER||', '||ADDE_STRN_NAMEANDTYPE||', '||ADDE_SUBURB||', '||ADDE_CITY||', '||ADDE_COUNTRY
      INTO   l_prom_add
      FROM PROBLEMS, PROBLEM_LINKS, SERVICES_ADDRESS, ADDRESSES
      WHERE PROM_NUMBER = p_faultnumber
      AND PROL_PROM_NUMBER = PROM_NUMBER
      AND PROL_FOREIGNTYPE = 'SERVICES'
      AND PROL_FOREIGNID = SADD_SERV_ID
      AND SADD_TYPE = 'BEND'
      AND ADDE_ID = SADD_ADDE_ID;*/
      

            INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'LEA',NULL,'NONE','16','CHAR');
            INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'CONTACT_NUMBER',NULL,'NONE','18','CHAR');
          ----  INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'ADDRESS',NULL,'NONE','19','CHAR');
        
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_prom_lea
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'LEA';
            
            UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_prom_contact
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'CONTACT_NUMBER';
            
         /*   UPDATE PROBLEM_ATTRIBUTES 
            SET PRAT_VALUE = l_prom_add
            WHERE PRAT_PROM_NUMBER = p_faultnumber
            AND PRAT_PRAL_NAME = 'ADDRESS';*/


     
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         DBMS_OUTPUT.put_line ('Err: Proc ' || $$plsql_unit || ' Line:' || $$plsql_line);
   END;


---- Dinesh Perera 28-07-2015  ----
PROCEDURE FAULT_ESCALATION_INDEX (p_faultnumber IN NUMBER)
   IS
      L_PROM_INDEX  NUMBER; 
      L_PROBLEM_ATT NUMBER;    
      l_satt_val    services_attributes.satt_defaultvalue%TYPE;
      l_seoa_val    service_order_attributes.seoa_defaultvalue%TYPE;

      
  BEGIN
      
      SELECT COUNT(*)
      INTO L_PROBLEM_ATT
      FROM PROBLEM_ATTRIBUTES 
      WHERE PRAT_PROM_NUMBER = p_faultnumber
      AND PRAT_PRAL_NAME = 'ESCALATION_INDEX';
      
      SELECT COUNT(*)
      INTO   L_PROM_INDEX
      FROM PROBLEM_COMMENTS
      WHERE PROC_PROM_NUMBER = p_faultnumber
      AND PROC_TEXT LIKE '121-%'
      AND PROC_USERENTERED = 'Y';
      
      IF L_PROBLEM_ATT = '0' THEN 

       INSERT INTO PROBLEM_ATTRIBUTES VALUES (p_faultnumber,'ESCALATION_INDEX',NULL,'NONE','17','CHAR');
        
       UPDATE PROBLEM_ATTRIBUTES 
       SET PRAT_VALUE = L_PROM_INDEX
       WHERE PRAT_PROM_NUMBER = p_faultnumber
       AND PRAT_PRAL_NAME = 'ESCALATION_INDEX'; 

      ELSIF L_PROM_INDEX != '0' THEN
      
       UPDATE PROBLEM_ATTRIBUTES 
       SET PRAT_VALUE = L_PROM_INDEX
       WHERE PRAT_PROM_NUMBER = p_faultnumber
       AND PRAT_PRAL_NAME = 'ESCALATION_INDEX';
       
      END IF;
     
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         DBMS_OUTPUT.put_line ('Err: Proc ' || $$plsql_unit || ' Line:' || $$plsql_line);
   END;
      
END;
/
