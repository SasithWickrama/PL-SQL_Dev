CREATE OR REPLACE PACKAGE BODY GCI_MIG.P_Slt_Functions AS

-- 28-07-2008 Vinay TechM
PROCEDURE SLT_ADSL_IPTV_ADDED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_isvalid VARCHAR(1);

BEGIN

    SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
    AND SOFE_FEATURE_NAME = 'IPTV' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N') AND SOFE_DEFAULTVALUE = 'Y';

    p_ret_msg := '';

EXCEPTION

WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END SLT_ADSL_IPTV_ADDED;
-- 28-07-2008 Vinay TechM

-- 28-07-2008 Vinay TechM
PROCEDURE SLT_ADSL_IPTV_REMOVED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_isvalid VARCHAR(1);

BEGIN

    SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
    AND SOFE_FEATURE_NAME = 'IPTV' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'Y') AND SOFE_DEFAULTVALUE = 'N';

    p_ret_msg := '';

EXCEPTION

WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END SLT_ADSL_IPTV_REMOVED;
-- 28-07-2008 Vinay TechM

-- 07-08-2008 Gihan Amarasinghe

PROCEDURE SLT_CHANGE_ATTR_VAL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

     CURSOR sero_cur IS
     SELECT sero_sert_abbreviation, sero_ordt_type
       FROM service_orders
         WHERE sero_id = p_sero_id;

v_isvalid VARCHAR(1);
sero_rec                    sero_cur%ROWTYPE;

BEGIN

    OPEN sero_cur;
        FETCH sero_cur INTO sero_rec;
        CLOSE sero_cur;

    IF sero_rec.sero_sert_abbreviation = 'PSTN' AND sero_rec.sero_ordt_type = 'MODIFY-LOCATION' THEN
         UPDATE clarity.service_order_attributes
               SET SEOA_DEFAULTVALUE = NULL
               WHERE seoa_sero_id = p_sero_id
               AND SEOA_SERO_REVISION = 0
               AND SEOA_NAME = 'SA_DISTANCE';
    END IF;

      UPDATE clarity.service_order_attributes
      SET SEOA_DEFAULTVALUE = NULL
      WHERE seoa_sero_id = p_sero_id
      AND SEOA_SERO_REVISION = 0
      AND SEOA_NAME IN ('SUPPLEMENTARY WORK COST','ESTIMATE_SERIAL_NO','INSTALLED BY','SA_SITE_VISIT_DATE');

      p_ret_msg := '';

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION

WHEN NO_DATA_FOUND THEN
   p_ret_msg := '';
WHEN OTHERS THEN
   p_ret_msg := 'Failure in Attribute update';
END SLT_CHANGE_ATTR_VAL;
-- 07-08-2008 Gihan Amarasinghe

-- 15-08-2008 Gihan Amarasinghe
PROCEDURE SLT_LOAD_SERV_FEAT_FROM_HIST (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

   CURSOR diff_sfea_cur  IS
    SELECT SFEA_FEATURE_NAME FROM services_features
    WHERE sfea_serv_id = p_serv_id
    --AND SFEA_PARENT_FEATURE_NAME IS NOT NULL
    AND sfea_value = 'Y'
    MINUS
    SELECT SOFE_FEATURE_NAME FROM service_order_features
    WHERE sofe_sero_id = p_sero_id;
    --AND SOFE_PARENT_FEATURE_NAME IS NOT NULL;

   CURSOR serv_feat_curr (c_sfea_name     IN services_features.SFEA_FEATURE_NAME%TYPE) IS
    SELECT * FROM services_features
    WHERE sfea_serv_id = p_serv_id
    AND SFEA_FEATURE_NAME = c_sfea_name;

   CURSOR satt_cur( c_sfea_id     IN services_attributes.satt_sfea_id%TYPE)   IS
      SELECT *
        FROM services_attributes
       WHERE satt_sfea_id = c_sfea_id
         AND satt_serv_id = p_serv_id;

   CURSOR sero_cur IS
     SELECT sero_ordt_type
       FROM service_orders
         WHERE sero_id = p_sero_id;

   serv_feat_rec            serv_feat_curr%ROWTYPE;
   sero_rec                    sero_cur%ROWTYPE;
   l_sofe_id            NUMBER;

  BEGIN
    -- Assumption -> This will be configured for MODIFY-SERVICE order type of ADSL service

    OPEN sero_cur;
    FETCH sero_cur INTO sero_rec;
    CLOSE sero_cur;

    IF sero_rec.sero_ordt_type = 'MODIFY-SERVICE' THEN

        DBMS_OUTPUT.PUT_LINE('Process Populate Users for Sero:' || p_sero_id || '-' || sero_rec.sero_ordt_type);

        FOR sfea_rec  IN diff_sfea_cur LOOP
        OPEN serv_feat_curr(sfea_rec.SFEA_FEATURE_NAME);
           FETCH serv_feat_curr INTO serv_feat_rec;
           CLOSE serv_feat_curr;

             DBMS_OUTPUT.PUT_LINE('Process Populate Users for SeroFea:' || p_sero_id || '-' || sfea_rec.SFEA_FEATURE_NAME);

             SELECT sofe_id_seq.NEXTVAL INTO l_sofe_id FROM dual;

             INSERT INTO service_order_features(SOFE_SERO_ID,
                    SOFE_SERO_REVISION,
                    SOFE_FEATURE_NAME,
                    SOFE_TYPE,
                    SOFE_DEFAULTVALUE,
                    SOFE_PREV_VALUE,
                    SOFE_PARENT_FEATURE_NAME,
                    SOFE_PROVISION_STATUS,
                    SOFE_PROVISION_TIME,
                    SOFE_PROVISION_USERNAME,
                    SOFE_ID)
             VALUES(p_sero_id, 0, serv_feat_rec.SFEA_FEATURE_NAME,serv_feat_rec.sfea_type,
             'Y',
             'Y',
             serv_feat_rec.SFEA_PARENT_FEATURE_NAME,'','','', l_sofe_id);

          FOR satt_rec IN satt_cur(serv_feat_rec.sfea_id) LOOP

        DBMS_OUTPUT.PUT_LINE('Process Populate Users for SeroAttr:' || p_sero_id || '-' || satt_rec.SATT_ATTRIBUTE_NAME);

               INSERT INTO service_order_attributes(SEOA_ID, SEOA_NAME, SEOA_SERO_ID, SEOA_SERO_REVISION,
                                             SEOA_DEFAULTVALUE, SEOA_DISPLAY_ORDER, SEOA_PREV_VALUE, SEOA_SOFE_ID)

               VALUES(seoa_id_seq.NEXTVAL, satt_rec.SATT_ATTRIBUTE_NAME, p_sero_id, 0,
                       satt_rec.SATT_DEFAULTVALUE,
                       99,
                       satt_rec.SATT_DEFAULTVALUE,
                       l_sofe_id);

           END LOOP;

        END LOOP;

     END IF;

     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_msg  := 'Failed to add users from history. Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
END SLT_LOAD_SERV_FEAT_FROM_HIST;
-- 15-08-2008 Gihan Amarasinghe

-- 28-08-2008 Gihan Amarasinghe
  PROCEDURE populate_serv_feature_del_adsl (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2) IS

   CURSOR sfea_cur  IS
      SELECT *
        FROM services_features sfea
       WHERE sfea.sfea_serv_id = p_serv_id;

   CURSOR satt_cur( c_sfea_id     IN services_attributes.satt_sfea_id%TYPE)   IS
      SELECT *
        FROM services_attributes
       WHERE satt_sfea_id = c_sfea_id
         AND satt_serv_id = p_serv_id;

   CURSOR sero_cur IS
     SELECT sero_ordt_type
       FROM service_orders
         WHERE sero_id = p_sero_id;

   CURSOR sero_cur_suspend IS
     SELECT sero_ordt_type
       FROM service_orders
         WHERE sero_serv_id = p_serv_id
           AND sero_id != p_sero_id
           AND sero_stas_abbreviation NOT IN ('CLOSED','CANCELLED','WAITERS')
             ORDER BY sero_datecreated DESC;

   sero_rec            sero_cur%ROWTYPE;

   l_sofe_id            NUMBER;
   l_default_value        VARCHAR2(2000);
   l_prev_value            VARCHAR2(2000);
   l_previous_ordt_type        VARCHAR2(100);

  BEGIN
    -- Assumption -> This will be configured for SUSPEND, RESUME and delete order types for LADP Service

    OPEN sero_cur;
    FETCH sero_cur INTO sero_rec;
    CLOSE sero_cur;

    OPEN sero_cur_suspend;
    FETCH sero_cur_suspend INTO l_previous_ordt_type;
    IF sero_cur_suspend%NOTFOUND THEN
      l_previous_ordt_type := 'NOTTHERE';
    END IF;
    CLOSE sero_cur_suspend;
    DBMS_OUTPUT.PUT_LINE('Process Populate Users Prevous Ordt:' || p_sero_id || '-' || l_previous_ordt_type);

    IF sero_rec.sero_ordt_type LIKE 'SUSPEND%' OR sero_rec.sero_ordt_type LIKE 'DELETE%' THEN
      l_default_value := 'N';
      l_prev_value    := 'Y';
    ELSE
      l_default_value := 'Y';
      l_prev_value    := 'N';
    END IF;

    IF l_previous_ordt_type LIKE '%SUSPEND%' AND sero_rec.sero_ordt_type LIKE 'DELETE%' THEN
      l_default_value := 'Y';
      l_prev_value    := 'N';
    END IF;

    DBMS_OUTPUT.PUT_LINE('Process Populate Users for Sero:' || p_sero_id || '-' || sero_rec.sero_ordt_type);

    -- delete incase the non-switch features are poluated
    DELETE FROM service_order_attributes WHERE SEOA_SOFE_ID IN
              (SELECT SOFE_ID FROM service_order_features
                 WHERE sofe_sero_id = p_sero_id);

    DELETE FROM service_order_features WHERE sofe_sero_id = p_sero_id;

    FOR sfea_rec  IN sfea_cur LOOP

      DBMS_OUTPUT.PUT_LINE('Process Populate Users for SeroFea:' || p_sero_id || '-' || sfea_rec.SFEA_FEATURE_NAME);

      SELECT sofe_id_seq.NEXTVAL INTO l_sofe_id FROM dual;

      -- if sfea_rec.sfea_value = 'Y' then
      --   l_default_value := 'N';
      -- else
      --   l_default_value := 'Y';
      -- end if;

      INSERT INTO service_order_features(SOFE_SERO_ID,
                    SOFE_SERO_REVISION,
                    SOFE_FEATURE_NAME,
                    SOFE_TYPE,
                    SOFE_DEFAULTVALUE,
                    SOFE_PREV_VALUE,
                    SOFE_PARENT_FEATURE_NAME,
                    SOFE_PROVISION_STATUS,
                    SOFE_PROVISION_TIME,
                    SOFE_PROVISION_USERNAME,
                    SOFE_ID)
      VALUES(p_sero_id, 0, sfea_rec.SFEA_FEATURE_NAME,sfea_rec.sfea_type,
             l_default_value,
             sfea_rec.sfea_value,
             sfea_rec.SFEA_PARENT_FEATURE_NAME,'','','', l_sofe_id);

      FOR satt_rec IN satt_cur(sfea_rec.sfea_id) LOOP
        DBMS_OUTPUT.PUT_LINE('Process Populate Users for SeroAttr:' || p_sero_id || '-' || satt_rec.SATT_ATTRIBUTE_NAME);

        INSERT INTO service_order_attributes(SEOA_ID, SEOA_NAME, SEOA_SERO_ID, SEOA_SERO_REVISION,
                                             SEOA_DEFAULTVALUE, SEOA_DISPLAY_ORDER, SEOA_PREV_VALUE, SEOA_SOFE_ID)

        VALUES(seoa_id_seq.NEXTVAL, satt_rec.SATT_ATTRIBUTE_NAME, p_sero_id, 0,
               satt_rec.SATT_DEFAULTVALUE,
               99,
               satt_rec.SATT_DEFAULTVALUE,
               l_sofe_id);

      END LOOP;

    END LOOP;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_msg  := 'Failed to add users from history. Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
  END populate_serv_feature_del_adsl;
-- 28-08-2008 Gihan Amarasinghe
-- 02-09-2008 Gihan Amarasinghe
PROCEDURE copy_CIRCUIT_details_slt (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2) IS

  CURSOR sero_cur IS
    SELECT SERO_SERT_ABBREVIATION, SERO_ORDT_TYPE, SERO_CIRT_NAME,
           SERO_SPED_ABBREVIATION, SERO_STAS_ABBREVIATION, SERO_LOCN_ID_BEND
      FROM SERVICE_ORDERS
        WHERE SERO_ID = p_sero_id ;

  CURSOR seoa_cur(c_seoa_name          IN   VARCHAR2) IS
     SELECT seoa_defaultvalue
       FROM  service_order_attributes
     WHERE seoa_sero_id       = p_sero_id
       AND SEOA_NAME        = c_seoa_name;

  sero_rec            sero_cur%ROWTYPE;

  l_old_cirt_name        circuits.cirt_name%TYPE;
  l_seoa_name            VARCHAR2(1000);
  l_seit_taskname        IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE;
  l_ret_msg            VARCHAR2(4000);

BEGIN
   OPEN  sero_cur;
   FETCH sero_cur INTO sero_rec;
   CLOSE sero_cur;

   IF sero_rec.sero_sert_abbreviation LIKE 'ISDN%' THEN
     l_seoa_name := 'SA_PSTN_NUMBER';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-IPVPN%' THEN
     l_seoa_name := 'OLD DATA CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-P2P%' THEN
     l_seoa_name := 'OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-VALUE VPN%' THEN
     l_seoa_name := 'OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-VPLS ACCESS LINK%' THEN
     l_seoa_name := 'OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-ILL%' THEN
     l_seoa_name := 'OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-DIDO%' THEN
     l_seoa_name := 'SA_OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-IPLC%' THEN
     l_seoa_name := 'OLD CIRCUIT ID';
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-SIP TRUNK' THEN
     l_seoa_name := 'OLD CIRCUIT ID';  
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-DAB' THEN
     l_seoa_name := 'OLD CIRCUIT ID'; 
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-ETHERNET VPN' THEN
     l_seoa_name := 'OLD CIRCUIT ID';     
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-PREMIUM IPVPN' THEN
     l_seoa_name := 'OLD CIRCUIT ID';    
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-SCHOOLNET BACKHAUL' THEN
     l_seoa_name := 'OLD CIRCUIT ID'; 
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-BTL' THEN
     l_seoa_name := 'OLD CIRCUIT ID'; 
   ELSE
     l_seoa_name := 'SA_ISDN_NUMBER';
   END IF;

   OPEN  seoa_cur(l_seoa_name);
   FETCH seoa_cur INTO l_old_cirt_name;
   CLOSE seoa_cur;

  -- Vinay TechM Test Start  17-12-2007
   SELECT MAX(a.CIRT_NAME) INTO l_old_cirt_name FROM circuits a WHERE a.CIRT_DISPLAYNAME = l_old_cirt_name and CIRT_STATUS = 'INSERVICE';
  -- Vinay TechM Test end 17-12-2007
   IF copyXconnection.copyPortLinks(10, sero_rec.sero_cirt_name, l_old_cirt_name, 'REUSE', 'F', l_ret_msg) THEN

     p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id,'COMPLETED');

   ELSE
     p_auto_execute_tasks.add_work_comment(p_seit_id, l_ret_msg);
     p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id,'ERROR');
   END IF;
END copy_CIRCUIT_details_slt;
-- 02-09-2008 Gihan Amarasinghe

-- 02-09-2008 Gihan Amarasinghe
PROCEDURE slt_chk_feat_prov_custom(
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2) IS

    CURSOR sero_cur IS
      SELECT sero_ordt_type
        FROM service_orders
          WHERE sero_id = p_sero_id;

   CURSOR sofe_cur    IS

      SELECT sofe_feature_name, sofe_defaultvalue, sofe_prev_value, SOFE_PROVISION_STATUS, seit_taskname
        FROM service_order_features, service_implementation_tasks
        WHERE sofe_sero_id = p_sero_id
    AND seit_id = p_seit_id
        AND sofe_defaultvalue <> sofe_prev_value
        AND NVL(sofe_provision_status,'N') = 'N';

   sero_rec            sero_cur%ROWTYPE;
   l_count            NUMBER := 0;
   l_unprovisioned_features    VARCHAR2(2000);

  BEGIN

    DBMS_OUTPUT.PUT_LINE('Process check_features_provisioned for Sero:' || p_sero_id );
    p_ret_msg := '';

    OPEN sero_cur;
    FETCH sero_cur INTO sero_rec;
    CLOSE sero_cur;

    FOR sofe_rec  IN sofe_cur LOOP
      IF sero_rec.sero_ordt_type IN ('MODIFY-SERVICE','CREATE') THEN
    IF sofe_rec.sofe_feature_name IN ('IPTV','TSTV','VIDEO ON DEMAND') AND sofe_rec.seit_taskname = 'ACTIVATE IPTV SERVIC' THEN
            l_unprovisioned_features := l_unprovisioned_features || '   ' || sofe_rec.sofe_feature_name;
    END IF;
      END IF;

    END LOOP;

    UPDATE service_order_attributes SET seoa_defaultvalue =
              (SELECT TO_CHAR(NVL(MAX(SOFE_PROVISION_TIME),SYSDATE), 'DD-MON-YYYY HH24:MI') FROM service_order_features
                  WHERE sofe_sero_id = p_sero_id AND sofe_provision_time IS NOT NULL)
      WHERE seoa_sero_id = p_sero_id
        AND seoa_name LIKE 'ACTUAL_DSP_DATE%';

    IF  l_unprovisioned_features IS NOT NULL THEN
    p_ret_char := 'Some of the requested features are not yet provisioned. ' || SUBSTR(l_unprovisioned_features,1,100) || '...' ;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_msg  := 'check_features_provisioned.  Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
  END slt_chk_feat_prov_custom;
-- 02-09-2008 Gihan Amarasinghe


-- 09-09-2008 Gihan Amarasinghe/Samankula Owitipana
-- CHANGED  19-06-2009
--- Modified to accomadate all number status
PROCEDURE SLT_CDMA_NUMB_RESERVE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      
v_NUMB_NO VARCHAR2(10);
v_PP_VAL VARCHAR2(50);
v_numb_status number;      
v_serv_id VARCHAR2(50);
CURSOR num_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_CDMA_NUMBER';
--AND    SOA.SEOA_DEFAULTVALUE LIKE '060%';
CURSOR pp_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PRE-PAID';
CURSOR c_number_status  IS
select nu.NUMB_NUMS_ID,nu.NUMB_SERV_ID from numbers nu
WHERE NU.NUMB_NUMBER = SUBSTR(v_NUMB_NO,4,7)
AND NU.NUMB_NUCC_CODE = SUBSTR(v_NUMB_NO,1,3);

BEGIN

OPEN num_select_cur;
FETCH num_select_cur INTO v_NUMB_NO;
CLOSE num_select_cur;
OPEN pp_select_cur;
FETCH pp_select_cur INTO v_PP_VAL;
CLOSE pp_select_cur;
OPEN c_number_status;
FETCH c_number_status INTO v_numb_status,v_serv_id;
CLOSE c_number_status;

IF v_numb_status = 3 or v_numb_status = 6 THEN

if v_serv_id is null then

UPDATE NUMBERS NU
SET NU.NUMB_NUMS_ID = 3 ,
NU.NUMB_SERV_ID = p_serv_id
WHERE NU.NUMB_NUMBER = SUBSTR(v_NUMB_NO,4,7)
AND NU.NUMB_NUCC_CODE = SUBSTR(v_NUMB_NO,1,3)
AND (NU.NUMB_NUMS_ID = 3 OR NU.NUMB_NUMS_ID = 6);

end if;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
ELSIF v_PP_VAL = 'N[pre2post]' or v_PP_VAL = 'Y[post2pre]' or v_PP_VAL = 'Y[PerMin]' or v_PP_VAL = 'N[PerMin]'
or v_PP_VAL = 'Y[Sec2Min]' or v_PP_VAL = 'N[Sec2Min]' THEN
UPDATE NUMBERS NU
SET NU.NUMB_NUMS_ID = 3 ,
NU.NUMB_SERV_ID = p_serv_id
WHERE NU.NUMB_NUMBER = SUBSTR(v_NUMB_NO,4,7)
AND NU.NUMB_NUCC_CODE = SUBSTR(v_NUMB_NO,1,3)
AND (NU.NUMB_NUMS_ID = 2 OR NU.NUMB_NUMS_ID = 5);

IF SQL%NOTFOUND THEN
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, 'Failed to reserve number. Please check the number:' || v_NUMB_NO); ELSE
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
END IF;ELSE 
UPDATE NUMBERS NU
SET NU.NUMB_NUMS_ID = 3 ,
NU.NUMB_SERV_ID = p_serv_id
WHERE NU.NUMB_NUMBER = SUBSTR(v_NUMB_NO,4,7)
AND NU.NUMB_NUCC_CODE = SUBSTR(v_NUMB_NO,1,3)
AND (NU.NUMB_NUMS_ID = 2 OR NU.NUMB_NUMS_ID = 5);

IF SQL%NOTFOUND THEN
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, 'Failed to reserve number. Please check the number:' || v_NUMB_NO);
ELSE p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
END IF;END IF;

EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to reserve number. Please check the number:' || v_NUMB_NO || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END SLT_CDMA_NUMB_RESERVE;

-- 09-09-2008 Gihan Amarasinghe/Samankula Owitipana


-- Edited on 02-01-2012
-- 16-Sep-2008 Vinay Techm/Jayan Liyanage
PROCEDURE SLT_SET_DSLAM_VLAN_ID(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2) IS
-- Vinay TechM 15-Sep-2008 CURSOR c_vlan_query  IS

-- New Cursor 2011-01-12 ---
-- New Cursor 2011-08-10 ---

    CURSOR c_vlan_query (v_seit_id Service_Implementation_Tasks.seit_id%TYPE) IS
    SELECT SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'HomeExpress'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'HomeExpress'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'HomeExpress'||CHR(9))-1),CHR(9),-1,1)+1)) HomeVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'OfficeExpress'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'OfficeExpress'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'OfficeExpress'||CHR(9))-1),CHR(9),-1,1)+1)) OfficeVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Entree'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'Entree'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Entree'||CHR(9))-1),CHR(9),-1,1)+1)) EntreeVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'IPTV'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'IPTV'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'IPTV'||CHR(9))-1),CHR(9),-1,1)+1)) IPTVVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Xcite'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'Xcite'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Xcite'||CHR(9))-1),CHR(9),-1,1)+1)) XciteVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Xcel'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'Xcel'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'Xcel'||CHR(9))-1),CHR(9),-1,1)+1)) XcelVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'OfficePlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'OfficePlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'OfficePlus'||CHR(9))-1),CHR(9),-1,1)+1)) OfficePlusVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'XcitePlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'XcitePlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'XcitePlus'||CHR(9))-1),CHR(9),-1,1)+1)) XcitePlusVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'XcelPlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'XcelPlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'XcelPlus'||CHR(9))-1),CHR(9),-1,1)+1)) XcelPlusVLAN,
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'HomePlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'HomePlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'HomePlus'||CHR(9))-1),CHR(9),-1,1)+1)) HomePlusVLAN
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebSurferPlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebSurferPlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebSurferPlus'||CHR(9))-1),CHR(9),-1,1)+1)) WebSurferPlusVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebProPlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebProPlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebProPlus'||CHR(9))-1),CHR(9),-1,1)+1)) WebProPlusVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMasterPlus'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebMasterPlus'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMasterPlus'||CHR(9))-1),CHR(9),-1,1)+1)) WebMasterPlusVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMate'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebMate'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMate'||CHR(9))-1),CHR(9),-1,1)+1)) WebMateVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebSurfer'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebSurfer'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebSurfer'||CHR(9))-1),CHR(9),-1,1)+1)) WebSurferVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebPro'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebPro'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebPro'||CHR(9))-1),CHR(9),-1,1)+1)) WebProVLAN,
	--SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMaster'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'WebMaster'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'WebMaster'||CHR(9))-1),CHR(9),-1,1)+1)) WebMasterVLAN
         FROM service_implementation_tasks,
              sop_queue,
              sop_reply_data
        WHERE seit_id = v_seit_id -- Vinay TechM 15-Sep-2008 p_seit_id
          AND sopq_seit_id = seit_id
          AND sopq_sopc_command = 'LST-VLAN'
          AND sord_sopq_requestid = sopq_requestid
          AND SORD_NAME = 'RAW_MESSAGES';
          
-- New Cursor 2011-08-10 ---		  
-- New Cursor 2011-01-12 ---

--- Cursor Comment 2011-01-12 --

 -- CURSOR c_vlan_query (v_seit_id Service_Implementation_Tasks.seit_id%TYPE) IS
        -- SELECT /* replace space with tab substr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'HomeEx')-1)),instr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'HomeEx')-1)),' ',-1,1)+1) HomeVLAN,
            -- substr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'OfficeEx')-1)),instr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'OfficeEx')-1)),' ',-1,1)+1) OfficeVLAN,
            -- substr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'Entree')-1)),instr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'Entree')-1)),' ',-1,1)+1) EntreeVLAN,
            -- substr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'IPTV ')-1)),instr(trim(substr(SORD_VALUE,1,instr(SORD_VALUE,'IPTV ')-1)),' ',-1,1)+1) IPTVVLAN -- Vinay TechM 15-Sep-2008*/
            --  REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'HomeEx')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'HomeEx') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'HomeEx')-1)),CHR(9),-1,1))),CHR(9),'') HomeVLAN,
            --  REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'OfficeEx')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'OfficeEx') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'OfficeEx')-1)),CHR(9),-1,1))),CHR(9),'') OfficeVLAN,
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Entree')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'Entree') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Entree')-1)),CHR(9),-1,1))),CHR(9),'') EntreeVLAN,
              --------------- Samankula Owitipana 18 02 2010 -------------------------
        --REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'IPTV'||CHR(9))-1)),CHR(9),-1,1))+1,(INSTR(SORD_VALUE,'IPTV'||CHR(9)) - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'IPTV'||CHR(9))-1)),CHR(9),-1,1)-2)),CHR(9),'') IPTVVLAN,
              --SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'IPTV'||CHR(9))-1),CHR(9),-1,1)-1),CHR(9),-1,1)+1,((INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'IPTV'||CHR(9))-1),CHR(9),-1,1)-1) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'IPTV'||CHR(9))-1),CHR(9),-1,1)-1),CHR(9),-1,1)))) IPTVVLAN,

        --------------- Jayan Liyanage ADD 2009 02 13 -----
              --REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcite'||CHR(9))-1)),CHR(9),-1,1))+1,(INSTR(SORD_VALUE,'Xcite'||CHR(9)) - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcite'||CHR(9))-1)),CHR(9),-1,1)-2)),CHR(9),'') XciteVLAN,
              --REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcel'||CHR(9))-1)),CHR(9),-1,1))+1,(INSTR(SORD_VALUE,'Xcel'||CHR(9)) - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcel'||CHR(9))-1)),CHR(9),-1,1)-2)),CHR(9),'') XcelVLAN
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcite')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'Xcite') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcite')-1)),CHR(9),-1,1))),CHR(9),'') XciteVLAN,
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcel')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'Xcel') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'Xcel')-1)),CHR(9),-1,1))),CHR(9),'') XcelVLAN,
              --------------- Jayan Liyanage ADD 2009 02 13 -----
              --------------- Jayan Liyanage ADD 2010 06 23 -----
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'OfficePlus')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'OfficePlus') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'OfficePlus')-1)),CHR(9),-1,1))),CHR(9),'') OfficePlusVLAN,
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'XcitePlus')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'XcitePlus') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'XcitePlus')-1)),CHR(9),-1,1))),CHR(9),'') XcitePlusVLAN,
             -- REPLACE(SUBSTR( SORD_VALUE, (  INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'XcelPlus')-1)),CHR(9),-1,1))-1,(INSTR(SORD_VALUE,'XcelPlus') - INSTR(trim(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,'XcelPlus')-1)),CHR(9),-1,1))),CHR(9),'') XcelPlusVLAN
              --------------- Jayan Liyanage ADD 2010 06 23 -----       
              
              
        -- FROM service_implementation_tasks,
           --   sop_queue,
           --   sop_reply_data
       -- WHERE seit_id = v_seit_id -- Vinay TechM 15-Sep-2008 p_seit_id
        --  AND sopq_seit_id = seit_id
        --  AND sopq_sopc_command = 'LST-VLAN'
         -- AND sord_sopq_requestid = sopq_requestid; 
         
--- Cursor Comment 2011-01-12 --

--  CURSOR c_port_id IS -- Vinay TechM 15-Sep-2008
  CURSOR c_port_id  (v_seit_id Service_Implementation_Tasks.seit_id%TYPE) IS
    SELECT podi_port_id
        FROM service_implementation_tasks,
             service_orders,
             circuits,
             port_links,
             port_link_ports,
             ports,
             port_detail_instance
       WHERE seit_id = v_seit_id -- Vinay TechM 15-Sep-2008 p_seit_id
         AND sero_id = seit_sero_id
         AND cirt_name = sero_cirt_name
         AND porl_cirt_name = cirt_name
         AND polp_porl_id = porl_id
         AND port_id = polp_port_id
         AND podi_port_id = port_id
         AND podi_name = 'PA_DSLAM_DEV';

--  CURSOR c_port_name IS -- Vinay TechM 15-Sep-2008
    CURSOR c_port_name   (v_seit_id Service_Implementation_Tasks.seit_id%TYPE) IS
    SELECT podi_name
        FROM service_implementation_tasks,
             service_orders,
             circuits,
             port_links,
             port_link_ports,
             ports,
             port_detail_instance
       WHERE seit_id = v_seit_id -- Vinay TechM 15-Sep-2008 p_seit_id
         AND sero_id = seit_sero_id
         AND cirt_name = sero_cirt_name
         AND porl_cirt_name = cirt_name
         AND polp_porl_id = porl_id
         AND port_id = polp_port_id
         AND podi_port_id = port_id
         AND podi_name = 'PA_DSLAM_HOME_VLANID';

    l_vlan_query          VARCHAR2(2000);
    l_port_id            port_detail_instance.podi_port_id%TYPE;
    l_port_name            port_detail_instance.podi_name%TYPE;
    l_home_vlan_id         NUMBER;
    l_office_vlan_id    NUMBER;
    l_entree_vlan_id    NUMBER;
    l_IPTV_vlan_id    NUMBER;
    l_Xcite_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2009 02 13 -----
    l_Xcel_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2009 02 13 -----
    
    l_officeplus_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2009 02 13 -----
    l_Xciteplus_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2009 02 13 -----
    l_Xcelplus_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2009 02 13 -----
    l_Homeplus_vlan_id    NUMBER; --------------- Jayan Liyanage ADD 2011 02 09 -----
	
	--l_WebSurferPlus_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebProPlus_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebMasterPlus_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebMate_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebSurfer_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebPro_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
	--l_WebMaster_vlan_id    NUMBER; --------------- Samankula Owitipana ADD 2011 08 10 -----
    
    
    
         v_seit_id Service_Implementation_Tasks.seit_id%TYPE;
--22-10-2008 Vinay Techm ADD Error condition FOR RECORD NOT HAVING Vlan IDs START
     e_no_vlan_data_found  EXCEPTION;
--22-10-2008 Vinay Techm ADD Error condition FOR RECORD NOT HAVING Vlan IDs END
    BEGIN

         BEGIN
             SELECT MAX(SEIT_ID) INTO v_seit_id FROM SERVICE_IMPLEMENTATION_TASKS WHERE SEIT_SERO_ID = p_sero_id AND SEIT_TASKNAME IN ('QUERY DSLAM VLAN ID','QUERY VLAN ID');
         EXCEPTION
           WHEN OTHERS THEN
              p_ret_msg  := 'Unable to get Task Id for QUERY DSLAM VLAN ID Task';
         END;

         OPEN c_vlan_query(v_seit_id); -- Vinay TechM 15-Sep-2008
         FETCH c_vlan_query INTO l_home_vlan_id,l_office_vlan_id ,l_entree_vlan_id ,l_IPTV_vlan_id, l_Xcite_vlan_id, l_Xcel_vlan_id,l_officeplus_vlan_id,l_Xciteplus_vlan_id,l_Xcelplus_vlan_id,l_Homeplus_vlan_id; -- Vinay TechM 15-Sep-2008 --------------- Jayan Liyanage 2009 02 13 ----- --------------- Jayan Liyanage ADD 2010 06 23 ----- 
-- 22-10-2008 Vinay Techm add Error condition for record not having Vlan IDs Start
--         CLOSE c_vlan_query;
           IF l_home_vlan_id IS NULL AND l_office_vlan_id IS NULL AND l_entree_vlan_id IS NULL AND l_IPTV_vlan_id IS NULL AND l_Xcite_vlan_id IS NULL AND l_Xcel_vlan_id IS NULL AND l_officeplus_vlan_id IS NULL AND l_Xciteplus_vlan_id IS NULL AND l_Xcelplus_vlan_id IS NULL   AND l_Homeplus_vlan_id  IS NULL  THEN--------------- Jayan Liyanage 2009 02 13 ----- --------------- Jayan Liyanage ADD 2010 06 23 ----- ---- Samankula Owitipana ADD 2011 08 10 -----
             CLOSE c_vlan_query;
              RAISE e_no_vlan_data_found;
           ELSE
              CLOSE c_vlan_query;
           END IF;
-- 22-10-2008 Vinay Techm add Error condition for record not having Vlan IDs End

         OPEN c_port_id(v_seit_id);-- Vinay TechM 15-Sep-2008
         FETCH c_port_id INTO l_port_id;
         CLOSE c_port_id;

         OPEN c_port_name(v_seit_id);-- Vinay TechM 15-Sep-2008
         FETCH c_port_name INTO l_port_name;
         CLOSE c_port_name;


    IF l_port_name IS NULL THEN
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_HOME_VLANID', l_home_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_OFFICE_VLANID', l_office_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_ENTREE_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_IPTV_VLANID', l_IPTV_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        --------------- Jayan Liyanage ADD 2009 02 13 -----
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_XCITE_VLANID', l_Xcite_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_XCEL_VLANID', l_Xcel_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        --------------- Jayan Liyanage ADD 2009 02 13 -----
        
        --------------- Jayan Liyanage ADD 2010 06 23 -----
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_OFFICEPLUS_VLANID', l_officeplus_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_XCITEPLUS_VLANID', l_Xciteplus_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_XCELPLUS_VLANID', l_Xcelplus_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        --------------- Jayan Liyanage ADD 2010 06 23 -----
        
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_HOMEPLUS_VLANID', l_Homeplus_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        
		---- Samankula Owitipana ADD 2011 08 10 -----
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBSURFERPLUS_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBPROPLUS_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBMASTERPLUS_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBMATE_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBSURFER_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBPRO_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBMASTER_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		
		---- Samankula Owitipana ADD 2011 12 30 -----
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBPAL_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBFAMILY_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBCHAMP_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBLIFE_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_WEBSTARTER_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_GMOAADMIN_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_GMOACONSULTANT_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
        INSERT INTO port_detail_instance VALUES (l_port_id, 'PA_DSLAM_GMOAMEDICAL_VLANID', l_entree_vlan_id, 'OPTIONAL', 'ENGINEER', '', 'NONE', podi_id_seq.nextval);
		
        
  p_ret_char := 'OK';
  p_ret_msg := NULL;

  p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); -- Vinay TechM 25-5-07
    ELSE
        UPDATE port_detail_instance SET PODI_VALUE = l_home_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_HOME_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_office_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_OFFICE_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_ENTREE_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_IPTV_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_IPTV_VLANID';
        --------------- Jayan Liyanage ADD 2009 02 13 -----
        UPDATE port_detail_instance SET PODI_VALUE = l_Xcite_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_XCITE_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_Xcel_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_XCEL_VLANID';
        --------------- Jayan Liyanage ADD 2009 02 13 -----
        
        --------------- Jayan Liyanage ADD 2010 06 23 -----
        UPDATE port_detail_instance SET PODI_VALUE = l_officeplus_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_OFFICEPLUS_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_Xciteplus_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_XCITEPLUS_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_Xcelplus_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_XCELPLUS_VLANID';
        --------------- Jayan Liyanage ADD 2010 06 23 -----
        
        UPDATE port_detail_instance SET PODI_VALUE = l_Homeplus_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_HOMEPLUS_VLANID';
		
		---- Samankula Owitipana ADD 2011 08 10 -----
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBSURFERPLUS_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBPROPLUS_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBMASTERPLUS_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBMATE_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBSURFER_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBPRO_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBMASTER_VLANID';
		
		---- Samankula Owitipana ADD 2011 12 30 -----
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBPAL_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBFAMILY_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBCHAMP_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBLIFE_VLANID';
		UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_WEBSTARTER_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_GMOAADMIN_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_GMOACONSULTANT_VLANID';
        UPDATE port_detail_instance SET PODI_VALUE = l_entree_vlan_id WHERE PODI_PORT_ID = l_port_id AND PODI_NAME = 'PA_DSLAM_GMOAMEDICAL_VLANID';

  p_ret_char := 'OK';
  p_ret_msg := NULL;

  p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); -- Vinay TechM 25-5-07
    END IF;


 EXCEPTION
-- 22-10-2008 Vinay Techm add Error condition for record not having Vlan IDs Start
   WHEN e_no_vlan_data_found THEN
   ----      p_ret_msg  := 'Failed to SET_DSLAM_VLAN_ID. No data for Vlan ID' ;
         p_ret_char := 'OK';
         p_ret_msg := NULL;

  p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); -- Dinesh 01-02-2013
  
-- 22-10-2008 Vinay Techm add Error condition for record not having Vlan IDs End
    WHEN OTHERS THEN
   ----    p_ret_msg  := 'Failed to SET_DSLAM_VLAN_ID. Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM ;
       
       p_ret_char := 'OK';
       p_ret_msg := NULL;

  p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); -- Dinesh 01-02-2013
  
END SLT_SET_DSLAM_VLAN_ID;

-- 16-Sep-2008 Vinay Techm/Jayan Liyanage
-- Edited on 02-01-2012



-- 20-09-2008 Samankula Owitipana

PROCEDURE SLT_CDMA_IDENTIFY_FACILITIES (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR area_select_cur  IS
SELECT SO.SERO_AREA_CODE FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;

v_AREA_CODE VARCHAR2(5);
v_LOCN_ID NUMBER := NULL;

BEGIN

OPEN area_select_cur;
FETCH area_select_cur INTO v_AREA_CODE;
CLOSE area_select_cur;


SELECT LO.LOCN_ID
INTO v_LOCN_ID
FROM LOCATIONS LO
WHERE LO.LOCN_TTNAME = v_AREA_CODE || '-NODE';




    IF v_LOCN_ID = NULL THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , 'Failed to do identify facility. Please check the SO EXCHANGE_CODE:' || v_AREA_CODE);

    ELSE


    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_LOCN_ID_AEND = v_LOCN_ID, SO.SERO_LOCN_ID_BEND = v_LOCN_ID
    WHERE SO.SERO_ID = p_sero_id;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    END IF;


EXCEPTION
WHEN OTHERS THEN
      p_ret_msg  := 'Failed to do identify facility. Please check the SO EXCHANGE_CODE:' || v_AREA_CODE || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg );

END SLT_CDMA_IDENTIFY_FACILITIES;

-- 20-09-2008 Samankula Owitipana



-- 24-09-2008 Samankula Owitipana
-- MODIFY SERVICE
PROCEDURE SLT_RVPN_HIDE_TASK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR val_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NO OF ACCOUNTS';

v_NEW_VAL NUMBER;
v_PRE_VAL NUMBER;

BEGIN

OPEN val_select_cur;
FETCH val_select_cur INTO v_NEW_VAL,v_PRE_VAL;
CLOSE val_select_cur;




    IF  v_NEW_VAL > v_PRE_VAL THEN


    DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND (SIT.SEIT_TASKNAME = 'DELETE USERS' OR SIT.SEIT_TASKNAME = 'COLLECT TOKEN');

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    ELSIF v_PRE_VAL > v_NEW_VAL THEN


       DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND (SIT.SEIT_TASKNAME = 'ADD USERS' OR SIT.SEIT_TASKNAME = 'HAND OVER TOKEN');

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    ELSE

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
        p_ret_msg  := 'Failed to hide tasks. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    END IF;


EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to hide tasks. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END SLT_RVPN_HIDE_TASK;

-- 24-09-2008 Samankula Owitipana



-- 29-09-2008 Samankula Owitipana
-- ADSL Modify Service automatically close Design Circuit Task

PROCEDURE SLT_ADSL_DESIGNCCT_CLOSED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



BEGIN

    UPDATE WORK_ORDER wo
    SET wo.WORO_STAS_ABBREVIATION = 'CLOSED'
    WHERE wo.WORO_SERO_ID = p_sero_id
    AND wo.WORO_TASKNAME = 'DESIGN CIRCUIT';


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to do identify facility. Please check the EXCHANGE_CODE:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END SLT_ADSL_DESIGNCCT_CLOSED;

-- 29-09-2008 Samankula Owitipana


-- 04-10-2008 Samankula Owitipana
-- IPVPN CREATE-UPGRADE
PROCEDURE SLT_IPVPN_ADD_COMMENT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR oldcct_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND (SOA.SEOA_NAME = 'OLD DATA CIRCUIT ID' or SOA.SEOA_NAME = 'OLD CIRCUIT ID')
and soa.SEOA_DEFAULTVALUE is not null;

CURSOR newcct_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DATA CIRCUIT ID';


v_OLDCCT_NO VARCHAR2(10);
v_NEWCCT_NO VARCHAR2(10);
v_STRING VARCHAR2(40);
v_COMMENT VARCHAR2(50);

BEGIN

OPEN oldcct_select_cur;
FETCH oldcct_select_cur INTO v_OLDCCT_NO;
CLOSE oldcct_select_cur;

OPEN newcct_select_cur;
FETCH newcct_select_cur INTO v_NEWCCT_NO;
CLOSE newcct_select_cur;

v_STRING := 'Facility is reserved to ';
v_COMMENT := v_STRING || v_NEWCCT_NO;

UPDATE CIRCUITS CI
SET CI.CIRT_COMMENT = v_COMMENT
WHERE CI.CIRT_DISPLAYNAME = v_OLDCCT_NO
AND CI.CIRT_SERT_ABBREVIATION like 'D-%';


    IF SQL%NOTFOUND THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , 'Fail to add the comment to ' || v_OLDCCT_NO);

    ELSE

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    END IF;


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Fail to add the comment to ' || v_OLDCCT_NO || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END SLT_IPVPN_ADD_COMMENT;

-- 04-10-2008 Samankula Owitipana

-- 16-10-2008 Samankula Owitipana

PROCEDURE SLT_VPLSACCLINK_MEDIACHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR media_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE';

v_MEDIA_OLD VARCHAR2(20);
v_MEDIA_NEW VARCHAR2(20);

BEGIN

OPEN media_select_cur;
FETCH media_select_cur INTO v_MEDIA_NEW,v_MEDIA_OLD;
CLOSE media_select_cur;





    IF (v_MEDIA_OLD = 'COPPER-2W' AND v_MEDIA_NEW = 'COPPER-4W') THEN

    NULL;
    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    ELSIF (v_MEDIA_OLD = 'COPPER-4W' AND v_MEDIA_NEW = 'COPPER-2W') THEN

    NULL;
    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    ELSE

    DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND (SIT.SEIT_TASKNAME = 'WO TO MDF' OR SIT.SEIT_TASKNAME = 'WO TO OSP');

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    END IF;


EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to delete tasks:WO TO MDF and WO TO OSP - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


END SLT_VPLSACCLINK_MEDIACHANGE;

-- 16-10-2008 Samankula Owitipana

-- 20-09-2008 Samankula Owitipana/Buddika
-- CCB CREATE
PROCEDURE SLT_CCB_WG_MAPPING (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR CONTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CONNECTION TYPE';

CURSOR AREA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';

v_CONTYPE_VAL VARCHAR2(8);

v_AREA_VAL VARCHAR2(4);
v_CSU_VAL VARCHAR2(5);

BEGIN

OPEN CONTYPE_select_cur;
FETCH CONTYPE_select_cur INTO v_CONTYPE_VAL;
CLOSE CONTYPE_select_cur;

OPEN AREA_select_cur;
FETCH AREA_select_cur INTO v_AREA_VAL;
CLOSE AREA_select_cur;


      SELECT SUBSTR(ar.area_area_code,3) INTO v_CSU_VAL
      FROM areas ar
      WHERE ar.area_code = v_AREA_VAL;


    IF v_CONTYPE_VAL <> 'PSTN'  THEN


    UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
    SET sit.SEIT_WORG_NAME =  v_CSU_VAL ||'-CSU'
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;


    UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
    SET sit.SEIT_WORG_NAME = 'CEN-CDMA-SW'
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND SIT.SEIT_TASKNAME = 'SOP_PROVISION' ;

    END IF;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to hide tasks. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Check attribute exchange_code ' || v_AREA_VAL);

END SLT_CCB_WG_MAPPING;

-- 20-09-2008 Samankula Owitipana/Buddika

-- 22-10-2008 Samankula Owitipana
--P2P CREATE
PROCEDURE SLT_P2P_WGCH_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PAend_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

CURSOR P2PBend_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';


v_P2PTYPE_VAL VARCHAR2(100);
v_CUSTYPE_VAL VARCHAR2(100);
v_AEND_VAL VARCHAR2(10);
v_BEND_VAL VARCHAR2(10);
v_MIDTYPEA_VAL VARCHAR2(100);
v_MIDTYPEB_VAL VARCHAR2(100);
v_SECAT_VAL VARCHAR2(100);
v_SLA_TYPE_A varchar2(100);
v_SLA_TYPE_B varchar2(100);
v_SLA_PERCENTAGE_A varchar2(100);
v_SLA_PERCENTAGE_B varchar2(100);

BEGIN

OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN P2PAend_select_cur;
FETCH P2PAend_select_cur INTO v_AEND_VAL;
CLOSE P2PAend_select_cur;

OPEN P2PBend_select_cur;
FETCH P2PBend_select_cur INTO v_BEND_VAL;
CLOSE P2PBend_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;



    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;

-----------------------------------------DESIGN CIRCUIT----------------------------------------------
    BEGIN

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CORP-SSU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in DESIGN CIRCUIT. Please check the P2P TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in DESIGN CIRCUIT. Please check the P2P TYPE Attributes: ' || v_P2PTYPE_VAL);

        END;
--------------------------------------------ISSUE INVOICE----------------------------------------------


         BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;

------------------------------------------APPROVE SO-----------------------------------------------------------


 /*        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END; */

------------------------------------------UPDATE CIRCUIT-----------------------------------------------------


         BEGIN

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the P2P TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in UPDATE CIRCUIT. Please check the P2P TYPE Attributes: ' || v_P2PTYPE_VAL);

        END;

--------------------------------------------WO TO A-END MDF------------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO A-END MDF' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO TO A-END MDF. Please check the EXCHANGE_AREA_CODE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in WO TO A-END MDF. Please check the EXCHANGE_AREA_CODE Attributes:' || v_AEND_VAL);

        END;

--------------------------------------------------WO TO B-END MDF-----------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_BEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO B-END MDF' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO TO B-END MDF. Please check the EXCHANGE AREA CODE B END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in WO TO B-END MDF. Please check the EXCHANGE AREA CODE B END Attributes:' || v_BEND_VAL);

        END;

------------------------------------------OSP/DSU INSTALL A----------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'OSP/DSU INSTALL A' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL A. Please check the EXCHANGE_AREA_CODE END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in OSP/DSU INSTALL A. Please check the EXCHANGE_AREA_CODE Attributes:' || v_AEND_VAL);

        END;

-------------------------------------------OSP/DSU INSTALL B----------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_BEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'OSP/DSU INSTALL B' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL B. Please check the EXCHANGE_AREA_CODE B END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in OSP/DSU INSTALL B. Please check the EXCHANGE_AREA_CODE B END Attributes:' || v_BEND_VAL);

        END;

-----------------------------------------------END TO END TEST------------------------------------------------

   BEGIN

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END TO END TEST. Please check the P2P TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END TO END TEST. Please check the P2P TYPE Attributes: ' || v_P2PTYPE_VAL);

        END;


----------------------------------------CONFIRM  W/ CUSTOMER-------------------------------------------------------


   BEGIN

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         END IF;




        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the P2P TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the P2P TYPE Attributes: ' || v_P2PTYPE_VAL);

        END;


--------------------------------------------CONFIRM TEST LINK------------------------------------------------


        /* BEGIN


    IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM TEST LINK. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM TEST LINK. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;
*/


--------------------------------------------INSTALL CPE A END--------------------------------------------------


         BEGIN


         IF v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'INSTALL CPE-A END' ;



         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in INSTALL CPE A. Please check the MEDIA TYPE A END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in INSTALL CPE. Please check the MEDIA TYPE A END Attributes:' || v_AEND_VAL);

        END;

--------------------------------------------INSTALL CPE B END--------------------------------------------------


         BEGIN


         IF v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'INSTALL CPE-B END' ;



         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in INSTALL CPE. Please check the MEDIA TYPE B END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in INSTALL CPE B. Please check the MEDIA TYPE B END Attributes:' || v_AEND_VAL);

        END;



--------------------------------------------------------------------------------------------------------------------

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to Change WGs. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WGs. Please check the Attributes:' );

END SLT_P2P_WGCH_CREATE;

-- 22-10-2008 Samankula Owitipana

-- 22-10-2008 Samankula Owitipana
-- PSTN Modify Feature U to Y

PROCEDURE SLT_PSTN_IDD_U2Y (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

CURSOR IDDTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IDD TYPE';




v_IDDTYPE VARCHAR2(25);
v_NEW VARCHAR2(25);
v_OLD VARCHAR2(25);
v_NEW_SEC VARCHAR2(25);
v_OLD_SEC VARCHAR2(25);
v_FEAID VARCHAR2(25);

BEGIN

OPEN IDDTYPE_select_cur;
FETCH IDDTYPE_select_cur INTO v_IDDTYPE;
CLOSE IDDTYPE_select_cur;




SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE,sof.SOFE_ID
INTO v_NEW,v_OLD,v_FEAID
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_IDD';

SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
INTO v_NEW_SEC,v_OLD_SEC
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_SECRET_CODE';


UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_SOFE_ID = v_FEAID
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IDD TYPE';



      IF (v_IDDTYPE = 'SLT PLUS TO IDD' AND v_NEW_SEC = 'U' AND v_OLD_SEC = 'Y') THEN


        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_defaultvalue = 'Y'
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_SECRET_CODE';

      END IF;

      IF (v_IDDTYPE = 'SLT PLUS TO IDD' AND v_NEW = 'U' AND v_OLD = 'Y') THEN


        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_defaultvalue = 'Y'
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_IDD';

      END IF;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to Set Y. Please check the IDD TYPE:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END SLT_PSTN_IDD_U2Y;

-- 22-10-2008 Samankula Owitipana

-- 22-10-2008 Samankula Owitipana
-- PSTN Modify Feature IDD SOP STATUS SET as Y

PROCEDURE SLT_PSTN_IDDSOP_Y (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

CURSOR IDDTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IDD TYPE';


v_IDDTYPE VARCHAR2(25);
v_NEW VARCHAR2(25);
v_OLD VARCHAR2(25);
v_NEW_SEC VARCHAR2(25);
v_OLD_SEC VARCHAR2(25);

BEGIN

SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
INTO v_NEW,v_OLD
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_IDD';

SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
INTO v_NEW_SEC,v_OLD_SEC
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_SECRET_CODE';

OPEN IDDTYPE_select_cur;
FETCH IDDTYPE_select_cur INTO v_IDDTYPE;
CLOSE IDDTYPE_select_cur;

      IF (v_IDDTYPE = 'SLT PLUS TO IDD' AND v_NEW_SEC = 'Y' AND v_OLD_SEC = 'Y') THEN


        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',
        sof.sofe_provision_time = sysdate
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_SECRET_CODE';

      END IF;

      IF (v_IDDTYPE = 'SLT PLUS TO IDD' AND v_NEW = 'Y' AND v_OLD = 'Y') THEN


        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',
        sof.sofe_provision_time = sysdate
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_IDD';

      END IF;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to Set Y. Please check the IDD TYPE:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END SLT_PSTN_IDDSOP_Y;

-- 22-10-2008 Samankula Owitipana

-- 22-10-2008 Samankula Owitipana
--P2P SUSPEND

PROCEDURE SLT_P2P_WGCH_SUSPEND (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;







v_CUSTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/




------------------------------------------APPROVE SO-----------------------------------------------------------


         BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;

         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

END;



END SLT_P2P_WGCH_SUSPEND;



-- 22-10-2008 Samankula Owitipana
--P2P RESUME

PROCEDURE SLT_P2P_WGCH_RESUME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;







v_CUSTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;



/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/



------------------------------------------APPROVE SO-----------------------------------------------------------


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;


         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;



END SLT_P2P_WGCH_RESUME;


-- 22-10-2008 Samankula Owitipana

-- 22-10-2008 Samankula Owitipana
--P2P DELETE

PROCEDURE SLT_P2P_WGCH_DELETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';


CURSOR P2PAend_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

CURSOR P2PBend_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';


v_CUSTYPE_VAL VARCHAR2(150);
v_P2PTYPE_VAL VARCHAR2(150);
v_SLA_TYPE_A VARCHAR2(150);
v_SLA_TYPE_B VARCHAR2(150);
v_SLA_PERCENTAGE_A VARCHAR2(150);
v_SLA_PERCENTAGE_B VARCHAR2(150);
v_AEND_VAL VARCHAR2(150);
v_BEND_VAL VARCHAR2(150);
v_MIDTYPEA_VAL VARCHAR2(150);
v_MIDTYPEB_VAL VARCHAR2(150);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN P2PAend_select_cur;
FETCH P2PAend_select_cur INTO v_AEND_VAL;
CLOSE P2PAend_select_cur;

OPEN P2PBend_select_cur;
FETCH P2PBend_select_cur INTO v_BEND_VAL;
CLOSE P2PBend_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;


/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;



------------------------------------------APPROVE SO-----------------------------------------------------------


         BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;


        --------------------------------------------WO TO A-END MDF------------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE MDF JUMP-A EN' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO TO A-END MDF. Please check the EXCHANGE_AREA_CODE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in REMOVE MDF JUMP-A EN. Please check the EXCHANGE_AREA_CODE Attributes:' || v_AEND_VAL);

        END;



        ------------------------------------------OSP/DSU INSTALL A----------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-A END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL A. Please check the EXCHANGE_AREA_CODE END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in REMOVE OSP/DSU-A END. Please check the EXCHANGE_AREA_CODE Attributes:' || v_AEND_VAL);

        END;




         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

END SLT_P2P_WGCH_DELETE;




-- 22-10-2008 Samankula Owitipana
--P2P DELETEOR

PROCEDURE SLT_P2P_WGCH_DELETEOR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';


v_CUSTYPE_VAL VARCHAR2(25);
v_P2PTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);

BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;

------------------------------------------APPROVE SO-----------------------------------------------------------


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;


         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;



END SLT_P2P_WGCH_DELETEOR;

-- 22-10-2008 Samankula Owitipana
--P2P MODIFYCPE

PROCEDURE SLT_P2P_WGCH_MODIFYCPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_P2PTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);

BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;


/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;




------------------------------------------MODIFY PRICE PLAN-------------------------------


        BEGIN


     IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

     ELSE

     UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;


------------------------------------------APPROVE SO-----------------------------------------------------------

      /*   IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF; */


         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg );

        END;



END SLT_P2P_WGCH_MODIFYCPE;


-- 22-10-2008 Samankula Owitipana
--P2P MODIFYSPEED

PROCEDURE SLT_P2P_WGCH_MODIFYSPEED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR DSUA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSU TYPE A END';

CURSOR DSUB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSU TYPE B END';

CURSOR CPEA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS A END';

CURSOR CPEB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS B END';

v_P2PTYPE_VAL VARCHAR2(50);
v_CUSTYPE_VAL VARCHAR2(50);
v_MIDTYPEA_VAL VARCHAR2(50);
v_MIDTYPEB_VAL VARCHAR2(50);
v_DSUA_VAL VARCHAR2(50);
v_DSUB_VAL VARCHAR2(50);
v_DSUAold_VAL VARCHAR2(50);
v_DSUBold_VAL VARCHAR2(50);
v_CPEA_VAL VARCHAR2(50);
v_CPEB_VAL VARCHAR2(50);
v_SLA_TYPE_A varchar2(50);
v_SLA_TYPE_B varchar2(50);
v_SLA_PERCENTAGE_A varchar2(50);
v_SLA_PERCENTAGE_B varchar2(50);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN DSUA_select_cur;
FETCH DSUA_select_cur INTO v_DSUA_VAL,v_DSUAold_VAL;
CLOSE DSUA_select_cur;

OPEN DSUB_select_cur;
FETCH DSUB_select_cur INTO v_DSUB_VAL,v_DSUBold_VAL;
CLOSE DSUB_select_cur;

OPEN CPEA_select_cur;
FETCH CPEA_select_cur INTO v_CPEA_VAL;
CLOSE CPEA_select_cur;

OPEN CPEB_select_cur;
FETCH CPEB_select_cur INTO v_CPEB_VAL;
CLOSE CPEB_select_cur;


/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;
------------------------------------------MODIFY PRICE PLAN-------------------------------



         BEGIN

    IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

     ELSE

     UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;

------------------------------------------APPROVE SO-----------------------------------------------------------


      /*   IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF; */

----------------------------CONFIRM TEST LINK----------------------------------



         IF v_CUSTYPE_VAL = 'CORPORATE-WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WSALES-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-LARGE & VERY LARGE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;
-------------------------CONFIRM  W/ CUSTOMER----------------------------------

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         END IF;

----------------------------ODIFY MDF JUMPER A---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUA_VAL <> v_DSUAold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ODIFY MDF JUMPER A' ;


         END IF;

----------------------------ODIFY MDF JUMPER B---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUB_VAL <> v_DSUBold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY MDF JUMPER B' ;


         END IF;

----------------------------MODIFY DSU - A END--------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUA_VAL <> v_DSUAold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DSU - A END' ;


         END IF;

----------------------------MODIFY DSU - B END---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUB_VAL <> v_DSUBold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DSU - B END' ;


         END IF;

----------------------------MODIFY CPE A END--------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_CPEA_VAL = 'SLT' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY CPE A END' ;


         END IF;

----------------------------MODIFY CPE B END---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_CPEB_VAL = 'SLT' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY CPE B END' ;


         END IF;

         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg );

        END;



END SLT_P2P_WGCH_MODIFYSPEED;


PROCEDURE SLT_P2P_WGCH_MODIFYEQUIP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR DSUA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSU TYPE A END';

CURSOR DSUB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSU TYPE B END';

CURSOR CPEA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS A END';

CURSOR CPEB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS B END';

v_P2PTYPE_VAL VARCHAR2(25);
v_CUSTYPE_VAL VARCHAR2(25);
v_MIDTYPEA_VAL VARCHAR2(25);
v_MIDTYPEB_VAL VARCHAR2(25);
v_DSUA_VAL VARCHAR2(25);
v_DSUB_VAL VARCHAR2(25);
v_DSUAold_VAL VARCHAR2(25);
v_DSUBold_VAL VARCHAR2(25);
v_CPEA_VAL VARCHAR2(25);
v_CPEB_VAL VARCHAR2(25);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);

BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN DSUA_select_cur;
FETCH DSUA_select_cur INTO v_DSUA_VAL,v_DSUAold_VAL;
CLOSE DSUA_select_cur;

OPEN DSUB_select_cur;
FETCH DSUB_select_cur INTO v_DSUB_VAL,v_DSUBold_VAL;
CLOSE DSUB_select_cur;

OPEN CPEA_select_cur;
FETCH CPEA_select_cur INTO v_CPEA_VAL;
CLOSE CPEA_select_cur;

OPEN CPEB_select_cur;
FETCH CPEB_select_cur INTO v_CPEB_VAL;
CLOSE CPEB_select_cur;

/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/


    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;

------------------------------------------MODIFY PRICE PLAN-------------------------------



         BEGIN

     IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

     ELSE

     UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;


------------------------------------------APPROVE SO-----------------------------------------------------------


       /*  IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF; */

----------------------------ODIFY MDF JUMPER A---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUA_VAL <> v_DSUAold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY MDF JUMPER A' ;


         END IF;

----------------------------ODIFY MDF JUMPER B---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUB_VAL <> v_DSUBold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY MDF JUMPER B' ;


         END IF;

----------------------------MODIFY DSU - A END--------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUA_VAL <> v_DSUAold_VAL THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DSU - A END' ;


         END IF;

----------------------------MODIFY DSU - B END---------------------------------

         IF (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL) AND v_DSUB_VAL <> v_DSUBold_VAL THEN

          NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DSU - B END' ;


         END IF;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg );

        END;



END SLT_P2P_WGCH_MODIFYEQUIP;

-- 31-10-2008 Samankula Owitipana
-- P2P MODIFY LOCATION
-- Modified 19_02_2014

PROCEDURE SLT_P2P_WGCH_MODIFYLOC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR AEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

CURSOR BEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';

CURSOR NewAEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NEW LEA AREA';

CURSOR CPEA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS A END';

CURSOR CPEB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS B END';

v_P2PTYPE_VAL VARCHAR2(25);
v_CUSTYPE_VAL VARCHAR2(50);
v_MIDTYPEA_VAL VARCHAR2(25);
v_MIDTYPEB_VAL VARCHAR2(25);
v_AEND_VAL VARCHAR2(25);
v_BEND_VAL VARCHAR2(25);
v_AENDold_VAL VARCHAR2(25);
v_BENDold_VAL VARCHAR2(25);
v_CPEA_VAL VARCHAR2(25);
v_CPEB_VAL VARCHAR2(25);
v_RTOM_VAL VARCHAR2(5);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_RELOC_END varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);

BEGIN

SELECT soa.SEOA_DEFAULTVALUE into v_RELOC_END
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RELOCATED END';


OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN AEND_select_cur;
FETCH AEND_select_cur INTO v_AEND_VAL;
CLOSE AEND_select_cur;

OPEN BEND_select_cur;
FETCH BEND_select_cur INTO v_BEND_VAL;
CLOSE BEND_select_cur;

OPEN NewAEND_select_cur;
FETCH NewAEND_select_cur INTO v_AENDold_VAL;
CLOSE NewAEND_select_cur;

OPEN NewAEND_select_cur;
FETCH NewAEND_select_cur INTO v_BENDold_VAL;
CLOSE NewAEND_select_cur;

OPEN CPEA_select_cur;
FETCH CPEA_select_cur INTO v_CPEA_VAL;
CLOSE CPEA_select_cur;

OPEN CPEB_select_cur;
FETCH CPEB_select_cur INTO v_CPEB_VAL;
CLOSE CPEB_select_cur;


/*SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;*/

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;


--------------------------------------------WO TO A-END MDF------------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF  v_RELOC_END = 'A END' and (v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO A-END MDF' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO TO A-END MDF. Please check the RELOCATED END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in WO TO A-END MDF. Please check the RELOCATED END Attributes:' || v_RELOC_END);

        END;

------------------------------------------OSP/DSU INSTALL A----------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' and (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'OSP/DSU INSTALL A' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || v_RELOC_END);

        END;


------------------------------------------REMOVE OSP/DSU-A END---------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' and (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-A END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || v_RELOC_END);

        END;


------------------------------------------APPROVE SO-----------------------------------------------------------


    /*     IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF; */



-------------------------CONFIRM  W/ CUSTOMER----------------------------------

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         END IF;




        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg );





END SLT_P2P_WGCH_MODIFYLOC;

-- 31-10-2008 Samankula Owitipana

-- 31-10-2008 Samankula Owitipana

PROCEDURE SLT_P2P_WGCH_CREATEOR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';


CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR AEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

CURSOR BEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';

CURSOR NewAEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NEW LEA AREA';

CURSOR CPEA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS A END';

CURSOR CPEB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS B END';

v_P2PTYPE_VAL VARCHAR2(25);
v_CUSTYPE_VAL VARCHAR2(25);
v_MIDTYPEA_VAL VARCHAR2(25);
v_MIDTYPEB_VAL VARCHAR2(25);
v_AEND_VAL VARCHAR2(25);
v_BEND_VAL VARCHAR2(25);
v_AENDold_VAL VARCHAR2(25);
v_BENDold_VAL VARCHAR2(25);
v_CPEA_VAL VARCHAR2(25);
v_CPEB_VAL VARCHAR2(25);
v_RTOM_VAL VARCHAR2(5);
v_SLA_TYPE_A varchar2(20);
v_SLA_TYPE_B varchar2(20);
v_RELOC_END varchar2(20);
v_SLA_PERCENTAGE_A varchar2(20);
v_SLA_PERCENTAGE_B varchar2(20);

BEGIN

SELECT soa.SEOA_DEFAULTVALUE into v_RELOC_END
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RELOCATED END';



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_P2PTYPE_VAL;
CLOSE P2PTYPE_select_cur;

OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN AEND_select_cur;
FETCH AEND_select_cur INTO v_AEND_VAL;
CLOSE AEND_select_cur;

OPEN BEND_select_cur;
FETCH BEND_select_cur INTO v_BEND_VAL;
CLOSE BEND_select_cur;


OPEN NewAEND_select_cur;
FETCH NewAEND_select_cur INTO v_AENDold_VAL;
CLOSE NewAEND_select_cur;

OPEN NewAEND_select_cur;
FETCH NewAEND_select_cur INTO v_BENDold_VAL;
CLOSE NewAEND_select_cur;


OPEN CPEA_select_cur;
FETCH CPEA_select_cur INTO v_CPEA_VAL;
CLOSE CPEA_select_cur;

OPEN CPEB_select_cur;
FETCH CPEB_select_cur INTO v_CPEB_VAL;
CLOSE CPEB_select_cur;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_B
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_PERCENTAGE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_TYPE_A
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_A
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE A END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_TYPE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA_TYPE B END' ;

UPDATE service_order_attributes soa
set SOA.SEOA_DEFAULTVALUE = v_SLA_PERCENTAGE_B
WHERE soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SLA PERCENTAGE B END' ;

    IF v_P2PTYPE_VAL = 'CHANNELIZED-MAIN' OR v_P2PTYPE_VAL = 'CHANNELIZED-SUB' THEN

    UPDATE SERVICE_ORDERS SO
    SET SO.SERO_ADDE_ID_AEND = NULL
    WHERE SO.SERO_ID = p_sero_id;

    END IF;



------------------------------MODIFY CIRCUIT--------------------------------------------------------

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CORP-SSU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY CIRCUIT' ;

         END IF;


------------------------------------------APPROVE SO-----------------------------------------------------------


   /*      IF v_CUSTYPE_VAL = 'WHOLESALE  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WHOSALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF; */
----------------------------------UPDATE CIRCUIT------------------------------------------

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         END IF;


--------------------------------------------WO TO A-END MDF------------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF  v_RELOC_END = 'A END' and (v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO A-END MDF' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO TO A-END MDF. Please check the RELOCATED END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in WO TO A-END MDF. Please check the RELOCATED END Attributes:' || v_RELOC_END);

        END;

------------------------------------------OSP/DSU INSTALL A----------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' and (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'OSP/DSU INSTALL A' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in OSP/DSU INSTALL A. Please check the RELOCATED END Attributes:' || v_RELOC_END);

        END;





-------------------------------END TO END TEST------------------------------------


         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         END IF;


-------------------------CONFIRM  W/ CUSTOMER----------------------------------

         IF v_P2PTYPE_VAL = 'TX- LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         END IF;


--------------------------------ISSUE DELETE-OR SO-----------------------------------------------


         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         END IF;


        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg );





END SLT_P2P_WGCH_CREATEOR;


-- 11-11-2008 Samankula Owitipana
-- CREATE
PROCEDURE SLT_RVPN_CREATE_CH_WG (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




v_CUSTYPE_VAL VARCHAR2(25);


BEGIN


SELECT cu.cusr_cutp_type into v_CUSTYPE_VAL FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

         IF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'HAND OVER TOKEN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'HAND OVER TOKEN' ;

         end if;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to hide tasks. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END SLT_RVPN_CREATE_CH_WG;

-- 11-11-2008 Samankula Owitipana

-- 12-11-2008 Samankula Owitipana
PROCEDURE SLT_P2P_LOCADD_CH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




v_ADD_ID VARCHAR2(25);
v_RELOC_END VARCHAR2(25);
v_ORD_TYPE VARCHAR2(25);
v_CCT_ID VARCHAR2(25);


BEGIN

SELECT soa.SEOA_DEFAULTVALUE into v_RELOC_END
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RELOCATED END';

SELECT so.SERO_ORDT_TYPE into v_ORD_TYPE
FROM SERVICE_ORDERS so
WHERE so.SERO_ID = p_sero_id;


     IF v_RELOC_END = 'A END' and v_ORD_TYPE = 'MODIFY-LOCATION'  then

     SELECT  max(sa.SADD_ADDE_ID) into v_ADD_ID FROM SERVICES_ADDRESS sa
     WHERE sa.SADD_SERV_ID = p_serv_id
     AND sa.SADD_TYPE = 'BEND';

     update SERVICE_ORDERS so
     set so.SERO_ADDE_ID_BEND = v_ADD_ID
     where so.SERO_ID = p_sero_id;

     ELSIF v_RELOC_END = 'B END' and v_ORD_TYPE = 'MODIFY-LOCATION'  then

     SELECT  max(sa.SADD_ADDE_ID) into v_ADD_ID FROM SERVICES_ADDRESS sa
     WHERE sa.SADD_SERV_ID = p_serv_id
     AND sa.SADD_TYPE = 'AEND';

     update SERVICE_ORDERS so
     set so.SERO_ADDE_ID_AEND = v_ADD_ID
     where so.SERO_ID = p_sero_id;

     ELSIF v_RELOC_END = 'A END' and v_ORD_TYPE = 'CREATE-OR'  then

     SELECT soa.SEOA_DEFAULTVALUE into v_CCT_ID
     FROM SERVICE_ORDER_ATTRIBUTES soa
     WHERE soa.SEOA_SERO_ID = p_sero_id
     AND soa.SEOA_NAME = 'OLD CIRCUIT ID';

     SELECT  max(sa.SADD_ADDE_ID) into v_ADD_ID FROM SERVICES_ADDRESS sa,circuits ci
     WHERE ci.CIRT_SERV_ID = sa.SADD_SERV_ID
     and ci.CIRT_DISPLAYNAME = v_CCT_ID
     and ci.CIRT_STATUS = 'INSERVICE'
     AND sa.SADD_TYPE = 'BEND';

     update SERVICE_ORDERS so
     set so.SERO_ADDE_ID_BEND = v_ADD_ID
     where so.SERO_ID = p_sero_id;

     ELSIF v_RELOC_END = 'B END' and v_ORD_TYPE = 'CREATE-OR'  then

     SELECT soa.SEOA_DEFAULTVALUE into v_CCT_ID
     FROM SERVICE_ORDER_ATTRIBUTES soa
     WHERE soa.SEOA_SERO_ID = p_sero_id
     AND soa.SEOA_NAME = 'OLD CIRCUIT ID';

     SELECT  max(sa.SADD_ADDE_ID) into v_ADD_ID FROM SERVICES_ADDRESS sa,circuits ci
     WHERE ci.CIRT_SERV_ID = sa.SADD_SERV_ID
     and ci.CIRT_DISPLAYNAME = v_CCT_ID
     and ci.CIRT_STATUS = 'INSERVICE'
     AND sa.SADD_TYPE = 'AEND';

     update SERVICE_ORDERS so
     set so.SERO_ADDE_ID_AEND = v_ADD_ID
     where so.SERO_ID = p_sero_id;

     end if;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to hide tasks. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END SLT_P2P_LOCADD_CH;

-- 12-11-2008 Samankula Owitipana


-- 13-11-2008 Samankula Owitipana
--P2P DELETEOR -Relocation

PROCEDURE SLT_P2P_WGCH_DELETEOR_RELOC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR MIDA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE A END';

CURSOR MIDB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';

CURSOR AEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

CURSOR BEND_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';



CURSOR CPEA_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS A END';

CURSOR CPEB_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE CLASS B END';





v_CUSTYPE_VAL VARCHAR2(25);
v_MIDTYPEA_VAL VARCHAR2(25);
v_MIDTYPEB_VAL VARCHAR2(25);
v_AEND_VAL VARCHAR2(25);
v_BEND_VAL VARCHAR2(25);
v_CPEA_VAL VARCHAR2(25);
v_CPEB_VAL VARCHAR2(25);
v_RELOC_END VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN MIDA_select_cur;
FETCH MIDA_select_cur INTO v_MIDTYPEA_VAL;
CLOSE MIDA_select_cur;

OPEN MIDB_select_cur;
FETCH MIDB_select_cur INTO v_MIDTYPEB_VAL;
CLOSE MIDB_select_cur;

OPEN AEND_select_cur;
FETCH AEND_select_cur INTO v_AEND_VAL;
CLOSE AEND_select_cur;

OPEN BEND_select_cur;
FETCH BEND_select_cur INTO v_BEND_VAL;
CLOSE BEND_select_cur;



OPEN CPEA_select_cur;
FETCH CPEA_select_cur INTO v_CPEA_VAL;
CLOSE CPEA_select_cur;

OPEN CPEB_select_cur;
FETCH CPEB_select_cur INTO v_CPEB_VAL;
CLOSE CPEB_select_cur;

SELECT soa.SEOA_DEFAULTVALUE INTO v_RELOC_END
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RELOCATED END';


--------------------------------------------REMOVE MDF JUMP-A EN------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' AND (v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE MDF JUMP-A EN' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE MDF JUMP-A EN' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG REMOVE MDF JUMP-A EN:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          ,p_ret_msg);

        END;

-----------------------------------------------REMOVE MDF JUMP-B EN--------------------------------------------------

         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_RELOC_END = 'B END' AND (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' ||trim(v_BEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE MDF JUMP-B EN' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE MDF JUMP-B EN' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG REMOVE MDF JUMP-B EN ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

------------------------------------------REMOVE OSP/DSU-A END---------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' AND (v_MIDTYPEA_VAL <> 'FIBER' OR v_MIDTYPEA_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-A END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-A END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG REMOVE OSP/DSU-A END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

------------------------------------------REMOVE OSP/DSU-B END-------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_RELOC_END = 'B END' AND (v_MIDTYPEB_VAL <> 'FIBER' OR v_MIDTYPEB_VAL IS NOT NULL)  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_BEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-B END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE OSP/DSU-B END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG REMOVE OSP/DSU-B END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

------------------------------------------COLLECT RADIO-A END---------------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' AND v_MIDTYPEA_VAL = 'RADIO'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'RADIO LAB'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT RADIO-A END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT RADIO-A END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG COLLECT RADIO-A END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

-----------------------------------------COLLECT RADIO-B END-----------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_RELOC_END = 'B END' AND v_MIDTYPEB_VAL = 'RADIO'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'RADIO LAB'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT RADIO-B END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT RADIO-B END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG COLLECT RADIO-B END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

------------------------------------------UNINSTALL LINK A-END---------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' AND v_MIDTYPEA_VAL = 'RADIO'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CORP-SSU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UNINSTALL LINK A-END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UNINSTALL LINK A-END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG UNINSTALL LINK A-END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

-----------------------------------------UNINSTALL LINK B-END---------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_RELOC_END = 'B END' AND v_MIDTYPEB_VAL = 'RADIO'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CORP-SSU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UNINSTALL LINK B-END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UNINSTALL LINK B-END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG UNINSTALL LINK B-END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

-----------------------------------------COLLECT ROUTER-A END--------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;

         IF v_RELOC_END = 'A END' AND v_CPEA_VAL = 'SLT'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT ROUTER-A END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT ROUTER-A END' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG COLLECT ROUTER-A END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

----------------------------------------COLLECT ROUTER-B END-------------------------------------------



         DECLARE

         v_RTOM_VAL VARCHAR2(5);

         BEGIN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_BEND_VAL;

         IF v_RELOC_END = 'B END' AND v_CPEB_VAL = 'SLT'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT ROUTER-B END' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT ROUTER-B END' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG COLLECT ROUTER-B END' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

END SLT_P2P_WGCH_DELETEOR_RELOC;

-- 13-11-2008 Samankula Owitipana



-- 17-11-2008 Samankula Owitipana
PROCEDURE SLT_P2P_SERVICECAT_CH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_SERVICE_CAT VARCHAR(30);

BEGIN

SELECT soa.SEOA_DEFAULTVALUE
INTO v_SERVICE_CAT
FROM service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'SERVICE CATEGORY' ;

    IF v_SERVICE_CAT = 'TEST' THEN

    UPDATE service_order_attributes soa
    SET soa.SEOA_DEFAULTVALUE = 'PERMANENT'
    where soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'SERVICE CATEGORY' ;

    END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN


    p_ret_msg  := 'Failed to change the SERVICE CATEGORY' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END SLT_P2P_SERVICECAT_CH;
-- 17-11-2008 Samankula Owitipana



-- 03-12-2008 Samankula Owitipana
-- CCB OTHER SOP_PROVISION Only
PROCEDURE SLT_CCB_WG_CH_OTHER (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR CONTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CONNECTION TYPE';

v_CONTYPE_VAL VARCHAR2(8);


BEGIN

OPEN CONTYPE_select_cur;
FETCH CONTYPE_select_cur INTO v_CONTYPE_VAL;
CLOSE CONTYPE_select_cur;




    IF v_CONTYPE_VAL <> 'PSTN'  THEN


    UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
    SET sit.SEIT_WORG_NAME = 'CEN-CDMA-SW'
    WHERE SIT.SEIT_SERO_ID =  p_sero_id
    AND SIT.SEIT_TASKNAME = 'SOP_PROVISION' ;



    END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to Change WorkGroup. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'CONNECTION TYPE ' || v_CONTYPE_VAL);

END SLT_CCB_WG_CH_OTHER;


-- 03-12-2008 Samankula Owitipana



-- 10-12-2008 Edward Son
PROCEDURE CHECK_ADSL_ADD_TASK_COMPLETION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

    CURSOR c_service_order IS
      SELECT *
      FROM   service_orders
      WHERE  sero_id = p_sero_id;

    r_service_order     c_service_order%ROWTYPE;
    v_isvalid             VARCHAR(1);
BEGIN
    v_isvalid := 'N';

    SELECT /*+ INDEX(service_order_attributes SEOA_SERO_FK_IDX) */ 'Y' INTO v_isvalid FROM SERVICE_ORDER_ATTRIBUTES WHERE SEOA_SERO_ID = p_sero_id
    AND SEOA_NAME = 'ADSL_NE_TYPE' AND SEOA_DEFAULTVALUE IN ('DSLAM-HUAWEI','NGN-MSAN');

    IF v_isvalid = 'Y' THEN
       v_isvalid := 'N';

       OPEN c_service_order;
       FETCH c_service_order INTO r_service_order;
       CLOSE c_service_order;

       IF r_service_order.SERO_ORDT_TYPE = 'CREATE' or r_service_order.SERO_ORDT_TYPE = 'CREATE-OR' THEN
             SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
             AND SOFE_FEATURE_NAME = 'INTERNET' AND SOFE_DEFAULTVALUE = 'Y';
       ELSIF r_service_order.SERO_ORDT_TYPE = 'MODIFY-SERVICE' THEN
          SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
          AND SOFE_FEATURE_NAME = 'INTERNET' AND SOFE_DEFAULTVALUE = 'Y' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');
       END IF;
    END IF;

    IF v_isvalid = 'Y' THEN
        p_ret_msg := '';
    ELSE
        p_ret_msg := 'FALSE';
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END CHECK_ADSL_ADD_TASK_COMPLETION;
-- 10-12-2008 Edward Son

-- 10-12-2008 Edward Son
PROCEDURE CHECK_ADSL_DEL_TASK_COMPLETION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      v_isvalid             VARCHAR(1);
BEGIN
    v_isvalid := 'N';

    SELECT /*+ INDEX(service_order_attributes SEOA_SERO_FK_IDX) */ 'Y' INTO v_isvalid FROM SERVICE_ORDER_ATTRIBUTES WHERE SEOA_SERO_ID = p_sero_id
    AND SEOA_NAME = 'ADSL_NE_TYPE' AND SEOA_DEFAULTVALUE IN ('DSLAM-HUAWEI','NGN-MSAN');

    IF v_isvalid = 'Y' THEN
       v_isvalid := 'N';
       SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
       AND SOFE_FEATURE_NAME = 'INTERNET' AND SOFE_DEFAULTVALUE = 'N' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'Y');
    END IF;

    IF v_isvalid = 'Y' THEN
        p_ret_msg := '';
    ELSE
        p_ret_msg := 'FALSE';
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END CHECK_ADSL_DEL_TASK_COMPLETION;
-- 10-12-2008 Edward Son

-- 10-12-2008 Edward Son
PROCEDURE CHECK_IPTV_ADD_TASK_COMPLETION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

    CURSOR c_service_order IS
      SELECT *
      FROM   service_orders
      WHERE  sero_id = p_sero_id;

    r_service_order     c_service_order%ROWTYPE;
    v_isvalid             VARCHAR(1);
BEGIN
    v_isvalid := 'N';

    SELECT /*+ INDEX(service_order_attributes SEOA_SERO_FK_IDX) */ 'Y' INTO v_isvalid FROM SERVICE_ORDER_ATTRIBUTES WHERE SEOA_SERO_ID = p_sero_id
    AND SEOA_NAME = 'ADSL_NE_TYPE' AND SEOA_DEFAULTVALUE IN ('DSLAM-HUAWEI','NGN-MSAN');

    IF v_isvalid = 'Y' THEN
       v_isvalid := 'N';

       OPEN c_service_order;
       FETCH c_service_order INTO r_service_order;
       CLOSE c_service_order;

       IF r_service_order.SERO_ORDT_TYPE = 'CREATE' or r_service_order.SERO_ORDT_TYPE = 'CREATE-OR' THEN
          SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
          AND SOFE_FEATURE_NAME = 'IPTV' AND SOFE_DEFAULTVALUE = 'Y';
       ELSIF r_service_order.SERO_ORDT_TYPE = 'MODIFY-SERVICE' THEN
          SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
          AND SOFE_FEATURE_NAME = 'IPTV' AND SOFE_DEFAULTVALUE = 'Y' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');
       END IF;
    END IF;

    IF v_isvalid = 'Y' THEN
        p_ret_msg := '';
    ELSE
        p_ret_msg := 'FALSE';
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END CHECK_IPTV_ADD_TASK_COMPLETION;
-- 10-12-2008 Edward Son

-- 10-12-2008 Edward Son
PROCEDURE CHECK_IPTV_DEL_TASK_COMPLETION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      v_isvalid             VARCHAR(1);
BEGIN
    v_isvalid := 'N';

    SELECT /*+ INDEX(service_order_attributes SEOA_SERO_FK_IDX) */ 'Y' INTO v_isvalid FROM SERVICE_ORDER_ATTRIBUTES WHERE SEOA_SERO_ID = p_sero_id
    AND SEOA_NAME = 'ADSL_NE_TYPE' AND SEOA_DEFAULTVALUE IN ('DSLAM-HUAWEI','NGN-MSAN');

    IF v_isvalid = 'Y' THEN
       v_isvalid := 'N';
       SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
       AND SOFE_FEATURE_NAME = 'IPTV' AND SOFE_DEFAULTVALUE = 'N' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'Y');
       
    END IF;

    IF v_isvalid = 'Y' THEN
        p_ret_msg := '';
    ELSE
        p_ret_msg := 'FALSE';
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END CHECK_IPTV_DEL_TASK_COMPLETION;
-- 10-12-2008 Edward Son

-- 19-12-2008 Samankula Owitipana
-- ADSL PSTN CREATE  APPROVE SO parallel Completion rule

PROCEDURE ADSL_PARALLEL_CUSCONF_COMPRULE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_CCT_ID VARCHAR2(25);
v_SO_ID VARCHAR2(25);

BEGIN

p_ret_msg := '';

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_PSTN_NO
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

SELECT ci.CIRT_NAME
INTO v_CCT_ID
FROM CIRCUITS ci
WHERE ci.CIRT_DISPLAYNAME like trim(v_PSTN_NO) || '%(N)%'
and (ci.CIRT_STATUS <> 'PENDINGDELETE' and ci.CIRT_STATUS <>'CANCELLED');

SELECT SO.SERO_ID
INTO v_SO_ID
FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
AND SO.SERO_CIRT_NAME = v_CCT_ID
AND SIT.SEIT_TASKNAME = 'CUTOMER CONFIRMATION'
AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED'
OR SIT.SEIT_STAS_ABBREVIATION = 'INPROGRESS');

  IF v_SO_ID is not null THEN
      p_ret_msg := 'PSTN SERVICE ORDER STILL INPROGRESS:' || v_SO_ID;
  ELSE
      p_ret_msg := '';
  END IF;

EXCEPTION
  WHEN no_data_found  THEN
    p_ret_msg := '';
END ADSL_PARALLEL_CUSCONF_COMPRULE;
-- 19-12-2008 Samankula Owitipana



-- 05-01-2009 Samankula Owitipana
--Insert customer contact no in to SO

PROCEDURE SLT_CUS_CONTACT_NO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR tp_select_cur  IS
SELECT SO.SERO_CUSR_ABBREVIATION FROM SERVICE_ORDERs SO
WHERE SO.SERO_ID = p_sero_id;

CURSOR tp_acc_cur  IS
SELECT SO.SERO_ACCT_NUMBER FROM SERVICE_ORDERs SO
WHERE SO.SERO_ID = p_sero_id;

v_CR_NO VARCHAR2(20);
v_AC_NO VARCHAR2(20);
v_CUS_TYEP VARCHAR2(50);


v_CUS_TPAM VARCHAR2(30);
v_CUS_TPPM VARCHAR2(30);
v_CUS_TPM VARCHAR2(30);
v_CUS_TP VARCHAR2(33);

v_CUS_TPAM_AC VARCHAR2(30);
v_CUS_TPPM_AC VARCHAR2(30);
v_CUS_TPM_AC VARCHAR2(30);
v_CUS_TP_AC VARCHAR2(33);

BEGIN

OPEN tp_select_cur;
FETCH tp_select_cur INTO v_CR_NO;
CLOSE tp_select_cur;

OPEN tp_acc_cur;
FETCH tp_acc_cur INTO v_AC_NO;
CLOSE tp_acc_cur;



                              Declare


                              CURSOR tp1_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_CUSR_ABBREVIATION = v_CR_NO
                              AND cp.CONP_HOURS like '%AM'
                              AND cp.CONP_CONT_ABBREVIATION = 'PHONE');

                              CURSOR tp2_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_CUSR_ABBREVIATION = v_CR_NO
                              AND cp.CONP_HOURS like '%PM'
                              AND cp.CONP_CONT_ABBREVIATION = 'PHONE');

                              CURSOR tp3_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_CUSR_ABBREVIATION = v_CR_NO
                              AND cp.CONP_CONT_ABBREVIATION = 'MOBILE');

                              ----------------AC Contact------------------

                              CURSOR tp4_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ACCT_NUMBER = v_AC_NO
                              AND cp.CONP_HOURS like '%AM'
                              AND cp.CONP_CONT_ABBREVIATION = 'PHONE');

                              CURSOR tp5_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ACCT_NUMBER = v_AC_NO
                              AND cp.CONP_HOURS like '%PM'
                              AND cp.CONP_CONT_ABBREVIATION = 'PHONE');

                              CURSOR tp6_select_cur  IS
                              SELECT substr(trim(cp.CONP_NUMBER),1,10)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ID in
                              (SELECT max(cp.CONP_ID)
                              FROM CONTACT_POINTS cp
                              WHERE cp.CONP_ACCT_NUMBER = v_AC_NO
                              AND cp.CONP_CONT_ABBREVIATION = 'MOBILE');


                              CURSOR cus_type_cur  IS
                              SELECT cu.CUSR_CUTP_TYPE FROM customer cu
                              WHERE cu.CUSR_ABBREVIATION = v_CR_NO;

                              Begin

                              OPEN tp1_select_cur;
                              FETCH tp1_select_cur INTO v_CUS_TPAM;
                              CLOSE tp1_select_cur;

                              OPEN tp2_select_cur;
                              FETCH tp2_select_cur INTO v_CUS_TPPM;
                              CLOSE tp2_select_cur;

                              OPEN tp3_select_cur;
                              FETCH tp3_select_cur INTO v_CUS_TPM;
                              CLOSE tp3_select_cur;
                              ------------------------------------
                              OPEN tp4_select_cur;
                              FETCH tp4_select_cur INTO v_CUS_TPAM_AC;
                              CLOSE tp4_select_cur;

                              OPEN tp5_select_cur;
                              FETCH tp5_select_cur INTO v_CUS_TPPM_AC;
                              CLOSE tp5_select_cur;

                              OPEN tp6_select_cur;
                              FETCH tp6_select_cur INTO v_CUS_TPM_AC;
                              CLOSE tp6_select_cur;

                              OPEN cus_type_cur;
                              FETCH cus_type_cur INTO v_CUS_TYEP;
                              CLOSE cus_type_cur;

                              v_CUS_TP := v_CUS_TPAM || ',' || v_CUS_TPPM || ',' || v_CUS_TPM;

                              v_CUS_TP_AC := v_CUS_TPAM_AC || ',' || v_CUS_TPPM_AC || ',' || v_CUS_TPM_AC;

                              End;


IF  v_CUS_TYEP = 'RESIDENTIAL' then

    IF length(v_CUS_TP) < 4 THEN

    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = 'N/A'
    WHERE soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'CUSTOMER CONTACT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    ELSE


    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = v_CUS_TP
    WHERE soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'CUSTOMER CONTACT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    END IF;

ElSE

IF length(v_CUS_TP) < 4 THEN

    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = 'N/A'
    WHERE soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'CUSTOMER CONTACT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    ELSE


    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = v_CUS_TP_AC
    WHERE soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'CUSTOMER CONTACT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    END IF;

END IF;

EXCEPTION

WHEN NO_DATA_FOUND THEN

    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = 'N/A'
    WHERE soa.SEOA_SERO_ID = p_sero_id
    and soa.SEOA_NAME = 'CUSTOMER CONTACT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

WHEN OTHERS THEN

      p_ret_msg  := 'Failed to insert customer contact no. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

     INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
     SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
     , p_ret_msg);


END SLT_CUS_CONTACT_NO;

-- 05-01-2009 Samankula Owitipana




-- 06-01-2009 Samankula Owitipana
--ADSL Update CCT SET COMMISSION

PROCEDURE SLT_SET_COMMISSION_ADSL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




BEGIN


P_dynamic_procedure.PROCESS_UPDATE_CIRT_commision(
              p_serv_id,
              p_sero_id,
              p_seit_id,
              p_impt_taskname,
              p_woro_id,
              p_ret_char,
              p_ret_number,
              p_ret_msg);


            IF p_ret_msg IS NULL THEN

            p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

            else

            p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

            INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
             SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
             , p_ret_msg);

            end if;

EXCEPTION

WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set as commission:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

     INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
     SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
     , p_ret_msg);


END SLT_SET_COMMISSION_ADSL;

-- 06-01-2009 Samankula Owitipana


-- 08-01-2009 Samankula Owitipana
-- ADSL MODIFY-CPE SET SUPPLEMENTARY WORK COST TO 0

PROCEDURE SLT_ADSL_SET_WORKCOST (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




BEGIN


        UPDATE SERVICE_ORDER_ATTRIBUTES soa
        SET soa.SEOA_DEFAULTVALUE = '0'
        WHERE soa.SEOA_SERO_ID = p_sero_id
        AND soa.SEOA_NAME = 'SUPPLEMENTARY WORK COST';

     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'SET SUPPLEMENTARY WORK COST TO 0 FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);

END SLT_ADSL_SET_WORKCOST;

-- 08-01-2009 Samankula Owitipana


-- 12-01-2009 Samankula Owitipana
-- DIDDOD CREATE SET WG

PROCEDURE SLT_DIDDOD_CREATEWG_CHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DIOD TYPE';

CURSOR so_type_cur IS
SELECT so.SERO_ORDT_TYPE FROM SERVICE_ORDERS SO
WHERE so.SERO_ID = p_sero_id;





v_CUSTYPE_VAL VARCHAR2(50);
v_DIDOTYPE_VAL VARCHAR2(50);
v_DIDOTYPE_PRE_VAL VARCHAR2(50);
v_SERVICECAT_VAL VARCHAR2(50);
v_NOF_PSTN_NEW number;
v_NOF_PSTN_PRE number;
v_NUMB_CHG VARCHAR2(50);
v_SO_TYPE_VAL VARCHAR2(40);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_DIDOTYPE_VAL,v_DIDOTYPE_PRE_VAL;
CLOSE P2PTYPE_select_cur;


OPEN so_type_cur;
FETCH so_type_cur INTO v_SO_TYPE_VAL;
CLOSE so_type_cur;



SELECT soa.SEOA_DEFAULTVALUE
INTO v_SERVICECAT_VAL
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SERVICE CATEGORY' ;


SELECT soa.SEOA_DEFAULTVALUE
INTO v_NOF_PSTN_NEW
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SA_NO_OF_PSTN NUMBERS' ;

SELECT soa.SEOA_PREV_VALUE
INTO v_NOF_PSTN_PRE
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SA_NO_OF_PSTN NUMBERS' ;

SELECT soa.SEOA_DEFAULTVALUE
INTO v_NUMB_CHG
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SA_NUMBER CHANGE' ;





------------------------------------------CONFIRM DIOD NUMBERS---------------------------------------------------------



         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;


         END IF;




--------------------------------------------ISSUE INVOICE----------------------------------------------



         BEGIN

         IF  v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF  v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg || ' ' ||v_CUSTYPE_VAL);

        END;



--------------------------------------------CONFIRM TEST LINK------------------------------------------------


/*         BEGIN

         IF v_SERVICECAT_VAL = 'TEST' and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-WSALES-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_SERVICECAT_VAL = 'TEST' and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_SERVICECAT_VAL = 'TEST' and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM TEST LINK. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM TEST LINK. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;
*/

--------------------------------------------ADD DIOD USAGE CHARGE CREATE----------------------------------------------


         BEGIN

         IF (v_SO_TYPE_VAL = 'CREATE' or v_SO_TYPE_VAL = 'CREATE-OR' ) and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         ELSIF (v_SO_TYPE_VAL = 'CREATE' or v_SO_TYPE_VAL = 'CREATE-OR' ) and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         ELSIF (v_SO_TYPE_VAL = 'CREATE' or v_SO_TYPE_VAL = 'CREATE-OR' ) and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ADD DID-DOD USAGE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in ADD DID-DOD USAGE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;


--------------------------------------------ADD DIOD USAGE CHARGE----------------------------------------------


      /*   BEGIN

         IF v_SO_TYPE_VAL = 'MODIFY-FEATURE' and (v_DIDOTYPE_PRE_VAL ='DID' and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD')) and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-FEATURE' and (v_DIDOTYPE_PRE_VAL ='DID' and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD')) and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-FEATURE' and (v_DIDOTYPE_PRE_VAL ='DID' and (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD')) and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-FEATURE' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ADD DID-DOD USAGE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ADD DID-DOD USAGE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in ADD DID-DOD USAGE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END; */


--------------------------------------------END DIOD USAGE CHARGE----------------------------------------------


         BEGIN

         IF ((v_DIDOTYPE_PRE_VAL = 'DOD' or v_DIDOTYPE_PRE_VAL = 'DIOD') and v_DIDOTYPE_VAL ='DID' ) and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DID-DOD USAGE' ;

         ELSIF ((v_DIDOTYPE_PRE_VAL = 'DOD' or v_DIDOTYPE_PRE_VAL = 'DIOD') and v_DIDOTYPE_VAL ='DID' ) and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DID-DOD USAGE' ;

         ELSIF ((v_DIDOTYPE_PRE_VAL = 'DOD' or v_DIDOTYPE_PRE_VAL = 'DIOD') and v_DIDOTYPE_VAL ='DID' ) and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DID-DOD USAGE' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DID-DOD USAGE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END DID-DOD USAGE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END DID-DOD USAGE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;




    --------------------------------------------ISSUE DELETE-OR SO---------------------------------------------


         BEGIN

         IF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ISSUE DELETE-OR SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in ISSUE DELETE-OR SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;



    --------------------------------------------END DIOD USAGE----------------------------------------------


         BEGIN

         IF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DIOD USAGE' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DIOD USAGE' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DIOD USAGE' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END DIOD USAGE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END DIOD USAGE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END DIOD USAGE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;


------------------------------------------APPROVE SO-----------------------------------------------------------


         BEGIN

         IF (v_SO_TYPE_VAL = 'RESUME' or v_SO_TYPE_VAL = 'SUSPEND' or v_SO_TYPE_VAL = 'DELETE-OR' or v_SO_TYPE_VAL = 'DELETE-DOWNGRADE' or
         v_SO_TYPE_VAL = 'DELETE') AND v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_SO_TYPE_VAL = 'RESUME' or v_SO_TYPE_VAL = 'SUSPEND' or v_SO_TYPE_VAL = 'DELETE-OR' or v_SO_TYPE_VAL = 'DELETE-DOWNGRADE' or
         v_SO_TYPE_VAL = 'DELETE') AND v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_SO_TYPE_VAL = 'RESUME' or v_SO_TYPE_VAL = 'SUSPEND' or v_SO_TYPE_VAL = 'DELETE-OR' or v_SO_TYPE_VAL = 'DELETE-DOWNGRADE' or
         v_SO_TYPE_VAL = 'DELETE') AND v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;





        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;



        /* IF (v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND  v_NUMB_CHG = 'Y') THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RESERVE NUMBER' ;


         END IF;


         IF (v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND   v_NUMB_CHG = 'Y') THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RESERVE NUMBERS' ;


         END IF; */

        IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND nvl(v_NOF_PSTN_NEW,0) > nvl(v_NOF_PSTN_PRE,0)  THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIG DIOD NUMBERS' ;


         END IF;


         IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND nvl(v_NOF_PSTN_NEW,0) < nvl(v_NOF_PSTN_PRE,0)  THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE DIOD NUMBERS' ;


         END IF;



        IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND (nvl(v_NOF_PSTN_NEW,0) > nvl(v_NOF_PSTN_PRE,0) or v_NUMB_CHG = 'Y') THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE MEDIATION' ;


         END IF;


        IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND nvl(v_NOF_PSTN_NEW,0) < nvl(v_NOF_PSTN_PRE,0)  THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DELETE NUMBERS' ;


         END IF;




        IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND (nvl(v_NOF_PSTN_NEW,0) > nvl(v_NOF_PSTN_PRE,0) or v_NUMB_CHG = 'Y') THEN

         NULL;

         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIVATE ROUTES' ;


         END IF;

-------------------------------- CONFIRM DIOD NUMBERS --    MODIFY-NUMBER --------------------------------

        IF v_SO_TYPE_VAL = 'MODIFY-NUMBER' AND nvl(v_NOF_PSTN_NEW,0) >= nvl(v_NOF_PSTN_PRE,0)  THEN


         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;


         END IF;


         ELSIF v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN


         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DIOD NUMBERS' ;



         END IF;



    --------------------------------------------MODIFY DIOD USAGE---------------------------------------------


         BEGIN

         IF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'WHOLESALE' and v_NUMB_CHG = 'Y' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DIOD USAGE' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'CORPORATE' and v_NUMB_CHG = 'Y' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DIOD USAGE' ;

         ELSIF (v_DIDOTYPE_VAL = 'DOD' or v_DIDOTYPE_VAL = 'DIOD') and v_CUSTYPE_VAL = 'SME' and v_NUMB_CHG = 'Y' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DIOD USAGE' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY DIOD USAGE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in MODIFY DIOD USAGE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in MODIFY DIOD USAGE. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;








        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'FAILED SET WORKGROUP' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);

END SLT_DIDDOD_CREATEWG_CHANGE;

-- 12-01-2009 Samankula Owitipana




-- 19-01-2009 Gihan Amarasinghe
PROCEDURE SLT_METER_PULSE_TCOND (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

    CURSOR C_NE_TYPE IS
      SELECT equp_equt_abbreviation
                FROM service_orders,
                     circuits,
                     port_links,
                     port_link_ports,
                     ports,
                     equipment
               WHERE sero_id = p_sero_id
                 AND cirt_name = sero_cirt_name
                 AND porl_cirt_name = cirt_name
                 AND polp_porl_id = porl_id
                 AND polp_commonport = 'F'
                 AND port_id = polp_port_id
                 AND equp_id = port_equp_id;

    v_ne_type     VARCHAR2(25);
    v_isvalid     VARCHAR(1);
BEGIN
    v_isvalid := 'N';

    SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
    AND SOFE_FEATURE_NAME = 'SF_METER_PULSE_P_REV' AND SOFE_DEFAULTVALUE <> SOFE_PREV_VALUE;

    IF v_isvalid = 'Y' THEN
       v_isvalid := 'N';

       OPEN C_NE_TYPE;
       FETCH C_NE_TYPE INTO v_ne_type;
       CLOSE C_NE_TYPE;

       IF v_ne_type = 'NGN-MSAN' THEN
             v_isvalid := 'Y';
       END IF;
    END IF;

    IF v_isvalid = 'Y' THEN
        p_ret_msg := '';
    ELSE
        p_ret_msg := 'FALSE';
    END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END SLT_METER_PULSE_TCOND;
-- 19-01-2009 Gihan Amarasinghe


-- 23-01-2009 Buddika Weerasinghe
-- ADSL_DELETE_SO

PROCEDURE ADSL_DELETE_SO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR c1 IS
SELECT PLP.POLP_PORL_ID,C.CIRT_NAME
FROM CIRCUITS C ,PORT_LINKS PL,PORT_LINK_PORTS PLP,Service_Orders so
WHERE C.CIRT_STATUS ='INSERVICE'
AND C.CIRT_NAME = PL.PORL_CIRT_NAME
AND so.SERO_CIRT_NAME= c.CIRT_NAME
AND so.SERO_ID = p_sero_id
AND PL.PORL_ID = PLP.POLP_PORL_ID;


CURSOR cct_id IS
SELECT ch.CIRH_PARENT
FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND so.SERO_ID = p_sero_id;




v_POLP_PORL_ID PORT_LINK_PORTS.POLP_PORL_ID %TYPE;
v_CIRT_NAME CIRCUITS.CIRT_NAME %TYPE;
v_PSTN VARCHAR2(25);
v_plp_ex VARCHAR2(25);
v_plp_ug VARCHAR2(25);
v_plp_ex_1c VARCHAR2(25);
v_plp_ug_2c VARCHAR2(25);
v_plp_port NUMBER;
v_pl_port NUMBER;
v_pl_test NUMBER;
v_pl_test2 NUMBER;


BEGIN





  OPEN c1;
  LOOP

    EXIT WHEN c1%NOTFOUND;

    FETCH c1
      INTO v_POLP_PORL_ID,v_CIRT_NAME;

    DELETE  PORT_LINK_PORTS
    WHERE   POLP_PORL_ID = v_POLP_PORL_ID;

    DELETE PORT_LINKS
    WHERE PORL_CIRT_NAME = v_CIRT_NAME;



  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Done');
  CLOSE c1;


UPDATE PORTS Po
SET po.PORT_CIRT_NAME = NULL
WHERE po.PORT_CIRT_NAME IN
(SELECT C.CIRT_NAME
FROM CIRCUITS C ,Service_Orders so
WHERE C.CIRT_STATUS ='INSERVICE'
AND so.SERO_CIRT_NAME= c.CIRT_NAME
AND so.SERO_ID = p_sero_id);


OPEN cct_id;
FETCH cct_id INTO v_PSTN;
CLOSE cct_id;


      DECLARE

      CURSOR plp_ex_cur IS
      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%EX%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND fa.FRAA_CIRT_NAME = v_PSTN;


      CURSOR plp_ug_cur IS
      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%UG%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND fa.FRAA_CIRT_NAME = v_PSTN;



      BEGIN

      OPEN plp_ex_cur;
      FETCH plp_ex_cur INTO v_plp_ex,v_plp_ex_1c;
      CLOSE plp_ex_cur;

      OPEN plp_ug_cur;
      FETCH plp_ug_cur INTO v_plp_ug,v_plp_ug_2c;
      CLOSE plp_ug_cur;







      END;


DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(SELECT ci.CIRT_NAME FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch,circuits ci
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND ch.CIRH_PARENT = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id  )
AND FU.FRAU_NAME LIKE  '%ADSL%');

DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (SELECT ci.CIRT_NAME FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch,circuits ci
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND ch.CIRH_PARENT = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id )
AND P.PORT_NAME LIKE 'P%');

UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL
WHERE p.PORT_CIRT_NAME IN (SELECT ci.CIRT_NAME FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch,circuits ci
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND ch.CIRH_PARENT = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id )
AND P.PORT_NAME LIKE 'P%';

UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(SELECT ci.CIRT_NAME FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch,circuits ci
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND ch.CIRH_PARENT = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id )
AND FU.FRAU_NAME LIKE  '%ADSL%');



IF v_plp_ex_1c = 'F' THEN

UPDATE PORT_LINK_PORTS plp
SET PLP.POLP_PORL_ID = v_plp_ex
WHERE PLP.POLP_PORL_ID = v_plp_ug;



ELSIF v_plp_ug_2c = 'F' THEN

UPDATE PORT_LINK_PORTS plp
SET PLP.POLP_PORL_ID = v_plp_ug
WHERE PLP.POLP_PORL_ID = v_plp_ex;



END IF;

                    DECLARE

                 CURSOR del_pl_cur IS
                   SELECT pl.PORL_ID,plp.POLP_PORL_ID
                 FROM port_links pl,port_link_ports plp
                 WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
                 AND pl.PORL_CIRT_NAME = v_PSTN;

                 BEGIN


                   OPEN del_pl_cur;
                   LOOP

                 EXIT WHEN del_pl_cur%NOTFOUND;

                 FETCH del_pl_cur
                   INTO v_pl_port,v_plp_port;

                 IF v_plp_port IS NULL THEN

                 DELETE  PORT_LINKS PL
                 WHERE   PL.PORL_ID = v_pl_port;

                 END IF;



                   END LOOP;

                   CLOSE del_pl_cur;

                 END;






                            DECLARE

                            CURSOR dp_select_cur  IS
                            SELECT fa.FRAA_ID
                             FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,port_link_ports plp,circuits ci
                             WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
                             AND fu.FRAU_ID = fa.FRAA_FRAU_ID
                            AND fa.FRAA_ID = plp.POLP_FRAA_ID
                            AND fa.FRAA_CIRT_NAME = ci.CIRT_NAME
                            AND ci.CIRT_STATUS = 'INSERVICE'
                             AND fc.FRAC_FRAN_NAME = 'DP'
                             AND fa.FRAA_SIDE = 'REAR'
                             AND fa.FRAA_CIRT_NAME = v_PSTN;

                            CURSOR sw_select_cur  IS
                            SELECT p.PORT_ID
                            FROM ports p,port_link_ports plp,circuits ci
                             WHERE p.PORT_ID = plp.POLP_PORT_ID
                            AND p.PORT_CIRT_NAME = ci.CIRT_NAME
                            AND ci.CIRT_STATUS = 'INSERVICE'
                            AND p.PORT_NAME NOT LIKE 'P%'
                            AND p.PORT_CIRT_NAME = v_PSTN;

                            BEGIN


                            OPEN dp_select_cur;
                            FETCH dp_select_cur INTO v_pl_test;
                            CLOSE dp_select_cur;

                            OPEN sw_select_cur;
                            FETCH sw_select_cur INTO v_pl_test2;
                            CLOSE sw_select_cur;





                            END;






EXCEPTION
WHEN OTHERS THEN


    p_ret_msg  := 'ADSL REMOVE CCT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END ADSL_DELETE_SO;

-- 23-01-2009 Buddika Weerasinghe


-- 11-02-2009 Samankula Owitipana
----DIDO WG change in WO TO TX

PROCEDURE SLT_DIDO_SET_WGTX (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR P2PTYPE_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DIOD TYPE';

CURSOR so_type_cur IS
SELECT so.SERO_ORDT_TYPE FROM SERVICE_ORDERS SO
WHERE so.SERO_ID = p_sero_id;


v_CUSTYPE_VAL VARCHAR2(50);
v_DIDOTYPE_VAL VARCHAR2(50);
v_SERVICECAT_VAL VARCHAR2(50);
v_NOF_PSTN_NEW number;
v_NOF_PSTN_PRE number;
v_NUMB_CHG VARCHAR2(50);
v_SO_TYPE_VAL VARCHAR2(40);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


OPEN P2PTYPE_select_cur;
FETCH P2PTYPE_select_cur INTO v_DIDOTYPE_VAL;
CLOSE P2PTYPE_select_cur;


OPEN so_type_cur;
FETCH so_type_cur INTO v_SO_TYPE_VAL;
CLOSE so_type_cur;







--------------------------------------------IMPLEMENT TX BEARER---------------------------------------------

        Declare

        CURSOR ex_area_cur  IS
        SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
        WHERE SOA.SEOA_SERO_ID = p_sero_id
        AND SOA.SEOA_NAME = 'TX WORK GROUP';



        v_ex_code VARCHAR2(20);



          BEGIN


           OPEN ex_area_cur;
          FETCH ex_area_cur INTO v_ex_code;
          CLOSE ex_area_cur;

           UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME =  v_ex_code || '-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IMPLEMENT TX BEARER' ;



    EXCEPTION
    WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set the WG. Check TX WORK GROUP:' || v_ex_code || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


    END;





 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);





END SLT_DIDO_SET_WGTX;

-- 11-02-2009 Samankula Owitipana


-- 24-11-2008 Samankula Owitipana
-- ADSL PSTN CREATE parallel Completion rule

PROCEDURE ADSL_PARALLEL_COMPRULE_NEW (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_CCT_ID VARCHAR2(25);
v_SO_ID VARCHAR2(25);

BEGIN

p_ret_msg := '';

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_PSTN_NO
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

SELECT ci.CIRT_NAME
INTO v_CCT_ID
FROM CIRCUITS ci
WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO) || '%(N)%'
AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED');

SELECT SO.SERO_ID
INTO v_SO_ID
FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
AND SO.SERO_CIRT_NAME = v_CCT_ID
AND SIT.SEIT_TASKNAME = 'CLOSE SERVICE ORDER'
AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED');

  IF v_SO_ID IS NOT NULL THEN
      p_ret_msg := 'PSTN SERVICE ORDER IS STILL INPROGRESS :' || v_SO_ID;
  ELSE
      p_ret_msg := '';
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND  THEN
    p_ret_msg := '';
END ADSL_PARALLEL_COMPRULE_NEW;
-- 24-11-2008 Samankula Owitipana



-- 06-12-2008 Samankula Owitipana
-- ADSL PSTN CREATE  APPROVE SO parallel Completion rule
PROCEDURE ADSL_PARALLEL_APPSO_COMPRULE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_CCT_ID VARCHAR2(25);
v_SO_ID VARCHAR2(25);


v_internet_fe VARCHAR2(10);
v_iptv_fe     VARCHAR2(10);

v_adsl_pkg  VARCHAR2(100);
v_iptv_pkg  VARCHAR2(100);

v_pkg_speed VARCHAR2(100);
 

cursor c_feature_internet is
SELECT sof.SOFE_DEFAULTVALUE
FROM SERVICE_ORDER_FEATURES sof 
WHERE SOFE_SERO_ID = p_sero_id
AND SOFE_FEATURE_NAME = 'INTERNET' ;

cursor c_feature_iptv is
SELECT sof.SOFE_DEFAULTVALUE
FROM SERVICE_ORDER_FEATURES sof 
WHERE SOFE_SERO_ID = p_sero_id
AND SOFE_FEATURE_NAME = 'IPTV' ;

CURSOR c_adsl_pkg  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PACKAGE_NAME'
AND soa.SEOA_SOFE_ID IS NULL;


CURSOR c_iptv_pkg  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IPTV_PACKAGE'
AND soa.SEOA_SOFE_ID IS NULL;


CURSOR c_adsl_speed  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED'
AND soa.SEOA_SOFE_ID IS NULL;



BEGIN




 P_dynamic_procedure.complete_approve_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);

  IF p_ret_msg IS NULL THEN
  
  
    OPEN c_feature_internet;
    FETCH c_feature_internet INTO v_internet_fe;
    CLOSE c_feature_internet;
    
    OPEN c_feature_iptv;
    FETCH c_feature_iptv INTO v_iptv_fe;
    CLOSE c_feature_iptv;
    
    OPEN c_adsl_pkg;
    FETCH c_adsl_pkg INTO v_adsl_pkg;
    CLOSE c_adsl_pkg;
    
    OPEN c_iptv_pkg;
    FETCH c_iptv_pkg INTO v_iptv_pkg;
    CLOSE c_iptv_pkg;
    
    OPEN c_adsl_speed;
    FETCH c_adsl_speed INTO v_pkg_speed;
    CLOSE c_adsl_speed;
  
  

  SELECT SOA.SEOA_DEFAULTVALUE
  INTO v_PSTN_NO
  FROM SERVICE_ORDER_ATTRIBUTES SOA
  WHERE SOA.SEOA_SERO_ID = p_sero_id
  AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

  SELECT ci.CIRT_NAME
  INTO v_CCT_ID
  FROM CIRCUITS ci
  WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO) || '%(N)%'
  AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED');

  SELECT SO.SERO_ID
  INTO v_SO_ID
  FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
  WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
  AND SO.SERO_CIRT_NAME = v_CCT_ID
  AND SIT.SEIT_TASKNAME = 'APPROVE SO'
  AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED'
  OR SIT.SEIT_STAS_ABBREVIATION = 'INPROGRESS');
  
  

        IF v_SO_ID IS NOT NULL THEN

            p_ret_msg := 'PSTN SERVICE ORDER STILL NOT APPROVED:' || v_SO_ID;

        ELSE

            p_ret_msg := '';

        END IF;
        
        
        IF v_internet_fe = 'Y' and v_adsl_pkg is null THEN
        
        p_ret_msg := 'ADSL Package name is empty';
        
        ELSIF  v_iptv_fe = 'Y' and v_iptv_pkg is null THEN
        
        p_ret_msg := 'IPTV Package name is empty';
        
        END IF;
        
        
        IF v_pkg_speed is null THEN
        
        p_ret_msg := 'SERVICE_SPEED attribute is blank';
        
        ELSIF (v_pkg_speed like '%/%' or v_pkg_speed like '%\%') THEN
        
        p_ret_msg := 'SERVICE_SPEED attribute value is wrong';
        
        END IF;
        
        

  ELSE

  p_ret_msg := p_ret_msg || ' APPROVE SO NOT COMPLETED PROPERLY.';

  END IF;
  
  

EXCEPTION
WHEN NO_DATA_FOUND  THEN

  
    p_ret_msg := '';
    
    
END ADSL_PARALLEL_APPSO_COMPRULE;

-- 06-12-2008 Samankula Owitipana


-- 17-02-2009 Samankula Owitipana
-- CDMA CREATE CLI SMS SOP STATUS SET as Y

PROCEDURE SLT_CDMA_SMS_CLI_SOP_Y (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_NEW_CLI VARCHAR2(5);
v_NEW_SMS VARCHAR2(5);

BEGIN

SELECT sof.SOFE_DEFAULTVALUE
INTO v_NEW_CLI
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_CLI'
AND NVL(sof.SOFE_DEFAULTVALUE,'N') <> NVL(sof.SOFE_PREV_VALUE,'N');

SELECT sof.SOFE_DEFAULTVALUE
INTO v_NEW_SMS
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_SMS'
AND NVL(sof.SOFE_DEFAULTVALUE,'N') <> NVL(sof.SOFE_PREV_VALUE,'N');

         IF     v_NEW_CLI = 'Y' THEN

        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',sof.SOFE_PROVISION_TIME = sysdate, sof.SOFE_PROVISION_USERNAME = 'CLARITY'
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_CLI';


        END IF;


        IF     v_NEW_SMS = 'Y' THEN

        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',sof.SOFE_PROVISION_TIME = sysdate, sof.SOFE_PROVISION_USERNAME = 'CLARITY'
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_SMS';


        END IF;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to Set Y. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END SLT_CDMA_SMS_CLI_SOP_Y;
-- 17-02-2009 Samankula Owitipana


-- 16-03-2009 Samankula Owitipana
--DELETE UPGRADE

PROCEDURE SLT_VPLS_ACC_WGCH_DEL_UPGRADE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;



v_CUSTYPE_VAL VARCHAR2(25);


-----------------------------------------APPROVE SO-----------------------------------------------------------


        BEGIN


        OPEN CUSTYPE_select_cur;
        FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
        CLOSE CUSTYPE_select_cur;

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;

         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);





END SLT_VPLS_ACC_WGCH_DEL_UPGRADE;

-- 16-03-2009 Samankula Owitipana
--DELETE UPGRADE


-- 17-03-2009 Samankula Owitipana
-- CCB SET METRO WG

PROCEDURE SLT_CCB_METROWG_CHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR reagon_select_cur  IS
SELECT DISTINCT trim(sar.SLTA_RH) FROM SERVICE_ORDERS SO,slt_areas sar
WHERE so.SERO_ID = p_sero_id
AND so.SERO_AREA_CODE = trim(sar.SLTA_LEA);


CURSOR so_type_cur IS
SELECT so.SERO_ORDT_TYPE FROM SERVICE_ORDERS SO
WHERE so.SERO_ID = p_sero_id;



v_REAGON_VAL VARCHAR2(40);
v_SO_TYPE_VAL VARCHAR2(40);

BEGIN

OPEN reagon_select_cur;
FETCH reagon_select_cur INTO v_REAGON_VAL;
CLOSE reagon_select_cur;

OPEN so_type_cur;
FETCH so_type_cur INTO v_SO_TYPE_VAL;
CLOSE so_type_cur;







---------------------------MTCE-----------------------------------

            IF v_REAGON_VAL = 'METRO' THEN


            UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
             SET sit.SEIT_WORG_NAME = 'PPO-DEV'
             WHERE SIT.SEIT_SERO_ID =  p_sero_id
             AND SIT.SEIT_WORG_NAME like '%-CCB-MTCE' ;

            END IF;




---------------------------CREATE------------------------------------

           IF v_REAGON_VAL = 'METRO' AND v_SO_TYPE_VAL = 'CREATE' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RESERVE NUMBER' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IDENTIFY FACILITIES' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE  INVOICE' ;



         END IF;

---------------------------CREATE-OR------------------------------------


         IF v_REAGON_VAL = 'METRO' AND v_SO_TYPE_VAL = 'CREATE-OR' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RESERVE NUMBER' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IDENTIFY FACILITIES' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE  INVOICE' ;



         END IF;

---------------------------MODIFY LOCATION-----------------------------------


         IF v_REAGON_VAL = 'METRO' AND v_SO_TYPE_VAL = 'MODIFY-LOCATION' THEN



         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IDENTIFY FACILITIES' ;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;




         END IF;

---------------------------MODIFY-NUMBER-----------------------------------


         IF v_REAGON_VAL = 'METRO' AND v_SO_TYPE_VAL = 'MODIFY-NUMBER' THEN



         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'PPO-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RESERVE NUMBER' ;


         END IF;

---------------------------APPROVE SO-----------------------------------

          IF v_REAGON_VAL = 'METRO' THEN



         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CEN-CCB-ENG'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;


        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'FAILED SET WORKGROUP' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);

END SLT_CCB_METROWG_CHANGE;


-- 17-03-2009 Samankula Owitipana
-- CCB SET METRO WG

--- 07-04-2009  jayan liyanage --


PROCEDURE SLT_SET_INITIAL_DSP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR Actual_Dsp_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACTUAL_DSP_DATE';




v_cct_id VARCHAR2(20);
v_cvt_char varchar2(100);






BEGIN



OPEN Actual_Dsp_cur;
FETCH Actual_Dsp_cur INTO v_cvt_char;
CLOSE Actual_Dsp_cur;




UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_cvt_char
WHERE SA.SEOA_NAME = 'SERVICE_PROVISION_DATE'
AND SA.SEOA_SERO_ID = p_sero_id;








p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set CCT attribute. Please check the INITIAL_DSP_DATE :' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END SLT_SET_INITIAL_DSP;


--- 07-04-2009  jayan liyanage --


-- 29-04-2009 jayan Liyanage

  PROCEDURE SLT_IPVPN_VER_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';





v_customer_type varchar2(30);
v_service_type  varchar2(30);
v_service_cat varchar2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;


    -----------------------------------------  ISSUE INVOICE -----------------------------------------
     BEGIN

         IF v_customer_type = 'CORPORATE' AND  v_service_cat = 'TEMPORARY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE  INVOICE' ;

         ELSIF v_customer_type = 'SME' AND  v_service_cat = 'TEMPORARY'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE  INVOICE' ;

         ELSIF v_customer_type = 'WHOLESALE' AND  v_service_cat = 'TEMPORARY'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE  INVOICE' ;




         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in ISSUE INVOICE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes: ' || v_customer_type);

     END;




        ---------------------- CONFIRM TEST LINK ------------------------------------------------------

  /* BEGIN

        IF v_customer_type = 'CORPORATE' AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'SME' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'WHOLESALE' AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes: ' || v_customer_type);

   END;
*/

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in IPVPN VERTUAL CREATE . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes: ' || v_customer_type);


 END SLT_IPVPN_VER_CREATE;


-- 29-04-2009 jayan Liyanage



-- 29-04-2009 jayan Liyanage

PROCEDURE SLT_IPVPN_VER_DELETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

v_customer_type varchar2(30);
v_service_type  varchar2(30);



  BEGIN


  OPEN serv_type_cur;
  FETCH serv_type_cur INTO v_service_type;
  CLOSE serv_type_cur;

  OPEN cust_type_cur;
  FETCH cust_type_cur INTO v_customer_type;
  CLOSE cust_type_cur;


    -----------------------------------------  APPROVE SO -----------------------------------------

         IF v_customer_type = 'CORPORATE'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;




         END IF;

          p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Approve So . Please check the Customer TYPE Attributes: ' || v_customer_type);





END SLT_IPVPN_VER_DELETE;

-- 29-04-2009 jayan Liyanage

-- 29-04-2009 jayan Liyanage

PROCEDURE SLT_IPVPN_VER_MODIFY_OTH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';


v_customer_type varchar2(30);
v_service_type  varchar2(30);
v_service_cat  varchar2(30);


BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;





        ---------------------- CONFIRM TEST LINK ------------------------------------------------------
/*    BEGIN

        IF v_customer_type = 'CORPORATE' AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'SME' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'WHOLESALE' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;




         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change  in CONFIRM TEST LINK. Please check the Customer TYPE Attributes: ' || v_customer_type);

    END;
*/

        ---------------------- MODIFY PRICE PLAN ------------------------------------------------------

   BEGIN

         IF v_customer_type = 'CORPORATE'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_customer_type = 'WHOLESALE'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;






         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes: ' || v_customer_type);

   END;





   p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


   EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change MODIFY-OTHERS . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change MODIFY-OTHERS. Please check the Customer TYPE Attributes: ' || v_customer_type);




  END SLT_IPVPN_VER_MODIFY_OTH;

-- 29-04-2009 jayan Liyanage

-- 29-04-2009 jayan Liyanage

  PROCEDURE SLT_IPVPN_VER_MODFI_SPEED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




 CURSOR cust_type_cur  IS
 SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
 WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
 AND so.SERO_ID = p_sero_id;


 CURSOR serv_type_cur  IS
 SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
 WHERE SOA.SEOA_SERO_ID = p_sero_id
 AND SOA.SEOA_NAME = 'SERVICE TYPE';

 CURSOR serv_categ_cur  IS
 SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
 WHERE SOA.SEOA_SERO_ID = p_sero_id
 AND SOA.SEOA_NAME = 'SERVICE CATEGORY';


 v_customer_type varchar2(30);
 v_service_type  varchar2(30);
 v_service_cat  varchar2(30);



  BEGIN


  OPEN serv_type_cur;
  FETCH serv_type_cur INTO v_service_type;
  CLOSE serv_type_cur;

  OPEN cust_type_cur;
  FETCH cust_type_cur INTO v_customer_type;
  CLOSE cust_type_cur;

  OPEN serv_categ_cur;
  FETCH serv_categ_cur INTO v_service_cat;
  CLOSE serv_categ_cur;




        ---------------------- CONFIRM TEST LINK ------------------------------------------------------
/*
   BEGIN
        IF v_customer_type = 'CORPORATE' AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'SME' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'WHOLESALE' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;




         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change  in CONFIRM TEST LINK. Please check the Customer TYPE Attributes: ' || v_customer_type);

    END;*/
        ----------------------------------  MODIFY PRICE PLAN ------------------------------------------

   BEGIN

         IF v_customer_type = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSif v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;






         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in MODIFY PRICE PLAN . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WG in ISSUE INVOICE. Please check the Customer TYPE Attributes: ' || v_customer_type);

    END;


   p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



   EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change in MODIFY-SPEED . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change in MODIFY-SPEED. Please check the Customer TYPE Attributes: ' || v_customer_type);


  END SLT_IPVPN_VER_MODFI_SPEED;


-- 29-04-2009 jayan Liyanage



-- 29-04-2009 jayan Liyanage

  PROCEDURE SLT_IPVPV_VER_RESUME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

v_customer_type varchar2(30);
v_service_type  varchar2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

    --------------------------------------   APPROVE SO -----------------------------------------------


         IF v_customer_type = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSif v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;

          p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in APPROVE SO . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change  in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_customer_type);



 END SLT_IPVPV_VER_RESUME;

 -- 29-04-2009 jayan Liyanage

-- 29-04-2009 jayan Liyanage

 PROCEDURE SLT_IPVPN_VER_SUSPEND (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

v_customer_type varchar2(30);
v_service_type  varchar2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

    --------------------------------------   APPROVE SO -----------------------------------------------


         IF v_customer_type = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSif v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;

          p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||v_customer_type);



 END SLT_IPVPN_VER_SUSPEND;


 -- 29-04-2009 jayan Liyanage


---29-04-2009  jayan Liyanage variable lenghts Updated on 20-10-2014---
PROCEDURE SLT_IPVPN_VER_MODIFY_CPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR firewall_cur  IS
SELECT SOA.SEOA_PREV_VALUE,SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'FIREWALL ROUTER CLASS';

CURSOR firewall_model_cur  IS
SELECT SOA.SEOA_PREV_VALUE,SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'FIREWALL ROUTER MODEL';




v_customer_type varchar2(200);
v_service_type  varchar2(200);
v_firewall_pre_type varchar2(200);
v_firewall_curr_type varchar2(200);
v_router_pre_val varchar2(100);
v_router_def_val varchar2(100);


BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN firewall_cur;
FETCH firewall_cur INTO v_firewall_pre_type,v_firewall_curr_type;
CLOSE firewall_cur;

OPEN firewall_model_cur;
FETCH firewall_model_cur INTO v_router_pre_val,v_router_def_val;
CLOSE firewall_model_cur;


    ---------------------------  Assign Firewall  Port -----------------------------------
             BEGIN

                      IF v_firewall_pre_type = 'NONE' AND  v_firewall_curr_type <> 'NONE' THEN

                            NULL;

                      ELSE

                             DELETE
                             FROM SERVICE_IMPLEMENTATION_TASKS SIT
                                 WHERE SIT.SEIT_SERO_ID =  p_sero_id
                             AND SIT.SEIT_TASKNAME = 'ASSIGN FIREWALL PORT';



                               p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

                      END IF;

        EXCEPTION
        WHEN OTHERS THEN


                     p_ret_msg  := 'Failed to ASSIGN FIREWALL PORT . Please check the  Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change ASSIGN FIREWALL PORT. Please check the  Attributes: ' ||v_firewall_pre_type || v_firewall_curr_type );

                -----------------------------------------------------------------------------------------

        END;


        BEGIN

            ---------------------------------------------------------------------------------------

                  IF v_firewall_curr_type = 'SLT' AND v_router_def_val = v_router_pre_val THEN

                           UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
                           SET sit.SEIT_WORG_NAME = 'IDC-PROV'
                           WHERE SIT.SEIT_SERO_ID =  p_sero_id
                           AND SIT.SEIT_TASKNAME = 'ASSIGN NEW F/W PORTS' ;

                  ELSE

                           DELETE
                           FROM SERVICE_IMPLEMENTATION_TASKS SIT
                           WHERE SIT.SEIT_SERO_ID =  p_sero_id
                           AND SIT.SEIT_TASKNAME = 'ASSIGN NEW F/W PORTS';



                            p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

                  END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to ASSIGN NEW F/W PORTS . Please check the  Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change ASSIGN NEW F/W PORTS. Please check  Attributes: ' ||  v_firewall_curr_type || v_router_def_val || v_router_pre_val);


        -----------------------------------------------------------------------------------------

        END;




     --------------------------   COLLECT FIREWALL ROUTER ---------------------------------
    BEGIN
         IF v_firewall_pre_type = 'SLT' and v_firewall_curr_type = 'CUSTOMER' THEN

         NULL;

         --UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         --SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         --WHERE SIT.SEIT_SERO_ID =  p_sero_id
         --AND SIT.SEIT_TASKNAME = 'COLLECT F/W ROUTER';

         ELSE

         DELETE
         FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT F/W ROUTER';




         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change COLLECT F/W ROUTER . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change COLLECT F/W ROUTER. Please check the Customer TYPE Attributes: ' || v_customer_type);
   END;

   --------------------------------------  HANDOVER F/W ROUTER-------------------------------

   BEGIN

        IF v_firewall_pre_type = 'CUSTOMER' and v_firewall_curr_type = 'SLT' THEN


         NULL;
         --UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         --SET sit.SEIT_WORG_NAME = 'IDC-PROV'
         --WHERE SIT.SEIT_SERO_ID =  p_sero_id
         --AND SIT.SEIT_TASKNAME = 'HANDOVER F/W ROUTER';

         ELSE

         DELETE
         FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'HANDOVER F/W ROUTER';


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change HANDOVER F/W ROUTER . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change HANDOVER F/W ROUTER. Please check the Customer TYPE Attributes: ' || v_customer_type);
   END;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change SLT_IPVPN_VER_MODIFY_CPE . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change SLT_IPVPN_VER_MODIFY_CPE . Please check the Customer TYPE Attributes: ' || v_customer_type);



END SLT_IPVPN_VER_MODIFY_CPE;
---29-04-2009  jayan Liyanage---



--- 29-04-2009  jayan Liyanage --


   PROCEDURE SLT_IPVPN_VER_CLOSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



      CURSOR serv_categ_cur  IS
      SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
      WHERE SOA.SEOA_SERO_ID = p_sero_id
      AND SOA.SEOA_NAME = 'SERVICE CATEGORY';


      v_service_cat varchar2(30);


        ---------------------- CLOSE SERVICE ORDERS  ------------------------------------------------------
   BEGIN



   OPEN serv_categ_cur;
   FETCH serv_categ_cur INTO v_service_cat;
   CLOSE serv_categ_cur;


       IF v_service_cat = 'TEST' THEN

       UPDATE SERVICE_ORDER_ATTRIBUTES SOA
       SET SOA.SEOA_DEFAULTVALUE = 'PERMANENT'
       WHERE SOA.SEOA_SERO_ID = p_sero_id
       AND SOA.SEOA_NAME = 'SERVICE CATEGORY';




        END IF;


         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CLOSE SERVICE ORDERS . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change  in CLOSE SERVICE ORDERS. Please check the Customer TYPE Attributes: ' || v_service_cat);



   END  SLT_IPVPN_VER_CLOSE;



--- 29-04-2009  jayan Liyanage --



-- 29-04-2009 Samankula Owitipana
-- PSTN MODIFY-LOCATION  CHECK ADSL SO

PROCEDURE PSTN_MODIFYLOC_CHKADSL_IDENTFA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_ADSL VARCHAR2(25);
v_LEA VARCHAR2(25);
v_ORD_TYPE VARCHAR2(75);
v_ADSL_N VARCHAR2(25);
v_ORD_TYPE_N VARCHAR2(75);
v_ADSL_CCT VARCHAR2(25);



CURSOR LEA_select_cur  IS
SELECT lo.LOCN_AREA_CODE
FROM SERVICE_ORDER_ATTRIBUTES SOA,EQUIPMENT eq,LOCATIONS lo
WHERE SOA.SEOA_SERO_ID = p_sero_id
and SOA.SEOA_DEFAULTVALUE = eq.EQUP_EXCC_CODE
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_TTNAME like '%-NODE'
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE';


CURSOR PSTN_select_cur  IS
SELECT substr(trim(ci.CIRT_DISPLAYNAME),4,7)
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME;



BEGIN

P_dynamic_procedure.complete_dp_address_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


OPEN LEA_select_cur;
FETCH LEA_select_cur INTO v_LEA;
CLOSE LEA_select_cur;


OPEN PSTN_select_cur;
FETCH PSTN_select_cur INTO v_PSTN_NO;
CLOSE PSTN_select_cur;

                      IF p_ret_msg IS NULL THEN

                        DECLARE

                      CURSOR ADSL_CCT_cur  IS
                      SELECT ci.CIRT_DISPLAYNAME
                      FROM CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO)
                      and ci.CIRT_STATUS = 'INSERVICE';

                      CURSOR ADSL_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO)
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      and ci.CIRT_STATUS = 'INSERVICE'
                      and (so.SERO_ORDT_TYPE = 'MODIFY-LOCATION' or so.SERO_ORDT_TYPE = 'DELETE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');


                      CURSOR ADSL2_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO) || '%(N)%'
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED')
                      and (so.SERO_ORDT_TYPE = 'MODIFY-LOCATION' or so.SERO_ORDT_TYPE = 'DELETE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');



                      BEGIN

                      OPEN ADSL_CCT_cur;
                      FETCH ADSL_CCT_cur INTO v_ADSL_CCT;
                      CLOSE ADSL_CCT_cur;

                      OPEN ADSL2_select_cur;
                      FETCH ADSL2_select_cur INTO v_ADSL_N,v_ORD_TYPE_N;
                      CLOSE ADSL2_select_cur;

                      OPEN ADSL_select_cur;
                      FETCH ADSL_select_cur INTO v_ADSL,v_ORD_TYPE;
                      CLOSE ADSL_select_cur;


                         IF v_ADSL_CCT is not null THEN


                               IF v_ADSL_N is null THEN

                                    IF v_ADSL is null THEN

                                    p_ret_char := 'WARNING: ' || v_ADSL_CCT || ' ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. TAKE ACTION ACCORDINGLY     ';

                                  ELSE

                                  p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. ' || v_ADSL || ' ' || v_ORD_TYPE || ' SERVICE ORDER INPROGRESS     ';

                                  END IF;



                                ELSE

                               p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. ' || v_ADSL_N || ' ' || v_ORD_TYPE_N || ' SERVICE ORDER INPROGRESS     ';

                               END IF;


                          ELSE

                          NULL;

                          END IF;


                      END;

                    ELSE

                      p_ret_msg := p_ret_msg || ' Check DP Addresses Error.';

                      END IF;



EXCEPTION
  WHEN OTHERS  THEN
    p_ret_msg := 'Failed Completion Rule. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END PSTN_MODIFYLOC_CHKADSL_IDENTFA;
-- 29-04-2009 Samankula Owitipana

-- 30-04-2009 Samankula Owitipana
-- PSTN MODIFY-LOCATION  CHECK ADSL SO

PROCEDURE PSTN_MODIFYLOC_CHKADSL_APPSO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_ADSL VARCHAR2(25);
v_LEA VARCHAR2(25);
v_ORD_TYPE VARCHAR2(75);
v_ADSL_N VARCHAR2(25);
v_ORD_TYPE_N VARCHAR2(75);
v_ADSL_CCT VARCHAR2(25);


CURSOR LEA_select_cur  IS
SELECT lo.LOCN_AREA_CODE
FROM SERVICE_ORDER_ATTRIBUTES SOA,EQUIPMENT eq,LOCATIONS lo
WHERE SOA.SEOA_SERO_ID = p_sero_id
and SOA.SEOA_DEFAULTVALUE = eq.EQUP_EXCC_CODE
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_TTNAME like '%-NODE'
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE';


CURSOR PSTN_select_cur  IS
SELECT substr(trim(ci.CIRT_DISPLAYNAME),4,7)
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME;



BEGIN

P_dynamic_procedure.complete_approve_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


OPEN LEA_select_cur;
FETCH LEA_select_cur INTO v_LEA;
CLOSE LEA_select_cur;


OPEN PSTN_select_cur;
FETCH PSTN_select_cur INTO v_PSTN_NO;
CLOSE PSTN_select_cur;



                      IF p_ret_msg IS NULL THEN


                      DECLARE

                      CURSOR ADSL_CCT_cur  IS
                      SELECT ci.CIRT_DISPLAYNAME
                      FROM CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO)
                      and ci.CIRT_STATUS = 'INSERVICE';

                      CURSOR ADSL_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO)
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      and ci.CIRT_STATUS = 'INSERVICE'
                      and (so.SERO_ORDT_TYPE = 'MODIFY-LOCATION' or so.SERO_ORDT_TYPE = 'DELETE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');


                      CURSOR ADSL2_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO) || '%(N)%'
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED')
                      and (so.SERO_ORDT_TYPE = 'MODIFY-LOCATION' or so.SERO_ORDT_TYPE = 'DELETE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');



                      BEGIN

                      OPEN ADSL_CCT_cur;
                      FETCH ADSL_CCT_cur INTO v_ADSL_CCT;
                      CLOSE ADSL_CCT_cur;

                      OPEN ADSL2_select_cur;
                      FETCH ADSL2_select_cur INTO v_ADSL_N,v_ORD_TYPE_N;
                      CLOSE ADSL2_select_cur;

                      OPEN ADSL_select_cur;
                      FETCH ADSL_select_cur INTO v_ADSL,v_ORD_TYPE;
                      CLOSE ADSL_select_cur;


                         IF v_ADSL_CCT is not null THEN


                               IF v_ADSL_N is null THEN

                                    IF v_ADSL is null THEN

                                    p_ret_char := 'WARNING: ' || v_ADSL_CCT || ' ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. TAKE ACTION ACCORDINGLY      ';

                                  ELSE

                                  p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. ' || v_ADSL || ' ' || v_ORD_TYPE || ' SERVICE ORDER INPROGRESS     ';

                                  END IF;



                                ELSE

                               p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR THIS PSTN. ' || v_ADSL_N || ' ' || v_ORD_TYPE_N || ' SERVICE ORDER INPROGRESS     ';

                               END IF;


                          ELSE

                          NULL;

                          END IF;


                      END;


                    ELSE

                      p_ret_msg := p_ret_msg || ' Check DP Addresses Error.';

                      END IF;



EXCEPTION
  WHEN OTHERS  THEN
    p_ret_msg := 'Failed Completion Rule. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END PSTN_MODIFYLOC_CHKADSL_APPSO;
-- 30-04-2009 Samankula Owitipana




-- 04-05-2009 Samankula Owitipana
-- ADSL PSTN MODIFY LOCATION  APPROVE SO parallel Completion rule

PROCEDURE ADSL_MODIFYLOC_APPSO_COMPRULE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_CCT_ID VARCHAR2(25);
v_CCT_ID_INS VARCHAR2(25);
v_SO_ID VARCHAR2(25);

BEGIN




 P_dynamic_procedure.complete_approve_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);

  IF p_ret_msg IS NULL THEN

  SELECT SOA.SEOA_DEFAULTVALUE
  INTO v_PSTN_NO
  FROM SERVICE_ORDER_ATTRIBUTES SOA
  WHERE SOA.SEOA_SERO_ID = p_sero_id
  AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';



                           DECLARE

                       CURSOR TP_select_cur  IS
                         SELECT ci.CIRT_NAME
                         FROM CIRCUITS ci
                         WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO) || '%(N)%'
                         AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED');

                       CURSOR TP2_select_cur  IS
                         SELECT ci.CIRT_NAME
                         FROM CIRCUITS ci
                         WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO)
                         AND (ci.CIRT_STATUS = 'INSERVICE');


                       BEGIN

                       OPEN TP_select_cur;
                       FETCH TP_select_cur INTO v_CCT_ID;
                       CLOSE TP_select_cur;


                       OPEN TP2_select_cur;
                       FETCH TP2_select_cur INTO v_CCT_ID_INS;
                       CLOSE TP2_select_cur;


                       IF v_CCT_ID is not null THEN


                         SELECT SO.SERO_ID
                         INTO v_SO_ID
                         FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
                         WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
                         AND SO.SERO_CIRT_NAME = v_CCT_ID
                         AND SIT.SEIT_TASKNAME = 'APPROVE SO'
                         AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED'
                         OR SIT.SEIT_STAS_ABBREVIATION = 'INPROGRESS');

                       ELSE

                       SELECT SO.SERO_ID
                         INTO v_SO_ID
                         FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
                         WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
                         AND SO.SERO_CIRT_NAME = v_CCT_ID_INS
                         AND SIT.SEIT_TASKNAME = 'APPROVE SO'
                         AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED'
                         OR SIT.SEIT_STAS_ABBREVIATION = 'INPROGRESS');

                       END IF;


                       END;



        IF v_SO_ID IS NOT NULL THEN

      p_ret_msg := 'PSTN SERVICE ORDER STILL NOT APPROVED:' || v_SO_ID;

        ELSE

      p_ret_msg := '';

        END IF;

  ELSE

  p_ret_msg := p_ret_msg || ' APPROVE SO NOT COMPLETED PROPERLY.';

  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND  THEN
    p_ret_msg := '';
END ADSL_MODIFYLOC_APPSO_COMPRULE ;

-- 04-05-2009 Samankula Owitipana


-- 04-05-2009 Samankula Owitipana
-- ADSL PSTN MODIFY LOCATION  APPROVE SO parallel Completion rule

PROCEDURE ADSL_MODIFYLOC_MDF_COMPRULE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_CCT_ID VARCHAR2(25);
v_CCT_ID_INS VARCHAR2(25);
v_SO_ID VARCHAR2(25);

BEGIN



p_ret_msg := '';



  SELECT SOA.SEOA_DEFAULTVALUE
  INTO v_PSTN_NO
  FROM SERVICE_ORDER_ATTRIBUTES SOA
  WHERE SOA.SEOA_SERO_ID = p_sero_id
  AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';



                           DECLARE

                       CURSOR TP_select_cur  IS
                         SELECT ci.CIRT_NAME
                         FROM CIRCUITS ci
                         WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO) || '%(N)%'
                         AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED');

                       CURSOR TP2_select_cur  IS
                         SELECT ci.CIRT_NAME
                         FROM CIRCUITS ci
                         WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO)
                         AND (ci.CIRT_STATUS = 'INSERVICE');


                       BEGIN

                       OPEN TP_select_cur;
                       FETCH TP_select_cur INTO v_CCT_ID;
                       CLOSE TP_select_cur;


                       OPEN TP2_select_cur;
                       FETCH TP2_select_cur INTO v_CCT_ID_INS;
                       CLOSE TP2_select_cur;


                       IF v_CCT_ID is not null THEN


                         SELECT SO.SERO_ID
                         INTO v_SO_ID
                         FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
                         WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
                         AND SO.SERO_CIRT_NAME = v_CCT_ID
                         AND SIT.SEIT_TASKNAME = 'CLOSE SERVICE ORDER'
                         AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED');

                       ELSE

                       SELECT SO.SERO_ID
                         INTO v_SO_ID
                         FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
                         WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
                         AND SO.SERO_CIRT_NAME = v_CCT_ID_INS
                         AND SIT.SEIT_TASKNAME = 'CLOSE SERVICE ORDER'
                         AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED');

                       END IF;


                       END;



        IF v_SO_ID IS NOT NULL THEN

      p_ret_msg := 'PSTN SERVICE ORDER IS STILL INPROGRESS:' || v_SO_ID;

        ELSE

      p_ret_msg := '';

        END IF;



EXCEPTION
  WHEN NO_DATA_FOUND  THEN
    p_ret_msg := '';

END ADSL_MODIFYLOC_MDF_COMPRULE ;

-- 04-05-2009 Samankula Owitipana


--- 01-05-2009  Buddika weerasinghe--


PROCEDURE SLT_SET_ATER_NAME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR vpn_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'VPN NAME';

CURSOR cct_cur  IS
SELECT SO.SERO_CIRT_NAME
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;


v_cct_id VARCHAR2(20);
v_cvt_char varchar2(100);






BEGIN



OPEN vpn_cur;
FETCH vpn_cur INTO v_cvt_char;
CLOSE vpn_cur;

OPEN cct_cur;
FETCH cct_cur INTO v_cct_id;
CLOSE cct_cur;




INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_cvt_char,'VPN NAME',null);








p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set ALTERNATE NAME. Please check VPN Name attribute :' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END SLT_SET_ATER_NAME;


--- 01-05-2009  Buddika weerasinghe--


--- 05-05-2009  jayan Liyanage

PROCEDURE SLT_IPVPN_VER_MODIFY_CPE_MODPP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


v_customer_type varchar2(30);

   BEGIN


   OPEN cust_type_cur;
   FETCH cust_type_cur INTO v_customer_type;
   CLOSE cust_type_cur;







    --------------------------------------   MODIFY PRICE PLAN -----------------------------------------------


         IF v_customer_type = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSif v_customer_type = 'SME'    THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to MODIFY PRICE PLAN . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change MODIFY PRICE PLAN. Please check the Customer TYPE Attributes: ' || v_customer_type);



END SLT_IPVPN_VER_MODIFY_CPE_MODPP;


--- 05-05-2009  jayan Liyanage


--- 13-05-2009  jayan Liyanage


  PROCEDURE SLT_IPVPV_VER_DATE_CONVERTE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS







CURSOR serv_terminate_date_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TERMINATION DATE';




  v_cc varchar2(10);
  v_service_type varchar2(10);

BEGIN


OPEN serv_terminate_date_cur;
FETCH serv_terminate_date_cur INTO v_service_type;
CLOSE serv_terminate_date_cur;


      v_cc := TO_CHAR(TO_DATE(v_service_type,'yyyy-mm-dd'));


      UPDATE SERVICE_ORDER_ATTRIBUTES SOA
      SET SOA.SEOA_DEFAULTVALUE = v_cc
      WHERE SOA.SEOA_SERO_ID = p_sero_id
      AND SOA.SEOA_NAME = 'TERMINATION DATE';





      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Convert to Date . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Convert to Date. Please check the Customer TYPE Attributes: ' || v_cc);



 END SLT_IPVPV_VER_DATE_CONVERTE;


--- 13-05-2009  jayan Liyanage

-- 07-05-2009 Samankula Owitipana
-- PSTN CREATE-OR CHECK ADSL SO

PROCEDURE PSTN_CREATEOR_CHKADSL_IDENTI (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_ADSL VARCHAR2(25);
v_LEA VARCHAR2(25);
v_ORD_TYPE VARCHAR2(75);
v_ADSL_N VARCHAR2(25);
v_ORD_TYPE_N VARCHAR2(75);
v_ADSL_CCT VARCHAR2(25);
v_LEA_OLD VARCHAR2(25);
v_PSTN_NO_OLD VARCHAR2(25);


CURSOR OLD_LEA_cur  IS
SELECT soa.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_OLD_EXCHANGE_AREA_CODE';


CURSOR OLD_PSTN_cur  IS
SELECT substr(trim(soa.SEOA_DEFAULTVALUE),4,7)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_OLD_PHONE_NUMBER';


CURSOR LEA_select_cur  IS
SELECT lo.LOCN_AREA_CODE
FROM SERVICE_ORDER_ATTRIBUTES SOA,EQUIPMENT eq,LOCATIONS lo
WHERE SOA.SEOA_SERO_ID = p_sero_id
and SOA.SEOA_DEFAULTVALUE = eq.EQUP_EXCC_CODE
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_TTNAME like '%-NODE'
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE';


CURSOR PSTN_select_cur  IS
SELECT substr(trim(ci.CIRT_DISPLAYNAME),4,7)
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME;



BEGIN

P_dynamic_procedure.complete_dp_address_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


OPEN LEA_select_cur;
FETCH LEA_select_cur INTO v_LEA;
CLOSE LEA_select_cur;


OPEN PSTN_select_cur;
FETCH PSTN_select_cur INTO v_PSTN_NO;
CLOSE PSTN_select_cur;

OPEN OLD_LEA_cur;
FETCH OLD_LEA_cur INTO v_LEA_OLD;
CLOSE OLD_LEA_cur;


OPEN OLD_PSTN_cur;
FETCH OLD_PSTN_cur INTO v_PSTN_NO_OLD;
CLOSE OLD_PSTN_cur;


                      IF p_ret_msg IS NULL THEN

                        DECLARE

                      CURSOR ADSL_CCT_cur  IS
                      SELECT ci.CIRT_DISPLAYNAME
                      FROM CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA_OLD) || trim(v_PSTN_NO_OLD)
                      and ci.CIRT_STATUS = 'INSERVICE';

                      CURSOR ADSL_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA_OLD) || trim(v_PSTN_NO_OLD)
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      and ci.CIRT_STATUS = 'INSERVICE'
                      and so.SERO_ORDT_TYPE = 'DELETE'
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');


                      CURSOR ADSL2_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO) || '%(N)%'
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED')
                      and (so.SERO_ORDT_TYPE = 'CREATE-OR' or so.SERO_ORDT_TYPE = 'CREATE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');



                      BEGIN

                      OPEN ADSL_CCT_cur;
                      FETCH ADSL_CCT_cur INTO v_ADSL_CCT;
                      CLOSE ADSL_CCT_cur;

                      OPEN ADSL2_select_cur;
                      FETCH ADSL2_select_cur INTO v_ADSL_N,v_ORD_TYPE_N;
                      CLOSE ADSL2_select_cur;

                      OPEN ADSL_select_cur;
                      FETCH ADSL_select_cur INTO v_ADSL,v_ORD_TYPE;
                      CLOSE ADSL_select_cur;


                         IF v_ADSL_CCT is not null THEN


                               IF v_ADSL_N is null THEN

                                    IF v_ADSL is null THEN

                                    p_ret_char := 'WARNING: ' || v_ADSL_CCT || ' ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. TAKE ACTION ACCORDINGLY     ';

                                  ELSE

                                  p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. ' || v_ADSL || ' ' || v_ORD_TYPE || ' SERVICE ORDER INPROGRESS     ';

                                  END IF;



                                ELSE

                               p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. ' || v_ADSL_N || ' ' || v_ORD_TYPE_N || ' SERVICE ORDER INPROGRESS FOR NEW ADSL     ';

                               END IF;


                          ELSE

                          NULL;

                          END IF;


                      END;

                    ELSE

                      p_ret_msg := p_ret_msg || ' Check DP Addresses Error.';

                      END IF;



EXCEPTION
  WHEN OTHERS  THEN
    p_ret_msg := 'Failed Completion Rule. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END PSTN_CREATEOR_CHKADSL_IDENTI;
-- 07-05-2009 Samankula Owitipana


-- 07-05-2009 Samankula Owitipana
-- PSTN CREATE-OR CHECK ADSL SO

PROCEDURE PSTN_CREATEOR_CHKADSL_APPSO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_PSTN_NO VARCHAR2(25);
v_ADSL VARCHAR2(25);
v_LEA VARCHAR2(25);
v_ORD_TYPE VARCHAR2(75);
v_ADSL_N VARCHAR2(25);
v_ORD_TYPE_N VARCHAR2(75);
v_ADSL_CCT VARCHAR2(25);
v_LEA_OLD VARCHAR2(25);
v_PSTN_NO_OLD VARCHAR2(25);


CURSOR OLD_LEA_cur  IS
SELECT soa.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_OLD_EXCHANGE_AREA_CODE';


CURSOR OLD_PSTN_cur  IS
SELECT substr(trim(soa.SEOA_DEFAULTVALUE),4,7)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_OLD_PHONE_NUMBER';


CURSOR LEA_select_cur  IS
SELECT lo.LOCN_AREA_CODE
FROM SERVICE_ORDER_ATTRIBUTES SOA,EQUIPMENT eq,LOCATIONS lo
WHERE SOA.SEOA_SERO_ID = p_sero_id
and SOA.SEOA_DEFAULTVALUE = eq.EQUP_EXCC_CODE
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_TTNAME like '%-NODE'
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE';


CURSOR PSTN_select_cur  IS
SELECT substr(trim(ci.CIRT_DISPLAYNAME),4,7)
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME;



BEGIN

P_dynamic_procedure.complete_approve_check (
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


OPEN LEA_select_cur;
FETCH LEA_select_cur INTO v_LEA;
CLOSE LEA_select_cur;


OPEN PSTN_select_cur;
FETCH PSTN_select_cur INTO v_PSTN_NO;
CLOSE PSTN_select_cur;

OPEN OLD_LEA_cur;
FETCH OLD_LEA_cur INTO v_LEA_OLD;
CLOSE OLD_LEA_cur;


OPEN OLD_PSTN_cur;
FETCH OLD_PSTN_cur INTO v_PSTN_NO_OLD;
CLOSE OLD_PSTN_cur;


                      IF p_ret_msg IS NULL THEN

                        DECLARE

                      CURSOR ADSL_CCT_cur  IS
                      SELECT ci.CIRT_DISPLAYNAME
                      FROM CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA_OLD) || trim(v_PSTN_NO_OLD)
                      and ci.CIRT_STATUS = 'INSERVICE';

                      CURSOR ADSL_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA_OLD) || trim(v_PSTN_NO_OLD)
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      and ci.CIRT_STATUS = 'INSERVICE'
                      and so.SERO_ORDT_TYPE = 'DELETE'
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');


                      CURSOR ADSL2_select_cur  IS
                      SELECT so.SERO_ID,SO.SERO_ORDT_TYPE
                      FROM SERVICE_ORDERS SO,CIRCUITS CI
                      WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_LEA) || trim(v_PSTN_NO) || '%(N)%'
                      and so.SERO_CIRT_NAME = ci.CIRT_NAME
                      AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED')
                      and (so.SERO_ORDT_TYPE = 'CREATE-OR' or so.SERO_ORDT_TYPE = 'CREATE')
                      and (so.SERO_STAS_ABBREVIATION = 'APPROVED' or so.SERO_STAS_ABBREVIATION = 'PROPOSED');



                      BEGIN

                      OPEN ADSL_CCT_cur;
                      FETCH ADSL_CCT_cur INTO v_ADSL_CCT;
                      CLOSE ADSL_CCT_cur;

                      OPEN ADSL2_select_cur;
                      FETCH ADSL2_select_cur INTO v_ADSL_N,v_ORD_TYPE_N;
                      CLOSE ADSL2_select_cur;

                      OPEN ADSL_select_cur;
                      FETCH ADSL_select_cur INTO v_ADSL,v_ORD_TYPE;
                      CLOSE ADSL_select_cur;


                         IF v_ADSL_CCT is not null THEN


                               IF v_ADSL_N is null THEN

                                    IF v_ADSL is null THEN

                                    p_ret_char := 'WARNING: ' || v_ADSL_CCT || ' ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. TAKE ACTION ACCORDINGLY     ';

                                  ELSE

                                  p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. ' || v_ADSL || ' ' || v_ORD_TYPE || ' SERVICE ORDER INPROGRESS     ';

                                  END IF;



                                ELSE

                               p_ret_char := 'ADSL CIRCUIT IS AVAILABLE FOR OLD PSTN. ' || v_ADSL_N || ' ' || v_ORD_TYPE_N || ' SERVICE ORDER INPROGRESS FOR NEW ADSL     ';

                               END IF;


                          ELSE

                          NULL;

                          END IF;


                      END;

                    ELSE

                      p_ret_msg := p_ret_msg || ' APPROVE SO NOT COMPLETED PROPERLY.';

                      END IF;



EXCEPTION
  WHEN OTHERS  THEN
    p_ret_msg := 'Failed Completion Rule. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END PSTN_CREATEOR_CHKADSL_APPSO;
-- 07-05-2009 Samankula Owitipana


-- 26-05-2009 Samankula Owitipana
-- SLA MAINTANENCE WINDOW and RESTORATION TIME SEPERATION

PROCEDURE ALL_SLA_VALUE_UPDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR RESTORE_select_cur  IS
SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;

CURSOR MAINT_select_cur  IS
SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;
CURSOR c_oss_sla_window  IS
SELECT soa.SEOA_DEFAULTVALUE 
from service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;

CURSOR c_oss_restore_time  IS
SELECT soa.SEOA_DEFAULTVALUE 
from service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RESTORATION TIME' ;
v_SLA_MAINT_WINDOW service_order_attributes.SEOA_DEFAULTVALUE%TYPE;
v_RESTORE_TIME service_order_attributes.SEOA_DEFAULTVALUE%TYPE;
v_oss_sla service_order_attributes.SEOA_DEFAULTVALUE%TYPE;
v_oss_restore service_order_attributes.SEOA_DEFAULTVALUE%TYPE;


BEGIN

OPEN RESTORE_select_cur;
FETCH RESTORE_select_cur INTO v_RESTORE_TIME;
CLOSE RESTORE_select_cur;
OPEN MAINT_select_cur;
FETCH MAINT_select_cur INTO v_SLA_MAINT_WINDOW;
CLOSE MAINT_select_cur;

IF (v_RESTORE_TIME is null and v_SLA_MAINT_WINDOW is null) THEN
OPEN c_oss_sla_window;
FETCH c_oss_sla_window INTO v_oss_sla;
CLOSE c_oss_sla_window;
OPEN c_oss_restore_time;
FETCH c_oss_restore_time INTO v_oss_restore;
CLOSE c_oss_restore_time;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_oss_sla || ',' || v_oss_restore
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;
ELSE

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_RESTORE_TIME
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RESTORATION TIME' ;
UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_MAINT_WINDOW
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;
END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to set SLA and RESTORE TIME:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END ALL_SLA_VALUE_UPDATE;

-- 26-05-2009 Samankula Owitipana

-- 22-06-2009 Samankula Owitipana
--VPLS Access Link CREATE_UPGRADE

PROCEDURE VPLS_WGCH_CREATE_UPGRADE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


v_CUSTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A VARCHAR2(20);
v_SLA_TYPE_B VARCHAR2(20);
v_SLA_PERCENTAGE_A VARCHAR2(20);
v_SLA_PERCENTAGE_B VARCHAR2(20);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;







------------------------------------------ISSUE DEL UPGRADE SO-----------------------------------------------------------


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL UPGRADE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL UPGRADE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL UPGRADE SO' ;


         END IF;

         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ISSUE DEL UPGRADE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg  || v_CUSTYPE_VAL);

        END;



END VPLS_WGCH_CREATE_UPGRADE;

-- 22-06-2009 Samankula Owitipana

-- 10-06-2009  Jayan Liyanage

-- 11-08-2011  Jayan Liyanage

PROCEDURE ADSL_MODIFY_SPEED_REMOVE_IP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS

   CURSOR cur_sa_package
   IS
      SELECT UPPER(soa.seoa_defaultvalue),UPPER(soa.seoa_prev_value)
        FROM service_orders so, service_order_attributes soa
       WHERE so.sero_id = soa.seoa_sero_id
         --AND (so.sero_ordt_type = 'MODIFY-SPEED' or so.sero_ordt_type = 'CREATE')
         AND so.sero_sert_abbreviation = 'ADSL'
         AND soa.seoa_name = 'SA_PACKAGE_NAME'
         AND so.sero_id = p_sero_id;
		 
   CURSOR cur_adal_type
   IS
      SELECT UPPER(soa.seoa_defaultvalue),UPPER(soa.seoa_prev_value)
        FROM service_orders so, service_order_attributes soa
       WHERE so.sero_id = soa.seoa_sero_id
         --AND (so.sero_ordt_type = 'MODIFY-SPEED' or so.sero_ordt_type = 'CREATE')
         AND so.sero_sert_abbreviation = 'ADSL'
         AND soa.seoa_name = 'ADSL_TYPE'
         AND so.sero_id = p_sero_id;		 

   sa_value_pre     VARCHAR2 (1000);
   sa_default_val   VARCHAR2 (1000);
   
   v_adsltype_pre   VARCHAR2 (100);
   v_adsltype_new   VARCHAR2 (100);   
   
BEGIN

   OPEN cur_sa_package;
   FETCH cur_sa_package
    INTO sa_default_val, sa_value_pre;
   CLOSE cur_sa_package;
   
      OPEN cur_adal_type;
   FETCH cur_adal_type
    INTO v_adsltype_new, v_adsltype_pre;
   CLOSE cur_adal_type;
   

   IF     ((sa_default_val = 'WEB MASTER' OR sa_default_val = 'WEB PRO') AND v_adsltype_new LIKE '%STATIC%')

      AND (   sa_value_pre = 'HOME'
           OR sa_value_pre = 'OFFICE'
           OR sa_value_pre = 'OFFICE PLUS'
           OR sa_value_pre = 'XCEL'
           OR sa_value_pre = 'XCEL PLUS'
           OR sa_value_pre = 'XCITE'
           OR sa_value_pre = 'XCITE PLUS'
           OR sa_value_pre = 'ENTREE'
           OR sa_value_pre = 'HOME PLUS'
           OR sa_value_pre = 'WEB SURFER PLUS'
           OR sa_value_pre = 'WEB PRO PLUS'
           OR sa_value_pre = 'WEB MASTER PLUS'
           OR sa_value_pre = 'WEB MATE'
           OR sa_value_pre = 'WEB SURFER'
		   OR sa_value_pre = 'WEB FAMILY'
		   OR sa_value_pre = 'WEB STARTER'
		   OR sa_value_pre = 'WEB PAL'
		   OR sa_value_pre = 'WEB CHAMP'
		   OR sa_value_pre = 'WEB LIFE'
           OR ( (sa_value_pre = 'WEB PRO' OR sa_value_pre = 'WEB MASTER') AND v_adsltype_pre NOT LIKE '%STATIC%')
		   OR sa_value_pre IS NULL)
   THEN
   
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'REMOVE IPS';

      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'MODIFY IPS';
			  
   ELSIF sa_value_pre LIKE '%1IP%' OR ( (sa_value_pre = 'WEB PRO' OR sa_value_pre = 'WEB MASTER') AND v_adsltype_pre LIKE '%STATIC%')
    AND ((sa_default_val = 'WEB MASTER' OR sa_default_val = 'WEB PRO') AND v_adsltype_new LIKE '%STATIC%')	
   THEN
   
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'REMOVE IPS';

      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ISSUE IPS';
			  
   ELSIF     (   sa_value_pre = 'HOME'
              OR sa_value_pre = 'OFFICE'
              OR sa_value_pre = 'OFFICE PLUS'
              OR sa_value_pre = 'XCEL'
              OR sa_value_pre = 'XCEL PLUS'
              OR sa_value_pre = 'XCITE'
              OR sa_value_pre = 'XCITE PLUS'
              OR sa_value_pre = 'ENTREE'
              OR sa_value_pre = 'HOME PLUS'
              OR sa_value_pre = 'WEB SURFER PLUS'
              OR sa_value_pre = 'WEB PRO PLUS'
              OR sa_value_pre = 'WEB MASTER PLUS'
              OR sa_value_pre = 'WEB MATE'
              OR sa_value_pre = 'WEB SURFER'
			  OR sa_value_pre = 'WEB FAMILY'
		      OR sa_value_pre = 'WEB STARTER'
		      OR sa_value_pre = 'WEB PAL'
		      OR sa_value_pre = 'WEB CHAMP'
		      OR sa_value_pre = 'WEB LIFE'
              OR ( (sa_value_pre = 'WEB PRO' OR sa_value_pre = 'WEB MASTER') AND v_adsltype_pre NOT LIKE '%STATIC%')
              OR sa_value_pre IS NULL)
         AND (   sa_default_val = 'HOME'
              OR sa_default_val = 'OFFICE'
              OR sa_default_val = 'OFFICE PLUS'
              OR sa_default_val = 'XCEL'
              OR sa_default_val = 'XCEL PLUS'
              OR sa_default_val = 'XCITE'
              OR sa_default_val = 'XCITE PLUS'
              OR sa_default_val = 'ENTREE'
              OR sa_default_val = 'HOME PLUS'
              OR sa_default_val = 'WEB SURFER PLUS'
              OR sa_default_val = 'WEB PRO PLUS'
              OR sa_default_val = 'WEB MASTER PLUS'
              OR sa_default_val = 'WEB MATE'
              OR sa_default_val = 'WEB SURFER'
			  OR sa_default_val = 'WEB FAMILY'
		      OR sa_default_val = 'WEB STARTER'
		      OR sa_default_val = 'WEB PAL'
		      OR sa_default_val = 'WEB CHAMP'
		      OR sa_default_val = 'WEB LIFE'
              OR ((sa_default_val = 'WEB MASTER' OR sa_default_val = 'WEB PRO') AND v_adsltype_new NOT LIKE '%STATIC%')
			  )
   THEN
   
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'REMOVE IPS';

      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ISSUE IPS';

      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'MODIFY IPS';
			  
   ELSIF     sa_value_pre LIKE '%1IP%' OR ( (sa_value_pre = 'WEB PRO' OR sa_value_pre = 'WEB MASTER') AND v_adsltype_pre LIKE '%STATIC%')
         AND (   sa_default_val = 'HOME'
              OR sa_default_val = 'OFFICE'
              OR sa_default_val = 'OFFICE PLUS'
              OR sa_default_val = 'XCEL'
              OR sa_default_val = 'XCEL PLUS'
              OR sa_default_val = 'XCITE'
              OR sa_default_val = 'XCITE PLUS'
              OR sa_default_val = 'ENTREE'
              OR sa_default_val = 'HOME PLUS'
              OR sa_default_val = 'WEB SURFER PLUS'
              OR sa_default_val = 'WEB PRO PLUS'
              OR sa_default_val = 'WEB MASTER PLUS'
              OR sa_default_val = 'WEB MATE'
              OR sa_default_val = 'WEB SURFER'
			  OR sa_default_val = 'WEB FAMILY'
		      OR sa_default_val = 'WEB STARTER'
		      OR sa_default_val = 'WEB PAL'
		      OR sa_default_val = 'WEB CHAMP'
		      OR sa_default_val = 'WEB LIFE'
              OR ((sa_default_val = 'WEB MASTER' OR sa_default_val = 'WEB PRO') AND v_adsltype_new NOT LIKE '%STATIC%')
             )
   THEN
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ISSUE IPS';

      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'MODIFY IPS';
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to REMOVE IPS . Please check the  Task attributes:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                      'Failed to Remove the IP task. Please check the  Task : '
                   || sa_default_val
                   || sa_value_pre
                  );
END ADSL_MODIFY_SPEED_REMOVE_IP;

-- 10-06-2009  Jayan Liyanage

-- 16-06-2009  Jayan Liyanage  


PROCEDURE ADSL_SUSPEND_ATT_CHANG (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2)   IS


-- Change Part******** Start 2013/09/16

cursor max_suspend is
select so.sero_id,so.SERO_ORDT_TYPE
from service_orders so,circuits ci
Where ci.CIRT_NAME = so.SERO_CIRT_NAME
And ci.CIRT_SERT_ABBREVIATION = 'ADSL'
and ci.cirt_serv_id = p_serv_id
AND so.SERO_COMPLETION_DATE  = ( select max(s.SERO_COMPLETION_DATE)
from service_orders s
where s.SERO_SERT_ABBREVIATION = 'ADSL'
And s.SERO_STAS_ABBREVIATION = 'CLOSED'
and s.sero_cirt_name = ci.cirt_name
and s.sero_serv_id = ci.cirt_serv_id
and ci.cirt_serv_id = p_serv_id );

-- Change Part******** End  2013/09/16


/*cursor max_suspend is
select so.sero_id,so.SERO_ORDT_TYPE
from service_orders so,circuits ci
Where ci.CIRT_NAME = so.SERO_CIRT_NAME
And ci.CIRT_SERT_ABBREVIATION = 'ADSL'
and so.SERO_SERV_ID = p_serv_id
AND so.SERO_COMPLETION_DATE  = ( select max(s.SERO_COMPLETION_DATE)
from service_orders s
where s.SERO_SERT_ABBREVIATION = 'ADSL'
And s.SERO_STAS_ABBREVIATION = 'CLOSED'
and s.SERO_SERV_ID = p_serv_id);*/


pre_soid varchar2(1000);
pre_so_type varchar2(100);

BEGIN

OPEN max_suspend;
FETCH max_suspend INTO PRE_SOID,pre_so_type;
CLOSE max_suspend;

DECLARE

  CURSOR  Cur_Service_Feat  IS
  SELECT SOA.SOFE_FEATURE_NAME,SOA.SOFE_PREV_VALUE
  FROM SERVICE_ORDER_FEATURES SOA
  WHERE SOA.SOFE_SERO_ID = pre_soid;


v_Pre_So_feat_Name varchar2(100);
v_pre_so_Value     varchar2(100);

BEGIN

IF PRE_SO_TYPE = 'SUSPEND'  THEN

  OPEN Cur_Service_Feat;
  LOOP
  FETCH  Cur_Service_Feat INTO v_Pre_So_feat_Name,v_pre_so_Value;
  EXIT WHEN Cur_Service_Feat%NOTFOUND;


  UPDATE SERVICE_ORDER_FEATURES SOF
     SET SOF.SOFE_PREV_VALUE = v_pre_so_Value
   WHERE SOF.SOFE_FEATURE_NAME = v_Pre_So_feat_Name
    AND SOF.SOFE_SERO_ID = p_sero_id;

END LOOP;
CLOSE  Cur_Service_Feat;

END IF;

END;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


p_ret_msg  := 'Failed to ADSL Feature Mapping . Please ADSL Features:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
,'Failed to ADSL Feature Mapping . Please ADSL Features:' || p_sero_id);




END ADSL_SUSPEND_ATT_CHANG;

-- 16-06-2009  Jayan Liyanage

-- 22-06-2009  Jayan Liyanage

 PROCEDURE ADSL_SUSPEND_SO_ATT_CHANG (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) IS


          CURSOR SO_FEA_SWITCH_cur  IS
          SELECT SOF.SFEA_FEATURE_NAME,SOF.SFEA_VALUE
          FROM SERVICES_FEATURES sof
          WHERE SOF.SFEA_TYPE = 'SWITCH'
          AND SOF.SFEA_SERV_ID = p_serv_id;

          CURSOR NEW_SO IS
          SELECT SO.SERO_ORDT_TYPE
          FROM SERVICE_ORDERS SO
          WHERE SO.SERO_ID = p_sero_id;

         New_So_type varchar2(100);
         v_so_type   varchar2(100);
         v_swich     varchar2(100);

                            BEGIN



                              OPEN NEW_SO;
                              FETCH NEW_SO INTO New_So_type;
                              CLOSE NEW_SO;

                                                            open SO_FEA_SWITCH_cur ;

                                                            loop

                                                                    fetch SO_FEA_SWITCH_cur into v_so_type,v_swich;
                                                                     exit when SO_FEA_SWITCH_cur%notfound;



                                                                  IF    New_So_type = 'SUSPEND'  THEN

                                                                     IF v_so_type = 'IPTV' AND v_swich = 'Y' THEN

                                                                                UPDATE SERVICE_ORDER_FEATURES SOF
                                                                                --SET SOF.SOFE_PREV_VALUE = 'N'
                                                                                SET SOF.SOFE_DEFAULTVALUE = 'N'
                                                                                WHERE SOF.SOFE_FEATURE_NAME = 'IPTV'
                                                                                AND SOF.SOFE_SERO_ID = p_sero_id;

                                                                     ELSIF v_so_type = 'TSTV' AND v_swich = 'Y' THEN

                                                                                UPDATE SERVICE_ORDER_FEATURES SOF
                                                                                --SET SOF.SOFE_PREV_VALUE = 'N'
                                                                                SET SOF.SOFE_DEFAULTVALUE = 'N'
                                                                                WHERE SOF.SOFE_FEATURE_NAME = 'TSTV'
                                                                                AND SOF.SOFE_SERO_ID = p_sero_id;

                                                                    ELSIF v_so_type = 'VIDEO ON DEMAND' AND v_swich = 'Y' THEN

                                                                                UPDATE SERVICE_ORDER_FEATURES SOF
                                                                                --SET SOF.SOFE_PREV_VALUE = 'N'
                                                                                SET SOF.SOFE_DEFAULTVALUE = 'N'
                                                                                WHERE SOF.SOFE_FEATURE_NAME = 'VIDEO ON DEMAND'
                                                                                AND SOF.SOFE_SERO_ID = p_sero_id;

                                                                    END IF;

                                                                 END IF;




                                                     END LOOP;

                                                        CLOSE SO_FEA_SWITCH_cur;

                                p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');





                    EXCEPTION
                    WHEN OTHERS THEN


                    p_ret_msg  := 'Failed to MODIFY PRICE PLAN . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

                    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

                    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
                    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
                    , 'Failed to Change MODIFY PRICE PLAN. Please check the Customer TYPE Attributes: ' || p_sero_id);











END ADSL_SUSPEND_SO_ATT_CHANG;

-- 22-06-2009  Jayan Liyanage

-- 30-06-2009 Gihan Amarasinghe

PROCEDURE  SET_DATA_ID_NUMBER_TOSOATTR(
                p_serv_id             IN     Services.serv_id%type,
                            p_sero_id              IN     Service_Orders.sero_id%type,
                            p_seit_id                IN     Service_Implementation_Tasks.seit_id%type,
                            p_impt_taskname        IN     Implementation_Tasks.impt_taskname%type,
                            p_woro_id            IN     work_order.woro_id%TYPE,
                            p_ret_char            out    varchar2,
                            p_ret_number        out    number,
                            p_ret_msg               OUT    Varchar2) is

    l_number            varchar2(100);
    cursor numb_cur is
     select numb_nucc_code || numb_number
      from numbers, number_status
        where numb_serv_id = p_serv_id
          and numb_nums_id = nums_id
          and nums_before_code like 'RESERVED%';


  begin

    P_dynamic_procedure.complete_resrve_number_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);

    IF p_ret_msg IS NULL THEN

       open numb_cur;
       fetch numb_cur into l_number;
       close numb_cur;

      if l_number is not null then
        UPDATE service_order_attributes
            SET seoa_defaultvalue = 'D' || l_number
          WHERE seoa_sero_id = p_sero_id
            AND seoa_name = 'DATA CIRCUIT ID';
      end if;
    ELSE
          p_ret_msg := p_ret_msg || ' Invalid Number. Reserved number not available.';
    END IF;

  exception
    when others then
      p_ret_msg  := 'Failed to Find the set_DATA_number_SO ATTR:' || to_char(sqlcode) ||'-'|| sqlerrm;

  end SET_DATA_ID_NUMBER_TOSOATTR;

-- 30-06-2009 Gihan Amarasinghe


-- 06-10-2009 Jayan Liyanage

 PROCEDURE PSTN_CAB_DP_LOOP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) IS





CURSOR Cir_name is
SELECT so.SERO_CIRT_NAME
FROM SERVICE_ORDERS SO
WHERE so.SERO_ID = p_sero_id;









v_dp         varchar2(100);
v_position   varchar2(100);
v_cable_code varchar2(100);
v_Cable_numb varchar2(100);
v_cir        varchar2(100);
v_err        varchar2(100);

          BEGIN


        OPEN Cir_name;
        FETCH Cir_name INTO v_cir;
        CLOSE Cir_name;


                        DECLARE



                                    CURSOR  Cab_dp_loop is
                                    SELECT  fu.FRAU_NAME,FA.FRAA_POSITION
                                    FROM FRAME_APPEARANCES FA,FRAME_CONTAINERS FC,FRAME_UNITS FU,CIRCUITS CI
                                    WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
                                    AND FU.FRAU_FRAC_ID = FC.FRAC_ID
                                    AND FA.FRAA_CIRT_NAME = CI.CIRT_NAME
                                    AND FA.FRAA_SIDE = 'REAR'
                                    AND FC.FRAC_FRAN_NAME = 'DP'
                                    AND CI.CIRT_NAME = v_cir;

                                    CURSOR Cable_Code is
                                    SELECT SUBSTR(cs.CABS_NAME, INSTR(cs.CABS_NAME,'-', 1, 1)+1,
                                    INSTR(cs.CABS_NAME,'-',1,2)-INSTR(cs.CABS_NAME,'-',1,1)-1) as code,CC.CABC_NUMBER
                                    FROM FRAME_APPEARANCES FA,FRAME_CONTAINERS FC,FRAME_UNITS FU,cable_sheaths cs,cable_cores cc,cable_core_ends cce
                                    WHERE cs.CABS_ID=cc.CABC_CABS_ID
                                    and cc.CABC_ID=cce.CACE_CABC_ID
                                    and cce.CACE_ID=fa.FRAA_CACE_ID
                                    and FA.FRAA_FRAU_ID = FU.FRAU_ID
                                    AND FU.FRAU_FRAC_ID = FC.FRAC_ID
                                    and cs.CABS_CAST_TYPE LIKE 'PRIMARY%'
                                    AND FA.FRAA_SIDE = 'REAR'
                                    and fc.FRAC_FRAN_NAME = 'MDF'
                                    AND FU.FRAU_NAME LIKE '%UG%'
                                    AND FA.FRAA_CIRT_NAME = v_cir;

                        BEGIN

                            OPEN Cab_dp_loop;
                            FETCH Cab_dp_loop INTO v_dp,v_position;
                            CLOSE Cab_dp_loop;

                            OPEN Cable_Code;
                            FETCH Cable_Code INTO v_cable_code,v_Cable_numb;
                            CLOSE Cable_Code;


                                  v_err := v_dp||'-'||v_position|| '   ' ||v_cable_code ||'-'||v_Cable_numb;



                               UPDATE  SERVICE_ORDER_ATTRIBUTES SOA
                               SET  SOA.SEOA_DEFAULTVALUE = v_err
                               WHERE SOA.SEOA_NAME = 'SA_CAB_DP_LOOP_CABLE'
                               AND SOA.SEOA_SERO_ID = p_sero_id;

                                   p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



                        END;



                            EXCEPTION
                            WHEN OTHERS THEN


                            p_ret_msg  := 'Failed to SA_CAB_DP_LOOP Attribute Update . Please check the SA_CAB_DP_LOOP Attribute:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

                                    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

                            INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
                          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
                          , p_ret_msg  || p_sero_id);





END PSTN_CAB_DP_LOOP;



-- 06-10-2009 Jayan Liyanage


-- 29-06-2009 Samankula Owitipana
-- ADSL_CREATE_PSTN_CCT_AUTO_BUILD

PROCEDURE ADSL_CREATE_PSTN_CCT_AUTO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_ADSL_CCT_ID service_Orders.SERO_CIRT_NAME%TYPE;
v_PSTN_CCT circuits.CIRT_NAME%TYPE;
v_PSTN_NO SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_CHK_NGN ports.PORT_CARD_SLOT%TYPE;


v_plp_ex port_link_ports.POLP_PORL_ID%TYPE;
v_plp_ex_1c port_link_ports.POLP_COMMONPORT%TYPE;
v_pl_seq_ex port_links.PORL_SEQUENCE%TYPE;
v_pl_fraa_ex port_link_ports.POLP_FRAA_ID%TYPE;

v_plp_ug port_link_ports.POLP_PORL_ID%TYPE;
v_plp_ug_1c port_link_ports.POLP_COMMONPORT%TYPE;
v_pl_seq_ug port_links.PORL_SEQUENCE%TYPE;
v_pl_fraa_ug port_link_ports.POLP_FRAA_ID%TYPE;

v_po_equip_id ports.PORT_EQUP_ID%TYPE;
v_portname_adsl ports.PORT_NAME%TYPE;
v_po_cardslot_adsl ports.PORT_CARD_SLOT%TYPE;

v_P_PORT_ID ports.PORT_ID%TYPE;
v_P_PHYC_ID ports.PORT_PHYC_ID%TYPE;
v_P_CACE_ID ports.PORT_CACE_ID%TYPE;
v_P_CABC_ID CABLE_CORE_ENDS.CACE_CABC_ID%TYPE;


v_POTS_PORT_ID ports.PORT_ID%TYPE;
v_POTS_PHYC_ID ports.PORT_PHYC_ID%TYPE;
v_POTS_CACE_ID ports.PORT_CACE_ID%TYPE;
v_POTS_CABC_ID CABLE_CORE_ENDS.CACE_CABC_ID%TYPE;

v_POTS_FRAA_ID_REAR FRAME_APPEARANCES.FRAA_ID%TYPE;
v_POTS_FRAU_ID FRAME_APPEARANCES.FRAA_FRAU_ID%TYPE;
v_POTS_FRAA_POSITION FRAME_APPEARANCES.FRAA_POSITION%TYPE;
v_POTS_FRAA_ID_FRONT FRAME_APPEARANCES.FRAA_ID%TYPE;

v_P_FRAA_ID_REAR FRAME_APPEARANCES.FRAA_ID%TYPE;
v_P_FRAU_ID FRAME_APPEARANCES.FRAA_FRAU_ID%TYPE;
v_P_FRAA_POSITION FRAME_APPEARANCES.FRAA_POSITION%TYPE;
v_P_FRAA_ID_FRONT FRAME_APPEARANCES.FRAA_ID%TYPE;

v_pl_id_1 port_links.PORL_ID%TYPE;
v_pl_id_2 port_links.PORL_ID%TYPE;
v_pl_id_3 port_links.PORL_ID%TYPE;
v_pl_id_4 port_links.PORL_ID%TYPE;

v_CHK_P_PORT_ID ports.PORT_ID%TYPE;
v_CHK_POTS_PORT_ID ports.PORT_ID%TYPE;
v_CHK_P_FRAA_ID FRAME_APPEARANCES.FRAA_ID%TYPE;
v_CHK_POTS_FRAA_ID FRAME_APPEARANCES.FRAA_ID%TYPE;

v_CHK_PROPOSE ports.PORT_ID%TYPE;
v_PRO_CCT_ID circuits.CIRT_DISPLAYNAME%TYPE;


CURSOR PROPOSED_select_cur  IS
select ci.CIRT_DISPLAYNAME
from PORT_LINKS pl,PORT_LINK_PORTS plp,circuits ci
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and plp.POLP_PORT_ID = v_CHK_PROPOSE
and pl.PORL_CIRT_NAME <> v_ADSL_CCT_ID;

BEGIN



P_SERVICE_ORDER.SLT_SET_ADSL_EQIP_MODEL(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);




IF p_ret_msg is null THEN


SELECT so.SERO_CIRT_NAME
INTO v_ADSL_CCT_ID
FROM Service_Orders so
WHERE so.SERO_ID = p_sero_id;

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_PSTN_NO
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

SELECT ci.CIRT_NAME
INTO v_PSTN_CCT
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_PSTN_NO || '%'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');


select po.PORT_CARD_SLOT
into v_CHK_NGN
from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and plp.POLP_COMMONPORT = 'F'
and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;


  IF v_CHK_NGN like 'M%' or v_CHK_NGN like 'D%' THEN




    BEGIN


      IF v_CHK_NGN like 'M%' THEN

       select po.PORT_EQUP_ID,trim(replace(po.PORT_NAME,'P','')),replace(po.PORT_CARD_SLOT,'M','P'),po.PORT_ID
      INTO v_po_equip_id,v_portname_adsl,v_po_cardslot_adsl,v_CHK_PROPOSE
      from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp
      where pl.PORL_ID = plp.POLP_PORL_ID
      and plp.POLP_PORT_ID = po.PORT_ID
      and plp.POLP_COMMONPORT = 'F'
      and po.PORT_NAME like 'P%'
      and po.PORT_CARD_SLOT like 'M%'
      and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

      ELSE

      select po.PORT_EQUP_ID,trim(replace(po.PORT_NAME,'P','')),replace(po.PORT_CARD_SLOT,'D','P'),po.PORT_ID
      INTO v_po_equip_id,v_portname_adsl,v_po_cardslot_adsl,v_CHK_PROPOSE
      from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp
      where pl.PORL_ID = plp.POLP_PORL_ID
      and plp.POLP_PORT_ID = po.PORT_ID
      and plp.POLP_COMMONPORT = 'F'
      and po.PORT_NAME like 'P%'
      and po.PORT_CARD_SLOT like 'D%'
      and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

      END IF;



      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
      INTO v_plp_ex,v_plp_ex_1c,v_pl_seq_ex,v_pl_fraa_ex
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      and plp.POLP_PORL_ID = pl.PORL_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%EX%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND pl.PORL_CIRT_NAME = v_PSTN_CCT;



      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
      INTO v_plp_ug,v_plp_ug_1c,v_pl_seq_ug,v_pl_fraa_ug
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      and plp.POLP_PORL_ID = pl.PORL_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%UG%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND pl.PORL_CIRT_NAME = v_PSTN_CCT;






      select po.PORT_ID,cce.CACE_CABC_ID,cce.CACE_ID,cce.CACE_PHYC_ID
      into v_P_PORT_ID,v_P_CABC_ID,v_P_CACE_ID,v_P_PHYC_ID
      from ports po,CABLE_CORE_ENDS cce
      where po.PORT_PHYC_ID = cce.CACE_PHYC_ID
      and po.PORT_CACE_ID = cce.CACE_ID
      and po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'P' || v_portname_adsl;

      select po.PORT_ID,cce.CACE_CABC_ID,cce.CACE_ID,cce.CACE_PHYC_ID
      into v_POTS_PORT_ID,v_POTS_CABC_ID,v_POTS_CACE_ID,v_POTS_PHYC_ID
      from ports po,CABLE_CORE_ENDS cce
      where po.PORT_PHYC_ID = cce.CACE_PHYC_ID
      and po.PORT_CACE_ID = cce.CACE_ID
      and po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'POTS' || v_portname_adsl;


      select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
      into v_POTS_FRAA_ID_REAR,v_POTS_FRAU_ID,v_POTS_FRAA_POSITION
      from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
      where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
      and cce.CACE_ID = fa.FRAA_CACE_ID
      and cce.CACE_CABC_ID = v_POTS_CABC_ID
      and cce.CACE_PHYC_ID <> v_POTS_PHYC_ID
      and cce.CACE_ID <> v_POTS_CACE_ID;


     select fa.FRAA_ID
     into v_POTS_FRAA_ID_FRONT
     from FRAME_APPEARANCES fa
     where fa.FRAA_FRAU_ID = v_POTS_FRAU_ID
     and fa.FRAA_POSITION = v_POTS_FRAA_POSITION
     and fa.FRAA_SIDE = 'FRONT';

     select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
      into v_P_FRAA_ID_REAR,v_P_FRAU_ID,v_P_FRAA_POSITION
      from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
      where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
      and cce.CACE_ID = fa.FRAA_CACE_ID
      and cce.CACE_CABC_ID = v_P_CABC_ID
      and cce.CACE_PHYC_ID <> v_P_PHYC_ID
      and cce.CACE_ID <> v_P_CACE_ID;


     select fa.FRAA_ID
     into v_P_FRAA_ID_FRONT
     from FRAME_APPEARANCES fa
     where fa.FRAA_FRAU_ID = v_P_FRAU_ID
     and fa.FRAA_POSITION = v_P_FRAA_POSITION
     and fa.FRAA_SIDE = 'FRONT';




    EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := 'SET VARIABLES FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;

------------------Check for Proposed Ports----------------------------------------------------

    OPEN PROPOSED_select_cur;
    FETCH PROPOSED_select_cur INTO v_PRO_CCT_ID;
    CLOSE PROPOSED_select_cur;


    IF v_PRO_CCT_ID is not null THEN

    p_ret_msg  := 'THIS ADSL PORT IS RESERVED FOR ' || v_PRO_CCT_ID ||'. PLEASE RESERVE A FREE PORT';

    END IF;



--------------- Check Availability ------------------------------------------------------------

DECLARE

 cursor GET_P_PORT_ID is
 select distinct plp.POLP_PORT_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_PORT_ID = v_P_PORT_ID;

 cursor GET_POTS_PORT_ID is
 select distinct plp.POLP_PORT_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_PORT_ID = v_POTS_PORT_ID;

 cursor GET_P_FRAA_ID is
 select distinct plp.POLP_FRAA_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_FRAA_ID = v_P_FRAA_ID_FRONT;

 cursor GET_POTS_FRAA_ID is
 select distinct plp.POLP_FRAA_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_FRAA_ID = v_POTS_FRAA_ID_FRONT;

 BEGIN


    OPEN GET_P_PORT_ID;
    FETCH GET_P_PORT_ID INTO v_CHK_P_PORT_ID;
    CLOSE GET_P_PORT_ID;

    OPEN GET_POTS_PORT_ID;
    FETCH GET_POTS_PORT_ID INTO v_CHK_POTS_PORT_ID;
    CLOSE GET_POTS_PORT_ID;

    OPEN GET_P_FRAA_ID;
    FETCH GET_P_FRAA_ID INTO v_CHK_P_FRAA_ID;
    CLOSE GET_P_FRAA_ID;

    OPEN GET_P_FRAA_ID;
    FETCH GET_P_FRAA_ID INTO v_CHK_POTS_FRAA_ID;
    CLOSE GET_P_FRAA_ID;

 END;

----------------------------------------------------------------------------------------------


 IF    v_CHK_P_PORT_ID is null AND v_CHK_POTS_PORT_ID is null AND v_CHK_P_FRAA_ID is null AND v_CHK_POTS_FRAA_ID is null THEN


    BEGIN

         IF v_plp_ug_1c = 'F' THEN



         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+1, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+2, 'LOGICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+3, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+4, 'JUMPER', NULL, 'Y');


        ELSE


         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+1, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+2, 'LOGICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+3, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+4, 'JUMPER', NULL, 'Y');


       END IF;






    EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := p_ret_msg || 'PORT LINK INSERT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;


 IF v_plp_ug_1c = 'F' THEN


 select pl.PORL_ID
 into v_pl_id_1
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+1;

 select pl.PORL_ID
 into v_pl_id_2
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+2;

 select pl.PORL_ID
 into v_pl_id_3
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+3;

 select pl.PORL_ID
 into v_pl_id_4
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+4;


 ELSE


 select pl.PORL_ID
 into v_pl_id_1
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+1;

 select pl.PORL_ID
 into v_pl_id_2
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+2;

 select pl.PORL_ID
 into v_pl_id_3
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+3;

 select pl.PORL_ID
 into v_pl_id_4
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+4;

 END IF;


      BEGIN



     IF v_plp_ug_1c = 'F' THEN




     UPDATE PORT_LINK_PORTS
     SET POLP_FRAA_ID = v_P_FRAA_ID_FRONT
     WHERE POLP_PORL_ID = v_plp_ug
     AND POLP_COMMONPORT = 'T';


    INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_1, 'F', v_P_FRAA_ID_REAR);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_1, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_2, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_2, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_3, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_3, 'T',v_POTS_FRAA_ID_REAR );

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'F',v_POTS_FRAA_ID_FRONT );


    INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'T',v_pl_fraa_ex );





     ELSE

    UPDATE PORT_LINK_PORTS
     SET POLP_FRAA_ID = v_POTS_FRAA_ID_FRONT
     WHERE POLP_PORL_ID = v_plp_ex
     AND POLP_COMMONPORT = 'T';

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_1, 'F',v_POTS_FRAA_ID_REAR );


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_1, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_2, 'F', NULL);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_2, 'T', NULL);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_3, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_3, 'T',v_P_FRAA_ID_REAR );

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'F',v_P_FRAA_ID_FRONT);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'T', v_pl_fraa_ug);





     END IF;

      update ports po
      set po.PORT_CIRT_NAME = v_PSTN_CCT
      where po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'P' || v_portname_adsl;


      update ports po
      set po.PORT_CIRT_NAME = v_PSTN_CCT
      where po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'POTS' || v_portname_adsl;


     update FRAME_APPEARANCES fa
     set fa.FRAA_CIRT_NAME = v_PSTN_CCT
     where fa.FRAA_FRAU_ID = v_POTS_FRAU_ID
     and fa.FRAA_POSITION = v_POTS_FRAA_POSITION;


     update FRAME_APPEARANCES fa
     set fa.FRAA_CIRT_NAME = v_PSTN_CCT
     where fa.FRAA_FRAU_ID = v_P_FRAU_ID
     and fa.FRAA_POSITION = v_P_FRAA_POSITION;



     EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := p_ret_msg || 'PORT LINK PORT INSERT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;

  ELSIF v_CHK_P_PORT_ID is not null AND v_CHK_POTS_PORT_ID is not null AND v_CHK_P_FRAA_ID is not null AND v_CHK_POTS_FRAA_ID is not null THEN

  NULL;

  ELSE

  p_ret_msg  := 'WRONG ADSL CROSSCONNECTION IN PSTN CCT';

  END IF;

 END IF;

ELSE

      p_ret_msg := p_ret_msg || ' Failed to UPDATE ADSL_EQUIP_MODEL.';

END IF;







EXCEPTION
WHEN OTHERS THEN


    p_ret_msg  := 'PSTN CCT ADD CROSS CONNECTIONS FAILED. CHECK SA_PSTN_NUMBER ATTRIBUTE AND PSTN CIRCUIT' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END ADSL_CREATE_PSTN_CCT_AUTO;

-- 29-06-2009 Samankula Owitipana


-- 01-09-2009 Jayan Liyanage


PROCEDURE SLT_IPTV_DSP_ZERO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

CURSOR IPTV_FETUR_CUR IS
SELECT SF.SOFE_DEFAULTVALUE
FROM SERVICE_ORDER_FEATURES SF
WHERE SF.SOFE_SERO_ID = p_sero_id
AND SF.SOFE_FEATURE_NAME = 'IPTV';


CURSOR Cur_Ser_Impl_Task is
SELECT SIT.SEIT_TASKNAME
FROM SERVICE_IMPLEMENTATION_TASKS SIT
WHERE SIT.SEIT_SERO_ID = p_sero_id;




V_IPTV_VAL VARCHAR2(100);
V_Task_Name varchar2(100);




BEGIN

OPEN IPTV_FETUR_CUR;
FETCH IPTV_FETUR_CUR INTO V_IPTV_VAL;
CLOSE IPTV_FETUR_CUR;


OPEN Cur_Ser_Impl_Task;
LOOP
     FETCH Cur_Ser_Impl_Task INTO V_Task_Name;
      EXIT WHEN Cur_Ser_Impl_Task%NOTFOUND;

                     IF V_IPTV_VAL = 'Y' and ( V_Task_Name = 'STB INSTALLATION' OR V_Task_Name ='INSTALL SET TOP BOX') THEN


                             UPDATE SERVICE_ORDER_ATTRIBUTES soa
                             SET soa.SEOA_DEFAULTVALUE = ''
                             WHERE soa.SEOA_SERO_ID = p_sero_id
                             AND soa.SEOA_NAME = 'ACTUAL_DSP_DATE';



                     END IF;
END LOOP;




    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

  p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := '' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

  INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
  SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
  , p_ret_msg);

END SLT_IPTV_DSP_ZERO;

-- 14-07-2009 Jayan Liyanage



-- 14-07-2009 Dilupa Alahakoon

PROCEDURE MODIFY_NUMBER_DIFF_EXCHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) is


CURSOR CUR_SA_EXCHANGE IS
SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE
FROM SERVICE_ORDERS SO,SERVICE_ORDER_ATTRIBUTES SOA
WHERE SO.SERO_ID = SOA.SEOA_SERO_ID
AND SO.SERO_ORDT_TYPE = 'MODIFY-NUMBER'
AND SO.SERO_SERT_ABBREVIATION = 'PSTN'
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE'
AND SO.SERO_ID =  p_sero_id ;


SA_VALUE_PRE VARCHAR2(10);
SA_DEFAULT_VAL VARCHAR2(10);


BEGIN

    OPEN CUR_SA_EXCHANGE;
    FETCH CUR_SA_EXCHANGE INTO SA_DEFAULT_VAL,SA_VALUE_PRE;
    CLOSE CUR_SA_EXCHANGE;

           IF SA_DEFAULT_VAL = SA_VALUE_PRE THEN

             DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
             WHERE SIT.SEIT_SERO_ID =  p_sero_id
             AND SIT.SEIT_TASKNAME = 'WO FOR MDF';


           END IF;

                     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

    EXCEPTION

        WHEN OTHERS THEN


         p_ret_msg  := 'Failed to REMOVE IPS . Please check the  Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change ASSIGN FIREWALL PORT. Please check the  Attributes: ' ||SA_DEFAULT_VAL ||SA_VALUE_PRE );


END MODIFY_NUMBER_DIFF_EXCHANGE;

--01-09-2009 Dilupa Alahakoon


-- 15-07-2009 Jayan Liyanage

PROCEDURE MODIFY_SER_DISABLE_INTERNET  (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) IS



CURSOR Cir_Dis_Name is
SELECT CI.CIRT_DISPLAYNAME
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND SO.SERO_ID = p_sero_id;


V_cir_dis varchar2(100);

  BEGIN

  OPEN Cir_Dis_Name;
  FETCH Cir_Dis_Name INTO V_cir_dis;
  CLOSE Cir_Dis_Name;

                        DECLARE

                        CURSOR Cur_Def_Value_DIS is
                        SELECT SOF.SOFE_DEFAULTVALUE
                        FROM SERVICE_ORDERS SO,SERVICE_ORDER_FEATURES SOF
                        WHERE SO.SERO_ID = SOF.SOFE_SERO_ID
                        AND SO.SERO_ORDT_TYPE = 'MODIFY-SERVICE'
                        AND SO.SERO_SERT_ABBREVIATION = 'ADSL'
                        AND SOF.SOFE_TYPE = 'NON-SWITCH'
                        AND SO.SERO_ID = p_sero_id
                        AND SOF.SOFE_FEATURE_NAME = V_cir_dis;

                        CURSOR Cur_Def_Value_INT is
                        SELECT SOF.SOFE_DEFAULTVALUE
                        FROM SERVICE_ORDERS SO,SERVICE_ORDER_FEATURES SOF
                        WHERE SO.SERO_ID = SOF.SOFE_SERO_ID
                        AND SO.SERO_ORDT_TYPE = 'MODIFY-SERVICE'
                        AND SO.SERO_SERT_ABBREVIATION = 'ADSL'
                        AND SOF.SOFE_TYPE = 'NON-SWITCH'
                        AND SOF.SOFE_FEATURE_NAME = 'INTERNET'
                        AND SO.SERO_ID = p_sero_id;


                        V_Cir_value varchar2(100);
                        V_INTER_val varchar2(100);


                        BEGIN

                          OPEN Cur_Def_Value_DIS;
                          FETCH Cur_Def_Value_DIS INTO V_Cir_value;
                          CLOSE Cur_Def_Value_DIS;

                          OPEN Cur_Def_Value_INT;
                          FETCH Cur_Def_Value_INT INTO V_INTER_val;
                          CLOSE Cur_Def_Value_INT;



                          IF V_Cir_value = 'N' AND V_INTER_val = 'N' THEN

                              DELETE SERVICE_IMPLEMENTATION_TASKS SIT
                              WHERE SIT.SEIT_SERO_ID =  p_sero_id
                              AND SIT.SEIT_TASKNAME = 'QUERY USER PASSWORD';

                              DELETE SERVICE_IMPLEMENTATION_TASKS SIT
                              WHERE SIT.SEIT_SERO_ID = p_sero_id
                              AND SIT.SEIT_TASKNAME = 'RESERVE USER NAME';

                              DELETE SERVICE_IMPLEMENTATION_TASKS SIT
                              WHERE SIT.SEIT_SERO_ID =  p_sero_id
                              AND SIT.SEIT_TASKNAME = 'ACTIVATE LDAP';



                          END IF;

                           p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



                            EXCEPTION
                            WHEN OTHERS THEN


                                p_ret_msg  := 'Failed to MODIFY-SERVICE Feature Pass . Please check the Service Order Feature  Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

                                p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

                                INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
                                SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
                                , 'Failed to Change MODIFY PRICE PLAN. Please check the Customer TYPE Attributes: ' || p_sero_id);

                        END;






   END MODIFY_SER_DISABLE_INTERNET;


-- 15-07-2009 Jayan Liyanage




-- 06-10-2009 Jayan Liyanage

PROCEDURE DATA_CIRCUITS_CROSSCON_DELETE  (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) IS


Cursor Cur_So_Cir_Name is
SELECT SO.SERO_CIRT_NAME
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;


v_Cir_Dis       varchar2(100);

BEGIN

OPEN Cur_So_Cir_Name;
FETCH Cur_So_Cir_Name INTO v_Cir_Dis;
CLOSE Cur_So_Cir_Name;



DECLARE

  cursor Cur_Por is
  SELECT DISTINCT PLP.POLP_PORT_ID,PLP.POLP_FRAA_ID,PL.PORL_CIRT_NAME
  FROM PORT_LINKS PL,PORT_LINK_PORTS PLP
  WHERE PL.PORL_ID = PLP.POLP_PORL_ID
  AND PL.PORL_CIRT_NAME = v_Cir_Dis;

      v_Port_ID             varchar2(100);
      v_Frame_App_Id        varchar2(100);
      v_Cir_Name            varchar2(100);

BEGIN

      open Cur_Por;
           loop

           fetch Cur_Por into v_Port_ID,v_Frame_App_Id,v_Cir_Name;
                 exit when Cur_Por%notfound;




                 UPDATE  ports po
                 SET PO.PORT_CIRT_NAME = NULL
                 WHERE  po.port_id = v_Port_ID;


                 UPDATE  FRAME_APPEARANCES FA
                 SET FA.FRAA_CIRT_NAME = NULL
                 WHERE FA.FRAA_ID = v_Frame_App_Id;



          end loop;
     close Cur_Por;

                  DELETE PORT_LINK_PORTS PLW
                  WHERE PLW.POLP_PORL_ID  IN (
                  SELECT PL.PORL_ID
                  FROM CIRCUITS C ,PORT_LINKS PL,PORT_LINK_PORTS PLP
                  WHERE  C.CIRT_NAME = PL.PORL_CIRT_NAME
                  AND PL.PORL_ID = PLP.POLP_PORL_ID
                  and C.CIRT_NAME =v_Cir_Name);




                   DELETE PORT_LINKS PL
                   WHERE PL.PORL_ID  in (select PL.PORL_ID
                   from circuits ci,PORT_LINKS PL
                   where ci.CIRT_NAME = pl.PORL_CIRT_NAME
                   and ci.CIRT_NAME = v_Cir_Name);






                      END;


                 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



   EXCEPTION
     WHEN OTHERS THEN


          p_ret_msg  := 'Unable To Delete Data Service CrossConnections Please Check' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

          p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

           INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
           SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
           , 'Unable To Delete Data Service CrossConnections Please Check This Service Order : ' || p_sero_id);


 END;


-- 06-10-2009 Jayan Liyanage


-- 06-10-2009 Samankula Owitipana

PROCEDURE IPVPN_MODIFY_IPS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR lanip_select_cur  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE),trim(SOA.SEOA_PREV_VALUE)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'LAN IP';

v_NEW_VALUE SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_OLD_VALUE SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

BEGIN

OPEN lanip_select_cur;
FETCH lanip_select_cur INTO v_NEW_VALUE , v_OLD_VALUE ;
CLOSE lanip_select_cur;




           IF  nvl(v_NEW_VALUE,0) = nvl(v_OLD_VALUE,0) THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY LAN IP' ;

         ELSIF nvl(v_NEW_VALUE,0) <> nvl(v_OLD_VALUE,0) THEN

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY WAN IP' ;


         END IF;





    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to do TASK REMOVAL:' || v_NEW_VALUE || ' ' || v_OLD_VALUE || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg );

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


END IPVPN_MODIFY_IPS;

-- 06-10-2009 Samankula Owitipana

-- 13-11-2009 Jayan Liyanage

  PROCEDURE SLT_CREATE_TRANSFER_BIZ_DSL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




      CURSOR cust_type_cur  IS
      SELECT cu.cusr_cutp_type
      FROM SERVICE_ORDERS SO,CUSTOMER cu
      WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
      AND so.SERO_ID = p_sero_id;

      CURSOR Cur_Dsl_Interface  IS
      SELECT SOA.SEOA_DEFAULTVALUE
      FROM SERVICE_ORDER_ATTRIBUTES SOA
      WHERE SOA.SEOA_SERO_ID = p_sero_id
      AND SOA.SEOA_NAME = 'DSL INTERFACE TYPE';

      CURSOR Cur_Area_sw_code  IS
      SELECT SOA.SEOA_DEFAULTVALUE
      FROM SERVICE_ORDER_ATTRIBUTES SOA
      WHERE SOA.SEOA_SERO_ID = p_sero_id
      AND SOA.SEOA_NAME = 'SW CODE';


      CURSOR Cur_Old_Cir_Id  IS
      SELECT SOA.SEOA_DEFAULTVALUE
      FROM SERVICE_ORDER_ATTRIBUTES SOA
      WHERE SOA.SEOA_SERO_ID = p_sero_id
      AND SOA.SEOA_NAME = 'OLD CIRCUIT ID';

      CURSOR Cur_New_Cir_Name IS
      SELECT REPLACE(CI.CIRT_DISPLAYNAME,'(N)')
      FROM SERVICE_ORDERS SO,CIRCUITS CI
      WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
      AND SO.SERO_ID = p_sero_id;


      v_customer_type     VARCHAR2(100);
      v_Dsl_Interface     VARCHAR2(100);
      v_area_Sw_Code      VARCHAR2(100);
      v_Old_Cir_Id        VARCHAR2(100);
      v_New_Cir_Name      VARCHAR2(100);

      BEGIN

      OPEN cust_type_cur;
      FETCH cust_type_cur INTO v_customer_type;
      CLOSE cust_type_cur;

      OPEN Cur_Dsl_Interface;
      FETCH Cur_Dsl_Interface INTO v_Dsl_Interface;
      CLOSE Cur_Dsl_Interface;

      OPEN Cur_Area_sw_code;
      FETCH Cur_Area_sw_code INTO v_area_Sw_Code;
      CLOSE Cur_Area_sw_code;


      OPEN Cur_Old_Cir_Id;
      FETCH Cur_Old_Cir_Id INTO v_Old_Cir_Id;
      CLOSE Cur_Old_Cir_Id;


      OPEN Cur_New_Cir_Name;
      FETCH Cur_New_Cir_Name INTO v_New_Cir_Name;
      CLOSE Cur_New_Cir_Name;

      BEGIN



      UPDATE CIRCUITS CI
      SET CI.CIRT_COMMENT = NULL
      WHERE CI.CIRT_DISPLAYNAME = v_Old_Cir_Id;



      UPDATE CIRCUITS CI
      SET CI.CIRT_COMMENT = 'PART OF THE NETWORK RESOURSES WERE USED FOR THE NEW CIRCUITS  '||v_New_Cir_Name
      WHERE CI.CIRT_DISPLAYNAME = v_Old_Cir_Id;

      UPDATE CIRCUITS CI
      SET CI.CIRT_COMMENT = NULL
      WHERE CI.CIRT_DISPLAYNAME LIKE v_New_Cir_Name||'%';

      UPDATE CIRCUITS CI
      SET CI.CIRT_COMMENT = 'NETWORK RESOURSES USED FROM OLD CIRCUITS '||v_Old_Cir_Id
      WHERE CI.CIRT_DISPLAYNAME LIKE v_New_Cir_Name||'%';


        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

      EXCEPTION
             WHEN OTHERS THEN


              p_ret_msg  := 'Failed to Update Circuits Comments Field ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

              p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

              INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
              SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
              , 'Failed to Update Circuits Comments Field ' || v_New_Cir_Name);


      END;

      BEGIN

            IF UPPER(v_Dsl_Interface) = UPPER('DSLAM') THEN

            UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
            SET sit.SEIT_WORG_NAME = 'CEN-ADSL'
            WHERE SIT.SEIT_SERO_ID =  p_sero_id
            AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT';

            ELSIF UPPER(v_Dsl_Interface) = UPPER('MSAN')  THEN

            UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
            SET sit.SEIT_WORG_NAME = (SELECT AW.ARWG_WORG_NAME
                                     FROM AREAS AR,AREA_WORKGROUPS  AW
                                     WHERE AR.AREA_CODE = AW.ARWG_AREA_CODE
                                     AND AW.ARWG_SERT_ABBREVIATION = 'PSTN'
                                     AND AR.AREA_CODE = v_area_Sw_Code)
            WHERE SIT.SEIT_SERO_ID = p_sero_id
            AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT';


            UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
            SET sit.SEIT_WORG_NAME = (SELECT AW.ARWG_WORG_NAME
                                     FROM AREAS AR,AREA_WORKGROUPS  AW
                                     WHERE AR.AREA_CODE = AW.ARWG_AREA_CODE
                                     AND AW.ARWG_SERT_ABBREVIATION = 'PSTN'
                                     AND AR.AREA_CODE = v_area_Sw_Code)
            WHERE SIT.SEIT_SERO_ID = p_sero_id
            AND SIT.SEIT_TASKNAME = 'CONFIGURE VOICE PORT';

            END IF;

            p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

      EXCEPTION
             WHEN OTHERS THEN


              p_ret_msg  := 'Failed to Change  DSL Interface in UPDATE CIRCUITS task:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

              p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

              INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
              SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
              , 'Failed to Change  DSL Interface in UPDATE CIRCUITS Task:' || v_customer_type);


      END;



      BEGIN

         IF v_customer_type = 'CORPORATE'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSIF v_customer_type = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         END IF;


             p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

         EXCEPTION
             WHEN OTHERS THEN


              p_ret_msg  := 'Failed to Change  in ISSUE DEL-TRNSFER SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

              p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

              INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
              SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
              , 'Failed to Change  in ISSUE DEL-TRNSFER SO. Please check the Customer TYPE Attributes:' || v_customer_type);


      END ;






      END SLT_CREATE_TRANSFER_BIZ_DSL;

-- 13-11-2009 Jayan Liyanage


-- 13-11-2009 Jayan Liyanage

  PROCEDURE SLT_D_IPVPN_DELETE_TRANSFER (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



      CURSOR cust_type_cur  IS
      SELECT cu.cusr_cutp_type
      FROM SERVICE_ORDERS SO,CUSTOMER cu
      WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
      AND so.SERO_ID = p_sero_id;

      v_customer_type varchar2(100);

      BEGIN

      OPEN cust_type_cur;
      FETCH cust_type_cur INTO v_customer_type;
      CLOSE cust_type_cur;


      IF v_customer_type = 'CORPORATE'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_customer_type = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;


         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

         EXCEPTION
             WHEN OTHERS THEN


              p_ret_msg  := 'Failed to Change  in Approve So. Please check the Customer Type Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

              p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

              INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
              SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
              , 'Failed to Change  in Approve So. Please check the Customer Type Attributes:' || v_customer_type);






  END SLT_D_IPVPN_DELETE_TRANSFER;

-- 13-11-2009 Jayan Liyanage


-- 27-11-2009 Samankula Owitipana


PROCEDURE DIDO_SET_NET_CODE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR vpn_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NETWORK CODE';

CURSOR cct_cur  IS
SELECT SO.SERO_CIRT_NAME
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;


v_cct_id VARCHAR2(20);
v_cvt_char varchar2(100);






BEGIN



OPEN vpn_cur;
FETCH vpn_cur INTO v_cvt_char;
CLOSE vpn_cur;

OPEN cct_cur;
FETCH cct_cur INTO v_cct_id;
CLOSE cct_cur;




INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_cvt_char,'NETWORK CODE',null);








p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set ALTERNATE NAME. Please check NETWORK CODE attribute :' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END DIDO_SET_NET_CODE;

-- 27-11-2009 Samankula Owitipana

-- 27-11-2009 Samankula Owitipana

PROCEDURE DIDO_SET_PRIMARY_NUMBER (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR num_select_cur  IS
SELECT NU.NUMB_NUMBER,nu.NUMB_NUCC_CODE
FROM NUMBERS NU,NUMBER_INSTANCE_DETAILS nid
WHERE nu.NUMB_SERV_ID = p_serv_id
and nu.NUMB_ID = nid.NIDE_NUMB_ID
and (nu.NUMB_NUMS_ID = 3 or nu.NUMB_NUMS_ID = 4)
and nid.NIDE_NAME = 'PRIMARY_NUMBER'
and nid.NIDE_VALUE = 'Y';


v_NUMBER numbers.NUMB_NUMBER%TYPE;
v_CITY_CODE numbers.NUMB_NUCC_CODE%TYPE;

BEGIN

OPEN num_select_cur;
FETCH num_select_cur INTO v_NUMBER,v_CITY_CODE;
CLOSE num_select_cur;


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_CITY_CODE || v_NUMBER
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'PHONE_NUMBER' ;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to set Primary Number. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


END DIDO_SET_PRIMARY_NUMBER;

-- 27-11-2009 Samankula Owitipana


-- 27-11-2009 Jayan Liyanage

PROCEDURE PSTN_PORT_STATUS_CHECKING(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR Cur_Dis_name IS
SELECT CI.CIRT_DISPLAYNAME
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND CI.CIRT_SERT_ABBREVIATION = 'PSTN'
AND SO.SERO_ID =  p_sero_id;


v_cir_name     varchar2(100);

begin

 p_dynamic_extension.chk_ACTUAL_DSP_BILL_NOTIFY_DT(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


                IF p_ret_msg IS NULL THEN

                    open Cur_Dis_name;
                    fetch Cur_Dis_name into v_cir_name;
                    close Cur_Dis_name;


                          DECLARE


                          CURSOR Cur_Status IS
                          SELECT FA.FRAA_STATUS,PO.PORT_STATUS,FC.FRAC_STATUS,FU.FRAU_NAME,fa.fraa_position
                          FROM CIRCUITS CI,FRAME_APPEARANCES FA,FRAME_UNITS FU,PORTS PO,FRAME_CONTAINERS FC
                          WHERE CI.CIRT_NAME = FA.FRAA_CIRT_NAME
                          AND FA.FRAA_FRAU_ID = FU.FRAU_ID
                          AND PO.PORT_CIRT_NAME = CI.CIRT_NAME
                          AND FU.FRAU_FRAC_ID = FC.FRAC_ID
                          AND CI.CIRT_SERT_ABBREVIATION = 'PSTN'
                          AND CI.CIRT_DISPLAYNAME = v_cir_name;
                          --GROUP BY FA.FRAA_STATUS,PO.PORT_STATUS,FU.FRAU_NAME;

                          CURSOR Cur_Po_Status IS
                          SELECT EQ.EQUP_EQUT_ABBREVIATION,PO.PORT_NAME,PO.PORT_CARD_SLOT,PO.PORT_STATUS
                          FROM CIRCUITS CI,PORTS PO,EQUIPMENT EQ
                          WHERE PO.PORT_CIRT_NAME = CI.CIRT_NAME
                          AND EQ.EQUP_ID = PO.PORT_EQUP_ID
                          AND CI.CIRT_SERT_ABBREVIATION = 'PSTN'
                          AND CI.CIRT_DISPLAYNAME = v_cir_name;


                          v_Frame_App     varchar2(100);
                          v_Dp_name       varchar2(100);
                          v_Fr_cnt_Status varchar2(100);
                          v_fra_possi     varchar2(100);

                          v_Eq_Abbriva    varchar2(100);
                          v_Port_Name     varchar2(100);
                          v_Port_Crd      varchar2(100);
                          v_Port_Status   varchar2(100);



                          BEGIN


                          OPEN Cur_Po_Status;
                          FETCH Cur_Po_Status INTO v_Eq_Abbriva,v_Port_Name,v_Port_Crd,v_Port_Status;
                          CLOSE Cur_Po_Status;


                          open Cur_Status;
                          loop
                          exit WHEN Cur_Status %notfound;
                          fetch Cur_Status into v_Frame_App,v_Port_Status,v_Fr_cnt_Status,v_Dp_name,v_fra_possi;



                          IF  v_Frame_App <> 'INSERVICE' OR v_Fr_cnt_Status <> 'INSERVICE' THEN

                                 p_ret_msg := 'WORNNING ! ' || 'Please select an Active Port '||v_Dp_name||' Position : '||v_fra_possi;


                          END IF;



                          end loop;
                          close Cur_Status;


                          IF v_Port_Status <> 'INSERVICE' THEN

                                 p_ret_msg := 'WORNNING ! ' || 'Please select an Active Port '||v_Eq_Abbriva|| ' Port Card   ' ||v_Port_Crd||'  Port Name : '||v_Port_Name;

                          END IF;



                         EXCEPTION WHEN NO_DATA_FOUND THEN

                                   p_ret_msg := '';

                          END;




               ELSE


               p_ret_msg :=  'PLEASE  CHECK  PSTN ACTUAL DSP DATE ';

               END IF;


   EXCEPTION WHEN NO_DATA_FOUND THEN

  p_ret_msg := '';

END PSTN_PORT_STATUS_CHECKING;


-- 27-11-2009 Jayan Liyanage

-- 11-08-2009 Samankula Owitipana

PROCEDURE WAN_IP_ADDRESS_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR ip_select_cur  IS
SELECT NU.NUMB_NUMBER,nu.NUMB_NETMASK FROM NUMBERS NU
WHERE nu.NUMB_SERV_ID = p_serv_id
AND nu.NUMB_NETMASK is not null;



v_IP numbers.NUMB_NUMBER%TYPE;
v_SUBNET numbers.NUMB_NETMASK%TYPE;

BEGIN

OPEN ip_select_cur;
FETCH ip_select_cur INTO v_IP,v_SUBNET;
CLOSE ip_select_cur;


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_IP || '/' || v_SUBNET
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'VPN WAN IP' ;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to set WAN IP ATTRIBUTE. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END WAN_IP_ADDRESS_ATTR;

-- 11-08-2009 Samankula Owitipana

-- 12-10-2009 Samankula Owitipana

PROCEDURE WIFI_ADD_ATTRIBUTE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR nof_accp_select_cur  IS
SELECT nvl(trim(SOA.SEOA_DEFAULTVALUE),0)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NO_OF ACCESS POINTS';


CURSOR nof_oruters_select_cur  IS
SELECT nvl(trim(SOA.SEOA_DEFAULTVALUE),0)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NO_OF ROUTERS';


CURSOR nof_sw_select_cur  IS
SELECT nvl(trim(SOA.SEOA_DEFAULTVALUE),0)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NO_OF SWITCHES';

CURSOR nof_ups_select_cur  IS
SELECT nvl(trim(SOA.SEOA_DEFAULTVALUE),0)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NO_OF UPS';

CURSOR nof_evi_select_cur  IS
SELECT nvl(trim(SOA.SEOA_DEFAULTVALUE),0)
FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NO_OF EVI';



v_NOF_ACCP SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_NOF_ROUTERS SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_NOF_SW SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_NOF_UPS SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_NOF_EVI SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

v_Counter1 number := 1;
v_Counter2 number := 1;
v_Counter3 number := 1;
v_Counter4 number := 1;
v_Counter5 number := 1;


BEGIN

OPEN nof_accp_select_cur;
FETCH nof_accp_select_cur INTO v_NOF_ACCP ;
CLOSE nof_accp_select_cur;

OPEN nof_oruters_select_cur;
FETCH nof_oruters_select_cur INTO v_NOF_ROUTERS ;
CLOSE nof_oruters_select_cur;

OPEN nof_sw_select_cur;
FETCH nof_sw_select_cur INTO v_NOF_SW ;
CLOSE nof_sw_select_cur;

OPEN nof_ups_select_cur;
FETCH nof_ups_select_cur INTO v_NOF_UPS ;
CLOSE nof_ups_select_cur;

OPEN nof_evi_select_cur;
FETCH nof_evi_select_cur INTO v_NOF_EVI ;
CLOSE nof_evi_select_cur;




For v_Counter1 in reverse v_NOF_ACCP+1..50 loop


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'ACCESS_POINT_MODEL ' || v_Counter1;


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'ACCESS_POINT_SERIAL_NO ' || v_Counter1;


end loop;

For v_Counter2 in reverse v_NOF_ROUTERS+1..10 loop


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'ROUTER_MODEL ' || v_Counter2;


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'ROUTER_SERIAL_NO ' || v_Counter2;


end loop;


For v_Counter3 in reverse v_NOF_SW+1..10 loop


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SWITCH_MODEL ' || v_Counter3;


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SWITCH_SERIAL_NO ' || v_Counter3;


end loop;


For v_Counter4 in reverse v_NOF_UPS+1..10 loop


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'UPS_MODEL ' || v_Counter4;


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'UPS_SERIAL_NO ' || v_Counter4;


end loop;


For v_Counter5 in reverse v_NOF_EVI+1..5 loop


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'EVI_MODEL ' || v_Counter5;


DELETE FROM SERVICE_ORDER_ATTRIBUTES soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'EVI_SERIAL_NO ' || v_Counter5;


end loop;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to insert attributes:'|| ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg );

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


END WIFI_ADD_ATTRIBUTE;

-- 12-10-2009 Samankula Owitipana

-- 19-11-2009 Samankula Owitipana
-- Completion rule

PROCEDURE WIFI_CHK_MANDATORY_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_ROUTER_T VARCHAR2(100);
v_ROUTER_S VARCHAR2(100);

v_ACCESS_T VARCHAR2(100);
v_ACCESS_S VARCHAR2(100);

v_SWITCH_T VARCHAR2(100);
v_SWITCH_S VARCHAR2(100);

v_UPS_T VARCHAR2(100);
v_UPS_S VARCHAR2(100);

v_EVI_T VARCHAR2(100);
v_EVI_S VARCHAR2(100);

cursor c_router_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'ROUTER_MODEL%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_router_serial_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'ROUTER_SERIAL_NO%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_access_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'ACCESS_POINT_MODEL%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_access_serial_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'ACCESS_POINT_SERIAL_NO%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_switch_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'SWITCH_MODEL%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_switch_serial_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'SWITCH_SERIAL_NO%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_ups_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'UPS_MODEL%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_ups_serial_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'UPS_SERIAL_NO%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_evi_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'EVI_MODEL%'
and SOA.SEOA_DEFAULTVALUE is null;

cursor c_evi_serial_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME like 'EVI_SERIAL_NO%'
and SOA.SEOA_DEFAULTVALUE is null;



BEGIN

p_ret_msg := '';

open c_router_type_chk;
fetch c_router_type_chk into v_ROUTER_T;
close c_router_type_chk;

open c_router_serial_chk;
fetch c_router_serial_chk into v_ROUTER_S;
close c_router_serial_chk;

open c_access_type_chk;
fetch c_access_type_chk into v_ACCESS_T;
close c_access_type_chk;

open c_access_serial_chk;
fetch c_access_serial_chk into v_ACCESS_S;
close c_access_serial_chk;

open c_switch_type_chk;
fetch c_switch_type_chk into v_SWITCH_T;
close c_switch_type_chk;

open c_switch_serial_chk;
fetch c_switch_serial_chk into v_SWITCH_S;
close c_switch_serial_chk;

open c_ups_type_chk;
fetch c_ups_type_chk into v_UPS_T;
close c_ups_type_chk;

open c_ups_serial_chk;
fetch c_ups_serial_chk into v_UPS_S;
close c_ups_serial_chk;

open c_evi_type_chk;
fetch c_evi_type_chk into v_EVI_T;
close c_evi_type_chk;

open c_evi_serial_chk;
fetch c_evi_serial_chk into v_EVI_S;
close c_evi_serial_chk;



  IF v_ROUTER_T IS NOT NULL THEN

      p_ret_msg := 'ROUTER_TYPE - MANDATORY ATTRIBUTES BLANK' ;

  ELSIF v_ROUTER_S IS NOT NULL THEN

      p_ret_msg := 'ROUTER_SERIAL_NO - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_ACCESS_T IS NOT NULL THEN

          p_ret_msg := 'ACCESS_POINT_TYPE - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_ACCESS_S IS NOT NULL THEN

          p_ret_msg := 'ACCESS_POINT_SERIAL_NO - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_SWITCH_T IS NOT NULL THEN

          p_ret_msg := 'SWITCH_TYPE - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_SWITCH_S IS NOT NULL THEN

          p_ret_msg := 'SWITCH_SERIAL_NO - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_UPS_T IS NOT NULL THEN

          p_ret_msg := 'UPS_TYPE - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_UPS_S IS NOT NULL THEN

          p_ret_msg := 'UPS_SERIAL_NO - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_EVI_T IS NOT NULL THEN

          p_ret_msg := 'EVI_TYPE - MANDATORY ATTRIBUTES BLANK';

  ELSIF v_EVI_S IS NOT NULL THEN

          p_ret_msg := 'EVI_SERIAL_NO - MANDATORY ATTRIBUTES BLANK';


  END IF;



EXCEPTION

WHEN OTHERS THEN

    p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END WIFI_CHK_MANDATORY_ATTR;
-- 19-11-2009 Samankula Owitipan

--- 30-12-2009  Samankula Owitipana


PROCEDURE DIDO_SET_NUM_RANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS






v_min_number varchar2(10);
v_max_number varchar2(10);
v_city_code varchar2(4);




BEGIN



select max(nu.NUMB_NUMBER)
into v_max_number
from numbers nu
where nu.NUMB_SERV_ID = p_serv_id
and (nu.NUMB_NUMS_ID = 3 or nu.NUMB_NUMS_ID = 4);


select min(nu.NUMB_NUMBER)
into v_min_number
from numbers nu
where nu.NUMB_SERV_ID = p_serv_id
and (nu.NUMB_NUMS_ID = 3 or nu.NUMB_NUMS_ID = 4);


select nu.NUMB_NUCC_CODE
into v_city_code
from numbers nu
where nu.NUMB_NUMBER = v_min_number
and nu.NUMB_SERV_ID = p_serv_id;


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_city_code || v_min_number || '-' || v_city_code || v_max_number
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'NUMBER_RANGE' ;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to get reserved number range :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END DIDO_SET_NUM_RANGE;


--- 30-12-2009  Samankula Owitipana


--- 30-12-2009  Samankula Owitipana


PROCEDURE DIDO_SET_PILOT_ADE1_NUM (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS






v_pilot_number varchar2(15);
v_parent_cct_id circuits.CIRT_NAME%TYPE;
v_parent_cct_name varchar2(15);
v_cct_id circuits.CIRT_NAME%TYPE;
v_cct_name circuits.CIRT_DISPLAYNAME%TYPE;




cursor c_cct_id is
select so.SERO_CIRT_NAME,soa.SEOA_DEFAULTVALUE
from service_orders so,service_order_attributes soa
where so.SERO_ID = soa.SEOA_SERO_ID
and soa.SEOA_NAME = 'DATA CIRCUIT ID'
and so.SERO_ID = p_sero_id ;

cursor c_get_parent_cct is
select soa.SEOA_DEFAULTVALUE
from service_order_attributes soa
where soa.SEOA_NAME = 'SA_PARENT CIRCUIT ID'
and soa.SEOA_SERO_ID = p_sero_id;

cursor c_get_parent_details is
select ci.CIRT_NAME,ot.OTHN_NAME from circuits ci,OTHER_NAMES ot
where ci.CIRT_NAME = ot.OTHN_CIRT_NAME
and ci.CIRT_DISPLAYNAME = v_parent_cct_name
and (ci.CIRT_STATUS not like 'PE%' and ci.CIRT_STATUS not like 'CA%');


BEGIN


open c_cct_id;
fetch c_cct_id into v_cct_id,v_cct_name;
close c_cct_id;

open c_get_parent_cct;
fetch c_get_parent_cct into v_parent_cct_name;
close c_get_parent_cct;

open c_get_parent_details;
fetch c_get_parent_details into v_parent_cct_id,v_pilot_number ;
close c_get_parent_details;


INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_pilot_number,'DIDO PILOT NUMBER',null);


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set pilot and additional E1 other name :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END DIDO_SET_PILOT_ADE1_NUM;


--- 30-12-2009  Samankula Owitipana

-- 30-12-2009 Samankula Owitipana

PROCEDURE DIDO_SET_PILOT_NUMBER (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_NUMBER service_order_attributes.SEOA_DEFAULTVALUE%TYPE;
v_cct_id circuits.CIRT_NAME%TYPE;


cursor c_get_pilot_num is
select soa.SEOA_DEFAULTVALUE
from service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'PHONE_NUMBER' ;

cursor c_cct_id is
select so.SERO_CIRT_NAME
from service_orders so
where so.SERO_ID = p_sero_id ;



BEGIN

OPEN c_get_pilot_num;
FETCH c_get_pilot_num INTO v_NUMBER;
CLOSE c_get_pilot_num;

open c_cct_id;
fetch c_cct_id into v_cct_id;
close c_cct_id;



INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_NUMBER,'DIDO PILOT NUMBER',null);

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to set Primary Number. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


END DIDO_SET_PILOT_NUMBER;

-- 30-12-2009 Samankula Owitipana

-- 04-01-2010 Samankula Owitipana

  PROCEDURE IPVPN_CONFTESTLINK_WGCH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';





v_customer_type varchar2(30);
v_service_type  varchar2(30);
v_service_cat varchar2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;





        ---------------------- CONFIRM TEST LINK ------------------------------------------------------

/*

        IF v_customer_type = 'CORPORATE' AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'SME' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'WHOLESALE' AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;

*/

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg || ' ' || v_customer_type);


 END IPVPN_CONFTESTLINK_WGCH;


-- 04-01-2010 Samankula Owitipana


-- 01-02-2010 Samankula Owitipana

PROCEDURE DATA_SERVICE_SET_CCTID_COMP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CCT_ID numbers.NUMB_NUMBER%TYPE;


BEGIN


SELECT NU.NUMB_NUMBER
INTO CCT_ID
FROM NUMBERS NU
WHERE nu.NUMB_SERV_ID = p_serv_id;


IF CCT_ID is not null THEN

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = 'D' || CCT_ID
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'DATA CIRCUIT ID' ;

ELSE

p_ret_msg := 'Number not reserved';


END IF;




EXCEPTION
WHEN OTHERS THEN

  p_ret_msg := 'Number Reservation Error'|| ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END DATA_SERVICE_SET_CCTID_COMP;

-- 01-02-2010 Samankula Owitipana


-- 20-10-2009 Samankula Owitipana

PROCEDURE DATA_DELETE_CHK_DSP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




BEGIN



 P_dynamic_procedure.complete_approve_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


  IF p_ret_msg IS NULL THEN


  p_dynamic_extension.chk_ACTUAL_DSP_BILL_NOTIFY_DT(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


  IF p_ret_msg IS NULL THEN


  NULL;


  ELSE

  p_ret_msg := p_ret_msg || ' INVALID DSP.';

  END IF;


  ELSE

  p_ret_msg := p_ret_msg || ' APPROVE SO NOT COMPLETED PROPERLY.';

  END IF;








EXCEPTION
WHEN OTHERS THEN

     p_ret_msg := p_ret_msg || 'INVALID DSP or APPROVE SO NOT COMPLETED PROPERLY.';


END DATA_DELETE_CHK_DSP;

-- 20-10-2009 Samankula Owitipana

-- 09-02-2010  Jayan Liyanage
-- 09-12-2012  Updated

PROCEDURE adsl_card_type (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)

IS CURSOR cur_crd_model IS 
SELECT distinct ca.card_model  
FROM circuits ci,port_links pl,port_link_ports plp,ports p, cards ca,service_orders so 
WHERE ci.cirt_name = pl.porl_cirt_name AND pl.porl_id = plp.polp_porl_id
AND so.sero_cirt_name = ci.cirt_name 
AND (plp.polp_commonport = 'T' or plp.polp_commonport = 'F') 
AND plp.polp_port_id = p.port_id
AND ca.card_model is not null 
AND p.port_equp_id = ca.card_equp_id 
AND p.port_card_slot = ca.card_slot
AND so.sero_id = p_sero_id;
 
CURSOR cur_equip_model IS
SELECT eq.equp_equt_abbreviation ,NVL(REPLACE(eq.EQUP_EQUM_MODEL,'-ISL',''),eq.EQUP_EQUM_MODEL) EQ_MODEL
FROM circuits ci,port_links pl,port_link_ports plp,ports p,
cards ca,service_orders so, equipment eq 
WHERE ci.cirt_name = pl.porl_cirt_name 
AND pl.porl_id = plp.polp_porl_id
AND so.sero_cirt_name = ci.cirt_name 
AND (plp.polp_commonport = 'T' or plp.polp_commonport = 'F') 
AND plp.polp_port_id = p.port_id
AND eq.equp_equt_abbreviation not like '%SPLITTER%'
AND p.port_equp_id = ca.card_equp_id 
AND p.port_equp_id = eq.equp_id 
AND p.port_card_slot = ca.card_slot
AND so.sero_id = p_sero_id;
 
v_crd_model     VARCHAR2 (100);
v_equi_type     VARCHAR2 (100);
v_equi_model    VARCHAR2 (100);

BEGIN 

OPEN cur_crd_model; 
FETCH cur_crd_model INTO v_crd_model; 
CLOSE cur_crd_model; 

OPEN cur_equip_model; 
FETCH cur_equip_model INTO v_equi_type,v_equi_model;
CLOSE cur_equip_model; 

IF v_crd_model IS NOT NULL THEN 
    UPDATE service_order_attributes soa 
    SET soa.seoa_defaultvalue = v_crd_model
    WHERE soa.seoa_name = 'ADSL_CARD_MODEL'
    AND soa.seoa_sero_id = p_sero_id; 

    UPDATE service_order_attributes soa 
    SET soa.seoa_defaultvalue = v_equi_type
    WHERE soa.seoa_name = 'ADSL_NE_TYPE' 
    AND soa.seoa_sero_id = p_sero_id; 
    
    UPDATE service_order_attributes soa 
    SET soa.seoa_defaultvalue = v_equi_model
    WHERE soa.seoa_name = 'ADSL_EQIP_MODEL' 
    AND soa.seoa_sero_id = p_sero_id; 

ELSIF v_crd_model IS NULL THEN 
    UPDATE circuits ci SET ci.cirt_comment = 'Incomplete Circuits'    
    WHERE ci.cirt_name IN 
    (SELECT s.sero_cirt_name FROM service_orders s 
    WHERE s.sero_id = p_sero_id); 
END IF; 

p_implementation_tasks.update_task_status_byid (p_sero_id,0, p_seit_id, 'COMPLETED');

EXCEPTION WHEN OTHERS THEN 
p_ret_msg := 'Failed to Adsl Card Model Attribute  '  || ' - Erro is:'  || TO_CHAR (SQLCODE) || '-' || SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'ERROR' );
INSERT INTO service_task_comments (setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text )
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,'Failed to Adsl Card Model Attribute' || p_sero_id
                  );

END adsl_card_type;

-- 09-12-2012  Updated 
-- 09-02-2010  Jayan Liyanage

-- 11-02-2010  Jayan Liyanage

PROCEDURE ADSL_DELETE_COMBO_PORT_TSK(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




cursor Cur_Crd_Model IS
select  ca.card_model
from CIRCUITS ci,PORT_LINKS pl,PORT_LINK_PORTS plp,ports p,cards ca,SERVICE_ORDERS so
where ci.cirt_name = pl.porl_cirt_name
and pl.porl_id = plp.polp_porl_id
and so.sero_cirt_name = ci.cirt_name
and plp.polp_commonport = 'T'
and plp.polp_port_id  = p.port_id
and p.port_equp_id = ca.card_equp_id
and p.port_card_slot = ca.card_slot
and so.sero_id = p_sero_id;



CURSOR Cur_SA_PSTN_Number IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE  SOA.SEOA_NAME = 'SA_PSTN_NUMBER'
AND SOA.SEOA_SERO_ID = p_sero_id;





v_crd_model       varchar2(100);
v_Pstn_number     varchar2(100);



BEGIN

OPEN Cur_Crd_Model;
FETCH Cur_Crd_Model INTO v_crd_model;
CLOSE Cur_Crd_Model;

OPEN Cur_SA_PSTN_Number;
FETCH Cur_SA_PSTN_Number INTO v_Pstn_number;
CLOSE Cur_SA_PSTN_Number;




                IF v_crd_model <> 'COMBO' THEN

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'RESERVE VOICE PORT'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'CHANGE TO VOICE PORT'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'CHANGE MDF POSITION'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

              END IF;

              DECLARE

              CURSOR Cur_Max_Delete is
              SELECT so.sero_id
              FROM service_orders so,circuits ci
              WHERE ci.CIRT_NAME = so.SERO_CIRT_NAME
              And ci.CIRT_SERT_ABBREVIATION = 'PSTN'
              And (so.SERO_STAS_ABBREVIATION LIKE 'PRO%'OR so.SERO_STAS_ABBREVIATION LIKE 'APPR%')
              AND SO.SERO_ORDT_TYPE = 'DELETE'
              AND CI.CIRT_DISPLAYNAME = v_Pstn_number
              AND so.SERO_COMPLETION_DATE  = ( SELECT max(so.SERO_COMPLETION_DATE)
                                 FROM service_orders so
                                 WHERE so.SERO_SERT_ABBREVIATION = 'PSTN'
                                 AND ci.CIRT_NAME = so.SERO_CIRT_NAME);


              v_Max_delete_So   varchar2(100);

              BEGIN

              OPEN Cur_Max_Delete;
              FETCH Cur_Max_Delete INTO v_Max_delete_So;
              CLOSE Cur_Max_Delete;

               IF   v_crd_model = 'COMBO'  AND  v_Max_delete_So IS NOT NULL THEN

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'RESERVE VOICE PORT'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'CHANGE TO VOICE PORT'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

                    DELETE  SERVICE_IMPLEMENTATION_TASKS SIT
                    WHERE SIT.SEIT_TASKNAME = 'CHANGE MDF POSITION'
                    AND SIT.SEIT_SERO_ID = p_sero_id;

              END IF;

        END;



  p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

   EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Adsl Card Model Attribute  ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Adsl Card Model Attribute' || p_sero_id);


END ADSL_DELETE_COMBO_PORT_TSK;

-- 11-02-2010  Jayan Liyanage



-- 24-11-2009 Samankula Owitipana

PROCEDURE DIALUP_SET_ACCOUNT_NO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR acc_select_cur  IS
SELECT SO.SERO_ACCT_NUMBER FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;

v_ACC_NO varchar2(50);


BEGIN

OPEN acc_select_cur;
FETCH acc_select_cur INTO v_ACC_NO;
CLOSE acc_select_cur;






    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET soa.SEOA_DEFAULTVALUE = v_ACC_NO
    WHERE SOA.SEOA_SERO_ID = p_sero_id
    AND soa.SEOA_NAME = 'ACCOUNT NO';

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN
      p_ret_msg  := 'Failed to set account no: - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg );

END DIALUP_SET_ACCOUNT_NO;

-- 24-11-2009 Samankula Owitipana

-- 25-03-2010  Jayan Liyanage


PROCEDURE SLT_ADSL_RESU_FEATURE_MAPPING (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR Max_sus_SO IS
select so.SERO_ID
from service_orders so
where so.SERO_SERT_ABBREVIATION = 'ADSL'
and so.SERO_STAS_ABBREVIATION = 'CLOSED'
and so.SERO_ORDT_TYPE LIKE 'SUSP%'
and so.sero_serv_id = p_serv_id
and so.sero_statusdate IN ( SELECT MAX(s.SERO_STATUSDATE)
                            FROM service_orders s
                            where s.SERO_SERT_ABBREVIATION = 'ADSL'
                            and s.SERO_STAS_ABBREVIATION = 'CLOSED'
                            and s.SERO_ORDT_TYPE LIKE 'SUSP%'
                            and s.sero_serv_id = p_serv_id);


v_Max_Sus_So_Id             varchar2(100);

BEGIN

    OPEN Max_sus_SO;
    FETCH Max_sus_SO INTO v_Max_Sus_So_Id;
    CLOSE Max_sus_SO;

                                    DECLARE

                                    CURSOR  Cur_Service_Feat  IS
                                    SELECT SOA.SOFE_FEATURE_NAME,SOA.SOFE_PREV_VALUE
                                    FROM SERVICE_ORDER_FEATURES SOA
                                    WHERE SOA.SOFE_SERO_ID = v_Max_Sus_So_Id;


                                    v_Pre_So_feat_Name varchar2(100);
                                    v_pre_so_Value     varchar2(100);

                                    BEGIN

                                    OPEN Cur_Service_Feat;
                                    LOOP
                                    FETCH  Cur_Service_Feat INTO v_Pre_So_feat_Name,v_pre_so_Value;
                                    EXIT WHEN Cur_Service_Feat%NOTFOUND;


                                                    UPDATE SERVICE_ORDER_FEATURES SOF
                                                    SET SOF.SOFE_DEFAULTVALUE = v_pre_so_Value
                                                    WHERE SOF.SOFE_FEATURE_NAME = v_Pre_So_feat_Name
                                                    AND SOF.SOFE_SERO_ID = p_sero_id;

                                   END LOOP;
                                   CLOSE  Cur_Service_Feat;
                                   END;

                                     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

   EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Suspend Feature Mapping Failed.' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Suspend Feature Mapping Failed.' || v_Max_Sus_So_Id);

  END SLT_ADSL_RESU_FEATURE_MAPPING;

-- 25-03-2010  Jayan Liyanage


-- 18-02-2010 Samankula Owitipana

  PROCEDURE TRANSMISSION_WGCH_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





CURSOR link_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LINK TYPE';

CURSOR nw_a_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT A END';

CURSOR nw_b_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT B END';


v_nw_a varchar2(100);
v_nw_b varchar2(100);

v_link_type  varchar2(100);



BEGIN



OPEN link_type_cur;
FETCH link_type_cur INTO v_link_type;
CLOSE link_type_cur;

OPEN nw_a_cur;
FETCH nw_a_cur INTO v_nw_a;
CLOSE nw_a_cur;

OPEN nw_b_cur;
FETCH nw_b_cur INTO v_nw_b;
CLOSE nw_b_cur;



------------------------------------------IDENTIFY PARAMETERS----------------------------------------------------------------

         IF v_link_type = 'TRUNK' or v_link_type = 'IPS(VoiceGW)-SW' or v_link_type = 'VOIP(CoreRW)-SW' or
         v_link_type = 'VOIP(CoreRW)-Other Operator(SW)' or v_link_type = 'CDMA(SW-HLR)' or
         v_link_type = 'CDMA(SW-SMSserver)' or v_link_type = 'CDMA(SW-IN)' or v_link_type = 'CDMA(SW-CRBT)'
         or v_link_type = 'CDMA(SW-BSC)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IDENTIFY PARAMETERS' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'IDENTIFY PARAMETERS' ;

         END IF;

---------------------------------------------DESIGN CIRCUIT-----------------------------------------------------------------


         IF v_link_type = 'TRUNK' or v_link_type = 'IPS(VoiceGW)-SW' or v_link_type = 'VOIP(CoreRW)-SW' or
         v_link_type = 'VOIP(CoreRW)-Other Operator(SW)' or v_link_type = 'CDMA(SW-HLR)' or
         v_link_type = 'CDMA(SW-SMSserver)' or v_link_type = 'CDMA(SW-IN)' or v_link_type = 'CDMA(SW-CRBT)'
         or v_link_type = 'CDMA(SW-BSC)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DESIGN CIRCUIT' ;

         END IF;



------------------------------------------WO TO IP BACK BONE-------------------------------------------------------------



     IF (v_nw_a = 'MPLS(CoreRW)' and v_nw_b = 'MPLS(CoreRW)') or v_nw_a = 'BRAS' or v_nw_b = 'MPLS(EdgeRw)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IP-BACKBONE'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;


         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;


         END IF;


------------------------------------------WO TO IPS------------------------------------------------------------------


         IF (v_nw_a = 'ISP(POP)' and v_nw_b = 'ISP(AggRW)') or v_nw_b = 'ISP(AggRW)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INT-NW-SYSADMIN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;


         END IF;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG . Please check the Attributes' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);


 END TRANSMISSION_WGCH_CREATE;


-- 18-02-2010 Samankula Owitipana


-- 18-02-2010 Samankula Owitipana

  PROCEDURE TRANSMISSION_WGCH_MODIFY_FE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





CURSOR link_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LINK TYPE';



v_link_type  varchar2(100);



BEGIN



OPEN link_type_cur;
FETCH link_type_cur INTO v_link_type;
CLOSE link_type_cur;


-----------------------------------------APPROVE SO----------------------------------------------------------------

         IF v_link_type = 'TRUNK' or v_link_type = 'IPS(VoiceGW)-SW' or v_link_type = 'VOIP(CoreRW)-SW' or
         v_link_type = 'VOIP(CoreRW)-Other Operator(SW)' or v_link_type = 'CDMA(SW-HLR)' or
         v_link_type = 'CDMA(SW-SMSserver)' or v_link_type = 'CDMA(SW-IN)' or v_link_type = 'CDMA(SW-CRBT)'
         or v_link_type = 'CDMA(SW-BSC)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;






    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG . Please check the Attributes' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);


 END TRANSMISSION_WGCH_MODIFY_FE;


-- 18-02-2010 Samankula Owitipana

-- 18-02-2010 Samankula Owitipana

  PROCEDURE TRANSMISSION_WGCH_MODIFY_PATH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS







CURSOR nw_a_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT A END';

CURSOR nw_b_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT B END';


v_nw_a varchar2(100);
v_nw_b varchar2(100);



BEGIN



OPEN nw_a_cur;
FETCH nw_a_cur INTO v_nw_a;
CLOSE nw_a_cur;

OPEN nw_b_cur;
FETCH nw_b_cur INTO v_nw_b;
CLOSE nw_b_cur;





------------------------------------------WO TO IP BACK BONE---------------------------------------------------------------------------



         IF (v_nw_a = 'MPLS(CoreRW)' and v_nw_b = 'MPLS(CoreRW)') or v_nw_a = 'BRAS' or v_nw_b = 'MPLS(EdgeRw)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IP-BACKBONE'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;

         ELSE

          DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;


         END IF;


------------------------------------------WO TO IPS------------------------------------------------------------------


         IF (v_nw_a = 'ISP(POP)' and v_nw_b = 'ISP(AggRW)') or v_nw_b = 'ISP(AggRW)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INT-NW-SYSADMIN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;


         ELSE

          DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;


         END IF;





    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG . Please check the Attributes' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);


 END TRANSMISSION_WGCH_MODIFY_PATH;


-- 18-02-2010 Samankula Owitipana



-- 18-02-2010 Samankula Owitipana

  PROCEDURE TRANSMISSION_WGCH_DELETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





CURSOR link_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LINK TYPE';

CURSOR nw_a_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT A END';

CURSOR nw_b_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT B END';


v_link_type  varchar2(100);
v_nw_a varchar2(100);
v_nw_b varchar2(100);



BEGIN



OPEN link_type_cur;
FETCH link_type_cur INTO v_link_type;
CLOSE link_type_cur;

OPEN nw_a_cur;
FETCH nw_a_cur INTO v_nw_a;
CLOSE nw_a_cur;

OPEN nw_b_cur;
FETCH nw_b_cur INTO v_nw_b;
CLOSE nw_b_cur;



------------------------------------------APPROVE SO----------------------------------------------------------------

         IF v_link_type = 'TRUNK' or v_link_type = 'IPS(VoiceGW)-SW' or v_link_type = 'VOIP(CoreRW)-SW' or
         v_link_type = 'VOIP(CoreRW)-Other Operator(SW)' or v_link_type = 'CDMA(SW-HLR)' or
         v_link_type = 'CDMA(SW-SMSserver)' or v_link_type = 'CDMA(SW-IN)' or v_link_type = 'CDMA(SW-CRBT)'
         or v_link_type = 'CDMA(SW-BSC)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;


------------------------------------------ICONFIRM DELETION----------------------------------------------------------------

         IF v_link_type = 'TRUNK' or v_link_type = 'IPS(VoiceGW)-SW' or v_link_type = 'VOIP(CoreRW)-SW' or
         v_link_type = 'VOIP(CoreRW)-Other Operator(SW)' or v_link_type = 'CDMA(SW-HLR)' or
         v_link_type = 'CDMA(SW-SMSserver)' or v_link_type = 'CDMA(SW-IN)' or v_link_type = 'CDMA(SW-CRBT)'
         or v_link_type = 'CDMA(SW-BSC)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DELETION' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM DELETION' ;

         END IF;

-----------------------------------------WO TO IP BACKBONE--------------------------------------------------------------------------



         IF (v_nw_a = 'MPLS(CoreRW)' and v_nw_b = 'MPLS(CoreRW)') or v_nw_a = 'BRAS' or v_nw_b = 'MPLS(EdgeRw)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IP-BACKBONE'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;

         ELSE

           DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO IP BACKBONE' ;


         END IF;


------------------------------------------WO TO IPS------------------------------------------------------------------


         IF (v_nw_a = 'ISP(POP)' and v_nw_b = 'ISP(AggRW)') or v_nw_b = 'ISP(AggRW)' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INT-NW-SYSADMIN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;


         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO TO ISP' ;


         END IF;





    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in IPVPN VERTUAL CREATE . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);


 END TRANSMISSION_WGCH_DELETE;


-- 18-02-2010 Samankula Owitipana


-- 15-03-2010 Samankula Owitipana
-- Completion rule

PROCEDURE TX_CHK_MANDATORY_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_NW_A VARCHAR2(100);
v_NW_B VARCHAR2(100);

v_EX_A VARCHAR2(100);
v_EX_B VARCHAR2(100);



cursor c_NW_A_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT A END';

cursor c_NW_B_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NW ELEMENT B END';


cursor c_EX_B_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_EXCHANGE_CODE';

cursor c_EX_A_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_EXCHANGE_A END';



BEGIN

p_ret_msg := '';

open c_NW_A_chk;
fetch c_NW_A_chk into v_NW_A;
close c_NW_A_chk;

open c_NW_B_chk;
fetch c_NW_B_chk into v_NW_B;
close c_NW_B_chk;

open c_EX_B_chk;
fetch c_EX_B_chk into v_EX_B;
close c_EX_B_chk;

open c_EX_A_chk;
fetch c_EX_A_chk into v_EX_A;
close c_EX_A_chk;




  IF v_NW_A = 'Switch' AND v_NW_B = 'Switch' THEN


       IF v_EX_B is null or v_EX_A is null THEN

      p_ret_msg := 'SA_EXCHANGE... - MANDATORY ATTRIBUTES BLANK' ;

      END IF;

  ELSIF v_NW_A = 'Switch' THEN


      IF v_EX_A is null THEN

      p_ret_msg := 'SA_EXCHANGE_A END - MANDATORY ATTRIBUTES BLANK';

    END IF;


  ELSIF v_NW_B = 'Switch' THEN

    IF v_EX_B is null THEN

      p_ret_msg := 'SA_EXCHANGE_CODE - MANDATORY ATTRIBUTES BLANK';

    END IF;


  END IF;



EXCEPTION

WHEN OTHERS THEN

    p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END TX_CHK_MANDATORY_ATTR;

-- 15-03-2010 Samankula Owitipana


-- 27-04-2010Samankula Owitipana
----ZTE Provisioning Data
----modified for ZTE
PROCEDURE ADSL_ZTE_PROV_DATA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_NE_TYPE         SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_ADSL_CCT_ID   Service_Orders.SERO_CIRT_NAME%TYPE;
v_ADSL_CCT_ID_OLD   Service_Orders.SERO_CIRT_NAME%TYPE;
v_AREA          areas.AREA_DESCRIPTION%TYPE;
v_ORDER_TYPE    Service_Orders.SERO_ORDT_TYPE%TYPE;
v_PID           VARCHAR2(100);
v_DISPLAY_NAME  circuits.CIRT_DISPLAYNAME%TYPE;

v_ADSL_PKG SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_IPTV_PKG SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_ADSL_PKG_OLD SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;
v_IPTV_PKG_OLD SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

v_ADSL_FE_NEW SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
v_ADSL_FE_OLD SERVICE_ORDER_FEATURES.SOFE_PREV_VALUE%TYPE;
v_IPTV_FE_NEW SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
v_IPTV_FE_OLD SERVICE_ORDER_FEATURES.SOFE_PREV_VALUE%TYPE;
v_WO_ID work_order.WORO_ID%TYPE;

v_ADSL_VLANID VARCHAR2(100);
v_SVLANID VARCHAR2(100);
v_IPTV_MVLANID VARCHAR2(100);
v_IPTV_UVLANID VARCHAR2(100);

v_ADSL_PKG_NMS VARCHAR2(100);
v_DEFPRI VARCHAR2(10);
v_INGRESS VARCHAR2(10);
v_EGRESS VARCHAR2(10);
v_EQ_MODEL VARCHAR2(100);
v_EQ_AREA VARCHAR2(100);
v_EQUIP_VERTION VARCHAR2(100);

v_ADSL_SPEED_OLD VARCHAR2(100);
v_ADSL_SPEED      VARCHAR2(100);

v_HOME VARCHAR2(100);
v_OFFICE VARCHAR2(100);
v_ENTREE VARCHAR2(100);
v_EXCITE VARCHAR2(100);
v_EXCEL VARCHAR2(100);

v_EXCITEPLUS VARCHAR2(100);
v_OFFICEPLUS VARCHAR2(100);
v_EXCELPLUS VARCHAR2(100);

v_CARD_MODEL VARCHAR2(100);
v_CARD_NAME VARCHAR2(100);
v_PORT VARCHAR2(100);

v_ADSL_PVC VARCHAR2(10);
v_IPTV_PVC VARCHAR2(10);

v_card_type VARCHAR2(10);

v_domain_name ZTE_SOP_PRO.DOMAIN%TYPE; ---- ZTE


CURSOR c_adsl_pkg  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE),trim(SOA.SEOA_PREV_VALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PACKAGE_NAME'
AND soa.SEOA_SOFE_ID IS NULL;

CURSOR c_adsl_speed  IS
SELECT replace(trim(SOA.SEOA_DEFAULTVALUE),'IPTV_', ''),replace(trim(SOA.SEOA_PREV_VALUE),'IPTV_', '')
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LINE_PROFILE'
AND soa.SEOA_SOFE_ID IS NULL;

CURSOR c_iptv_pkg  IS
SELECT trim(SOA.SEOA_DEFAULTVALUE),trim(SOA.SEOA_PREV_VALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IPTV_PACKAGE'
AND soa.SEOA_SOFE_ID IS NULL;

CURSOR c_adsl_fe  IS
SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.SOFE_SERO_ID = p_sero_id
AND sof.SOFE_FEATURE_NAME = 'INTERNET';

CURSOR c_iptv_fe  IS
SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.SOFE_SERO_ID = p_sero_id
AND sof.SOFE_FEATURE_NAME = 'IPTV';

CURSOR c_pid IS
SELECT DISTINCT REPLACE(SUBSTR(REPLACE(po.PORT_CARD_SLOT,'P',''),INSTR(po.PORT_CARD_SLOT,'.')),'.','-') || '-' || REPLACE(po.PORT_NAME,'DSL-IN-',''),
SUBSTR(eq.equp_index,-2) ,trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),eq.EQUP_EQUM_MODEL
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT LIKE 'P%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

CURSOR c_pid2 IS
SELECT DISTINCT '1' || SUBSTR(po.PORT_CARD_SLOT,4) || '-' , REPLACE(po.PORT_NAME,'DSL-IN-',''),
REPLACE(SUBSTR(po.PORT_CARD_SLOT,0,3),'Z',''),trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),ca.CARD_MODEL,ca.CARD_NAME,
eq.EQUP_EQUM_MODEL
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo,cards ca
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = ca.CARD_EQUP_ID
AND po.PORT_CARD_SLOT = ca.CARD_SLOT
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT LIKE 'Z%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

CURSOR c_vlan_id  IS
SELECT zv.ADSL_SVLAN,zv.ADSL_HOME,zv.ADSL_OFFICE,zv.ADSL_ENTREE,zv.ADSL_EXCITE,zv.ADSL_EXCEL,zv.IPTV_MVLAN,zv.IPTV_UVLAN
FROM ZTE_VLAN_TABLE zv
WHERE zv.LEA = v_AREA;

/*CURSOR c_vlan_id_plus  IS
select zv2.ADSL_EXCITEPLUS,zv2.ADSL_OFFICEPLUS,zv2.ADSL_EXCELPLUS,zv2.ADSL_SVLAN,zv2.IPTV_MVLAN,zv2.IPTV_UVLAN
from ZTE_VLAN_TABLE zv2
where zv2.LEA = v_AREA;*/


BEGIN

P_dynamic_procedure.Process_ISSUE_WORK_ORDER(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);

IF p_ret_msg IS NULL THEN

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_NE_TYPE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ADSL_NE_TYPE';


SELECT trim(SOA.SEOA_PREV_VALUE)
INTO v_ADSL_CCT_ID_OLD
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'USER_NAME';


SELECT so.SERO_CIRT_NAME,so.SERO_ORDT_TYPE,trim(REPLACE(ci.CIRT_DISPLAYNAME,'(N)',''))
INTO v_ADSL_CCT_ID, v_ORDER_TYPE, v_DISPLAY_NAME
FROM Service_Orders so,circuits ci
WHERE so.SERO_CIRT_NAME = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id;



IF v_NE_TYPE LIKE '%MSAN%' OR v_NE_TYPE LIKE '%DSLAM-ZTE%' THEN

    OPEN c_adsl_pkg;
    FETCH c_adsl_pkg INTO v_ADSL_PKG,v_ADSL_PKG_OLD;
    CLOSE c_adsl_pkg;
      
      OPEN c_adsl_speed;
    FETCH c_adsl_speed INTO v_ADSL_SPEED,v_ADSL_SPEED_OLD;
    CLOSE c_adsl_speed;


    OPEN c_iptv_pkg;
    FETCH c_iptv_pkg INTO v_IPTV_PKG,v_IPTV_PKG_OLD;
    CLOSE c_iptv_pkg;

    OPEN c_adsl_fe;
    FETCH c_adsl_fe INTO v_ADSL_FE_NEW,v_ADSL_FE_OLD;
    CLOSE c_adsl_fe;

    OPEN c_iptv_fe;
    FETCH c_iptv_fe INTO v_IPTV_FE_NEW,v_IPTV_FE_OLD;
    CLOSE c_iptv_fe;


      IF v_NE_TYPE LIKE 'DSLAM-ZTE' THEN

      OPEN c_pid;
      FETCH c_pid INTO v_PID,v_EQ_MODEL,v_AREA,v_EQUIP_VERTION;
      CLOSE c_pid;
      
      ELSIF v_NE_TYPE LIKE 'MSAN-ZTE' OR v_NE_TYPE LIKE 'MSAN-OG' OR v_NE_TYPE LIKE 'MSAN-OP' 
        OR v_NE_TYPE LIKE 'MSAN-IG' OR v_NE_TYPE LIKE 'MSAN-IW' OR v_NE_TYPE LIKE 'MSAN-OW' THEN
      
      OPEN c_pid2;
      FETCH c_pid2 INTO v_PID,v_PORT,v_EQ_MODEL,v_AREA,v_CARD_MODEL,v_CARD_NAME,v_EQUIP_VERTION;
      CLOSE c_pid2;   
      
        IF   v_PID is null THEN
      
        OPEN c_pid;
        FETCH c_pid INTO v_PID,v_EQ_MODEL,v_AREA,v_EQUIP_VERTION;
        CLOSE c_pid;
      
        END IF;
      
      
      IF  v_CARD_MODEL = 'COMBO' AND v_CARD_NAME = '16 LINE CARD' THEN
      
      ---- v_PORT := (to_number(v_PORT)-16);
      
             ---IF to_number(v_PORT) < 10 THEN
      
              /* IF to_number(v_PORT) < 8 THEN
             
             v_PORT := (to_number(v_PORT)+16);
      
              v_PID := v_PID || v_PORT;
             
             ELSE
             
             v_PID := v_PID || v_PORT;
      
               END IF; */
      
      
        v_PID := v_PID || v_PORT;
        
        
       /* ELSIF  ((v_CARD_MODEL = 'COMBO' AND v_CARD_NAME = 'ASTGC+ATLDI-(00-31)') OR 
            (v_CARD_MODEL = 'COMBO' AND v_CARD_NAME = 'ASTGC+ATLDI-(32-63)')) THEN
              
              
        v_PORT := (TO_NUMBER(v_PORT) + 1);
        v_PID  :=  v_PID || v_PORT ; */
        
      ELSE 
      
      v_PID := v_PID || v_PORT;
      
      END IF;
      
      
      END IF;
      
      
      
      
      IF v_EQUIP_VERTION like 'ZXDSL9806H%' THEN
      
      
      v_EQ_AREA := v_AREA || '_ZXDSL9806H_' || v_EQ_MODEL;
      
      
      ELSE
      

      v_EQ_AREA := v_AREA || '_MSAG5200_' || v_EQ_MODEL;
      
      
      END IF;
      
      
      
      IF v_EQUIP_VERTION = 'MSAG5200' THEN
      
      v_EQUIP_VERTION := 'MSAGV2';
      v_ADSL_PVC := '0';
      v_IPTV_PVC := '1';
      
      ELSIF v_EQUIP_VERTION = 'MSAG5200-ISL' THEN
      
      v_EQUIP_VERTION := 'MSAGV3';
      v_ADSL_PVC := '0';
      v_IPTV_PVC := '1';
      
      ELSIF v_EQUIP_VERTION like 'ZXDSL9806H%' THEN
      
      v_EQUIP_VERTION := 'ZXDSL9806H';
      v_ADSL_PVC := '1';
      v_IPTV_PVC := '2';
      
      END IF;
      


      IF v_ADSL_PKG = 'HOME' THEN

      v_ADSL_PKG_NMS := 'HOMEEXPRESS';
      v_DEFPRI := '0';
      v_INGRESS := '192';
      v_EGRESS := '576';
      v_domain_name := 'sltbb'; ----- ZTE      

      OPEN c_vlan_id;
      FETCH c_vlan_id INTO v_SVLANID,v_HOME,v_OFFICE,v_ENTREE,v_EXCITE,v_EXCEL,v_IPTV_MVLANID,v_IPTV_UVLANID;
      CLOSE c_vlan_id;

      v_ADSL_VLANID := v_HOME;


      ELSIF (v_ADSL_PKG = 'OFFICE' OR v_ADSL_PKG = 'OFFICE 1IP') THEN

      v_ADSL_PKG_NMS := 'OFFICEEXPRESS';
      v_DEFPRI := '0';
      v_INGRESS := '576';
      v_EGRESS := '2112';
      v_domain_name := 'sltbb'; ----- ZTE

      OPEN c_vlan_id;
      FETCH c_vlan_id INTO v_SVLANID,v_HOME,v_OFFICE,v_ENTREE,v_EXCITE,v_EXCEL,v_IPTV_MVLANID,v_IPTV_UVLANID;
      CLOSE c_vlan_id;

      v_ADSL_VLANID := v_OFFICE;
 
 
      
      ELSE 
      
      v_ADSL_PKG_NMS := v_ADSL_SPEED;
        v_DEFPRI := '0';
      v_domain_name := 'sltbb'; 
           
      
      

      END IF;
      
      
      IF v_ADSL_PKG_OLD = 'HOME' THEN
      
      v_ADSL_PKG_OLD := 'HOMEEXPRESS';
      
      ELSIF (v_ADSL_PKG_OLD = 'OFFICE' OR v_ADSL_PKG_OLD = 'OFFICE 1IP') THEN

      v_ADSL_PKG_OLD := 'OFFICEEXPRESS';
      
          
      ELSE 
        
        v_ADSL_PKG_OLD := v_ADSL_SPEED_OLD;
            
      END IF;


      SELECT wo.WORO_ID
      INTO v_WO_ID
      FROM work_order wo
      WHERE wo.WORO_SERO_ID = p_sero_id
      AND wo.WORO_SEIT_ID = p_seit_id;
      
      
      
      IF  v_CARD_MODEL = 'COMBO' AND v_CARD_NAME = '32 LINE CARD' THEN
      
      v_card_type := 'Y';
      
      ELSE
      
      v_card_type := 'N';
      
      END IF;
      
      

INSERT INTO ZTE_SOP_PRO z ( SERO_ID, WORO_ID, SERO_ORDT_TYPE, AREA, PID, ADSL_PKG_NAME, CCT_NAME,
IPTV_PKG_NAME, ADSL_FEATURE_NEW, ADSL_FEATURE_OLD, IPTV_FEATURE_NEW, IPTV_FEATURE_OLD, ADSL_VLANID,
SVLANID, IPTV_MVLANID, IPTV_UVLANID, DEFPRI, INGRESS, EGRESS, DATE_TIME, STATUS, COMMENTS,
SEIT_ID, ADSL_PKG_NAME_OLD,IPTV_PKG_NAME_OLD,CCT_NAME_OLD,z.CARD_TYPE,Z.DOMAIN,z.VER,z.ADSL_PVC,z.IPTV_PVC ) VALUES (  ---- ZTE DOMAIN
p_sero_id, v_WO_ID, v_ORDER_TYPE, v_EQ_AREA, v_PID
, v_ADSL_PKG_NMS, v_DISPLAY_NAME, v_IPTV_PKG, v_ADSL_FE_NEW, v_ADSL_FE_OLD, v_IPTV_FE_NEW, v_IPTV_FE_OLD
, v_ADSL_VLANID, v_SVLANID, v_IPTV_MVLANID, v_IPTV_UVLANID, v_DEFPRI, v_INGRESS, v_EGRESS, SYSDATE ,
 'NEW', NULL, p_seit_id,v_ADSL_PKG_OLD,v_IPTV_PKG_OLD,v_ADSL_CCT_ID_OLD,v_card_type,v_domain_name,
 v_EQUIP_VERTION,v_ADSL_PVC,v_IPTV_PVC);  --- ZTE  v_domain_name


INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Auto Provisioning Inprogress');


END IF;

 ----p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

ELSE

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

END IF;



 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'ZTE ADSL SET DATA FAILED:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);





END ADSL_ZTE_PROV_DATA;

-- 27-04-2010Samankula Owitipana

-- 27-04-2010Samankula Owitipana

PROCEDURE AUDIO_CONF_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;




v_CUSTYPE_VAL VARCHAR2(25);



BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;





------------------------------------------ISSUE INVOICE----------------------------------------------------------




         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;


         END IF;




         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in ISSUE INVOIC. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg || v_CUSTYPE_VAL);


END AUDIO_CONF_CREATE;

-- 25-05-2010 Samankula Owitipana

-- 25-05-2010 Samankula Owitipana
--AUDIO_CONF_MODIFY PRICE PLAN


PROCEDURE AUDIO_CONF_CUST_CON (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;




v_CUSTYPE_VAL VARCHAR2(25);



BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;





------------------------------------------MODIFY PRICE PLAN---------------------------------------------------------



         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;




         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg || v_CUSTYPE_VAL);


END AUDIO_CONF_CUST_CON;

-- 25-05-2010 Samankula Owitipana


-- 07-06-2010  Jayan Liyanage

PROCEDURE AUDI_CONFN_SUSPEND_ATT_CHANG (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





          CURSOR SO_FEA_SWITCH_cur  IS
          SELECT SOF.SFEA_FEATURE_NAME,SOF.SFEA_VALUE
          FROM SERVICES_FEATURES sof
          WHERE SOF.SFEA_SERV_ID = p_serv_id;

          CURSOR NEW_SO IS
          SELECT SO.SERO_ORDT_TYPE
          FROM SERVICE_ORDERS SO
          WHERE SO.SERO_ID = p_sero_id;




          v_So_Feature_Name  varchar2(100);
          v_So_Feature_Val   varchar2(100);

          v_So_Type          varchar2(100);





   BEGIN

  OPEN NEW_SO;
  FETCH NEW_SO INTO v_So_Type;
  CLOSE NEW_SO;





          IF   v_So_Type = 'SUSPEND' THEN


          OPEN SO_FEA_SWITCH_cur;
          LOOP
          FETCH SO_FEA_SWITCH_cur INTO v_So_Feature_Name,v_So_Feature_Val;

          EXIT WHEN SO_FEA_SWITCH_cur%NOTFOUND;

               IF v_So_Feature_Name = 'SF_CALL RECORDING' AND v_So_Feature_Val = 'Y'THEN


                         UPDATE SERVICE_ORDER_FEATURES SOF
                         SET SOF.SOFE_DEFAULTVALUE = 'N'
                         WHERE SOF.SOFE_FEATURE_NAME = 'SF_CALL RECORDING'
                         AND SOF.SOFE_SERO_ID = p_sero_id;

               END IF;



          END LOOP;
          CLOSE SO_FEA_SWITCH_cur;

          END IF;


        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to MODIFY PRICE PLAN . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Failed to Change MODIFY PRICE PLAN. Please check the Customer TYPE Attributes: ' || p_sero_id);




END AUDI_CONFN_SUSPEND_ATT_CHANG;

-- 07-06-2010  Jayan Liyanage

-- 07-06-2010  Jayan Liyanage


PROCEDURE AUDI_CONFN_RESUM_ATT_CHANG (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR Max_sus_SO IS
select so.SERO_ID
from service_orders so,circuits ci
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and so.SERO_SERT_ABBREVIATION = 'AUDIO CONFERENCING'
and so.SERO_STAS_ABBREVIATION = 'CLOSED'
and so.SERO_ORDT_TYPE LIKE 'SUSP%'
and so.sero_serv_id = p_serv_id
and so.sero_statusdate IN ( SELECT MAX(SO.SERO_STATUSDATE)
                            FROM service_orders s
                            where s.SERO_CIRT_NAME = ci.CIRT_NAME);


v_Max_Sus_So_Id             varchar2(100);

BEGIN

    OPEN Max_sus_SO;
    FETCH Max_sus_SO INTO v_Max_Sus_So_Id;
    CLOSE Max_sus_SO;

                                    DECLARE

                                    CURSOR  Cur_Service_Feat  IS
                                    SELECT SOA.SOFE_FEATURE_NAME,SOA.SOFE_PREV_VALUE
                                    FROM SERVICE_ORDER_FEATURES SOA
                                    WHERE SOA.SOFE_SERO_ID = v_Max_Sus_So_Id;


                                    v_Pre_So_feat_Name varchar2(100);
                                    v_pre_so_Value     varchar2(100);

                                    BEGIN

                                    OPEN Cur_Service_Feat;
                                    LOOP
                                    FETCH  Cur_Service_Feat INTO v_Pre_So_feat_Name,v_pre_so_Value;
                                    EXIT WHEN Cur_Service_Feat%NOTFOUND;


                                                    UPDATE SERVICE_ORDER_FEATURES SOF
                                                    SET SOF.SOFE_DEFAULTVALUE = v_pre_so_Value
                                                    WHERE SOF.SOFE_FEATURE_NAME = v_Pre_So_feat_Name
                                                    AND SOF.SOFE_SERO_ID = p_sero_id;

                                   END LOOP;
                                   CLOSE  Cur_Service_Feat;
                                   END;

                                     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

   EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Suspend Feature Mapping Failed.' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , 'Suspend Feature Mapping Failed.' || v_Max_Sus_So_Id);

  END AUDI_CONFN_RESUM_ATT_CHANG;

-- 18-03-2010  Jayan Liyanage


-- 02-12-2009 Buddika Weerasinghe
--SLT_IPLC_CREATE


PROCEDURE SLT_IPLC_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);

v_SLA_MAINTANENCE VARCHAR2(50);
v_SLA_RESTORATION VARCHAR2(50);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;

SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_MAINTANENCE
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_RESTORATION
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_MAINTANENCE
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_RESTORATION
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RESTORATION TIME' ;


------------------------------------------APPROVE SO-----------------------------------------------------------


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;





/*BEGIN

         IF v_CUSTYPE_VAL = 'CORPORATE-WHOLESALE'and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-LARGE & VERY LARGE' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-SME' and v_SECAT_VAL='TEST' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-GLOBAL' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;*/


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;




        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT.' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in UPDATE CIRCUIT. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;

        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;



        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;






 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_CREATE;

-- 02-12-2009 Buddika Weerasinghe

-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_CREATE_OR

PROCEDURE SLT_IPLC_CREATE_OR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);

v_SLA_MAINTANENCE VARCHAR2(50);
v_SLA_RESTORATION VARCHAR2(50);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_MAINTANENCE
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_RESTORATION
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW & RESTORATION TIME' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_MAINTANENCE
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_RESTORATION
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RESTORATION TIME' ;




        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;




/*BEGIN

         IF v_CUSTYPE_VAL = 'CORPORATE-WHOLESALE'and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-LARGE & VERY LARGE' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-SME' and v_SECAT_VAL='TEST' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE-GLOBAL' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;
*/

        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;




        BEGIN


         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;



         END IF;


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in UPDATE CIRCUIT. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;

        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;



        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;



 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_CREATE_OR;

-- 02-12-2009 Buddika Weerasinghe



-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_MODIFY_LOCATION
PROCEDURE SLT_IPLC_MODIFY_LOCATION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR ACC_INTF_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACCESS N/W INTF';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_ACC_INTF VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN ACC_INTF_select_cur;
FETCH ACC_INTF_select_cur INTO v_ACC_INTF;
CLOSE ACC_INTF_select_cur;






        BEGIN

         IF v_ACC_INTF = 'TDM TX PORT'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSIF v_ACC_INTF = 'DATA PORT'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the ACCESS N/W INTF Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg || v_ACC_INTF);

        END;





        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;




        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;




 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_MODIFY_LOCATION;

-- 02-12-2009 Buddika Weerasinghe

-- 02-12-2009 Buddika Weerasinghe
-- Edited by Jayan on 23-07-2015
-- SLT_IPLC_DELETE
PROCEDURE SLT_IPLC_DELETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(200);
v_SECAT_VAL VARCHAR2(200);
v_TRA_NW_VAL VARCHAR2(200);
v_BILL_TY_VAL VARCHAR2(200);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;





BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;

BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;








 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_DELETE;

-- 02-12-2009 Buddika Weerasinghe

-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_DELETE_OR

PROCEDURE SLT_IPLC_DELETE_OR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;



BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;




BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY INTL-BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY INTL-BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;








 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_DELETE_OR;
-- 02-12-2009 Buddika Weerasinghe

-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_MODIFY_CPE

PROCEDURE SLT_IPLC_MODIFY_CPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NOTIFY INTL BILLING';



v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);



BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;







BEGIN

     IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;








 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_MODIFY_CPE;

-- 02-12-2009 Buddika Weerasinghe

-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_CREATE_UPGRADE_PU

PROCEDURE SLT_IPLC_CREATE_UPGRADE_PU (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);

v_SLA_MAINTANENCE VARCHAR2(50);
v_SLA_RESTORATION VARCHAR2(50);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;



SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
INTO v_SLA_MAINTANENCE
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;


SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
INTO v_SLA_RESTORATION
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_MAINTANENCE
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SLA MAINTANENCE WINDOW' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_SLA_RESTORATION
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'RESTORATION TIME' ;



        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE UPGRADE' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE UPGRADE' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE UPGRADE' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE UPGRADE' ;

         END IF;

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;





BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'SME' and v_SECAT_VAL='TEST' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV. INTL PRODUCT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;




        BEGIN

        IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;



         END IF;


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in UPDATE CIRCUIT. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;

        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in END TO END TEST. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;



        BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;







 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_CREATE_UPGRADE_PU;

-- 02-12-2009 Buddika Weerasinghe


-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_DELETE_UPGRADE

PROCEDURE SLT_IPLC_DELETE_UPGRADE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;






        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'TERM. INTL PRODUCT' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;







        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;






 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_DELETE_UPGRADE;

-- 02-12-2009 Buddika Weerasinghe


-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_MODIFY_SPEED_HU

PROCEDURE SLT_IPLC_MODIFY_SPEED_HU (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;


UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET SOA.SEOA_DEFAULTVALUE = null
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'NEW BEARER REQUIRED?';


/*BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'SME' and v_SECAT_VAL='TEST' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL' and v_SECAT_VAL='TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;*/


BEGIN

         IF v_TRA_NW_VAL = 'TDM TX'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSIF (v_TRA_NW_VAL = 'MLLN' or v_TRA_NW_VAL = 'MLLN+TDM TX') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;



         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in CONFIRM  W/ CUSTOMER. Please check the TRANSPORT NW Attributes: ' || v_TRA_NW_VAL);

        END;



        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;

        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;


        BEGIN

         IF v_BILL_TY_VAL = 'FOREIGN PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-ISU'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;

         ELSIF v_BILL_TY_VAL = 'LOCAL PARTY'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'BCU-ACCT-DATA'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'NOTIFY BILLING' ;



         END IF;


        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in NOTIFY BILLING. Please check the BILLING_TYPE Attributes:' ||' - Erro is:' || TO_CHAR(SQLCODE)||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||v_CUSTYPE_VAL);

        END;

 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_MODIFY_SPEED_HU;

-- 02-12-2009 Buddika Weerasinghe




-- 02-12-2009 Buddika Weerasinghe
-- SLT_IPLC_MODIFY_EQUIPMENT

PROCEDURE SLT_IPLC_MODIFY_EQUIPMENT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

CURSOR SECAT_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR TRA_NW_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';


CURSOR BILL_TY_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BILLING_TYPE';




v_CUSTYPE_VAL VARCHAR2(25);
v_SECAT_VAL VARCHAR2(25);
v_TRA_NW_VAL VARCHAR2(25);
v_BILL_TY_VAL VARCHAR2(25);


BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;

OPEN SECAT_select_cur;
FETCH SECAT_select_cur INTO v_SECAT_VAL;
CLOSE SECAT_select_cur;

OPEN TRA_NW_select_cur;
FETCH TRA_NW_select_cur INTO v_TRA_NW_VAL;
CLOSE TRA_NW_select_cur;

OPEN BILL_TY_select_cur;
FETCH BILL_TY_select_cur INTO v_BILL_TY_VAL;
CLOSE BILL_TY_select_cur;        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;

        BEGIN

         IF v_CUSTYPE_VAL <>'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL ='GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INTL-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' ||

' - Erro is:' || TO_CHAR(SQLCODE)

||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' ||

v_CUSTYPE_VAL);

        END;

 p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


END SLT_IPLC_MODIFY_EQUIPMENT;

-- 02-12-2009 Buddika Weerasinghe

PROCEDURE SLT_IPLC_SUSPEND (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;




v_CUSTYPE_VAL VARCHAR2(25);
v_P2PTYPE_VAL VARCHAR2(25);
v_SLA_TYPE_A VARCHAR2(20);
v_SLA_TYPE_B VARCHAR2(20);
v_SLA_PERCENTAGE_A VARCHAR2(20);
v_SLA_PERCENTAGE_B VARCHAR2(20);

BEGIN



OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;




------------------------------------------APPROVE SO-----------------------------------------------------------


        BEGIN

         IF v_CUSTYPE_VAL = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'CORPORATE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF v_CUSTYPE_VAL = 'GLOBAL'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'INT-SALES-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;

         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes: ' || v_CUSTYPE_VAL);

        END;



END SLT_IPLC_SUSPEND;



--- 11-12-2009  Samankula Owitipana


PROCEDURE IPLC_SET_ALTER_NAME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR vpn_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTL CCT ID';

CURSOR cct_cur  IS
SELECT SO.SERO_CIRT_NAME
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;


v_cct_id VARCHAR2(20);
v_cvt_char varchar2(100);






BEGIN



OPEN vpn_cur;
FETCH vpn_cur INTO v_cvt_char;
CLOSE vpn_cur;

OPEN cct_cur;
FETCH cct_cur INTO v_cct_id;
CLOSE cct_cur;




INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_cvt_char,'INTL CCT ID',null);






p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set ALTERNATE NAME. Please check VPN Name attribute :' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END IPLC_SET_ALTER_NAME;


--- 11-12-2009  Samankula Owitipana


-- 21-01-2010 Samankula Owitipana

PROCEDURE IPLC_MODIFY_SPEED_DSU_CHK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR Cur_old_dsu IS
SELECT trim(SOA.SEOA_PREV_VALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_NAME = 'DSU SERIAL NO'
AND SOA.SEOA_SERO_ID = p_sero_id;

CURSOR Cur_new_dsu IS
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_NAME = 'DSU SERIAL NO'
AND SOA.SEOA_SERO_ID = p_sero_id;






v_old_dsu      varchar2(100);
v_new_dsu      varchar2(100);



BEGIN

open Cur_old_dsu;
fetch Cur_old_dsu into v_old_dsu;
close Cur_old_dsu ;

open Cur_new_dsu;
fetch Cur_new_dsu into v_new_dsu;
close Cur_new_dsu ;

IF v_new_dsu is null THEN

p_ret_msg := 'New DSU SERIAL NO is blank';

ELSIF v_new_dsu = v_old_dsu THEN


p_ret_msg := 'Old and new DSU SERIAL NO are same';


END IF;





EXCEPTION
WHEN NO_DATA_FOUND THEN

  p_ret_msg := '';



END IPLC_MODIFY_SPEED_DSU_CHK;

-- 21-01-2010 Samankula Owitipana

-- 11-03-2010 Samankula Owitipana

PROCEDURE  get_worg_sa_exchange_aend (

      p_serv_id                      IN     Services.serv_id%TYPE,
      p_sero_id                                     IN     Service_Orders.sero_id%TYPE,
      p_seit_id                                       IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname                     IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                                    IN     work_order.woro_id%TYPE,
      p_ret_char                                   OUT    VARCHAR2,
      p_ret_number                            OUT    NUMBER,
      p_ret_msg                                    OUT    VARCHAR2) is



    cursor sero_cur is
       select sero_sert_abbreviation, sero_ordt_type
         from service_orders
           where sero_id = p_sero_id;



    cursor seoa_cur is
       select SEOA_DEFAULTVALUE
         from service_order_attributes
           where seoa_sero_id = p_sero_id
             and seoa_name like 'SA_EXCHANGE_CODE_A END%';



    cursor area_cur (c_area_code                               varchar2) is
      select area_aret_code
        FROM areas
          WHERE area_code = c_area_code;





    sero_rec                                          sero_cur%rowtype;

    l_area_type                                   varchar2(50) := '';

    l_area_type_dummy                 varchar2(50) := '';

    l_actual_area                 varchar2(100) := '';

    l_area_worg_type                      varchar2(100) := '';

    l_ret_msg                                       varchar2(4000) := '';

    l_worg_name                                                varchar2(100) := '';



  begin

    DBMS_OUTPUT.put_line('Process get_worg_sa_exchange_code for Sero:' || p_sero_id );

    p_ret_char := '';

    open sero_cur;

    fetch sero_cur into sero_rec;

    close sero_cur;





    open seoa_cur;

    fetch seoa_cur into l_actual_area;

    close seoa_cur;



    if l_actual_area is null then

      p_ret_msg := 'Unable to calculate work group. The exchange code is not defined.';

      return;

    end if;



     dbms_output.put_line('In get_worg_sa_exchange_code:Worg_area-' || l_actual_area || ' WorgType:' || l_area_worg_type );



     P_dynamic_procedure.get_task_worg_type( sero_rec.sero_sert_abbreviation,sero_rec.sero_ordt_type,

                                             p_impt_taskname, l_area_type_dummy, l_area_worg_type, l_ret_msg);

     if l_ret_msg is not null then

       p_ret_msg := l_ret_msg;

       return;

     end if;



     dbms_output.put_line('In get_worg_sa_exchange_code2:Worg_area-' || l_actual_area || ' WorgType:' || l_area_worg_type );



     P_dynamic_procedure.get_worg_name(sero_rec.sero_sert_abbreviation,l_area_worg_type,l_actual_area,l_worg_name,l_ret_msg);





     IF l_ret_msg is not null or l_worg_name is null then

       p_ret_msg := 'The work groups are not configured for area ' || l_actual_area || '.' || l_ret_msg;

       RETURN;

     END IF;



     p_ret_char := l_worg_name;

     p_ret_msg := '';

 ---p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

  exception

    when others then

      p_ret_msg  := 'Failed to get_worg_sa_exchange_code. Erro is:' || to_char(sqlcode) ||'-'|| sqlerrm;


        ---p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        ---INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          ---SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
         ---- , p_ret_msg);

  END get_worg_sa_exchange_aend;


-- 11-06-2010 Samankula Owitipana
-- Completion rule

PROCEDURE TX_CHK_MANDATORY_IDNTPARA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_LINK_TYPE VARCHAR2(200);
v_SIGNAL_TYPE VARCHAR2(200);
v_CCT_NO VARCHAR2(200);
v_POINT_A VARCHAR2(200);
v_POINT_B VARCHAR2(200);



cursor c_link_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LINK TYPE';

cursor c_signal_type_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SIGNALING TYPE';

cursor c_cct_no_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT NO:';

cursor c_point_a_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'POINT CODE A END';

cursor c_point_b_chk is
SELECT SOA.SEOA_NAME
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'POINT CODE B END';


BEGIN

p_ret_msg := '';

open c_link_type_chk;
fetch c_link_type_chk into v_LINK_TYPE;
close c_link_type_chk;

open c_signal_type_chk;
fetch c_signal_type_chk into v_SIGNAL_TYPE;
close c_signal_type_chk;

open c_cct_no_chk;
fetch c_cct_no_chk into v_CCT_NO;
close c_cct_no_chk;

open c_point_a_chk;
fetch c_point_a_chk into v_POINT_A;
close c_point_a_chk;

open c_point_b_chk;
fetch c_point_b_chk into v_POINT_B;
close c_point_b_chk;


  IF v_LINK_TYPE = 'IPS(L3SW)-ISP(AggRW)' or v_LINK_TYPE = 'CDMA(BSC-BSC)' or v_LINK_TYPE = 'CDMA(BSC-BTS)' or v_LINK_TYPE = 'Datacom(Dnode-Dnode)'
     or v_LINK_TYPE = 'ISP(POP-AggRW)' or v_LINK_TYPE = 'MPLS(CoreRW-CoreRw)' or v_LINK_TYPE = 'MPLS(CoreRW-EdgeRw)' or
     v_LINK_TYPE = 'BRAS-IPTV(HeadEnd)' or v_LINK_TYPE = 'Tx_MUX-Tx_MUX' THEN


  NULL;


  ELSE

    IF v_SIGNAL_TYPE is null THEN

    p_ret_msg := 'SIGNALING TYPE - MANDATORY ATTRIBUTES BLANK';

    ELSIF v_CCT_NO is null THEN

     p_ret_msg := 'CIRCUIT NO: - MANDATORY ATTRIBUTES BLANK';

    ELSIF v_POINT_A is null THEN

     p_ret_msg := 'POINT CODE A END - MANDATORY ATTRIBUTES BLANK';

    ELSIF v_POINT_B is null THEN

      p_ret_msg := 'POINT CODE B END - MANDATORY ATTRIBUTES BLANK';

    END IF;


  END IF;



EXCEPTION

WHEN OTHERS THEN

    p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END TX_CHK_MANDATORY_IDNTPARA;

-- 11-06-2010 Samankula Owitipana

-- 10-Nov-2008 Gihan Amarasinghe
PROCEDURE SLT_CLI_PROVISIONED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_isvalid VARCHAR(1);
v_wip_order VARCHAR(1);
count_1 NUMBER :=0;

BEGIN

    SELECT seoa.SEOA_DEFAULTVALUE INTO v_wip_order
    FROM SERVICE_ORDER_ATTRIBUTES seoa
    WHERE  seoa.SEOA_SERO_ID = p_sero_id AND seoa.SEOA_NAME = 'SA_WIP_ORDER';

    IF v_wip_order = 'N' THEN

        SELECT 'Y' INTO v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
        AND SOFE_FEATURE_NAME = 'SF_CLI' AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');

             select  count(*) into count_1
               from service_orders, circuits, equipment equp, port_link_ports, port_links, ports, equipment_types, ne_nodes
                 where sero_id = p_sero_id
        and cirt_name = sero_cirt_name
        and porl_cirt_name = cirt_name
                   and porl_id = polp_porl_id
                   and polp_port_id = port_id
                   and port_equp_id = equp_id
                   and EQUp_EQUT_ABBREVIATION = EQUT_ABBREVIATION
                   and equp_id = NENO_EQUP_ID
                   and neno_type like '%SOP%'
                   and equt_group in ('SWITCHING', 'DATA')
                   and neno_mans_name like 'NEAX61E%7.5%';


        IF  count_1 = 0 THEN
            p_ret_msg := 'FALSE';
        ELSE
            p_ret_msg := '';
        END IF;
    ELSE
        p_ret_msg := 'FALSE';
    END IF;

EXCEPTION

WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := 'FALSE';
END SLT_CLI_PROVISIONED;
-- 10-Nov-2008 Gihan Amarasinghe

-- 02-06-2010 Fayaz Thahir -------------
--Edited Dinesh 07-02-2014
--- NEAX 61E start providing CLI
--- commented following to achived
PROCEDURE CHECK_CLI_FEA_TASK_CONDITION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      v_isvalid             VARCHAR(1);
      count_1 NUMBER :=0;
      --count_2 NUMBER :=0;
      count_3 NUMBER :=0;
BEGIN
    v_isvalid := 'N';

     p_dynamic_extension.SLT_CHECK_AUTO_MANUAL(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);

     IF p_ret_msg is null then

        SELECT count(*) into count_1
        FROM SERVICE_ORDER_FEATURES  A WHERE A.SOFE_SERO_ID = p_sero_id
        AND A.SOFE_FEATURE_NAME != 'SF_CLI' AND A.SOFE_FEATURE_NAME != 'SF_SISU CONNECT' 
        AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');
        
        SELECT count(*) into count_3
        FROM SERVICE_ORDER_FEATURES  A WHERE A.SOFE_SERO_ID = p_sero_id
        AND A.SOFE_FEATURE_NAME != 'SF_SISU CONNECT' 
        AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');

        IF count_1 != 0 THEN
                p_ret_msg := '';
        /*ELSE

        select count(*) into count_2
               from service_orders, circuits, equipment equp, port_link_ports, port_links, ports, equipment_types, ne_nodes
                 where sero_id = p_sero_id
        and cirt_name = sero_cirt_name
        and porl_cirt_name = cirt_name
                   and porl_id = polp_porl_id
                   and polp_port_id = port_id
                   and port_equp_id = equp_id
                   and EQUp_EQUT_ABBREVIATION = EQUT_ABBREVIATION
                   and equp_id = NENO_EQUP_ID
                   and neno_type like '%SOP%'
                   and equt_group in ('SWITCHING', 'DATA')
                   and neno_mans_name like 'NEAX61E%7.5%';*/

        ELSIF /*count_2 != 0 and*/ count_3 != 0 THEN
            p_ret_msg := '';
        ELSE
            p_ret_msg := 'FALSE';
        END IF;
        --END IF;
     ELSE
        p_ret_msg := 'FALSE';
     END IF;

EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := '';
WHEN OTHERS THEN
   p_ret_msg := 'FALSE';
END CHECK_CLI_FEA_TASK_CONDITION;
-- 02-06-2010 Fayaz Thahir -------------



------28-12-2009 Fayaz -------------------

PROCEDURE FAULT_HIS_UPDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


       CURSOR cur_new_cirt IS
         select SO.SERO_CIRT_NAME
         from Service_Orders so
         where sero_id=p_sero_id;

      CURSOR cur_old_cirt IS
        select CRT.CIRT_NAME
        from circuits crt
        where   CRT.CIRT_STATUS = 'INSERVICE'
        and CRT.CIRT_SERV_ID = p_serv_id;


          v_new_cirt    varchar2(20);
          v_old_cirt    varchar2(20);


BEGIN

    OPEN  cur_new_cirt;
    FETCH  cur_new_cirt INTO v_new_cirt;
    CLOSE  cur_new_cirt;

    OPEN  cur_old_cirt;
    FETCH  cur_old_cirt INTO v_old_cirt;
    CLOSE  cur_old_cirt;


update  problem_links prob
    set PROB.PROL_FOREIGNID = v_new_cirt
    where PROB.PROL_FOREIGNID = v_old_cirt;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
    WHEN OTHERS THEN
      p_ret_msg  := 'Failed to add users from history. Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


END FAULT_HIS_UPDATE;


------28-12-2009 Fayaz  --------------------



-- 08-06-2010 Samankula Owitipana

  PROCEDURE DATAPRODUCT_CHK_CCT_DETAILS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_pl_seq varchar2(100);
v_po_id varchar2(100);
v_po_card varchar2(100);
v_po_port varchar2(100);
v_fa_id varchar2(100);
v_fa_side varchar2(100);
v_fa_position varchar2(100);
v_cct_id varchar2(100);

v_po_id_ins  varchar2(100);
v_card_slot_ins varchar2(100);
v_pl_seq_ins varchar2(100);

v_display_name varchar2(100);


cursor c_circuit_details is
select pl.PORL_SEQUENCE,plp.POLP_PORT_ID, po.PORT_CARD_SLOT,po.PORT_NAME,plp.POLP_FRAA_ID,fa.FRAA_SIDE,fa.FRAA_POSITION,ci.CIRT_SERV_ID
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po,FRAME_APPEARANCES fa
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID(+)
and plp.POLP_FRAA_ID = fa.FRAA_ID(+)
and so.SERO_ID = p_sero_id;


cursor c_port_chk is
select ci.CIRT_DISPLAYNAME
from circuits ci,port_links pl,port_link_ports plp
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_SERV_ID <> v_cct_id
and plp.POLP_PORT_ID = v_po_id;


cursor c_fa_chk is
select ci.CIRT_DISPLAYNAME
from circuits ci,port_links pl,port_link_ports plp
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_SERV_ID <> v_cct_id
and plp.POLP_FRAA_ID = v_fa_id;

 cursor c_inservice_chk is
 select pl.PORL_SEQUENCE,po.PORT_CARD_SLOT,po.PORT_NAME
 from service_orders so,port_links pl,port_link_ports plp,ports po,equipment eq
 where so.SERO_CIRT_NAME = pl.PORL_CIRT_NAME
 and pl.PORL_ID = plp.POLP_PORL_ID
 and plp.POLP_PORT_ID = po.PORT_ID
 and po.PORT_EQUP_ID = eq.EQUP_ID
 and (po.PORT_STATUS <> 'INSERVICE'
 or eq.EQUP_STATUS <> 'INSERVICE')
 and so.SERO_ID = p_sero_id;

BEGIN



 p_dynamic_extension.update_so_header_from_cirt(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


IF p_ret_msg is null THEN


open c_inservice_chk;

loop

v_po_id_ins  := null;
v_card_slot_ins := null;
v_pl_seq_ins := null;

     fetch c_inservice_chk into v_pl_seq_ins,v_card_slot_ins,v_po_id_ins;
      exit when c_inservice_chk%notfound;

     IF v_card_slot_ins is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq_ins ||' port ' || v_card_slot_ins || '-' || v_po_id_ins || ' is not set to inservice ';

     END IF;



end loop;

close c_inservice_chk;


open c_circuit_details;

     loop

     v_display_name := null;

     v_pl_seq := null;
     v_po_id := null;
     v_po_card := null;
     v_po_port := null;
     v_fa_id := null;
     v_fa_side := null;
     v_fa_position := null;
     v_cct_id := null;

     fetch c_circuit_details into v_pl_seq,v_po_id,v_po_card,v_po_port,v_fa_id,v_fa_side,v_fa_position,v_cct_id;
      exit when c_circuit_details%notfound;



     IF v_po_id is not null THEN

       open c_port_chk;
       fetch c_port_chk into v_display_name;
       close c_port_chk;


            IF v_display_name is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq ||' port ' || v_po_card || '-' || v_po_port || ' is reserved for ' || v_display_name ;

           END IF;




     ELSIF v_fa_id is not null THEN

       open c_fa_chk;
       fetch c_fa_chk into v_display_name;
       close c_fa_chk;

            IF v_display_name is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq ||' frame ' || v_fa_side || ' side ' || v_fa_position || ' is reserved for ' || v_display_name ;

           END IF;




     END IF;



     end loop;

     close c_circuit_details;

ELSE

p_ret_msg := p_ret_msg || ' -Update SO location failed';

END IF;



EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to check circuit details' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;




END DATAPRODUCT_CHK_CCT_DETAILS;

-- 08-06-2010 Samankula Owitipana




-- 23-06-2010 Samankula Owitipana


PROCEDURE DELETE_DSP_VALIDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR Actual_Dsp_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACTUAL_DSP_DATE';

CURSOR sop_date_cur  IS
select sit.SEIT_ACTUAL_END_DATE
from  SERVICE_IMPLEMENTATION_TASKS SIT
WHERE SIT.SEIT_SERO_ID =  p_sero_id
AND SIT.SEIT_TASKNAME = 'SOP_PROVISION';


v_cvt_char SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_sop_date date;




BEGIN



OPEN Actual_Dsp_cur;
FETCH Actual_Dsp_cur INTO v_cvt_char;
CLOSE Actual_Dsp_cur;

OPEN sop_date_cur;
FETCH sop_date_cur INTO v_sop_date;
CLOSE sop_date_cur;

p_dynamic_extension.chk_ACTUAL_DSP_BILL_NOTIFY_DT(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);


IF p_ret_msg is null THEN


IF v_sop_date = GREATEST(v_sop_date,to_date(v_cvt_char, 'DD-MON-YYYY HH24:MI')) THEN

p_ret_msg  := 'DSP_DATE should be greater than SOP_PROVISION actual end date';

END IF;

ELSE

p_ret_msg := p_ret_msg || ' Check existance of ACTUAL_DSP BILL_NOTIFY DATES failed';

END IF;



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'DSP_DATE wrong format. Format should be DD-MON-YYYY HH24:MI:' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;




END DELETE_DSP_VALIDATE;


-- 23-06-2010 Samankula Owitipana


-- 28-06-2010 Samankula Owitipana
----without SO location completion rule

  PROCEDURE DATAPRO_CHK_CCT_MODSPEED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_pl_seq varchar2(100);
v_po_id varchar2(100);
v_po_card varchar2(100);
v_po_port varchar2(100);
v_fa_id varchar2(100);
v_fa_side varchar2(100);
v_fa_position varchar2(100);
v_cct_id varchar2(100);

v_po_id_ins  varchar2(100);
v_card_slot_ins varchar2(100);
v_pl_seq_ins varchar2(100);

v_display_name varchar2(100);


cursor c_circuit_details is
select pl.PORL_SEQUENCE,plp.POLP_PORT_ID, po.PORT_CARD_SLOT,po.PORT_NAME,plp.POLP_FRAA_ID,fa.FRAA_SIDE,fa.FRAA_POSITION,ci.CIRT_SERV_ID
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po,FRAME_APPEARANCES fa
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID(+)
and plp.POLP_FRAA_ID = fa.FRAA_ID(+)
and so.SERO_ID = p_sero_id;


cursor c_port_chk is
select ci.CIRT_DISPLAYNAME
from circuits ci,port_links pl,port_link_ports plp
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_SERV_ID <> v_cct_id
and plp.POLP_PORT_ID = v_po_id;


cursor c_fa_chk is
select ci.CIRT_DISPLAYNAME
from circuits ci,port_links pl,port_link_ports plp
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_SERV_ID <> v_cct_id
and plp.POLP_FRAA_ID = v_fa_id;

 cursor c_inservice_chk is
 select pl.PORL_SEQUENCE,po.PORT_CARD_SLOT,po.PORT_NAME
 from service_orders so,port_links pl,port_link_ports plp,ports po,equipment eq
 where so.SERO_CIRT_NAME = pl.PORL_CIRT_NAME
 and pl.PORL_ID = plp.POLP_PORL_ID
 and plp.POLP_PORT_ID = po.PORT_ID
 and po.PORT_EQUP_ID = eq.EQUP_ID
 and (po.PORT_STATUS <> 'INSERVICE'
 or eq.EQUP_STATUS <> 'INSERVICE')
 and so.SERO_ID = p_sero_id;


BEGIN



P_dynamic_procedure.PROCESS_UPDATE_CIRT_commision(
              p_serv_id,
              p_sero_id,
              p_seit_id,
              p_impt_taskname,
              p_woro_id,
              p_ret_char,
              p_ret_number,
              p_ret_msg);


IF p_ret_msg IS NULL THEN



open c_inservice_chk;

loop

v_po_id_ins  := null;
v_card_slot_ins := null;
v_pl_seq_ins := null;

     fetch c_inservice_chk into v_pl_seq_ins,v_card_slot_ins,v_po_id_ins;
      exit when c_inservice_chk%notfound;

     IF v_card_slot_ins is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq_ins ||' port ' || v_card_slot_ins || '-' || v_po_id_ins || ' is not set to inservice ';

     END IF;



end loop;

close c_inservice_chk;

--------------------------------------------------------------------------

open c_circuit_details;

     loop

     v_display_name := null;

     v_pl_seq := null;
     v_po_id := null;
     v_po_card := null;
     v_po_port := null;
     v_fa_id := null;
     v_fa_side := null;
     v_fa_position := null;
     v_cct_id := null;

     fetch c_circuit_details into v_pl_seq,v_po_id,v_po_card,v_po_port,v_fa_id,v_fa_side,v_fa_position,v_cct_id;
      exit when c_circuit_details%notfound;



     IF v_po_id is not null THEN

       open c_port_chk;
       fetch c_port_chk into v_display_name;
       close c_port_chk;


            IF v_display_name is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq ||' port ' || v_po_card || '-' || v_po_port || ' is reserved for ' || v_display_name ;

           END IF;




     ELSIF v_fa_id is not null THEN

       open c_fa_chk;
       fetch c_fa_chk into v_display_name;
       close c_fa_chk;

            IF v_display_name is not null THEN

           p_ret_msg := 'Row ' || v_pl_seq ||' frame ' || v_fa_side || ' side ' || v_fa_position || ' is reserved for ' || v_display_name ;

           END IF;




     END IF;



     end loop;

     close c_circuit_details;
ELSE

p_ret_msg := p_ret_msg || ' - CCT set commission error';

END IF;



EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to check circuit details' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;




END DATAPRO_CHK_CCT_MODSPEED;

-- 28-06-2010 Samankula Owitipana



--- 03-08-2010  Fayaz Thahir

procedure slt_check_CLI_fea_provisioned(
      p_serv_id             IN     Services.serv_id%type,
      p_sero_id             IN     Service_Orders.sero_id%type,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%type,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%type,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               out    varchar2,
      p_ret_number             OUT    number,
      p_ret_msg                OUT    Varchar2) is

   cursor sero_cur is
      select sero_ordt_type
        from service_orders
          where sero_id = p_sero_id;

   CURSOR sofe_cur IS
      SELECT sofe_feature_name, sofe_defaultvalue, sofe_prev_value, SOFE_PROVISION_STATUS, seit_taskname
        FROM service_order_features, service_implementation_tasks
        WHERE sofe_sero_id = p_sero_id
            AND seit_id = p_seit_id
            AND sofe_feature_name = 'SF_CLI'
            AND sofe_defaultvalue <> sofe_prev_value
            AND NVL(sofe_provision_status,'N') = 'N';

   sero_rec            sero_cur%rowtype;
   l_count            number := 0;
   l_unprovisioned_features    varchar2(2000);

  begin

    DBMS_OUTPUT.put_line('Process check_CLI_feature_provisioned for Sero:' || p_sero_id );

    p_ret_msg := '';

    open sero_cur;
    fetch sero_cur into sero_rec;
    close sero_cur;

    for sofe_rec  in sofe_cur loop
      IF sero_rec.sero_ordt_type like 'MODIFY%FEATURE%' or sero_rec.sero_ordt_type like 'CREATE%' then
        if sofe_rec.sofe_feature_name = 'SF_CLI' and sofe_rec.seit_taskname = 'PROVISION CLI' then
                l_unprovisioned_features := l_unprovisioned_features || '   ' || sofe_rec.sofe_feature_name;
        end if;
      END IF;

    end loop;

    update service_order_attributes set seoa_defaultvalue =
              (select to_char(nvl(max(SOFE_PROVISION_TIME),sysdate), 'DD-MON-YYYY HH24:MI') from service_order_features
                  where sofe_sero_id = p_sero_id and sofe_provision_time is not null)
      where seoa_sero_id = p_sero_id
        and seoa_name like 'ACTUAL_DSP_DATE%';

    IF  l_unprovisioned_features IS NOT NULL then
     p_ret_char := 'Some of the requested features are not yet provisioned. ' || substr(l_unprovisioned_features,1,100) || '...' ;
    END IF;

  exception
    when others then
      p_ret_msg  := 'check_features_provisioned.  Erro is:' || to_char(sqlcode) ||'-'|| sqlerrm;
  END slt_check_CLI_fea_provisioned;

--- 03-08-2010  Fayaz Thahir

-- 18-08-2010 Samankula Owitipana
-- CREATE_TRANSFER

PROCEDURE P2P_CREATE_TRANSFER_WGCH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




v_CUSTYPE_VAL VARCHAR2(50);
v_DSU_CHANGED VARCHAR2(50);
v_P2PTYPE_VAL VARCHAR2(50);
v_MEDIA_TYPE_B VARCHAR2(50);



BEGIN


SELECT cu.cusr_cutp_type
INTO v_CUSTYPE_VAL
FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_P2PTYPE_VAL
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'P2P TYPE';

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_DSU_CHANGED
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSU TYPE CHANGED?';

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_MEDIA_TYPE_B
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MEDIA TYPE B END';


         IF v_CUSTYPE_VAL  = 'WHOLESALE'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSIF v_CUSTYPE_VAL  = 'SME'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         END IF;

        ----------------------------------------------------------------------------------------------------------------------

         IF (v_MEDIA_TYPE_B <> 'FIBER' OR v_MEDIA_TYPE_B IS NULL) and v_DSU_CHANGED = 'YES'  THEN

         null;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'INSTALL DSU- B END' ;


         END IF;

        -----------------------------------------------------------------------------------------------------------------------

         IF v_P2PTYPE_VAL = 'TX-LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-OPR-NM'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;

         END IF;


         -----------------------------------------------------------------------------------------------------------------------

         IF v_P2PTYPE_VAL = 'TX-LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'END TO END TEST' ;

         END IF;

         -----------------------------------------------------------------------------------------------------------------------

         IF v_P2PTYPE_VAL = 'TX-LEASED BEARER'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM  W/ CUSTOMER' ;

         END IF;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to change workgroups:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END P2P_CREATE_TRANSFER_WGCH ;

-- 18-08-2010 Samankula Owitipana


-- 01-09-2010 Samankula Owitipana
-- ADSL_CREATE_PSTN_CCT_AUTO_BUILD Version 02
--Circuit validation is added.

PROCEDURE ADSL_CREATE_PSTN_CCT_AUTO_V2 (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_ADSL_CCT_ID service_Orders.SERO_CIRT_NAME%TYPE;
v_PSTN_CCT circuits.CIRT_NAME%TYPE;
v_PSTN_NO SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
v_CHK_NGN ports.PORT_CARD_SLOT%TYPE;
v_CHK_PORT ports.PORT_NAME%TYPE;
v_CHK_ID ports.PORT_ID%TYPE;
v_DISP_NAME circuits.CIRT_DISPLAYNAME%TYPE;
v_serv_id service_Orders.SERO_SERV_ID%TYPE;

v_EQ_STAT equipment.EQUP_STATUS%TYPE;
v_PORT_STAT ports.PORT_STATUS%TYPE;

v_plp_ex port_link_ports.POLP_PORL_ID%TYPE;
v_plp_ex_1c port_link_ports.POLP_COMMONPORT%TYPE;
v_pl_seq_ex port_links.PORL_SEQUENCE%TYPE;
v_pl_fraa_ex port_link_ports.POLP_FRAA_ID%TYPE;

v_plp_ug port_link_ports.POLP_PORL_ID%TYPE;
v_plp_ug_1c port_link_ports.POLP_COMMONPORT%TYPE;
v_pl_seq_ug port_links.PORL_SEQUENCE%TYPE;
v_pl_fraa_ug port_link_ports.POLP_FRAA_ID%TYPE;

v_po_equip_id ports.PORT_EQUP_ID%TYPE;
v_portname_adsl ports.PORT_NAME%TYPE;
v_po_cardslot_adsl ports.PORT_CARD_SLOT%TYPE;

v_P_PORT_ID ports.PORT_ID%TYPE;
v_P_PHYC_ID ports.PORT_PHYC_ID%TYPE;
v_P_CACE_ID ports.PORT_CACE_ID%TYPE;
v_P_CABC_ID CABLE_CORE_ENDS.CACE_CABC_ID%TYPE;


v_POTS_PORT_ID ports.PORT_ID%TYPE;
v_POTS_PHYC_ID ports.PORT_PHYC_ID%TYPE;
v_POTS_CACE_ID ports.PORT_CACE_ID%TYPE;
v_POTS_CABC_ID CABLE_CORE_ENDS.CACE_CABC_ID%TYPE;

v_POTS_FRAA_ID_REAR FRAME_APPEARANCES.FRAA_ID%TYPE;
v_POTS_FRAU_ID FRAME_APPEARANCES.FRAA_FRAU_ID%TYPE;
v_POTS_FRAA_POSITION FRAME_APPEARANCES.FRAA_POSITION%TYPE;
v_POTS_FRAA_ID_FRONT FRAME_APPEARANCES.FRAA_ID%TYPE;

v_P_FRAA_ID_REAR FRAME_APPEARANCES.FRAA_ID%TYPE;
v_P_FRAU_ID FRAME_APPEARANCES.FRAA_FRAU_ID%TYPE;
v_P_FRAA_POSITION FRAME_APPEARANCES.FRAA_POSITION%TYPE;
v_P_FRAA_ID_FRONT FRAME_APPEARANCES.FRAA_ID%TYPE;

v_pl_id_1 port_links.PORL_ID%TYPE;
v_pl_id_2 port_links.PORL_ID%TYPE;
v_pl_id_3 port_links.PORL_ID%TYPE;
v_pl_id_4 port_links.PORL_ID%TYPE;

v_CHK_P_PORT_ID ports.PORT_ID%TYPE;
v_CHK_POTS_PORT_ID ports.PORT_ID%TYPE;
v_CHK_P_FRAA_ID FRAME_APPEARANCES.FRAA_ID%TYPE;
v_CHK_POTS_FRAA_ID FRAME_APPEARANCES.FRAA_ID%TYPE;

v_CHK_PROPOSE ports.PORT_ID%TYPE;
v_PRO_CCT_ID circuits.CIRT_DISPLAYNAME%TYPE;


CURSOR PROPOSED_select_cur  IS
select ci.CIRT_DISPLAYNAME
from PORT_LINKS pl,PORT_LINK_PORTS plp,circuits ci
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and plp.POLP_PORT_ID = v_CHK_PROPOSE
and pl.PORL_CIRT_NAME <> v_ADSL_CCT_ID;

cursor c_fa_chk is
select ci.CIRT_DISPLAYNAME
from circuits ci,port_links pl,port_link_ports plp
where plp.POLP_PORL_ID = pl.PORL_ID
and pl.PORL_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_SERV_ID <> v_serv_id
and plp.POLP_PORT_ID = v_CHK_ID;

BEGIN



P_SERVICE_ORDER.SLT_SET_ADSL_EQIP_MODEL(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);




IF p_ret_msg is null THEN


SELECT so.SERO_CIRT_NAME,so.SERO_SERV_ID
INTO v_ADSL_CCT_ID,v_serv_id
FROM Service_Orders so
WHERE so.SERO_ID = p_sero_id;

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_PSTN_NO
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

SELECT ci.CIRT_NAME
INTO v_PSTN_CCT
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_PSTN_NO || '%'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');


select po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID,eq.EQUP_STATUS,po.PORT_STATUS
into v_CHK_NGN, v_CHK_PORT, v_CHK_ID, v_EQ_STAT, v_PORT_STAT
from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = eq.EQUP_ID
and plp.POLP_COMMONPORT = 'F'
and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;


    OPEN c_fa_chk;
    FETCH c_fa_chk INTO v_DISP_NAME;
    CLOSE c_fa_chk;


IF v_EQ_STAT <> 'INSERVICE' or v_PORT_STAT <> 'INSERVICE' THEN

p_ret_msg  := 'Equipment or port status not INSERVICE';


ELSIF v_DISP_NAME is not null THEN


p_ret_msg  := 'CARD '||v_CHK_NGN || 'PORT ' || v_CHK_PORT || ' is reserved for ' || v_DISP_NAME || ' circuit' ;


ELSIF v_CHK_NGN not like 'M%' and v_CHK_NGN not like 'D%' and v_CHK_NGN not like 'A%' and v_CHK_NGN not like 'Z%' THEN

p_ret_msg  := 'Wrong card type selected for from side';

ELSIF v_CHK_NGN like 'A%' and v_CHK_PORT not like '%P0' THEN

p_ret_msg  := 'Wrong port type selected. Please select a combo port';

ELSIF v_CHK_NGN like 'Z%' and v_CHK_PORT not like '%P0' THEN

p_ret_msg  := 'Wrong port type selected. Please select a combo port';

ELSE


  IF v_CHK_NGN like 'M%' or v_CHK_NGN like 'D%' THEN




    BEGIN


      IF v_CHK_NGN like 'M%' THEN

       select po.PORT_EQUP_ID,trim(replace(po.PORT_NAME,'P','')),replace(po.PORT_CARD_SLOT,'M','P'),po.PORT_ID
      INTO v_po_equip_id,v_portname_adsl,v_po_cardslot_adsl,v_CHK_PROPOSE
      from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp
      where pl.PORL_ID = plp.POLP_PORL_ID
      and plp.POLP_PORT_ID = po.PORT_ID
      and plp.POLP_COMMONPORT = 'F'
      and po.PORT_NAME like 'P%'
      and po.PORT_CARD_SLOT like 'M%'
      and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

      ELSE

      select po.PORT_EQUP_ID,trim(replace(po.PORT_NAME,'P','')),replace(po.PORT_CARD_SLOT,'D','P'),po.PORT_ID
      INTO v_po_equip_id,v_portname_adsl,v_po_cardslot_adsl,v_CHK_PROPOSE
      from ports po,PORT_LINKS pl,PORT_LINK_PORTS plp
      where pl.PORL_ID = plp.POLP_PORL_ID
      and plp.POLP_PORT_ID = po.PORT_ID
      and plp.POLP_COMMONPORT = 'F'
      and po.PORT_NAME like 'P%'
      and po.PORT_CARD_SLOT like 'D%'
      and pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

      END IF;



      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
      INTO v_plp_ex,v_plp_ex_1c,v_pl_seq_ex,v_pl_fraa_ex
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      and plp.POLP_PORL_ID = pl.PORL_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%EX%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND pl.PORL_CIRT_NAME = v_PSTN_CCT;



      SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
      INTO v_plp_ug,v_plp_ug_1c,v_pl_seq_ug,v_pl_fraa_ug
      FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
      WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
      AND fu.FRAU_ID = fa.FRAA_FRAU_ID
      AND fa.FRAA_ID = plp.POLP_FRAA_ID
      and plp.POLP_PORL_ID = pl.PORL_ID
      AND fc.FRAC_FRAN_NAME = 'MDF'
      AND fu.FRAU_NAME LIKE '%UG%'
      AND fa.FRAA_SIDE = 'FRONT'
      AND pl.PORL_CIRT_NAME = v_PSTN_CCT;






      select po.PORT_ID,cce.CACE_CABC_ID,cce.CACE_ID,cce.CACE_PHYC_ID
      into v_P_PORT_ID,v_P_CABC_ID,v_P_CACE_ID,v_P_PHYC_ID
      from ports po,CABLE_CORE_ENDS cce
      where po.PORT_PHYC_ID = cce.CACE_PHYC_ID
      and po.PORT_CACE_ID = cce.CACE_ID
      and po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'P' || v_portname_adsl;

      select po.PORT_ID,cce.CACE_CABC_ID,cce.CACE_ID,cce.CACE_PHYC_ID
      into v_POTS_PORT_ID,v_POTS_CABC_ID,v_POTS_CACE_ID,v_POTS_PHYC_ID
      from ports po,CABLE_CORE_ENDS cce
      where po.PORT_PHYC_ID = cce.CACE_PHYC_ID
      and po.PORT_CACE_ID = cce.CACE_ID
      and po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'POTS' || v_portname_adsl;


      select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
      into v_POTS_FRAA_ID_REAR,v_POTS_FRAU_ID,v_POTS_FRAA_POSITION
      from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
      where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
      and cce.CACE_ID = fa.FRAA_CACE_ID
      and cce.CACE_CABC_ID = v_POTS_CABC_ID
      and cce.CACE_PHYC_ID <> v_POTS_PHYC_ID
      and cce.CACE_ID <> v_POTS_CACE_ID;


     select fa.FRAA_ID
     into v_POTS_FRAA_ID_FRONT
     from FRAME_APPEARANCES fa
     where fa.FRAA_FRAU_ID = v_POTS_FRAU_ID
     and fa.FRAA_POSITION = v_POTS_FRAA_POSITION
     and fa.FRAA_SIDE = 'FRONT';

     select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
      into v_P_FRAA_ID_REAR,v_P_FRAU_ID,v_P_FRAA_POSITION
      from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
      where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
      and cce.CACE_ID = fa.FRAA_CACE_ID
      and cce.CACE_CABC_ID = v_P_CABC_ID
      and cce.CACE_PHYC_ID <> v_P_PHYC_ID
      and cce.CACE_ID <> v_P_CACE_ID;


     select fa.FRAA_ID
     into v_P_FRAA_ID_FRONT
     from FRAME_APPEARANCES fa
     where fa.FRAA_FRAU_ID = v_P_FRAU_ID
     and fa.FRAA_POSITION = v_P_FRAA_POSITION
     and fa.FRAA_SIDE = 'FRONT';




    EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := 'SET VARIABLES FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;

------------------Check for Proposed Ports----------------------------------------------------

    OPEN PROPOSED_select_cur;
    FETCH PROPOSED_select_cur INTO v_PRO_CCT_ID;
    CLOSE PROPOSED_select_cur;


    IF v_PRO_CCT_ID is not null THEN

    p_ret_msg  := 'THIS ADSL PORT IS RESERVED FOR ' || v_PRO_CCT_ID ||'. PLEASE RESERVE A FREE PORT';

    END IF;



--------------- Check Availability ------------------------------------------------------------

DECLARE

 cursor GET_P_PORT_ID is
 select distinct plp.POLP_PORT_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_PORT_ID = v_P_PORT_ID;

 cursor GET_POTS_PORT_ID is
 select distinct plp.POLP_PORT_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_PORT_ID = v_POTS_PORT_ID;

 cursor GET_P_FRAA_ID is
 select distinct plp.POLP_FRAA_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_FRAA_ID = v_P_FRAA_ID_FRONT;

 cursor GET_POTS_FRAA_ID is
 select distinct plp.POLP_FRAA_ID
 from PORT_LINKS pl,port_link_ports plp
 where pl.PORL_ID = plp.POLP_PORL_ID
 and pl.PORL_CIRT_NAME = v_PSTN_CCT
 and plp.POLP_FRAA_ID = v_POTS_FRAA_ID_FRONT;

 BEGIN


    OPEN GET_P_PORT_ID;
    FETCH GET_P_PORT_ID INTO v_CHK_P_PORT_ID;
    CLOSE GET_P_PORT_ID;

    OPEN GET_POTS_PORT_ID;
    FETCH GET_POTS_PORT_ID INTO v_CHK_POTS_PORT_ID;
    CLOSE GET_POTS_PORT_ID;

    OPEN GET_P_FRAA_ID;
    FETCH GET_P_FRAA_ID INTO v_CHK_P_FRAA_ID;
    CLOSE GET_P_FRAA_ID;

    OPEN GET_P_FRAA_ID;
    FETCH GET_P_FRAA_ID INTO v_CHK_POTS_FRAA_ID;
    CLOSE GET_P_FRAA_ID;

 END;

----------------------------------------------------------------------------------------------


 IF    v_CHK_P_PORT_ID is null AND v_CHK_POTS_PORT_ID is null AND v_CHK_P_FRAA_ID is null AND v_CHK_POTS_FRAA_ID is null THEN


    BEGIN

         IF v_plp_ug_1c = 'F' THEN



         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+1, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+2, 'LOGICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+3, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ug+4, 'JUMPER', NULL, 'Y');


        ELSE


         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+1, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+2, 'LOGICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+3, 'PHYSICAL', NULL, 'Y');

         INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
                            VALUES ( PORL_ID_SEQ.nextval, v_PSTN_CCT, v_pl_seq_ex+4, 'JUMPER', NULL, 'Y');


       END IF;






    EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := p_ret_msg || 'PORT LINK INSERT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;


 IF v_plp_ug_1c = 'F' THEN


 select pl.PORL_ID
 into v_pl_id_1
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+1;

 select pl.PORL_ID
 into v_pl_id_2
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+2;

 select pl.PORL_ID
 into v_pl_id_3
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+3;

 select pl.PORL_ID
 into v_pl_id_4
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ug+4;


 ELSE


 select pl.PORL_ID
 into v_pl_id_1
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+1;

 select pl.PORL_ID
 into v_pl_id_2
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+2;

 select pl.PORL_ID
 into v_pl_id_3
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+3;

 select pl.PORL_ID
 into v_pl_id_4
 from PORT_LINKS pl
 where pl.PORL_CIRT_NAME = v_PSTN_CCT
 and pl.PORL_SEQUENCE = v_pl_seq_ex+4;

 END IF;


      BEGIN



     IF v_plp_ug_1c = 'F' THEN




     UPDATE PORT_LINK_PORTS
     SET POLP_FRAA_ID = v_P_FRAA_ID_FRONT
     WHERE POLP_PORL_ID = v_plp_ug
     AND POLP_COMMONPORT = 'T';


    INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_1, 'F', v_P_FRAA_ID_REAR);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_1, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_2, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_2, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_3, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_3, 'T',v_POTS_FRAA_ID_REAR );

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'F',v_POTS_FRAA_ID_FRONT );


    INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'T',v_pl_fraa_ex );





     ELSE

    UPDATE PORT_LINK_PORTS
     SET POLP_FRAA_ID = v_POTS_FRAA_ID_FRONT
     WHERE POLP_PORL_ID = v_plp_ex
     AND POLP_COMMONPORT = 'T';

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_1, 'F',v_POTS_FRAA_ID_REAR );


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_1, 'T', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_POTS_PORT_ID, v_pl_id_2, 'F', NULL);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_2, 'T', NULL);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( v_P_PORT_ID, v_pl_id_3, 'F', NULL);

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_3, 'T',v_P_FRAA_ID_REAR );

     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'F',v_P_FRAA_ID_FRONT);


     INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
                            VALUES ( NULL, v_pl_id_4, 'T', v_pl_fraa_ug);





     END IF;

      update ports po
      set po.PORT_CIRT_NAME = v_PSTN_CCT
      where po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'P' || v_portname_adsl;


      update ports po
      set po.PORT_CIRT_NAME = v_PSTN_CCT
      where po.PORT_EQUP_ID = v_po_equip_id
      and po.PORT_CARD_SLOT = v_po_cardslot_adsl
      and po.PORT_NAME = 'POTS' || v_portname_adsl;


     update FRAME_APPEARANCES fa
     set fa.FRAA_CIRT_NAME = v_PSTN_CCT
     where fa.FRAA_FRAU_ID = v_POTS_FRAU_ID
     and fa.FRAA_POSITION = v_POTS_FRAA_POSITION;


     update FRAME_APPEARANCES fa
     set fa.FRAA_CIRT_NAME = v_PSTN_CCT
     where fa.FRAA_FRAU_ID = v_P_FRAU_ID
     and fa.FRAA_POSITION = v_P_FRAA_POSITION;



     EXCEPTION
    WHEN OTHERS THEN


    p_ret_msg  := p_ret_msg || 'PORT LINK PORT INSERT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    END;

  ELSIF v_CHK_P_PORT_ID is not null AND v_CHK_POTS_PORT_ID is not null AND v_CHK_P_FRAA_ID is not null AND v_CHK_POTS_FRAA_ID is not null THEN

  NULL;

  ELSE

  p_ret_msg  := 'WRONG ADSL CROSSCONNECTION IN PSTN CCT';

  END IF;

 END IF;

END IF;

ELSE

      p_ret_msg := p_ret_msg || ' Failed to UPDATE ADSL_EQUIP_MODEL.';

END IF;







EXCEPTION
WHEN OTHERS THEN


    p_ret_msg  := 'PSTN CCT ADD CROSS CONNECTIONS FAILED. CHECK SA_PSTN_NUMBER ATTRIBUTE AND PSTN CIRCUIT' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;



END ADSL_CREATE_PSTN_CCT_AUTO_V2;

-- 01-09-2010 Samankula Owitipana


-- 2010/11/10 jayan Liyanage
--- Transmissions WG Changes " Create Order Type" ----

PROCEDURE SLT_INT_CREATE_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS
   CURSOR cur_link_type
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'LINK TYPE';

   CURSOR cur_so_type
   IS
      SELECT so.sero_ordt_type
        FROM service_orders so
       WHERE so.sero_id = p_sero_id;

   CURSOR cur_sa_exc_code
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id
         AND soa.seoa_name = 'SA_EXCHANGE_CODE';

   v_link_type   VARCHAR2 (100);
   v_so_type     VARCHAR2 (100);
   v_exc_code    VARCHAR2 (100);
BEGIN
   OPEN cur_link_type;

   FETCH cur_link_type
    INTO v_link_type;

   CLOSE cur_link_type;

   OPEN cur_so_type;

   FETCH cur_so_type
    INTO v_so_type;

   CLOSE cur_so_type;

   OPEN cur_sa_exc_code;

   FETCH cur_sa_exc_code
    INTO v_exc_code;

   CLOSE cur_sa_exc_code;

   IF v_link_type = 'SW-SW' AND v_so_type = 'CREATE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'IDENTIFY PARAMETERS';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'DESIGN CIRCUIT';
   ELSIF v_link_type <> 'SW-SW' AND v_so_type = 'CREATE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'IDENTIFY PARAMETERS';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'DESIGN CIRCUIT';
   END IF;

   ----------------------------------  FILL ATTRIB:SW "A" END  ----------
  /* IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   END IF;

   --------------------------------------- FILL ATTRIB:SW "B" END ---------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   END IF;

   ------------------------------ WO TO SW "A" END -------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   END IF;

--------------------------  WO TO SW " B " END ----------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   END IF; */

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );
      p_ret_msg :=
            'Faild to WorkGroup Changing  :'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                   p_ret_msg
                  );
END SLT_INT_CREATE_WG_CHANGE;
-- 2010/11/10 jayan Liyanage


-- 2010/11/10 jayan Liyanage
--- Transmissions WG Changes " Modify-Feature " ----

PROCEDURE SLT_INT_MODIFY_FEATU_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS
   CURSOR cur_link_type
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'LINK TYPE';

   CURSOR cur_so_type
   IS
      SELECT so.sero_ordt_type
        FROM service_orders so
       WHERE so.sero_id = p_sero_id;

   CURSOR cur_sa_exc_code
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id
         AND soa.seoa_name = 'SA_EXCHANGE_CODE';

   v_link_type   VARCHAR2 (100);
   v_so_type     VARCHAR2 (100);
   v_exc_code    VARCHAR2 (100);
BEGIN
   OPEN cur_link_type;

   FETCH cur_link_type
    INTO v_link_type;

   CLOSE cur_link_type;

   OPEN cur_so_type;

   FETCH cur_so_type
    INTO v_so_type;

   CLOSE cur_so_type;

   OPEN cur_sa_exc_code;

   FETCH cur_sa_exc_code
    INTO v_exc_code;

   CLOSE cur_sa_exc_code;

   IF v_link_type = 'SW-SW' AND v_so_type = 'MODIFY-FEATURE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';
   ELSIF v_link_type <> 'SW-SW' AND v_so_type = 'MODIFY-FEATURE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';
   END IF;

   ----------------------------------  FILL ATTRIB:SW "A" END  ----------
 /*  IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW AEND';
   END IF;

   ------------------------------  FILL ATTRIB:SW "B" END ----------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'FILL ATTRIB:SW BEND';
   END IF;

   ---------------------------  WO TO SW "A END ---------------------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   END IF;

   ---------------------------   WO TO SW "B" END ----------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   END IF; */

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );
      p_ret_msg :=
            'Faild to WorkGroup Changing  :'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                   p_ret_msg
                  );
END SLT_INT_MODIFY_FEATU_WG_CHANGE;
-- 2010/11/10 jayan Liyanage


-- 2010/11/10 jayan Liyanage
--- Transmissions WG Changes " Modify_Others " ----

PROCEDURE SLT_INT_MODIFY_OTH_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS
   CURSOR cur_link_type
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'LINK TYPE';

   CURSOR cur_so_type
   IS
      SELECT so.sero_ordt_type
        FROM service_orders so
       WHERE so.sero_id = p_sero_id;

   CURSOR cur_sa_exc_code
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id
         AND soa.seoa_name = 'SA_EXCHANGE_CODE';

   v_link_type   VARCHAR2 (100);
   v_so_type     VARCHAR2 (100);
   v_exc_code    VARCHAR2 (100);
BEGIN
   OPEN cur_link_type;

   FETCH cur_link_type
    INTO v_link_type;

   CLOSE cur_link_type;

   OPEN cur_so_type;

   FETCH cur_so_type
    INTO v_so_type;

   CLOSE cur_so_type;

   OPEN cur_sa_exc_code;

   FETCH cur_sa_exc_code
    INTO v_exc_code;

   CLOSE cur_sa_exc_code;

   IF v_link_type = 'SW-SW' AND v_so_type = 'MODIFY-OTHERS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'IDENTIFY MODIFICATIO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';


      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'UPDATE CIRCUIT';

   ELSIF v_link_type <> 'SW-SW' AND v_so_type = 'MODIFY-OTHERS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'IDENTIFY MODIFICATIO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';


      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'UPDATE CIRCUIT';

   END IF;

------------------  ACK. TO SW "A" END -------------------------------------
 /*  IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW A END';
   END IF;

   ------------------------  ACK. TO SW "B" END  -----------------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACK. TO SW B END';
   END IF;

   -----------------------   WO TO SW "A" END ------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   END IF;

   ----------------------  WO TO SW "B" END -------------------------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   END IF; */

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );
      p_ret_msg :=
            'Faild to WorkGroup Changing  :'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                   p_ret_msg
                  );
END SLT_INT_MODIFY_OTH_WG_CHANGE;
-- 2010/11/10 jayan Liyanage

-- 2010/11/10 jayan Liyanage
--- Transmissions WG Changes " DELETE " ----

PROCEDURE SLT_INT_DELETE_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS
   CURSOR cur_link_type
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'LINK TYPE';

   CURSOR cur_so_type
   IS
      SELECT so.sero_ordt_type
        FROM service_orders so
       WHERE so.sero_id = p_sero_id;

   CURSOR cur_sa_exc_code
   IS
      SELECT soa.seoa_defaultvalue
        FROM service_order_attributes soa
       WHERE soa.seoa_sero_id = p_sero_id
         AND soa.seoa_name = 'SA_EXCHANGE_CODE';

   v_link_type   VARCHAR2 (100);
   v_so_type     VARCHAR2 (100);
   v_exc_code    VARCHAR2 (100);
BEGIN
   OPEN cur_link_type;

   FETCH cur_link_type
    INTO v_link_type;

   CLOSE cur_link_type;

   OPEN cur_so_type;

   FETCH cur_so_type
    INTO v_so_type;

   CLOSE cur_so_type;

   OPEN cur_sa_exc_code;

   FETCH cur_sa_exc_code
    INTO v_exc_code;

   CLOSE cur_sa_exc_code;

   IF v_link_type = 'SW-SW'   THEN

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-SW'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM DELETION';

   ELSIF v_link_type <> 'SW-SW'  THEN

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'APPROVE SO';

      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM DELETION';

   END IF;

   -----------------------   WO TO SW "A" END ------------------------
 /*  IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW A END';
   END IF;

   -------------------------   WO TO SW "B" END ---------------------
   IF v_exc_code = 'S-ZS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC1'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZW'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC3'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-ZE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-ISC4'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-SW-CCS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-IPS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-IPS'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-FNS'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-VOIP'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   ELSIF v_exc_code = 'S-CZ' OR v_exc_code = 'S-TZ' OR v_exc_code = 'S-AZ'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-CDMA-MSC'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'WO TO SW B END';
   END IF; */



 -----------------------------------------APPROVE SO----------------------------------------------------------------

         IF v_link_type = 'SW-SW' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-SW'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSE

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'OPR-NETMGT-TX'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );
      p_ret_msg :=
            'Faild to WorkGroup Changing  :'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                   p_ret_msg
                  );
END SLT_INT_DELETE_WG_CHANGE;
-- 2010/11/10 jayan Liyanage



-- 18-11-2010 Samankula Owitipana

PROCEDURE SLTINT_SET_NULL_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




BEGIN




UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = null
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'EXPECTED DATE OF COMMISSIONING' ;





p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to set blank EXPECTED DATE OF COMMISSIONING attribute. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        ,p_ret_msg );

END SLTINT_SET_NULL_ATTR;

-- 18-11-2010 Samankula Owitipana


-- 02-07-20010 Samankula Owitipana

PROCEDURE WIMAX_SET_DATACCT_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cct_select_cur  IS
SELECT NU.NUMB_NUMBER FROM NUMBERS NU
WHERE nu.NUMB_SERV_ID = p_serv_id;


v_CCT_ID numbers.NUMB_NUMBER%TYPE;


BEGIN

OPEN cct_select_cur;
FETCH cct_select_cur INTO v_CCT_ID;
CLOSE cct_select_cur;



UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE =  'W' || v_CCT_ID
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'CIRCUIT ID' ;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      p_ret_msg  := 'Failed to set CIRCUIT ID ATTRIBUTE. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg || v_CCT_ID);

END WIMAX_SET_DATACCT_ATTR;

-- 02-07-20010 Samankula Owitipana

-- 16-09-2010 Samankula Owitipana

PROCEDURE SLT_WIMAX_CREATE_PRO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
    v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
    v_bsid     VARCHAR2(200);v_pkg     VARCHAR2(200);v_paytp  NUMBER;
    v_pkggroup VARCHAR2(100);v_domain VARCHAR2(200);v_gpid      NUMBER;
    v_speed     VARCHAR2(100);env       VARCHAR2(32767);http_req  UTL_HTTP.REQ;
    http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;in_xml    sys.XMLTYPE;
    url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';
    v_state   VARCHAR2(100);v_state_1 VARCHAR2(400); v_pre_val VARCHAR2(10);
    v_new_val VARCHAR2(10);v_fea_name VARCHAR2(100);
CURSOR c_feature_select IS
SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id;
BEGIN SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_bsid FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BS ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkg FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'WIMAX PACKAGE NAME';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE'; 
SELECT SOA.SEOA_DEFAULTVALUE
INTO v_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF v_pkg = 'Post Paid' THEN v_paytp := '1';
ELSIF v_pkg = 'Pre Paid' THEN v_paytp := '2'; END IF;
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk'; v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk'; v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk'; v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk'; v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk'; v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk'; v_gpid      := '21';END IF;
env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
 <SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id || '</Serial><BizCode>ADDWIMAX</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</TIME><Pri>1</Pri><TIMEOUT>30000</TIMEOUT>
<ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</ReservedExeTime>
<ParaList><Para><NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE></Para><Para>
<NAME>DOMAIN</NAME><VALUE>' || v_domain || '</VALUE></Para><Para><NAME>CHARGEAMOUNT</NAME>
<VALUE></VALUE></Para><Para><NAME>PSWD</NAME><VALUE>' || v_cct || '</VALUE></Para><Para>
<NAME>USERTYPE</NAME><VALUE></VALUE></Para><Para><NAME>USERGROUPID</NAME><VALUE>' || v_gpid || '</VALUE>
</Para><Para><NAME>PAIDTYPE</NAME><VALUE>' || v_paytp || '</VALUE></Para><Para><NAME>MSID</NAME>
<VALUE>' || v_mac || '</VALUE></Para><Para><NAME>BSID</NAME><VALUE>' || v_bsid || '</VALUE>
</Para></ParaList></MessageBody></RequestMessage></SyncRequestMsg></m:SendSyncReq></SOAP-ENV:BODY></SOAP-ENV:Envelope>';
http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');
--   utl_http.set_proxy('proxy:80', NULL);--   utl_http.set_persistent_conn_support(TRUE);
--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');UTL_HTTP.WRITE_TEXT(http_req, env);
http_resp := UTL_HTTP.GET_RESPONSE(http_req);UTL_HTTP.READ_TEXT(http_resp, env);UTL_HTTP.END_RESPONSE(http_resp);
in_xml := sys.XMLTYPE.createxml(env);resp := XMLTYPE.createxml(env);
v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING - ' || v_state || '...';
OPEN c_feature_select; LOOP v_pre_val := NULL; v_new_val := NULL; v_fea_name := NULL;
                FETCH c_feature_select INTO v_fea_name, v_new_val, v_pre_val;
                EXIT WHEN c_feature_select%NOTFOUND;
                IF (v_new_val = 'Y' AND v_pre_val IS NULL) OR (v_new_val = 'Y' AND v_pre_val = 'N') THEN
                UPDATE SERVICE_ORDER_FEATURES sof
                SET sof.sofe_provision_status = 'Y',
                sof.SOFE_PROVISION_TIME = sysdate
                WHERE sof.sofe_sero_id= p_sero_id
                AND sof.sofe_feature_name = v_fea_name;END IF;END LOOP; CLOSE c_feature_select;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , v_state_1 || v_gpid);ELSE P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,
p_impt_taskname,p_woro_id,p_ret_char,p_ret_number,p_ret_msg);
v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, v_state_1 || v_gpid);END IF; EXCEPTION WHEN OTHERS THEN
p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,
p_woro_id,p_ret_char,p_ret_number,p_ret_msg);INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg || v_gpid); END SLT_WIMAX_CREATE_PRO;    
 -- 16-09-2010 Samankula Owitipana

-- 16-09-2010 Samankula Owitipana

PROCEDURE SLT_WIMAX_DELETE_PRO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
    v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
	v_bsid     VARCHAR2(200);v_pkg     VARCHAR2(200);v_paytp  NUMBER;
    v_pkggroup VARCHAR2(100);v_domain VARCHAR2(200);v_gpid      NUMBER;
    v_speed  VARCHAR2(100);env       VARCHAR2(32767);http_req  UTL_HTTP.REQ;
    http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;in_xml    sys.XMLTYPE;
    url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';
    v_state   VARCHAR2(100);v_state_1 VARCHAR2(400);v_pre_val VARCHAR2(10);
	v_new_val VARCHAR2(10);v_fea_name VARCHAR2(100);
CURSOR c_feature_select IS
SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id;BEGIN
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';
SELECT SOA.SEOA_DEFAULTVALUE
INTO v_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk';v_gpid      := '21';END IF;
env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id  || '</Serial><BizCode>RMVWIMAX</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</TIME><Pri>1</Pri><TIMEOUT>30000</TIMEOUT>
<ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</ReservedExeTime>
<ParaList><Para><NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE></Para><Para>
<NAME>DOMAIN</NAME><VALUE>' || v_domain || '</VALUE></Para><Para><NAME>REMOVEALL</NAME>
<VALUE>1</VALUE></Para></ParaList></MessageBody></RequestMessage></SyncRequestMsg>
</m:SendSyncReq></SOAP-ENV:BODY></SOAP-ENV:Envelope>';
http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');
UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');--   utl_http.set_proxy('proxy:80', NULL);
--   utl_http.set_persistent_conn_support(TRUE);--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');UTL_HTTP.WRITE_TEXT(http_req, env);
http_resp := UTL_HTTP.GET_RESPONSE(http_req);UTL_HTTP.READ_TEXT(http_resp, env);UTL_HTTP.END_RESPONSE(http_resp);
in_xml := sys.XMLTYPE.createxml(env);resp := XMLTYPE.createxml(env);
v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING REMOVEALL- ' || v_state || '...';
UPDATE SERVICE_ORDER_ATTRIBUTES SA SET SA.SEOA_DEFAULTVALUE = TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI')
WHERE SA.SEOA_NAME = 'ACTUAL_DSP_DATE'AND SA.SEOA_SERO_ID = p_sero_id; OPEN c_feature_select;
LOOP  v_pre_val := NULL; v_new_val := NULL; v_fea_name := NULL;
FETCH c_feature_select INTO v_fea_name, v_new_val, v_pre_val;EXIT WHEN c_feature_select%NOTFOUND;
IF (v_new_val = 'Y' AND v_pre_val IS NULL) OR (v_new_val = 'Y' AND v_pre_val = 'N') THEN
UPDATE SERVICE_ORDER_FEATURES sof SET sof.sofe_provision_status = 'Y', sof.SOFE_PROVISION_TIME = sysdate
WHERE sof.sofe_sero_id= p_sero_id AND sof.sofe_feature_name = v_fea_name;END IF;END LOOP;
CLOSE c_feature_select;INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1);
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');ELSE
P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,p_woro_id,p_ret_char,
p_ret_number,p_ret_msg);v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1 );END IF;EXCEPTION WHEN OTHERS THEN
p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg );END SLT_WIMAX_DELETE_PRO;    
-- 16-09-2010 Samankula Owitipana

-- 16-09-2010 Samankula Owitipana

PROCEDURE SLT_WIMAX_MODFEA_PRO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
    v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
    v_bsid     VARCHAR2(200);v_pkg     VARCHAR2(200);v_paytp  NUMBER;
    v_pkggroup VARCHAR2(100);v_domain VARCHAR2(200);v_gpid      NUMBER;
	v_speed  VARCHAR2(100);v_old_speed VARCHAR2(100);v_gpid_old  VARCHAR2(100);
    v_old_pkggroup VARCHAR2(100);env       VARCHAR2(32767);http_req  UTL_HTTP.REQ;
    http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;in_xml    sys.XMLTYPE;
	url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';v_state   VARCHAR2(100);
    v_state_1 VARCHAR2(400);v_pre_val VARCHAR2(10);v_new_val VARCHAR2(10);v_fea_name VARCHAR2(100);
CURSOR c_feature_select IS SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof WHERE sof.sofe_sero_id= p_sero_id;BEGIN
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE 
INTO v_pkggroup,v_old_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';
SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE 
INTO v_speed,v_old_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk';v_gpid      := '21';END IF;
IF v_old_pkggroup = 'Biz-Express' AND v_old_speed = '4096K/512K' THEN
v_gpid_old  := '25';ELSIF v_old_pkggroup = 'Office-Express' AND v_old_speed = '2048K/512K' THEN
v_gpid_old  := '24';ELSIF v_old_pkggroup = 'Standard' AND v_old_speed = '1024K/256K' THEN
v_gpid_old  := '23';ELSIF v_old_pkggroup = 'Home-Express' AND v_old_speed = '1024K/256K' THEN
v_gpid_old      := '22';ELSIF v_old_pkggroup = 'Home-Lite' AND v_old_speed = '512K/128K' THEN
v_gpid_old      := '21';END IF;env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id  || '</Serial><BizCode>MODSPEED</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</TIME><Pri>1</Pri><TIMEOUT>30000</TIMEOUT>
<ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</ReservedExeTime><ParaList><Para>
<NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE></Para><Para><NAME>DOMAIN</NAME>
<VALUE>' || v_domain || '</VALUE></Para><Para><NAME>TEMPLATEID</NAME><VALUE>-1</VALUE>
</Para><Para><NAME>NEWUSERGROUPID</NAME><VALUE>' || v_gpid || '</VALUE></Para><Para>
<NAME>NEWGRPEFFECTTIME</NAME><VALUE>'||to_char(sysdate +0.001,'YYYYMMDDhh24miss')||'</VALUE>
</Para><Para><NAME>USERGROUPID</NAME><VALUE>' || v_gpid_old || '</VALUE></Para>
<Para><NAME>MSID</NAME><VALUE>' || v_mac || '</VALUE></Para></ParaList></MessageBody>
</RequestMessage></SyncRequestMsg></m:SendSyncReq></SOAP-ENV:BODY></SOAP-ENV:Envelope>';
http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');
--   utl_http.set_proxy('proxy:80', NULL);--   utl_http.set_persistent_conn_support(TRUE);
--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');UTL_HTTP.WRITE_TEXT(http_req, env);
http_resp := UTL_HTTP.GET_RESPONSE(http_req);UTL_HTTP.READ_TEXT(http_resp, env);
UTL_HTTP.END_RESPONSE(http_resp);in_xml := sys.XMLTYPE.createxml(env);resp := XMLTYPE.createxml(env);
v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING MODIFY SPEED- ' || v_state || '...';
UPDATE SERVICE_ORDER_ATTRIBUTES SA SET SA.SEOA_DEFAULTVALUE = TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI')
WHERE SA.SEOA_NAME = 'ACTUAL_DSP_DATE'AND SA.SEOA_SERO_ID = p_sero_id;OPEN c_feature_select;LOOP
v_pre_val := NULL;v_new_val := NULL;v_fea_name := NULL;FETCH c_feature_select INTO v_fea_name, v_new_val, v_pre_val;
EXIT WHEN c_feature_select%NOTFOUND;IF (v_new_val = 'Y' AND v_pre_val IS NULL) OR (v_new_val = 'Y' AND v_pre_val = 'N') THEN
UPDATE SERVICE_ORDER_FEATURES sof SET sof.sofe_provision_status = 'Y', sof.SOFE_PROVISION_TIME = sysdate WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = v_fea_name;END IF;END LOOP;CLOSE c_feature_select;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1);
ELSE P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,p_woro_id,
p_ret_char,p_ret_number,p_ret_msg);v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1 );END IF;EXCEPTION
WHEN OTHERS THEN p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg );END SLT_WIMAX_MODFEA_PRO;    
-- 16-09-2010 Samankula Owitipana

-- 20-09-2010 Samankula Owitipana

PROCEDURE SLT_WIMAX_SUSPEND_PRO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
    v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
    v_bsid     VARCHAR2(200);v_pkg     VARCHAR2(200);v_paytp  NUMBER;
    v_pkggroup VARCHAR2(100);v_domain VARCHAR2(200);v_gpid      NUMBER;
	v_speed  VARCHAR2(100);env       VARCHAR2(32767);
    http_req  UTL_HTTP.REQ;http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;
    in_xml    sys.XMLTYPE;url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';
	v_state   VARCHAR2(100);v_state_1 VARCHAR2(400);v_pre_val VARCHAR2(10);
	v_new_val VARCHAR2(10);v_fea_name VARCHAR2(100);CURSOR c_feature_select IS
	SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
	FROM SERVICE_ORDER_FEATURES sof WHERE sof.sofe_sero_id= p_sero_id;BEGIN
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';
SELECT SOA.SEOA_DEFAULTVALUE
INTO v_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk';v_gpid      := '21';END IF;env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id  || '</Serial><BizCode>DEACTIVESUB</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</TIME><Pri>1</Pri><TIMEOUT>30000</TIMEOUT>
<ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</ReservedExeTime><ParaList><Para>
<NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE></Para><Para><NAME>DOMAIN</NAME>
<VALUE>' || v_domain || '</VALUE></Para><Para><NAME>MSID</NAME><VALUE>' || v_mac || '</VALUE>
</Para></ParaList></MessageBody></RequestMessage></SyncRequestMsg></m:SendSyncReq></SOAP-ENV:BODY>
</SOAP-ENV:Envelope>';http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');
UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');--   utl_http.set_proxy('proxy:80', NULL);
--   utl_http.set_persistent_conn_support(TRUE);--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');
UTL_HTTP.WRITE_TEXT(http_req, env);http_resp := UTL_HTTP.GET_RESPONSE(http_req);UTL_HTTP.READ_TEXT(http_resp, env);
UTL_HTTP.END_RESPONSE(http_resp);in_xml := sys.XMLTYPE.createxml(env);resp := XMLTYPE.createxml(env);
v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING SUSPEND- ' || v_state || '...';
UPDATE SERVICE_ORDER_ATTRIBUTES SA SET SA.SEOA_DEFAULTVALUE = TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI')
WHERE SA.SEOA_NAME = 'ACTUAL_DSP_DATE'AND SA.SEOA_SERO_ID = p_sero_id;OPEN c_feature_select;LOOP v_pre_val := NULL;
v_new_val := NULL;v_fea_name := NULL;FETCH c_feature_select INTO v_fea_name, v_new_val, v_pre_val;
EXIT WHEN c_feature_select%NOTFOUND;IF (v_new_val = 'Y' AND v_pre_val IS NULL) OR (v_new_val = 'Y' AND v_pre_val = 'N') THEN
UPDATE SERVICE_ORDER_FEATURES sof SET sof.sofe_provision_status = 'Y', sof.SOFE_PROVISION_TIME = sysdate
WHERE sof.sofe_sero_id= p_sero_id AND sof.sofe_feature_name = v_fea_name;END IF;END LOOP;
CLOSE c_feature_select;p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1);
ELSE P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,p_woro_id,
p_ret_char,p_ret_number,p_ret_msg);v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1 );END IF;EXCEPTION
WHEN OTHERS THEN p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg );END SLT_WIMAX_SUSPEND_PRO;    
-- 20-09-2010 Samankula Owitipana

-- 20-09-2010 Samankula Owitipana

PROCEDURE SLT_WIMAX_RESUME_PRO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
	v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
    v_pkg     VARCHAR2(200);v_paytp  NUMBER;v_pkggroup VARCHAR2(100);
    v_domain VARCHAR2(200);v_gpid      NUMBER;v_speed  VARCHAR2(100);
    v_bsid     VARCHAR2(200);env       VARCHAR2(32767);http_req  UTL_HTTP.REQ;
    http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;in_xml    sys.XMLTYPE;
    url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';v_state   VARCHAR2(100);
    v_state_1 VARCHAR2(400);v_pre_val VARCHAR2(10);v_new_val VARCHAR2(10);
    v_fea_name VARCHAR2(100);CURSOR c_feature_select IS
	SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof WHERE sof.sofe_sero_id= p_sero_id;BEGIN
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';
SELECT SOA.SEOA_DEFAULTVALUE
INTO v_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk';v_gpid      := '21';END IF;env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id  || '</Serial><BizCode>ACTIVESUB</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</TIME><Pri>1</Pri>
<TIMEOUT>30000</TIMEOUT><ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhh24miss')||'</ReservedExeTime>
<ParaList><Para><NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE>
</Para><Para><NAME>DOMAIN</NAME><VALUE>' || v_domain || '</VALUE></Para><Para>
<NAME>MSID</NAME><VALUE>' || v_mac || '</VALUE></Para></ParaList></MessageBody>
</RequestMessage></SyncRequestMsg></m:SendSyncReq></SOAP-ENV:BODY></SOAP-ENV:Envelope>';
http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');
--   utl_http.set_proxy('proxy:80', NULL);--   utl_http.set_persistent_conn_support(TRUE);
--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');
UTL_HTTP.WRITE_TEXT(http_req, env);http_resp := UTL_HTTP.GET_RESPONSE(http_req);UTL_HTTP.READ_TEXT(http_resp, env);
UTL_HTTP.END_RESPONSE(http_resp);in_xml := sys.XMLTYPE.createxml(env);resp := XMLTYPE.createxml(env);
v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING RESUME- ' || v_state || '...';
UPDATE SERVICE_ORDER_ATTRIBUTES SA SET SA.SEOA_DEFAULTVALUE = TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI')
WHERE SA.SEOA_NAME = 'ACTUAL_DSP_DATE'AND SA.SEOA_SERO_ID = p_sero_id;OPEN c_feature_select;LOOP
v_pre_val := NULL;v_new_val := NULL;v_fea_name := NULL;FETCH c_feature_select INTO v_fea_name, v_new_val, v_pre_val;
EXIT WHEN c_feature_select%NOTFOUND;IF (v_new_val = 'Y' AND v_pre_val IS NULL) OR (v_new_val = 'Y' AND v_pre_val = 'N') THEN
UPDATE SERVICE_ORDER_FEATURES sof SET sof.sofe_provision_status = 'Y', sof.SOFE_PROVISION_TIME = sysdate WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = v_fea_name;END IF;END LOOP;CLOSE c_feature_select;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1);
ELSE P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,
p_woro_id,p_ret_char,p_ret_number,p_ret_msg);v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1 );END IF;EXCEPTION
WHEN OTHERS THEN p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg );END SLT_WIMAX_RESUME_PRO;        
-- 20-09-2010 Samankula Owitipana

-- 16-11-2010 Samankula Owitipana
PROCEDURE SLT_WIMAX_MOD_LOC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
	v_date    VARCHAR2(100);v_cct    VARCHAR2(100);v_mac     VARCHAR2(200);
    v_bsid     VARCHAR2(200);v_pkg     VARCHAR2(200);v_paytp  NUMBER;
	v_pkggroup VARCHAR2(100);v_domain VARCHAR2(200);v_gpid      NUMBER;
    v_speed     VARCHAR2(100);env       VARCHAR2(32767);http_req  UTL_HTTP.REQ;
    http_resp UTL_HTTP.RESP;resp      sys.XMLTYPE;in_xml    sys.XMLTYPE;
    url       VARCHAR2(2000):='http://10.96.73.17:8090/provision?wsdl';v_state   VARCHAR2(100);
    v_state_1 VARCHAR2(400);v_pre_val VARCHAR2(10);v_new_val VARCHAR2(10);v_fea_name VARCHAR2(100);
CURSOR c_feature_select IS SELECT sof.SOFE_FEATURE_NAME,sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof WHERE sof.sofe_sero_id= p_sero_id;BEGIN
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_cct FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_mac FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE MAC ADDRESS';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_bsid FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BS ID';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkg FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'WIMAX PACKAGE NAME';
SELECT SOA.SEOA_DEFAULTVALUE 
INTO v_pkggroup FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';
SELECT SOA.SEOA_DEFAULTVALUE
INTO v_speed FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE_SPEED';
IF v_pkg = 'Post Paid' THEN v_paytp := '1';ELSIF v_pkg = 'Pre Paid' THEN v_paytp := '2';END IF;
IF  v_pkggroup = 'Biz-Express+IP' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '26';
ELSIF  v_pkggroup = 'Biz-Express' AND v_speed = '4096K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '25';
ELSIF v_pkggroup = 'Office-Express' AND v_speed = '2048K/512K' THEN
v_domain := 'skymax.lk';v_gpid      := '24';
ELSIF  v_pkggroup = 'Standard' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '23';
ELSIF v_pkggroup = 'Home-Express' AND v_speed = '1024K/256K' THEN
v_domain := 'skymax.lk';v_gpid      := '22';
ELSIF v_pkggroup = 'Home-Lite' AND v_speed = '512K/128K' THEN
v_domain := 'skymax.lk';v_gpid      := '21';END IF;env:='<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:BODY><m:SendSyncReq xmlns:m="http://huawei.com/mds/access/webservice/server/bean">
<SyncRequestMsg><RequestMessage><MessageHeader><SysUser>boss</SysUser><SysPassword>boss</SysPassword>
</MessageHeader><MessageBody><Serial>' || p_seit_id || '</Serial><BizCode>MODIFYCPELOCAION</BizCode>
<TIME>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</TIME><Pri>1</Pri><TIMEOUT>30000</TIMEOUT>
<ReservedExeTime>'||to_char(sysdate,'YYYYMMDDhhmiss')||'</ReservedExeTime><ParaList>
<Para><NAME>LOGINNAME</NAME><VALUE>' || v_cct || '</VALUE></Para><Para><NAME>DOMAIN</NAME>
<VALUE>' || v_domain || '</VALUE></Para><Para><NAME>MSID</NAME><VALUE>' || v_mac || '</VALUE>
</Para><Para><NAME>USERGROUPID</NAME><VALUE>' || v_gpid || '</VALUE></Para><Para>
<NAME>BSID</NAME><VALUE>' || v_bsid || '</VALUE></Para></ParaList></MessageBody></RequestMessage>
</SyncRequestMsg></m:SendSyncReq></SOAP-ENV:BODY></SOAP-ENV:Envelope>';
http_req := UTL_HTTP.BEGIN_REQUEST(url, 'POST','HTTP/1.1');UTL_HTTP.SET_BODY_CHARSET(http_req, 'UTF-8');
--   utl_http.set_proxy('proxy:80', NULL);--   utl_http.set_persistent_conn_support(TRUE);
--   UTL_HTTP.set_authentication(http_req, '', '3', 'Basic', TRUE );
UTL_HTTP.SET_HEADER(http_req, 'Content-Type', 'text/xml');UTL_HTTP.SET_HEADER(http_req, 'Content-Length', LENGTH(env));
UTL_HTTP.SET_HEADER(http_req, 'SOAPAction', 'http://10.96.73.17:8090/provision');
UTL_HTTP.WRITE_TEXT(http_req, env);http_resp := UTL_HTTP.GET_RESPONSE(http_req);
UTL_HTTP.READ_TEXT(http_resp, env);UTL_HTTP.END_RESPONSE(http_resp);in_xml := sys.XMLTYPE.createxml(env);
resp := XMLTYPE.createxml(env);v_state := SUBSTR(env,INSTR(env,'<RetDesc>')+9,INSTR(env,'</RetDesc>')-(INSTR(env,'<RetDesc>')+9));
IF v_state = 'Success' THEN v_state_1  := 'USER ' || v_cct || ' AUTO PROVISIONING - ' || v_state || '...';
UPDATE SERVICE_ORDER_ATTRIBUTES SA SET SA.SEOA_DEFAULTVALUE = TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI')
WHERE SA.SEOA_NAME = 'ACTUAL_DSP_DATE' AND SA.SEOA_SERO_ID = p_sero_id;    
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1);ELSE
P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,p_woro_id,
p_ret_char,p_ret_number,p_ret_msg);v_state_1 := 'Failed Run the service - '|| v_state || '...';
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, v_state_1 );END IF;EXCEPTION
WHEN OTHERS THEN p_ret_msg  := 'Failed Run the service. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || v_state;
P_dynamic_procedure.Process_ISSUE_WORK_ORDER(p_serv_id,p_sero_id,p_seit_id,p_impt_taskname,p_woro_id,
p_ret_char,p_ret_number,p_ret_msg);INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, p_ret_msg );END SLT_WIMAX_MOD_LOC;       
-- 16-11-2010 Samankula Owitipana


-- 07-01-2011 Samankula Owitipana
---- 29-10-2011 Edited
----PSTN ADD Port Parameters

PROCEDURE PSTN_ADD_PORT_PARAMETERS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      
      
      
v_port_id ports.PORT_ID%TYPE;
v_equip_id ports.PORT_EQUP_ID%TYPE;
v_tid port_detail_instance.PODI_VALUE%TYPE;
v_rack_id VARCHAR2(5);
v_eid VARCHAR2(100);
v_eid_chk VARCHAR2(100);
v_eid_rec_chk VARCHAR2(100);
v_tid_chk VARCHAR2(1000);
v_tid_rec_chk VARCHAR2(100);
v_equit_type equipment.EQUP_EQUT_ABBREVIATION%TYPE;

CURSOR c_cct_port_details IS      
SELECT po.PORT_ID,po.PORT_EQUP_ID,SUBSTR(po.PORT_CARD_SLOT,1,3), REPLACE(SUBSTR(po.PORT_CARD_SLOT,2),'-','')||REPLACE(po.PORT_NAME,'-',''),
eq.EQUP_EQUT_ABBREVIATION 
FROM service_orders so,port_links pl,port_link_ports plp,ports po,equipment eq
WHERE so.SERO_CIRT_NAME = pl.PORL_CIRT_NAME
AND pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND so.SERO_ID = p_sero_id
AND po.PORT_NAME NOT LIKE 'P%';
      
CURSOR c_eid_select IS    
SELECT ze.PA_NGN_EID 
FROM clarity.ZTE_EID_TABLE ze
WHERE ze.EQUIP_ID = v_equip_id
AND ze.RACK = v_rack_id;

CURSOR c_chk_eid IS
SELECT pdi.PODI_VALUE,pdi.PODI_NAME
FROM PORT_DETAIL_INSTANCE pdi
WHERE pdi.PODI_PORT_ID = v_port_id
AND pdi.PODI_NAME = 'PA_NGN_EID';

CURSOR c_chk_tid IS
SELECT pdi.PODI_VALUE ,pdi.PODI_NAME
FROM PORT_DETAIL_INSTANCE pdi
WHERE pdi.PODI_PORT_ID = v_port_id
AND pdi.PODI_NAME = 'PA_NGN_TID';


BEGIN

OPEN c_cct_port_details;
FETCH c_cct_port_details INTO v_port_id,v_equip_id,v_rack_id,v_tid,v_equit_type;
CLOSE c_cct_port_details;

IF v_equit_type = 'MSAN-ZTE' OR v_equit_type = 'MSAN-OG' OR v_equit_type = 'MSAN-OP' 
      OR v_equit_type = 'MSAN-IG' OR v_equit_type = 'MSAN-IW' OR v_equit_type = 'MSAN-OW' THEN

OPEN c_eid_select;
FETCH c_eid_select INTO v_eid;
CLOSE c_eid_select;

OPEN c_chk_eid;
FETCH c_chk_eid INTO v_eid_chk,v_eid_rec_chk;
CLOSE c_chk_eid;

OPEN c_chk_tid;
FETCH c_chk_tid INTO v_tid_chk,v_tid_rec_chk;
CLOSE c_chk_tid;


IF (v_eid_chk IS NULL AND v_eid_rec_chk IS NULL) THEN 

INSERT INTO PORT_DETAIL_INSTANCE(PODI_PORT_ID, PODI_NAME, PODI_VALUE, PODI_OPTIONALITY, PODI_OWNER,PODI_VALR_ID, PODI_DATATYPE)
VALUES(v_port_id, 'PA_NGN_EID', v_eid, 'OPTIONAL', 'ENGINEER',     NULL, 'CHAR');

ELSIF v_eid_chk IS NULL THEN

UPDATE PORT_DETAIL_INSTANCE
SET PODI_VALUE = v_eid
WHERE PODI_PORT_ID = v_port_id
AND PODI_NAME = 'PA_NGN_EID'; 


END IF;

--------------------------------------------

IF (v_tid_chk IS NULL AND v_tid_rec_chk IS NULL) THEN

INSERT INTO PORT_DETAIL_INSTANCE(PODI_PORT_ID, PODI_NAME, PODI_VALUE, PODI_OPTIONALITY, PODI_OWNER,PODI_VALR_ID, PODI_DATATYPE)
VALUES(v_port_id, 'PA_NGN_TID', v_tid, 'OPTIONAL', 'ENGINEER', NULL, 'CHAR');

ELSIF v_eid_chk IS NULL THEN

UPDATE PORT_DETAIL_INSTANCE
SET PODI_VALUE = v_tid
WHERE PODI_PORT_ID = v_port_id
AND PODI_NAME = 'PA_NGN_TID'; 


END IF;


END IF;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'PSTN ADD PORT PARAMETERS FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);





END PSTN_ADD_PORT_PARAMETERS;
      
-- 07-01-2011 Samankula Owitipana
---- 29-10-2011 Edited


-- 31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_CREATE

 PROCEDURE BIZ_DSL_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';

CURSOR dsl_interface_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSL INTERFACE TYPE';


v_customer_type VARCHAR2(50);
v_service_type  VARCHAR2(50);
v_service_cat VARCHAR2(50);
v_parallel_ser VARCHAR2(50);
v_dsl_ser VARCHAR2(50);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;

OPEN dsl_interface_cur;
FETCH dsl_interface_cur INTO v_dsl_ser;
CLOSE dsl_interface_cur;

    -----------------------------------------  ISSUE INVOICE -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN
         
         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in ISSUE INVOICE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


------------------------------------------UPDATE CIRCUIT-----------------------------------------------------


         BEGIN
         
         

         IF (v_parallel_ser = 'NONE' OR v_dsl_ser = 'DSLAM') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CEN-ADSL'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the PARALLEL SERVICE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;
        

        ---------------------- CONFIRM TEST LINK ------------------------------------------------------

   /*BEGIN

        IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' AND v_service_cat = 'TEST'   THEN
         
         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

   END;*/


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_CREATE;

-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited


-- 31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_CREATEOR

PROCEDURE BIZ_DSL_CREATEOR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';

CURSOR dsl_interface_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSL INTERFACE TYPE';



v_customer_type VARCHAR2(50);
v_service_type  VARCHAR2(50);
v_service_cat VARCHAR2(50);
v_parallel_ser VARCHAR2(50);
v_dsl_ser VARCHAR2(50);


BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;

OPEN dsl_interface_cur;
FETCH dsl_interface_cur INTO v_dsl_ser;
CLOSE dsl_interface_cur;


    -----------------------------------------  ISSUE INVOICE -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in ISSUE INVOICE. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


------------------------------------------UPDATE CIRCUIT-----------------------------------------------------


         BEGIN
         
         

         IF (v_parallel_ser = 'NONE' OR v_dsl_ser = 'DSLAM')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CEN-ADSL'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the PARALLEL SERVICE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;
        

        ---------------------- ISSUE DELETE-OR SO------------------------------------------------------

   BEGIN

        IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in ISSUE DELETE-OR SO . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

   END;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END BIZ_DSL_CREATEOR;

-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited



-- 31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_CREATE_TRANSFER

PROCEDURE BIZ_DSL_CREATE_TRANS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';

CURSOR dsl_interface_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSL INTERFACE TYPE';


v_customer_type VARCHAR2(50);
v_service_type  VARCHAR2(50);
v_service_cat VARCHAR2(50);
v_parallel_ser VARCHAR2(50);
v_dsl_ser VARCHAR2(50);


BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;

OPEN dsl_interface_cur;
FETCH dsl_interface_cur INTO v_dsl_ser;
CLOSE dsl_interface_cur;




------------------------------------------UPDATE CIRCUIT-----------------------------------------------------


         BEGIN
         
         

         IF (v_parallel_ser = 'NONE' OR v_dsl_ser = 'DSLAM')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CEN-ADSL'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in UPDATE CIRCUIT. Please check the PARALLEL SERVICE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;
        

        ---------------------- ISSUE DEL-TRNSFER SO-----------------------------------------------------

   BEGIN

        IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DEL-TRNSFER SO' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in ISSUE DEL-TRNSFER SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

   END;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  WG . Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END BIZ_DSL_CREATE_TRANS;
      
-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited


--31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_MODIFY_SPEED

PROCEDURE BIZ_DSL_MODSPEED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';



v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_service_cat VARCHAR2(30);
v_parallel_ser VARCHAR2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;


    ----------------------------------------- MODIFY PRICE PLAN -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


        

        ---------------------- CONFIRM TEST LINK ------------------------------------------------------

   /*BEGIN

        IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

   END;*/


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_MODSPEED;

-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited



-- 31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_MODIFY_CPE
PROCEDURE BIZ_DSL_MODCPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';



v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_service_cat VARCHAR2(30);
v_parallel_ser VARCHAR2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;


    ----------------------------------------- MODIFY PRICE PLAN -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


        

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_MODCPE;
     
-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited

--23-07-2015 Edited by Jayan
-- 31-12-2011 Edited
-- 21-09-2010 Samankula Owitipana
--BIZ_DSL_APPROVE_SO

PROCEDURE BIZ_DSL_APPROVE_SO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';



v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_service_cat VARCHAR2(30);
v_parallel_ser VARCHAR2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;


    ----------------------------------------- APPROVE SO -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


        

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_APPROVE_SO;
      
-- 21-09-2010 Samankula Owitipana
-- 31-12-2011 Edited

-- 31-12-2011 Edited
-- 23-09-2010 Samankula Owitipana
--BIZ_DSL_DELETE
    
PROCEDURE BIZ_DSL_DELETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';

CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';



v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_service_cat VARCHAR2(30);
v_parallel_ser VARCHAR2(30);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;

OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;



----------------------------------------- APPROVE SO -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in APPROVE SO. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


    ----------------------------------------- MODIFY PRICE PLAN -----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;

    ----------------------------------------- MODIFY OLD PRICE PLA-----------------------------------------
     BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY OLD PRICE PLA' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY OLD PRICE PLA' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY OLD PRICE PLA' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY OLD PRICE PLA' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY OLD PRICE PLA. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;

        

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_DELETE;

--  31-12-2011 Edited
-- 23-09-2010 Samankula Owitipana


-- 31-12-2011 Edited
-- 23-09-2010 Samankula Owitipana
--BIZ_DSL_MODOTHERS
PROCEDURE BIZ_DSL_MODOTHERS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;


CURSOR serv_type_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE TYPE';

CURSOR serv_router_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ROUTER MODEL';

CURSOR serv_cpe_class_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE_CLASS';



v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_router_model VARCHAR2(50);
v_cpe_class VARCHAR2(50);



BEGIN


OPEN serv_type_cur;
FETCH serv_type_cur INTO v_service_type;
CLOSE serv_type_cur;

OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_router_cur;
FETCH serv_router_cur INTO v_router_model;
CLOSE serv_router_cur;

OPEN serv_cpe_class_cur;
FETCH serv_cpe_class_cur INTO v_cpe_class;
CLOSE serv_cpe_class_cur;



------------------------------------------CONFIGURE CPE-----------------------------------------------------


         BEGIN
         
         

         IF  v_cpe_class = 'SLT' AND v_router_model <> 'SLT Default' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-CPEI'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIGURE CPE' ;


         END IF;



        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in CONFIGURE CPE.' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

        END;


----------------------------------------- MODIFY PRICE PLAN -----------------------------------------
BEGIN
     
     

         IF (v_customer_type = 'CORPORATE' or v_customer_type = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'SME' or v_customer_type = 'CORPORATE-SME' ) THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_customer_type = 'WHOLESALE' or v_customer_type = 'CORPORATE-WHOLESALE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;
         
         ELSIF v_customer_type = 'REGIONAL-SME' THEN
         
         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;
         
         

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in MODIFY PRICE PLAN. Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg);

     END;


        

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_MODOTHERS;

-- 23-09-2010 Samankula Owitipana
-- 31-12-2011 Edited



-- 08-12-2010 Samankula Owitipana


PROCEDURE BIZ_DSL_SET_ATER_NAME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR vpn_cur  IS
SELECT substr(trim(SOA.SEOA_DEFAULTVALUE),4,7)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PSTN PHONE NUMBER';

CURSOR cct_cur  IS
SELECT SO.SERO_CIRT_NAME,so.SERO_AREA_CODE
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;


v_cct_id VARCHAR2(20);
v_cvt_char varchar2(100);
v_area_code VARCHAR2(10);



BEGIN



OPEN vpn_cur;
FETCH vpn_cur INTO v_cvt_char;
CLOSE vpn_cur;

OPEN cct_cur;
FETCH cct_cur INTO v_cct_id,v_area_code;
CLOSE cct_cur;




INSERT INTO OTHER_NAMES ONA (OTHN_CIRT_NAME, OTHN_NAME, OTHN_NAMETYPE, OTHN_WORG_NAME)
VALUES (v_cct_id,v_area_code || v_cvt_char,'BIZ-DSL PSTN NUMBER',null);


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set ALTERNATE NAME. Please check PSTN PHONE NUMBER attribute :' || v_cvt_char || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END BIZ_DSL_SET_ATER_NAME;


-- 08-12-2010 Samankula Owitipana

-- 10-02-2011 Samankula Owitipana
--BIZ_DSL_ACTIVATE ETHER LINK


  PROCEDURE BIZDSL_ACTIV_ETHA_LINK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_TRANS_NW varchar2(50);



BEGIN


SELECT SOA.SEOA_DEFAULTVALUE
INTO v_TRANS_NW
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';





         IF v_TRANS_NW = 'MEN'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-MEN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV ETHERNET LINK' ;

         ELSIF v_TRANS_NW = 'CEA' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IPNET-PROV'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ACTIV ETHERNET LINK' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZDSL_ACTIV_ETHA_LINK;

-- 10-02-2011 Samankula Owitipana

-- 10-02-2011 Samankula Owitipana
--BIZ_DSL_MODIFY ETHA LINK


  PROCEDURE BIZDSL_MODIFY_ETHA_LINK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_TRANS_NW varchar2(50);



BEGIN


SELECT SOA.SEOA_DEFAULTVALUE
INTO v_TRANS_NW
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';





         IF v_TRANS_NW = 'MEN'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-MEN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY ETHERNET LINK' ;

         ELSIF v_TRANS_NW = 'CEA' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IPNET-PROV'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY ETHERNET LINK' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZDSL_MODIFY_ETHA_LINK;

-- 10-02-2011 Samankula Owitipana

-- 10-02-2011 Samankula Owitipana
--BIZ_DSL_DELETE ETHA LINK


  PROCEDURE BIZDSL_DELETE_ETHA_LINK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_TRANS_NW varchar2(50);



BEGIN


SELECT SOA.SEOA_DEFAULTVALUE
INTO v_TRANS_NW
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'TRANSPORT NW';





         IF v_TRANS_NW = 'MEN'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'DS-MEN'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DELETE ETHERNET LINK' ;

         ELSIF v_TRANS_NW = 'CEA' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'IPNET-PROV'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'DELETE ETHERNET LINK' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZDSL_DELETE_ETHA_LINK;

-- 10-02-2011 Samankula Owitipana

-- 10-02-2011 Samankula Owitipana

--- 14-09-2011 updated

--BIZDSL_MODIFY_PRICE_PLAN


  PROCEDURE BIZDSL_MODIFY_PRICE_PLAN (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_CUSTYPE_VAL VARCHAR2(50);

CURSOR CUSTYPE_select_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

BEGIN


OPEN CUSTYPE_select_cur;
FETCH CUSTYPE_select_cur INTO v_CUSTYPE_VAL;
CLOSE CUSTYPE_select_cur;


         
         

         IF (v_CUSTYPE_VAL = 'WHOLESALE' or v_CUSTYPE_VAL = 'CORPORATE-WHOLESALE')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_CUSTYPE_VAL = 'SME' or v_CUSTYPE_VAL = 'CORPORATE-SME')  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         ELSIF (v_CUSTYPE_VAL = 'CORPORATE' or v_CUSTYPE_VAL = 'CORPORATE-LARGE & VERY LARGE') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;
         
         ELSIF v_CUSTYPE_VAL = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;

         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
    

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZDSL_MODIFY_PRICE_PLAN;
 
 --- 14-09-2011 updated

-- 10-02-2011 Samankula Owitipana

-- 11-02-2011 Samankula Owitipana


PROCEDURE BIZ_DSL_MOD_LOCATION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



CURSOR serv_DSLNTE_cur  IS
SELECT SOA.SEOA_PREV_VALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSL_NTE TYPE';

CURSOR serv_cpe_class_cur  IS
SELECT SOA.SEOA_PREV_VALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE_CLASS';


v_dslnte_type_old varchar2(50);
v_cpe_class_old varchar2(50);



BEGIN




OPEN serv_DSLNTE_cur;
FETCH serv_DSLNTE_cur INTO v_dslnte_type_old;
CLOSE serv_DSLNTE_cur;

OPEN serv_cpe_class_cur;
FETCH serv_cpe_class_cur INTO v_cpe_class_old;
CLOSE serv_cpe_class_cur;




         IF  v_dslnte_type_old = 'SLT Default' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT OLD DSL NTE' ;


         END IF;


         IF  v_cpe_class_old = 'SLT' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'COLLECT  OLD CPE' ;


         END IF;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Delete the tasks:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_MOD_LOCATION;

-- 11-02-2011 Samankula Owitipana

-- 11-02-2011 Samankula Owitipana


PROCEDURE BIZ_DSL_MOD_CPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR serv_cpe_class_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE_CLASS';


v_cpe_class_new varchar2(50);
v_cpe_class_old varchar2(50);



BEGIN


OPEN serv_cpe_class_cur;
FETCH serv_cpe_class_cur INTO v_cpe_class_new,v_cpe_class_old;
CLOSE serv_cpe_class_cur;




         IF  v_cpe_class_new = 'SLT' and v_cpe_class_old <> 'SLT' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'INSTALL CPE' ;


         END IF;


         IF  v_cpe_class_new <> 'SLT' and v_cpe_class_old = 'SLT' THEN

         NULL;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'RECOVER CPE' ;


         END IF;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Delete the tasks:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_MOD_CPE;

-- 11-02-2011 Samankula Owitipana



-- 11-02-2011 Samankula Owitipana

PROCEDURE ADSL_REMOVE_IPTV_TASK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_NE_TYPE varchar2(50);


BEGIN

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_NE_TYPE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ADSL_NE_TYPE';




         IF  (v_NE_TYPE = 'DSLAM-ZTE' or v_NE_TYPE = 'MSAN-ZTE') THEN


         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CREATE IPTV SERVICE' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Delete the tasks:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END ADSL_REMOVE_IPTV_TASK;

-- 11-02-2011 Samankula Owitipana


-- 14-02-2011 Samankula Owitipana
--BIZ_DSL_UPDATE_CCT


  PROCEDURE BIZ_DSL_UPDATE_CCT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





CURSOR serv_parallel_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PARALLEL SERVICE';

CURSOR dsl_interface_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'DSL INTERFACE TYPE';



v_parallel_ser varchar2(50);
v_dsl_ser varchar2(50);



BEGIN




OPEN serv_parallel_cur;
FETCH serv_parallel_cur INTO v_parallel_ser;
CLOSE serv_parallel_cur;

OPEN dsl_interface_cur;
FETCH dsl_interface_cur INTO v_dsl_ser;
CLOSE dsl_interface_cur;



         IF (v_parallel_ser = 'NONE' or v_dsl_ser = 'DSLAM') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'CEN-ADSL'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'UPDATE CIRCUIT' ;


         END IF;






    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG. Please check the Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END BIZ_DSL_UPDATE_CCT;

-- 14-02-2011 Samankula Owitipana


--- 29-03-2011  Samankula Owitipana


PROCEDURE ILL_ISSUE_INVOICE_WGCH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

v_customer_type varchar2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END ILL_ISSUE_INVOICE_WGCH;


--- 29-03-2011  Samankula Owitipana

--- 29-03-2011  Samankula Owitipana


PROCEDURE ILL_APPROVE_SO_WGCH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

v_customer_type varchar2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-MGR'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'APPROVE SO' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END ILL_APPROVE_SO_WGCH;


--- 29-03-2011  Samankula Owitipana

--- 29-03-2011  Samankula Owitipana


PROCEDURE ILL_MOD_PRICE_PLAN_WGCH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

v_customer_type varchar2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'MODIFY PRICE PLAN' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END ILL_MOD_PRICE_PLAN_WGCH;


--- 29-03-2011  Samankula Owitipana

--- 29-03-2011  Samankula Owitipana


PROCEDURE ILL_CONF_TEST_LINK_WGCH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

v_customer_type varchar2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-ACCT'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END ILL_CONF_TEST_LINK_WGCH;


--- 29-03-2011  Samankula Owitipana

--- 29-03-2011  Samankula Owitipana


PROCEDURE ILL_ISSUE_DEL_SO_WGCH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;

v_customer_type varchar2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'REGIONAL-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SMER-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE DELETE-OR SO' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END ILL_ISSUE_DEL_SO_WGCH;


--- 29-03-2011  Samankula Owitipana

-- 01-05-2011 Samankula Owitipana
--Price plane change message


  PROCEDURE BIZ_DSL_PRICE_CHG_MSG (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS






BEGIN



p_ret_char := 'Please Change the price plane of the old circuit to "Service Termination"';




EXCEPTION
WHEN OTHERS THEN


p_ret_msg := 'Failed Completion Rule. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


 END BIZ_DSL_PRICE_CHG_MSG;

-- 01-05-2011 Samankula Owitipana

-- 19-05-2011 Samankula Owitipana


PROCEDURE PSTN_SET_DP_DISTANCE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_dp_distance    varchar2(10);
v_circuit varchar2(100);

cursor c_dp_data is
select fu.FRAU_DISTANCE
from FRAME_APPEARANCES fa,FRAME_CONTAINERS fc,FRAME_UNITS fu,port_link_ports plp,port_links pl
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_FRAA_ID = fa.FRAA_ID
and fa.FRAA_FRAU_ID = fu.FRAU_ID
and fu.FRAU_FRAC_ID = fc.FRAC_ID
and fc.FRAC_FRAN_NAME = 'DP'
and fa.FRAA_SIDE = 'FRONT'
and pl.PORL_CIRT_NAME = v_circuit;


BEGIN


select so.SERO_CIRT_NAME
into v_circuit
from service_orders so
where so.SERO_ID = p_sero_id;



open c_dp_data;
fetch c_dp_data into v_dp_distance;
close c_dp_data;


UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET SOA.SEOA_DEFAULTVALUE = v_dp_distance
WHERE SOA.SEOA_NAME = 'EX_DP_DISTANCE'
AND SOA.SEOA_SERO_ID = p_sero_id ;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


     p_ret_msg  := 'Failed to set DP distance: - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END PSTN_SET_DP_DISTANCE;

-- 19-05-2011 Samankula Owitipana

-- 01-07-2011 Samankula Owitipana

PROCEDURE WIMAX_REMOVE_IP_TASK_DEL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_new_pkg varchar2(50);
v_old_pkg varchar2(50);


BEGIN

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_new_pkg
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';

SELECT SOA.SEOA_PREV_VALUE
INTO v_old_pkg
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';




         IF  (v_old_pkg = 'Biz-Express+IP' and v_new_pkg <> 'Biz-Express+IP' ) THEN

         null;

         ELSE

         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'REMOVE IP ADDRESS' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Delete the tasks:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END WIMAX_REMOVE_IP_TASK_DEL;

-- 01-07-2011 Samankula Owitipana

-- 01-07-2011 Samankula Owitipana

PROCEDURE WIMAX_REMOVE_IP_ATTR_NULL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_new_pkg varchar2(50);
v_old_pkg varchar2(50);


BEGIN

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_new_pkg
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';

SELECT SOA.SEOA_PREV_VALUE
INTO v_old_pkg
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'INTERNET PACKAGE';




         IF  (v_old_pkg = 'Biz-Express+IP' and v_new_pkg <> 'Biz-Express+IP' ) THEN


         UPDATE service_order_attributes soa
         SET SOA.SEOA_DEFAULTVALUE = null
         WHERE soa.SEOA_SERO_ID = p_sero_id
         AND soa.SEOA_NAME = 'IP_ADDRESS' ;


         END IF;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Delete the tasks:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


 END WIMAX_REMOVE_IP_ATTR_NULL;

-- 01-07-2011 Samankula Owitipana

--- 21-07-2011  Samankula Owitipana

PROCEDURE PO_MSAN_MDF_WG_CHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





v_equip_type VARCHAR2(100);



cursor c_equip_select is
SELECT EQ.EQUP_EQUT_ABBREVIATION
FROM SERVICE_ORDERS SO,CIRCUITS CI,PORT_LINKS PL,PORT_LINK_PORTS PLP,PORTS PO,EQUIPMENT EQ
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND CI.CIRT_NAME = PL.PORL_CIRT_NAME
AND PL.PORL_ID = PLP.POLP_PORL_ID
AND PLP.POLP_PORT_ID = PO.PORT_ID
AND PO.PORT_EQUP_ID = EQ.EQUP_ID
and EQ.EQUP_EQUT_ABBREVIATION like '%MSAN%'
AND SO.SERO_ID = p_sero_id;




 BEGIN



open c_equip_select;
fetch c_equip_select into v_equip_type;
close c_equip_select;


UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_equip_type
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'PSTN_NE_TYPE';





         IF (v_equip_type = 'MSAN-OP' or v_equip_type = 'MSAN-OW' or v_equip_type = 'MSAN-OG') THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = replace(sit.SEIT_WORG_NAME,'MDF','OSP-NC')
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO FOR MDF' ;


         END IF;





         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO FOR MDF. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );


END PO_MSAN_MDF_WG_CHANGE;

--- 21-07-2011  Samankula Owitipana

-- 2011/07/23 jayan Liyanage

PROCEDURE DATA_PRODUCT_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS


   v_customer_type   VARCHAR2 (100);
   v_service_order   VARCHAR2 (100);
   v_service_categ   VARCHAR2 (100);
   v_service_type    VARCHAR2 (100);
BEGIN
   SELECT distinct so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT distinct so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT distinct  cu.cusr_cutp_type
     INTO v_customer_type
     FROM service_orders so, customer cu
    WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
      AND so.sero_id = p_sero_id;



  --- D-ILL " DELETE "
   IF     v_service_type = 'D-ILL'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   ---  D-ILL "CREATE-OR"
   IF     v_service_type = 'D-ILL'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;



   -- D-BIZ-DSL " DELETE "
   IF     v_service_type = 'D-VALUE VPN'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   -- D-BIZ-DSL   "CREATE-TRANSFER"
   IF     v_service_type = 'D-VALUE VPN'
      AND v_service_order = 'CREATE-TRANSFER'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'CREATE-TRANSFER'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'CREATE-TRANSFER'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   END IF;



   -- D-IPLC   "DELETE"
   IF     v_service_type = 'D-IPLC'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   -- D-IPLC  "CREATE-OR"
   IF     v_service_type = 'D-IPLC'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;

   -- D-IPLC  "CREATE-UPGRADE"
   IF     v_service_type = 'D-IPLC'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE UPGRADE';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'CREATE-UPGRADE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE UPGRADE';
   ELSIF     v_service_type = 'D-IPLC'
         AND v_service_order = 'CREATE-UPGRADE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE UPGRADE';
   END IF;


--  D-VPLS ACCESS LINK "DELETE"
   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   --  D-VPLS ACCESS LINK "CREATE-OR"
   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;

   --  D-VPLS ACCESS LINK "CREATE"
/*   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'CREATE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;*/

   -- D-VPLS ACCESS LINK "MODIFY-SPEED"
/*   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/


   -- D-DIDO "CREATE-OR"
   IF     v_service_type = 'D-DIDO'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;

   -- D-DIDO "DELETE"
   IF     v_service_type = 'D-DIDO'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   -- D-DIDO "DELETE downgrade"
   IF     v_service_type = 'D-DIDO'
      AND v_service_order = 'DELETE-DOWNGRADE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'DELETE-DOWNGRADE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-DIDO'
         AND v_service_order = 'DELETE-DOWNGRADE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;


   -- D-P2P "CREATE-OR"
   IF     v_service_type = 'D-P2P'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-P2P'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-P2P'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;

   -- D-P2P "DELETE"
   IF     v_service_type = 'D-P2P'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-P2P'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-P2P'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;



   -- D-IPVPN "CREATE OR"
   IF     v_service_type = 'D-IPVPN'
      AND v_service_order = 'CREATE-OR'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'CREATE-OR'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DELETE-OR SO';
   END IF;

   ---  -- D-IPVPN "CREATE UPGRADE"
   IF     v_service_type = 'D-IPVPN'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'CREATE-UPGRADE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'CREATE-UPGRADE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ISSUE DEL-TRNSFER SO';
   END IF;

   -- D-P2P "DELETE"
   IF     v_service_type = 'D-IPVPN'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-IPVPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;



   -- D-RVPN "DELETE"
   IF     v_service_type = 'D-RVPN'
      AND v_service_order = 'DELETE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-RVPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-SME'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   ELSIF     v_service_type = 'D-RVPN'
         AND v_service_order = 'DELETE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'MODIFY PRICE PLAN';
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change  Work group Mapping. Please check the Work Groups:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                      'Failed to Change  Work group Mapping. Please check the Work Groups: '
                   || v_customer_type
                  );
END DATA_PRODUCT_WG_CHANGE;

-- 2011/07/23 jayan Liyanage

-- 23-07-2011 Jayan Liyanage

PROCEDURE DATA_PRODUCT_WG_CHG_SER_CATG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
)
IS


   v_customer_type   VARCHAR2 (100);
   v_service_order   VARCHAR2 (100);
   v_service_categ   VARCHAR2 (100);
   v_service_type    VARCHAR2 (100);
BEGIN
   SELECT distinct so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT distinct so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT distinct cu.cusr_cutp_type
     INTO v_customer_type
     FROM service_orders so, customer cu
    WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
      AND so.sero_id =  p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_service_categ
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id
    AND soa.seoa_name = 'SERVICE CATEGORY';



   -- D-ILL "CREATE"
 /*  IF     v_service_type = 'D-ILL'
      AND v_service_order = 'CREATE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;*/

   -- D-ILL "MODIFY SPEED"
/*   IF     v_service_type = 'D-ILL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-ILL'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/


   -- D-BIZ-DSL "CREATE"
/*   IF     v_service_type = 'D-VALUE VPN'
      AND v_service_order = 'CREATE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/
   -- D-BIZ-DSL "MODIFY - SPEED"
/*   IF     v_service_type = 'D-VALUE VPN'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VALUE VPN'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/




   --  D-VPLS ACCESS LINK "CREATE"
/*   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'CREATE'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'CREATE'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/
   -- D-VPLS ACCESS LINK "MODIFY-SPEED"
/*   IF     v_service_type = 'D-VPLS ACCESS LINK'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_customer_type like 'CORPORATE-LARGE%VERY LARGE'
      AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-CORP-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-SME'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-SME-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSIF     v_service_type = 'D-VPLS ACCESS LINK'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_customer_type = 'CORPORATE-WHOLESALE'
         AND v_service_categ = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'MKT-SALES-WSALE-ACCT'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;
*/



   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change  Work group Mapping. Please check the Work Groups:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR'
                                                     );

      INSERT INTO service_task_comments
                  (setc_seit_id, setc_id, setc_userid, setc_timestamp,
                   setc_text
                  )
           VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
                      'Failed to Change  Work group Mapping. Please check the Work Groups: '
                   || v_customer_type
                  );
END DATA_PRODUCT_WG_CHG_SER_CATG;

-- 23-07-2011 Jayan Liyanage

-- 23-07-2011 Jayan Liyanage

-- 12-08-2011 Samankula Owitipana

-- edited on 21-09-2011
-- Edited on 02-01-2012

PROCEDURE ADSL_SET_UPLOAD_POLICY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




	  
  


/*CURSOR CUR_LDAP_SPEED IS
--SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,0,(INSTR(A.SEOA_DEFAULTVALUE,'/'))-2)) CURR_DWN, TRIM(SUBSTR(A.SEOA_PREV_VALUE,0,(INSTR(A.SEOA_PREV_VALUE ,'/'))-2)) PRV_DWN
SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,(INSTR(A.SEOA_DEFAULTVALUE,'/'))+1,2)) CURR_UP, TRIM(SUBSTR(A.SEOA_PREV_VALUE,(INSTR(A.SEOA_PREV_VALUE,'/'))+1,2)) PRV_UP
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id 
AND A.SEOA_NAME='SERVICE_SPEED';*/

CURSOR CUR_LDAP_PKG IS
SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) CURR_PKG ---,TRIM(UPPER(A.SEOA_PREV_VALUE)) PRV_PKG
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id 
AND A.SEOA_NAME='SA_PACKAGE_NAME';
	   
			   
CURSOR CUR_FUP_VALUE IS
SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) 
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id 
AND A.SEOA_NAME='FUP';


--SELECT UPPER(L.PACKAGE_NAME)
--FROM CLARITY.LDAP_POLICY L

V_LDAP_PKG    VARCHAR2(200);----CUR_LDAP_PKG%ROWTYPE;	
V_FUP		  VARCHAR2(200);



BEGIN

        /*OPEN  CUR_LDAP_SPEED;
            FETCH  CUR_LDAP_SPEED INTO V_LDAP_SPEED;
        CLOSE  CUR_LDAP_SPEED;*/
		

        OPEN  CUR_LDAP_PKG;
            FETCH  CUR_LDAP_PKG INTO V_LDAP_PKG;
        CLOSE  CUR_LDAP_PKG;
		
		OPEN  CUR_FUP_VALUE;
            FETCH  CUR_FUP_VALUE INTO V_FUP;
        CLOSE  CUR_FUP_VALUE;


        IF (V_LDAP_PKG='WEBPROPLUS' OR V_LDAP_PKG='WEB PRO PLUS' OR V_LDAP_PKG='SLT STAFF WEB PRO PLUS') THEN
		
            IF V_FUP = 'Y' THEN
                
			   UPDATE SERVICE_ORDER_ATTRIBUTES soa
               SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
               WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
               AND soa.SEOA_SERO_ID = p_sero_id;
				
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webproplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id; 

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTERPLUS' OR V_LDAP_PKG='WEB MASTER PLUS' OR V_LDAP_PKG='SLT STAFF WEB MASTER PLUS') THEN
		
            IF V_FUP= 'Y' THEN
                
			   UPDATE SERVICE_ORDER_ATTRIBUTES soa
               SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
               WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
               AND soa.SEOA_SERO_ID = p_sero_id;
				
				
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBMATE' OR V_LDAP_PKG='WEB MATE' OR V_LDAP_PKG='SLT STAFF WEB MATE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmate_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmate_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;
            
        ELSIF (V_LDAP_PKG='WEBFAMILY' OR V_LDAP_PKG='WEB FAMILY' OR V_LDAP_PKG='SLT STAFF WEB FAMILY') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webfamily_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webfamily_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFER' OR V_LDAP_PKG='WEB SURFER' OR V_LDAP_PKG='SLT STAFF WEB SURFER') THEN
		
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurfer_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurfer_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBPRO' OR V_LDAP_PKG='WEB PRO' OR V_LDAP_PKG='SLT STAFF WEB PRO') THEN
		
            IF V_FUP = 'Y' THEN
               

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpro_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpro_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTER' OR V_LDAP_PKG='WEB MASTER' OR V_LDAP_PKG='SLT STAFF WEB MASTER') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmaster_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmaster_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFERPLUS' OR V_LDAP_PKG='WEB SURFER PLUS' OR V_LDAP_PKG='SLT STAFF WEB SURFER PLUS') THEN
		
            IF V_FUP = 'Y' THEN
                
				UPDATE SERVICE_ORDER_ATTRIBUTES soa
            	SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
            	WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
            	AND soa.SEOA_SERO_ID = p_sero_id;
				
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='ENTREE' OR V_LDAP_PKG='ENTRÉE' OR V_LDAP_PKG='SLT STAFF ENTREE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'entree_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'entree_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;


            END IF;
			
	   ELSIF (V_LDAP_PKG='HOME') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'home_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'home_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;


            END IF;	
			
		ELSIF (V_LDAP_PKG='OFFICE' or V_LDAP_PKG='OFFICEEXPRESS') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'office_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'office_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;


           END IF;
			
			
		ELSIF (V_LDAP_PKG='XCITE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcite_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcite_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;


            END IF;
			
		ELSIF (V_LDAP_PKG='XCEL') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcel_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcel_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;


            END IF;	
            
            
        ELSIF (V_LDAP_PKG='WEBSTARTER' OR V_LDAP_PKG='WEB STARTER' OR V_LDAP_PKG='SLT STAFF WEB STARTER') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webstarter_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webstarter_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            
            END IF;
            
            
        ELSIF (V_LDAP_PKG='WEBPAL' OR V_LDAP_PKG='WEB PAL' OR V_LDAP_PKG='SLT STAFF WEB PAL') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpal_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpal_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            
            END IF;
            
            
        ELSIF (V_LDAP_PKG='WEBCHAMP' OR V_LDAP_PKG='WEB CHAMP' OR V_LDAP_PKG='SLT STAFF WEB CHAMP') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webchamp_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE               

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webchamp_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            
            END IF;
			
            
	    ELSIF (V_LDAP_PKG='WEBLIFE' OR V_LDAP_PKG='WEB LIFE' OR V_LDAP_PKG='SLT STAFF WEB LIFE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'weblife_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'weblife_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
            
         	
        ELSIF (V_LDAP_PKG='GMOA_Medical' OR V_LDAP_PKG='GMOA_MEDICAL') THEN
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoamedical_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoamedical_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
            
            
        ELSIF (V_LDAP_PKG='GMOA_Admin' OR V_LDAP_PKG='GMOA_ADMIN') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaadmin_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaadmin_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
            
            
        ELSIF (V_LDAP_PKG='GMOA_Consultant' OR V_LDAP_PKG='GMOA_CONSULTANT') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaconsult_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaconsult_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
			
		
		ELSIF (V_LDAP_PKG='HOMEPLUS' OR V_LDAP_PKG='HOME PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'homeplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
			
			
		ELSIF (V_LDAP_PKG='OFFICEPLUS' OR V_LDAP_PKG='OFFICE PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'officeplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
			
			
			
		ELSIF (V_LDAP_PKG='XCELPLUS' OR V_LDAP_PKG='XCEL PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcelplus_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
            
            	
            
        ELSIF (V_LDAP_PKG='ABHIMAANA' OR V_LDAP_PKG='Abhimaana') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'abhimaana_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'abhimaana_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
            
            
        
        ELSIF (V_LDAP_PKG='SLT STAFF TRIPLE PLAY' OR V_LDAP_PKG='SLT STAFF') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'staff_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'staff_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;

        ELSIF (V_LDAP_PKG='BROADBAND EXPERIENCE' OR V_LDAP_PKG='Broadband Experience') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'experience_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'experience_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
            
        
        ELSIF (V_LDAP_PKG='STUDENT PACKAGE 1' OR V_LDAP_PKG='STUDENT_PACKAGE_1') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student1_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student1_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
        
        
        ELSIF (V_LDAP_PKG='STUDENT PACKAGE 2' OR V_LDAP_PKG='STUDENT_PACKAGE_2') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student2_heavy_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student2_normal_up'
                WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
               
        ELSE
		
            --THEN
            UPDATE SERVICE_ORDER_ATTRIBUTES soa
            SET soa.SEOA_DEFAULTVALUE = 'No match'
            WHERE soa.SEOA_NAME = 'LDAP_UP_POLICY'
            AND soa.SEOA_SERO_ID = p_sero_id;
			

        END IF;

      
 


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');





 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SET UPLOAD POLICY FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END  ADSL_SET_UPLOAD_POLICY;
      
-- Edited on 13-06-2012 
-- Edited on 02-01-2012
-- edited on 21-09-2011 

-- 12-08-2011 Samankula Owitipana

-- 12-08-2011 Samankula Owitipana

-- edited on 21-09-2011
-- Edited on 02-01-2012
-- Edited on 13-06-2012 

PROCEDURE ADSL_SET_DOWNLOAD_POLICY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




/*CURSOR CUR_LDAP_SPEED IS
---SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,(INSTR(A.SEOA_DEFAULTVALUE,'/'))+1,3)) CURR_UP, TRIM(SUBSTR(A.SEOA_PREV_VALUE,(INSTR(A.SEOA_PREV_VALUE,'/'))+1,3)) PRV_UP
SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,0,(INSTR(A.SEOA_DEFAULTVALUE,'/'))-2)) CURR_DWN, TRIM(SUBSTR(A.SEOA_PREV_VALUE,0,(INSTR(A.SEOA_PREV_VALUE ,'/'))-2)) PRV_DWN
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id 
AND A.SEOA_NAME='SERVICE_SPEED';*/

CURSOR CUR_LDAP_PKG IS
SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) CURR_PKG ---,TRIM(UPPER(A.SEOA_PREV_VALUE)) PRV_PKG
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id
AND A.SEOA_NAME='SA_PACKAGE_NAME';


CURSOR CUR_FUP_VALUE IS
SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) 
FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A
WHERE A.SEOA_SERO_ID= p_sero_id 
AND A.SEOA_NAME='FUP';

---SELECT UPPER(L.PACKAGE_NAME)
---FROM CLARITY.LDAP_POLICY L


V_LDAP_PKG    VARCHAR2(200);--CUR_LDAP_PKG%ROWTYPE;	  
V_FUP		  VARCHAR2(200);





BEGIN



        OPEN  CUR_LDAP_PKG;
            FETCH  CUR_LDAP_PKG INTO V_LDAP_PKG;
        CLOSE  CUR_LDAP_PKG;
		
		OPEN  CUR_FUP_VALUE;
            FETCH  CUR_FUP_VALUE INTO V_FUP;
        CLOSE  CUR_FUP_VALUE;		


        IF (V_LDAP_PKG='WEBPROPLUS' OR V_LDAP_PKG='WEB PRO PLUS' OR V_LDAP_PKG='SLT STAFF WEB PRO PLUS') THEN
		
            IF V_FUP = 'Y' THEN
                
			   UPDATE SERVICE_ORDER_ATTRIBUTES soa
               SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
               WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
               AND soa.SEOA_SERO_ID = p_sero_id;
				
				
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webproplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTERPLUS' OR V_LDAP_PKG='WEB MASTER PLUS' OR V_LDAP_PKG='SLT STAFF WEB MASTER PLUS') THEN
		
            IF V_FUP = 'Y' THEN
               
			   UPDATE SERVICE_ORDER_ATTRIBUTES soa
               SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
               WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
               AND soa.SEOA_SERO_ID = p_sero_id;
			
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBMATE' OR V_LDAP_PKG='WEB MATE' OR V_LDAP_PKG='SLT STAFF WEB MATE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmate_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmate_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;
            
        ELSIF (V_LDAP_PKG= 'WEBFAMILY' OR V_LDAP_PKG= 'WEB FAMILY' OR V_LDAP_PKG= 'SLT STAFF WEB FAMILY') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webfamily_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webfamily_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFER' OR V_LDAP_PKG='WEB SURFER' OR V_LDAP_PKG='SLT STAFF WEB SURFER') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurfer_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurfer_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBPRO' OR V_LDAP_PKG='WEB PRO' OR V_LDAP_PKG='SLT STAFF WEB PRO') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpro_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpro_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTER' OR V_LDAP_PKG='WEB MASTER' OR V_LDAP_PKG='SLT STAFF WEB MASTER') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmaster_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webmaster_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFERPLUS' OR V_LDAP_PKG='WEB SURFER PLUS' OR V_LDAP_PKG='SLT STAFF WEB SURFER PLUS') THEN
		
            IF V_FUP = 'Y' THEN
                
			   UPDATE SERVICE_ORDER_ATTRIBUTES soa
               SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
               WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
               AND soa.SEOA_SERO_ID = p_sero_id;
			
            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;

        ELSIF (V_LDAP_PKG='ENTREE' OR V_LDAP_PKG='ENTRÉE' OR V_LDAP_PKG='SLT STAFF ENTREE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'entree_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'entree_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;
			
		ELSIF (V_LDAP_PKG='HOME') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'home_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'home_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
			
		ELSIF (V_LDAP_PKG='OFFICE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'office_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'office_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
			
		ELSIF (V_LDAP_PKG='XCITE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcite_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcite_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;
			
		ELSIF (V_LDAP_PKG='XCEL') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcel_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcel_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;		
			
		ELSIF (V_LDAP_PKG='WEBSTARTER' OR V_LDAP_PKG='WEB STARTER' OR V_LDAP_PKG='SLT STAFF WEB STARTER') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webstarter_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webstarter_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;		
			
			
		ELSIF (V_LDAP_PKG='WEBPAL' OR V_LDAP_PKG='WEB PAL' OR V_LDAP_PKG='SLT STAFF WEB PAL') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpal_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webpal_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;		
			
			
		ELSIF (V_LDAP_PKG='WEBCHAMP' OR V_LDAP_PKG='WEB CHAMP' OR V_LDAP_PKG='SLT STAFF WEB CHAMP') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webchamp_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'webchamp_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
			
		ELSIF (V_LDAP_PKG='WEBLIFE' OR V_LDAP_PKG='WEB LIFE' OR V_LDAP_PKG='SLT STAFF WEB LIFE') THEN
		
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'weblife_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'weblife_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;			
			
		
        ELSIF (V_LDAP_PKG='GMOA_Medical' OR V_LDAP_PKG='GMOA_MEDICAL') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoamedical_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoamedical_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
		
        
        ELSIF (V_LDAP_PKG='GMOA_Admin' OR V_LDAP_PKG='GMOA_ADMIN') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaadmin_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaadmin_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
            
        
        ELSIF (V_LDAP_PKG='GMOA_Consultant' OR V_LDAP_PKG='GMOA_CONSULTANT') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaconsult_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'gmoaconsult_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            END IF;	
			
			
		ELSIF (V_LDAP_PKG='HOMEPLUS' OR V_LDAP_PKG='HOME PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'homeplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
			
			
		ELSIF (V_LDAP_PKG='OFFICEPLUS' OR V_LDAP_PKG='OFFICE PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'officeplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
			
			
			
		ELSIF (V_LDAP_PKG='XCELPLUS' OR V_LDAP_PKG='XCEL PLUS') THEN
        
        
            IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'NO Policy Defind'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'xcelplus_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
            
            
        ELSIF (V_LDAP_PKG='ABHIMAANA' OR V_LDAP_PKG='Abhimaana') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'abhimaana_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'abhimaana_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
            
            
            
        
        ELSIF (V_LDAP_PKG='SLT STAFF TRIPLE PLAY' OR V_LDAP_PKG='SLT STAFF') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'staff_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'staff_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;	
			
            
        ELSIF (V_LDAP_PKG='BROADBAND EXPERIENCE' OR V_LDAP_PKG='Broadband Experience') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'experience_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'experience_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;  
            
        ELSIF (V_LDAP_PKG='STUDENT PACKAGE 1' OR V_LDAP_PKG='STUDENT_PACKAGE_1') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student1_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student1_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;
        
        
        ELSIF (V_LDAP_PKG='STUDENT PACKAGE 2' OR V_LDAP_PKG='STUDENT_PACKAGE_2') THEN
        
           IF V_FUP = 'Y' THEN
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student2_heavy_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;

            ELSE
                

                UPDATE SERVICE_ORDER_ATTRIBUTES soa
                SET soa.SEOA_DEFAULTVALUE = 'student2_normal_down'
                WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                AND soa.SEOA_SERO_ID = p_sero_id;
            

            END IF;    

        ELSE
            
			
			UPDATE SERVICE_ORDER_ATTRIBUTES soa
            SET soa.SEOA_DEFAULTVALUE = 'No match'
            WHERE soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
            AND soa.SEOA_SERO_ID = p_sero_id;

        END IF;

      
 

 
      


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');





 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SET DOWNLOAD POLICY FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END  ADSL_SET_DOWNLOAD_POLICY;

-- Edited on 13-06-2012     
-- Edited on 02-01-2012      
-- edited on 21-09-2011

-- 12-08-2011 Samankula Owitipana

PROCEDURE ADSL_BLOCK_OLD_PKGS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      
v_ads_lpkg_name VARCHAR2(100);   
v_iptv_pkg_name VARCHAR2(100);
v_adsl_feature  VARCHAR2(100);
v_iptv_feature    VARCHAR2(100);


CURSOR c_adsl_pkg IS        
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PACKAGE_NAME';        

CURSOR c_iptv_pkg IS        
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IPTV_PACKAGE';    

CURSOR c_adsl_feature IS
SELECT trim(sof.SOFE_DEFAULTVALUE) 
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.SOFE_SERO_ID = p_sero_id
AND sof.SOFE_FEATURE_NAME = 'INTERNET';

CURSOR c_iptv_feature IS
SELECT trim(sof.SOFE_DEFAULTVALUE) 
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.SOFE_SERO_ID = p_sero_id
AND sof.SOFE_FEATURE_NAME = 'IPTV';

  

BEGIN
  

P_dynamic_procedure.complete_dp_address_check(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);
        
        


        

IF p_ret_msg IS NULL THEN



OPEN c_adsl_pkg;
FETCH c_adsl_pkg INTO v_ads_lpkg_name;
CLOSE c_adsl_pkg;

OPEN c_iptv_pkg;
FETCH c_iptv_pkg INTO v_iptv_pkg_name;
CLOSE c_iptv_pkg;

OPEN c_adsl_feature;
FETCH c_adsl_feature INTO v_adsl_feature;
CLOSE c_adsl_feature;

OPEN c_iptv_feature;
FETCH c_iptv_feature INTO v_iptv_feature;
CLOSE c_iptv_feature;


      IF (v_adsl_feature = 'Y' AND (v_ads_lpkg_name = 'HOME' OR v_ads_lpkg_name = 'HOME PLUS' OR v_ads_lpkg_name = 'OFFICE' 
      OR v_ads_lpkg_name = 'OFFICE 1IP' OR v_ads_lpkg_name = 'OFFICE PLUS' OR v_ads_lpkg_name = 'XCEL' OR v_ads_lpkg_name = 'XCEL 1IP' 
      OR v_ads_lpkg_name = 'XCEL PLUS' OR v_ads_lpkg_name = 'XCITE' OR v_ads_lpkg_name = 'XCITE PLUS')) THEN

      p_ret_msg := 'ADSL Package name is wrong' || v_ads_lpkg_name || ' . Please cancel the service order.' ;
      

      ELSIF (v_adsl_feature = 'Y' AND v_ads_lpkg_name IS NULL) THEN
      
      p_ret_msg := 'ADSL Package name is blank.';
      
    /*  ELSIF (v_iptv_feature = 'Y' AND v_iptv_pkg_name LIKE '%PRANAMA%') THEN
      
      p_ret_msg := 'IPTV Package name is wrong' || v_iptv_pkg_name || ' . Please cancel the service order.' ;*/
      
      ELSIF (v_iptv_feature = 'Y' AND v_iptv_pkg_name IS NULL) THEN
      
      p_ret_msg := 'IPTV Package name is blank.';
      
      ELSE

      p_ret_msg := '';

      END IF;
      
      

  ELSE

  p_ret_msg := p_ret_msg ;

  END IF;




EXCEPTION
WHEN NO_DATA_FOUND  THEN

    p_ret_msg := 'Package name is blank';
    
END ADSL_BLOCK_OLD_PKGS;

-- 19-10-2011 Samankula Owitipana


--- 28-09-2011  Samankula Owitipana

PROCEDURE SO_SET_EXPECTED_DATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      
      
      
      

v_exp_date VARCHAR2(100);

         
         
CURSOR c_comp_date_select IS
SELECT so.SERO_COMPLETION_DATE
FROM SERVICE_ORDERS SO
WHERE SO.SERO_ID = p_sero_id;
                  
         
         

 BEGIN
         
         
         
OPEN c_comp_date_select;
FETCH c_comp_date_select INTO v_exp_date;
CLOSE c_comp_date_select;

         
UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_exp_date
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE REQUIRED DATE';
         
         
        
         
         
         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
         
         

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to set SERVICE REQUIRED DATE. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );
          

END SO_SET_EXPECTED_DATE;

--- 28-09-2011  Samankula Owitipana

-- 18-10-2011 Samankula Owitipana
-----------Clarity Production Geneva DBLINK IS @DBLINK_GENEVA --------------------
-----------Change the DBLINK before sent to Clarity Production--------------------

PROCEDURE ACCOUNT_MANAGER_FROM_BSS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_acc_mgr VARCHAR2(150);
v_acc_no VARCHAR2(25);
v_acc_mgr_id NUMBER;


-----------Clarity Production Geneva DBLINK IS @DBLINK_GENEVA --------------------
-----------Change the DBLINK before sent to Clarity Production--------------------

/*CURSOR c_acc_manager_bss IS
SELECT trim(ca.ACCOUNT_MANAGER) 
FROM service_orders so,CUSTOMERATTRIBUTES@DBLINK_GENEVA ca
WHERE so.SERO_CUSR_ABBREVIATION = ca.CUSTOMER_REF
AND so.SERO_ID = p_sero_id;*/


CURSOR c_acc_mgr_id IS
SELECT am.ACCM_ID 
FROM ACCOUNT_MANAGERS am
WHERE trim(am.ACCM_SALESID) = v_acc_mgr;



BEGIN

/*OPEN c_acc_manager_bss;
FETCH c_acc_manager_bss INTO v_acc_mgr;
CLOSE c_acc_manager_bss;*/


OPEN c_acc_mgr_id;
FETCH c_acc_mgr_id INTO v_acc_mgr_id;
CLOSE c_acc_mgr_id;


SELECT so.SERO_ACCT_NUMBER
INTO v_acc_no 
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;



IF v_acc_mgr_id IS NOT NULL THEN

UPDATE ACCOUNTS ac
SET ac.ACCT_ACCM_ID = v_acc_mgr_id
WHERE ac.ACCT_NUMBER = v_acc_no;



END IF;



         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
             

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to update account manager. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );


END ACCOUNT_MANAGER_FROM_BSS;

-- 18-10-2011 Samankula Owitipana


---- Edited Dinesh 24-02-2015 ----
---- 02-11-2011 Samankula Owitipana
PROCEDURE PLANNED_EVENT_WG_CHANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_area    varchar2(25);
v_nature  varchar2(100);


BEGIN

select soa.SEOA_DEFAULTVALUE
into  v_nature
from SERVICE_ORDER_ATTRIBUTES soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'PE NATURE';

select pe.PLAE_REQA_ABBREVIATION 
into v_area
from PLANNED_EVENTS pe,SERVICE_ORDERS SO
where so.SERO_OEID = pe.PLAE_NUMBER
and so.SERO_ID = p_sero_id;

IF v_nature = 'LTE_PROJECT' THEN
UPDATE SERVICE_ORDERS SO
SET so.SERO_WORG_NAME = 'CEN-LTE-PROJECT'
WHERE SO.SERO_ID = p_sero_id;

ELSE 

UPDATE SERVICE_ORDERS SO
SET so.SERO_WORG_NAME = 'CEN-ENG-PROJECT'
WHERE SO.SERO_ID = p_sero_id;
END IF;

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_WORG_NAME = replace(sit.SEIT_WORG_NAME,'CEN',v_area)
where sit.SEIT_WORG_NAME = 'CEN-ENG-NW'
and sit.SEIT_SERO_ID = p_sero_id;


update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_WORG_NAME = replace(sit.SEIT_WORG_NAME,'CEN',v_area)
where sit.SEIT_WORG_NAME = 'CEN-RTOM'
and sit.SEIT_SERO_ID = p_sero_id;

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_WORG_NAME = replace(sit.SEIT_WORG_NAME,'CEN',v_area)
where sit.SEIT_WORG_NAME = 'CEN-MNG-OPMC'
and sit.SEIT_SERO_ID = p_sero_id;

         

         
     
         
         
    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');




EXCEPTION
WHEN OTHERS THEN


      p_ret_msg  := 'Failed to change workgroups:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

      INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );
        

END PLANNED_EVENT_WG_CHANGE;
--- 02-11-2011 Samankula Owitipana
---- Edited Dinesh 24-02-2015 ----

-- 07-10-2011 Samankula Owitipan
-- Completion rule

PROCEDURE PSTN_CHK_MANDATORY_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      
      
      
v_phone_class VARCHAR2(100);
v_issue_by       VARCHAR2(100);
v_issued_date VARCHAR2(100);
v_cpe_serial  VARCHAR2(100);


CURSOR c_phone_class IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'SA_PHONE_CLASS_CODE';


CURSOR c_issue_by IS
SELECT UPPER(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE ISSUED BY FO';

CURSOR c_issued_date IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'CPE ISSUE DATE';

CURSOR c_cpe_serial IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'CPE SERIAL NUMBER';




BEGIN


p_ret_msg := '';

PSTN_PORT_STATUS_CHECKING(
              p_serv_id,
              p_sero_id,
              p_seit_id,
              p_impt_taskname,
              p_woro_id,
              p_ret_char,
              p_ret_number,
              p_ret_msg);
              
              
IF p_ret_msg IS NULL THEN              

OPEN c_phone_class;
FETCH c_phone_class INTO v_phone_class;
CLOSE c_phone_class;

OPEN c_issue_by;
FETCH c_issue_by INTO v_issue_by;
CLOSE c_issue_by;

OPEN c_issued_date;
FETCH c_issued_date INTO v_issued_date;
CLOSE c_issued_date;

OPEN c_cpe_serial;
FETCH c_cpe_serial INTO v_cpe_serial;
CLOSE c_cpe_serial;





  IF v_phone_class = 'SLT' AND v_issue_by = 'YES' AND (v_issued_date IS NULL OR v_cpe_serial IS NULL) THEN

      p_ret_msg := 'CPE ISSUED BY FO, CPE ISSUED DATE and CPE_SERIAL NUMBER ATTRIBUTES MANDATORY' ;
      
  ELSIF v_phone_class = 'SLT' AND v_issue_by IS NULL THEN
        
      p_ret_msg := 'CPE ISSUED BY FO ATTRIBUTE IS MANDATORY' ;
  
  END IF;
  
  
ELSE


 p_ret_msg :=  p_ret_msg;
 

END IF;


EXCEPTION
WHEN OTHERS THEN

    p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END PSTN_CHK_MANDATORY_ATTR;
-- 07-10-2011 Samankula Owitipan


-- 07-10-2011 Samankula Owitipan
-- Completion rule

PROCEDURE PSTN_CHK_MANDATORY_ATTR2 (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

      
      
      
v_phone_class VARCHAR2(100);
v_issue_by       VARCHAR2(100);
v_issue_by_fs VARCHAR2(100);
v_issued_date VARCHAR2(100);
v_cpe_serial  VARCHAR2(100);


CURSOR c_phone_class IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'SA_PHONE_CLASS_CODE';


CURSOR c_issue_by IS
SELECT UPPER(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE ISSUED BY FO';

CURSOR c_issue_by_fs IS
SELECT UPPER(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CPE ISSUED BY FS';

CURSOR c_issued_date IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'CPE ISSUE DATE';

CURSOR c_cpe_serial IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME LIKE 'CPE SERIAL NUMBER';




BEGIN


p_ret_msg := '';

PSTN_PORT_STATUS_CHECKING(
              p_serv_id,
              p_sero_id,
              p_seit_id,
              p_impt_taskname,
              p_woro_id,
              p_ret_char,
              p_ret_number,
              p_ret_msg);
              
              
IF p_ret_msg IS NULL THEN              

OPEN c_phone_class;
FETCH c_phone_class INTO v_phone_class;
CLOSE c_phone_class;

OPEN c_issue_by;
FETCH c_issue_by INTO v_issue_by;
CLOSE c_issue_by;

OPEN c_issue_by_fs;
FETCH c_issue_by_fs INTO v_issue_by_fs;
CLOSE c_issue_by_fs;

OPEN c_issued_date;
FETCH c_issued_date INTO v_issued_date;
CLOSE c_issued_date;

OPEN c_cpe_serial;
FETCH c_cpe_serial INTO v_cpe_serial;
CLOSE c_cpe_serial;





  IF v_phone_class = 'SLT' AND (v_issue_by = 'NO' or v_issue_by is null)  AND v_issue_by_fs is null THEN

      p_ret_msg := 'CPE ISSUED BY FS ATTRIBUTE IS MANDATORY' ;
        
  ELSIF v_phone_class = 'SLT' AND (v_issue_by = 'NO' or v_issue_by is null) AND v_issue_by_fs = 'YES' AND (v_issued_date IS NULL OR v_cpe_serial IS NULL)  THEN
        
        p_ret_msg := 'CPE ISSUED BY FS, CPE ISSUED DATE and CPE_SERIAL NUMBER ATTRIBUTES MANDATORY' ;
  
  END IF;

  
  
ELSE


 p_ret_msg :=  p_ret_msg;
 

END IF;


EXCEPTION
WHEN OTHERS THEN

    p_ret_msg := ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END PSTN_CHK_MANDATORY_ATTR2;
-- 07-10-2011 Samankula Owitipan


--- 13-06-2011  Samankula Owitipana


  PROCEDURE SIPTRUNK_CONFTESTLINK_WGCH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS




CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;




CURSOR serv_categ_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SERVICE CATEGORY';





v_customer_type VARCHAR2(30);
v_service_type  VARCHAR2(30);
v_service_cat VARCHAR2(30);



BEGIN



OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;

OPEN serv_categ_cur;
FETCH serv_categ_cur INTO v_service_cat;
CLOSE serv_categ_cur;





        ---------------------- CONFIRM TEST LINK ------------------------------------------------------



        IF v_customer_type = 'CORPORATE-LARGE & VERY LARGE' AND  v_service_cat = 'TEST'  THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'CORPORATE-SME' AND  v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;

         ELSIF v_customer_type = 'CORPORATE-WHOLESALE' AND v_service_cat = 'TEST'   THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WHOSALES'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'CONFIRM TEST LINK' ;


         END IF;



    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



    EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change  in CONFIRM TEST LINK . Please check the Customer TYPE Attributes:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg || ' ' || v_customer_type);


 END SIPTRUNK_CONFTESTLINK_WGCH;


--- 13-06-2011  Samankula Owitipana

--- 13-06-2011  Samankula Owitipana

PROCEDURE SIPTRUNK_INSTALL_DSU_AEND (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      
      
      
      

         v_RTOM_VAL VARCHAR2(5);
         v_AEND_VAL VARCHAR2(5);
         
         
         CURSOR AEND_select_cur  IS
         SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
         WHERE SOA.SEOA_SERO_ID = p_sero_id
         AND SOA.SEOA_NAME = 'EXCHANGE AREA CODE A END';

         BEGIN
         
         
         
         OPEN AEND_select_cur;
         FETCH AEND_select_cur INTO v_AEND_VAL;
         CLOSE AEND_select_cur;
         
         

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;
         
         
         


         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-OSP-NC'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'INSTALL AEND OSP/DSU' ;



         
         
         
         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in INSTALL AEND OSP/DSU. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );
          

END SIPTRUNK_INSTALL_DSU_AEND;

--- 13-06-2011  Samankula Owitipana

--- 13-06-2011  Samankula Owitipana


PROCEDURE SIPTRUNK_ISSUE_INVOICE_WG_CH(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


CURSOR cust_type_cur  IS
SELECT cu.cusr_cutp_type FROM SERVICE_ORDERS SO,CUSTOMER cu
WHERE so.sero_cusr_abbreviation = cu.cusr_abbreviation
AND so.SERO_ID = p_sero_id;
      
v_customer_type VARCHAR2(50);

BEGIN


OPEN cust_type_cur;
FETCH cust_type_cur INTO v_customer_type;
CLOSE cust_type_cur;


         IF v_customer_type = 'CORPORATE-LARGE & VERY LARGE' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-CORP-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_customer_type = 'CORPORATE-SME' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-SME-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;

         ELSIF v_customer_type = 'CORPORATE-WHOLESALE' THEN

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = 'MKT-SALES-WSALE-FO'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'ISSUE INVOICE' ;


         END IF;




p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to change WG. Please check customer type :' || v_customer_type || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END SIPTRUNK_ISSUE_INVOICE_WG_CH;


--- 13-06-2011  Samankula Owitipana

--- 21-06-2011  Samankula Owitipana

PROCEDURE SIPTRUNK_SEPERATE_VLAN_VPN (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      

         
v_vpn_nam             VARCHAR2(100);
v_vlan_id             VARCHAR2(100);             



CURSOR VLAN_select_cur  IS     
SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)+1)
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'VPN NAME' ;

CURSOR VPN_select_cur  IS
SELECT SUBSTR(soa.SEOA_DEFAULTVALUE, 1,INSTR(soa.SEOA_DEFAULTVALUE, ',', 1, 1)-1)
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'VPN NAME' ;     
         

BEGIN
 
OPEN VPN_select_cur;
FETCH VPN_select_cur INTO v_vpn_nam;
CLOSE VPN_select_cur;

OPEN VLAN_select_cur;
FETCH VLAN_select_cur INTO v_vlan_id;
CLOSE VLAN_select_cur;
         
         


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_vpn_nam
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'VPN NAME' ;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_vlan_id
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'CUSTOMER VLAN ID' ;


         
         
         
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to set VPN NAME and VLAN. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );
          

END SIPTRUNK_SEPERATE_VLAN_VPN;

--- 21-06-2011  Samankula Owitipana

--- 21-06-2011  Samankula Owitipana

PROCEDURE SIPTRUNK_SET_SPEED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      

         
v_speed        VARCHAR2(100);             



CURSOR speed_select_cur  IS     
SELECT soa.SEOA_DEFAULTVALUE
FROM service_order_attributes soa
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'SERVICE_SPEED' ;

 
         

BEGIN
 
OPEN speed_select_cur;
FETCH speed_select_cur INTO v_speed;
CLOSE speed_select_cur;



UPDATE service_orders so
SET so.SERO_SPED_ABBREVIATION = v_speed
WHERE so.SERO_ID = p_sero_id;

/*UPDATE services se
set se.SERV_SPED_ABBREVIATION = v_speed
where se.SERV_ID = p_serv_id;*/

         
         
         
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'Failed to set SERVICE_SPEED. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );
          

END SIPTRUNK_SET_SPEED;

--- 21-06-2011  Samankula Owitipana

--- 21-06-2011  Samankula Owitipana

PROCEDURE SIPTRUNK_WO_TO_MDF (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      
      
      
      

         v_RTOM_VAL VARCHAR2(5);
         v_AEND_VAL VARCHAR2(5);
         v_TP_NW    VARCHAR2(100);
         v_ACC_MEDIA VARCHAR2(100);
         
         
         CURSOR AEND_select_cur  IS
         SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
         WHERE SOA.SEOA_SERO_ID = p_sero_id
         AND SOA.SEOA_NAME = 'EXCHANGE_AREA_CODE';
         
         CURSOR TNW_select_cur  IS
         SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
         WHERE SOA.SEOA_SERO_ID = p_sero_id
         AND SOA.SEOA_NAME = 'TRANSPORT NETWORK1';
         
         CURSOR ACC_media_select_cur  IS
         SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
         WHERE SOA.SEOA_SERO_ID = p_sero_id
         AND SOA.SEOA_NAME = 'ACCESS MEDIUM';
         
         
         

 BEGIN
         
         
         
         OPEN AEND_select_cur;
         FETCH AEND_select_cur INTO v_AEND_VAL;
         CLOSE AEND_select_cur;
         
         OPEN TNW_select_cur;
         FETCH TNW_select_cur INTO v_TP_NW;
         CLOSE TNW_select_cur;
         
         OPEN ACC_media_select_cur;
         FETCH ACC_media_select_cur INTO v_ACC_MEDIA;
         CLOSE ACC_media_select_cur;
         
         
         IF (v_TP_NW = 'MLLN' OR v_TP_NW = 'DSL') AND v_ACC_MEDIA <> 'FIBER' THEN

         SELECT SUBSTR(ar.area_area_code,3) INTO v_RTOM_VAL
         FROM areas ar
         WHERE ar.area_code = v_AEND_VAL;


         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = trim(v_RTOM_VAL) || '-' || trim(v_AEND_VAL) || '-MDF'
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO FOR MDF' ;
         
         ELSE
         
         DELETE FROM SERVICE_IMPLEMENTATION_TASKS SIT
         WHERE SIT.SEIT_SERO_ID =  p_sero_id
         AND SIT.SEIT_TASKNAME = 'WO FOR MDF' ;
         
         END IF;



         
         
         
         p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

        EXCEPTION
        WHEN OTHERS THEN


        p_ret_msg  := 'Failed to Change WG in WO FOR MDF. ' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg );
          

END SIPTRUNK_WO_TO_MDF;

--- 21-06-2011  Samankula Owitipana

-- 07-02-2011 Samankula Owitipana

PROCEDURE SIMCALL_SET_NUM_RANGE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS






v_number VARCHAR2(10);
v_city_code VARCHAR2(4);

CURSOR  cur_number_select  IS 
SELECT nu.NUMB_NUCC_CODE,nu.NUMB_NUMBER
FROM numbers nu
WHERE nu.NUMB_SERV_ID = p_serv_id
AND nu.NUMB_NUMS_ID = 3;


BEGIN



OPEN cur_number_select;
FETCH  cur_number_select INTO v_city_code,v_number;
CLOSE cur_number_select;


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_city_code || v_number 
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'LOCAL NUMBER' ;





p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to update number range attribute:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END SIMCALL_SET_NUM_RANGE;

-- 07-02-2011 Samankula Owitipana


END;
/
