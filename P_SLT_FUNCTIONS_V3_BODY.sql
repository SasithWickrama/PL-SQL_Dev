CREATE OR REPLACE PACKAGE BODY GCI_MIG.P_SLT_FUNCTIONS_V3 is


--- Jayan Liyanage 2013/04/22

PROCEDURE SLT_IDD_ACC (
   p_serv_id         IN     Services.serv_id%TYPE,
   p_sero_id         IN     Service_Orders.sero_id%TYPE,
   p_seit_id         IN     Service_Implementation_Tasks.seit_id%TYPE,
   p_impt_taskname   IN     Implementation_Tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   CURSOR Cr_idd
   IS
      SELECT DISTINCT sof.sofe_defaultvalue
       FROM service_order_features sof
       WHERE sof.sofe_feature_name = 'SF_IDD'
       AND SOF.SOFE_SERO_ID = p_sero_id
       AND NVL(SOFE_DEFAULTVALUE,'N') <> NVL(SOFE_PREV_VALUE,'N');
       
   v_idd_val   VARCHAR2 (100);
   v_or_type   VARCHAR2 (100);
BEGIN
   OPEN Cr_idd;

   FETCH Cr_idd INTO v_idd_val;

   CLOSE Cr_idd;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_or_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   IF v_or_type = 'MODIFY-PRICE' AND v_idd_val = 'Y'
   THEN
      UPDATE SERVICE_ORDER_FEATURES sof
         SET sof.sofe_provision_status = 'Y',
             sof.SOFE_PROVISION_TIME = SYSDATE,
             sof.SOFE_PROVISION_USERNAME = 'CLARITY'
       WHERE     sof.sofe_sero_id = p_sero_id
             AND sof.sofe_feature_name = 'SF_IDD';
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');
      p_ret_msg :=
            'Failed to Active IDD Feature.. Please Check IDD Feature Value. :'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS (SETC_SEIT_ID,
                                         SETC_ID,
                                         SETC_USERID,
                                         SETC_TIMESTAMP,
                                         SETC_TEXT)
           VALUES (p_seit_id,
                   SETC_ID_SEQ.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END SLT_IDD_ACC;
--- Jayan Liyanage 2013/04/22


---Dulip Fernando 2013/03/08
--MODIFIED 2013-04-02
--D-BIL  MODIFY-SPEED  task populate

PROCEDURE D_BIL_MODIFY_SPEED (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_cir_status              VARCHAR2 (100);
   v_new_bearer_id           VARCHAR2 (100);
   v_section_hndle           VARCHAR2 (100);
   v_service_type            VARCHAR2 (100);
   v_service_order           VARCHAR2 (100);
   v_service_order_area      VARCHAR2 (100);
   v_rtom_code               VARCHAR2 (100);
   v_lea_code                VARCHAR2 (100);
   v_acc_bear_status         VARCHAR2 (100);
   v_core_network            VARCHAR2 (100);
   v_acc_medium              VARCHAR2 (100);
   v_work_group              VARCHAR2 (100);
   v_acc_nw                  VARCHAR2 (100);
   v_cur_ntu_class           VARCHAR2 (100);
   v_pre_ntu_class           VARCHAR2 (100);
   v_work_group_cpe          VARCHAR2 (100);
   v_ser_ctg                 VARCHAR2 (100);
   v_so_attr_name            VARCHAR2 (100);
   v_so_attr_val             VARCHAR2 (100);
   v_bearer_id               VARCHAR2 (100);
   v_no_of_copper_pair_cur   VARCHAR2 (100);
   v_no_of_copper_pair_pre   VARCHAR2 (100);
   v_cpe_class_cur           VARCHAR2 (100);
   v_cpe_class_pre           VARCHAR2 (100);
   v_acc_port_bw_cur         VARCHAR2 (100);
   v_acc_port_bw_pre         VARCHAR2 (100);
   v_cur_ntu_model           VARCHAR2 (100);
   v_pre_ntu_model           VARCHAR2 (100);
   v_cur_cpe_model           VARCHAR2 (100);
   v_pre_cpe_model           VARCHAR2 (100);
   v_Cur_port_bw             VARCHAR2 (100);
   v_Pre_port_bw             VARCHAR2 (100);
   v_acc_nw_pre              VARCHAR2 (100);
   v_agre_nw                 VARCHAR2 (1000);
   v_test_ser_alterd         VARCHAR2 (1000);


BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_section_hndle
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_status
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS BEARER STATUS';

   SELECT DISTINCT so.sero_area_code
     INTO v_service_order_area
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes,
          ar.area_code
     INTO v_rtom_code, v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_medium
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cur_ntu_class, v_pre_ntu_class
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cur_ntu_model, v_pre_ntu_model
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_nw, v_acc_nw_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_Cur_port_bw, v_Pre_port_bw
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS INTF PORT BW';

   SELECT soa.seoa_defaultvalue
     INTO v_ser_ctg
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_no_of_copper_pair_cur, v_no_of_copper_pair_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'NO OF COPPER PAIRS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_class_cur, v_cpe_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cur_cpe_model, v_pre_cpe_model
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_port_bw_cur, v_acc_port_bw_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS INTF PORT BW';

   SELECT soa.seoa_defaultvalue
     INTO v_agre_nw
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'AGGREGATE NETWORK';

   SELECT soa.seoa_defaultvalue
     INTO v_test_ser_alterd
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'TEST SERVICE ALTERED?';
 

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_medium = 'P2P RADIO'
      AND v_Cur_port_bw <> v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'TX-RADIO-LAB'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONDUCT FIELD TRIAL';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONDUCT FIELD TRIAL';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_no_of_copper_pair_cur <> v_no_of_copper_pair_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CORP-SSU'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REDESIGN CIRCUIT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REDESIGN CIRCUIT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_no_of_copper_pair_cur > v_no_of_copper_pair_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT. ADD. SHDSL PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT. ADD. SHDSL PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_no_of_copper_pair_cur < v_no_of_copper_pair_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD.SHDSL PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD.SHDSL PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_no_of_copper_pair_cur > v_no_of_copper_pair_pre)
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST. ADD. OSP LINE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST. ADD. OSP LINE';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_no_of_copper_pair_cur = v_no_of_copper_pair_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB. PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB. PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_medium = 'P2P RADIO'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'TX-RADIO-LAB'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY RADIO LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY RADIO LINK';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_Cur_ntu_class = 'SLT'
      AND v_cur_ntu_model <> v_pre_ntu_model
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_cpe
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'MODIFY NTU'
             AND sit.seit_sero_id = p_sero_id;
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_Cur_ntu_class = 'SLT'
      AND v_cur_ntu_model = v_pre_ntu_model
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'RECONFIG NTU'
             AND sit.seit_sero_id = p_sero_id;
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_class_cur = 'SLT'
      AND v_cpe_class_pre = 'SLT'
      AND (v_cur_cpe_model <> v_pre_cpe_model)
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'MODIFY CPE'
             AND (sit.seit_sero_id = p_sero_id);
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_class_cur = 'SLT'
      AND v_cpe_class_pre <> 'SLT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'INSTALL CPE'
             AND sit.seit_sero_id = p_sero_id;
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_class_cur <> 'SLT'
      AND v_cpe_class_pre = 'SLT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'COLLECT CPE'
             AND sit.seit_sero_id = p_sero_id;
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_class_cur = 'SLT'
      AND (v_cur_cpe_model = v_pre_cpe_model)
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'RECONFIG CPE'
             AND (sit.seit_sero_id = p_sero_id);
   END IF;



   IF v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_agre_nw = 'MEN'
      AND v_acc_nw <> 'MEN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'MODIFY MEN VLAN'
             AND sit.seit_sero_id = p_sero_id;
   END IF;


   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_agre_nw = 'CEN'
      AND v_acc_nw <> 'CEN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'MODIFY CEN VLAN'
             AND sit.seit_sero_id = p_sero_id;
   END IF;


   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'MEN PORT'
      AND v_Cur_port_bw <> v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG. MEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG. MEN PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'CEN PORT'
      AND v_Cur_port_bw <> v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG. CEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG. CEN PORT';
   END IF;


   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'MEN PORT'
      AND v_Cur_port_bw = v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'CEN PORT'
      AND v_Cur_port_bw = v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'MPLS PORT'
      AND v_Cur_port_bw = v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MPLS SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MPLS SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw = 'MEN PORT'
      AND v_Cur_port_bw <> v_Pre_port_bw
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN PORT BW';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'MODIFY MEN PORT BW'
             AND sit.seit_sero_id = p_sero_id;
   END IF;


   

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ser_ctg = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-ACCM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   END IF;

   

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (   v_no_of_copper_pair_cur <> v_no_of_copper_pair_pre
           OR v_acc_port_bw_cur <> v_acc_port_bw_pre)
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-FO'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'UPDATE ACC. BEARER';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_taskname = 'UPDATE ACC. BEARER'
             AND sit.seit_sero_id = p_sero_id;
   END IF;

   
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_no_of_copper_pair_cur < v_no_of_copper_pair_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE ADD. OSP LINE';
   ELSIF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-SPEED'
   THEN
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE ADD. OSP LINE';
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D-Premium VPN Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_BIL_MODIFY_SPEED;

--Dulip Fernando 2013/03/08


--- Indika de silva 14/04/2013

PROCEDURE D_BIL_MOD_LOC_WF1 (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   CURSOR pre_cir (v_old_ids VARCHAR)
   IS
      SELECT DISTINCT c.cirt_status
        FROM circuits c
       WHERE c.cirt_displayname = v_old_ids;

   CURSOR cur_tributer (
      parent_name     VARCHAR2,
      v_new_cir_id    VARCHAR2)
   IS
      SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
        FROM circuits c, circuit_hierarchy ch, circuits ci
       WHERE     c.cirt_name = ch.cirh_parent
             AND ch.cirh_child = ci.cirt_name
             AND (   ci.cirt_status LIKE 'INSERVICE%'
                  OR ci.cirt_status LIKE 'PROPOSED%'
                  OR ci.cirt_status LIKE 'SUSPEND%'
                  OR ci.cirt_status LIKE 'COMMISS%')
             AND (   ci.cirt_status NOT LIKE 'CANCE%'
                  OR ci.cirt_status NOT LIKE 'PENDING%')
             AND ci.cirt_displayname NOT LIKE
                    REPLACE (v_new_cir_id, '(N)') || '%'
             AND c.cirt_displayname LIKE REPLACE (parent_name, '(N)') || '%';

   CURSOR cur_old_tributer (
      old_parent_name    VARCHAR2,
      v_new_cir_id       VARCHAR2)
   IS
      SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
        FROM circuits c, circuit_hierarchy ch, circuits ci
       WHERE     c.cirt_name = ch.cirh_parent
             AND ch.cirh_child = ci.cirt_name
             AND (   ci.cirt_status LIKE 'INSERVICE%'
                  OR ci.cirt_status LIKE 'PROPOSED%'
                  OR ci.cirt_status LIKE 'SUSPEND%'
                  OR ci.cirt_status LIKE 'COMMISS%')
             AND (   ci.cirt_status NOT LIKE 'CANCE%'
                  OR ci.cirt_status NOT LIKE 'PENDING%')
             AND ci.cirt_displayname NOT LIKE
                    REPLACE (v_new_cir_id, '(N)') || '%'
             AND c.cirt_displayname LIKE
                    REPLACE (old_parent_name, '(N)') || '%';

   v_cir_status              VARCHAR2 (100);
   v_new_bearer_id           VARCHAR2 (100);
   v_section_hndle           VARCHAR2 (100);
   v_service_type            VARCHAR2 (100);
   v_service_order           VARCHAR2 (100);
   v_service_order_area      VARCHAR2 (100);
   v_rtom_code               VARCHAR2 (100);
   v_lea_code                VARCHAR2 (100);
   v_acc_bear_status         VARCHAR2 (100);
   v_core_network            VARCHAR2 (100);
   v_acc_medium_cur          VARCHAR2 (100);
   v_acc_medium_pre          VARCHAR2 (100);
   v_work_group              VARCHAR2 (100);
   v_acc_nw                  VARCHAR2 (100);
   v_ntu_class_cur           VARCHAR2 (100);
   v_ntu_class_pre           VARCHAR2 (100);
   v_work_group_cpe          VARCHAR2 (100);
   v_ser_ctg                 VARCHAR2 (100);
   v_so_attr_name            VARCHAR2 (100);
   v_so_attr_val             VARCHAR2 (100);
   v_bearer_id               VARCHAR2 (100);
   v_no_of_copper_pair_cur   VARCHAR2 (100);
   v_no_of_copper_pair_pre   VARCHAR2 (100);
   v_cpe_class_cur           VARCHAR2 (100);
   v_cpe_class_pre           VARCHAR2 (100);
   v_acc_port_bw_cur         VARCHAR2 (100);
   v_acc_port_bw_pre         VARCHAR2 (100);
   v_acc_node_change         VARCHAR2 (100);
   v_old_cir_id              VARCHAR2 (100);
   v_old_ids                 VARCHAR2 (100);
   v_old_staus               VARCHAR2 (100);
   parent_name               VARCHAR2 (100);
   v_new_cir_id              VARCHAR2 (100);
   v_access_bear_id          VARCHAR2 (100);
   v_new_cir_name            VARCHAR2 (100);
   v_pre_access_bear_id      VARCHAR2 (100);
   old_parent_name           VARCHAR2 (100);
   v_old_ch_dis              VARCHAR2 (100);
   v_old_cir_trib_status     VARCHAR2 (100);
   v_ch_dis                  VARCHAR2 (100);
   v_cir_trib_status         VARCHAR2 (100);
   v_pre_acc_nw              VARCHAR2 (100);
   v_work_group_nw           VARCHAR2 (100);
   v_cur_media               VARCHAR2 (100);
   v_pre_media               VARCHAR2 (100);
   v_pre_core_nw             VARCHAR2 (100);
   v_cpe_mode_cur            VARCHAR2 (100);
   v_cpe_mode_pre            VARCHAR2 (100);
   v_aggr_nw                 VARCHAR2 (100);
   v_aggr_nw_pre             VARCHAR2 (100);
   v_fib_avalable            VARCHAR2 (100);
   
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_section_hndle
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_status
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS BEARER STATUS';

   SELECT DISTINCT so.sero_area_code
     INTO v_service_order_area
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes,
          ar.area_code
     INTO v_rtom_code, v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_nw
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'ENG-NW' || '%';

   SELECT wg.worg_name
     INTO v_work_group_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_medium_cur, v_acc_medium_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_ntu_class_cur, v_ntu_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_nw, v_pre_acc_nw
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

   SELECT soa.seoa_defaultvalue
     INTO v_ser_ctg
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_no_of_copper_pair_cur, v_no_of_copper_pair_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'NO OF COPPER PAIRS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_class_cur, v_cpe_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_mode_cur, v_cpe_mode_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_port_bw_cur, v_acc_port_bw_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS INTF PORT BW';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_node_change
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS NODE CHANGE?';

   SELECT soa.seoa_defaultvalue
     INTO v_old_cir_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'OLD CIRCUIT ID';


   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_access_bear_id, v_pre_access_bear_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID';


   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_aggr_nw, v_aggr_nw_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'AGGREGATE NETWORK';
          
  select distinct soa.seoa_defaultvalue into v_fib_avalable  
  from service_order_attributes soa 
     where soa.seoa_name = 'ACCESS FIBER AVAILABLE ?' and soa.seoa_sero_id = p_sero_id;



   SELECT DISTINCT c.cirt_displayname
     INTO v_new_cir_name
     FROM service_orders so, circuits c
    WHERE so.sero_cirt_name = c.cirt_name AND so.sero_id = p_sero_id;

   OPEN cur_tributer (v_access_bear_id, v_new_cir_name);

   FETCH cur_tributer
      INTO v_ch_dis, v_cir_trib_status;

   CLOSE cur_tributer;

   OPEN cur_old_tributer (v_pre_access_bear_id, v_new_cir_name);

   FETCH cur_old_tributer
      INTO v_old_ch_dis, v_old_cir_trib_status;

   CLOSE cur_old_tributer;



   ---VERIFY NTU
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU';
   END IF;


   ---CONFIG MEN VLAN
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw <> 'MEN PORT'
      AND v_acc_node_change = 'YES'
      AND (v_aggr_nw = 'MEN')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN VLAN';
   END IF;


   ----CONFIG CEN VLAN
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw <> 'CEN PORT'
      AND v_acc_node_change = 'YES'
      AND (v_aggr_nw = 'CEN')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN VLAN';
   END IF;

   ---CONFIG MEN PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw = 'MEN PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN PORT';
   END IF;


   ---CONFIG CEN PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw = 'CEN PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN PORT';
   END IF;

   ---CONFIG MPLS PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw = 'MPLS PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MPLS PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MPLS PORT';
   END IF;


   ---CONFIG MEN SUB PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw = 'MEN PORT'
      AND v_acc_bear_status = 'INSERVICE'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG MEN SUB PORT';
   END IF;


   ----CONFIG CEN SUB PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_nw = 'CEN PORT'
      AND v_acc_bear_status = 'INSERVICE'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG CEN SUB PORT';
   END IF;


   ---ACTIVATE SHDSL PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'COMMISSIONED'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE SHDSL PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE SHDSL PORT';
   END IF;


   ---ACTIVATE TRIB. PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE TRIB. PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE TRIB. PORT';
   END IF;


   ---CONFIG INTERNET PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-NW-SYSADMIN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG INTERNET PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIG INTERNET PORT';
   END IF;

 -- Jayan Liyanage Modified 2014/10/24

/*   ----COMM. FIBER LINK

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_cur = 'FIBER'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CORP-SSU'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COMM. FIBER LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COMM. FIBER LINK';
   END IF;*/
   
      ----COMM. FIBER LINK

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_cur = 'FIBER'
      AND v_acc_bear_status = 'COMMISSIONED'
      AND ( v_fib_avalable = 'NO' OR v_fib_avalable = 'INCOMPLETE')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'SFC-SOM-DATA'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'WAIT FOR FIBER';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'WAIT FOR FIBER';
   END IF;

 -- Jayan Liyanage Modified  End.2014/10/24
 
   ---ESTABLISH ACC.LINK

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_acc_medium_cur = 'FIBER' OR v_acc_medium_cur = 'COPPER-UTP')
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_nw
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ESTABLISH ACC.LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ESTABLISH ACC.LINK';
   END IF;


   ---INSTALL SLT-END NTU

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_cur = 'P2P RADIO'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL SLT-END NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL SLT-END NTU';
   END IF;


   ---SETUP RADIO LINK
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_cur = 'P2P RADIO'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'TX-RADIO-LAB'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'SETUP RADIO LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'SETUP RADIO LINK';
   END IF;


   ---CONSTRUCT OSP LINE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_cur = 'COPPER'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT OSP LINE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT OSP LINE';
   END IF;


   ----INSTALL CPE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_cpe_class_cur = 'SLT'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE';
   END IF;


   ---RECONFIG CPE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_cpe_class_cur = 'SLT'
      AND v_acc_bear_status = 'INSERVICE'
      AND v_cpe_mode_cur = v_cpe_mode_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE';
   END IF;


   ---RECON INTERNET PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'NO'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-NW-SYSADMIN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECON INTERNET PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECON INTERNET PORT';
   END IF;


   ---ACT INTERNET PORT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-NW-SYSADMIN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT INTERNET PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT INTERNET PORT';
   END IF;


   ---ACTIVATE ACC BEARER
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-FO'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE ACC BEARER';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE ACC BEARER';
   END IF;


   ---DEACT OLD MEN VLAN
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_aggr_nw_pre = 'MEN')
      AND v_acc_node_change = 'YES'
      AND v_pre_acc_nw <> 'MEN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD MEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD MEN VLAN';
   END IF;


   ---DEACT OLD CEA VLAN
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_aggr_nw_pre = 'CEN')
      AND v_acc_node_change = 'YES'
      AND v_pre_acc_nw <> 'MEN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD CEA VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD CEA VLAN';
   END IF;


   ---DEL OLD INTERNET PRT

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'INT-NW-SYSADMIN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD INTERNET PRT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD INTERNET PRT';
   END IF;

   ---REMOVE ACC. LINK
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_acc_medium_pre = 'FIBER' OR v_acc_medium_pre = 'COPPER-UTP')
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_nw
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE ACC. LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE ACC. LINK';
   END IF;

   ---COLLECT OLD RADIO
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_pre = 'P2P RADIO'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'TX-RADIO-LAB'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD RADIO';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD RADIO';
   END IF;

   ---REMOVE SLT-END NTU
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_pre = 'P2P RADIO'
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE SLT-END NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE SLT-END NTU';
   END IF;


   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D_BIL_MOD_LOC_WF1 Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_BIL_MOD_LOC_WF1;

--- Indika de silva 14/04/2013

--- Indika de silva 14/04/2013
PROCEDURE D_BIL_MOD_LOC_WF2 (
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
   
   v_cir_status              VARCHAR2 (100);
   v_new_bearer_id           VARCHAR2 (100);
   v_section_hndle           VARCHAR2 (100);
   v_service_type            VARCHAR2 (100);
   v_service_order           VARCHAR2 (100);
   v_service_order_area      VARCHAR2 (100);
   v_rtom_code               VARCHAR2 (100);
   v_lea_code                VARCHAR2 (100);
   v_acc_bear_status         VARCHAR2 (100);
   v_core_network            VARCHAR2 (100);
   v_acc_medium_cur          VARCHAR2 (100);
   v_acc_medium_pre          VARCHAR2 (100);
   v_work_group              VARCHAR2 (100);
   v_acc_nw                  VARCHAR2 (100);
   v_ntu_class_cur           VARCHAR2 (100);
   v_ntu_class_pre           VARCHAR2 (100);
   v_work_group_cpe          VARCHAR2 (100);
   v_ser_ctg                 VARCHAR2 (100);
   v_so_attr_name            VARCHAR2 (100);
   v_so_attr_val             VARCHAR2 (100);
   v_bearer_id               VARCHAR2 (100);
   v_no_of_copper_pair_cur   VARCHAR2 (100);
   v_no_of_copper_pair_pre   VARCHAR2 (100);
   v_cpe_class_cur           VARCHAR2 (100);
   v_cpe_class_pre           VARCHAR2 (100);
   v_acc_port_bw_cur         VARCHAR2 (100);
   v_acc_port_bw_pre         VARCHAR2 (100);
   v_acc_node_change         VARCHAR2 (100);
   v_old_cir_id              VARCHAR2 (100);
   v_old_ids                 VARCHAR2 (100);
   v_old_staus               VARCHAR2 (100);
   parent_name               VARCHAR2 (100);
   v_new_cir_id              VARCHAR2 (100);
   v_access_bear_id          VARCHAR2 (100);
   v_new_cir_name            VARCHAR2 (100);
   v_pre_access_bear_id      VARCHAR2 (100);
   old_parent_name           VARCHAR2 (100);
   v_old_ch_dis              VARCHAR2 (100);
   v_old_cir_trib_status     VARCHAR2 (100);
   v_ch_dis                  VARCHAR2 (100);
   v_cir_trib_status         VARCHAR2 (100);
   v_pre_acc_nw              VARCHAR2 (100);
   v_work_group_nw           VARCHAR2 (100);
   v_cur_media               VARCHAR2 (100);
   v_pre_media               VARCHAR2 (100);
   v_pre_core_nw             VARCHAR2 (100);
   v_cpe_mode_cur            VARCHAR2 (100);
   v_cpe_mode_pre            VARCHAR2 (100);
   v_aggr_nw                 VARCHAR2 (100);   
   v_aggr_nw_pre             VARCHAR2 (100);
   v_ntu_model_ch_cur        VARCHAR2 (100);
      
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
              INTO v_service_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_order
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_status
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id
      AND soa.seoa_name = 'ACCESS BEARER STATUS';


  SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_ntu_class_cur, v_ntu_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

  SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_access_bear_id, v_pre_access_bear_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID';


  
    
    ---RECONFIG NTU
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_ntu_class_cur = 'SLT'
      AND v_acc_bear_status = 'INSERVICE'
      AND v_ntu_model_ch_cur= 'NO'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'RECONFIG NTU';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'RECONFIG NTU';
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
            'Failed to Change D_BIL_MOD_LOC_WF2 Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END D_BIL_MOD_LOC_WF2;

--- Indika de silva 14/04/2013


-- Indika de silva 04/04/2013
PROCEDURE MODIFY_CPE_EQUI_DSP_MAP (
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
   v_actual_dsp_date    VARCHAR2 (100);
   bearer_id            VARCHAR2 (100);
   v_service_od_id      VARCHAR2 (100);
   v_cir_status         VARCHAR2 (100);
   v_service_ord_type   VARCHAR2 (100);
   v_new_bearer_id      VARCHAR2 (100);
   v_new_service        VARCHAR2 (100);


   CURSOR bearer_so (v_new_bearer_id VARCHAR, v_new_service VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
                 FROM service_orders so,
                      service_order_attributes soa,
                      circuits c
                WHERE so.sero_id = soa.seoa_sero_id
                  AND so.sero_cirt_name = c.cirt_name
                  AND (    c.cirt_status <> 'CANCELLED'
                       AND c.cirt_status <> 'PENDINGDELETE'
                      )
                  AND so.sero_stas_abbreviation <> 'CANCELLED'
                  AND so.sero_ordt_type = v_new_service
                  AND so.sero_id IN (
                         SELECT MAX (s.sero_id)
                           FROM service_orders s, circuits ci
                          WHERE s.sero_cirt_name = ci.cirt_name
                            AND s.sero_ordt_type = v_new_service
                            AND ci.cirt_displayname = v_new_bearer_id);
BEGIN
   SELECT DISTINCT soa.seoa_defaultvalue
              INTO bearer_id
              FROM service_orders so, service_order_attributes soa
             WHERE so.sero_id = soa.seoa_sero_id
               AND soa.seoa_name = 'ACCESS BEARER ID'
               AND so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_ord_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_actual_dsp_date
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   OPEN bearer_so (bearer_id, v_service_ord_type);

   FETCH bearer_so
    INTO v_service_od_id, v_cir_status;

   CLOSE bearer_so;

   IF v_cir_status = 'INSERVICE'
   THEN
      UPDATE service_order_attributes soa
         SET soa.seoa_defaultvalue = v_actual_dsp_date
       WHERE soa.seoa_sero_id = v_service_od_id
         AND soa.seoa_name = 'ACTUAL_DSP_DATE';

      UPDATE service_implementation_tasks sit
         SET sit.seit_stas_abbreviation = 'COMPLETED'
       WHERE sit.seit_taskname = 'ENTER BEARER DSP'
         AND sit.seit_sero_id = v_service_od_id;
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
            'Failed to Change  Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END MODIFY_CPE_EQUI_DSP_MAP;


-- Indika de silva 04/04/2013


---- Dulip Fernando 2013-02-26 
---- Modified 2013-03-12
---- MOdified 2013-03-20 comment CONSTRUCT FIBER LINK /ACT. SERVICE PORT /
--- Modified Jayan Liyanage 20/10/2015

PROCEDURE D_BIL_MODIFY_EQUIP_WF1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 )
IS 
v_cir_status           VARCHAR2 (100);
v_new_bearer_id        VARCHAR2 (100);
v_section_hndle        VARCHAR2 (100);
v_service_type         VARCHAR2 (100);
v_service_order        VARCHAR2 (100);
v_service_order_area   VARCHAR2 (100);
v_rtom_code            VARCHAR2 (100);
v_lea_code             VARCHAR2 (100);
v_acc_bear_status      VARCHAR2 (100);
v_core_network         VARCHAR2 (100);
v_acc_medium           VARCHAR2 (100);
v_work_group           VARCHAR2 (100);
v_acc_nw_intf               VARCHAR2 (100);
v_ntu_class_cur            VARCHAR2 (100);
v_ntu_model_changed    VARCHAR2 (100);
v_work_group_cpe       VARCHAR2 (100);
v_ser_ctg              VARCHAR2 (100);
v_so_attr_name         VARCHAR2 (100);
v_so_attr_val          VARCHAR2 (100);
v_bearer_id            VARCHAR2 (100);
v_eng_net              VARCHAR2 (100);
v_cpe_class_cur            VARCHAR2 (100);
v_cur_cpe_model        VARCHAR2 (100);
v_pre_cpe_model        VARCHAR2 (100);
v_net_aggri            VARCHAR2 (100); 
v_fib_avalable         VARCHAR2 (100); 
--v_net_aggri_1          VARCHAR2 (100);
--v_net_aggri_2          VARCHAR2 (100);
v_ntu_model_cur        VARCHAR2 (100); 
v_ntu_model_pre        VARCHAR2 (100); 
v_ntu_class_pre        VARCHAR2 (100); 
v_Cur_Vlan_Tag         VARCHAR2 (100);
v_Pre_Vlan_Tag         VARCHAR2 (100);
v_work_group_nw      VARCHAR2 (100);
v_cpe_class_pre        VARCHAR2 (100);
v_cpe_mod_cur         VARCHAR2 (100);
v_cpe_mod_pre         VARCHAR2 (100);



BEGIN

SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type
FROM service_orders so WHERE so.sero_id = p_sero_id;

SELECT DISTINCT so.sero_ordt_type INTO v_service_order
FROM service_orders so WHERE so.sero_id = p_sero_id;

SELECT DISTINCT so.sero_area_code INTO v_service_order_area
FROM service_orders so WHERE so.sero_id = p_sero_id;

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes,
ar.area_code INTO v_rtom_code,v_lea_code FROM areas ar WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

--INSTALL SLT-END-NTU tasks work group 

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes,ar.area_code INTO v_rtom_code,v_lea_code FROM areas ar WHERE ar.area_code = 

v_service_order_area AND ar.area_aret_code = 'LEA';


SELECT wg.worg_name INTO v_work_group FROM work_groups wg 
WHERE worg_name = v_rtom_code || '-' || v_lea_code ||'-OSP-NC';

/*SELECT wg.worg_name INTO v_work_group_cpe 
FROM work_groups wg WHERE worg_name = v_rtom_code || '-CPE-NC';*/

SELECT wg.worg_name INTO v_work_group_nw  FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code ||'-ENG-NW';


SELECT soa.seoa_defaultvalue INTO v_acc_medium 
FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name ='ACCESS MEDIUM';

SELECT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_ntu_class_cur,v_ntu_class_pre 
FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

SELECT soa.seoa_defaultvalue,soa.SEOA_PREV_VALUE
INTO v_ntu_model_cur, v_ntu_model_pre
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL';

SELECT soa.seoa_defaultvalue INTO v_acc_nw_intf FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';


SELECT soa.seoa_defaultvalue,SOA.SEOA_PREV_VALUE  INTO v_cpe_class_cur,v_cpe_class_pre FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';  
 
SELECT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_cpe_mod_cur,v_cpe_mod_pre 
FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';  


SELECT soa.seoa_defaultvalue,soa.seoa_prev_value
INTO v_Cur_Vlan_Tag,v_Pre_Vlan_Tag
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAGGED/UNTAGGED ?';



-- Modification Start Jayan Liyanage 20/10/2015 

IF  v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT' 
  AND v_ntu_class_cur = 'SLT' AND NVL(v_ntu_model_cur,0) <> NVL(v_ntu_model_pre,0) 
  and v_acc_medium = 'COPPER'
THEN UPDATE service_implementation_tasks sit 
  SET sit.seit_worg_name = v_work_group
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MODIFY NTU';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id AND
 sit.seit_taskname = 'MODIFY NTU'; END IF;


IF     v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT' 
  AND v_ntu_class_cur = 'SLT' AND NVL(v_ntu_model_cur,0) <> NVL(v_ntu_model_pre,0) 
  and v_acc_medium = 'FIBER'
THEN UPDATE service_implementation_tasks sit 
  SET sit.seit_worg_name = v_work_group_nw
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MODIFY NTU FO';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id AND
 sit.seit_taskname = 'MODIFY NTU FO'; END IF;



IF     v_service_type = 'D-BIL' 
  AND v_service_order = 'MODIFY-EQUIPMENT'
   AND v_ntu_class_cur = 'SLT'
AND NVL(v_ntu_model_cur,0) = NVL(v_ntu_model_pre,0)
 and v_acc_medium = 'COPPER'
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG NTU';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG NTU'; END IF;


IF     v_service_type = 'D-BIL' 
  AND v_service_order = 'MODIFY-EQUIPMENT' AND v_ntu_class_cur = 'SLT'
AND NVL(v_ntu_model_cur,0) = NVL(v_ntu_model_pre,0) 
and v_acc_medium = 'FIBER'
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG NTU FO';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'RECONFIG NTU FO'; END IF;
 
IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND  v_acc_nw_intf = 'MEN PORT' and NVL(v_Cur_Vlan_Tag,0) <> NVL(v_Pre_Vlan_Tag,0) 
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG MEN PORT';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'RECONFIG MEN PORT'; END IF;
   
IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND  v_acc_nw_intf = 'CEN PORT' and NVL(v_Cur_Vlan_Tag,0) <> NVL(v_Pre_Vlan_Tag,0) 
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG CEN PORT';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'RECONFIG CEN PORT'; END IF;
 
 IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND  ( v_acc_nw_intf = 'MSAN PORT' OR v_acc_nw_intf = 'DSLAM PORT') and NVL(v_Cur_Vlan_Tag,0) <> NVL(v_Pre_Vlan_Tag,0) 
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG SHDSL PORT';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'RECONFIG SHDSL PORT'; END IF;
  
 IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND  ( v_cpe_class_cur = 'SLT' and  v_cpe_class_pre = 'SLT') and NVL(v_cpe_mod_cur,0) <> NVL(v_cpe_mod_pre,0)   
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-OPERATIONS'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MODIFY CPE';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'MODIFY CPE'; END IF;
 
  IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND v_cpe_class_cur = 'SLT' and NVL(v_cpe_mod_cur,0) = NVL(v_cpe_mod_pre,0)   
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'RECONFIG CPE';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'RECONFIG CPE'; END IF;
 
   IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND ( v_cpe_class_cur = 'SLT' and  v_cpe_class_pre <> 'SLT')   
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-OPERATIONS'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'INSTALL CPE';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'INSTALL CPE'; END IF;
 
   IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND ( v_cpe_class_cur <> 'SLT' and  v_cpe_class_pre = 'SLT')    
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'DS-OPERATIONS'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'COLLECT CPE';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'COLLECT CPE'; END IF;



   IF v_service_type = 'D-BIL' AND v_service_order = 'MODIFY-EQUIPMENT'
   AND (( v_cpe_class_cur <>  v_cpe_class_pre )  OR (v_cpe_mod_cur <> v_cpe_mod_pre ))  
THEN UPDATE service_implementation_tasks sit
   SET sit.seit_worg_name = 'INT-NW-SYSADMIN'
WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MODIFY INTERNET PORT';
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
 AND sit.seit_taskname = 'MODIFY INTERNET PORT'; END IF;

-- End 20/10/2015


p_implementation_tasks.update_task_status_byid (p_sero_id,
                                     0,
                                     p_seit_id,
                                     'COMPLETED'
                                    );
EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change D-BIL Modified Process function. Please check the conditions:'
|| ' - Erro is:'
|| TO_CHAR (SQLCODE)
|| '-'
|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,
                                        0,
                                        p_seit_id,
                                        'ERROR'
                                       );

INSERT INTO service_task_comments (setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text
    )
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
     p_ret_msg
    );
END D_BIL_MODIFY_EQUIP_WF1;

---- Dulip Fernando 2013-02-26 / Modified 20/10/2015

--- Jayan Liyanage 2013/04/02

PROCEDURE D_SIP_CREA_UPGRADE (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_service_type         VARCHAR2 (100);
   v_service_order        VARCHAR2 (100);
   v_section_hndle        VARCHAR2 (100);
   v_trs_nw1              VARCHAR2 (100);
   v_trs_nw2              VARCHAR2 (100);
   v_trs_nw3              VARCHAR2 (100);
   v_acc_me               VARCHAR2 (100);
   v_Ser_ctg              VARCHAR2 (100);
   v_rtom_code            VARCHAR2 (100);
   v_lea_code             VARCHAR2 (100);
   v_service_order_area   VARCHAR2 (100);
   v_work_group_cpe       VARCHAR2 (100);
   v_work_group_eng       VARCHAR2 (100);
   v_work_group_osp       VARCHAR2 (100);
   v_nte                  VARCHAR2 (100);
   v_work_mdf             VARCHAR2 (100);
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_section_hndle
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY';

   SELECT soa.seoa_defaultvalue
     INTO v_trs_nw1
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'TRANSPORT NETWORK1';

   SELECT soa.seoa_defaultvalue
     INTO v_trs_nw2
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'TRANSPORT NETWORK2';

   SELECT soa.seoa_defaultvalue
     INTO v_trs_nw3
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'TRANSPORT NETWORK3';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_me
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

   SELECT soa.seoa_defaultvalue
     INTO v_Ser_ctg
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';

   SELECT soa.seoa_defaultvalue
     INTO v_nte
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTE TYPE';

   SELECT DISTINCT so.sero_area_code
     INTO v_service_order_area
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes,
          ar.area_code
     INTO v_rtom_code, v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_eng
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'ENG-NW' || '%';

   SELECT wg.worg_name
     INTO v_work_group_osp
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   /*
   SELECT wg.worg_name INTO v_work_group_osp FROM work_groups wg
   WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'OSP-NC' || '%';*/
   SELECT wg.worg_name
     INTO v_work_mdf
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'MDF' || '%';

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'TDM TX'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE TX PORTS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE TX PORTS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'DSL'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-ADSL'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE BB FASCILITY';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE BB FASCILITY';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'MLLN'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE MLLN FACILIT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE MLLN FACILIT';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND (v_trs_nw1 = 'MEN' OR v_trs_nw2 = 'MEN' OR v_trs_nw3 = 'MEN')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE MEN FACILITY';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE MEN FACILITY';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND (v_trs_nw1 = 'CEN' OR v_trs_nw2 = 'CEN' OR v_trs_nw3 = 'CEN')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE CEA FACILITY';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE CEA FACILITY';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'MLLN'
      AND v_acc_me = 'COPPER'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_osp
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL OSP/NTE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL OSP/NTE';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'MEN'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT MEN ACCESS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT MEN ACCESS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'MLLN'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_mdf
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DO MDF X CONNECTIONS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DO MDF X CONNECTIONS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'CEA'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT CEA ACCESS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT CEA ACCESS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'MLLN'
      AND v_acc_me = 'FIBER'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_eng
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INTEGRATE AGG NW';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INTEGRATE AGG NW';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'DSL'
      AND v_acc_me = 'COPPER'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_osp
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT DSL ACCESS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONSTRUCT DSL ACCESS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND (v_trs_nw1 = 'MEN' OR v_trs_nw2 = 'MEN' OR v_trs_nw3 = 'MEN')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV. ETHERNET LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV. ETHERNET LINK';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'DSL'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CEN-ADSL'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV.BROADBAND LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV.BROADBAND LINK';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'TDMTX'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE TX PORTS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE TX PORTS';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND (v_trs_nw1 = 'CEA' OR v_trs_nw2 = 'CEA' OR v_trs_nw3 = 'CEA')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV. ETHERNET CEA';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIV. ETHERNET CEA';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'DSL'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_cpe
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL DSL NTE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL DSL NTE';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_trs_nw1 = 'DSL'
      AND v_nte <> 'N/A'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_cpe
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL NTE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL NTE';
   END IF;

   IF     v_service_type = 'D-SIP TRUNK'
      AND v_service_order = 'CREATE-UPGRADE'
      AND v_Ser_ctg = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-ACCM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST LINK';
   END IF;


   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D-Sip Trunk Create Upgrade Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_SIP_CREA_UPGRADE;
--- Jayan Liyanage 2013/04/02

--- Jayan Liyanage 2013/04/02

PROCEDURE D_SIP_CREA_UPGRDE_X_CONNE (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_equip_type              VARCHAR2 (100);
   v_eq_loc_name             VARCHAR2 (100);
   v_service_type            VARCHAR2 (100);
   v_service_order           VARCHAR2 (100);
   v_service_order_area      VARCHAR2 (100);
   v_rtom_code               VARCHAR2 (100);
   v_lea_code                VARCHAR2 (100);
   v_work_group              VARCHAR2 (100);
   v_work_group_mdf          VARCHAR2 (100);
   v_location                VARCHAR2 (100);
   v_main_node               VARCHAR2 (100);
   v_sub_node                VARCHAR2 (100);
   v_acc_nw                  VARCHAR2 (100);
   v_acc_bearer_status       VARCHAR2 (100);
   v_mig_type                VARCHAR2 (100);
   v_access_bear_id          VARCHAR2 (100);
   v_ch_dis                  VARCHAR2 (100);
   v_cir_trib_status         VARCHAR2 (100);
   v_cur_nof_copper          VARCHAR2 (100);
   v_pre_nof_copper          VARCHAR2 (100);
   v_access_node_chg         VARCHAR2 (100);
   v_no_of_copper_pair_cur   VARCHAR2 (100);
   v_no_of_copper_pair_pre   VARCHAR2 (100);
   v_new_cir_id              VARCHAR2 (100);
   v_new_Cir_Name            VARCHAR2 (100);
   v_acc_nw_pre              VARCHAR2 (100);
   v_trs_nw1                 VARCHAR2 (100);

   CURSOR cur_equi_type
   IS
      SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname
        FROM service_orders so, ports p, equipment e
       WHERE     so.sero_cirt_name = p.port_cirt_name
             AND (   e.equp_equt_abbreviation LIKE 'MSAN%'
                  OR e.equp_equt_abbreviation LIKE 'DSLAM%'
                  OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'
                  OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%')
             AND p.port_equp_id = e.equp_id
             AND so.sero_id = p_sero_id;

BEGIN
   OPEN cur_equi_type;

   FETCH cur_equi_type
      INTO v_equip_type, v_eq_loc_name;

   CLOSE cur_equi_type;

   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_area_code
     INTO v_service_order_area
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT c.cirt_displayname
     INTO v_new_Cir_Name
     FROM service_orders so, circuits c
    WHERE so.sero_cirt_name = c.cirt_name AND so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_trs_nw1
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'TRANSPORT NETWORK1';

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes,
          ar.area_code
     INTO v_rtom_code, v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_mdf
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'MDF' || '%';

   SELECT SUBSTR (v_eq_loc_name, 1, INSTR (v_eq_loc_name, '-NODE', '1') - 1)
             AS node
     INTO v_location
     FROM DUAL;

   SELECT TRIM (SUBSTR (v_location,
                        1,
                          INSTR (v_location,
                                 '-',
                                 '1',
                                 1)
                        - 1))
             AS main_node,
          TRIM (SUBSTR (v_location, INSTR (v_location, '-') + 1)) AS sub_node
     INTO v_main_node, v_sub_node
     FROM DUAL;

   /*OPEN cur_tributer (v_access_bear_id,v_new_Cir_Name);FETCH cur_tributer INTO v_ch_dis, v_cir_trib_status;CLOSE cur_tributer;*/

   IF v_main_node IS NOT NULL
   THEN
      IF     v_service_type = 'D-SIP TRUNK'
         AND v_service_order = 'CREATE-UPGRADE'
         AND v_trs_nw1 = 'DSL'
         AND v_main_node <> v_sub_node
         AND (v_equip_type LIKE 'MSAN%' OR v_equip_type LIKE 'DSLAM%')
      THEN
         UPDATE service_implementation_tasks sit
            SET sit.seit_worg_name = v_work_group
          WHERE     sit.seit_sero_id = p_sero_id
                AND sit.seit_taskname = 'MAKE X CONNECTIONS';
      ELSIF     v_service_type = 'D-SIP TRUNK'
            AND v_service_order = 'CREATE-UPGRADE'
            AND v_main_node = v_sub_node
            AND v_trs_nw1 = 'DSL'
            AND (v_equip_type LIKE 'MSAN%' OR v_equip_type LIKE 'DSLAM%')
      THEN
         UPDATE service_implementation_tasks sit
            SET sit.seit_worg_name = v_work_group_mdf
          WHERE     sit.seit_sero_id = p_sero_id
                AND sit.seit_taskname = 'MAKE X CONNECTIONS';
      ELSIF     v_service_type = 'D-SIP TRUNK'
            AND v_service_order = 'CREATE-UPGRADE'
      THEN
         DELETE service_implementation_tasks sit
          WHERE     sit.seit_sero_id = p_sero_id
                AND sit.seit_taskname = 'MAKE X CONNECTIONS';
      END IF;
   END IF;

   IF v_main_node IS NULL
   THEN
      IF     v_service_type = 'D-SIP TRUNK'
         AND v_service_order = 'CREATE-UPGRADE'
         AND (v_equip_type LIKE 'MSAN%' OR v_equip_type LIKE 'DSLAM%')
         AND v_trs_nw1 = 'DSL'
      THEN
         UPDATE service_implementation_tasks sit
            SET sit.seit_worg_name = v_work_group_mdf
          WHERE     sit.seit_sero_id = p_sero_id
                AND sit.seit_taskname = 'MAKE X CONNECTIONS';
      ELSIF     v_service_type = 'D-SIP TRUNK'
            AND v_service_order = 'CREATE-UPGRADE'
      THEN
         DELETE service_implementation_tasks sit
          WHERE     sit.seit_sero_id = p_sero_id
                AND sit.seit_taskname = 'MAKE X CONNECTIONS';
      END IF;
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to WG Mapping Please check the X Connection   :  - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_SIP_CREA_UPGRDE_X_CONNE;

--- Jayan Liyanage 2013/04/02

-- 22-03-2013 Samankula Owitipana

PROCEDURE SMART_DIAL_ACC_GP_ID (
   p_serv_id         IN     Services.serv_id%TYPE,
   p_sero_id         IN     Service_Orders.sero_id%TYPE,
   p_seit_id         IN     Service_Implementation_Tasks.seit_id%TYPE,
   p_impt_taskname   IN     Implementation_Tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_order_type    VARCHAR2 (100);
   v_acc_no        VARCHAR2 (100);
   v_acc_gp_id     VARCHAR2 (20);
   v_acc_port_bw   VARCHAR2 (50);

   CURSOR c_so_order_type
   IS
      SELECT so.SERO_ORDT_TYPE
        FROM service_orders so
       WHERE so.SERO_ID = p_sero_id;

   CURSOR c_so_acc_no
   IS
      SELECT so.SERO_ACCT_NUMBER
        FROM service_orders so
       WHERE so.SERO_ID = p_sero_id;

BEGIN
   OPEN c_so_order_type;

   FETCH c_so_order_type INTO v_order_type;

   CLOSE c_so_order_type;

   OPEN c_so_acc_no;

   FETCH c_so_acc_no INTO v_acc_no;

   CLOSE c_so_acc_no;

   /*SELECT soa.seoa_defaultvalue
   INTO v_acc_port_bw
   FROM service_order_attributes soa
   WHERE soa.seoa_sero_id = p_sero_id
   AND soa.seoa_name = 'ACCESS INTF PORT BW';*/

   SELECT 'SD-' || LPAD (clarity.SMART_DIAL_ACCGP_SEQ.NEXTVAL, 11, '0')
     INTO v_acc_gp_id
     FROM DUAL;

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_acc_gp_id
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'CDMA PBX GROUP ID';

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');
      p_ret_msg :=
            'Failed to set CDMA PBX GROUP ID attribute. - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS (SETC_SEIT_ID,
                                         SETC_ID,
                                         SETC_USERID,
                                         SETC_TIMESTAMP,
                                         SETC_TEXT)
           VALUES (p_seit_id,
                   SETC_ID_SEQ.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END SMART_DIAL_ACC_GP_ID;

--- 23-03-2013 Samankula Owitipana

--- Samankula Owitipana 2013/05/16 
--- Task Condition function

PROCEDURE SISU_CON_TASK_CON_FUNCTION(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
v_new_val VARCHAR2(10);
v_pre_val VARCHAR2(10);
BEGIN    
select sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
into  v_new_val,v_pre_val
from SERVICE_ORDER_FEATURES sof
where sof.SOFE_SERO_ID = p_sero_id
and sof.SOFE_FEATURE_NAME = 'SF_SISU CONNECT';
IF v_new_val = 'U' and v_pre_val = 'Y' THEN
p_ret_msg := '';
ELSE
p_ret_msg := 'FALSE';
END IF;         
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';   
WHEN OTHERS THEN
   p_ret_msg := ''; 
END SISU_CON_TASK_CON_FUNCTION;

--- Samankula Owitipana 2013/05/16

--- 25-06-2013 Samankula Owitipana -------------
PROCEDURE  SISUCON_FEATURE_ATTRIB_BLANK(
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

begin
 
UPDATE service_order_attributes soa
SET soa.SEOA_DEFAULTVALUE = NULL 
where soa.seoa_sero_id = p_sero_id 
AND  soa.SEOA_SOFE_ID in
(SELECT a.SOFE_ID
FROM SERVICE_ORDER_FEATURES  A WHERE A.SOFE_SERO_ID = p_sero_id
AND A.SOFE_FEATURE_NAME = 'SF_SISU CONNECT' 
and a.SOFE_PREV_VALUE = 'Y' and a.SOFE_DEFAULTVALUE = 'N' );

p_implementation_tasks.update_task_status_byid (p_sero_id,
0,p_seit_id,'COMPLETED');
EXCEPTION
WHEN OTHERS
THEN
p_ret_msg :=
'Failed to Copy Bearer Att Process function. Please check the conditions:'
|| ' - Erro is:'
|| TO_CHAR (SQLCODE)
|| '-'
|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,
0,p_seit_id,
'ERROR');
INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,
setc_text)
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
p_ret_msg);

END SISUCON_FEATURE_ATTRIB_BLANK;

-- 25-06-2013 Samankula Owitipana -------------

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
l_rcpt:= 'mangala_b@slt.com.lk';
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

--Indika de Silva 30/06/2013

PROCEDURE D_BIL_M_LOC_PRE_X_CONNE_1 (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   CURSOR pre_cir (v_old_ids VARCHAR)
   IS
      SELECT DISTINCT c.cirt_status
        FROM circuits c
       WHERE c.cirt_displayname = v_old_ids;

   CURSOR cur_tributer (
      parent_name     VARCHAR2,
      v_new_cir_id    VARCHAR2)
   IS
      SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
        FROM circuits c, circuit_hierarchy ch, circuits ci
       WHERE     c.cirt_name = ch.cirh_parent
             AND ch.cirh_child = ci.cirt_name
             AND (   ci.cirt_status LIKE 'INSERVICE%'
                  OR ci.cirt_status LIKE 'PROPOSED%'
                  OR ci.cirt_status LIKE 'SUSPEND%'
                  OR ci.cirt_status LIKE 'COMMISS%')
             AND (   ci.cirt_status NOT LIKE 'CANCE%'
                  OR ci.cirt_status NOT LIKE 'PENDING%')
             AND ci.cirt_displayname NOT LIKE
                    REPLACE (v_new_cir_id, '(N)') || '%'
             AND c.cirt_displayname LIKE REPLACE (parent_name, '(N)') || '%';

   CURSOR cur_old_tributer (
      old_parent_name    VARCHAR2,
      v_new_cir_id       VARCHAR2)
   IS
      SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
        FROM circuits c, circuit_hierarchy ch, circuits ci
       WHERE     c.cirt_name = ch.cirh_parent
             AND ch.cirh_child = ci.cirt_name
             AND (   ci.cirt_status LIKE 'INSERVICE%'
                  OR ci.cirt_status LIKE 'PROPOSED%'
                  OR ci.cirt_status LIKE 'SUSPEND%'
                  OR ci.cirt_status LIKE 'COMMISS%')
             AND (   ci.cirt_status NOT LIKE 'CANCE%'
                  OR ci.cirt_status NOT LIKE 'PENDING%')
             AND ci.cirt_displayname NOT LIKE
                    REPLACE (v_new_cir_id, '(N)') || '%'
             AND c.cirt_displayname LIKE
                    REPLACE (old_parent_name, '(N)') || '%';

   v_cir_status              VARCHAR2 (100);
   v_new_bearer_id           VARCHAR2 (100);
   v_section_hndle           VARCHAR2 (100);
   v_service_type            VARCHAR2 (100);
   v_service_order           VARCHAR2 (100);
   v_service_order_area      VARCHAR2 (100);
   v_rtom_code               VARCHAR2 (100);
   v_lea_code                VARCHAR2 (100);
   v_acc_bear_status         VARCHAR2 (100);
   v_core_network            VARCHAR2 (100);
   v_acc_medium_cur          VARCHAR2 (100);
   v_acc_medium_pre          VARCHAR2 (100);
   v_work_group              VARCHAR2 (100);
   v_acc_nw                  VARCHAR2 (100);
   v_ntu_class_cur           VARCHAR2 (100);
   v_ntu_class_pre           VARCHAR2 (100);
   v_work_group_cpe          VARCHAR2 (100);
   v_ser_ctg                 VARCHAR2 (100);
   v_so_attr_name            VARCHAR2 (100);
   v_so_attr_val             VARCHAR2 (100);
   v_bearer_id               VARCHAR2 (100);
   v_no_of_copper_pair_cur   VARCHAR2 (100);
   v_no_of_copper_pair_pre   VARCHAR2 (100);
   v_cpe_class_cur           VARCHAR2 (100);
   v_cpe_class_pre           VARCHAR2 (100);
   v_acc_port_bw_cur         VARCHAR2 (100);
   v_acc_port_bw_pre         VARCHAR2 (100);
   v_acc_node_change         VARCHAR2 (100);
   v_old_cir_id              VARCHAR2 (100);
   v_old_ids                 VARCHAR2 (100);
   v_old_staus               VARCHAR2 (100);
   parent_name               VARCHAR2 (100);
   v_new_cir_id              VARCHAR2 (100);
   v_access_bear_id          VARCHAR2 (100);
   v_new_cir_name            VARCHAR2 (100);
   v_pre_access_bear_id      VARCHAR2 (100);
   old_parent_name           VARCHAR2 (100);
   v_old_ch_dis              VARCHAR2 (100);
   v_old_cir_trib_status     VARCHAR2 (100);
   v_ch_dis                  VARCHAR2 (100);
   v_cir_trib_status         VARCHAR2 (100);
   v_pre_acc_nw              VARCHAR2 (100);
   v_work_group_nw           VARCHAR2 (100);
   v_cur_media               VARCHAR2 (100);
   v_pre_media               VARCHAR2 (100);
   v_pre_core_nw             VARCHAR2 (100);
   v_cpe_mode_cur            VARCHAR2 (100);
   v_cpe_mode_pre            VARCHAR2 (100);
   v_aggr_nw                 VARCHAR2 (100);
   v_aggr_nw_pre             VARCHAR2 (100);
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_section_hndle
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_status
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS BEARER STATUS';

   SELECT DISTINCT so.sero_area_code
     INTO v_service_order_area
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes,
          ar.area_code
     INTO v_rtom_code, v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_nw
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'ENG-NW' || '%';

   SELECT wg.worg_name
     INTO v_work_group_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_medium_cur, v_acc_medium_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_ntu_class_cur, v_ntu_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_nw, v_pre_acc_nw
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

   SELECT soa.seoa_defaultvalue
     INTO v_ser_ctg
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_no_of_copper_pair_cur, v_no_of_copper_pair_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'NO OF COPPER PAIRS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_class_cur, v_cpe_class_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_mode_cur, v_cpe_mode_pre
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_port_bw_cur, v_acc_port_bw_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS INTF PORT BW';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_node_change
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'ACCESS NODE CHANGE?';

   SELECT soa.seoa_defaultvalue
     INTO v_old_cir_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'OLD CIRCUIT ID';


   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_access_bear_id, v_pre_access_bear_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID';


   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_aggr_nw, v_aggr_nw_pre
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'AGGREGATE NETWORK';


   SELECT DISTINCT c.cirt_displayname
     INTO v_new_cir_name
     FROM service_orders so, circuits c
    WHERE so.sero_cirt_name = c.cirt_name AND so.sero_id = p_sero_id;

   OPEN cur_tributer (v_access_bear_id, v_new_cir_name);

   FETCH cur_tributer
      INTO v_ch_dis, v_cir_trib_status;

   CLOSE cur_tributer;

   OPEN cur_old_tributer (v_pre_access_bear_id, v_new_cir_name);

   FETCH cur_old_tributer
      INTO v_old_ch_dis, v_old_cir_trib_status;

   CLOSE cur_old_tributer;

   ---DEACT. OLD MEN PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
      AND v_pre_acc_nw = 'MEN PORT'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD MEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD MEN PORT';
   END IF;

   ---DEACT. OLD CEN PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
      AND v_pre_acc_nw = 'CEN PORT'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD CEN PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD CEN PORT';
   END IF;

   ---DEACT. OLD MPLS PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_node_change = 'YES'
      AND v_pre_acc_nw = 'MPLS PORT'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD MPLS PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT. OLD MPLS PORT';
   END IF;

   ---DEL OLD MEN SUB PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_pre_acc_nw = 'MEN PORT'
      AND v_old_ch_dis IS NOT NULL
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD MEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD MEN SUB PORT';
   END IF;

   ---DEL OLD CEN SUB PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_pre_acc_nw = 'CEN PORT'
      AND v_old_ch_dis IS NOT NULL
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD CEN SUB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD CEN SUB PORT';
   END IF;

   ---DEL OLD MPLS SUB PRT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_pre_acc_nw = 'MPLS PORT'
      AND v_old_ch_dis IS NOT NULL
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD MPLS SUB PRT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEL OLD MPLS SUB PRT';
   END IF;

   ---COLLECT OLD NTU
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_pre_acc_nw = 'MSAN PORT' OR v_pre_acc_nw = 'DSLAM PORT')
      AND v_ntu_class_pre = 'SLT'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD NTU';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD NTU';
   END IF;

   ---COLLECT OLD CPE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_cpe_class_pre = 'SLT'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD CPE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'COLLECT OLD CPE';
   END IF;

   ---REMOVE OLD OSP LINE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_pre = 'COPPER'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE OLD OSP LINE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REMOVE OLD OSP LINE';
   END IF;

   ---UNINS. OLD FIBER LIN
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_acc_medium_pre = 'FIBER'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CORP-SSU'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'UNINS. OLD FIBER LIN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'UNINS. OLD FIBER LIN';
   END IF;

   ---DEACT OLD SHDSL PORT
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_pre_acc_nw = 'MSAN PORT' OR v_pre_acc_nw = 'DSLAM PORT')
      AND v_old_ch_dis IS NULL
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD SHDSL PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD SHDSL PORT';
   END IF;

   ---DEACT OLD TRIB PORT
   IF     v_service_type = 'D-BIL'             --- task name shoud change Prod
      AND v_service_order = 'MODIFY-LOCATION'
      AND (v_pre_acc_nw = 'MSAN PORT' OR v_pre_acc_nw = 'DSLAM PORT')
      AND v_old_ch_dis IS NOT NULL
      AND v_acc_node_change = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD TRIB PORT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT OLD TRIB PORT';
   END IF;

   ---DEAC. OLD ACC BEARER
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'MODIFY-LOCATION'
      AND v_old_ch_dis IS NULL
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-FO'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEAC. OLD ACC BEARER';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEAC. OLD ACC BEARER';
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D_BIL_M_LOC_PRE_X_CONNE_1 Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_BIL_M_LOC_PRE_X_CONNE_1;

--Indika de Silva 30/06/2013

--Indika de Silva 30/06/2013

PROCEDURE D_BIL_M_LOC_PRE_X_CONNE_2 (
p_serv_id       IN services.serv_id%TYPE, 
p_sero_id       IN service_orders.sero_id%TYPE, 
p_seit_id       IN service_implementation_tasks.seit_id%TYPE, 
p_impt_taskname IN implementation_tasks.impt_taskname%TYPE, 
p_woro_id       IN work_order.woro_id%TYPE, 
p_ret_char      OUT VARCHAR2, 
p_ret_number    OUT NUMBER, 
p_ret_msg       OUT VARCHAR2) 
IS 
  v_equip_type            VARCHAR2 (100); 
  v_eq_loc_name           VARCHAR2 (100); 
  v_service_type          VARCHAR2 (100); 
  v_service_order         VARCHAR2 (100); 
  v_service_order_area    VARCHAR2 (100); 
  v_rtom_code             VARCHAR2 (100); 
  v_lea_code              VARCHAR2 (100); 
  v_work_group            VARCHAR2 (100); 
  v_work_group_mdf        VARCHAR2 (100); 
  v_location              VARCHAR2 (100); 
  v_main_node             VARCHAR2 (100); 
  v_sub_node              VARCHAR2 (100); 
  v_acc_nw                VARCHAR2 (100); 
  v_acc_bearer_status     VARCHAR2 (100); 
  v_mig_type              VARCHAR2 (100); 
  v_access_bear_id        VARCHAR2 (100); 
  v_ch_dis                VARCHAR2 (100); 
  v_access_id             VARCHAR2 (100); 
  v_cir_trib_status       VARCHAR2 (100); 
  v_cur_nof_copper        VARCHAR2 (100); 
  v_pre_nof_copper        VARCHAR2 (100); 
  v_access_node_chg       VARCHAR2 (100); 
  v_no_of_copper_pair_cur VARCHAR2 (100); 
  v_no_of_copper_pair_pre VARCHAR2 (100); 
  v_new_cir_id            VARCHAR2 (100); 
  v_new_cir_name          VARCHAR2 (100); 
  v_acc_medium            VARCHAR2 (100); 
  v_acc_medium_pre        VARCHAR2 (100); 
  v_ch_dis_p              VARCHAR2 (100); 
  v_cir_trib_status_p     VARCHAR2 (100); 
  v_pre_eq                VARCHAR2 (100); 
  v_pre_location          VARCHAR2 (100); 
  v_location_pre          VARCHAR2 (100); 
  v_pre_main_node         VARCHAR2 (100); 
  v_pre_sub_node          VARCHAR2 (100);
  v_access_id_c           VARCHAR2 (100);
  
  CURSOR cur_equi_type IS 
    SELECT DISTINCT e.equp_equt_abbreviation, 
                    e.equp_locn_ttname 
    FROM   service_orders so, 
           ports p, 
           equipment e 
    WHERE  so.sero_cirt_name = p.port_cirt_name 
           AND ( e.equp_equt_abbreviation LIKE '%MSAN%' 
                  OR e.equp_equt_abbreviation LIKE '%DSLAM%' 
                  OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%' 
                  OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%' ) 
           AND p.port_equp_id = e.equp_id 
           AND so.sero_id = p_sero_id;
            
  CURSOR cur_tributer ( 
    parent_name  VARCHAR2, 
    v_new_cir_id VARCHAR2) IS 
    SELECT DISTINCT ci.cirt_displayname, 
                    ci.cirt_status 
    FROM   circuits c, 
           circuit_hierarchy ch, 
           circuits ci 
    WHERE  c.cirt_name = ch.cirh_parent 
           AND ch.cirh_child = ci.cirt_name 
           AND ( ci.cirt_status LIKE 'INSERVICE%' 
                  OR ci.cirt_status LIKE 'PROPOSED%' 
                  OR ci.cirt_status LIKE 'SUSPEND%' 
                  OR ci.cirt_status LIKE 'COMMISS%' ) 
           AND ( ci.cirt_status NOT LIKE 'CANCE%' 
                  OR ci.cirt_status NOT LIKE 'PENDING%' ) 
           AND ci.cirt_displayname NOT LIKE REPLACE (v_new_cir_id,'(N)')||'%' 
           AND c.cirt_displayname like replace(parent_name,'(N)')||'%';
            
  CURSOR cur_tributer_p ( 
    parent_pre_name  VARCHAR2, 
    v_parent_cir_old VARCHAR2) IS 
    SELECT DISTINCT ci.cirt_displayname, 
                    ci.cirt_status 
    FROM   circuits c, 
           circuit_hierarchy ch, 
           circuits ci 
    WHERE  c.cirt_name = ch.cirh_parent 
           AND ch.cirh_child = ci.cirt_name 
           AND ( ci.cirt_status LIKE 'INSERVICE%' 
                  OR ci.cirt_status LIKE 'PROPOSED%' 
                  OR ci.cirt_status LIKE 'SUSPEND%' 
                  OR ci.cirt_status LIKE 'COMMISS%' ) 
           AND ( ci.cirt_status NOT LIKE 'CANCE%' 
                  OR ci.cirt_status NOT LIKE 'PENDING%' ) 
           AND ci.cirt_displayname NOT LIKE REPLACE (v_parent_cir_old,'(N)')||'%' 
           AND c.cirt_displayname like replace(parent_pre_name,'(N)')||'%';
            
  CURSOR cur_eq_pre ( 
    parent_c VARCHAR2) IS 
    SELECT DISTINCT e.equp_equt_abbreviation, 
                    e.equp_locn_ttname 
    FROM   ports p, 
           equipment e, 
           circuits ci 
    WHERE  ci.cirt_name = p.port_cirt_name 
           AND ( e.equp_equt_abbreviation LIKE '%MSAN%' 
                  OR e.equp_equt_abbreviation LIKE '%DSLAM%' 
                  OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%' 
                  OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%' ) 
           AND p.port_equp_id = e.equp_id 
           AND ci.cirt_displayname = parent_c; 
BEGIN 
    OPEN cur_equi_type; 

    FETCH cur_equi_type INTO v_equip_type, v_eq_loc_name; 

    CLOSE cur_equi_type; 

    SELECT DISTINCT so.sero_sert_abbreviation 
    INTO   v_service_type 
    FROM   service_orders so 
    WHERE  so.sero_id = p_sero_id; 

    SELECT DISTINCT so.sero_ordt_type 
    INTO   v_service_order 
    FROM   service_orders so 
    WHERE  so.sero_id = p_sero_id; 

    SELECT DISTINCT so.sero_area_code 
    INTO   v_service_order_area 
    FROM   service_orders so 
    WHERE  so.sero_id = p_sero_id; 

    SELECT soa.seoa_defaultvalue 
    INTO   v_acc_nw 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS N/W INTF'; 

    SELECT soa.seoa_defaultvalue 
    INTO   v_mig_type 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'MIGRATION TYPE'; 

    SELECT soa.seoa_defaultvalue 
    INTO   v_acc_bearer_status 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS BEARER STATUS'; 

    SELECT soa.seoa_defaultvalue, 
           soa.seoa_prev_value 
    INTO   v_cur_nof_copper, v_pre_nof_copper 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'NO OF COPPER PAIRS'; 

    SELECT soa.seoa_defaultvalue 
    INTO   v_access_bear_id 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS BEARER ID'; 

    SELECT soa.seoa_defaultvalue,soa.seoa_prev_value 
    INTO   v_access_id_c,v_access_id 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS_ID'; 

    SELECT DISTINCT c.cirt_displayname 
    INTO   v_new_cir_name 
    FROM   service_orders so, 
           circuits c 
    WHERE  so.sero_cirt_name = c.cirt_name 
           AND so.sero_id = p_sero_id; 

    SELECT soa.seoa_defaultvalue 
    INTO   v_access_node_chg 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS NODE CHANGE?'; 

    SELECT soa.seoa_defaultvalue, 
           soa.seoa_prev_value 
    INTO   v_acc_medium, v_acc_medium_pre 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'ACCESS MEDIUM'; 

    SELECT soa.seoa_defaultvalue, 
           soa.seoa_prev_value 
    INTO   v_no_of_copper_pair_cur, v_no_of_copper_pair_pre 
    FROM   service_order_attributes soa 
    WHERE  soa.seoa_sero_id = p_sero_id 
           AND soa.seoa_name = 'NO OF COPPER PAIRS'; 

    SELECT Substr (ar.area_area_code, 3, Instr (ar.area_area_code, '-', 1) + 1) 
           AS 
           codes, 
           ar.area_code 
    INTO   v_rtom_code, v_lea_code 
    FROM   areas ar 
    WHERE  ar.area_code = v_service_order_area 
           AND ar.area_aret_code = 'LEA'; 

    SELECT wg.worg_name 
    INTO   v_work_group 
    FROM   work_groups wg 
    WHERE  worg_name LIKE v_rtom_code 
                          || '-' 
                          || v_lea_code 
                          || '%' 
                          || 'OSP-NC' 
                          || '%'; 

    SELECT wg.worg_name 
    INTO   v_work_group_mdf 
    FROM   work_groups wg 
    WHERE  worg_name LIKE v_rtom_code 
                          || '-' 
                          || v_lea_code 
                          || '%' 
                          || 'MDF' 
                          || '%'; 

    SELECT Substr (v_eq_loc_name, 1, Instr (v_eq_loc_name, '-NODE', '1') - 1) AS 
           node 
    INTO   v_location 
    FROM   dual; 

    SELECT Trim (Substr (v_location, 1, Instr (v_location, '-', '1', 1) - 1)) AS 
           main_node, 
           Trim (Substr (v_location, Instr (v_location, '-') + 1))            AS 
           sub_node 
    INTO   v_main_node, v_sub_node 
    FROM   dual; 

    -- Pre Location Details Start 
    OPEN cur_tributer (v_access_bear_id, v_new_cir_name); 

    FETCH cur_tributer INTO v_ch_dis, v_cir_trib_status; 

    CLOSE cur_tributer; 

    OPEN cur_tributer_p (v_access_id, v_new_cir_name); 

    FETCH cur_tributer_p INTO v_ch_dis_p, v_cir_trib_status_p; 

    CLOSE cur_tributer_p; 

    OPEN cur_eq_pre (v_access_id_c); 

    FETCH cur_eq_pre INTO v_pre_eq, v_pre_location; 

    CLOSE cur_eq_pre; 

    SELECT Substr (v_pre_location, 1, Instr (v_pre_location, '-NODE', '1') - 1) 
           AS 
           node 
    INTO   v_location_pre 
    FROM   dual; 

    SELECT Trim (Substr (v_location_pre, 1, Instr (v_location_pre, '-', '1', 1) 
                                            - 1) 
           ) AS 
           main_node, 
           Trim (Substr (v_location_pre, Instr (v_location_pre, '-') + 1)) 
           AS sub_node 
    INTO   v_pre_main_node, v_pre_sub_node 
    FROM   dual;
    
    IF v_pre_main_node IS NOT NULL THEN 
      IF v_service_type = 'D-BIL' 
         AND v_service_order = 'MODIFY-LOCATION' 
         AND v_pre_main_node <> v_pre_sub_node 
         AND ( v_pre_eq LIKE '%MSAN%' 
                OR v_pre_eq LIKE '%DSLAM%' ) 
         AND ( v_acc_medium_pre = 'COPPER' ) 
         AND v_access_node_chg = 'YES' 
         AND v_ch_dis_p IS NULL THEN 
        UPDATE service_implementation_tasks sit 
        SET    sit.seit_worg_name = v_work_group 
        WHERE  sit.seit_sero_id = p_sero_id 
               AND sit.seit_taskname = 'REMOVE OLD X CONNEC.'; 
      ELSIF v_service_type = 'D-BIL' 
            AND v_service_order = 'MODIFY-LOCATION' 
            AND v_pre_main_node = v_pre_sub_node 
            AND ( v_pre_eq LIKE '%MSAN%' 
                   OR v_pre_eq LIKE '%DSLAM%' ) 
            AND ( v_acc_medium_pre = 'COPPER' ) 
            AND v_access_node_chg = 'YES' 
            AND v_ch_dis_p IS NULL THEN 
        UPDATE service_implementation_tasks sit 
        SET    sit.seit_worg_name = v_work_group_mdf 
        WHERE  sit.seit_sero_id = p_sero_id 
               AND sit.seit_taskname = 'REMOVE OLD X CONNEC.'; 
      ELSIF v_service_type = 'D-BIL' 
            AND v_service_order = 'MODIFY-LOCATION' THEN 
        DELETE service_implementation_tasks sit 
        WHERE  sit.seit_sero_id = p_sero_id 
               AND sit.seit_taskname = 'REMOVE OLD X CONNEC.'; 
      END IF; 
    END IF; 

    IF v_pre_main_node IS NULL THEN 
      IF v_service_type = 'D-BIL' 
         AND v_service_order = 'MODIFY-LOCATION' 
         AND ( v_pre_eq LIKE '%MSAN%' 
                OR v_pre_eq LIKE '%DSLAM%' ) 
         AND ( v_acc_medium_pre = 'COPPER' ) 
         AND v_access_node_chg = 'YES' 
         AND v_ch_dis_p IS NULL THEN 
        UPDATE service_implementation_tasks sit 
        SET    sit.seit_worg_name = v_work_group_mdf 
        WHERE  sit.seit_sero_id = p_sero_id 
               AND sit.seit_taskname = 'REMOVE OLD X CONNEC.'; 
      ELSIF v_service_type = 'D-BIL' 
            AND v_service_order = 'MODIFY-LOCATION' THEN 
        DELETE service_implementation_tasks sit 
        WHERE  sit.seit_sero_id = p_sero_id 
               AND sit.seit_taskname = 'REMOVE OLD X CONNEC.'; 
      END IF; 
    END IF;
    
    p_implementation_tasks.Update_task_status_byid (p_sero_id, 0, p_seit_id, 
    'COMPLETED'); 
EXCEPTION 
  WHEN OTHERS THEN 
             p_ret_msg := 'Failed to Workgroup Mapping Please check the Cross Connection Equip Type  :  - Erro  is:' 
                          || To_char (SQLCODE) 
                          || '-' 
                          || SQLERRM; 

             p_implementation_tasks.Update_task_status_byid (p_sero_id, 0, 
             p_seit_id, 
             'ERROR' 
             ); 

             INSERT INTO service_task_comments 
                         (setc_seit_id, 
                          setc_id, 
                          setc_userid, 
                          setc_timestamp, 
                          setc_text) 
             VALUES      (p_seit_id, 
                          setc_id_seq.NEXTVAL, 
                          'CLARITYB', 
                          SYSDATE, 
                          p_ret_msg); 
                          
 END D_BIL_M_LOC_PRE_X_CONNE_2;

--Indika de Silva 30/06/2013


-- 25-06-2013 Samankula Owitipana -------------
-- Modified 2013/07/05 Jayan Liayanage

--- Jayan Liyanage 2013/07/05

PROCEDURE SLT_SISI_ACC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


cursor Cr_idd IS
select distinct sof.sofe_defaultvalue
from service_order_features sof
where sof.sofe_feature_name = 'SF_SISU CONNECT'
and SOF.SOFE_SERO_ID =p_sero_id
and NVL(SOF.SOFE_DEFAULTVALUE,'N') <> NVL(SOF.SOFE_PREV_VALUE,'N');

v_Sis_val varchar2(100);
v_or_type varchar2(100);


BEGIN

open Cr_idd; fetch Cr_idd into v_Sis_val;
close Cr_idd;

select distinct so.sero_ordt_type INTO v_or_type
from service_orders so where so.sero_id = p_sero_id;

IF v_or_type = 'MODIFY-FEATURE' and  (v_Sis_val = 'Y' or v_Sis_val = 'N'or v_Sis_val = 'U') THEN

UPDATE SERVICE_ORDER_FEATURES sof SET sof.sofe_provision_status = 'Y',sof.SOFE_PROVISION_TIME = SYSDATE, 
sof.SOFE_PROVISION_USERNAME = 'CLARITY' WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_SISU CONNECT'; 
update service_order_attributes soa set soa.seoa_defaultvalue = TO_char(SYSDATE,'DD-MON-YYYY HH24:MI')
where soa.seoa_name = 'ACTUAL_DSP_DATE' and soa.seoa_sero_id = p_sero_id;END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to Active IDD Feature.. Please Check IDD Feature Value. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END SLT_SISI_ACC;

--- Jayan Liyanage 2013/07/05

-- 25-06-2013 Samankula Owitipana ---------
-- Modified 2013/07/05 Jayan Liayanage
PROCEDURE CDMA_CHK_SISU_CON_FEATURECON (
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
      count_2 NUMBER :=0;
      count_3 NUMBER :=0;
BEGIN
    v_isvalid := 'N';


        
        SELECT count(*) into count_1
        FROM SERVICE_ORDER_FEATURES  A WHERE A.SOFE_SERO_ID = p_sero_id
        AND A.SOFE_FEATURE_NAME != 'SF_SISU CONNECT' 
        AND SOFE_DEFAULTVALUE <> NVL(SOFE_PREV_VALUE,'N');

        IF count_1 != 0 THEN
        
                p_ret_msg := '';
                
        ELSE
        
            p_ret_msg := 'FALSE';

        END IF;


EXCEPTION
WHEN OTHERS THEN
   p_ret_msg := 'FALSE';
END CDMA_CHK_SISU_CON_FEATURECON;


--- Samankula Owitipana 2013/07/16

PROCEDURE D_BDL_MDF_X_CONNE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
)IS  

v_equip_type              VARCHAR2 (100);
v_eq_loc_name             VARCHAR2 (100);
v_service_type            VARCHAR2 (100);
v_service_order           VARCHAR2 (100);
v_service_order_area      VARCHAR2 (100);
v_service_order_area_a    VARCHAR2 (100);
v_service_order_area_b    VARCHAR2 (100);
v_rtom_code_aa            VARCHAR2 (100);
v_lea_code_aa             VARCHAR2 (100);
v_main_node_a             VARCHAR2 (100);
v_sub_node_a              VARCHAR2 (100);
v_main_node_b             VARCHAR2 (100);
v_sub_node_b              VARCHAR2 (100);
v_work_group_a_os         VARCHAR2 (100);
v_work_group_a_mdf        VARCHAR2 (100);
v_work_group_b_os         VARCHAR2 (100);
v_work_group_b_mdf        VARCHAR2 (100);
v_rtom_code_bb            VARCHAR2 (100);
v_lea_code_bb             VARCHAR2 (100);
acc_lin_a                 VARCHAR2 (100);
acc_lin_b                 VARCHAR2 (100);
acc_medi_a                VARCHAR2 (100);
acc_medi_b                VARCHAR2 (100);
v_rtom_code               VARCHAR2 (100);
v_lea_code                VARCHAR2 (100);
v_work_group              VARCHAR2 (100);
v_work_group_mdf          VARCHAR2 (100);
v_location                VARCHAR2 (100);
v_main_node               VARCHAR2 (100);
v_sub_node                VARCHAR2 (100);
           


cursor c_aend_equip_locations is
select substr(replace(lo.LOCN_TTNAME,'NODE'),1,instr(replace(lo.LOCN_TTNAME,'NODE'),'-')-1),
substr(replace(lo.LOCN_TTNAME,'NODE'),instr(replace(lo.LOCN_TTNAME,'NODE'),'-')+1)
from service_orders so,circuits ci,ports po,equipment eq,locations lo
where so.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = po.PORT_CIRT_NAME
and po.PORT_EQUP_ID = eq.EQUP_ID
and (eq.EQUP_EQUT_ABBREVIATION like 'MSAN%' or eq.EQUP_EQUT_ABBREVIATION like 'DSLAM%')
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_AREA_CODE = v_service_order_area_a;

cursor c_bend_equip_locations is
select substr(replace(lo.LOCN_TTNAME,'NODE'),1,instr(replace(lo.LOCN_TTNAME,'NODE'),'-')-1),
substr(replace(lo.LOCN_TTNAME,'NODE'),instr(replace(lo.LOCN_TTNAME,'NODE'),'-')+1)
from service_orders so,circuits ci,ports po,equipment eq,locations lo
where so.SERO_ID = p_sero_id
and so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = po.PORT_CIRT_NAME
and po.PORT_EQUP_ID = eq.EQUP_ID
and (eq.EQUP_EQUT_ABBREVIATION like 'MSAN%' or eq.EQUP_EQUT_ABBREVIATION like 'DSLAM%')
and eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
and lo.LOCN_AREA_CODE = v_service_order_area_b;

BEGIN 


SELECT trim(soa.seoa_defaultvalue) INTO v_service_order_area_a
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';
SELECT trim(soa.seoa_defaultvalue) INTO v_service_order_area_b
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';

SELECT soa.seoa_defaultvalue INTO acc_lin_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';

SELECT soa.seoa_defaultvalue INTO acc_lin_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

SELECT soa.seoa_defaultvalue INTO acc_medi_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END';

SELECT soa.seoa_defaultvalue INTO acc_medi_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END';

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_aa,v_lea_code_aa FROM areas ar WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';

SELECT wg.worg_name INTO v_work_group_a_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'OSP-NC';

SELECT wg.worg_name INTO v_work_group_a_mdf FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'MDF';

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_bb,v_lea_code_bb FROM areas ar WHERE ar.area_code = v_service_order_area_b AND ar.area_aret_code = 'LEA';

SELECT wg.worg_name INTO v_work_group_b_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC'; 

SELECT wg.worg_name INTO v_work_group_b_mdf FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'MDF'; 

open c_aend_equip_locations;
fetch c_aend_equip_locations into v_main_node_a,v_sub_node_a;
close c_aend_equip_locations;

open c_bend_equip_locations;
fetch c_bend_equip_locations into v_main_node_b,v_sub_node_b;
close c_bend_equip_locations;

/*OPEN cur_tributer (v_access_bear_id,v_new_Cir_Name);FETCH cur_tributer INTO v_ch_dis, v_cir_trib_status;CLOSE cur_tributer;*/


IF v_main_node_a is null AND v_sub_node_a is null THEN

DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE X CONNECT-A END'; 

ELSIF  ( acc_lin_a = 'DEDICATED LINE' and acc_medi_a = 'COPPER' ) and v_main_node_a <> v_sub_node_a THEN 

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_os
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE X CONNECT-A END';

ELSIF  ( acc_lin_a = 'DEDICATED LINE' and acc_medi_a = 'COPPER' ) and 
(v_main_node_a = v_sub_node_a) or v_sub_node_a is null  THEN 

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_mdf
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE X CONNECT-A END'; 

ELSE

DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE X CONNECT-A END'; 

END IF;


IF v_main_node_b is null AND v_sub_node_b is null THEN

DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE X CONNECT-B END'; 

ELSIF  ( acc_lin_b = 'DEDICATED LINE' and acc_medi_b = 'COPPER' ) and v_main_node_b <> v_sub_node_b THEN 

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_os
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE X CONNECT-B END';

ELSIF  ( acc_lin_b = 'DEDICATED LINE' and acc_medi_b = 'COPPER' ) and 
(v_main_node_b = v_sub_node_b) or v_sub_node_b is null  THEN 

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_mdf
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE X CONNECT-B END'; 

ELSE

DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE X CONNECT-B END'; 

END IF;



p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
         'Failed to WG Mapping Please check the X Connection   :  - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);

END D_BDL_MDF_X_CONNE;

--- Samankula Owitipana 2013/07/16

--- 01-03-2013  Samankula Owitipana

PROCEDURE ADSL_COPY_PSTN_CIRCUIT(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_pstn_dis_name varchar2(50);
v_pstn_cct_id   varchar2(50);
errorText varchar2(1000);

BEGIN

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_dis_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';
SELECT ci.CIRT_NAME
INTO v_pstn_cct_id
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_dis_name || '%'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');
IF not copyCircuit.copyCircuitInfo(v_pstn_cct_id, v_pstn_dis_name|| '-COPY', '', 'COPY', 'REUSE', errorText) THEN
p_ret_msg := 'Error in copyCIrcuitInfo '||errorText; 
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg);END IF;
p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN
      p_ret_msg  := 'Failed to Copy Circuit:'  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);
END ADSL_COPY_PSTN_CIRCUIT;

--- 01-03-2013  Samankula Owitipana


-- 19-03-2013 Samankula Owitipana
-- ADSL PSTN CREATE parallel Completion rule

PROCEDURE ADSL_CHK_PSTN_SO_SOP_CLOSE (
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

P_SLT_FUNCTIONS_V2.ADSL_PSTN_CARD_PORT_CHK(
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

SELECT ci.CIRT_NAME
INTO v_CCT_ID
FROM CIRCUITS ci
WHERE ci.CIRT_DISPLAYNAME LIKE trim(v_PSTN_NO) || '%(N)%'
AND (ci.CIRT_STATUS <> 'PENDINGDELETE' AND ci.CIRT_STATUS <>'CANCELLED')
and ci.CIRT_DISPLAYNAME not like '%-COPY%' ;

SELECT SO.SERO_ID
INTO v_SO_ID
FROM SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SIT
WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
AND SO.SERO_CIRT_NAME = v_CCT_ID
AND SIT.SEIT_TASKNAME = 'SOP_PROVISION'
AND (SIT.SEIT_STAS_ABBREVIATION = 'ASSIGNED' or SIT.SEIT_STAS_ABBREVIATION = 'INPROGRESS');

  IF v_SO_ID IS NOT NULL THEN
      p_ret_msg := 'PSTN SERVICE ORDER SOP PROVISIONING IS STILL INPROGRESS : ' || v_SO_ID;
  ELSE
      p_ret_msg := '';
  END IF;
  
ELSE

 p_ret_msg := p_ret_msg;
  
END IF; 

EXCEPTION
  WHEN NO_DATA_FOUND  THEN
    p_ret_msg := '';
END ADSL_CHK_PSTN_SO_SOP_CLOSE;

-- 19-03-2013 Samankula Owitipana

------JANAKA 2013-06-20 ---- HLR-----------------

PROCEDURE PROCESS_UPDATE_HLR_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


      
    CURSOR NUMB_ID  IS
    
    SELECT  NUMB_ID
    FROM    SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SO.SERO_ID=p_sero_id
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID;
      
      
    CURSOR C_NO_AUTO_PROV (T_NUMB_ID NUMBERS.NUMB_ID%TYPE) IS
        SELECT  NIDE_VALUE
        FROM    NUMBER_INSTANCE_DETAILS
        WHERE   NIDE_NUMB_ID=T_NUMB_ID
        AND     NIDE_NAME ='AUTO_PROV';

    CURSOR C_NO_MANS_NAME (T_NUMB_ID NUMBERS.NUMB_ID%TYPE) IS
        SELECT  NIDE_VALUE
        FROM    NUMBER_INSTANCE_DETAILS
        WHERE   NIDE_NUMB_ID=T_NUMB_ID
        AND     NIDE_NAME='MANS_NAME';
      
     

      V_NUMB_ID         NUMBERS.NUMB_ID%TYPE;
      V_SERO_ATTR       SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;  
      V_AUTO_PROV       SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      V_MANS_NAME       SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

BEGIN


    OPEN NUMB_ID;
    FETCH NUMB_ID INTO V_NUMB_ID;
    CLOSE NUMB_ID;

      
    OPEN C_NO_AUTO_PROV(V_NUMB_ID);
    FETCH C_NO_AUTO_PROV INTO V_AUTO_PROV;
    CLOSE C_NO_AUTO_PROV;

    
    OPEN C_NO_MANS_NAME(V_NUMB_ID);
    FETCH C_NO_MANS_NAME INTO V_MANS_NAME;
    CLOSE C_NO_MANS_NAME;

 

    IF V_AUTO_PROV IS NOT NULL AND V_MANS_NAME IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_MANS_NAME
        where soa.SEOA_SERO_ID = p_sero_id
        and soa.SEOA_NAME = 'MANS_NAME';
        
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_AUTO_PROV
        where soa.SEOA_SERO_ID = p_sero_id
        and soa.SEOA_NAME = 'AUTO_PROV';
        
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, 

p_seit_id,'COMPLETED');
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = p_sero_id
        and soa.SEOA_NAME = 'MANS_NAME';
        
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = p_sero_id
        and soa.SEOA_NAME = 'AUTO_PROV';
        
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, 

p_seit_id,'COMPLETED');
    
    END IF;
    

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'UPDATE HLR ATTR PROCESS FAILED' || ' - Erro is:' || 

TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, 

p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, 

SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  

SYSDATE
          , p_ret_msg);


END PROCESS_UPDATE_HLR_ATTR;

------JANAKA 2013-06-20 ---- HLR-----------------

------JANAKA 2013-07-05 ---- HUAWEI-IN-----------------


PROCEDURE UPDATE_SA_PRE_PAID (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = P_SEIT_ID;
      
      
    CURSOR C_SEOA_VALUE (T_SERO_ID SERVICE_ORDER_ATTRIBUTES.SEOA_SERO_ID%TYPE) IS
        SELECT MAX(SEOA_DEFAULTVALUE)
        from SERVICE_ORDER_ATTRIBUTES SOA
        where soa.SEOA_SERO_ID = T_SERO_ID
        and soa.SEOA_NAME = 'SA_PRE-PAID';
      

      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;  
      V_SEOA_VALUE      SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;


      V_VALUE                SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;


BEGIN


    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;

      
    OPEN C_SEOA_VALUE(V_SERO_ID);
    FETCH C_SEOA_VALUE INTO V_SEOA_VALUE;
    CLOSE C_SEOA_VALUE;

        
     
     IF V_SEOA_VALUE IS NOT NULL THEN
     
        V_VALUE:=UPPER(V_SEOA_VALUE);
        
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_VALUE
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'SA_PRE-PAID_UPPER';
        
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
        
        
     ELSE
     
         p_ret_msg  := 'SA_PRE-PAID is null' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
        
                p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);    
     
     
     END IF;



 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SA_PRE-PAID_UPPER UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_SA_PRE_PAID;

------JANAKA 2013-07-05 ---- HUAWEI-IN-----------------

--- 22-08-2013  Samankula Owitipana

PROCEDURE ADSL_COPY_PSTN_REMOVE (
    p_serv_id        IN     Services.serv_id%type,
    p_sero_id        IN     Service_Orders.sero_id%type,
    p_seit_id        IN     Service_Implementation_Tasks.seit_id%type,
    p_impt_taskname  IN     Implementation_Tasks.impt_taskname%type,
    p_srbt_id        IN     service_rollback_tasks.srbt_id%TYPE,
    p_ret_char       OUT    varchar2,
    p_ret_number     OUT    number,
    p_ret_msg        OUT    Varchar2) is

v_pstn_dis_name varchar2(50);
v_dispalay_name varchar2(50);
v_pstn_cct_id   varchar2(50);
v_copy_cct_id   varchar2(50);
v_pstn_status   varchar2(50);
errorText varchar2(1000);

BEGIN

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_dis_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

update circuits ci
set ci.CIRT_STATUS = 'PENDINGDELETE',ci.CIRT_DECOMMISSIONED = sysdate,ci.CIRT_OUTSERVICE = sysdate
where ci.CIRT_NAME in
(SELECT ci.CIRT_NAME
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_dis_name || '%'
and ci.CIRT_DISPLAYNAME like '%-COPY'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%'));


p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
   
END ADSL_COPY_PSTN_REMOVE;

--- 22-08-2013  Samankula Owitipana

--- 13-08-2013  Samankula Owitipana
--- 30-07-2014 Edited By Rana
PROCEDURE ADSL_COPY_PSTN_REPLACE (
    p_serv_id        IN     Services.serv_id%type,
    p_sero_id        IN     Service_Orders.sero_id%type,
    p_seit_id        IN     Service_Implementation_Tasks.seit_id%type,
    p_impt_taskname  IN     Implementation_Tasks.impt_taskname%type,
    p_srbt_id        IN     service_rollback_tasks.srbt_id%TYPE,
    p_ret_char       OUT    varchar2,
    p_ret_number     OUT    number,
    p_ret_msg        OUT    Varchar2) is

v_pstn_dis_name varchar2(50);
v_dispalay_name varchar2(50);
v_pstn_cct_id   varchar2(50);
v_copy_cct_id   varchar2(50);
v_pstn_status   varchar2(50);
errorText varchar2(1000);

BEGIN

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_dis_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


SELECT ci.CIRT_NAME,ci.CIRT_STATUS,ci.CIRT_DISPLAYNAME
INTO v_pstn_cct_id,v_pstn_status,v_dispalay_name
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_dis_name || '%'
and ci.CIRT_DISPLAYNAME not like '%-COPY'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');


SELECT ci.CIRT_NAME
INTO v_copy_cct_id
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_dis_name || '%'
and ci.CIRT_DISPLAYNAME like '%-COPY'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');

--- TO TEST ROLLBACK FUNCTION -----
UPDATE service_order_attributes 
SET SEOA_DEFAULTVALUE='PC:'||v_pstn_cct_id||'PS:'||v_pstn_status||'PD:'||v_dispalay_name||'CC:'||v_copy_cct_id
WHERE SEOA_SERO_ID=p_sero_id
AND SEOA_NAME='SLTNET_IP_ADDRESS8';


update circuits ci
set ci.CIRT_STATUS = 'PENDINGDELETE',ci.CIRT_DECOMMISSIONED = sysdate,ci.CIRT_OUTSERVICE = sysdate
where ci.CIRT_NAME in
(select ci.CIRT_NAME 
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_CHILD = v_pstn_cct_id
and ch.CIRH_PARENT = ci.CIRT_NAME
and upper(ci.CIRT_TYPE) = 'BEARER'
and upper(ci.CIRT_SERT_ABBREVIATION) = 'ADSL');


update ports po
set po.PORT_CIRT_NAME = null
where po.PORT_CIRT_NAME in
(select ci.CIRT_NAME 
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_CHILD = v_pstn_cct_id
and ch.CIRH_PARENT = ci.CIRT_NAME
and upper(ci.CIRT_TYPE) = 'BEARER'
and upper(ci.CIRT_SERT_ABBREVIATION) = 'ADSL');

update FRAME_APPEARANCES fa
set fa.FRAA_CIRT_NAME = null
where fa.FRAA_CIRT_NAME in
(select ci.CIRT_NAME 
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_CHILD = v_pstn_cct_id
and ch.CIRH_PARENT = ci.CIRT_NAME
and upper(ci.CIRT_TYPE) = 'BEARER'
and upper(ci.CIRT_SERT_ABBREVIATION) = 'ADSL');

delete from port_link_ports plp
where plp.POLP_PORL_ID in
(select pl.PORL_ID from port_links pl
where pl.PORL_CIRT_NAME = v_pstn_cct_id);

delete port_links pl
where pl.PORL_CIRT_NAME = v_pstn_cct_id;


update port_links pl
set pl.PORL_CIRT_NAME = v_pstn_cct_id
where pl.PORL_CIRT_NAME = v_copy_cct_id;

update circuits ci
set ci.CIRT_STATUS = 'PENDINGDELETE',ci.CIRT_DECOMMISSIONED = sysdate,ci.CIRT_OUTSERVICE = sysdate
where ci.CIRT_NAME = v_copy_cct_id;

IF v_pstn_status <> 'PROPOSED' THEN


update FRAME_APPEARANCES fa
set fa.FRAA_CIRT_NAME = v_pstn_cct_id
where fa.FRAA_ID in
(select plp.POLP_FRAA_ID
from port_links pl,port_link_ports plp
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_FRAA_ID is not null
and pl.PORL_CIRT_NAME = v_pstn_cct_id );

update ports po
set po.PORT_CIRT_NAME = v_pstn_cct_id
where po.PORT_ID in
(select plp.POLP_PORT_ID
from port_links pl,port_link_ports plp
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID is not null
and pl.PORL_CIRT_NAME = v_pstn_cct_id );

--- TO TEST ROLLBACK FUNCTION -----
UPDATE service_order_attributes 
SET SEOA_PREV_VALUE='PC:'||v_pstn_cct_id||'PS:'||v_pstn_status||'PD:'||v_dispalay_name||'CC:'||v_copy_cct_id
WHERE SEOA_SERO_ID=p_sero_id
AND SEOA_NAME='SLTNET_IP_ADDRESS8';

END IF;


p_ret_msg  := null;


EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := null;

   
END ADSL_COPY_PSTN_REPLACE;
--- 13-08-2013  Samankula Owitipana
--- 30-07-2014 Edited By Rana

-- 15-02-2013 Samankula Owitipana
-- ADSL_DELETE_SO_EDITED 04_09_2013
---edited 2014/03/14
--- 10-01-2016  DINESH PERERA RE-WRITTEN ----
PROCEDURE ADSL_DELETE_CCT_REARRANGEMENT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

CURSOR GET_ADSL_CIRT ( IN_SERO_ID IN VARCHAR2 ) IS
SELECT 
SERO_CIRT_NAME,
CIRT_DISPLAYNAME 
FROM 
SERVICE_ORDERS,
CIRCUITS
WHERE 
    SERO_CIRT_NAME = CIRT_NAME
AND SERO_ID = IN_SERO_ID;

CURSOR GET_BEARER ( IN_ADSL_CIRT_ID IN VARCHAR2 ) IS
SELECT 
CIRT_NAME,
CIRT_DISPLAYNAME
FROM 
CIRCUIT_HIERARCHY,
CIRCUITS
WHERE 
    CIRH_PARENT = CIRT_NAME
AND CIRH_CHILD = IN_ADSL_CIRT_ID
AND CIRT_TYPE = 'BEARER';

CURSOR GET_EQUIPMENT ( IN_ADSL_CRT VARCHAR2 ) IS
SELECT
EQUP_EQUT_ABBREVIATION
FROM
PORT_LINKS,
PORT_LINK_PORTS,
PORTS,
CARDS,
EQUIPMENT
WHERE
    PORL_CIRT_NAME = IN_ADSL_CRT
AND PORL_ID = POLP_PORL_ID
AND POLP_PORT_ID = PORT_ID
AND PORT_CARD_SLOT = CARD_SLOT
AND CARD_EQUP_ID = EQUP_ID
AND PORT_EQUP_ID = EQUP_ID
AND PORT_NAME LIKE 'DSL-IN-%';

CURSOR GET_ADSL_CARD_PORT (V_ADSL_CCT_ID VARCHAR2) IS
SELECT 
DISTINCT PORT_CARD_SLOT,
REPLACE(PORT_NAME,'DSL-IN-',''),
PORT_ID,
PORT_EQUP_ID
FROM 
PORT_LINKS ,
PORT_LINK_PORTS,
PORTS 
WHERE 
    PORL_ID = POLP_PORL_ID
AND POLP_PORT_ID = PORT_ID
AND PORT_NAME LIKE 'DSL-IN-%'
AND PORL_CIRT_NAME = V_ADSL_CCT_ID;

CURSOR GET_PSTN_DSP_NAME  ( INN_SERO_ID IN VARCHAR2 ) IS
SELECT TRIM(SOA.SEOA_DEFAULTVALUE) AS SA_PSTN
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = INN_SERO_ID
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';

CURSOR GET_SPLITER (IN_ADSL_CIRT IN VARCHAR2) IS 
SELECT
PORT_ID,EQUP_ID
FROM
CIRCUITS,
PORTS,
CARDS,
EQUIPMENT
WHERE
CIRT_NAME = IN_ADSL_CIRT
AND CIRT_NAME = PORT_CIRT_NAME
AND PORT_CARD_SLOT = CARD_SLOT
AND EQUP_ID = CARD_EQUP_ID
AND EQUP_ID = PORT_EQUP_ID
AND EQUP_EQUT_ABBREVIATION LIKE 'DSL_SPLITTER%';

CURSOR GET_DSLAM (IN_ADSL_CIRT IN VARCHAR2) IS 
SELECT
PORT_ID,EQUP_ID
FROM
CIRCUITS,
PORTS,
CARDS,
EQUIPMENT
WHERE
CIRT_NAME = IN_ADSL_CIRT
AND CIRT_NAME = PORT_CIRT_NAME
AND PORT_CARD_SLOT = CARD_SLOT
AND EQUP_ID = CARD_EQUP_ID
AND EQUP_ID = PORT_EQUP_ID
AND EQUP_EQUT_ABBREVIATION LIKE 'DSLAM%';

CURSOR GET_MDF_ADSL_DAT (IN_BEARER_CIRT IN VARCHAR2) IS 
SELECT 
PORL_ID,POLP_FRAA_ID
FROM 
PORT_LINKS,
PORT_LINK_PORTS,
FRAME_APPEARANCES,
FRAME_UNITS,
FRAME_CONTAINERS
WHERE
PORL_ID = POLP_PORL_ID
AND PORL_CIRT_NAME  = IN_BEARER_CIRT
AND POLP_FRAA_ID IS NOT NULL
AND POLP_FRAA_ID = FRAA_ID
AND FRAA_FRAU_ID = FRAU_ID
AND FRAU_FRAC_ID = FRAC_ID
AND FRAU_NAME LIKE 'MDF-ADSL%';

CURSOR GET_MDF_ADSL_POT_DAT (IN_PSTN_CIRT IN VARCHAR2) IS 
SELECT 
PORL_ID,POLP_FRAA_ID
FROM 
PORT_LINKS,
PORT_LINK_PORTS,
FRAME_APPEARANCES,
FRAME_UNITS,
FRAME_CONTAINERS
WHERE
PORL_ID = POLP_PORL_ID
AND PORL_CIRT_NAME  = IN_PSTN_CIRT
AND POLP_FRAA_ID IS NOT NULL
AND POLP_FRAA_ID = FRAA_ID
AND FRAA_FRAU_ID = FRAU_ID
AND FRAU_FRAC_ID = FRAC_ID
AND FRAU_NAME LIKE 'MDF-ADSL-POT%';

GET_ADSL_CIRT_R GET_ADSL_CIRT%ROWTYPE;
GET_BEARER_R GET_BEARER%ROWTYPE;
GET_EQUIPMENT_R GET_EQUIPMENT%ROWTYPE;
GET_ADSL_CARD_PORT_R GET_ADSL_CARD_PORT%ROWTYPE;
GET_PSTN_DSP_NAME_R GET_PSTN_DSP_NAME%ROWTYPE;
NEW_BEARER_DSP_NAME VARCHAR2(500);
PSTN_CIRT_NAME VARCHAR2(200);
GET_SPLITER_R GET_SPLITER%ROWTYPE;
GET_DSLAM_R GET_DSLAM%ROWTYPE;

SP_DSL_IN_PORT  NUMBER;
SP_POTS_OUT_PORT NUMBER;
SP_POTS_IN_PORT NUMBER;

DSLAM_DSL_IN_PORT NUMBER;
DSLAM_POTS_OUT_PORT NUMBER;
DSLAM_POTS_IN_PORT NUMBER;

MDF_UG_F_LINK NUMBER;
MDF_EX_F_LINK NUMBER;

BEGIN

-- GET RELATED ADSL CIRCUIT
OPEN GET_ADSL_CIRT (p_sero_id);
FETCH GET_ADSL_CIRT INTO GET_ADSL_CIRT_R ;
CLOSE GET_ADSL_CIRT;
-- CHECK FOR BEARER
OPEN GET_BEARER (GET_ADSL_CIRT_R.SERO_CIRT_NAME);
FETCH GET_BEARER INTO GET_BEARER_R;
CLOSE GET_BEARER;

    IF GET_BEARER_R.CIRT_NAME IS NOT NULL THEN
    -- REARRANGE SCENARIO
    -- GET THE EQUIPMENT
    OPEN GET_EQUIPMENT (GET_ADSL_CIRT_R.SERO_CIRT_NAME);
    FETCH GET_EQUIPMENT INTO GET_EQUIPMENT_R;
    CLOSE GET_EQUIPMENT;
        IF GET_EQUIPMENT_R.EQUP_EQUT_ABBREVIATION LIKE 'MSAN%' THEN
        -- REARRANGED MSAN  SCENARIO 
         OPEN GET_ADSL_CARD_PORT(GET_ADSL_CIRT_R.SERO_CIRT_NAME);
         FETCH GET_ADSL_CARD_PORT INTO GET_ADSL_CARD_PORT_R;
         CLOSE GET_ADSL_CARD_PORT;
        -- REMOVE PORT LINK PORT ENTRY FOR ADSL
         DELETE FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
         (SELECT PORL_ID FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME);
        -- REMOVE PORT LINK ENTRY FOR ADSL
         DELETE FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- RELESE ADSL PORT 
         UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- REMOVE CIRCUIT HIRARCHEY ENTRY FOR ADSL
         DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_CHILD = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- ADSL CIRCUIT SET TO CANCELED
         UPDATE CIRCUITS SET CIRT_STATUS = 'CANCELLED' WHERE CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- GET PSTN CIRCUIT DISPLAY NAME
         OPEN GET_PSTN_DSP_NAME (p_sero_id);
         FETCH GET_PSTN_DSP_NAME INTO GET_PSTN_DSP_NAME_R;
         CLOSE GET_PSTN_DSP_NAME;
        -- PREAPRE NEW NAME FOR BEARER
         SELECT REPLACE(GET_BEARER_R.CIRT_DISPLAYNAME, SUBSTR(GET_BEARER_R.CIRT_DISPLAYNAME,-15,15),'PSTN '||GET_PSTN_DSP_NAME_R.SA_PSTN) 
         INTO NEW_BEARER_DSP_NAME
         FROM CIRCUITS WHERE CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- UPDATE NEW NAME FOR BEARER
         UPDATE CIRCUITS SET CIRT_DISPLAYNAME = NEW_BEARER_DSP_NAME WHERE CIRT_NAME = GET_BEARER_R.CIRT_NAME;

        ELSIF GET_EQUIPMENT_R.EQUP_EQUT_ABBREVIATION LIKE 'DSLAM%' THEN
        -- REARRANGED DSLAM
        -- GET RELATED PSTN CIRCUIT
         OPEN GET_PSTN_DSP_NAME (p_sero_id);
         FETCH GET_PSTN_DSP_NAME INTO GET_PSTN_DSP_NAME_R;
         CLOSE GET_PSTN_DSP_NAME;
        -- GET THE SPLITER
         OPEN GET_SPLITER (GET_ADSL_CIRT_R.SERO_CIRT_NAME);
         FETCH GET_SPLITER INTO GET_SPLITER_R;
         CLOSE GET_SPLITER;
        -- GET THE SPLITER DSL-IN PORT
         SP_DSL_IN_PORT := GET_SPLITER_R.PORT_ID;
        -- GET THE SPLITER POTS-OUT PORT
         SELECT PORH_PARENTID INTO SP_POTS_OUT_PORT FROM PORT_HIERARCHY WHERE PORH_CHILDID = SP_DSL_IN_PORT;
        -- GET THE SPLITER POTS-IN PORT
         SELECT PORH_CHILDID INTO SP_POTS_IN_PORT 
         FROM PORT_HIERARCHY WHERE PORH_PARENTID = 
         (SELECT PORH_PARENTID FROM PORT_HIERARCHY WHERE PORH_CHILDID = SP_DSL_IN_PORT)
         AND PORH_CHILDID <> SP_DSL_IN_PORT;         
        -- DELETE PORT LINK PORTS ENTRY RELATED TO SPLITER
         DELETE FROM PORT_LINK_PORTS WHERE POLP_PORT_ID IN (SP_DSL_IN_PORT,SP_POTS_OUT_PORT,SP_POTS_IN_PORT);
        -- DELETE PORT HIRARCHEY ENTRY RELATED TO SPLITER
         DELETE FROM PORT_HIERARCHY WHERE PORH_CHILDID IN (SP_DSL_IN_PORT,SP_POTS_OUT_PORT,SP_POTS_IN_PORT);
        -- DELETE PORT DETAIL INSTANCE ENTRY RELATED TO SPLITER
         DELETE FROM PORT_DETAIL_INSTANCE WHERE PODI_PORT_ID IN (SP_DSL_IN_PORT,SP_POTS_OUT_PORT,SP_POTS_IN_PORT);
        -- DELETE PORT ENTRY RELATED TO SPLITER
         DELETE FROM PORTS WHERE PORT_ID IN (SP_DSL_IN_PORT,SP_POTS_OUT_PORT,SP_POTS_IN_PORT);
        -- DELETE CARD RELATED TO SPLITER
         DELETE FROM CARDS WHERE CARD_EQUP_ID = GET_SPLITER_R.EQUP_ID;
        -- DELETE SPLITER
         DELETE FROM EQUIPMENT WHERE EQUP_ID = GET_SPLITER_R.EQUP_ID;
        -- GET ADSL RELATED DSLAM
         OPEN GET_DSLAM (GET_ADSL_CIRT_R.SERO_CIRT_NAME);
         FETCH GET_DSLAM INTO GET_DSLAM_R;
         CLOSE GET_DSLAM;
        -- GET THE DSLAM DSL-IN PORT
         DSLAM_DSL_IN_PORT := GET_DSLAM_R.PORT_ID;
        -- GET THE DSLAM POTS-OUT PORT
         SELECT DISTINCT PORH_PARENTID INTO DSLAM_POTS_OUT_PORT 
         FROM PORT_HIERARCHY 
         WHERE PORH_CHILDID = DSLAM_DSL_IN_PORT;
        -- GET THE DSLAM POTS-IN PORT
         SELECT DISTINCT PORH_CHILDID INTO DSLAM_POTS_IN_PORT 
         FROM PORT_HIERARCHY 
         WHERE PORH_PARENTID = DSLAM_POTS_OUT_PORT
         AND PORH_CHILDID <> DSLAM_DSL_IN_PORT;
        -- RELESE DSLAM PORTS
         UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_ID IN (DSLAM_DSL_IN_PORT,DSLAM_POTS_OUT_PORT,DSLAM_POTS_IN_PORT);
        -- DELETE PORT LINK PORTS ENTRY RELATED TO DSALM
         DELETE FROM PORT_LINK_PORTS WHERE POLP_PORT_ID IN  (DSLAM_DSL_IN_PORT,DSLAM_POTS_OUT_PORT,DSLAM_POTS_IN_PORT);
        -- DELETE PORT LINK ENTRY RELATED TO DSALM
         DELETE FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- ADSL CIRCUIT SET TO CANCELED
         UPDATE CIRCUITS SET CIRT_STATUS = 'CANCELLED' WHERE CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
         
         FOR GET_MDF_ADSL_DAT_R IN GET_MDF_ADSL_DAT(GET_BEARER_R.CIRT_NAME) LOOP
         -- RELSE FRAME APPEARANCE REALTE TO MDF ADSL IN BEARER
          UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = NULL WHERE FRAA_ID = GET_MDF_ADSL_DAT_R.POLP_FRAA_ID;
        -- DELETE PORT LINK PORTS ENTRY RELATED TO MDF ADSL IN BEARER
          DELETE FROM PORT_LINK_PORTS WHERE POLP_FRAA_ID = GET_MDF_ADSL_DAT_R.POLP_FRAA_ID;          
         END LOOP;
        -- DELETE PORT LINK RECORDS NOT REFER TO PORT LINK PORTS IN BERER CIRCUIT
         DELETE FROM PORT_LINKS WHERE PORL_ID IN
            (
            SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = GET_BEARER_R.CIRT_NAME
            MINUS
            SELECT DISTINCT POLP_PORL_ID FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
            (SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = GET_BEARER_R.CIRT_NAME)
            );
        -- GET THE PSTN CIRT_NAME   
         SELECT CIRT_NAME INTO PSTN_CIRT_NAME FROM CIRCUITS WHERE CIRT_DISPLAYNAME = GET_PSTN_DSP_NAME_R.SA_PSTN AND CIRT_STATUS = 'INSERVICE';
        -- DELETE PORT LINK RECORDS NOT REFER TO PORT LINK PORTS IN BERER CIRCUIT
         FOR GET_MDF_ADSL_POT_DAT_R IN GET_MDF_ADSL_POT_DAT (PSTN_CIRT_NAME) LOOP
         -- RELSE FRAME APPEARANCE REALTE TO MDF ADSL POT IN PSTN
          UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = NULL WHERE FRAA_ID = GET_MDF_ADSL_POT_DAT_R.POLP_FRAA_ID;
        -- DELETE PORT LINK PORTS ENTRY RELATED TO MDF ADSL POT IN PSTN
          DELETE FROM PORT_LINK_PORTS WHERE POLP_FRAA_ID = GET_MDF_ADSL_POT_DAT_R.POLP_FRAA_ID;
         END LOOP;         
        -- DELETE PORT LINK RECORDS NOT REFER TO PORT LINK PORTS IN PSTN CIRCUIT
         DELETE FROM PORT_LINKS WHERE PORL_ID IN
            (
            SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME
            MINUS
            SELECT DISTINCT POLP_PORL_ID FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
            (SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME)
            );
            -- TRANSFER REMAINING BEARER X CONNECTION TO PSTN            
            UPDATE PORT_LINKS SET PORL_CIRT_NAME = PSTN_CIRT_NAME
            WHERE 
            PORL_CIRT_NAME = GET_BEARER_R.CIRT_NAME;
            -- RSERVED PORTS FOR BEARER RESERVED FOR PSTN
            UPDATE PORTS SET PORT_CIRT_NAME = PSTN_CIRT_NAME
            WHERE PORT_ID IN
            (
            SELECT 
            PORT_ID
            FROM 
            PORT_LINKS,
            PORT_LINK_PORTS,
            PORTS
            WHERE 
            PORL_CIRT_NAME = PSTN_CIRT_NAME
            AND PORL_ID = POLP_PORL_ID
            AND PORT_ID = POLP_PORT_ID
            )
            AND PORT_CIRT_NAME <> PSTN_CIRT_NAME;
            -- RSERVED FEAME APPERANCE FOR BEARER RESERVED FOR PSTN
            UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = PSTN_CIRT_NAME WHERE FRAA_ID IN 
            (
            SELECT 
            FRAA_ID
            FROM 
            PORT_LINKS,
            PORT_LINK_PORTS,
            FRAME_APPEARANCES
            WHERE 
            PORL_CIRT_NAME = PSTN_CIRT_NAME
            AND PORL_ID = POLP_PORL_ID
            AND POLP_FRAA_ID = FRAA_ID
            )
            AND FRAA_CIRT_NAME <> PSTN_CIRT_NAME;
            -- BEARER CIRCUIT SET TO CANCEL
            UPDATE CIRCUITS SET CIRT_STATUS = 'CANCELLED' WHERE CIRT_NAME = GET_BEARER_R.CIRT_NAME;
            -- REMOVE CIRCUIT HIRARCHEY ENTRY FOR BEARER
            DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_PARENT = GET_BEARER_R.CIRT_NAME;
            -- GET PSTN MDF UG FRONT POLP_PORL_ID
            SELECT 
            POLP_PORL_ID INTO MDF_UG_F_LINK
            FROM 
            PORT_LINKS,
            PORT_LINK_PORTS,
            FRAME_APPEARANCES,
            FRAME_UNITS,
            FRAME_CONTAINERS
            WHERE
            PORL_ID = POLP_PORL_ID
            AND PORL_CIRT_NAME  = PSTN_CIRT_NAME
            AND POLP_FRAA_ID IS NOT NULL
            AND POLP_FRAA_ID = FRAA_ID
            AND FRAA_FRAU_ID = FRAU_ID
            AND FRAU_FRAC_ID = FRAC_ID
            AND FRAU_NAME LIKE 'MDF-UG%'
            AND FRAA_SIDE = 'FRONT';
            -- GET PSTN MDF EX FRONT POLP_PORL_ID
            SELECT 
            POLP_PORL_ID INTO MDF_EX_F_LINK
            FROM 
            PORT_LINKS,
            PORT_LINK_PORTS,
            FRAME_APPEARANCES,
            FRAME_UNITS,
            FRAME_CONTAINERS
            WHERE
            PORL_ID = POLP_PORL_ID
            AND PORL_CIRT_NAME  = PSTN_CIRT_NAME
            AND POLP_FRAA_ID IS NOT NULL
            AND POLP_FRAA_ID = FRAA_ID
            AND FRAA_FRAU_ID = FRAU_ID
            AND FRAU_FRAC_ID = FRAC_ID
            AND FRAU_NAME LIKE 'MDF-EX%'
            AND FRAA_SIDE = 'FRONT';
            -- SET JUMPER FROM MDF UG FRONT TO MDF EX FRONT
            UPDATE PORT_LINK_PORTS SET POLP_PORL_ID = MDF_UG_F_LINK  WHERE POLP_PORL_ID = MDF_EX_F_LINK;
            -- DELETE PORT LINK RECORDS NOT REFER TO PORT LINK PORTS IN PSTN CIRCUIT
            DELETE FROM PORT_LINKS WHERE PORL_ID IN
            (
            SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME
            MINUS
            SELECT DISTINCT POLP_PORL_ID FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
            (SELECT 
            PORL_ID
            FROM 
            PORT_LINKS
            WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME)
            );

        END IF;

    ELSE
    -- NOT REARRANGE SCENARIO
     OPEN GET_EQUIPMENT (GET_ADSL_CIRT_R.SERO_CIRT_NAME);
     FETCH GET_EQUIPMENT INTO GET_EQUIPMENT_R;
     CLOSE GET_EQUIPMENT;
  
     IF GET_EQUIPMENT_R.EQUP_EQUT_ABBREVIATION LIKE 'MSAN%' THEN
        -- MSAN NOT REARRANGE SCENARIO
         OPEN GET_ADSL_CARD_PORT(GET_ADSL_CIRT_R.SERO_CIRT_NAME);
         FETCH GET_ADSL_CARD_PORT INTO GET_ADSL_CARD_PORT_R;
         CLOSE GET_ADSL_CARD_PORT;
        -- DELETE PORT LINK PORT REALTED TO ADSL
         DELETE FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
         (SELECT PORL_ID FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME);
        -- DELETE PORT LINK REALTED TO ADSL
         DELETE FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- RELESE PORTS
         UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- DELETE ENTRY FOR ADSL IN CIRCUIT HIERARCHY
         DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_CHILD = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- SET ADSL CIRCUIT TO CANCELED
         UPDATE CIRCUITS SET CIRT_STATUS = 'CANCELLED' WHERE CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
         
     ELSIF GET_EQUIPMENT_R.EQUP_EQUT_ABBREVIATION LIKE 'DSLAM%' THEN
        -- DSLAM NOT REARRANGE SCENARIO
         OPEN GET_ADSL_CARD_PORT(GET_ADSL_CIRT_R.SERO_CIRT_NAME);
         FETCH GET_ADSL_CARD_PORT INTO GET_ADSL_CARD_PORT_R;
         CLOSE GET_ADSL_CARD_PORT;
        -- DELETE PORT LINK PORT REALTED TO ADSL
         DELETE FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
         (SELECT PORL_ID FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME);
        -- DELETE PORT LINK REALTED TO ADSL
         DELETE FROM PORT_LINKS WHERE PORL_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- RELESE PORTS
         UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- DELETE ENTRY FOR ADSL IN CIRCUIT HIERARCHY
         DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_CHILD = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- SET ADSL CIRCUIT TO CANCELED
         UPDATE CIRCUITS SET CIRT_STATUS = 'CANCELLED' WHERE CIRT_NAME = GET_ADSL_CIRT_R.SERO_CIRT_NAME;
        -- GET RELATED PSTN CIRCUIT
        OPEN GET_PSTN_DSP_NAME (p_sero_id);
        FETCH GET_PSTN_DSP_NAME INTO GET_PSTN_DSP_NAME_R;
        CLOSE GET_PSTN_DSP_NAME;
        -- GET THE PSTN CIRT_NAME   
        SELECT CIRT_NAME INTO PSTN_CIRT_NAME FROM CIRCUITS WHERE CIRT_DISPLAYNAME = GET_PSTN_DSP_NAME_R.SA_PSTN
        AND CIRT_STATUS = 'INSERVICE';
        -- GET PSTN RELATED DSLAM
        FOR GET_DSLAM_RR IN GET_DSLAM (PSTN_CIRT_NAME) LOOP
            -- RELSE DSLAM PORT
            UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_ID = GET_DSLAM_RR.PORT_ID;
            -- REMOVE PORT LINK PORT 
            DELETE FROM PORT_LINK_PORTS WHERE POLP_PORT_ID = GET_DSLAM_RR.PORT_ID;
        END LOOP;
        -- GET PSTN RELATED MDF_ADSL
        FOR GET_MDF_ADSL_DAT_RR IN GET_MDF_ADSL_DAT(PSTN_CIRT_NAME) LOOP
            -- RELSE FRAME APPEARANCE
            UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = NULL WHERE FRAA_ID = GET_MDF_ADSL_DAT_RR.POLP_FRAA_ID;
            -- REMOVE PORT LINK PORT
            DELETE FROM PORT_LINK_PORTS WHERE POLP_FRAA_ID = GET_MDF_ADSL_DAT_RR.POLP_FRAA_ID;
        END LOOP;
            -- GET PSTN MDF UG FRONT POLP_PORL_ID
        SELECT 
        POLP_PORL_ID INTO MDF_UG_F_LINK
        FROM 
        PORT_LINKS,
        PORT_LINK_PORTS,
        FRAME_APPEARANCES,
        FRAME_UNITS,
        FRAME_CONTAINERS
        WHERE
        PORL_ID = POLP_PORL_ID
        AND PORL_CIRT_NAME  = PSTN_CIRT_NAME
        AND POLP_FRAA_ID IS NOT NULL
        AND POLP_FRAA_ID = FRAA_ID
        AND FRAA_FRAU_ID = FRAU_ID
        AND FRAU_FRAC_ID = FRAC_ID
        AND FRAU_NAME LIKE 'MDF-UG%'
        AND FRAA_SIDE = 'FRONT';
        -- GET PSTN MDF EX FRONT POLP_PORL_ID
        SELECT 
        POLP_PORL_ID INTO MDF_EX_F_LINK
        FROM 
        PORT_LINKS,
        PORT_LINK_PORTS,
        FRAME_APPEARANCES,
        FRAME_UNITS,
        FRAME_CONTAINERS
        WHERE
        PORL_ID = POLP_PORL_ID
        AND PORL_CIRT_NAME  = PSTN_CIRT_NAME
        AND POLP_FRAA_ID IS NOT NULL
        AND POLP_FRAA_ID = FRAA_ID
        AND FRAA_FRAU_ID = FRAU_ID
        AND FRAU_FRAC_ID = FRAC_ID
        AND FRAU_NAME LIKE 'MDF-EX%'
        AND FRAA_SIDE = 'FRONT';
        -- SET JUMPER FROM MDF UG FRONT TO MDF EX FRONT
        UPDATE PORT_LINK_PORTS SET POLP_PORL_ID = MDF_UG_F_LINK  WHERE POLP_PORL_ID = MDF_EX_F_LINK;
        -- REMOVE PORT LINK WHICH NOT NEED            
        DELETE FROM PORT_LINKS WHERE PORL_ID IN
        (
        SELECT 
        PORL_ID
        FROM 
        PORT_LINKS
        WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME
        MINUS
        SELECT DISTINCT POLP_PORL_ID FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN
        (SELECT 
        PORL_ID
        FROM 
        PORT_LINKS
        WHERE PORL_CIRT_NAME  = PSTN_CIRT_NAME)
        );

     END IF;

    END IF;

EXCEPTION
WHEN OTHERS THEN

    p_ret_msg  := 'ADSL REMOVE CCT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
    
END ADSL_DELETE_CCT_REARRANGEMENT;
--- 10-01-2016  DINESH PERERA RE-WRITTEN ----
-- 15-02-2013 Samankula Owitipana

--- 18-01-2013 Samankula Owitipana
--- 03-01-2014 Edited -----
--- 13-10-2014 Edited -----
--- 05-08-2015 DINESH PERERA 
--- 12-11-2015 DINESH PERERA ( RE-WRITTEN )
PROCEDURE ADSL_BEARER_CREATION_AUTO (
P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
P_RET_CHAR        OUT      VARCHAR2,
P_RET_NUMBER      OUT      NUMBER,
P_RET_MSG         OUT      VARCHAR2
)
IS

P_ERROR_MSG VARCHAR2(1000);
P_ERROR_2 VARCHAR2(1000);
V_ADSL_CCT_ID VARCHAR2(30);
V_ADSL_DIS_NAME VARCHAR2(30);
V_ALREADY_REARRANGED VARCHAR2(30);
V_ADSL_EQUIP_ID NUMBER;
V_ADSL_EQUIP_ABBR VARCHAR2(200);
V_PSTN_DIS_NAME VARCHAR2(30);
V_PSTN_CCT_ID VARCHAR2(30);
POTS_OUT_PORL_ID NUMBER;
POTS_IN_PORL_ID NUMBER;
MDF_ADSL_POT_PORL_ID NUMBER;
V_ADSL_POTS_CARD VARCHAR2(100);
V_ADSL_POTS_PORT VARCHAR2(100);
V_PSTN_POTS_CARD VARCHAR2(100);
V_PSTN_POTS_PORT VARCHAR2(100);
V_ADSL_LOC_AEND VARCHAR2(100);
V_ADSL_INSERVICE_DT DATE;
V_ADSL_CCT_STATE VARCHAR2(30);
V_ADSL_SPEED VARCHAR2(100);
V_PSTN_LOC_AEND VARCHAR2(100);
V_PSTN_LOC_BEND VARCHAR2(100);
V_PSTN_CR VARCHAR2(30);
V_PSTN_AC VARCHAR2(30);
V_BEARER_CCT_ID VARCHAR2(30);
V_DP_LOOP NUMBER;
V_DP_R_PLP_POSITION VARCHAR2(5);
V_DP_INDEX VARCHAR2(10);   
V_DP_LOC VARCHAR2(100);
V_SPLIT_INDEX VARCHAR2(10);
V_SPLITTER_EQUIP_ID NUMBER; 
V_SPLITTER_POT_OUT_ID NUMBER;              
V_SPLITTER_DSL_IN_ID NUMBER;               
V_SPLITTER_POT_IN_ID NUMBER;  
V_ADSL_CARD_SLOT VARCHAR2(100);
V_ADSL_PORT_ID NUMBER;
V_DSLAM_ADSL_PLID NUMBER;
V_DSLAM_DP_PLID NUMBER;
V_DSLAM_DP_FRAA_ID NUMBER;
V_PSTN_MIN_INDEX NUMBER ;
V_NEXT_PSTN_PORT_LINK_A NUMBER; 
V_NEXT_PSTN_PORT_LINK_B NUMBER; 
V_NEXT_PSTN_PORT_LINK_C NUMBER;
MDF_EX_FRONT_FRAA_ID NUMBER ;
PSTN_DSLAM_POTS_IN NUMBER ;
PSTN_MDF_ADSL_POT_R_FRAA_ID NUMBER;
PSTN_MDF_ADSL_POT_F_FRAA_ID NUMBER;
V_PSTN_MSAN_PL_ID NUMBER;
V_MSAN_SW_CHILD_PID NUMBER;
V_MSAN_ADSL_PLID NUMBER;
V_MSAN_DP_PLID NUMBER;
V_MSAN_DP_FRAA_ID NUMBER;

CURSOR CHK_ALREADY_REARRANGED IS
SELECT CI.CIRT_NAME 
FROM CIRCUIT_HIERARCHY CH,CIRCUITS CI
WHERE CH.CIRH_PARENT = CI.CIRT_NAME
AND CI.CIRT_TYPE = 'BEARER'
AND CH.CIRH_CHILD = V_ADSL_CCT_ID;

CURSOR POTS_IN_OUT_IN_SAME_X (IN_CIRT_NAME VARCHAR2 ) IS
SELECT
CIRT_NAME,PORL_SEQUENCE,PORL_ID,F_PORT,
F_COMM,F_PO,F_CRD_SLOT,F_EQ,F_EQ_NME,
T_PORT,T_COMM,T_PO,T_CRD_SLOT,T_EQ,T_EQ_NME
FROM
(
SELECT
CIRT_NAME,
PORL_SEQUENCE,
PORL_ID,
PLP_F.POLP_PORT_ID F_PORT,
PLP_F.POLP_COMMONPORT F_COMM,
PO_F.PORT_NAME F_PO,
PO_F.PORT_CARD_SLOT F_CRD_SLOT,
PO_F.PORT_EQUP_ID F_EQ,
F_EQUIP.EQUP_EQUT_ABBREVIATION F_EQ_NME,
PLP_T.POLP_PORT_ID T_PORT,
PLP_T.POLP_COMMONPORT T_COMM,
PO_T.PORT_NAME T_PO,
PO_T.PORT_CARD_SLOT T_CRD_SLOT,
PO_T.PORT_EQUP_ID T_EQ,
T_EQUIP.EQUP_EQUT_ABBREVIATION T_EQ_NME

FROM
CIRCUITS,
PORT_LINKS,
PORT_LINK_PORTS PLP_F,
PORT_LINK_PORTS PLP_T,
PORTS PO_F,
PORTS PO_T,
EQUIPMENT F_EQUIP,
EQUIPMENT T_EQUIP

WHERE
CIRT_NAME = IN_CIRT_NAME
AND CIRT_NAME = PORL_CIRT_NAME
AND PORL_ID = PLP_F.POLP_PORL_ID(+)
AND PORL_ID = PLP_T.POLP_PORL_ID(+)
AND PLP_F.POLP_PORT_ID = PO_F.PORT_ID
AND PLP_T.POLP_PORT_ID = PO_T.PORT_ID
AND PO_F.PORT_EQUP_ID = F_EQUIP.EQUP_ID
AND PO_T.PORT_EQUP_ID = T_EQUIP.EQUP_ID
)
WHERE
    F_COMM = 'F'
AND T_COMM = 'T'
AND F_PORT IS NOT NULL
AND T_PORT IS NOT NULL;

CURSOR GET_POTS_OUT_LINK ( IN_CRT VARCHAR2 ) IS
SELECT PORL_ID 
FROM PORT_LINKS,PORT_LINK_PORTS,PORTS
WHERE PORL_CIRT_NAME = IN_CRT AND PORL_ID = POLP_PORL_ID AND POLP_PORT_ID = PORT_ID 
AND PORT_NAME LIKE 'POTS-OUT%' AND POLP_COMMONPORT ='F';

CURSOR GET_POTS_IN_LINK ( IN_CRTT VARCHAR2 ) IS
SELECT PORL_ID 
FROM PORT_LINKS,PORT_LINK_PORTS,PORTS
WHERE PORL_CIRT_NAME = IN_CRTT AND PORL_ID = POLP_PORL_ID AND POLP_PORT_ID = PORT_ID 
AND PORT_NAME LIKE 'POTS-IN%' AND POLP_COMMONPORT ='F';

CURSOR GET_MDF_ADSL_POT_LINK ( IN_CRTTT VARCHAR2 ) IS
SELECT PORL_ID
FROM PORT_LINKS,PORT_LINK_PORTS,FRAME_APPEARANCES,FRAME_UNITS
WHERE
PORL_CIRT_NAME = IN_CRTTT AND PORL_ID = POLP_PORL_ID AND POLP_FRAA_ID = FRAA_ID
AND POLP_COMMONPORT ='F' AND FRAA_FRAU_ID = FRAU_ID AND FRAU_NAME LIKE 'MDF-ADSL-POT%';

CURSOR GET_SW_CHILD_PORT IS
SELECT PO2.PORT_ID
FROM PORTS PO,PORTS PO2,PORT_HIERARCHY PH,EQUIPMENT EQ
WHERE PO.PORT_ID = PH.PORH_PARENTID
AND PH.PORH_CHILDID = PO2.PORT_ID
AND PO2.PORT_EQUP_ID = EQ.EQUP_ID
AND PO.PORT_CIRT_NAME = V_BEARER_CCT_ID
AND PO2.PORT_NAME LIKE 'POTS-IN%'
AND EQ.EQUP_EQUT_ABBREVIATION LIKE '%MSAN%';

POTS_IN_OUT_IN_SAME_X_R POTS_IN_OUT_IN_SAME_X%ROWTYPE := NULL;

/* ADD FOR MANAGE REARRANGED CIRCUITS 10-12-2015*/
CURSOR GET_SPLITER_DATA ( IN_PSTN_CIRT IN VARCHAR2 ) IS
SELECT
PORL_ID,POLP_PORT_ID,PORT_EQUP_ID,PORT_NAME
FROM
PORT_LINKS,
PORT_LINK_PORTS,
PORTS,
CARDS,
EQUIPMENT
WHERE
    PORL_CIRT_NAME = IN_PSTN_CIRT
AND PORL_ID = POLP_PORL_ID
AND POLP_PORT_ID = PORT_ID
AND PORT_CARD_SLOT = CARD_SLOT
AND CARD_EQUP_ID = EQUP_ID
AND PORT_EQUP_ID = EQUP_ID
AND EQUP_EQUT_ABBREVIATION LIKE 'DSL_SPLITTER%';

CURSOR GET_EQUIPM_DATA ( IN_CIRT IN VARCHAR2 ) IS
SELECT
POLP_PORT_ID,POLP_PORL_ID,POLP_COMMONPORT
FROM
PORT_LINKS,
PORT_LINK_PORTS,
PORTS,
CARDS,
EQUIPMENT
WHERE
    PORL_CIRT_NAME = IN_CIRT
AND PORL_ID = POLP_PORL_ID
AND POLP_PORT_ID = PORT_ID
AND PORT_CARD_SLOT = CARD_SLOT
AND CARD_EQUP_ID = EQUP_ID
AND PORT_EQUP_ID = EQUP_ID
AND EQUP_EQUT_ABBREVIATION NOT LIKE 'DSL_SPLITTER%';

GET_SPLITER_DATA_R GET_SPLITER_DATA%ROWTYPE;
GET_EQUIPM_DATA_R GET_EQUIPM_DATA%ROWTYPE;
DSLAM_DSL_PORT NUMBER;
/* END OF ADDITION 10-12-2015*/
BEGIN

ADSL_CHK_PSTN_SO_SOP_CLOSE(P_SERV_ID,P_SERO_ID,P_SEIT_ID,P_IMPT_TASKNAME,P_WORO_ID,P_RET_CHAR,P_RET_NUMBER,P_RET_MSG);

IF P_RET_MSG IS NULL THEN  
/* GET ADSL CIRT DATA*/
SELECT SO.SERO_CIRT_NAME,REPLACE(CI.CIRT_DISPLAYNAME,'(N)','') 
INTO V_ADSL_CCT_ID,V_ADSL_DIS_NAME
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND SO.SERO_ID = P_SERO_ID;
/* CHECK ALREADY REARRANGED CIRCUIT*/
OPEN CHK_ALREADY_REARRANGED;
FETCH CHK_ALREADY_REARRANGED INTO V_ALREADY_REARRANGED;
CLOSE CHK_ALREADY_REARRANGED;

    IF V_ALREADY_REARRANGED IS NULL THEN
    /* GET RELATED EQUIPMENT*/
    SELECT EQ.EQUP_ID, EQ.EQUP_EQUT_ABBREVIATION
    INTO V_ADSL_EQUIP_ID, V_ADSL_EQUIP_ABBR
    FROM EQUIPMENT EQ,PORTS PO,PORT_LINK_PORTS PLP,PORT_LINKS PL
    WHERE EQ.EQUP_ID = PO.PORT_EQUP_ID
    AND PO.PORT_ID = PLP.POLP_PORT_ID
    AND PLP.POLP_PORL_ID = PL.PORL_ID
    AND PL.PORL_CIRT_NAME = V_ADSL_CCT_ID
    AND (PO.PORT_CARD_SLOT NOT LIKE 'D%' AND PO.PORT_CARD_SLOT NOT LIKE 'M%');
    /* GET RELATED PSTN DISPLAY NAME*/
    SELECT TRIM(SOA.SEOA_DEFAULTVALUE)
    INTO V_PSTN_DIS_NAME
    FROM SERVICE_ORDER_ATTRIBUTES SOA
    WHERE SOA.SEOA_SERO_ID = P_SERO_ID
    AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';
    /* GET RELATED PSTN CIRT NAME*/
    SELECT CI.CIRT_NAME
    INTO V_PSTN_CCT_ID
    FROM CIRCUITS CI
    WHERE CI.CIRT_DISPLAYNAME LIKE V_PSTN_DIS_NAME || '%'
    AND (CI.CIRT_STATUS NOT LIKE 'CA%' AND CI.CIRT_STATUS NOT LIKE 'PE%')
    AND CI.CIRT_DISPLAYNAME NOT LIKE '%-COPY%';
    
        IF V_ADSL_EQUIP_ABBR LIKE 'MSAN-%' THEN
        /* GET POTS-IN & POTS-OUT IN SAME X CONNECTION*/
        OPEN POTS_IN_OUT_IN_SAME_X (V_PSTN_CCT_ID);
        FETCH POTS_IN_OUT_IN_SAME_X INTO POTS_IN_OUT_IN_SAME_X_R ;
        CLOSE POTS_IN_OUT_IN_SAME_X;
            IF POTS_IN_OUT_IN_SAME_X_R.CIRT_NAME IS NOT NULL THEN
            /* DELETE FROM SIDE LINK*/
            DELETE FROM PORT_LINK_PORTS 
            WHERE POLP_PORT_ID = POTS_IN_OUT_IN_SAME_X_R.F_PORT AND POLP_PORL_ID = POTS_IN_OUT_IN_SAME_X_R.PORL_ID;
            /* DELETE TO SIDE LINK*/
            DELETE FROM PORT_LINK_PORTS 
            WHERE POLP_PORT_ID = POTS_IN_OUT_IN_SAME_X_R.T_PORT AND POLP_PORL_ID = POTS_IN_OUT_IN_SAME_X_R.PORL_ID;
            /* DELETE X CONNECTION RECORD*/
            DELETE FROM PORT_LINKS  WHERE PORL_ID = POTS_IN_OUT_IN_SAME_X_R.PORL_ID;
            /* DELETE SELF REFERAING RECORD*/
            DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_PARENT = V_PSTN_CCT_ID AND CIRH_CHILD = V_PSTN_CCT_ID;
            /* RELESE PORT*/
            UPDATE PORTS SET PORT_CIRT_NAME = NULL WHERE PORT_ID IN (POTS_IN_OUT_IN_SAME_X_R.F_PORT,POTS_IN_OUT_IN_SAME_X_R.T_PORT)
            AND PORT_NAME LIKE 'POTS-IN%';
            
            END IF;    
        END IF;

        IF V_ADSL_EQUIP_ABBR LIKE 'DSLAM-%' THEN
        /* GET PSTN POTS-OUT FRONT LINK*/
        OPEN GET_POTS_OUT_LINK(V_PSTN_CCT_ID);
        FETCH GET_POTS_OUT_LINK INTO POTS_OUT_PORL_ID;
        CLOSE GET_POTS_OUT_LINK;
        /* GET PSTN POTS-IN FRONT LINK*/
        OPEN GET_POTS_IN_LINK(V_PSTN_CCT_ID);
        FETCH GET_POTS_IN_LINK INTO POTS_IN_PORL_ID;
        CLOSE GET_POTS_IN_LINK;
        /* GET MDF-ADSL-POT FRONT LINK*/
        OPEN GET_MDF_ADSL_POT_LINK(V_PSTN_CCT_ID);
        FETCH GET_MDF_ADSL_POT_LINK INTO MDF_ADSL_POT_PORL_ID;
        CLOSE GET_MDF_ADSL_POT_LINK;
        /* DELETE FROM AND TO SIDE LINKS*/
        DELETE FROM PORT_LINK_PORTS WHERE POLP_PORL_ID IN (POTS_OUT_PORL_ID,POTS_IN_PORL_ID,MDF_ADSL_POT_PORL_ID);
        /* DELETE X CONNECTION RECORD */
        DELETE FROM PORT_LINKS WHERE PORL_ID IN (POTS_OUT_PORL_ID,POTS_IN_PORL_ID,MDF_ADSL_POT_PORL_ID);
        /* DELETE SELF REFERAING RECORD*/
        DELETE FROM CIRCUIT_HIERARCHY WHERE CIRH_PARENT = V_PSTN_CCT_ID AND CIRH_CHILD = V_PSTN_CCT_ID;
        /* NO NEED TO RELESE PORTS OR FRAME APPEARANCES. WE WILL LINK THEM AGAIN AFTER REARRANGE*/ 
        END IF;
        
        /* GET ADSL CARD SLOT AND PORT ID*/
        SELECT DISTINCT PO.PORT_CARD_SLOT,REPLACE(PO.PORT_NAME,'DSL-IN-','')
        INTO V_ADSL_POTS_CARD,V_ADSL_POTS_PORT
        FROM PORT_LINKS PL,PORT_LINK_PORTS PLP,PORTS PO
        WHERE PL.PORL_ID = PLP.POLP_PORL_ID
        AND PLP.POLP_PORT_ID = PO.PORT_ID
        AND PO.PORT_NAME LIKE 'DSL-IN-%'
        AND PL.PORL_CIRT_NAME = V_ADSL_CCT_ID;
        /* GET PSTN CARD SLOT AND PORT ID*/
        SELECT DISTINCT PO.PORT_CARD_SLOT,REPLACE(PO.PORT_NAME,'POTS-OUT-','')
        INTO V_PSTN_POTS_CARD,V_PSTN_POTS_PORT
        FROM PORT_LINKS PL,PORT_LINK_PORTS PLP,PORTS PO
        WHERE PL.PORL_ID = PLP.POLP_PORL_ID
        AND PLP.POLP_PORT_ID = PO.PORT_ID
        AND PO.PORT_NAME LIKE 'POTS-OUT-%'
        AND PL.PORL_CIRT_NAME = V_PSTN_CCT_ID;
        
        IF (V_ADSL_POTS_CARD = V_PSTN_POTS_CARD) AND (V_ADSL_POTS_PORT = V_PSTN_POTS_PORT) THEN
        /* GET ADSL CIRCUIT HEADER INFORMATION*/
        SELECT CI.CIRT_LOCN_AEND,CI.CIRT_INSERVICE,CI.CIRT_STATUS,CI.CIRT_SPED_ABBREVIATION 
        INTO V_ADSL_LOC_AEND,V_ADSL_INSERVICE_DT,V_ADSL_CCT_STATE,V_ADSL_SPEED
        FROM CIRCUITS CI
        WHERE CI.CIRT_NAME = V_ADSL_CCT_ID;
        
        P_ERROR_2 := 'adsl data select into completed';
        /* GET PSTN CIRCUIT HEADER INFORMATION*/
        SELECT CI.CIRT_LOCN_AEND,CI.CIRT_LOCN_BEND,CI.CIRT_CUSR_ABBREVIATION,CI.CIRT_ACCT_NUMBER
        INTO V_PSTN_LOC_AEND,V_PSTN_LOC_BEND,V_PSTN_CR,V_PSTN_AC
        FROM CIRCUITS CI
        WHERE CI.CIRT_NAME = V_PSTN_CCT_ID;
      
        P_ERROR_2 := 'pstn data select into completed';   
        /* GET A CIRCUIT FOR BEARER*/
        SELECT CIRT_NAME_SEQ.NEXTVAL INTO V_BEARER_CCT_ID FROM DUAL;
        /* CREATE BEARER CIRCUIT HEADER*/
        INSERT INTO CIRCUITS ( CIRT_NAME, CIRT_INSERVICE, CIRT_CUSR_ABBREVIATION, CIRT_SPED_ABBREVIATION,
        CIRT_SERE_ID, CIRT_STATUS, CIRT_EXPIRYDATE, CIRT_TYPE, CIRT_ARING_ABBREVIATION,
        CIRT_BRING_ABBREVIATION, CIRT_EMPE_ID, CIRT_COMMENT, CIRT_DECOMMISSIONED, CIRT_SERT_ABBREVIATION,
        CIRT_ACCT_NUMBER, CIRT_LOCN_AEND, CIRT_LOCN_BEND, CIRT_COMPLIANCE, CIRT_PREFIX, CIRT_SUFFIX,
        CIRT_SERIALNO, CIRT_CLCISVCCODE, CIRT_CLCISVCMOD, CIRT_CLCICOMPANY, CIRT_CLCISEGMENT,
        CIRT_OUTSERVICE, CIRT_SLRL_NAME, CIRT_DISPLAYNAME, CIRT_NOTIFYDATE, CIRT_SERV_ID,
        CIRT_RESERVATIONID, CIRT_RELM_NAME, CIRT_REALM, CIRT_EQUT_LEVEL ) VALUES ( 
        V_BEARER_CCT_ID,  V_ADSL_INSERVICE_DT, V_PSTN_CR, 'ADSL', NULL, V_ADSL_CCT_STATE,  NULL, 'BEARER', NULL, NULL, 'CL_ADM', 
        NULL,NULL, 'ADSL', V_PSTN_AC, V_PSTN_LOC_BEND, V_ADSL_LOC_AEND, 'ITU', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
        V_PSTN_LOC_AEND || ' ' || V_PSTN_LOC_BEND|| ' ' || ' ADSL ' ||  V_ADSL_DIS_NAME, NULL, NULL, NULL, NULL, NULL, NULL); 
        /* FETCH PSTN DP INFORMATION*/
        SELECT FA.FRAA_POSITION,PLP.POLP_COMMONPORT,FC.FRAC_INDEX,FC.FRAC_LOCN_TTNAME
        INTO V_DP_LOOP,V_DP_R_PLP_POSITION,V_DP_INDEX,V_DP_LOC
        FROM FRAME_CONTAINERS FC,FRAME_UNITS FU,FRAME_APPEARANCES FA,PORT_LINK_PORTS PLP,PORT_LINKS PL
        WHERE FC.FRAC_ID = FU.FRAU_FRAC_ID
        AND FU.FRAU_ID = FA.FRAA_FRAU_ID
        AND FA.FRAA_ID = PLP.POLP_FRAA_ID
        AND PLP.POLP_PORL_ID = PL.PORL_ID
        AND FC.FRAC_FRAN_NAME = 'DP'
        AND FA.FRAA_SIDE = 'REAR'
        AND PL.PORL_CIRT_NAME = V_PSTN_CCT_ID;
        
        P_ERROR_2 := 'pstn dp loop select into completed'; 
        /* CALCULATE INDEX FOR SPLITER */
        SELECT LPAD(NVL(MAX(EQ.EQUP_INDEX),0)+1,3,0)
        INTO V_SPLIT_INDEX
        FROM EQUIPMENT EQ
        WHERE EQ.EQUP_LOCN_TTNAME = V_DP_LOC
        AND EQ.EQUP_EQUT_ABBREVIATION = 'DSL_SPLITTER'
        AND EQ.EQUP_INDEX NOT LIKE '%-%';  
        /* GET A ID FOR SPLITER*/
        SELECT EQUP_ID_SEQ.NEXTVAL INTO V_SPLITTER_EQUIP_ID FROM DUAL;
        /* CREATE SPLITER*/
        INSERT INTO EQUIPMENT ( EQUP_ID, EQUP_EQUT_ABBREVIATION, EQUP_INDEX, EQUP_LOCN_TTNAME,
        EQUP_POSITION, EQUP_STATUS, EQUP_MANS_NAME, EQUP_NODEID, EQUP_IPADDRESS, EQUP_CUSR_ABBREVIATION,
        EQUP_MANR_ABBREVIATION, EQUP_EQUM_MODEL, EQUP_SERIALNUMBER, EQUP_INSERVICE, EQUP_SUPPLIER,
        EQUP_DEALER, EQUP_MAINTAINER, EQUP_COMMENTS, EQUP_WORG_NAME, EQUP_EXCC_CODE, EQUP_RELM_NAME,
        EQUP_DISCSTATUS, EQUP_DISCSTATUSDATE, EQUP_IPREGION ) VALUES
        ( V_SPLITTER_EQUIP_ID, 'DSL_SPLITTER', V_SPLIT_INDEX, V_DP_LOC, NULL, 'INSERVICE', NULL, NULL, NULL, 'SLT',
        'GENERIC', NULL, NULL,  SYSDATE, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

        P_ERROR_2 := 'SPLITTER Equip Done';
        /* CREATE A CARD FOR SPLITER*/
        INSERT INTO CARDS ( CARD_EQUP_ID, CARD_SLOT, CARD_NAME, CARD_LOCN_TTNAME, CARD_MODEL, CARD_REVISION,
        CARD_SERIAL, CARD_DEVIATION, CARD_STATUS, CARD_UNITSTATUS, CARD_OLD_STATUS, CARD_MODE,
        CARD_NEMSNAME, PARENT_CARD_SLOT ) VALUES ( V_SPLITTER_EQUIP_ID, 'NA', 'MAIN_UNIT', V_DP_LOC,
        NULL, NULL, NULL, NULL, 'INSERVICE', NULL, NULL, 'NEITHER', NULL, NULL); 
      
        P_ERROR_2 := 'SPLITTER Card Done';
        /* GET A PORT-ID FOR POTS-OUT*/
        SELECT PORT_ID_SEQ.NEXTVAL INTO V_SPLITTER_POT_OUT_ID FROM DUAL;
        /* CREATE POTS-OUT PORT*/
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        V_SPLITTER_POT_OUT_ID, V_SPLITTER_EQUIP_ID, 'POTS-OUT', 'NA', NULL, V_BEARER_CCT_ID, NULL, NULL, 'PARENT', NULL,'INSERVICE',
        'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL);  
        
        P_ERROR_2 := 'SPLITTER POTS-OUT Done';
        /* GET A PORT-ID FOR DSL-IN*/
        SELECT PORT_ID_SEQ.NEXTVAL INTO V_SPLITTER_DSL_IN_ID FROM DUAL;
        /* CREATE DSL-IN PORT*/
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        V_SPLITTER_DSL_IN_ID, V_SPLITTER_EQUIP_ID, 'DSL-IN', 'NA', NULL, V_ADSL_CCT_ID, NULL, NULL, 'CHILD', NULL, 'INSERVICE', 
        'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL); 
     
        P_ERROR_2 := 'SPLITTER DSL-IN Done';
        /* GET A PORT-ID FOR POTS-IN*/
        SELECT PORT_ID_SEQ.NEXTVAL INTO V_SPLITTER_POT_IN_ID FROM DUAL;
        /* CREATE POTS-IN PORT*/
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        V_SPLITTER_POT_IN_ID, V_SPLITTER_EQUIP_ID, 'POTS-IN', 'NA', NULL, V_PSTN_CCT_ID, NULL, NULL, 'CHILD', NULL, 'INSERVICE', 
        'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL);  
     
        P_ERROR_2 := 'SPLITTER POTS-IN Done';
        /* LINK CHILD DSL-IN TO PARENT POTS-OUT PORT*/
        INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
        V_SPLITTER_POT_OUT_ID, V_SPLITTER_DSL_IN_ID); 
        /* LINK CHILD POTS-IN TO PARENT POTS-OUT PORT*/
        INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
        V_SPLITTER_POT_OUT_ID, V_SPLITTER_POT_IN_ID); 
     
        P_ERROR_2 := 'SPLITTER PORT HIERARCHY DONE';
        /* IF ADSL->PSTN, THEN CHANGE IT ADSL->BEARER*/
        UPDATE CIRCUIT_HIERARCHY CH
        SET CH.CIRH_PARENT = V_BEARER_CCT_ID
        WHERE CH.CIRH_PARENT = V_PSTN_CCT_ID; 
      
            IF SQL%NOTFOUND THEN
            /* IF ABOUT RECORD NOT EXSISTS THEN CREATE IT*/
            INSERT INTO CIRCUIT_HIERARCHY ( CIRH_PARENT, CIRH_CHILD, CIRH_TRIBUTARY, CIRH_PARENTORDER,CIRH_PATH ) VALUES ( 
            V_BEARER_CCT_ID, V_ADSL_CCT_ID, NULL, 1, NULL);  
            END IF;
        /* CRETE PSTN'S PARENT AS BEARER*/
        INSERT INTO CIRCUIT_HIERARCHY ( CIRH_PARENT, CIRH_CHILD, CIRH_TRIBUTARY, CIRH_PARENTORDER,CIRH_PATH ) VALUES ( 
        V_BEARER_CCT_ID, V_PSTN_CCT_ID, NULL, 1, NULL);
        /* GET ADSL CARD SLOT & PORT FOR SEPARATE MSAN & DSLAM*/
        SELECT DISTINCT PO.PORT_CARD_SLOT,PO.PORT_ID
        INTO V_ADSL_CARD_SLOT,V_ADSL_PORT_ID
        FROM PORTS PO,PORT_LINK_PORTS PLP,PORT_LINKS PL
        WHERE PL.PORL_ID = PLP.POLP_PORL_ID
        AND PLP.POLP_PORT_ID = PO.PORT_ID
        AND (PO.PORT_CARD_SLOT NOT LIKE 'DP%' AND PO.PORT_CARD_SLOT NOT LIKE 'NA')
        AND PL.PORL_CIRT_NAME = V_ADSL_CCT_ID;
        
            IF V_ADSL_CARD_SLOT LIKE 'M%' OR V_ADSL_CARD_SLOT LIKE 'D%' OR V_ADSL_CARD_SLOT LIKE 'P%' THEN
            /* TRANSFER PSTN X CONNECTION TO BEARER EXCLUDING MDF EXCHANGE SIDE*/
            UPDATE PORT_LINKS PL
            SET PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
            WHERE PL.PORL_CIRT_NAME = V_PSTN_CCT_ID
            AND PL.PORL_ID NOT IN
            (SELECT PL.PORL_ID
            FROM FRAME_CONTAINERS FC,FRAME_UNITS FU,FRAME_APPEARANCES FA,PORT_LINK_PORTS PLP,PORT_LINKS PL
            WHERE FC.FRAC_ID = FU.FRAU_FRAC_ID
            AND FU.FRAU_ID = FA.FRAA_FRAU_ID
            AND FA.FRAA_ID = PLP.POLP_FRAA_ID
            AND PLP.POLP_PORL_ID = PL.PORL_ID
            AND FC.FRAC_FRAN_NAME = 'MDF'
            AND (FU.FRAU_NAME LIKE '%EX%' OR FU.FRAU_NAME LIKE '%ADSL%POT%')
            AND PL.PORL_CIRT_NAME = V_PSTN_CCT_ID);
            
                IF SQL%NOTFOUND THEN
                P_ERROR_MSG := 'Wrong Crossconnections';  
                END IF; 
            /* RESERVE TRANSFERED FRAME APPERANCE TO BEARER*/
            UPDATE FRAME_APPEARANCES FA
            SET FA.FRAA_CIRT_NAME = V_BEARER_CCT_ID
            WHERE FA.FRAA_ID IN
            (SELECT PLP.POLP_FRAA_ID
            FROM PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE PL.PORL_ID = PLP.POLP_PORL_ID
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
            AND PLP.POLP_FRAA_ID IS NOT NULL); 
            /* RESERVE TRANSFERED PORTS TO BEARER*/
            UPDATE PORTS PO
            SET PO.PORT_CIRT_NAME = V_BEARER_CCT_ID
            WHERE PO.PORT_ID IN 
            (SELECT PLP.POLP_PORT_ID
            FROM PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE PL.PORL_ID = PLP.POLP_PORL_ID
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
            AND PLP.POLP_PORT_ID IS NOT NULL);
            /* DSL-IN TRANSFER TO TO-SIDE */
            UPDATE PORT_LINK_PORTS PLP
            SET PLP.POLP_COMMONPORT = 'T'
            WHERE PLP.POLP_PORT_ID = V_ADSL_PORT_ID;
            /* GET ADSL X CONNECTION'S LINK ID*/
            SELECT DISTINCT PLP.POLP_PORL_ID
            INTO V_DSLAM_ADSL_PLID 
            FROM PORT_LINK_PORTS PLP,PORT_LINKS PL
            WHERE PLP.POLP_PORL_ID = PL.PORL_ID
            AND PLP.POLP_PORT_ID = V_ADSL_PORT_ID
            AND PL.PORL_CIRT_NAME = V_ADSL_CCT_ID;
            /* LINK SPLITEER TO ADSL X CONNECTION*/
            UPDATE PORT_LINK_PORTS PLP
            SET PLP.POLP_PORT_ID = V_SPLITTER_DSL_IN_ID
            WHERE PLP.POLP_COMMONPORT = 'F' 
            AND PLP.POLP_PORL_ID = V_DSLAM_ADSL_PLID;
            /* IF NOT EXSISTS INSERT THE RECORD*/
                IF SQL%NOTFOUND THEN
                INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
                POLP_FRAA_ID ) VALUES ( v_splitter_dsl_in_id,v_dslam_adsl_plid , 'F', NULL);
                END IF;
            /* GET THE DP'S PORT LINK AND FRAME APPEARANCE*/
            SELECT PL.PORL_ID,FA.FRAA_ID
            INTO V_DSLAM_DP_PLID,V_DSLAM_DP_FRAA_ID
            FROM FRAME_CONTAINERS FC,FRAME_UNITS FU,FRAME_APPEARANCES FA,PORT_LINK_PORTS PLP,PORT_LINKS PL
            WHERE FC.FRAC_ID = FU.FRAU_FRAC_ID
            AND FU.FRAU_ID = FA.FRAA_FRAU_ID
            AND FA.FRAA_ID = PLP.POLP_FRAA_ID
            AND PLP.POLP_PORL_ID = PL.PORL_ID
            AND FC.FRAC_FRAN_NAME = 'DP'
            AND FA.FRAA_SIDE = 'FRONT'
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID;
            
            P_ERROR_2 := 'dslam dp select into completed';

                IF V_DP_R_PLP_POSITION = 'T' THEN
                /* UPDATE DP REAR AS FROM */
                UPDATE PORT_LINK_PORTS PLP
                SET PLP.POLP_COMMONPORT = 'F'
                WHERE PLP.POLP_FRAA_ID = V_DSLAM_DP_FRAA_ID
                AND PLP.POLP_PORL_ID = V_DSLAM_DP_PLID;
                /* LINK SPLITER POTS-OUT*/
                INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
                POLP_FRAA_ID ) VALUES ( V_SPLITTER_POT_OUT_ID, V_DSLAM_DP_PLID, 'T', NULL);             
                ELSE
                /* UPDATE DP REAR AS TO */
                UPDATE PORT_LINK_PORTS PLP
                SET PLP.POLP_COMMONPORT = 'T'
                WHERE PLP.POLP_FRAA_ID = V_DSLAM_DP_FRAA_ID
                AND PLP.POLP_PORL_ID = V_DSLAM_DP_PLID;
                /* LINK SPLITER POTS-OUT*/
                INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
                POLP_FRAA_ID ) VALUES ( V_SPLITTER_POT_OUT_ID, V_DSLAM_DP_PLID, 'F', NULL); 
                END IF;
            /* GET LOWEST PORT LINK SEQUENCE OF PSTN */    
            SELECT MIN(PORL_SEQUENCE) INTO V_PSTN_MIN_INDEX   
            FROM PORT_LINKS 
            WHERE PORL_CIRT_NAME = V_PSTN_CCT_ID;
            /* GET PORT LINK ID FOR SPLITER POTS-IN */
            SELECT PORL_ID_SEQ.NEXTVAL INTO V_NEXT_PSTN_PORT_LINK_A FROM DUAL;
            /* GET PORT LINK ID FOR DSLAM POTS-IN */
            SELECT PORL_ID_SEQ.NEXTVAL INTO V_NEXT_PSTN_PORT_LINK_B FROM DUAL;
            /* GET PORT LINK ID FOR MDF ADSL POT */
            SELECT PORL_ID_SEQ.NEXTVAL INTO V_NEXT_PSTN_PORT_LINK_C FROM DUAL;
            /* CREATE PORT LINK RECORD FOR SPLITER POTS-IN */
            INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
            VALUES ( V_NEXT_PSTN_PORT_LINK_A,V_PSTN_CCT_ID,(V_PSTN_MIN_INDEX-3),'PHYSICAL', NULL,'Y');
            /* CREATE PORT LINK RECORD FOR DSLAM POTS-IN*/
            INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
            VALUES ( V_NEXT_PSTN_PORT_LINK_B,V_PSTN_CCT_ID,(V_PSTN_MIN_INDEX-2),'PHYSICAL', NULL,'Y');
            /* CREATE PORT LINK RECORD FOR ADSL POT */
            INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
            VALUES ( V_NEXT_PSTN_PORT_LINK_C,V_PSTN_CCT_ID,(V_PSTN_MIN_INDEX-1),'JUMPER', NULL,'Y');
            /* LINK SPLITER POTS-IN TO X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID ) VALUES 
            ( V_SPLITTER_POT_IN_ID, V_NEXT_PSTN_PORT_LINK_A ,'F', NULL );
            /* GET MDF-EX-FRONT FRAA_ID*/
            SELECT   FRAA_ID  INTO MDF_EX_FRONT_FRAA_ID FROM FRAME_APPEARANCES WHERE FRAA_PHYC_ID IN
            (SELECT FRAA_PHYC_ID FROM
            PORT_LINKS,PORT_LINK_PORTS,FRAME_APPEARANCES,FRAME_UNITS,FRAME_CONTAINERS
            WHERE PORL_CIRT_NAME = V_PSTN_CCT_ID
            AND POLP_PORL_ID = PORL_ID AND POLP_FRAA_ID = FRAA_ID AND FRAA_FRAU_ID = FRAU_ID
            AND FRAU_FRAC_ID = FRAC_ID AND FRAC_FRAN_NAME = 'MDF' AND FRAU_NAME LIKE '%EX%' AND POLP_COMMONPORT = 'F')
            AND FRAA_SIDE = 'FRONT';
            /* RESERVE FRAME APPEARANCE FOR PSTN CIRCUIT*/
            UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = V_PSTN_CCT_ID
            WHERE FRAA_ID = MDF_EX_FRONT_FRAA_ID ;
            /* LINK MDF-EX-FRONT TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID ) VALUES 
            ( NULL , V_NEXT_PSTN_PORT_LINK_C ,'T', MDF_EX_FRONT_FRAA_ID );
            /* GET DSLAM POTS-IN PORT ID*/
            SELECT PO_B.PORT_ID INTO PSTN_DSLAM_POTS_IN
            FROM
            PORT_LINKS,PORT_LINK_PORTS,PORTS PO_A,
            EQUIPMENT,PORT_HIERARCHY,    PORTS PO_B
            WHERE
            PORL_CIRT_NAME =  V_BEARER_CCT_ID
            AND POLP_PORL_ID = PORL_ID
            AND PO_A.PORT_ID = POLP_PORT_ID
            AND EQUP_ID = PO_A.PORT_EQUP_ID
            AND EQUP_EQUT_ABBREVIATION LIKE 'DSLAM%'
            AND PO_A.PORT_NAME LIKE  'POTS-OUT%'
            AND PORH_PARENTID = PO_A.PORT_ID
            AND PORH_CHILDID = PO_B.PORT_ID
            AND PO_B.PORT_NAME LIKE 'POTS-IN%' ;
            /* RESERVE PORT FOR PSTN CIRCUIT*/
            UPDATE PORTS SET PORT_CIRT_NAME = V_PSTN_CCT_ID WHERE PORT_ID = PSTN_DSLAM_POTS_IN;
            /* LINK DSLAM POTS-IN TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID ) VALUES 
            ( PSTN_DSLAM_POTS_IN ,  V_NEXT_PSTN_PORT_LINK_B ,'F', NULL );
            /* USING UNNAMED CONNECTION GET MDF ADSL POT REAR FRAA_ID*/
            SELECT FRAA_ID INTO PSTN_MDF_ADSL_POT_R_FRAA_ID 
            FROM 
            EQUIPMENT,CARDS,PORTS,FRAME_APPEARANCES
            WHERE
            EQUP_ID = V_ADSL_EQUIP_ID
            AND EQUP_ID = CARD_EQUP_ID
            AND EQUP_ID = PORT_EQUP_ID
            AND CARD_SLOT = PORT_CARD_SLOT
            AND PORT_CIRT_NAME = V_PSTN_CCT_ID
            AND (PORT_CACE_ID+1 ) = FRAA_CACE_ID;
            /* RESERVE FRAME APPEARANCE FOR PSTN X CONNECTION*/
            UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = V_PSTN_CCT_ID
            WHERE FRAA_ID = PSTN_MDF_ADSL_POT_R_FRAA_ID ;
            /* LINK TO MDF ADSL POT REAR TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID ) VALUES 
            (NULL , V_NEXT_PSTN_PORT_LINK_B ,'T', PSTN_MDF_ADSL_POT_R_FRAA_ID );
            /* GET MDF ADSL POT FRONT FRAA_ID*/
            SELECT FRAA_ID INTO PSTN_MDF_ADSL_POT_F_FRAA_ID
            FROM FRAME_APPEARANCES WHERE FRAA_PHYC_ID IN
            (SELECT FRAA_PHYC_ID FROM FRAME_APPEARANCES WHERE FRAA_ID = PSTN_MDF_ADSL_POT_R_FRAA_ID)
            AND FRAA_ID <> PSTN_MDF_ADSL_POT_R_FRAA_ID;
            /* RESERVE FRAME APPEARANCE FOR PSTN X CONNECTION*/
            UPDATE FRAME_APPEARANCES SET FRAA_CIRT_NAME = V_PSTN_CCT_ID
            WHERE FRAA_ID = PSTN_MDF_ADSL_POT_F_FRAA_ID;
            /* LINK TO MDF ADSL POT FRONT TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID ) VALUES 
            (NULL , V_NEXT_PSTN_PORT_LINK_C ,'F', PSTN_MDF_ADSL_POT_F_FRAA_ID );

            ELSIF V_ADSL_CARD_SLOT LIKE 'Z%' OR V_ADSL_CARD_SLOT LIKE 'A%' OR V_ADSL_CARD_SLOT LIKE 'H%' THEN
            
            /* TRANSFER PSTN X CONNECTION TO BEARER*/
            UPDATE PORT_LINKS PL SET PL.PORL_CIRT_NAME = V_BEARER_CCT_ID 
            WHERE PL.PORL_CIRT_NAME = V_PSTN_CCT_ID;
            
            IF SQL%NOTFOUND THEN
            P_RET_MSG := 'Wrong Crossconnections';  
            END IF;
            /* TRANSFER FRAME APPEARANCE FROM PSTN TO BEARER*/
            UPDATE FRAME_APPEARANCES FA
            SET FA.FRAA_CIRT_NAME = V_BEARER_CCT_ID
            WHERE FA.FRAA_CIRT_NAME = V_PSTN_CCT_ID
            AND FA.FRAA_ID IN
            (SELECT PLP.POLP_FRAA_ID
            FROM PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE PL.PORL_ID = PLP.POLP_PORL_ID
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
            AND FA.FRAA_ID IS NOT NULL); 
            /* TRANSFER PORTS FROM PSTN TO BEARERE*/
            UPDATE PORTS PO
            SET PO.PORT_CIRT_NAME = V_BEARER_CCT_ID
            WHERE PO.PORT_CIRT_NAME = V_PSTN_CCT_ID
            AND PO.PORT_ID IN 
            (SELECT PLP.POLP_PORT_ID
            FROM PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE PL.PORL_ID = PLP.POLP_PORL_ID
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
            AND PLP.POLP_PORT_ID IS NOT NULL);
            /* GET PORT LINK ID FOR PSTN*/
            SELECT PORL_ID_SEQ.NEXTVAL INTO V_PSTN_MSAN_PL_ID FROM DUAL;
            /* CREATE X CONNECTION LINE TO PSTN */
            INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
            VALUES ( V_PSTN_MSAN_PL_ID, V_PSTN_CCT_ID, '10', 'PHYSICAL', NULL, 'Y');
            /* GET MSAN CHILD PORT*/
            OPEN GET_SW_CHILD_PORT;
            FETCH GET_SW_CHILD_PORT INTO V_MSAN_SW_CHILD_PID;
            CLOSE GET_SW_CHILD_PORT;
            /* RESERVE CHILD PORT */
            UPDATE PORTS PO
            SET PO.PORT_CIRT_NAME = V_PSTN_CCT_ID
            WHERE PO.PORT_ID = V_MSAN_SW_CHILD_PID;
            /* LINK SWITCH CHILD PORT TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
            POLP_FRAA_ID ) VALUES ( V_MSAN_SW_CHILD_PID, V_PSTN_MSAN_PL_ID, 'T', NULL); 
            /* LINK SPLITER PORT TO PSTN X CONNECTION*/
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
            POLP_FRAA_ID ) VALUES ( V_SPLITTER_POT_IN_ID, V_PSTN_MSAN_PL_ID, 'F', NULL);
            /* MOVE ADSL SWITCH PORT TO X CONNECTION TO-SIDE*/
            UPDATE PORT_LINK_PORTS PLP
            SET PLP.POLP_COMMONPORT = 'T'
            WHERE PLP.POLP_PORT_ID = V_ADSL_PORT_ID;
            /* GET ADSL PORT LINK ID*/
            SELECT PLP.POLP_PORL_ID
            INTO V_MSAN_ADSL_PLID
            FROM PORT_LINK_PORTS PLP,PORT_LINKS PL
            WHERE PLP.POLP_PORL_ID = PL.PORL_ID
            AND PL.PORL_CIRT_NAME = V_ADSL_CCT_ID
            AND PLP.POLP_PORT_ID = V_ADSL_PORT_ID;
     
            P_ERROR_2 := 'MSAN ADSL PLID';
            /* LINK SPLITER PORT TO ADSL X CONNECTION  */
            INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
            POLP_FRAA_ID ) VALUES ( V_SPLITTER_DSL_IN_ID,V_MSAN_ADSL_PLID , 'F', NULL);
            /* GET DP CONNECTION DATA */ 
            SELECT PL.PORL_ID,FA.FRAA_ID
            INTO V_MSAN_DP_PLID,V_MSAN_DP_FRAA_ID
            FROM FRAME_CONTAINERS FC,FRAME_UNITS FU,FRAME_APPEARANCES FA,PORT_LINK_PORTS PLP,PORT_LINKS PL
            WHERE FC.FRAC_ID = FU.FRAU_FRAC_ID
            AND FU.FRAU_ID = FA.FRAA_FRAU_ID
            AND FA.FRAA_ID = PLP.POLP_FRAA_ID
            AND PLP.POLP_PORL_ID = PL.PORL_ID
            AND FC.FRAC_FRAN_NAME = 'DP'
            AND FA.FRAA_SIDE = 'FRONT'
            AND PL.PORL_CIRT_NAME = V_BEARER_CCT_ID;
     
            P_ERROR_2 := 'MSAN DP';
                /* SET PORT-LINK CONNECTION SIDE */
                IF V_DP_R_PLP_POSITION = 'T' THEN
                UPDATE PORT_LINK_PORTS PLP
                SET PLP.POLP_COMMONPORT = 'F'
                WHERE PLP.POLP_FRAA_ID = V_MSAN_DP_FRAA_ID
                AND PLP.POLP_PORL_ID = V_MSAN_DP_PLID;
                /* INSERT SPLITER POTS OUT */
                INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
                POLP_FRAA_ID ) VALUES ( V_SPLITTER_POT_OUT_ID, V_MSAN_DP_PLID, 'T', NULL); 
                ELSE
                /* SET PORT-LINK CONNECTION SIDE */
                UPDATE PORT_LINK_PORTS PLP
                SET PLP.POLP_COMMONPORT = 'T'
                WHERE PLP.POLP_FRAA_ID = V_MSAN_DP_FRAA_ID
                AND PLP.POLP_PORL_ID = V_MSAN_DP_PLID;
                /* INSERT SPLITER POTS OUT */
                INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
                POLP_FRAA_ID ) VALUES ( V_SPLITTER_POT_OUT_ID, V_MSAN_DP_PLID, 'F', NULL); 
                END IF;
        
            ELSE
            P_ERROR_MSG := 'Wrong Card Type: ' || V_ADSL_CARD_SLOT;
            END IF;
            
            IF P_ERROR_MSG IS NULL THEN
            P_RET_MSG  := '';
            ELSE
            P_RET_MSG  := 'ADSL Bearer creation failed. ' || P_ERROR_MSG;
            END IF;
        
        ELSE
        P_RET_MSG  := 'ADSL Circuit DSL-IN Card and port not match with PSTN POTS-IN card and port. ' || P_ERROR_MSG;
        END IF;
    ELSE
    -- REARRANGED SCENARIO
    --GET ADSL CIRT DATA
    SELECT SO.SERO_CIRT_NAME,REPLACE(CI.CIRT_DISPLAYNAME,'(N)','') 
    INTO V_ADSL_CCT_ID,V_ADSL_DIS_NAME
    FROM SERVICE_ORDERS SO,CIRCUITS CI
    WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
    AND SO.SERO_ID = P_SERO_ID;
    --GET RELATED PSTN DISPLAY NAME
    SELECT TRIM(SOA.SEOA_DEFAULTVALUE)
    INTO V_PSTN_DIS_NAME
    FROM SERVICE_ORDER_ATTRIBUTES SOA
    WHERE SOA.SEOA_SERO_ID = P_SERO_ID
    AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';
    --GET RELATED PSTN CIRT NAME
    SELECT CI.CIRT_NAME
    INTO V_PSTN_CCT_ID
    FROM CIRCUITS CI
    WHERE CI.CIRT_DISPLAYNAME LIKE V_PSTN_DIS_NAME || '%'
    AND (CI.CIRT_STATUS NOT LIKE 'CA%' AND CI.CIRT_STATUS NOT LIKE 'PE%')
    AND CI.CIRT_DISPLAYNAME NOT LIKE '%-COPY%';   
    --GET THE SPLITER OF ADSL    
    OPEN GET_SPLITER_DATA (V_ADSL_CCT_ID);
    FETCH GET_SPLITER_DATA INTO GET_SPLITER_DATA_R;
    CLOSE GET_SPLITER_DATA;

        IF GET_SPLITER_DATA_R.PORL_ID IS NULL THEN 
        -- SPLITER NOT AVILABLE IN ADSL X CONNECTION
            --GET THE SPLITER OF PSTN
            OPEN GET_SPLITER_DATA (V_PSTN_CCT_ID);
            FETCH GET_SPLITER_DATA INTO GET_SPLITER_DATA_R;
            CLOSE GET_SPLITER_DATA;
            -- GET DSL_IN PORT
            SELECT PORH_CHILDID INTO DSLAM_DSL_PORT FROM PORT_HIERARCHY 
            WHERE PORH_CHILDID <> GET_SPLITER_DATA_R.POLP_PORT_ID
            AND PORH_PARENTID = (SELECT PORH_PARENTID FROM PORT_HIERARCHY WHERE PORH_CHILDID = GET_SPLITER_DATA_R.POLP_PORT_ID);    
            -- CHECK SWITCH PORT SIDE    
            OPEN GET_EQUIPM_DATA (V_ADSL_CCT_ID);
            FETCH GET_EQUIPM_DATA INTO GET_EQUIPM_DATA_R;
            CLOSE GET_EQUIPM_DATA;
        
             IF GET_EQUIPM_DATA_R.POLP_COMMONPORT = 'F' THEN 
              --IF SWITCH PORT SIDE IN FROM SIDE THEN TRANSFER TO TO SIDE     
              UPDATE PORT_LINK_PORTS SET POLP_COMMONPORT = 'T'
              WHERE POLP_PORT_ID = GET_EQUIPM_DATA_R.POLP_PORT_ID
              AND POLP_PORL_ID = GET_EQUIPM_DATA_R.POLP_PORL_ID; 
             END IF;
         -- LINK SPLITER TO ADSL X CONNECTION     
         INSERT INTO PORT_LINK_PORTS (POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT)
         VALUES (DSLAM_DSL_PORT,GET_EQUIPM_DATA_R.POLP_PORL_ID,'F');       
        END IF; 
    
    END IF;

ELSE
P_RET_MSG  := 'ADSL Bearer creation failed. ' || P_RET_MSG;
END IF;   

EXCEPTION  
WHEN OTHERS THEN
 
    P_ERROR_MSG := ' CRM ADSL REARRANGEMENT FAILED : ' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM || ' Failed at ' || P_ERROR_2;
    P_RET_MSG := P_ERROR_MSG;  

END ADSL_BEARER_CREATION_AUTO;
--- 18-01-2013 Samankula Owitipana
--- 03-01-2014 Edited -----
--- 13-10-2014 Edited -----
--- 05-08-2015 DINESH PERERA 
--- 12-11-2015 DINESH PERERA ( RE-WRITTEN )

-- Jayan Liyanage 2012/08/16
PROCEDURE D_PREMIUM_VPN_X_CONNE_WG_CHG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2)IS
v_equip_type              VARCHAR2 (100); v_eq_loc_name             VARCHAR2 (100); v_service_type            VARCHAR2 (100); v_service_order           VARCHAR2 (100);
v_service_order_area      VARCHAR2 (100); v_rtom_code               VARCHAR2 (100); v_lea_code                VARCHAR2 (100); v_work_group              VARCHAR2 (100); v_work_group_mdf          VARCHAR2 (100);
v_location                VARCHAR2 (100); v_main_node               VARCHAR2 (100); v_sub_node                VARCHAR2 (100); v_acc_nw                  VARCHAR2 (100);
v_acc_bearer_status       VARCHAR2 (100); v_mig_type                VARCHAR2 (100); v_access_bear_id          VARCHAR2 (100); v_ch_dis                  VARCHAR2 (100);v_access_id                VARCHAR2 (100);
v_cir_trib_status         VARCHAR2 (100); v_cur_nof_copper          VARCHAR2 (100); v_pre_nof_copper          VARCHAR2 (100); v_access_node_chg         VARCHAR2 (100);
v_no_of_copper_pair_cur   VARCHAR2 (100); v_no_of_copper_pair_pre   VARCHAR2 (100); v_new_cir_id              VARCHAR2 (100);    v_new_Cir_Name            VARCHAR2 (100);           
v_ch_dis_p                VARCHAR2 (100); v_cir_trib_status_p       VARCHAR2 (100); v_pre_eq                  VARCHAR2 (100); v_acc_nw_pre                 VARCHAR2 (100);
v_pre_location            VARCHAR2 (100); v_location_pre            VARCHAR2 (100);  v_pre_main_node    VARCHAR2 (100);  v_pre_sub_node     VARCHAR2 (100);
v_access_medium            VARCHAR2 (100);

CURSOR cur_equi_type IS
SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname FROM service_orders so, ports p, equipment e
WHERE so.sero_cirt_name = p.port_cirt_name AND (   e.equp_equt_abbreviation LIKE 'MSAN%'OR e.equp_equt_abbreviation LIKE 'DSLAM%'OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%')AND p.port_equp_id = e.equp_id AND so.sero_id = p_sero_id;

CURSOR cur_tributer (parent_name VARCHAR2,v_new_cir_id varchar2 )IS
SELECT DISTINCT ci.cirt_displayname, ci.cirt_status FROM circuits c, circuit_hierarchy ch, circuits ci
WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name
AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')
AND (   ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%'
)AND ci.CIRT_DISPLAYNAME <> v_new_cir_id AND c.cirt_displayname = parent_name;
CURSOR cur_tributer_p (parent_pre_name VARCHAR2)IS
SELECT DISTINCT ci.cirt_displayname, ci.cirt_status FROM circuits c, circuit_hierarchy ch, circuits ci
WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name
AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')
AND (   ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%'
)AND c.cirt_displayname = parent_pre_name;

CURSOR cur_eq_pre (Parent_i VARCHAR2)IS
SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname
FROM  ports p, equipment e,circuits ci
WHERE ci.cirt_name = p.port_cirt_name AND
(   e.equp_equt_abbreviation LIKE 'MSAN%'OR e.equp_equt_abbreviation LIKE 'DSLAM%'OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%')
AND p.port_equp_id = e.equp_id AND ci.cirt_displayname = Parent_i;


BEGIN
OPEN cur_equi_type;FETCH cur_equi_type INTO v_equip_type, v_eq_loc_name;CLOSE cur_equi_type;
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_area_code INTO v_service_order_area FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_acc_nw,v_acc_nw_pre FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';
SELECT soa.seoa_defaultvalue INTO v_mig_type FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'MIGRATION TYPE';
SELECT soa.seoa_defaultvalue INTO v_acc_bearer_status FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS BEARER STATUS';
SELECT soa.seoa_defaultvalue, soa.seoa_prev_value INTO v_cur_nof_copper, v_pre_nof_copper FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS';
SELECT soa.seoa_defaultvalue INTO v_access_bear_id FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS BEARER ID';
SELECT soa.seoa_prev_value INTO v_access_id FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID';
SELECT DISTINCT c.cirt_displayname into v_new_Cir_Name FROM service_orders so,circuits c where so.sero_cirt_name = c.cirt_name and  so.sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue INTO v_access_node_chg FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS NODE CHANGE?';
SELECT soa.seoa_defaultvalue, soa.seoa_prev_value INTO v_no_of_copper_pair_cur, v_no_of_copper_pair_pre FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes,ar.area_code INTO v_rtom_code, v_lea_code
FROM areas ar WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';
SELECT wg.worg_name INTO v_work_group_mdf FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'MDF' || '%';
SELECT SUBSTR (v_eq_loc_name, 1, INSTR (v_eq_loc_name, '-NODE', '1') - 1) AS node INTO v_location FROM DUAL;
SELECT TRIM (SUBSTR (v_location, 1, INSTR (v_location, '-', '1', 1) - 1)) AS main_node,
TRIM (SUBSTR (v_location, INSTR (v_location, '-') + 1)) AS sub_node INTO v_main_node, v_sub_node FROM DUAL;
SELECT soa.seoa_defaultvalue INTO v_access_medium FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

OPEN cur_tributer (v_access_bear_id,v_new_Cir_Name);
FETCH cur_tributer INTO v_ch_dis, v_cir_trib_status;CLOSE cur_tributer;
OPEN cur_tributer_p (v_access_id);
FETCH cur_tributer_p INTO v_ch_dis_p, v_cir_trib_status_p;CLOSE cur_tributer_p;

open cur_eq_pre (v_access_id); FETCH cur_eq_pre INTO v_pre_eq,v_pre_location; CLOSE cur_eq_pre;

SELECT SUBSTR (v_pre_location, 1, INSTR (v_pre_location, '-NODE', '1') - 1) AS node INTO v_location_pre FROM DUAL;
SELECT TRIM (SUBSTR (v_location_pre, 1, INSTR (v_location_pre, '-', '1', 1) - 1)) AS main_node,
TRIM (SUBSTR (v_location_pre, INSTR (v_location_pre, '-') + 1)) AS sub_node INTO v_pre_main_node, v_pre_sub_node FROM DUAL;


IF v_main_node IS NOT NULL THEN  IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE' AND v_main_node <> v_sub_node 
   AND v_equip_type LIKE 'MSAN%'AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_access_medium = 'COPPER' AND v_acc_bearer_status = 'COMMISSIONED'THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id 
       AND sit.seit_taskname = 'MAKE MDF X CONNECT';  ELSIF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order = 'CREATE' AND
v_main_node = v_sub_node AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR 
            v_acc_nw = 'MSAN PORT') AND v_access_medium = 'COPPER' AND v_acc_bearer_status = 'COMMISSIONED'THEN UPDATE service_implementation_tasks sit 
SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
    ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE'THEN DELETE      service_implementation_tasks sit 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT'; END IF;
      IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-OR' AND v_main_node <> v_sub_node
AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') 
AND v_acc_bearer_status = 'COMMISSIONED'THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE MDF X CONNECT';ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-OR' AND v_main_node = v_sub_node AND (
v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')
AND v_acc_bearer_status = 'COMMISSIONED'THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'MAKE MDF X CONNECT'; ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-OR'THEN  DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT'; END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node <> v_sub_node AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')
AND v_mig_type = 'LEGACY TO NGN'THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; 
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node = v_sub_node AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_mig_type = 'LEGACY TO NGN'THEN UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; ELSIF     v_service_type = 'D-PREMIUM IPVPN'
AND v_service_order = 'CREATE-TRANSFER'THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; END IF;

IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED' AND v_main_node <> v_sub_node AND (
  v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND v_cur_nof_copper > v_pre_nof_copper THEN  
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'MAKE ADD. X CONNECTS';  ELSIF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order ='MODIFY-SPEED' 
AND v_main_node = v_sub_node AND 
(v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') 
 AND v_cur_nof_copper > v_pre_nof_copper THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'MAKE ADD. X CONNECTS';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD. X CONNECTS';
END IF;IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id  AND sit.seit_taskname = 'REM. ADD. X CONNECTS'; end if;


IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node <> v_sub_node AND (
  v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'YES'  THEN  
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'MAKE MDF X CONNECT';  
ELSIF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order ='MODIFY-LOCATION' AND v_main_node = v_sub_node AND 
(v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'YES'  
THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'MAKE MDF X CONNECT';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
END IF;


IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node <> v_sub_node AND (
  v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%') AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'NO'  THEN  
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'MODIFY MDF X CONNECT';  
ELSIF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order ='MODIFY-LOCATION' AND v_main_node = v_sub_node AND 
(v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')  AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'NO'  
THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'MODIFY MDF X CONNECT';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT';
END IF;



/*IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node <> v_sub_node AND v_equip_type LIKE 'MSAN%'
AND v_access_node_chg = 'YES' AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL THEN UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC'; ELSIF     v_service_type = 'D-PREMIUM IPVPN'
AND v_service_order = 'MODIFY-LOCATION' AND v_main_node = v_sub_node AND v_equip_type LIKE 'MSAN%' AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_access_node_chg = 'YES'
AND v_ch_dis IS NULL THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'RE. OLD MDF X CONNEC'; ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC'; END IF;
*/

IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE' AND v_main_node <> v_sub_node AND 
  (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')AND v_ch_dis IS NULL THEN 
    UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE'
AND v_main_node = v_sub_node AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')
    AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL THEN
UPDATE service_implementation_tasks sit  SET sit.seit_worg_name = v_work_group_mdf
       WHERE sit.seit_sero_id = p_sero_id  AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; 
ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE'
      THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR' AND v_main_node <> v_sub_node AND 
  (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')AND v_ch_dis IS NULL THEN 
    UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR'
AND v_main_node = v_sub_node AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')
    AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL THEN
UPDATE service_implementation_tasks sit  SET sit.seit_worg_name = v_work_group_mdf
       WHERE sit.seit_sero_id = p_sero_id  AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; 
ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR'
      THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; END IF;
/*IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR' AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT') AND v_ch_dis IS NULL THEN UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE DSL LINE';ELSIF     v_service_type = 'D-PREMIUM IPVPN'
AND v_service_order = 'DELETE-OR' THEN  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE DSL LINE';END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_equip_type LIKE 'MSAN%' AND v_access_node_chg = 'NO'
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_main_node <> v_sub_node AND v_acc_bearer_status = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT';ELSIF     v_service_type = 'D-PREMIUM IPVPN'
AND v_service_order = 'MODIFY-LOCATION' AND v_equip_type LIKE 'MSAN%' AND v_access_node_chg = 'NO' AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT')
AND v_main_node <> v_sub_node AND v_acc_bearer_status = 'COMMISSIONED' THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION'
THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_equip_type LIKE 'MSAN%' AND v_access_node_chg = 'YES'
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_main_node <> v_sub_node AND v_acc_bearer_status = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_equip_type LIKE 'MSAN%' AND v_access_node_chg = 'YES'
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_main_node <> v_sub_node AND v_acc_bearer_status = 'COMMISSIONED' THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT'; ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';END IF;
*/END IF; IF v_main_node IS NULL THEN IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE' AND (
      v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_access_medium = 'COPPER' AND v_acc_bearer_status = 'COMMISSIONED' 
THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id 
     AND sit.seit_taskname = 'MAKE MDF X CONNECT'; ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE'
THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
     END IF;IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-OR' AND (v_equip_type LIKE 'MSAN%' or 
v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' 
             THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id 
AND sit.seit_taskname = 'MAKE MDF X CONNECT'; ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-OR'
    THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
END IF;IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-TRANSFER' AND (v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')
    AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_mig_type = 'LEGACY TO NGN' THEN UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; 
    ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'CREATE-TRANSFER' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT'; END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED' AND (v_acc_nw = 'DSLAM PORT' 
  OR v_acc_nw = 'MSAN PORT')AND v_cur_nof_copper > v_pre_nof_copper THEN UPDATE service_implementation_tasks sit 
  SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD. X CONNECTS'; 
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED'THEN
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD. X CONNECTS'; END IF;
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED' AND (v_equip_type LIKE 'MSAN%' OR 
  v_equip_type LIKE 'DSLAM%')AND v_no_of_copper_pair_cur < v_no_of_copper_pair_pre THEN UPDATE service_implementation_tasks sit 
SET sit.seit_worg_name = v_work_group_mdf WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REM. ADD. X CONNECTS';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-SPEED'THEN DELETE      service_implementation_tasks sit 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REM. ADD. X CONNECTS'; END IF;/*IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_equip_type LIKE 'MSAN%' AND v_access_node_chg = 'YES'
AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC'; ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION'
THEN DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC'; END IF;
*/IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE' AND v_equip_type LIKE 'MSAN%' AND (
  v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL
THEN  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf  
  WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT';
ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE' THEN DELETE
      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; END IF; 
IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR' AND v_equip_type LIKE 'MSAN%' AND (
  v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_ch_dis IS NULL
THEN  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf  
  WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT';
ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'DELETE-OR' THEN DELETE
      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE CROSS CONNECT'; END IF; 

IF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order ='MODIFY-LOCATION'  AND 
(v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'YES'  
THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'MAKE MDF X CONNECT';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT';
END IF;
      
IF     v_service_type = 'D-PREMIUM IPVPN'AND v_service_order ='MODIFY-LOCATION'  AND 
(v_equip_type LIKE 'MSAN%' or v_equip_type LIKE 'DSLAM%')AND (v_acc_nw = 'DSLAM PORT' OR v_acc_nw = 'MSAN PORT') AND v_acc_bearer_status = 'COMMISSIONED' and v_access_node_chg = 'NO'  
THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'MODIFY MDF X CONNECT';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNECT';
END IF;END IF;-- v_pre_main_node, v_pre_sub_node

IF v_pre_main_node IS NOT NULL THEN IF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_pre_main_node <>  v_pre_sub_node AND (
  v_pre_eq LIKE 'MSAN%' or v_pre_eq LIKE 'DSLAM%')AND (v_acc_nw_pre = 'DSLAM PORT' OR v_acc_nw_pre = 'MSAN PORT') AND  v_access_node_chg = 'YES'  THEN  
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'RE. OLD MDF X CONNEC';  

ELSIF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND v_pre_main_node =  v_pre_sub_node AND (
  v_pre_eq LIKE 'MSAN%' or v_pre_eq LIKE 'DSLAM%')AND (v_acc_nw_pre = 'DSLAM PORT' OR v_acc_nw_pre = 'MSAN PORT') AND  v_access_node_chg = 'YES'   THEN
  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'RE. OLD MDF X CONNEC';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC';
END IF; END IF;

IF v_pre_main_node IS NULL THEN IF v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' AND --v_pre_main_node =  v_pre_sub_node AND
 (    v_pre_eq LIKE 'MSAN%' or v_pre_eq LIKE 'DSLAM%')AND (v_acc_nw_pre = 'DSLAM PORT' OR v_acc_nw_pre = 'MSAN PORT') AND  v_access_node_chg = 'YES'   THEN
 UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf 
 WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname =  'RE. OLD MDF X CONNEC';
ELSIF     v_service_type = 'D-PREMIUM IPVPN' AND v_service_order = 'MODIFY-LOCATION' THEN 
DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RE. OLD MDF X CONNEC';
END IF; END IF;


p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'COMPLETED' ); EXCEPTION WHEN OTHERS THEN
p_ret_msg := 'Failed to Workgroup Mapping Please check the Cross Connection Equip Type  :  - Erro is:'
|| TO_CHAR (SQLCODE) || '-' || SQLERRM; p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id,'ERROR' );INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);

END D_PREMIUM_VPN_X_CONNE_WG_CHG;
-- Jayan Liyanage 2012/08/16
---- edited on 20/09/2012

------JANAKA 2013-07-17 ----SOFSWITCH-----------------

PROCEDURE UPDATE_SOP_PROV_FET_STS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = P_SEIT_ID;
      
      
    CURSOR C_SEIT_ID (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE, T_SERO_REVISION SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE) IS
      SELECT SEIT_ID
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_SERO_ID = T_SERO_ID
      AND    SEIT_SERO_REVISION = T_SERO_REVISION
      AND    SEIT_TASKNAME = 'SOP_PROVISION';
      
    CURSOR C_ZTE_SS_REG_NEWSRV (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
        SELECT  COUNT(*)
        FROM    SOP_QUEUE
        WHERE   SOPQ_SOPC_COMMAND='ZTE_SS_REG_NEWSRV'
        AND     SOPQ_STATUS='COMPLETED'
        AND     SOPQ_MANS_NAME='PSTN%1%ZTE_SOFTSWITCH'
        --AND SOPQ_SEIT_ID = 54830236;
        AND SOPQ_SEIT_ID = T_SEIT_ID;

      CURSOR C_GET_FEATURES_ACT IS
      
            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = P_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='Y' 
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            AND     SOFE_FEATURE_NAME IN ('SF_ABBREVIATED_DIAL',
                                    'SF_ABSENTEE_SERVICE',
                                    'SF_ANONYMOUS_CALL_BARRING',
                                    'SF_CALL_BACK_ON_BUSY',
                                    'SF_CALL_CONFERENCE',
                                    'SF_CF_BY_TIME',
                                    'SF_CF_OFFLINE',
                                    'SF_CALL_HOLDING',
                                    'SF_CALL_TRANSFER_THREE_WAY',
                                    'SF_CALL_WAITING',
                                    'SF_CF_IMMEDIATE',
                                    'SF_CF_NO_ANSWER',
                                    'SF_CF_OFFLINE',
                                    'SF_CF_ON_BUSY',
                                    'SF_CF_SELECTIVE',
                                    'SF_CLI',
                                    'SF_CLI_PRESENTATION_IN_CALL_WAITING',
                                    'SF_DO_NOT_DISTURB_SERVICE',
                                    'SF_HOTLINE_IMMEDIATE',
                                    'SF_HOTLINE_TIMEDELAY',
                                    'SF_INCOMING_CALL_MEMORY',
                                    'SF_INCOMING_CALL_TRANSFER',
                                    'SF_MCT',
                                    'SF_MCT_ALL_INCOMING',
                                    'SF_OUTGOING_CALL_MEMORY',
                                    'SF_PASSWORD_CALL_BARRING',
                                    'SF_SECRET_CODE',
                                    'SF_SECRETARY_SERVICE',
                                    'SF_SELECTIVE_CALL_ACCEPTANCE',
                                    'SF_SELECTIVE_CALL_REJECTION')
            ORDER BY SOFE_FEATURE_NAME;
            
    CURSOR C_ZTE_SS_DELETE_NEWSRV (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
        SELECT  COUNT(*)
        FROM    SOP_QUEUE
        WHERE   SOPQ_SOPC_COMMAND='ZTE_SS_DELETE_NEWSRV'
        AND     SOPQ_STATUS='COMPLETED'
        AND     SOPQ_MANS_NAME='PSTN%1%ZTE_SOFTSWITCH'
        --AND SOPQ_SEIT_ID = 54830236;
        AND SOPQ_SEIT_ID = T_SEIT_ID;      

      CURSOR C_GET_FEATURES_DEACT IS
      
            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = P_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='N' 
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            AND     SOFE_FEATURE_NAME IN ('SF_ABBREVIATED_DIAL',
                                    'SF_ABSENTEE_SERVICE',
                                    'SF_ANONYMOUS_CALL_BARRING',
                                    'SF_CALL_BACK_ON_BUSY',
                                    'SF_CALL_CONFERENCE',
                                    'SF_CF_BY_TIME',
                                    'SF_CF_OFFLINE',
                                    'SF_CALL_HOLDING',
                                    'SF_CALL_TRANSFER_THREE_WAY',
                                    'SF_CALL_WAITING',
                                    'SF_CF_IMMEDIATE',
                                    'SF_CF_NO_ANSWER',
                                    'SF_CF_OFFLINE',
                                    'SF_CF_ON_BUSY',
                                    'SF_CF_SELECTIVE',
                                    'SF_CLI',
                                    'SF_CLI_PRESENTATION_IN_CALL_WAITING',
                                    'SF_DO_NOT_DISTURB_SERVICE',
                                    'SF_HOTLINE_IMMEDIATE',
                                    'SF_HOTLINE_TIMEDELAY',
                                    'SF_INCOMING_CALL_MEMORY',
                                    'SF_INCOMING_CALL_TRANSFER',
                                    'SF_MCT',
                                    'SF_MCT_ALL_INCOMING',
                                    'SF_OUTGOING_CALL_MEMORY',
                                    'SF_PASSWORD_CALL_BARRING',
                                    'SF_SECRET_CODE',
                                    'SF_SECRETARY_SERVICE',
                                    'SF_SELECTIVE_CALL_ACCEPTANCE',
                                    'SF_SELECTIVE_CALL_REJECTION')
            ORDER BY SOFE_FEATURE_NAME;

    CURSOR C_ZTE_SS_ATTR_RMODEL (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
        SELECT  COUNT(*)
        FROM    SOP_QUEUE
        WHERE   SOPQ_SOPC_COMMAND='ZTE_SS_MODIFY_SUB_ATTR_RMODEL'
        AND     SOPQ_STATUS='COMPLETED'
        AND     SOPQ_MANS_NAME='PSTN%1%ZTE_SOFTSWITCH'
        --AND SOPQ_SEIT_ID = 54830236;
        AND SOPQ_SEIT_ID = T_SEIT_ID;      

      CURSOR C_GET_FEATURES_RMODEL IS
      
            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = P_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            AND     SOFE_FEATURE_NAME IN ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD')
            ORDER BY SOFE_FEATURE_NAME;
            
      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      V_ORDER_TYPE      SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;      
      V_SEIT_ID         SOP_QUEUE.SOPQ_SEIT_ID%TYPE;


      
      V_NEWSRV                      VARCHAR2(10);
      V_DELNEWSRV                   VARCHAR2(10);
      V_RMODEL                      VARCHAR2(10);
            
      CURR_COUNT               VARCHAR2(10);
      OLD_COUNT                VARCHAR2(10);
      FEATURE_COUNT            VARCHAR2(10);
BEGIN


    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;

      
    OPEN C_SEIT_ID(V_SERO_ID, V_SERO_REVISION);
    FETCH C_SEIT_ID INTO V_SEIT_ID;
    CLOSE C_SEIT_ID;
    
    
    OPEN C_ZTE_SS_REG_NEWSRV(V_SEIT_ID);
    FETCH C_ZTE_SS_REG_NEWSRV INTO V_NEWSRV;
    CLOSE C_ZTE_SS_REG_NEWSRV;

    OPEN C_ZTE_SS_DELETE_NEWSRV(V_SEIT_ID);
    FETCH C_ZTE_SS_DELETE_NEWSRV INTO V_DELNEWSRV;
    CLOSE C_ZTE_SS_DELETE_NEWSRV;

    OPEN C_ZTE_SS_ATTR_RMODEL(V_SEIT_ID);
    FETCH C_ZTE_SS_ATTR_RMODEL INTO V_RMODEL;
    CLOSE C_ZTE_SS_ATTR_RMODEL;
    
    IF  V_DELNEWSRV>0 THEN
    
    
     FOR REC_FEATURE IN C_GET_FEATURES_DEACT LOOP
       
        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',SOFE_PROVISION_TIME=SYSDATE,SOFE_PROVISION_USERNAME=USER
        WHERE sof.sofe_sero_id= V_SERO_ID
        AND sof.sofe_feature_name = REC_FEATURE.SOFE_FEATURE_NAME;
       
       
       END LOOP;
       
    END IF;    
    
    IF  V_NEWSRV>0 THEN
    
    
     FOR REC_FEATURE IN C_GET_FEATURES_ACT LOOP
       
        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',SOFE_PROVISION_TIME=SYSDATE,SOFE_PROVISION_USERNAME=USER
        WHERE sof.sofe_sero_id= V_SERO_ID
        AND sof.sofe_feature_name = REC_FEATURE.SOFE_FEATURE_NAME;
       
       
       END LOOP;
       
    END IF;

    IF  V_RMODEL>0 THEN
    
    
     FOR REC_FEATURE IN C_GET_FEATURES_RMODEL LOOP
       
        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',SOFE_PROVISION_TIME=SYSDATE,SOFE_PROVISION_USERNAME=USER
        WHERE sof.sofe_sero_id= V_SERO_ID
        AND sof.sofe_feature_name = REC_FEATURE.SOFE_FEATURE_NAME;
       
       
       END LOOP;
       
    END IF;

    
    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SOP PROVISION FETURES UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_SOP_PROV_FET_STS;


------JANAKA 2013-06-04 ---- SOFTSWITCH------
---- UPDATE 24/07/013---------------
---- Updated 16/09/2013---------

PROCEDURE UPDATE_NUMBER_TYPE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = P_SEIT_ID;
      
    CURSOR C_ORDER_TYPE (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE, T_SERO_REVISION SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE) IS
        SELECT  SERO_ORDT_TYPE
        FROM    SERVICE_ORDERS
        WHERE   SERO_ID=T_SERO_ID
        AND     SERO_REVISION=T_SERO_REVISION;
      
    CURSOR C_SEIT_ID (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE, T_SERO_REVISION SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE) IS
      SELECT SEIT_ID
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_SERO_ID = T_SERO_ID
      AND    SEIT_SERO_REVISION = T_SERO_REVISION
      AND    SEIT_TASKNAME = 'QUERY_NUMBER_TYPE';
    
    CURSOR C_CHK_SOP_ERR (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
    SELECT SUBSTR(MAX(SOPQ_STATUS||' - ' ||SOPQ_SOPC_COMMAND||' - ' ||SOPQ_ERRORMESSAGE),1,450) MSG
    FROM SOP_QUEUE
    WHERE SOPQ_SEIT_ID=T_SEIT_ID
    AND SOPQ_STATUS='ERROR';
      
    CURSOR C_SORD_VALUE_ATTR (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(SORD_VALUE) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ZTE_SS_SHOW_NOC_ATTR'
      AND SORD_NAME='description'
      AND SOPQ_SEIT_ID = T_SEIT_ID);
      
    CURSOR C_SORD_VALUE_SDN (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(replace(replace((SORD_VALUE),CHR(13),''),CHR(10),' ') ) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ZTE_SS_SHOW_SDN'
      AND SORD_NAME='description'
      AND SOPQ_SEIT_ID = T_SEIT_ID);      

    CURSOR C_SORD_VALUE_SDN_NEW (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(replace(replace((SORD_VALUE),CHR(13),''),CHR(10),' ') ) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ZTE_SS_SHOW_SDN_NEW'
      AND SORD_NAME='description'
      AND SOPQ_SEIT_ID = T_SEIT_ID);          

    CURSOR C_ZTE_SS_SHOW_MOD_NUM (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(SORD_VALUE) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ZTE_SS_SHOW_MOD_NUM'
      AND SORD_NAME='description'
      AND SOPQ_SEIT_ID = T_SEIT_ID);       
       
       
      CURSOR C_GET_FEATURES_NEW (T_SERO_ID SERVICE_ORDER_FEATURES.SOFE_SERO_ID%TYPE) IS
      
            SELECT  COUNT(SOFE_FEATURE_NAME) CURR_COUNT
            FROM    SERVICE_ORDER_FEATURES
            WHERE   SOFE_SERO_ID=T_SERO_ID
            AND        SOFE_FEATURE_NAME NOT IN ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD')
            AND     NVL(SOFE_DEFAULTVALUE,'N') ='Y'
            AND     NVL(SOFE_PREV_VALUE,'N')   ='N'
            ORDER BY SOFE_FEATURE_NAME;
      
      CURSOR C_GET_FEATURES_DEL (T_SERO_ID SERVICE_ORDER_FEATURES.SOFE_SERO_ID%TYPE) IS
      
            SELECT  COUNT(SOFE_FEATURE_NAME) OLD_COUNT
            FROM    SERVICE_ORDER_FEATURES
            WHERE   SOFE_SERO_ID=T_SERO_ID
            AND        SOFE_FEATURE_NAME NOT IN ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD')
            AND     NVL(SOFE_DEFAULTVALUE,'N') ='N'
            AND     NVL(SOFE_PREV_VALUE,'N')   ='Y'
            ORDER BY SOFE_FEATURE_NAME; 

            
      CURSOR C_GET_FEATURES (T_SERO_ID SERVICE_ORDER_FEATURES.SOFE_SERO_ID%TYPE) IS
      
            SELECT  COUNT(SOFE_FEATURE_NAME) FEATURE_COUNT
            FROM    SERVICE_ORDER_FEATURES
            WHERE   SOFE_SERO_ID=T_SERO_ID
            AND     SOFE_FEATURE_NAME IN ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD')
            AND        NVL(SOFE_DEFAULTVALUE,'N') <> NVL(SOFE_PREV_VALUE,'N')
            ORDER BY SOFE_FEATURE_NAME;
            
            
      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      V_ORDER_TYPE      SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;      
      V_SEIT_ID         SOP_QUEUE.SOPQ_SEIT_ID%TYPE;
      V_SORD_VALUE      SOP_REPLY_DATA.SORD_VALUE%TYPE;
      V_SORD_VALUE_NEW      SOP_REPLY_DATA.SORD_VALUE%TYPE;
      V_SORD_VALUE_OLD      SOP_REPLY_DATA.SORD_VALUE%TYPE;
      
      V_MSG               VARCHAR2(500);

      
      V_REPLY               VARCHAR2(300);
      V_RETN                VARCHAR2(100);
      V_VALUE               VARCHAR2(100);
      V_LENGT               VARCHAR2(100);
      V_FNR                 VARCHAR2(100);
      V_REPLY_NEW               VARCHAR2(300);
      V_RETN_NEW                VARCHAR2(100);
      V_VALUE_NEW               VARCHAR2(100);
      V_LENGT_NEW               VARCHAR2(100);
      V_FNR_NEW                 VARCHAR2(100);
      V_REPLY_OLD               VARCHAR2(300);
      V_RETN_OLD                VARCHAR2(100);
      V_VALUE_OLD               VARCHAR2(100);
      V_LENGT_OLD               VARCHAR2(100);
      V_FNR_OLD                 VARCHAR2(100);
      CURR_COUNT               VARCHAR2(10);
      OLD_COUNT                VARCHAR2(10);
      FEATURE_COUNT            VARCHAR2(10);
BEGIN


    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;

    OPEN C_ORDER_TYPE(V_SERO_ID, V_SERO_REVISION);
    FETCH C_ORDER_TYPE INTO V_ORDER_TYPE;
    CLOSE C_ORDER_TYPE;
      
      
    OPEN C_SEIT_ID(V_SERO_ID, V_SERO_REVISION);
    FETCH C_SEIT_ID INTO V_SEIT_ID;
    CLOSE C_SEIT_ID;
    
    
    OPEN C_GET_FEATURES_NEW(V_SERO_ID);
    FETCH C_GET_FEATURES_NEW INTO CURR_COUNT;
    CLOSE C_GET_FEATURES_NEW;

    
    OPEN C_GET_FEATURES_DEL(V_SERO_ID);
    FETCH C_GET_FEATURES_DEL INTO OLD_COUNT;
    CLOSE C_GET_FEATURES_DEL;   

    OPEN C_GET_FEATURES(V_SERO_ID);
    FETCH C_GET_FEATURES INTO FEATURE_COUNT;
    CLOSE C_GET_FEATURES;   
 
    ---CHECK SOP ERROR AND UPDATE-----
    
    OPEN C_CHK_SOP_ERR(V_SEIT_ID);
    FETCH C_CHK_SOP_ERR INTO V_MSG;
    CLOSE C_CHK_SOP_ERR;
       
    
    IF  V_MSG IS NOT NULL THEN
    
    INSERT INTO CLARITY.SERVICE_ORDER_COMMENTS 
    (SEOC_SERO_ID,SEOC_SERO_REVISION,SEOC_ID,SEOC_USERID,SEOC_TIMESTAMP,SEOC_TEXT,SEOC_INDICATOR)
    VALUES
    (V_SERO_ID, V_SERO_REVISION,SEOC_ID_SEQ.NEXTVAL,USER,SYSDATE,V_MSG,'N');
    
    END IF;
    --- Check features and update attributes----------   
           
         IF CURR_COUNT >0 THEN
         
            update SERVICE_ORDER_ATTRIBUTES SOA
            set soa.SEOA_DEFAULTVALUE = 'Y'
            where soa.SEOA_SERO_ID = V_SERO_ID
            and soa.SEOA_NAME = 'ZTE_SS_ACT_FEATURES';
            
         ELSE
         
                update SERVICE_ORDER_ATTRIBUTES SOA
                set soa.SEOA_DEFAULTVALUE = 'N'
                where soa.SEOA_SERO_ID = V_SERO_ID
                and soa.SEOA_NAME = 'ZTE_SS_ACT_FEATURES';   
         
         
         END IF;
         
          IF OLD_COUNT >0 THEN
         
            update SERVICE_ORDER_ATTRIBUTES SOA
            set soa.SEOA_DEFAULTVALUE = 'Y'
            where soa.SEOA_SERO_ID = V_SERO_ID
            and soa.SEOA_NAME = 'ZTE_SS_DEACT_FEATURES';         
         
         ELSE
         
            update SERVICE_ORDER_ATTRIBUTES SOA
            set soa.SEOA_DEFAULTVALUE = 'N'
            where soa.SEOA_SERO_ID = V_SERO_ID
            and soa.SEOA_NAME = 'ZTE_SS_DEACT_FEATURES';
            
                     
         END IF;   

-------    FETHURES CHECK ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD') ---------------------


          IF FEATURE_COUNT >0 THEN
         
            update SERVICE_ORDER_ATTRIBUTES SOA
            set soa.SEOA_DEFAULTVALUE = 'Y'
            where soa.SEOA_SERO_ID = V_SERO_ID
            and soa.SEOA_NAME = 'ZTE_SS_PROV_FEATURES';         
         
         ELSE
         
            update SERVICE_ORDER_ATTRIBUTES SOA
            set soa.SEOA_DEFAULTVALUE = 'N'
            where soa.SEOA_SERO_ID = V_SERO_ID
            and soa.SEOA_NAME = 'ZTE_SS_PROV_FEATURES';
            
                     
         END IF;   

     
              
----------------------------------------------------

    IF V_ORDER_TYPE LIKE 'CREATE%' THEN
    
        OPEN C_SORD_VALUE_ATTR(V_SEIT_ID);
        FETCH C_SORD_VALUE_ATTR INTO V_SORD_VALUE;
        CLOSE C_SORD_VALUE_ATTR;

        V_REPLY:=SUBSTR(V_SORD_VALUE,INSTR(V_SORD_VALUE,'RETN='));
       
        V_RETN:=TRIM(TRANSLATE(SUBSTR(V_REPLY,1,INSTR(V_REPLY,',',1)),'RETN=,',' '));
        
        IF V_RETN='0' THEN
        
            V_VALUE:=TRIM(TRANSLATE(SUBSTR(V_REPLY,INSTRC(V_REPLY,',',1,7),INSTRC(V_REPLY,',',1,8)-INSTRC(V_REPLY,',',1,7)),',"',' '));
            
            V_LENGT:=LENGTH(V_VALUE);
            
            IF V_LENGT <=4 THEN
            
                V_FNR:='NON-FNR';
            
            ELSIF V_LENGT >4 THEN
            
                V_FNR:='FNR';
            
            ELSE            
            
                V_FNR:=NULL;
            
            END IF;
        
        ELSE
        
            V_FNR:='NA';
        
        END IF;      
    
    ELSE
        ------  ZTE_SS_SHOW_SDN-------  
        OPEN C_SORD_VALUE_SDN(V_SEIT_ID);
        FETCH C_SORD_VALUE_SDN INTO V_SORD_VALUE;
        CLOSE C_SORD_VALUE_SDN;
    
        V_REPLY:=SUBSTR(V_SORD_VALUE,INSTR(V_SORD_VALUE,'RETN='));     
         
        V_RETN:=TRIM(TRANSLATE(SUBSTR(V_REPLY,1,INSTR(V_REPLY,',',1)),'RETN=,',' '));

        IF V_RETN='0' THEN
        
            V_VALUE:=TRIM(TRANSLATE(SUBSTR(V_REPLY,INSTRC(V_REPLY,',',-1,1)),'," NMSI>',' '));
            
            V_LENGT:=LENGTH(V_VALUE);
            
            IF V_LENGT =7 THEN
            
                V_FNR:='NON-FNR';
            
            ELSIF V_LENGT >7 THEN
            
                V_FNR:='FNR';
            
            ELSE            
            
                V_FNR:=NULL;
            
            END IF;
        
        ELSE
        
            V_FNR:='NA';
        
        END IF; 

        ------  ZTE_SS_SHOW_SDN_NEW-------  
        OPEN C_SORD_VALUE_SDN_NEW(V_SEIT_ID);
        FETCH C_SORD_VALUE_SDN_NEW INTO V_SORD_VALUE_NEW;
        CLOSE C_SORD_VALUE_SDN_NEW;
    
        V_REPLY_NEW:=SUBSTR(V_SORD_VALUE_NEW,INSTR(V_SORD_VALUE_NEW,'RETN='));     
         
        V_RETN_NEW:=TRIM(TRANSLATE(SUBSTR(V_REPLY_NEW,1,INSTR(V_REPLY_NEW,',',1)),'RETN=,',' '));

        IF V_RETN_NEW='0' THEN
        
            V_VALUE_NEW:=TRIM(TRANSLATE(SUBSTR(V_REPLY_NEW,INSTRC(V_REPLY_NEW,',',-1,1)),'," NMSI>',' '));
            
            V_LENGT_NEW:=LENGTH(V_VALUE_NEW);
            
            IF V_LENGT_NEW =7 THEN
            
                V_FNR_NEW:='NON-FNR';
            
            ELSIF V_LENGT_NEW >7 THEN
            
                V_FNR_NEW:='FNR';
            
            ELSE            
            
                V_FNR_NEW:=NULL;
            
            END IF;
        
        ELSE
        
            V_FNR_NEW:='NA';
        
        END IF; 

    -------------ZTE_SS_SHOW_MOD_NUM-----------  
    OPEN C_ZTE_SS_SHOW_MOD_NUM(V_SEIT_ID);
        FETCH C_ZTE_SS_SHOW_MOD_NUM INTO V_SORD_VALUE_OLD;
        CLOSE C_ZTE_SS_SHOW_MOD_NUM;

        V_REPLY_OLD:=SUBSTR(V_SORD_VALUE_OLD,INSTR(V_SORD_VALUE_OLD,'RETN='));
       
        V_RETN_OLD:=TRIM(TRANSLATE(SUBSTR(V_REPLY_OLD,1,INSTR(V_REPLY_OLD,',',1)),'RETN=,',' '));
        
        IF V_RETN_OLD='0' THEN
        
            V_VALUE_OLD:=TRIM(TRANSLATE(SUBSTR(V_REPLY_OLD,INSTRC(V_REPLY_OLD,',',1,7),INSTRC(V_REPLY_OLD,',',1,8)-INSTRC(V_REPLY_OLD,',',1,7)),',"',' '));
            
            V_LENGT_OLD:=LENGTH(V_VALUE_OLD);
            
            IF V_LENGT_OLD <=4 THEN
            
                V_FNR_OLD:='NON-FNR';
            
            ELSIF V_LENGT_OLD >4 THEN
            
                V_FNR_OLD:='FNR';
            
            ELSE            
            
                V_FNR_OLD:=NULL;
            
            END IF;
        
        ELSE
        
            V_FNR_OLD:='NA';
        
        END IF; 
      
    END IF;

    IF V_FNR IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_FNR
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'SA_NUMBER_TYPE';

        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_FNR_NEW
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'SA_NUMBER_TYPE_NEW';

        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_FNR_OLD
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'SA_NUMBER_TYPE_OLD';
        
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    ELSE
    
        p_ret_msg  := 'SS FNR IS NULL' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
        
                p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);
    
    END IF;
    

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SS FNR UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_NUMBER_TYPE;


---- UPDATE 24/07/013---------------
-----Updated 16/09/2013--------


PROCEDURE UPDATE_ZTE_MSAN_NODEID (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS





    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = p_seit_id;
      
      
    CURSOR C_SEIT_ID (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE, T_SERO_REVISION SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE) IS
      SELECT SEIT_ID
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_SERO_ID = T_SERO_ID
      AND    SEIT_SERO_REVISION = T_SERO_REVISION
      AND    SEIT_TASKNAME = 'QUERY_MSAN_NODEID';
      
   CURSOR C_CHK_SOP_ERR (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
    SELECT SUBSTR(MAX(SOPQ_STATUS||' - ' ||SOPQ_SOPC_COMMAND||' - ' ||SOPQ_ERRORMESSAGE),1,450) MSG
    FROM SOP_QUEUE
    WHERE SOPQ_SEIT_ID=T_SEIT_ID
    AND SOPQ_STATUS='ERROR';
      
    CURSOR C_SORD_VALUE (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(SORD_VALUE) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ZTE_SS_SELECT_NODE_ATTR'
      AND SORD_NAME='description'
      AND SOPQ_SEIT_ID = T_SEIT_ID);
     

      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;  
      V_SEIT_ID         SOP_QUEUE.SOPQ_SEIT_ID%TYPE;
      V_SORD_VALUE      SOP_REPLY_DATA.SORD_VALUE%TYPE;

       V_MSG               VARCHAR2(500);
      
      V_REPLY               VARCHAR2(300);
      V_RETN                VARCHAR2(100);
      V_VALUE               VARCHAR2(300);
      V_RESULT              VARCHAR2(100);
      V_NODEID              VARCHAR2(100);

BEGIN


    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;

      
    OPEN C_SEIT_ID(V_SERO_ID, V_SERO_REVISION);
    FETCH C_SEIT_ID INTO V_SEIT_ID;
    CLOSE C_SEIT_ID;

    
    OPEN C_SORD_VALUE(V_SEIT_ID);
    FETCH C_SORD_VALUE INTO V_SORD_VALUE;
    CLOSE C_SORD_VALUE;      
     
    ---CHECK SOP ERROR AND UPDATE-----
    
    OPEN C_CHK_SOP_ERR(V_SEIT_ID);
    FETCH C_CHK_SOP_ERR INTO V_MSG;
    CLOSE C_CHK_SOP_ERR;
       
    
    IF  V_MSG IS NOT NULL THEN
    
    INSERT INTO CLARITY.SERVICE_ORDER_COMMENTS 
    (SEOC_SERO_ID,SEOC_SERO_REVISION,SEOC_ID,SEOC_USERID,SEOC_TIMESTAMP,SEOC_TEXT,SEOC_INDICATOR)
    VALUES
    (V_SERO_ID, V_SERO_REVISION,SEOC_ID_SEQ.NEXTVAL,USER,SYSDATE,V_MSG,'N');
    
    END IF;

        V_REPLY:=SUBSTR(V_SORD_VALUE,INSTR(V_SORD_VALUE,'RETN='));
       
        V_RETN:=TRIM(TRANSLATE(SUBSTR(V_REPLY,1,INSTR(V_REPLY,',',1)),'RETN=,',' ')); 
        
        IF V_RETN='0' THEN
        
            V_VALUE:=SUBSTR(V_REPLY,INSTR(V_REPLY,'RESULT='));
            
            V_RESULT:=TRIM(TRANSLATE(SUBSTR(V_VALUE,1,INSTR(V_VALUE,',',1)),'RESULT=,',' '));
            
           IF V_RESULT IS NOT NULL THEN
           
            V_NODEID :=V_RESULT;
           
           ELSE
           
            V_NODEID:=NULL;
           
           END IF;
        
        ELSE
        
            V_NODEID:='NA';
        
        END IF;      
    
 

    IF V_NODEID IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_NODEID
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'SA_ZTE_MSAN_NODEID';
        
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    ELSE
    
        p_ret_msg  := 'SS NODEID IS NULL' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
        
                p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);
    
    END IF;
    

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'SS NODEID UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_ZTE_MSAN_NODEID;

---@@@ Task Condition@@@-----
---- Edited 14-01-2016 Dinesh ----
PROCEDURE SLT_NEMS_SOFTSWITCH_CHECK (
      p_serv_id            IN     Services.serv_id%type,
      p_sero_id            IN     Service_Orders.sero_id%type,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%type,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%type,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              out varchar2,
      p_ret_number            OUT number,
      p_ret_msg               OUT Varchar2)   IS


      CURSOR C_SERV_ID  IS
            
            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS, CIRCUITS
            WHERE   CIRT_STATUS !='PENDINGDELETE'
            AND     SERO_CIRT_NAME = CIRT_NAME
            AND     SERO_ID= p_sero_id;


      CURSOR C_GET_CIRCUITNO (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  MAX(PO.PORT_EQUP_ID)
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,8)='POTS-OUT';

      CURSOR C_GET_CIRCUITNO_PSTN (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  MAX(PO.PORT_EQUP_ID)
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,7)='POTS-IN';

      CURSOR C_MANS_NAME (T_EQP_ID EQUIPMENT.EQUP_ID%TYPE) IS
      
            SELECT  MAX(NENO_EQUP_ID)
            FROM    NE_NODES
            WHERE   NENO_EQUP_ID= T_EQP_ID
            AND     NENO_MANS_NAME='PSTN%1%ZTE_SOFTSWITCH';
            
      CURSOR ATTR_MANS_NAME IS
      
            SELECT soa.seoa_defaultvalue
            FROM service_order_attributes soa
            WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'MANS_NAME';
    
        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_EQUP_ID      PORTS.PORT_EQUP_ID%TYPE;
        V_MANS_NAME         service_order_attributes.seoa_defaultvalue%TYPE;        

      L_TEMP_CODE         VARCHAR2(20);

  BEGIN
 
    p_ret_msg := '';
          
      OPEN C_SERV_ID;       
      FETCH C_SERV_ID     INTO V_CIRCUIT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;     
      
      IF V_SERO_TYPE='PSTN' THEN

          OPEN C_GET_CIRCUITNO_PSTN (V_CIRCUIT_ID);       
          FETCH C_GET_CIRCUITNO_PSTN INTO V_PORT_EQUP_ID;
          CLOSE C_GET_CIRCUITNO_PSTN;      
      
      ELSE

          OPEN C_GET_CIRCUITNO (V_CIRCUIT_ID);       
          FETCH C_GET_CIRCUITNO INTO V_PORT_EQUP_ID;
          CLOSE C_GET_CIRCUITNO; 
      
      END IF;     

      OPEN C_MANS_NAME (V_PORT_EQUP_ID);       
      FETCH C_MANS_NAME INTO L_TEMP_CODE;
      CLOSE C_MANS_NAME;      
      
      IF L_TEMP_CODE IS NOT NULL  THEN
      
      p_ret_msg := '';
      
      ELSE
       
      OPEN C_GET_CIRCUITNO (V_CIRCUIT_ID);       
      FETCH C_GET_CIRCUITNO INTO V_PORT_EQUP_ID;
      CLOSE C_GET_CIRCUITNO;
          
      p_ret_msg := '';
      
      END IF;

      OPEN ATTR_MANS_NAME;       
      FETCH ATTR_MANS_NAME INTO V_MANS_NAME;
      CLOSE ATTR_MANS_NAME; 

      IF V_MANS_NAME = 'ZTE'  THEN
      
      p_ret_msg := '';
      
      ELSE
       
      p_ret_msg := 'FALSE';
      
      END IF;

EXCEPTION

WHEN OTHERS THEN

      p_ret_msg  := 'Failed SLT_NEMS_SOFTSWITCH_CHECK:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

     INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
     SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
     , p_ret_msg);

END SLT_NEMS_SOFTSWITCH_CHECK;
---@@@@ Task Condition@@@-----
---- Edited 14-01-2016 Dinesh ----
------JANAKA 2013-06-04 ---- SOFTSWITCH-----------------

---- Janaka 2013 07 29 ****ZTE_ADSL****

PROCEDURE UPDATE_VLANCOM_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



   
    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = P_SEIT_ID;

    CURSOR C_SEIT_ID (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE, T_SERO_REVISION SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE) IS
      SELECT SEIT_ID
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_SERO_ID = T_SERO_ID
      AND    SEIT_SERO_REVISION = T_SERO_REVISION
      AND    SEIT_TASKNAME = 'QUERY ZTE VLAN ID';
      
    
      CURSOR C_SORD_VALUE_ATTR (T_SEIT_ID SOP_QUEUE.SOPQ_SEIT_ID%TYPE) IS
      SELECT DISTINCT(replace(replace((SORD_VALUE),CHR(13),' '),CHR(10),'# ') ) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) FROM SOP_REPLY_DATA, SOP_QUEUE
      WHERE SORD_SOPQ_REQUESTID = SOPQ_REQUESTID
      AND SOPQ_SOPC_COMMAND = 'ADSL_ZTE_CONF_LIST_VLANID'
      AND SORD_NAME='description'
      AND SOPQ_STATUS='COMPLETED'
      AND SOPQ_SEIT_ID = T_SEIT_ID);
    
      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      V_ORDER_TYPE      SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;      
      V_SEIT_ID         SOP_QUEUE.SOPQ_SEIT_ID%TYPE;
      V_SORD_VALUE      SOP_REPLY_DATA.SORD_VALUE%TYPE;
      V_SORD_VALUE_NEW      SOP_REPLY_DATA.SORD_VALUE%TYPE;
      
      V_IPTV                VARCHAR2(500);
      V_IPTV_SVLAN          VARCHAR2(500);
      V_Multicast           VARCHAR2(500);
      V_SVLAN               VARCHAR2(500);
      V_Entree              VARCHAR2(500);

      
   BEGIN
   

    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;


      
    OPEN C_SEIT_ID(V_SERO_ID, V_SERO_REVISION);
    FETCH C_SEIT_ID INTO V_SEIT_ID;
    CLOSE C_SEIT_ID;
    
    OPEN C_SORD_VALUE_ATTR(V_SEIT_ID);
    FETCH C_SORD_VALUE_ATTR INTO V_SORD_VALUE;
    CLOSE C_SORD_VALUE_ATTR;
    
   IF V_SORD_VALUE IS NOT NULL THEN

   ----Multicast-----
    V_Multicast:=  TRIM(REPLACE(SUBSTR(V_SORD_VALUE,(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' Multicast '))),'#',-1,1)),
                (INSTR(V_SORD_VALUE,' Multicast ')-1)-(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' Multicast '))),'#',-1,1))),'#',''));
    
    IF V_Multicast IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_Multicast
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_MVLAN';
        
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_MVLAN';
    
    END IF;
        
   ----IPTV-----
    V_IPTV:=  TRIM(REPLACE(SUBSTR(V_SORD_VALUE,(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' IPTV '))),'#',-1,1)),
                (INSTR(V_SORD_VALUE,' IPTV ')-1)-(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' IPTV '))),'#',-1,1))),'#',''));
    
    IF V_IPTV IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_IPTV
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV';
        
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV';
    
    END IF;
    
    ---IPTV_SVLAN------
    V_IPTV_SVLAN:=  TRIM(REPLACE(SUBSTR(V_SORD_VALUE,(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' IPTV_SVLAN '))),'#',-1,1)),
                (INSTR(V_SORD_VALUE,' IPTV_SVLAN ')-1)-(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' IPTV_SVLAN '))),'#',-1,1))),'#',''));
    
    IF V_IPTV_SVLAN IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_IPTV_SVLAN
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_SVLAN';

        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'Y'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_SVLAN_STATUS';
        
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_SVLAN';
        
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'N'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_SVLAN_STATUS';
    
    END IF;

   
    ---SVLAN-------
    V_SVLAN:=  TRIM(REPLACE(SUBSTR(V_SORD_VALUE,(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' SVLAN '))),'#',-1,1)),
                (INSTR(V_SORD_VALUE,' SVLAN ')-1)-(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' SVLAN '))),'#',-1,1))),'#',''));
    
    IF V_SVLAN IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_SVLAN
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_SVLAN';

        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'Y'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_SVLAN_STATUS';
        
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_SVLAN';
        
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'N'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_SVLAN_STATUS';
    
    END IF;

   ----Entree-----
    V_Entree:=  TRIM(REPLACE(SUBSTR(V_SORD_VALUE,(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' Entree '))),'#',-1,1)),
                (INSTR(V_SORD_VALUE,' Entree ')-1)-(instrc(SUBSTR(V_SORD_VALUE,1,(INSTR(V_SORD_VALUE,' Entree '))),'#',-1,1))),'#',''));
    
    IF V_Entree IS NOT NULL THEN
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_Entree
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_VLAN';
        
    ELSE
    
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_VLAN';
    
    END IF;
        

    
    END IF;
 
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');   

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'GET_VLAN UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_VLANCOM_ATTR;



PROCEDURE UPDATE_ZTE_ADSL_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



   
    CURSOR C_SERO_ID IS
      SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
      FROM   SERVICE_IMPLEMENTATION_TASKS
      WHERE  SEIT_ID = P_SEIT_ID;

    CURSOR C_SOFE_VAL (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE) IS
        SELECT  NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE 
        FROM    SERVICE_ORDER_FEATURES
        WHERE   SOFE_SERO_ID=T_SERO_ID
        AND     NVL(SOFE_DEFAULTVALUE,'N')<>NVL(SOFE_PREV_VALUE,'N')
        AND     SOFE_FEATURE_NAME='INTERNET';
      

    CURSOR C_SOFE_VAL_IPTV (T_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE) IS
        SELECT  NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE 
        FROM    SERVICE_ORDER_FEATURES
        WHERE   SOFE_SERO_ID=T_SERO_ID
        AND     NVL(SOFE_DEFAULTVALUE,'N')<>NVL(SOFE_PREV_VALUE,'N')
        AND     SOFE_FEATURE_NAME='IPTV';
    
      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      V_SOFE_VAL        SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;      
      V_VAL_IPTV        SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE; 
   


      
   BEGIN
   

    OPEN C_SERO_ID;
    FETCH C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE C_SERO_ID;

    OPEN C_SOFE_VAL(V_SERO_ID);
    FETCH C_SOFE_VAL INTO V_SOFE_VAL;
    CLOSE C_SOFE_VAL;
 
    
   IF V_SOFE_VAL IS NOT NULL THEN
   
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_SOFE_VAL
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_STATUS';
        
   ELSE
   
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_ADSL_STATUS';
           
    END IF;

    OPEN C_SOFE_VAL_IPTV(V_SERO_ID);
    FETCH C_SOFE_VAL_IPTV INTO V_VAL_IPTV;
    CLOSE C_SOFE_VAL_IPTV;
       


   IF V_VAL_IPTV IS NOT NULL THEN
   
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = V_VAL_IPTV
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_STATUS';
        
   ELSE
   
        update SERVICE_ORDER_ATTRIBUTES SOA
        set soa.SEOA_DEFAULTVALUE = 'NA'
        where soa.SEOA_SERO_ID = V_SERO_ID
        and soa.SEOA_NAME = 'ZTE_IPTV_STATUS';
           
    END IF;
    
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    
 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'ZTE_ADSL_STATUS ATTR UPDATE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_ZTE_ADSL_ATTR;

--- Jayan Liyanage 2013/04/03
--- Jayan Liyanage 2013/04/03 
--- Jayan Liyanage 2013/04/03 MODIFY SPEED order type added on 05/05/2014 MAKE MDF X CONNECT delete condition corrected on 31-05-2014 updated on 30-09-2014
--- MODIFY-LOCATION updated on 09/01/2016
PROCEDURE D_EDL_CONNE(
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
      
v_service_type                     Varchar2(100);
v_service_order                    Varchar2(100);      
v_acc_li_type_a                    Varchar2(100);
v_acc_li_type_b                    Varchar2(100);
v_acc_id_a                         Varchar2(100);
v_acc_id_b                         Varchar2(100);
v_service_order_area_a             Varchar2(100);
v_rtom_code_aa                     Varchar2(100);
v_lea_code_aa                      Varchar2(100);
v_acc_bearer_status_a              Varchar2(100);
v_access_medi_b                    Varchar2(100);
v_work_group_a                     Varchar2(100);
v_work_group_mdf_aa                Varchar2(100);           
v_service_order_area_b             Varchar2(100);
v_rtom_code_bb                     Varchar2(100);
v_lea_code_bb                      Varchar2(100);
v_acc_bearer_status_b              Varchar2(100);
v_access_medi_a                    Varchar2(100);
v_work_group_b                     Varchar2(100);                     
v_work_group_mdf_bb                Varchar2(100);
Eq_a_type                          Varchar2(100);
Eq_a_loc                           Varchar2(100);
Eq_b_type                          Varchar2(100);
Eq_b_loc                           Varchar2(100);
v_location_a                       Varchar2(100);
v_main_node_aa                     Varchar2(100);
v_sub_node_aa                      Varchar2(100);
v_location_b                       Varchar2(100);
v_main_node_bb                     Varchar2(100);
v_sub_node_bb                      Varchar2(100);
v_loc_a_cir_Sta                    Varchar2(100);
v_loc_b_cir_Sta                    Varchar2(100);
v_new_Cir_Name                     Varchar2(100);
v_loc_b_cir_dis                    Varchar2(100);
v_loc_a_cir_dis                    Varchar2(100);
v_loc_a_st                         Varchar2(100);
v_loc_b_st                         Varchar2(100);

v_no_copper_pair_a_cur             Varchar2(100);
v_no_copper_pair_a_pre             Varchar2(100);
v_no_copper_pair_b_cur             Varchar2(100);
v_no_copper_pair_b_pre             Varchar2(100);
v_mig_end                          Varchar2(100);
v_acc_node_chg_a                   varchar2(100);
v_acc_node_chg_b                   varchar2(100);
v_reloc_end                        varchar2(100);

/*CURSOR cur_equi_type IS 
SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname
FROM service_orders so, ports p, equipment e WHERE so.sero_cirt_name = p.port_cirt_name AND (   e.equp_equt_abbreviation LIKE 'MSAN%'
OR e.equp_equt_abbreviation LIKE 'DSLAM%' OR e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'OR e.equp_equt_abbreviation LIKE 'DUMMY NTU%')
AND p.port_equp_id = e.equp_id AND so.sero_id = p_sero_id; 
*/
cursor Cur_Loc_a(parent_and varchar2) is
SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname,ci.cirt_status
FROM ports p, equipment e,circuits ci
WHERE p.port_cirt_name = ci.cirt_name
AND (   e.equp_equt_abbreviation LIKE 'MSAN%'
OR e.equp_equt_abbreviation LIKE 'DSLAM%' OR 
e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'OR 
e.equp_equt_abbreviation LIKE 'DUMMY NTU%' OR
e.equp_equt_abbreviation LIKE 'MLLN%' )
AND p.port_equp_id = e.equp_id --AND so.sero_cirt_name = ci.cirt_name
and (ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%')
and ci.cirt_displayname like  replace(parent_and ,'(N)')||'%';

cursor Cur_Loc_b(parent_bnd varchar2) is
SELECT DISTINCT e.equp_equt_abbreviation, e.equp_locn_ttname,ci.cirt_status
FROM ports p, equipment e,circuits ci
WHERE p.port_cirt_name  = ci.cirt_name
AND (   e.equp_equt_abbreviation LIKE 'MSAN%'
OR e.equp_equt_abbreviation LIKE 'DSLAM%' OR 
e.equp_equt_abbreviation LIKE 'MEDIA CONVERTER%'OR 
e.equp_equt_abbreviation LIKE 'DUMMY NTU%'OR
e.equp_equt_abbreviation LIKE 'MLLN%')
AND p.port_equp_id = e.equp_id 
and (ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%')
and ci.cirt_displayname like replace(parent_bnd ,'(N)')||'%';

cursor Cur_a_s( a_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  
from circuits ci where ci.cirt_displayname like replace(a_cir,'(N)')||'%'
and  ci.cirt_inservice = (select max(c.cirt_inservice)
from circuits c where c.cirt_displayname like replace(a_cir,'(N)')||'%');

cursor Cur_b_s( b_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  
from circuits ci where  ci.cirt_displayname like replace(b_cir,'(N)')||'%'
and ci.cirt_inservice = (select max(c.cirt_inservice)
from circuits c where c.cirt_displayname like replace(b_cir,'(N)')||'%');



BEGIN 


SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id; 



/*SELECT DISTINCT so.sero_area_code
INTO v_service_order_area FROM service_orders so WHERE so.sero_id = p_sero_id; */

SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

IF (v_acc_li_type_a = 'DAB' ) THEN SELECT distinct soa.seoa_defaultvalue INTO v_acc_id_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';END IF;
IF (v_acc_li_type_b = 'DAB') THEN SELECT distinct soa.seoa_defaultvalue INTO v_acc_id_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';END IF;


IF v_acc_id_a IS NOT NULL THEN 
OPEN Cur_Loc_a(v_acc_id_a); FETCH Cur_Loc_a INTO Eq_a_type,Eq_a_loc,v_loc_a_cir_Sta; close Cur_Loc_a; 
END IF;

IF v_acc_id_b IS NOT NULL THEN
OPEN Cur_Loc_b(v_acc_id_b); FETCH Cur_Loc_b INTO Eq_b_type,Eq_b_loc,v_loc_b_cir_Sta; close Cur_Loc_b;
END IF;
/*OPEN Cur_Loc_a(v_acc_id_a); FETCH Cur_Loc_a INTO Eq_a_type,Eq_a_loc,v_loc_a_cir_Sta; close Cur_Loc_a;
OPEN Cur_Loc_b(v_acc_id_b); FETCH Cur_Loc_b INTO Eq_b_type,Eq_b_loc,v_loc_b_cir_Sta; close Cur_Loc_b;
*/

SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_no_copper_pair_a_cur,v_no_copper_pair_a_pre  
FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'AND so.sero_id = p_sero_id;

SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_no_copper_pair_b_cur,v_no_copper_pair_b_pre  
FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'AND so.sero_id = p_sero_id;

IF (v_acc_li_type_a = 'DAB' ) then 
open Cur_a_s(v_acc_id_a); fetch Cur_a_s into v_loc_a_cir_dis,v_loc_a_st; close Cur_a_s;end if;

IF (v_acc_li_type_b = 'DAB') then
open Cur_b_s(v_acc_id_b); fetch Cur_b_s into v_loc_b_cir_dis,v_loc_b_st ; close Cur_b_s; end if;

IF (v_acc_li_type_a = 'DAB'  or  v_acc_li_type_a  = 'DEDICATED LINE' or v_acc_li_type_a = 'NONE')  THEN

 /* IF (v_loc_a_st = 'COMMISSIONED' OR v_loc_a_st LIKE 'PROPOSED%') THEN 
select distinct soa.seoa_defaultvalue
into v_service_order_area_a
from service_orders so,service_order_attributes soa,circuits ci
where soa.seoa_name = 'EXCHANGE_AREA_CODE' 
and ( ci.cirt_status like 'COMM%' OR ci.cirt_status like 'PROP%')
and so.sero_cirt_name = ci.cirt_name
and so.sero_id = soa.seoa_sero_id
and ci.cirt_displayname = v_loc_a_cir_dis;
ELSIF v_loc_a_st = 'INSERVICE' THEN
select distinct sa.satt_defaultvalue into v_service_order_area_a from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_loc_a_cir_dis;END IF;*/

SELECT soa.seoa_defaultvalue INTO v_service_order_area_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes,
ar.area_code INTO v_rtom_code_aa, v_lea_code_aa FROM areas ar WHERE ar.area_code = v_service_order_area_a 
AND ar.area_aret_code = 'LEA';

SELECT soa.seoa_defaultvalue INTO v_acc_bearer_status_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-A END';
SELECT soa.seoa_defaultvalue INTO v_access_medi_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END';

SELECT soa.seoa_defaultvalue INTO v_mig_end FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'MIGRATED END';

SELECT soa.seoa_defaultvalue INTO v_acc_node_chg_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS NODE CHANGE?-A END';
SELECT soa.seoa_defaultvalue INTO v_acc_node_chg_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS NODE CHANGE?-B END';
SELECT soa.seoa_defaultvalue INTO v_reloc_end FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'RELOCATED END';

SELECT wg.worg_name INTO v_work_group_a FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'OSP-NC' || '%'; 
SELECT wg.worg_name INTO v_work_group_mdf_aa FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'MDF' || '%'; 


SELECT SUBSTR (Eq_a_loc, 1, INSTR (Eq_a_loc, '-NODE', '1') - 1)
AS node INTO v_location_a FROM DUAL; 
SELECT TRIM (SUBSTR (v_location_a, 1, INSTR (v_location_a, '-', '1', 1) - 1))AS main_node,
TRIM (SUBSTR (v_location_a, INSTR (v_location_a, '-') + 1)) AS sub_node INTO v_main_node_aa,v_sub_node_aa FROM DUAL;END IF;

IF ( v_acc_li_type_b = 'DAB'  or v_acc_li_type_b =  'DEDICATED LINE' or v_acc_li_type_b =  'NONE') THEN

/* IF (v_loc_b_st = 'COMMISSIONED' OR v_loc_b_st LIKE 'PROPOSED%') THEN 
select distinct soa.seoa_defaultvalue
into v_service_order_area_b
from service_orders so,service_order_attributes soa,circuits ci
where soa.seoa_name = 'EXCHANGE_AREA_CODE' 
and ( ci.cirt_status like 'COMM%' OR ci.cirt_status like 'PROP%')
and so.sero_cirt_name = ci.cirt_name
and so.sero_id = soa.seoa_sero_id
and ci.cirt_displayname = v_loc_b_cir_dis;ELSIF v_loc_b_st = 'INSERVICE' THEN
select distinct sa.satt_defaultvalue into v_service_order_area_b from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_loc_b_cir_dis; END IF;*/
SELECT soa.seoa_defaultvalue INTO v_service_order_area_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes,
ar.area_code INTO v_rtom_code_bb, v_lea_code_bb FROM areas ar WHERE ar.area_code = v_service_order_area_b 
AND ar.area_aret_code = 'LEA';
SELECT soa.seoa_defaultvalue INTO v_acc_bearer_status_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
SELECT soa.seoa_defaultvalue INTO v_access_medi_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END';
SELECT wg.worg_name INTO v_work_group_b FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC' || '%'; 
SELECT wg.worg_name INTO v_work_group_mdf_bb FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'MDF' || '%'; 
SELECT SUBSTR (Eq_b_loc, 1, INSTR (Eq_b_loc, '-NODE', '1') - 1)
AS node INTO v_location_b FROM DUAL; 
SELECT TRIM (SUBSTR (v_location_b, 1, INSTR (v_location_b, '-', '1', 1) - 1))AS main_node,
TRIM (SUBSTR (v_location_b, INSTR (v_location_b, '-') + 1)) AS sub_node INTO v_main_node_bb,v_sub_node_bb FROM DUAL; END IF;

/*SELECT soa.seoa_defaultvalue INTO v_access_bear_id_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';
SELECT soa.seoa_defaultvalue INTO v_access_link_ty_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT soa.seoa_defaultvalue INTO v_access_bear_id_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';
SELECT soa.seoa_defaultvalue INTO v_access_link_ty_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';*//*
select distinct sa.satt_defaultvalue into v_service_order_area_a from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_access_bear_id_a;
select distinct sa.satt_defaultvalue into v_service_order_area_b from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_access_bear_id_b;*/

SELECT DISTINCT c.cirt_displayname into v_new_Cir_Name FROM service_orders so,circuits c 
where so.sero_cirt_name = c.cirt_name and  so.sero_id = p_sero_id;
/*SELECT wg.worg_name INTO v_work_group FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%'; 
SELECT wg.worg_name
INTO v_work_group_mdf FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'MDF' || '%'; */


IF v_main_node_aa IS NOT NULL THEN  
  
  IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';

elsif     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';  

elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';
END IF; 

IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND  v_no_copper_pair_a_cur > v_no_copper_pair_a_pre and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-A';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND v_no_copper_pair_a_cur > v_no_copper_pair_a_pre and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%'or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-A';
END IF;

IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND  ( v_mig_end = 'A END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-A';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_mig_end = 'A END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%'or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-A';
END IF;
 /* IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'YES' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'YES' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';
END IF; 

  IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'NO' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-A';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'NO' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'CHANGE MDF X CONNE-A';
END IF; */


END IF;

IF v_main_node_bb IS NOT NULL THEN 
  IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_main_node_bb <> v_sub_node_bb 
  AND v_access_medi_b = 'COPPER' AND ( v_acc_bearer_status_b = 'COMMISSIONED' or v_acc_li_type_b = 'DEDICATED LINE' ) and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_main_node_bb = v_sub_node_bb 
  AND v_access_medi_b = 'COPPER' AND ( v_acc_bearer_status_b = 'COMMISSIONED' or v_acc_li_type_b = 'DEDICATED LINE' )and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';
END IF;

  IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_main_node_bb <> v_sub_node_bb 
  AND v_access_medi_b = 'COPPER' AND v_no_copper_pair_b_cur > v_no_copper_pair_b_pre and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%'or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-B';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_main_node_bb = v_sub_node_bb 
  AND v_access_medi_b = 'COPPER' AND v_no_copper_pair_b_cur  > v_no_copper_pair_b_pre and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-B';
END IF;

IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND  ( v_mig_end = 'B END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-B';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_mig_end = 'B END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%'or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-B';
END IF;
  IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'B-END' and v_acc_node_chg_b = 'YES' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'B-END' and v_acc_node_chg_b = 'YES' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-B'; END IF;
  
    IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa <> v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'B-END' and v_acc_node_chg_b = 'NO' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-B';
elsif     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' AND v_main_node_aa = v_sub_node_aa 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'B-END' and v_acc_node_chg_b = 'NO' and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'CHANGE MDF X CONNE-B';
END IF; 

 END IF; 


IF v_main_node_aa IS NULL  then IF   v_service_type = 'D-EDL' AND v_service_order = 'CREATE' 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-A'; END IF;
IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
  AND v_access_medi_a = 'COPPER' AND v_no_copper_pair_a_cur > v_no_copper_pair_a_pre and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-A';
END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
  AND v_access_medi_a = 'COPPER' AND ( v_mig_end = 'A END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-A';
END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'YES'  and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-A'; END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'NO'  and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-A';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'CHANGE MDF X CONNE-A'; END IF;

END IF;


 IF v_main_node_bb IS NULL  then
IF   v_service_type = 'D-EDL' AND v_service_order = 'CREATE' 
  AND v_access_medi_b = 'COPPER' AND ( v_acc_bearer_status_b = 'COMMISSIONED' or v_acc_li_type_b = 'DEDICATED LINE' ) and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-B'; END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
  AND v_access_medi_b = 'COPPER' AND v_no_copper_pair_b_cur > v_no_copper_pair_b_pre and 
  (Eq_b_type LIKE 'MSAN%' or Eq_b_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE ADD.X CONNECT-B';
END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
  AND v_access_medi_a = 'COPPER' AND ( v_mig_end = 'B END' or v_mig_end = 'BOTH ENDS') and 
  (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%' or Eq_a_type LIKE 'MLLN%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_bb 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF X CONNE-B';
END IF;

IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'B-END' and v_acc_node_chg_a = 'YES'  and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MAKE MDF X CONNECT-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MAKE MDF X CONNECT-B'; END IF;
  
  IF   v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
  AND v_access_medi_a = 'COPPER' AND ( v_acc_bearer_status_a = 'COMMISSIONED' or v_acc_li_type_a = 'DEDICATED LINE' )and 
  v_reloc_end = 'A-END' and v_acc_node_chg_a = 'NO'  and (Eq_a_type LIKE 'MSAN%' or Eq_a_type LIKE 'DSLAM%')THEN 
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_mdf_aa 
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CHANGE MDF X CONNE-B';  
elsif v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'then
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'CHANGE MDF X CONNE-B'; END IF;

END IF; 

p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION WHEN OTHERS THEN
p_ret_msg :='EDL X, Connection Mapping Function Failed :  - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);

END D_EDL_CONNE;


--- Jayan Liyanage 2013/04/02 Updated on 11/10/2015 Updated on 27/03/2016

PROCEDURE D_ETHERNET_DL_CP_ATTR_AB (
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

CURSOR bearer_c IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS_ID-B END'AND so.sero_id = p_sero_id;
CURSOR bearer_d IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS_ID-A END'AND so.sero_id = p_sero_id;
CURSOR so_copyattr (v_new_bearer_id VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS',
'ADD. NTU MODEL','NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL','CUSTOMER INTF TYPE',
'BACKBONE CORE NO','ACCESS LINK DISTANCE','VLAN TAGGED/UNTAGGED ?','ACCESS FIBER AVAILABLE ?','ACC. FIBER CORE NO#','ACC.FIBER PROJ SO #')AND so.sero_stas_abbreviation <> 

'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname LIKE REPLACE(v_new_bearer_id,'(N)')||'%');

CURSOR so_copyattr_c (v_new_bearer_id_b VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS',
'ADD. NTU MODEL','NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL','CUSTOMER INTF TYPE',
'BACKBONE CORE NO','ACCESS LINK DISTANCE','VLAN TAGGED/UNTAGGED ?','ACCESS FIBER AVAILABLE ?','ACC. FIBER CORE NO#','ACC.FIBER PROJ SO #')
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname LIKE REPLACE(v_new_bearer_id_b,'(N)')||'%');

v_so_attr_name     VARCHAR2 (100);
v_so_attr_val      VARCHAR2 (100);
v_bearer_id        VARCHAR2 (100);
v_cir_status       VARCHAR2 (100);
v_new_bearer_id    VARCHAR2 (100);
v_service_type     VARCHAR2 (100);
v_service_order    VARCHAR2 (100);
v_new_service_type VARCHAR2 (100);
v_new_bearer_id_b  VARCHAR2 (100);
v_bearer_id_b      VARCHAR2 (100);
v_so_attr_name_c     VARCHAR2 (100);
v_so_attr_val_c      VARCHAR2 (100);
v_cir_status_c      VARCHAR2 (100);

BEGIN
  
OPEN bearer_c;FETCH bearer_c INTO v_bearer_id;
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
OPEN so_copyattr (v_bearer_id);LOOP FETCH so_copyattr
INTO v_so_attr_name, v_so_attr_val, v_cir_status; EXIT WHEN so_copyattr%NOTFOUND;
IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-B END'; 

ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-B END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'CREATE' AND v_so_attr_name = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE'
AND v_so_attr_name = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-B END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'CREATE' AND v_so_attr_name = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-B END';
 ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. INTF PORT BW-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE' AND v_so_attr_name = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'BACKBONE CORE NO'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'BACKBONE CORE NO-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'ACCESS LINK DISTANCE' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS LINK DISTANCE-B END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'CREATE' AND v_so_attr_name = 'VLAN TAGGED/UNTAGGED ?'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'ACCESS FIBER AVAILABLE ?' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER AVAILABLE?-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'ACC. FIBER CORE NO#' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER CORE NO#-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name = 'ACC.FIBER PROJ SO #' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC.FIBER PROJ SO #-B END'; end if; END LOOP; 
IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
END IF;
CLOSE so_copyattr;CLOSE bearer_c;OPEN bearer_d;FETCH bearer_d INTO v_bearer_id_b;OPEN so_copyattr_c (v_bearer_id_b);LOOP FETCH so_copyattr_c
INTO v_so_attr_name_c, v_so_attr_val_c, v_cir_status_c; EXIT WHEN so_copyattr_c%NOTFOUND;
IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-A END'; 

ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name_c = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE' 
AND v_so_attr_name_c = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name_c = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-A END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE'
AND v_so_attr_name_c = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-A END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-A END';
 ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name_c = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' 
AND v_so_attr_name_c = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. INTF PORT BW-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
AND v_so_attr_name_c = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'BACKBONE CORE NO'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'BACKBONE CORE NO-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'ACCESS LINK DISTANCE' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS LINK DISTANCE-A END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'VLAN TAGGED/UNTAGGED ?'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'ACCESS FIBER AVAILABLE ?' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER AVAILABLE?-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'ACC. FIBER CORE NO#' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER CORE NO#-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE' AND v_so_attr_name_c = 'ACC.FIBER PROJ SO #' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC.FIBER PROJ SO #-A END'; 
END IF;

END LOOP; 
IF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-A END'; end if;
CLOSE so_copyattr_c;CLOSE bearer_d;

p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'COMPLETED' );EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change D-EDL Copy Attribute  function. Please check the conditions:'|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, 

setc_timestamp,setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);


END D_ETHERNET_DL_CP_ATTR_AB;

--- Jayan Liyanage 2013/04/02


--- Jayan Liyanage 2013/04/03

PROCEDURE D_EDL_NETWORK_NTU_EL_NOTIFY(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2) IS
BEGIN
     p_ret_char := 'Update SERIAL NUMBER in NTU Network Element if NTU is installed ...!' ;                                      
EXCEPTION WHEN OTHERS THEN 
      p_ret_msg  := 'Notify function Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;                                    
END D_EDL_NETWORK_NTU_EL_NOTIFY;

--- Jayan Liyanage 2013/04/03

--- Jayan Liyanage 2012/03/21 updated on 04/12/2013 modify speed added on 03/04/2014
--- MODIFY-LOCATION  updated on 09/01/2016

--- Jayan Liyanage 2012/03/21 updated on 04/12/2013 modify speed added on 03/04/2014


PROCEDURE D_EDL_CREATE_BEA_AT_MAP (
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
   CURSOR v_bearer_aend
   IS
      SELECT DISTINCT soa.seoa_defaultvalue
                 FROM service_orders so, service_order_attributes soa
                WHERE so.sero_id = soa.seoa_sero_id
                  AND soa.seoa_name = 'ACCESS_ID-A END'
                  AND so.sero_id = p_sero_id;

   CURSOR so_copyattr (v_new_bearer_id VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status, c.cirt_serv_id
                 FROM service_orders so,
                      service_order_attributes soa,
                      circuits c
                WHERE so.sero_id = soa.seoa_sero_id
                  AND so.sero_cirt_name = c.cirt_name
                  AND (    c.cirt_status <> 'CANCELLED'
                       AND c.cirt_status <> 'PENDINGDELETE'
                      )
                  AND so.sero_stas_abbreviation <> 'CANCELLED'
                  AND so.sero_id IN (
                         SELECT MAX (s.sero_id)
                           FROM service_orders s, circuits ci
                          WHERE s.sero_cirt_name = ci.cirt_name
                            AND s.sero_stas_abbreviation <> 'CANCELLED'
                            AND ci.cirt_displayname LIKE
                                        REPLACE (v_new_bearer_id, '(N)')
                                        || '%');

   CURSOR v_bearer_bend
   IS
      SELECT DISTINCT soa.seoa_defaultvalue
                 FROM service_orders so, service_order_attributes soa
                WHERE so.sero_id = soa.seoa_sero_id
                  AND soa.seoa_name = 'ACCESS_ID-B END'
                  AND so.sero_id = p_sero_id;

   CURSOR so_copyattr_bnd (v_new_bearer_id_ VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status, c.cirt_serv_id
                 FROM service_orders so,
                      service_order_attributes soa,
                      circuits c
                WHERE so.sero_id = soa.seoa_sero_id
                  AND so.sero_cirt_name = c.cirt_name
                  AND (    c.cirt_status <> 'CANCELLED'
                       AND c.cirt_status <> 'PENDINGDELETE'
                      )
                  AND so.sero_stas_abbreviation <> 'CANCELLED'
                  AND so.sero_id IN (
                         SELECT MAX (s.sero_id)
                           FROM service_orders s, circuits ci
                          WHERE s.sero_cirt_name = ci.cirt_name
                            AND s.sero_stas_abbreviation <> 'CANCELLED'
                            AND ci.cirt_displayname LIKE
                                       REPLACE (v_new_bearer_id_, '(N)')
                                       || '%');

   CURSOR so_att_mapping
   IS
      SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue
                 FROM service_orders so, service_order_attributes soa
                WHERE so.sero_id = soa.seoa_sero_id
                  AND soa.seoa_name IN
                         ('NTU TYPE-A END', 'NTU MODEL-A END',
                          'CPE MODEL-A END', 'ADDITIONAL NTU MODEL-A END',
                          'NO OF COPPER PAIRS-A END', 'CPE S/NUMBER-A END',
                          'NTU S/NUMBER-A END')
                  AND so.sero_id = p_sero_id;

   CURSOR so_att_mapping_b
   IS
      SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue
                 FROM service_orders so, service_order_attributes soa
                WHERE so.sero_id = soa.seoa_sero_id
                  AND soa.seoa_name IN
                         ('NTU TYPE-B END', 'NTU MODEL-B END',
                          'CPE MODEL-B END', 'ADDITIONAL NTU MODEL-B END',
                          'NO OF COPPER PAIRS-B END', 'CPE S/NUMBER-B END',
                          'NTU S/NUMBER-B END')
                  AND so.sero_id = p_sero_id;

   v_cir_status         VARCHAR2 (100);
   v_bearer_so_id       VARCHAR2 (100);
   v_so_attr_name       VARCHAR2 (100);
   v_so_att_val         VARCHAR2 (100);
   v_new_bearer_id      VARCHAR2 (100);
   v_bearer_id          VARCHAR2 (100);
   v_service_type       VARCHAR2 (100);
   v_service_order      VARCHAR2 (100);
   v_new_service        VARCHAR2 (100);
   v_cir_id             VARCHAR2 (100);
   v_bearer_id_and      VARCHAR2 (100);
   v_bearer_id_bnd      VARCHAR2 (100);
   v_bearer_so_id_bnd   VARCHAR2 (100);
   v_cir_status_bnd     VARCHAR2 (100);
   v_cir_id_bnd         VARCHAR2 (100);
   v_so_attr_name_b     VARCHAR2 (100);
   v_so_att_val_b       VARCHAR2 (100);
BEGIN
   OPEN v_bearer_aend;

   FETCH v_bearer_aend
    INTO v_bearer_id_and;

   SELECT DISTINCT so.sero_sert_abbreviation
              INTO v_service_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_order
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   IF v_bearer_id_and IS NOT NULL
   THEN
      OPEN so_copyattr (v_bearer_id_and);

      FETCH so_copyattr
       INTO v_bearer_so_id, v_cir_status, v_cir_id;

      CLOSE v_bearer_aend;

      OPEN so_att_mapping;

      LOOP
         FETCH so_att_mapping
          INTO v_so_attr_name, v_so_att_val;

         EXIT WHEN so_att_mapping%NOTFOUND;

--CLOSE v_bearer_aend;CLOSE v_bearer_bend;
         IF v_cir_status = 'COMMISSIONED'
         THEN
            IF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name = 'NTU TYPE-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                   TRIM (REPLACE ('NTU TYPE-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NTU MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                  TRIM (REPLACE ('NTU MODEL-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'CPE MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                  TRIM (REPLACE ('CPE MODEL-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                         TRIM (REPLACE ('ADDITIONAL NTU MODEL-A END',
                                        '-A END')
                              );
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'CPE S/NUMBER-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                               TRIM (REPLACE ('CPE S/NUMBER-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NTU S/NUMBER-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                               TRIM (REPLACE ('NTU S/NUMBER-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU TYPE-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                   TRIM (REPLACE ('NTU TYPE-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                  TRIM (REPLACE ('NTU MODEL-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'CPE MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                                  TRIM (REPLACE ('CPE MODEL-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                         TRIM (REPLACE ('ADDITIONAL NTU MODEL-A END',
                                        '-A END')
                              );
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'CPE S/NUMBER-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                               TRIM (REPLACE ('CPE S/NUMBER-A END', '-A END'));
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU S/NUMBER-A END'
            THEN
               UPDATE service_order_attributes soa
                  SET soa.seoa_defaultvalue = v_so_att_val
                WHERE soa.seoa_sero_id = v_bearer_so_id
                  AND soa.seoa_name =
                               TRIM (REPLACE ('NTU S/NUMBER-A END', '-A END'));
                               
         /* ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-A END','-A END'));*/

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU TYPE-A END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU MODEL-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'CPE MODEL-A END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-A END','-A END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'CPE S/NUMBER-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-A END','-A END'));          
          
          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU TYPE-A END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU MODEL-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'CPE MODEL-A END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-A END','-A END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'CPE S/NUMBER-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-A END','-A END'));   
          
         ---- 
      
          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU TYPE-A END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU MODEL-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'CPE MODEL-A END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-A END','-A END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'CPE S/NUMBER-A END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-A END','-A END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-A END','-A END')); 
   
            END IF;
         ELSIF v_cir_status = 'INSERVICE'
         THEN
            IF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name = 'NTU TYPE-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                   TRIM (REPLACE ('NTU TYPE-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NTU MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('NTU MODEL-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'CPE MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('CPE MODEL-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('ADDITIONAL NTU MODEL-A END',
                                        '-A END')
                              )
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'CPE S/NUMBER-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('CPE S/NUMBER-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'CREATE'
                  AND v_so_attr_name = 'NTU S/NUMBER-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('NTU S/NUMBER-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU TYPE-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                   TRIM (REPLACE ('NTU TYPE-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('NTU MODEL-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'CPE MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('CPE MODEL-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('ADDITIONAL NTU MODEL-A END',
                                        '-A END')
                              )
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'CPE S/NUMBER-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('CPE S/NUMBER-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
            ELSIF     v_service_type = 'D-EDL'
                  AND v_service_order = 'MODIFY-SPEED'
                  AND v_so_attr_name = 'NTU S/NUMBER-A END'
            THEN
               UPDATE services_attributes sa
                  SET sa.satt_defaultvalue = v_so_att_val
                WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('NTU S/NUMBER-A END', '-A END'))
                  AND sa.satt_serv_id = v_cir_id;
                  
             /*ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN UPDATE services_attributes sa  
              SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-A END','-A END'))
               AND sa.satt_serv_id = v_cir_id;*/

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER'
               AND v_so_attr_name = 'NTU TYPE-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU MODEL-A END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'CPE MODEL-A END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-A END','-A END')) 
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id;  

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'CPE S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 
              
              ----
              
              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION'
               AND v_so_attr_name = 'NTU TYPE-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NTU MODEL-A END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'CPE MODEL-A END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-A END','-A END')) 
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id;  

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'CPE S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 
              
              ------------
                ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR'
               AND v_so_attr_name = 'NTU TYPE-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NTU MODEL-A END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'CPE MODEL-A END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-A END','-A END')) 
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id;  

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-A END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'CPE S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NTU S/NUMBER-A END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-A END','-A END'))
              AND sa.satt_serv_id = v_cir_id; 
          
              -------------
              
            
            END IF;
         END IF;

         IF     v_service_type = 'D-EDL'
            AND v_service_order =
                   'CREATE'
          --AND (v_cir_status = 'COMMISSIONED')-- OR v_cir_status = 'INSERVICE')
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = 'INSERVICE'
             WHERE soa.seoa_name = 'ACC. BEARER STATUS-A END'
               AND soa.seoa_sero_id = p_sero_id;
         ELSIF v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'-- AND v_cir_status = 'COMMISSIONED'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = 'INSERVICE'
             WHERE soa.seoa_name = 'ACC. BEARER STATUS-A END'
               AND soa.seoa_sero_id = p_sero_id;
         ELSIF v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' --AND v_cir_status = 'COMMISSIONED'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = 'INSERVICE'
             WHERE soa.seoa_name = 'ACC. BEARER STATUS-A END'
               AND soa.seoa_sero_id = p_sero_id;
               
       ELSIF v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' --AND v_cir_status = 'COMMISSIONED'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = 'INSERVICE'
             WHERE soa.seoa_name = 'ACC. BEARER STATUS-A END'
               AND soa.seoa_sero_id = p_sero_id;
               
       ELSIF v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' --AND v_cir_status = 'COMMISSIONED'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = 'INSERVICE'
             WHERE soa.seoa_name = 'ACC. BEARER STATUS-A END'
               AND soa.seoa_sero_id = p_sero_id;
               
         END IF;
      END LOOP;

      CLOSE so_copyattr;
   END IF;

   OPEN v_bearer_bend;

   FETCH v_bearer_bend
    INTO v_bearer_id_bnd;

   IF v_bearer_id_bnd IS NOT NULL
   THEN
      OPEN so_copyattr_bnd (v_bearer_id_bnd);

      FETCH so_copyattr_bnd
       INTO v_bearer_so_id_bnd, v_cir_status_bnd, v_cir_id_bnd;

      IF     v_service_type = 'D-EDL'
         AND v_service_order =
                'CREATE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = 'INSERVICE'
          WHERE soa.seoa_name = 'ACC. BEARER STATUS-B END'
            AND soa.seoa_sero_id = p_sero_id;
      END IF;

      IF     v_service_type = 'D-EDL'
         AND v_service_order =
                'MODIFY-SPEED'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = 'INSERVICE'
          WHERE soa.seoa_name = 'ACC. BEARER STATUS-B END'
            AND soa.seoa_sero_id = p_sero_id;
      END IF;
      
        IF     v_service_type = 'D-EDL'
         AND v_service_order =
                'CREATE-TRANSFER'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = 'INSERVICE'
          WHERE soa.seoa_name = 'ACC. BEARER STATUS-B END'
            AND soa.seoa_sero_id = p_sero_id;
      END IF;
      
      IF     v_service_type = 'D-EDL'
         AND v_service_order =
                'MODIFY-LOCATION'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = 'INSERVICE'
          WHERE soa.seoa_name = 'ACC. BEARER STATUS-B END'
            AND soa.seoa_sero_id = p_sero_id;
      END IF;
      
            IF     v_service_type = 'D-EDL'
         AND v_service_order =
                'CREATE-OR'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = 'INSERVICE'
          WHERE soa.seoa_name = 'ACC. BEARER STATUS-B END'
            AND soa.seoa_sero_id = p_sero_id;
      END IF;

--CLOSE so_copyattr;
      CLOSE v_bearer_bend;

      CLOSE so_copyattr_bnd;
   END IF;

   OPEN so_att_mapping_b;

   LOOP
      FETCH so_att_mapping_b
       INTO v_so_attr_name_b, v_so_att_val_b;

      EXIT WHEN so_att_mapping_b%NOTFOUND;

      IF v_cir_status_bnd = 'COMMISSIONED'
      THEN
         IF     v_service_type = 'D-EDL'
            AND v_service_order = 'CREATE'
            AND v_so_attr_name_b = 'NTU TYPE-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name = TRIM (REPLACE ('NTU TYPE-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NTU MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                                  TRIM (REPLACE ('NTU MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'CPE MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                                  TRIM (REPLACE ('CPE MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'ADDITIONAL NTU MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                       TRIM (REPLACE ('ADDITIONAL NTU MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NO OF COPPER PAIRS-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'CPE S/NUMBER-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                               TRIM (REPLACE ('CPE S/NUMBER-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NTU S/NUMBER-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                               TRIM (REPLACE ('NTU S/NUMBER-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU TYPE-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name = TRIM (REPLACE ('NTU TYPE-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                                  TRIM (REPLACE ('NTU MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'CPE MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                                  TRIM (REPLACE ('CPE MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'ADDITIONAL NTU MODEL-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                       TRIM (REPLACE ('ADDITIONAL NTU MODEL-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NO OF COPPER PAIRS-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'CPE S/NUMBER-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                               TRIM (REPLACE ('CPE S/NUMBER-B END', '-B END'));
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU S/NUMBER-B END'
         THEN
            UPDATE service_order_attributes soa
               SET soa.seoa_defaultvalue = v_so_att_val_b
             WHERE soa.seoa_sero_id = v_bearer_so_id_bnd
               AND soa.seoa_name =
                               TRIM (REPLACE ('NTU S/NUMBER-B END', '-B END'));
                               
       ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU TYPE-B END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU MODEL-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'CPE MODEL-B END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-B END','-B END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'CPE S/NUMBER-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));
          
          
          --
          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU TYPE-B END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU MODEL-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'CPE MODEL-B END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-B END','-B END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'CPE S/NUMBER-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));
          --
                           
          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU TYPE-B END' 
          THEN UPDATE service_order_attributes soa 
            SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU TYPE-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU MODEL-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'CPE MODEL-B END' 
          THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_att_val 
            WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END' 
          THEN UPDATE service_order_attributes soa 
          SET soa.seoa_defaultvalue = v_so_att_val WHERE soa.seoa_sero_id = v_bearer_so_id
          AND soa.seoa_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR'  
          AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NO OF COPPER PAIRS-B END','-B END')); 

          ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'CPE S/NUMBER-B END'
          THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('CPE S/NUMBER-B END','-B END'));

          ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
          AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val 
          WHERE soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = trim(replace('NTU S/NUMBER-B END','-B END'));
    
         END IF;
      ELSIF v_cir_status = 'INSERVICE'
      THEN
         IF     v_service_type = 'D-EDL'
            AND v_service_order = 'CREATE'
            AND v_so_attr_name_b = 'NTU TYPE-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                   TRIM (REPLACE ('NTU TYPE-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NTU MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('NTU MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'CPE MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('CPE MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'ADDITIONAL NTU MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                       TRIM (REPLACE ('ADDITIONAL NTU MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NO OF COPPER PAIRS-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'CPE S/NUMBER-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('CPE S/NUMBER-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'CREATE'
               AND v_so_attr_name_b = 'NTU S/NUMBER-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('NTU S/NUMBER-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU TYPE-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                   TRIM (REPLACE ('NTU TYPE-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('NTU MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'CPE MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                                  TRIM (REPLACE ('CPE MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'ADDITIONAL NTU MODEL-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                       TRIM (REPLACE ('ADDITIONAL NTU MODEL-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NO OF COPPER PAIRS-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                         TRIM (REPLACE ('NO OF COPPER PAIRS-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'CPE S/NUMBER-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('CPE S/NUMBER-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
         ELSIF     v_service_type = 'D-EDL'
               AND v_service_order = 'MODIFY-SPEED'
               AND v_so_attr_name_b = 'NTU S/NUMBER-B END'
         THEN
            UPDATE services_attributes sa
               SET sa.satt_defaultvalue = v_so_att_val_b
             WHERE sa.satt_attribute_name =
                               TRIM (REPLACE ('NTU S/NUMBER-B END', '-B END'))
               AND sa.satt_serv_id = v_cir_id;
               
           ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN UPDATE services_attributes sa  
              SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
               AND sa.satt_serv_id = v_cir_id;

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER'
               AND v_so_attr_name = 'NTU TYPE-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU MODEL-B END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'CPE MODEL-B END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-B END','-B END')) 
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;  

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'CPE S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-TRANSFER' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;      
              
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN UPDATE services_attributes sa  
              SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
               AND sa.satt_serv_id = v_cir_id;

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION'
               AND v_so_attr_name = 'NTU TYPE-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 
              
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NTU MODEL-B END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'CPE MODEL-B END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-B END','-B END')) 
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;  

              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'CPE S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'MODIFY-LOCATION' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;    
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN UPDATE services_attributes sa  
              SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
               AND sa.satt_serv_id = v_cir_id;

              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR'
               AND v_so_attr_name = 'NTU TYPE-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU TYPE-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NTU MODEL-B END' 
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 
              ELSIF     v_service_type = 'D-EDL' AND  v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'CPE MODEL-B END'  
              THEN UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE MODEL-B END','-B END')) 
              AND sa.satt_serv_id = v_cir_id; 
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
               AND v_so_attr_name = 'ADDITIONAL NTU MODEL-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('ADDITIONAL NTU MODEL-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;  
              ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NO OF COPPER PAIRS-B END'
              THEN  UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NO OF COPPER PAIRS-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 
              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'CPE S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('CPE S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id; 
              ELSIF     v_service_type = 'D-EDL'  AND v_service_order = 'CREATE-OR' 
              AND v_so_attr_name = 'NTU S/NUMBER-B END' THEN 
              UPDATE services_attributes sa SET sa.satt_defaultvalue = v_so_att_val
              WHERE sa.satt_attribute_name = trim(replace('NTU S/NUMBER-B END','-B END'))
              AND sa.satt_serv_id = v_cir_id;    
              --
               
         END IF;
      END IF;
   END LOOP;
   CLOSE so_att_mapping_b;IF v_service_type = 'D-EDL' AND v_service_order = 'CREATE-TRANSFER' THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-A END' AND SOA.SEOA_SERO_ID = p_sero_id; 
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-B END' AND SOA.SEOA_SERO_ID = p_sero_id;
END IF; IF v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-LOCATION' THEN
 UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
 WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-A END' AND SOA.SEOA_SERO_ID = p_sero_id; 
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-B END' AND SOA.SEOA_SERO_ID = p_sero_id; 
END IF; IF v_service_type = 'D-EDL' AND v_service_order = 'CREATE-OR' THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
 WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-A END' AND SOA.SEOA_SERO_ID = p_sero_id; 
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = REPLACE(SOA.SEOA_DEFAULTVALUE,'(N)')
WHERE  SOA.SEOA_NAME = 'ACCESS BEARER ID-B END' AND SOA.SEOA_SERO_ID = p_sero_id;  END IF;



   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D-EDL  Attribute Mapping   function. Please check the conditions:'
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
                   p_ret_msg
                  );
END D_EDL_CREATE_BEA_AT_MAP;
--- Jayan Liyanage 2013/04/03 updated on 04/12/2013


--- Jayan Liyanage 2013/05/27 Updated with CONFIRM  W/ CUSTOMER TASK on 01/07/2014 

PROCEDURE D_EDL_ACT_TX(
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

v_Tx_a            varchar2(100);                     
v_Tx_b            varchar2(100);
v_service_type    varchar2(100);
v_service_order   varchar2(100);
acc_nw_intr_a     varchar2(100);
acc_nw_intr_b     varchar2(100);
agr_nw_a          varchar2(100);
agr_nw_b          varchar2(100);
v_acc_li_type_a   varchar2(100);
v_acc_li_type_b   varchar2(100);

BEGIN
  
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id; 

SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

select distinct soa.seoa_defaultvalue INTO v_Tx_a from service_order_attributes soa 
where soa.seoa_name = 'TX WORK GROUP-A END'  AND soa.seoa_sero_id = p_sero_id;
select distinct soa.seoa_defaultvalue INTO v_Tx_b  from service_order_attributes soa 
where soa.seoa_name = 'TX WORK GROUP-B END'  AND soa.seoa_sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue INTO acc_nw_intr_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-A END';
SELECT soa.seoa_defaultvalue INTO acc_nw_intr_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-B END';
SELECT soa.seoa_defaultvalue INTO agr_nw_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'AGG. NETWORK-A END';
SELECT soa.seoa_defaultvalue  INTO agr_nw_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'AGG. NETWORK-B END';

IF (v_acc_li_type_a = 'DAB' or  v_acc_li_type_a = 'DEDICATED LINE' or  v_acc_li_type_a = 'NONE') THEN IF    v_service_type = 'D-EDL'AND 
v_service_order = 'CREATE'  AND (acc_nw_intr_a = 'SDH PORT' or  agr_nw_a = 'SDH') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_Tx_a
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TX LINK-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-A'; 
END IF;   ELSIF (v_acc_li_type_a <> 'DAB' or  v_acc_li_type_a <> 'DEDICATED LINE' ) THEN 
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-A'; 
END IF;
IF (v_acc_li_type_b = 'DAB' or  v_acc_li_type_b = 'DEDICATED LINE'or v_acc_li_type_b = 'NONE' ) THEN
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'SDH PORT' AND  agr_nw_b = 'SDH') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_Tx_b
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TX LINK-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-B'; 
END IF;  ELSIF (v_acc_li_type_b <> 'DAB' or  v_acc_li_type_b <> 'DEDICATED LINE') THEN
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-B';END IF;


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT'OR acc_nw_intr_b = 'MLLN PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_nw_intr_b = 'MEN PORT'THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
 acc_nw_intr_b = 'CEN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
 (acc_nw_intr_b = 'SDH PORT' OR acc_nw_intr_b = 'OTN PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_Tx_b
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; ELSE
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; END IF;

p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION WHEN OTHERS THEN
p_ret_msg :='EDL Create  sub Function Failed   :  - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);

END D_EDL_ACT_TX;

--- Jayan Liyanage 2013/05/27

--- Jayan Liyanage 2013/04/02 CONFIRM  W/ CUSTOMER task removed from CREATE order type on 01/07/2014

PROCEDURE D_BL_CREATE (
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


CURSOR pre_cir (v_old_ids VARCHAR) IS SELECT DISTINCT c.cirt_status FROM circuits c WHERE c.cirt_displayname = v_old_ids;
CURSOR cur_tributer (parent_name VARCHAR2,v_new_cir_id varchar2 ) IS SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
FROM circuits c, circuit_hierarchy ch, circuits ci WHERE c.cirt_name = ch.cirh_parent
AND ch.cirh_child = ci.cirt_name AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')AND (   ci.cirt_status NOT LIKE 'CANCE%'
OR ci.cirt_status NOT LIKE 'PENDING%')AND ci.CIRT_DISPLAYNAME not like replace(v_new_cir_id,'(N)') ||'%' AND c.cirt_displayname = parent_name;               

CURSOR cur_Old_tributer (old_parent_name VARCHAR2,v_new_cir_id varchar2 )IS SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
FROM circuits c, circuit_hierarchy ch, circuits ci WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name
AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%' OR ci.cirt_status LIKE 'SUSPEND%'
OR ci.cirt_status LIKE 'COMMISS%')AND (   ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%'
) AND ci.CIRT_DISPLAYNAME not like replace(v_new_cir_id,'(N)') ||'%' AND c.cirt_displayname = old_parent_name;

cursor Cur_a_s( a_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  
from circuits ci where ci.cirt_displayname like replace(a_cir,'(N)')||'%'
and  ci.cirt_inservice = (select max(c.cirt_inservice)
from circuits c where c.cirt_displayname like replace(a_cir,'(N)')||'%');

cursor Cur_b_s( b_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  
from circuits ci where  ci.cirt_displayname like replace(b_cir,'(N)')||'%'
and ci.cirt_inservice = (select max(c.cirt_inservice)
from circuits c where c.cirt_displayname like replace(b_cir,'(N)')||'%');

acc_nw_intr_a             VARCHAR2 (100);
acc_nw_intr_b             VARCHAR2 (100);
acc_bearer_a_sta          VARCHAR2 (100);
acc_bearer_b_sta          VARCHAR2 (100);
acc_lin_a                 VARCHAR2 (100);
acc_lin_b                 VARCHAR2 (100);
acc_medi_a                VARCHAR2 (100);
acc_medi_b                VARCHAR2 (100);
acc_fib_a                 VARCHAR2 (100);
acc_fib_b                 VARCHAR2 (100);
back_b_capacity_a         VARCHAR2 (100);
back_b_capacity_b         VARCHAR2 (100);
agr_nw_a                  VARCHAR2 (100);
agr_nw_b                  VARCHAR2 (100);
Ntu_Cls_a                 VARCHAR2 (100);
Ntu_Cls_b                 VARCHAR2 (100);
Ntu_model_chg_a           VARCHAR2 (100);
Ntu_model_chg_b           VARCHAR2 (100);
cpe_Cls_a                 VARCHAR2 (100);
cpe_Cls_b                 VARCHAR2 (100);
cur_cpe_model_a           VARCHAR2 (100);
pre_cpe_model_a           VARCHAR2 (100);
cur_cpe_model_b           VARCHAR2 (100);
pre_cpe_model_b           VARCHAR2 (100);
Ser_cteg                  VARCHAR2 (100);
Test_Sr_Al                VARCHAR2 (100);
v_acc_id_a                VARCHAR2 (100);
v_acc_id_b                VARCHAR2 (100);
v_service_order_area_a    VARCHAR2 (100);
v_service_order_area_b    VARCHAR2 (100);
v_rtom_code_aa            VARCHAR2 (100);
v_lea_code_aa             VARCHAR2 (100);
v_work_group_a_os         VARCHAR2 (100);
--v_work_group_a_nw         VARCHAR2 (100);
v_work_group_a_cpe        VARCHAR2 (100);
v_rtom_code_bb            VARCHAR2 (100);
v_lea_code_bb             VARCHAR2 (100);
v_work_group_b_nw         VARCHAR2 (100);
--v_work_group_a_cpe        VARCHAR2 (100);
v_section_hndle           VARCHAR2 (100);
v_service_order           VARCHAR2 (100);
v_service_type            VARCHAR2 (100);
v_work_group_a_nw         VARCHAR2 (100);
v_work_group_b_os         VARCHAR2 (100);
v_loc_a_cir_dis           VARCHAR2(100);
v_loc_a_cir_Sta           VARCHAR2(100);
v_loc_b_cir_dis           VARCHAR2(100);
v_loc_b_cir_Sta           VARCHAR2(100);
v_acc_li_type_a           VARCHAR2(100);
v_acc_li_type_b           VARCHAR2(100);
v_fib_avalable_a          VARCHAR2(100);
v_fib_avalable_b          VARCHAR2(100);

BEGIN

SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type
FROM service_orders so WHERE so.sero_id =  p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order 
FROM service_orders so WHERE so.sero_id =  p_sero_id;
SELECT soa.seoa_defaultvalue INTO v_section_hndle
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'SECTION HANDLED BY';

SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

IF (v_acc_li_type_a = 'DAB') THEN SELECT distinct soa.seoa_defaultvalue INTO v_acc_id_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';END IF;
IF (v_acc_li_type_b = 'DAB') THEN SELECT distinct soa.seoa_defaultvalue INTO v_acc_id_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';END IF;

if  v_acc_id_a is not null then  open Cur_a_s(v_acc_id_a); fetch Cur_a_s into v_loc_a_cir_dis,v_loc_a_cir_Sta ; close Cur_a_s; end if;
if v_acc_id_b is not null then open Cur_b_s(v_acc_id_b); fetch Cur_b_s into v_loc_b_cir_dis,v_loc_b_cir_Sta; close Cur_b_s; end if;

IF (v_acc_li_type_a = 'DAB'  or  v_acc_li_type_a  = 'DEDICATED LINE' or v_acc_li_type_a = 'NONE' )  THEN  
  
/*  IF (v_loc_a_cir_Sta = 'COMMISSIONED' OR v_loc_a_cir_Sta LIKE 'PROPOSED%')  THEN 
select distinct soa.seoa_defaultvalue
into v_service_order_area_a
from service_orders so,service_order_attributes soa,circuits ci
where soa.seoa_name = 'EXCHANGE_AREA_CODE' 
and ( ci.cirt_status like 'COMM%' OR ci.cirt_status like 'PROP%')
and so.sero_cirt_name = ci.cirt_name
and so.sero_id = soa.seoa_sero_id
and ci.cirt_displayname = v_loc_a_cir_dis;
ELSIF v_loc_a_cir_Sta = 'INSERVICE'  THEN
select distinct sa.satt_defaultvalue into v_service_order_area_a from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_loc_a_cir_dis;end if;*/

SELECT soa.seoa_defaultvalue INTO v_service_order_area_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';
SELECT soa.seoa_defaultvalue INTO acc_nw_intr_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-A END';
SELECT soa.seoa_defaultvalue INTO acc_bearer_a_sta FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-A END';
SELECT soa.seoa_defaultvalue INTO acc_lin_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT soa.seoa_defaultvalue INTO acc_medi_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END';
SELECT soa.seoa_defaultvalue INTO acc_fib_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. FIBER AVAILABLE?-A END';
SELECT soa.seoa_defaultvalue  INTO back_b_capacity_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NEED B/BONE CAPACITY?-A END';
SELECT soa.seoa_defaultvalue INTO agr_nw_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'AGG. NETWORK-A END';
SELECT soa.seoa_defaultvalue  INTO Ntu_Cls_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU CLASS-A END';
SELECT soa.seoa_defaultvalue INTO Ntu_model_chg_a FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?-A END';
SELECT soa.seoa_defaultvalue  INTO cpe_Cls_a FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE CLASS-A END';
SELECT soa.seoa_defaultvalue,soa.seoa_prev_value INTO cur_cpe_model_a,pre_cpe_model_a
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE MODEL-A END';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_aa,v_lea_code_aa FROM areas ar WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_a_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'OSP-NC' || '%';                  
SELECT wg.worg_name INTO v_work_group_a_nw FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'ENG-NW' || '%';
SELECT wg.worg_name INTO v_work_group_a_cpe FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'CPE-NC' || '%';END IF;

select distinct soa.seoa_defaultvalue into v_fib_avalable_a  from service_order_attributes soa 
where soa.seoa_name = 'ACC. FIBER AVAILABLE?-A END' and soa.seoa_sero_id = p_sero_id;
select distinct soa.seoa_defaultvalue into v_fib_avalable_b  from service_order_attributes soa 
where soa.seoa_name = 'ACC. FIBER AVAILABLE?-B END' and soa.seoa_sero_id = p_sero_id;



IF ( v_acc_li_type_b = 'DAB'  or v_acc_li_type_b =  'DEDICATED LINE' or v_acc_li_type_b = 'NONE') THEN 
  
/*  IF (v_loc_b_cir_Sta = 'COMMISSIONED' OR v_loc_b_cir_Sta LIKE 'PROPOSED%') THEN 
select distinct soa.seoa_defaultvalue
into v_service_order_area_b
from service_orders so,service_order_attributes soa,circuits ci
where soa.seoa_name = 'EXCHANGE_AREA_CODE' 
and ( ci.cirt_status like 'COMM%' OR ci.cirt_status like 'PROP%')
and so.sero_cirt_name = ci.cirt_name
and so.sero_id = soa.seoa_sero_id
and ci.cirt_displayname = v_loc_b_cir_dis;ELSIF v_loc_b_cir_Sta = 'INSERVICE' THEN
select distinct sa.satt_defaultvalue into v_service_order_area_b from services_attributes sa,circuits c 
where sa.satt_serv_id = c.cirt_serv_id and c.cirt_status = 'INSERVICE' 
and sa.satt_attribute_name = 'EXCHANGE_AREA_CODE' and c.cirt_displayname = v_loc_b_cir_dis; end if;*/

SELECT soa.seoa_defaultvalue INTO v_service_order_area_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';

SELECT soa.seoa_defaultvalue INTO acc_nw_intr_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-B END';
SELECT soa.seoa_defaultvalue INTO acc_bearer_b_sta FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
SELECT soa.seoa_defaultvalue INTO acc_lin_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';
SELECT soa.seoa_defaultvalue INTO acc_medi_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END';
SELECT soa.seoa_defaultvalue INTO acc_fib_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. FIBER AVAILABLE?-B END';
SELECT soa.seoa_defaultvalue  INTO back_b_capacity_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NEED B/BONE CAPACITY?-B END';
SELECT soa.seoa_defaultvalue  INTO agr_nw_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'AGG. NETWORK-B END';
SELECT soa.seoa_defaultvalue  INTO Ntu_Cls_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU CLASS-B END';
SELECT soa.seoa_defaultvalue  INTO Ntu_model_chg_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?-B END';
SELECT soa.seoa_defaultvalue  INTO cpe_Cls_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE CLASS-B END';
SELECT soa.seoa_defaultvalue,soa.seoa_prev_value INTO cur_cpe_model_b,pre_cpe_model_b
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE MODEL-B END'; 

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_bb,v_lea_code_bb FROM areas ar WHERE ar.area_code = v_service_order_area_b AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_b_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC' || '%';                  
SELECT wg.worg_name INTO v_work_group_b_nw FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'ENG-NW' || '%';
SELECT wg.worg_name INTO v_work_group_a_cpe FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'CPE-NC' || '%';END IF; 
SELECT soa.seoa_defaultvalue INTO Ser_cteg FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';
--SELECT soa.seoa_defaultvalue INTO Test_Sr_Al FROM service_order_attributes soa
--WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'TEST SERVICE ALTERED?';

IF (v_acc_li_type_a = 'DAB' or v_acc_li_type_a = 'DEDICATED LINE' or v_acc_li_type_a = 'NONE' or v_acc_li_type_a = 'CUSTOMER-DED LINE') THEN  IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MSAN PORT' OR acc_nw_intr_a = 'DSLAM PORT') AND acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'VERIFY NTU-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'VERIFY NTU-A END'; END IF;  
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  acc_lin_a  = 'DEDICATED LINE' 
AND acc_medi_a = 'FIBER' AND acc_fib_a = 'NO'  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'START FIBER LAYING-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'START FIBER LAYING-A'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE MLLN PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE MLLN PORT-A'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  acc_lin_a  = 'DEDICATED LINE' 
AND acc_medi_a = 'FIBER' AND acc_fib_a = 'YES'  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE ACC FIBER-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE ACC FIBER-A'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'MEN PORT' AND acc_bearer_a_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG MEN PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MEN PORT-A'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'CEN PORT' AND acc_bearer_a_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG CEN PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG CEN PORT-A'; END IF;  

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'MPLS PORT' AND acc_bearer_a_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG MPLS PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MPLS PORT-A'; END IF;  */
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'MEN PORT' AND acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG MEN SUB PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG MEN SUB PORT-A'; END IF;  
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'CEN PORT' AND acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG CEN SUB PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG CEN SUB PORT-A'; END IF;  
/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_a = 'MPLS PORT' AND acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG MPL SUB PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG MPL SUB PORT-A'; END IF;  */

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MSAN PORT' or acc_nw_intr_a = 'DSLAM PORT') AND acc_bearer_a_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. SHDSL PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. SHDSL PORT-A'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MSAN PORT' or acc_nw_intr_a = 'DSLAM PORT')  AND acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. TRIB. PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. TRIB. PORT-A'; END IF;  

/*
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_a = 'SDH PORT' AND  agr_nw_a = 'SDH') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TX LINK-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-A'; 
END IF;  */

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_a = 'P2P RADIO' and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTAL SLT-END NTU-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTAL SLT-END NTU-A'; END IF;  

-- Jayan Liyanage Modified 2014/10/24
--
/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_a = 'FIBER' and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'WAIT FOR FIBER-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'WAIT FOR FIBER-A END'; END IF;*/


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_a = 'FIBER' and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE') 
AND ( v_fib_avalable_a = 'NO' OR v_fib_avalable_a = 'INCOMPLETE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'SFC-SOM-DATA' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'WAIT FOR FIBER-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'WAIT FOR FIBER-A END'; END IF;

-- Jayan Liyanage Modified 2014/10/24
  --


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_a = 'P2P RADIO' and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'TX-RADIO-LAB' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'SETUP RADIO LINK-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'SETUP RADIO LINK-A'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_a = 'COPPER' and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONSTRUCT OSP LINE-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONSTRUCT OSP LINE-A'; END IF;  
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND ( acc_nw_intr_a = 'MSAN PORT' or acc_nw_intr_a = 'DSLAM PORT') 
AND acc_bearer_a_sta = 'INSERVICE' AND Ntu_Cls_a = 'SLT'AND Ntu_model_chg_a = 'NO'   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG NTU-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-A END'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_a = 'SLT'
and (acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE')      THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTALL CPE-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTALL CPE-A END'; END IF; 
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND (acc_medi_a = 'FIBER' or acc_medi_a = 'COPPER-UTP') and
( acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_nw
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ESTAB_ACCESS_LINK-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ESTAB_ACCESS_LINK-A'; END IF;  

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_a = 'SLT'
and (acc_bearer_a_sta = 'COMMISSIONED' or acc_lin_a = 'DEDICATED LINE')      THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTALL CPE-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTALL CPE-A END'; END IF; */
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND ( acc_nw_intr_a = 'MSAN PORT' or acc_nw_intr_a = 'DSLAM PORT') 
AND acc_bearer_a_sta = 'INSERVICE' AND Ntu_Cls_a = 'SLT'AND Ntu_model_chg_a = 'YES'   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY NTU-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY NTU-A END'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_a = 'SLT' AND cur_cpe_model_a <> pre_cpe_model_a 
AND  (acc_bearer_a_sta = 'INSERVICE' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG CPE-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG CPE-A END'; END IF; 
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_a = 'SLT' AND cur_cpe_model_a <> pre_cpe_model_a 
AND  (acc_bearer_a_sta = 'INSERVICE' or acc_lin_a = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY CPE-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CPE-A END'; END IF; 
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_bearer_a_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-FO'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. ACC BEARER-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. ACC BEARER-A'; END IF;
/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_bearer_a_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-FO'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'UPDATE ACC BEARER-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'UPDATE ACC BEARER-A'; END IF;  */

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND   acc_nw_intr_a = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MLLN PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MLLN PORT-A'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND   acc_medi_a = 'CUSTOMER-OWN' 
  AND ( acc_bearer_a_sta = 'COMMISSIONED'
  OR acc_lin_a = 'CUSTOMER-DED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_a_nw
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'PATCH CUST.LINK-A ND'; 
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id =  p_sero_id
   AND sit.seit_taskname = 'PATCH CUST.LINK-A ND'; END IF;


ELSIF  (v_acc_li_type_a <> 'DAB' or v_acc_li_type_a <>  'DEDICATED LINE' or  v_acc_li_type_a <>  'NONE' or acc_lin_b = 'CUSTOMER-DED LINE') THEN DELETE service_implementation_tasks sit  WHERE sit.seit_sero_id =  p_sero_id AND  sit.seit_taskname IN (
'VERIFY NTU-A END','START FIBER LAYING-A','RESERVE MLLN PORT-A','RESERVE ACC FIBER-A','CONFIG MEN PORT-A','CONFIG CEN PORT-A',/*'CONFIG MPLS PORT-A',*/'CONFG MEN SUB PORT-A',
'CONFG CEN SUB PORT-A',/*'CONFG MPL SUB PORT-A',*/'ACTIV. SHDSL PORT-A','ACTIV. TRIB. PORT-A', 'INSTAL SLT-END NTU-A','WAIT FOR FIBER-A END','SETUP RADIO LINK-A','CONSTRUCT OSP LINE-A',
'RECONFIG NTU-A END','INSTALL CPE-A END','ESTAB_ACCESS_LINK-A','MODIFY NTU-A END','RECONFIG CPE-A END','MODIFY CPE-A END','ACTIV. ACC BEARER-A',/*'UPDATE ACC BEARER-A'*/'CONFIG MLLN PORT-A','PATCH CUST.LINK-A ND');END IF;

IF ( v_acc_li_type_b = 'DAB' or v_acc_li_type_b = 'DEDICATED LINE'or v_acc_li_type_b = 'NONE') THEN IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'VERIFY NTU-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'VERIFY NTU-B END'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  acc_lin_b  = 'DEDICATED LINE' 
AND acc_medi_b = 'FIBER' AND acc_fib_b = 'NO'  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'START FIBER LAYING-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'START FIBER LAYING-B'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE MLLN PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE MLLN PORT-B'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  acc_lin_b  = 'DEDICATED LINE' 
AND acc_medi_b = 'FIBER' AND acc_fib_b = 'YES'  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE ACC FIBER-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE ACC FIBER-B'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'MEN PORT' AND acc_bearer_b_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG MEN PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MEN PORT-B'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'CEN PORT' AND acc_bearer_b_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG CEN PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG CEN PORT-B'; END IF;  

/*
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'MPLS PORT' AND acc_bearer_b_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG MPLS PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MPLS PORT-B'; END IF;  */


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'MEN PORT' AND acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG MEN SUB PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG MEN SUB PORT-B'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'CEN PORT' AND acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG CEN SUB PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG CEN SUB PORT-B'; END IF;  

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
acc_nw_intr_b = 'MPLS PORT' AND acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFG MPL SUB PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFG MPL SUB PORT-B'; END IF;  */

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_b = 'MSAN PORT' or acc_nw_intr_b = 'DSLAM PORT')  AND acc_bearer_b_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. SHDSL PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. SHDSL PORT-B'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_b = 'MSAN PORT' or acc_nw_intr_b = 'DSLAM PORT')  AND acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. TRIB. PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. TRIB. PORT-B'; END IF; 

/*
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'SDH PORT' AND  agr_nw_b = 'SDH') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TX LINK-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK-B'; 
END IF;  */
--

-- Jayan Liyanage Modified 2014/10/24

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_b = 'FIBER' and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'CORP-SSU' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'WAIT FOR FIBER-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'WAIT FOR FIBER-B END'; END IF;  --*/

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_b = 'FIBER' and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') 
AND ( v_fib_avalable_b = 'NO' OR v_fib_avalable_b = 'INCOMPLETE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'SFC-SOM-DATA' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'WAIT FOR FIBER-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'WAIT FOR FIBER-B END'; END IF;

-- Jayan Liyanage Modified End. 2014/10/24

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_b = 'P2P RADIO' and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTAL SLT-END NTU-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTAL SLT-END NTU-B'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_b = 'P2P RADIO' and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'TX-RADIOLAB' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'SETUP RADIO LINK-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'SETUP RADIO LINK-B'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND acc_medi_b = 'COPPER' and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONSTRUCT OSP LINE-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONSTRUCT OSP LINE-B'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND (acc_medi_b = 'FIBER' or acc_medi_b = 'COPPER-UTP') and
( acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_nw
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ESTAB_ACCESS_LINK-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ESTAB_ACCESS_LINK-B'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND ( acc_nw_intr_b = 'MSAN PORT' or acc_nw_intr_b = 'DSLAM PORT') 
AND acc_bearer_b_sta = 'INSERVICE' AND Ntu_Cls_b = 'SLT'AND Ntu_model_chg_b = 'NO'   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG NTU-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-B END'; END IF; 


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND ( acc_nw_intr_b = 'MSAN PORT' or acc_nw_intr_b = 'DSLAM PORT') 
AND acc_bearer_b_sta = 'INSERVICE' AND Ntu_Cls_b = 'SLT'AND Ntu_model_chg_b = 'YES'   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY NTU-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY NTU-B END'; END IF; 


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_b = 'SLT'
and (acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE')      THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTALL CPE-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTALL CPE-B END'; END IF; 

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_b = 'SLT'
and (acc_bearer_b_sta = 'COMMISSIONED' or acc_lin_b = 'DEDICATED LINE')      THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'INSTALL CPE-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'INSTALL CPE-B END'; END IF; 

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_b = 'SLT' AND cur_cpe_model_b <> pre_cpe_model_b 
AND  (acc_bearer_b_sta = 'INSERVICE' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY CPE-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CPE-B END'; END IF; 
 

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND cpe_Cls_b = 'SLT' AND cur_cpe_model_b <> pre_cpe_model_b 
AND  (acc_bearer_b_sta = 'INSERVICE' or acc_lin_b = 'DEDICATED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG CPE-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG CPE-B END'; END IF; 


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_bearer_b_sta = 'COMMISSIONED' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-FO'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIV. ACC BEARER-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIV. ACC BEARER-B'; END IF;

/*
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_bearer_b_sta = 'INSERVICE' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-FO'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'UPDATE ACC BEARER-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'UPDATE ACC BEARER-B'; END IF;*/

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND   acc_nw_intr_b = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MLLN PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG MLLN PORT-B'; END IF;

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND   acc_medi_b = 'CUSTOMER-OWN' 
  AND ( acc_bearer_b_sta = 'COMMISSIONED'
  OR acc_lin_b = 'CUSTOMER-DED LINE') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_nw
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'PATCH CUST.LINK-B ND'; 
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id =  p_sero_id
   AND sit.seit_taskname = 'PATCH CUST.LINK-B ND'; END IF;

ELSIF ( v_acc_li_type_b <> 'DAB' or v_acc_li_type_b <> 'DEDICATED LINE' or v_acc_li_type_b <> 'NONE')  THEN  
DELETE      service_implementation_tasks sit 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname IN (
'VERIFY NTU-B END','START FIBER LAYING-B','RESERVE MLLN PORT-B','RESERVE ACC FIBER-B','CONFIG MEN PORT-B','CONFIG CEN PORT-B'/*,'CONFIG MPLS PORT-B'*/,'CONFG MEN SUB PORT-B',
'CONFG CEN SUB PORT-B',/*'CONFG MPL SUB PORT-B',*/'ACTIV. SHDSL PORT-B','ACTIV. TRIB. PORT-B','WAIT FOR FIBER-B END','INSTAL SLT-END NTU-B','SETUP RADIO LINK-B','CONSTRUCT OSP LINE-B',
'ESTAB_ACCESS_LINK-B','RECONFIG NTU-B END','MODIFY NTU-B END','INSTALL CPE-B END','MODIFY CPE-B END','RECONFIG CPE-B END','ACTIV. ACC BEARER-B',/*'UPDATE ACC BEARER-B',*/'CONFIG MLLN PORT-B','PATCH CUST.LINK-B ND');
 END IF; IF  (v_acc_li_type_a = 'DAB' or v_acc_li_type_a = 'DEDICATED LINE' or v_acc_li_type_a = 'NONE')or
   ( v_acc_li_type_b = 'DAB' or v_acc_li_type_b = 'DEDICATED LINE' or v_acc_li_type_b = 'NONE') THEN
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND (acc_nw_intr_A = 'SDH PORT'             
or acc_nw_intr_B = 'SDH PORT') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'OPR-NETMGT-TX' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE TX PORTS'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE TX PORTS'; END IF;  

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  
AND (acc_lin_b = 'DEDICATED LINE' and back_b_capacity_b = 'YES') 
AND (acc_lin_a = 'DEDICATED LINE' and back_b_capacity_a = 'YES')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'NET-PLAN-TX' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE BACKBONE CAP'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE BACKBONE CAP'; END IF; 

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
(agr_nw_b = 'MEN' AND acc_nw_intr_b <> 'MEN PORT') or (agr_nw_a = 'MEN' AND acc_nw_intr_a <> 'MEN PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG. MEN VLAN'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG. MEN VLAN'; END IF;  


IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
(agr_nw_b = 'CEN' AND acc_nw_intr_b <> 'CEN PORT') or (agr_nw_a = 'CEN' AND acc_nw_intr_a <> 'CEN PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIG. CEN VLAN'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIG. CEN VLAN'; END IF;
--Remove New Process 
/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MLLN PORT' or acc_nw_intr_b = 'MLLN PORT') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; END IF;  */

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'SDH PORT' or  agr_nw_a = 'SDH') or (acc_nw_intr_b = 'SDH PORT'or agr_nw_b = 'SDH') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TX LINK'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TX LINK'; END IF; 

IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MEN PORT' or acc_nw_intr_b = 'MEN PORT') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE VLL PORTS'; 
ELSIF   v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'CEN PORT' or acc_nw_intr_a = 'MPLS PORT') or
( acc_nw_intr_b = 'CEN PORT' or acc_nw_intr_b = 'MPLS PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE VLL PORTS'; 
ELSIF   v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND 
( acc_nw_intr_a = 'MSAN PORT' or acc_nw_intr_a = 'DSLAM PORT') or
( acc_nw_intr_b = 'MSAN PORT' or acc_nw_intr_b = 'DSLAM PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE VLL PORTS'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE VLL PORTS'; END IF;  END IF;

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND                                       -- 
Ser_cteg = 'TEST' AND Test_Sr_Al = 'YES' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-ACCM'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'UPDATE TEST SERVICE'; 
ELSE
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'UPDATE TEST SERVICE'; END IF;*/

/*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND (acc_nw_intr_A = 'SDH PORT'             
or acc_nw_intr_B = 'SDH PORT') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'OPR-NETMGT-TX' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RESERVE TX PORTS'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RESERVE TX PORTS'; END IF;  
*//*IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_a = 'MEN PORT' OR acc_nw_intr_b = 'DSLAM PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_a = 'CEN PORT' OR acc_nw_intr_a = 'MPLS PORT') AND ( acc_nw_intr_b = 'CEN PORT' OR acc_nw_intr_b = 'MPLS PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_a = 'MSAN PORT' OR acc_nw_intr_a = 'DSLAM PORT') AND ( acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; ELSE
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE MLLN LINK'; END IF;*/

/*
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
acc_nw_intr_b = 'MEN PORT'THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
( acc_nw_intr_b = 'CEN PORT' OR acc_nw_intr_b = 'MPLS PORT')THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; ELSE
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; END IF;*/
IF    v_service_type = 'D-EDL'AND v_service_order = 'CREATE'  AND  
Ser_cteg = 'TEST' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle||'-ACCM'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'CONFIRM TEST SERVICE'; 
ELSE
DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM TEST SERVICE'; END IF;



p_implementation_tasks.update_task_status_byid ( p_sero_id,
0,
p_seit_id,
'COMPLETED'
);
EXCEPTION
WHEN OTHERS
THEN
p_ret_msg :=
'Failed to Change D-DEL Create  function. Please check the conditions:'
|| ' - Erro is:'
|| TO_CHAR (SQLCODE)
|| '-'
|| SQLERRM;
p_implementation_tasks.update_task_status_byid ( p_sero_id,
0,
p_seit_id,
'ERROR'
);

INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,
setc_text
)
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
p_ret_msg
);


END D_BL_CREATE;

--- Jayan Liyanage 2013/04/02

--- Jayan Liyanage 2012/05/05

PROCEDURE BEARER_DSP_DATE_UPDATE_4_EDL (
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

   v_actual_dsp_date          VARCHAR2 (100);
   bearer_id                  VARCHAR2 (100);
   v_service_od_id            VARCHAR2 (100);
   v_Cir_Status               VARCHAR2 (100);
   v_service_ord_type         VARCHAR2 (100);
   v_new_bearer_id            VARCHAR2 (100);
   v_new_service              VARCHAR2 (100);
   v_service_od_id_bend       VARCHAR2 (100);
   v_Cir_Status_bend          VARCHAR2 (100);
   v_acc_li_type_b              VARCHAR2 (100);
   v_acc_li_type_a              VARCHAR2 (100);
   v_acc_id_a                    VARCHAR2 (100);
   v_acc_id_b                     VARCHAR2 (100);
   
/*
CURSOR bearer_so (v_bearer_id VARCHAR)
IS
SELECT DISTINCT so.sero_id,C.CIRT_STATUS
FROM service_orders so, circuits c
WHERE so.sero_cirt_name = c.cirt_name
AND (    c.cirt_status <> 'PENDINGDELETE'
AND c.cirt_status <> 'CANCELLED'
)
AND (     so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_stas_abbreviation <> 'CLOSED'
)
AND c.cirt_displayname = v_bearer_id;*/
                  
  CURSOR bearer_so (v_new_bearer_id VARCHAR,v_new_service VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service
                      AND ci.cirt_displayname like replace( v_new_bearer_id,'(N)')||'%');
 

  CURSOR bearer_so_bend (v_new_bearer_id_bend VARCHAR,v_new_service_bend VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service_bend
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service_bend
                      AND ci.cirt_displayname like replace(v_new_bearer_id_bend,'(N)')||'%');       
BEGIN
  

SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

IF (v_acc_li_type_a = 'DAB'  ) THEN SELECT 
  distinct soa.seoa_defaultvalue INTO v_acc_id_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';
END IF;
IF (v_acc_li_type_b = 'DAB' ) THEN SELECT 
  distinct soa.seoa_defaultvalue INTO v_acc_id_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';
END IF;
                     
/*   SELECT DISTINCT soa.seoa_defaultvalue
              INTO bearer_id
              FROM service_orders so, service_order_attributes soa
             WHERE so.sero_id = soa.seoa_sero_id
               AND soa.seoa_name = 'ACCESS BEARER ID'
               AND so.sero_id = p_sero_id;*/         
SELECT DISTINCT so.sero_ordt_type INTO v_service_ord_type
FROM service_orders so WHERE so.sero_id = p_sero_id;
                     
   SELECT soa.seoa_defaultvalue
     INTO v_actual_dsp_date
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACTUAL_DSP_DATE';
if v_acc_id_a is not null then
   OPEN bearer_so (v_acc_id_a,v_service_ord_type);

   FETCH bearer_so
    INTO v_service_od_id,v_Cir_Status;

   CLOSE bearer_so;end if;
   
if v_acc_id_b is not null then 
   OPEN bearer_so_bend (v_acc_id_b,v_service_ord_type); 

   FETCH bearer_so_bend
    INTO v_service_od_id_bend,v_Cir_Status_bend;

   CLOSE bearer_so_bend;end if;
   
   
   if v_Cir_Status = 'COMMISSIONED' and  v_acc_li_type_a = 'DAB' then
   

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
    WHERE soa.seoa_sero_id = v_service_od_id
      AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
    WHERE sit.seit_taskname = 'ENTER BEARER DSP'
      AND sit.seit_sero_id = v_service_od_id;
      
   END IF;

   IF v_Cir_Status_bend = 'COMMISSIONED' and  v_acc_li_type_b = 'DAB' then
   
   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
                          WHERE soa.seoa_sero_id = v_service_od_id_bend
                            AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
                        WHERE sit.seit_taskname = 'ENTER BEARER DSP'
                          AND sit.seit_sero_id = v_service_od_id_bend;
      
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
            'Failed to Change  Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END BEARER_DSP_DATE_UPDATE_4_EDL;

--- Jayan Liyanage 2012/05/05

--- Jayan Liyanage 2013/04/03
PROCEDURE  BEARER_CP_EDL(
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

v_acc_bear_id_a varchar2(100);
v_acc_bear_id_b varchar2(100);
begin
  
SELECT soa.seoa_defaultvalue INTO v_acc_bear_id_a
 FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id 
 AND soa.seoa_name = 'ACCESS BEARER ID-A END';
 SELECT soa.seoa_defaultvalue INTO v_acc_bear_id_b
 FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id 
 AND soa.seoa_name = 'ACCESS BEARER ID-B END';
 
 
 
UPDATE service_order_attributes SOA
SET SOA.SEOA_DEFAULTVALUE = v_acc_bear_id_a where 
soa.seoa_name = 'ACCESS_ID-A END' and  soa.seoa_sero_id = p_sero_id;

UPDATE service_order_attributes SOA
SET SOA.SEOA_DEFAULTVALUE = v_acc_bear_id_b where 
soa.seoa_name = 'ACCESS_ID-B END' and  soa.seoa_sero_id = p_sero_id;
  
p_implementation_tasks.update_task_status_byid (p_sero_id,
0,
p_seit_id,
'COMPLETED'
);
EXCEPTION
WHEN OTHERS
THEN
p_ret_msg :=
'Failed to Copy Bearer Att Process function. Please check the conditions:'
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
p_ret_msg
);

END BEARER_CP_EDL;
--- Jayan Liyanage 2013/04/03

--Dulip Fernando 
--Version 1.1
--NBN-ELine 
--blank ACCESS BEARER ID-B /A END based on ACC_BEARER_STATUS and ACCESS_LINK_TYPE

PROCEDURE  ACCESS_BEARER_ID_BLANK(
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

v_ACC_BEARER_STATUS_B_END varchar2(100);
v_ACC_BEARER_STATUS_A_END varchar2(100);

v_ACCESS_LINK_TYPE_A_END varchar2(100);
v_ACCESS_LINK_TYPE_B_END varchar2(100);

v_ACCESS_BEARER_ID_A_END varchar2(100);
v_ACCESS_BEARER_ID_B_END varchar2(100);



begin

select soa.seoa_defaultvalue INTO v_ACC_BEARER_STATUS_B_END
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-B END';

select soa.seoa_defaultvalue INTO v_ACCESS_LINK_TYPE_B_END
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS LINK TYPE-B END';

select soa.seoa_defaultvalue INTO v_ACC_BEARER_STATUS_A_END
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-A END';

select soa.seoa_defaultvalue INTO v_ACCESS_LINK_TYPE_A_END
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS LINK TYPE-A END';

    IF 
             v_ACC_BEARER_STATUS_B_END='NEW' AND v_ACCESS_LINK_TYPE_B_END ='DAB'
        THEN

        UPDATE service_order_attributes soa
        SET SOA.SEOA_DEFAULTVALUE = NULL
        where soa.seoa_name = 'ACCESS BEARER ID-B END' and  soa.seoa_sero_id = p_sero_id;


    END IF ;

    IF 
   
            v_ACC_BEARER_STATUS_A_END='NEW' AND v_ACCESS_LINK_TYPE_A_END ='DAB'
            
            THEN

        UPDATE service_order_attributes SOA
        SET SOA.SEOA_DEFAULTVALUE = NULL
        where soa.seoa_name = 'ACCESS BEARER ID-A END' and  soa.seoa_sero_id = p_sero_id;


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
'Failed  ACCESS_BEARER_ID_BLANK Process function. Please check the conditions:'
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
p_ret_msg
);

END ACCESS_BEARER_ID_BLANK;

--Dulip Fernando

--Indika de Silva 20-08-2013
PROCEDURE SIP_TRUNK_CONFIR_NO_LEVEL (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_service_order         VARCHAR2 (100);
   v_service_type          VARCHAR2 (100);
   v_work_group            VARCHAR2 (100);
   v_sec_handel_by         VARCHAR2 (100) := NULL;
   
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
     INTO v_service_type
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
     INTO v_service_order
     FROM service_orders so
    WHERE so.sero_id = p_sero_id;
    
    SELECT soa.seoa_defaultvalue
     INTO v_sec_handel_by
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SECTION HANDLED BY';
    
    p_ret_char := '';


   IF     v_service_type = 'D-SIP TRUNK'
      AND (v_service_order = 'CREATE' OR v_service_order ='CREATE-TRANSFER')
      AND v_sec_handel_by IS NULL
   THEN
      p_ret_char := 'CORP-SSU';
      
   ELSIF     v_service_type = 'D-SIP TRUNK'
         AND (v_service_order = 'CREATE' OR v_service_order ='CREATE-TRANSFER')
         AND ((v_sec_handel_by LIKE 'SALES-ENT-%')
         OR (v_sec_handel_by LIKE 'SALES-WSALE-%'))
   THEN
      p_ret_char := v_sec_handel_by || '-ACCM';
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = p_ret_char
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM NUMBER LEVEL';
   ELSIF v_service_type = 'D-SIP TRUNK'    
         AND (v_service_order = 'CREATE' OR v_service_order ='CREATE-TRANSFER')
         AND (v_sec_handel_by LIKE 'SALES-SME-%')
   THEN
      p_ret_char := v_sec_handel_by || '-PSM';
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = p_ret_char
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM NUMBER LEVEL';
   END IF;

   
   p_ret_msg := '';
   
   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to change workgroup:Please check SECTION HANDLED BY'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END SIP_TRUNK_CONFIR_NO_LEVEL;

--Indika de Silva 20-11-2013

---Dulip Fernando 2013-10-10
---- Dinesh Perera edited 31-08-2015 -----added wip order is null
PROCEDURE PROV_CDMA_TASK_LOAD (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
   
IS

   v_auto_prov             VARCHAR2 (100);
   v_mans_name             VARCHAR2 (100); 
   v_sa_wip_order          VARCHAR2 (100);
   
BEGIN

     SELECT soa.seoa_defaultvalue
     INTO v_auto_prov
     FROM service_order_attributes soa
     WHERE soa.seoa_sero_id = p_sero_id
     AND soa.seoa_name = 'AUTO_PROV'; 


     SELECT soa.seoa_defaultvalue
     INTO v_mans_name
     FROM service_order_attributes soa
     WHERE soa.seoa_sero_id = p_sero_id
     AND soa.seoa_name = 'MANS_NAME'; 
     
     
     
     SELECT soa.seoa_defaultvalue
     INTO v_sa_wip_order
     FROM service_order_attributes soa
     WHERE soa.seoa_sero_id = p_sero_id
     AND soa.seoa_name = 'SA_WIP_ORDER'; 

        IF ((v_sa_wip_order IS NULL OR v_sa_wip_order !='Y') AND v_auto_prov='N'AND v_mans_name='HUAWEI')    --PROV HUAWEI HLR
            THEN
            
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV HUAWEI HLR';
                                
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV ZTE HLR';
                                 
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV ZTE HLR';        
                            
        
        END IF;
        
        IF ((v_sa_wip_order IS NULL OR v_sa_wip_order !='Y') AND v_auto_prov='Y'AND v_mans_name='HUAWEI')  --SOP PROV HUAWEI HLR 
            THEN
            
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV HUAWEI HLR';
                                
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV ZTE HLR';
                                 
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV ZTE HLR';         
        
        END IF;
            
        IF ((v_sa_wip_order IS NULL OR v_sa_wip_order !='Y') AND v_auto_prov='N'AND v_mans_name='ZTE')   --PROV ZTE HLR
            THEN
            
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV HUAWEI HLR';
                                
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV HUAWEI HLR';
                                 
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV ZTE HLR';  
                
        END IF;                                   
                      
          

        IF  ((v_sa_wip_order IS NULL OR v_sa_wip_order !='Y') AND v_auto_prov='Y'AND v_mans_name='ZTE')  -- SOP PROV ZTE HLR   
            THEN
            
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'SOP PROV HUAWEI HLR';
                                
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV ZTE HLR';
                                 
            DELETE service_implementation_tasks sit
            WHERE     sit.seit_sero_id = p_sero_id
            AND sit.seit_taskname = 'PROV HUAWEI HLR';       


        END  IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change PROV_CDMA_TASK_LOAD Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END PROV_CDMA_TASK_LOAD;
---- Dinesh Perera edited 31-08-2015 -----added wip order is null
---Dulip Fernando 2013-10-10 

--  Jayan Liyanage 2013/07/19

PROCEDURE DATA_PROD_ACC_ID_SET (
   p_serv_id         IN     Services.serv_id%TYPE,
   p_sero_id         IN     Service_Orders.sero_id%TYPE,
   p_seit_id         IN     Service_Implementation_Tasks.seit_id%TYPE,
   p_impt_taskname   IN     Implementation_Tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_Ser_type           VARCHAR2 (100);
   bearer_status        VARCHAR2 (100);
   v_acc_gp_id     VARCHAR2 (20);
   v_acc_port_bw   VARCHAR2 (50);

   CURSOR Cur_type
   IS
      SELECT so.sero_sert_abbreviation
        FROM service_orders so
       WHERE so.SERO_ID = p_sero_id;
       
      
  Cursor Cur_bear_stu  
  is
      select soa.seoa_defaultvalue
             from service_orders so,service_order_attributes soa
      where so.sero_id = soa.seoa_sero_id
      and soa.seoa_name = 'ACCESS BEARER STATUS'
      and so.sero_id = p_sero_id;

BEGIN
  

open Cur_type;

fetch Cur_type into v_Ser_type;

close Cur_type;

open Cur_bear_stu;

fetch Cur_bear_stu into bearer_status;

close Cur_bear_stu;

if bearer_status = 'NEW' THEN   

UPDATE service_order_attributes soa
set soa.seoa_defaultvalue = NULL
where soa.seoa_name = 'ACCESS BEARER ID'
and soa.seoa_sero_id = p_sero_id; END IF;


   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');
      p_ret_msg :=
            'Failed to set Access Bearer ID to null. - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      INSERT INTO SERVICE_TASK_COMMENTS (SETC_SEIT_ID,
                                         SETC_ID,
                                         SETC_USERID,
                                         SETC_TIMESTAMP,
                                         SETC_TEXT)
           VALUES (p_seit_id,
                   SETC_ID_SEQ.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
                   
END DATA_PROD_ACC_ID_SET;

--  Jayan Liyanage 2013/07/19

--Indika de Silva 15-10-2013

PROCEDURE CP_SER_ID(
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
   v_prod_so_id   VARCHAR2 (100);
BEGIN
   SELECT soa.seoa_defaultvalue
     INTO v_prod_so_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'PRODUCT SO NUMBER';

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_prod_so_id
    WHERE soa.seoa_name = 'SA_SOD_NUMBER' AND soa.seoa_sero_id = p_sero_id;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Copy PRODUCT SO NUMBER to SER_ID Att. Please check the conditions:'
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
                   p_ret_msg
                  );
END CP_SER_ID;

--Indika de Silva 15-10-2013

-- Indika de Silva 15-10-2013

PROCEDURE ENTER_NEW_SO_NO_MSG_MAP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 )IS



v_net_aggri_1     VARCHAR2(100);
v_net_aggri_2     VARCHAR2(100);
v_service_type    VARCHAR2(100);
v_service_order   VARCHAR2(100);
v_acc_nw          VARCHAR2(100);

BEGIN


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = 'ENTER NEW SO NUMBER'
WHERE  soa.seoa_name = 'PRODUCT SO NUMBER'
AND SOA.SEOA_SERO_ID IN (
SELECT DISTINCT S.SERO_ID
FROM service_orders S
WHERE S.SERO_ID = p_sero_id);


p_implementation_tasks.update_task_status_byid (p_sero_id,
                                     0,
                                     p_seit_id,
                                     'COMPLETED'
                                    );
EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change ENTER_NEW_SO_NO_MSG_MAP Process function. Please check the conditions:'
|| ' - Erro is:'
|| TO_CHAR (SQLCODE)
|| '-'
|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,
                                        0,
                                        p_seit_id,
                                        'ERROR'
                                       );

INSERT INTO service_task_comments (setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text
    )
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
     p_ret_msg
    );
END ENTER_NEW_SO_NO_MSG_MAP;

-- Indika de Silva 15-10-2013

-- 16-10-2013 Gihan Amarasinghe and Janaka Rathnayaka
PROCEDURE copy_CIRCUIT_details_slt2 (
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
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-DAB' THEN
     l_seoa_name := 'OLD CIRCUIT ID'; 
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-ETHERNET VPN' THEN
     l_seoa_name := 'OLD CIRCUIT ID';     
   ELSIF sero_rec.sero_sert_abbreviation LIKE 'D-PREMIUM IPVPN' THEN
     l_seoa_name := 'OLD CIRCUIT ID';    
   ELSE
     l_seoa_name := 'SA_ISDN_NUMBER';
   END IF;

   OPEN  seoa_cur(l_seoa_name);
   FETCH seoa_cur INTO l_old_cirt_name;
   CLOSE seoa_cur;

  -- Vinay TechM Test Start  17-12-2007
   SELECT MAX(a.CIRT_NAME) INTO l_old_cirt_name FROM circuits a WHERE a.CIRT_DISPLAYNAME = l_old_cirt_name AND CIRT_STATUS='INSERVICE';
  -- Vinay TechM Test end 17-12-2007
   IF copyXconnection.copyPortLinks(10, sero_rec.sero_cirt_name, l_old_cirt_name, 'REUSE', 'F', l_ret_msg) THEN

     p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id,'COMPLETED');

   ELSE
     p_auto_execute_tasks.add_work_comment(p_seit_id, l_ret_msg);
     p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id,'ERROR');
   END IF;
END copy_CIRCUIT_details_slt2;

-- 16-10-2013 Gihan Amarasinghe and Janaka Rathnayaka

--- 21-10-2013  Janaka Ratnayake 
PROCEDURE UPDATE_ADSL_CIRCUIT_LOC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


    CURSOR C_SERO_ID IS
    SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
    FROM   SERVICE_IMPLEMENTATION_TASKS
    WHERE  SEIT_ID = p_seit_id;

    CURSOR C_SER_CIRT (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
    SELECT  SERO_CIRT_NAME
    FROM    SERVICE_ORDERS
    WHERE   SERO_ID=T_SERO_ID;
          
    CURSOR C_SER_ATTR (T_SER_ID SERVICE_ORDER_ATTRIBUTES.SEOA_SERO_ID%TYPE) IS
    SELECT  SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES
    WHERE   SEOA_SERO_ID    =T_SER_ID
    AND     SEOA_NAME       ='SA_PSTN_NUMBER';
    
 CURSOR     C_CIR_NO (T_CIRT_ID CIRCUITS.CIRT_DISPLAYNAME%TYPE) IS
    SELECT  MAX(CIRT_NAME) FROM CIRCUITS
    WHERE   CIRT_DISPLAYNAME LIKE T_CIRT_ID||'%'
    AND     CIRT_STATUS NOT IN ('COPY','CANCELLED','PENDINGDELETE')
    AND     CIRT_SERT_ABBREVIATION='PSTN';

    CURSOR C_CIR_LOC (T_CIRT_ID CIRCUITS.CIRT_NAME%TYPE) IS
    SELECT  CIRT_LOCN_AEND,CIRT_LOCN_BEND FROM CIRCUITS
    WHERE   CIRT_NAME=T_CIRT_ID;


    

      V_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      V_SERO_REVISION   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;  
      V_ATTR_VAL        SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE;
      V_SERO_OEID       SERVICE_ORDERS.SERO_OEID%TYPE;
      V_CIRT_LOCN_AEND  CIRCUITS.CIRT_LOCN_AEND%TYPE;
      V_CIRT_LOCN_BEND  CIRCUITS.CIRT_LOCN_BEND%TYPE;

    
    T_PSTN_CIRT         VARCHAR2(20);
    T_ADSL_CIRT         VARCHAR2(20);

 BEGIN


    OPEN    C_SERO_ID;
    FETCH   C_SERO_ID INTO V_SERO_ID, V_SERO_REVISION;
    CLOSE   C_SERO_ID;
    
    OPEN    C_SER_ATTR (V_SERO_ID);       
    FETCH   C_SER_ATTR     INTO V_ATTR_VAL;
    CLOSE   C_SER_ATTR;     

    OPEN    C_SER_CIRT (V_SERO_ID);       
    FETCH   C_SER_CIRT     INTO T_ADSL_CIRT;
    CLOSE   C_SER_CIRT;  

    OPEN    C_CIR_NO (V_ATTR_VAL);       
    FETCH   C_CIR_NO     INTO T_PSTN_CIRT;
    CLOSE   C_CIR_NO;             
 

    IF T_PSTN_CIRT IS NOT NULL THEN
    
      
                               
            OPEN    C_CIR_LOC (T_PSTN_CIRT);       
            FETCH   C_CIR_LOC     INTO V_CIRT_LOCN_AEND,V_CIRT_LOCN_BEND;
            CLOSE   C_CIR_LOC;    
            
            UPDATE  CIRCUITS
            SET     CIRT_LOCN_AEND=V_CIRT_LOCN_AEND,CIRT_LOCN_BEND=V_CIRT_LOCN_BEND
            WHERE   CIRT_NAME=T_ADSL_CIRT
            AND     CIRT_SERT_ABBREVIATION='ADSL';
            
            COMMIT;
        
      

    END IF;
    
        p_ret_char := 'OK';
        p_ret_msg := NULL;
        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'UPDATE_ADSL_CIRCUIT_LOC FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


 END UPDATE_ADSL_CIRCUIT_LOC;
 
--- 21-10-2013  Janaka Ratnayake


-- 16-11-2013 Samankula Owitipana
PROCEDURE SISU_CONNECT_SET_NEW_TP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_count number:=0;
v_new_tp varchar2(100);
v_old_tp varchar2(100);


CURSOR c_new_tp_details  IS
select soa.SEOA_NAME,soa.SEOA_DEFAULTVALUE,soa.SEOA_PREV_VALUE
from service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME like 'SC_DESIGNATED NUMBER%'
and soa.SEOA_SOFE_ID is null
and (soa.SEOA_DEFAULTVALUE <> soa.SEOA_PREV_VALUE OR ( soa.SEOA_DEFAULTVALUE is not null AND soa.SEOA_PREV_VALUE is null));



BEGIN



FOR new_tp_rec in c_new_tp_details
   LOOP
   
        v_count := v_count + 1;
   
      UPDATE SERVICE_ORDER_ATTRIBUTES SA
      SET SA.SEOA_DEFAULTVALUE = new_tp_rec.SEOA_DEFAULTVALUE
      WHERE SA.SEOA_NAME = 'SC_DESIGNATED NEW TP ' || v_count
      AND SA.SEOA_SOFE_ID is null
      AND SA.SEOA_SERO_ID = p_sero_id;
      
      
   END LOOP;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set Sisuconnect new TP:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END SISU_CONNECT_SET_NEW_TP;

-- 16-11-2013 Samankula Owitipana

-- 02-10-2012 Samankula Owitipana
PROCEDURE ADSL_WAIT_SOP_TSK_CLOSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_pstn_so_id         varchar2(100);

cursor c_pstn_so_id is
select so.SERO_ID
from service_orders so,service_implementation_tasks sit 
where so.SERO_OEID like v_crm_order_id || '-%'
and so.SERO_SERT_ABBREVIATION = 'PSTN'
and so.SERO_STAS_ABBREVIATION in ('PROPOSED','APPROVED')
and so.SERO_ID = sit.SEIT_SERO_ID
and sit.SEIT_TASKNAME = 'SOP_PROVISION'
and sit.SEIT_STAS_ABBREVIATION in ('ASSIGNED','INPROGRESS');       


BEGIN

    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;


open c_pstn_so_id;
fetch c_pstn_so_id into v_pstn_so_id;
close c_pstn_so_id;

IF v_pstn_so_id is null THEN

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID = p_sero_id
and sit.SEIT_TASKNAME = 'WAIT PSTN SOP CLOSE'
and sit.SEIT_STAS_ABBREVIATION = 'ASSIGNED';

END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update WAIT FOR FACILITY task in ADSL. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END ADSL_WAIT_SOP_TSK_CLOSE;

-- 02-10-2012 Samankula Owitipana

-- 01-10-2012 Samankula Owitipana
PROCEDURE PSTN_WAIT_SOP_ADSL_TSK_CLOSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_adsl_so_id         varchar2(100);

cursor c_adsl_so_id is
select so.SERO_ID 
from service_orders so 
where so.SERO_OEID like v_crm_order_id || '-%'
and so.SERO_SERT_ABBREVIATION = 'ADSL'
and so.SERO_STAS_ABBREVIATION in ('PROPOSED','APPROVED');       


BEGIN
    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;


open c_adsl_so_id;
fetch c_adsl_so_id into v_adsl_so_id;
close c_adsl_so_id;

IF v_adsl_so_id is not null THEN

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID = v_adsl_so_id
and sit.SEIT_TASKNAME = 'WAIT PSTN SOP CLOSE'
and sit.SEIT_STAS_ABBREVIATION = 'INPROGRESS';

END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update WAIT FOR FACILITY task in ADSL. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END PSTN_WAIT_SOP_ADSL_TSK_CLOSE;

-- 01-10-2012 Samankula Owitipana

--- Edited Dinesh 01/10/2015 ----
--- Jayan  Liyanage  2013/11/12 ---
PROCEDURE IPTV_PROV_MIS_COM(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2) IS

Cursor Cur_Provistion_data IS
select distinct sof.sofe_id,sof.sofe_defaultvalue
from service_order_features sof
where sof.sofe_feature_name in ('IPTV','TSTV','VIDEO ON DEMAND')
and sof.sofe_sero_id =p_sero_id
and NVL(sof.sofe_defaultvalue,'N') <> NVL(SOFE_PREV_VALUE,'N');

v_fe_id                   varchar2(100);
v_sof_feat_val            varchar2(100);

begin
v_sof_feat_val := NULL;
  
open Cur_Provistion_data;
loop
  fetch Cur_Provistion_data into v_fe_id, v_sof_feat_val;
   exit when  Cur_Provistion_data%notfound;
  
  IF v_sof_feat_val = 'Y' THEN
  
  update service_order_features sof
  set sof.sofe_provision_status = 'Y' ,sof.sofe_provision_time = sysdate ,sof.sofe_provision_username = 'CLARITY'
  where sof.sofe_id = v_fe_id and sof.sofe_sero_id = p_sero_id;
  
  ELSIF v_sof_feat_val = 'U' THEN
  
  update service_order_features sof
  set sof.sofe_provision_status = 'Y' ,sof.sofe_provision_time = sysdate ,sof.sofe_provision_username = 'CLARITY'
  where sof.sofe_id = v_fe_id and sof.sofe_sero_id = p_sero_id;
  
  ELSIF v_sof_feat_val = 'N' THEN
  
  update service_order_features sof
  set sof.sofe_provision_status = 'N' ,sof.sofe_provision_time = sysdate ,sof.sofe_provision_username = 'CLARITY'
  where sof.sofe_id = v_fe_id and sof.sofe_sero_id = p_sero_id;
  
  END IF;
  
  end loop; close Cur_Provistion_data;
  
              p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); 
  
  EXCEPTION
     WHEN OTHERS THEN
     
 p_ret_msg :='Please check the Oredr Feature value in  Provistion on  Manul Work Oredr   :  - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;

 p_implementation_tasks.update_task_status_byid (p_sero_id,0, p_seit_id, 'ERROR');

INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp, setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);

End IPTV_PROV_MIS_COM;
-- Jayan  Liyanage  2013/11/12
--- Edited Dinesh 01/10/2015 ----

-- jayan Liyanage 2013/12/11

PROCEDURE DATA_PRO_STATUS_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2) IS
   
   
   v_service_ty      varchar2(100);

BEGIN
  

SELECT DISTINCT SO.SERO_SERT_ABBREVIATION INTO v_service_ty FROM SERVICE_ORDERS SO WHERE SO.SERO_ID = p_sero_id;

IF (v_service_ty = 'D-PREMIUM IPVPN' OR v_service_ty = 'D-ETHERNET VPN'OR v_service_ty = 'D-BIL')
THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = 'INSERVICE'
WHERE SOA.SEOA_NAME = 'ACCESS BEARER STATUS'
AND SOA.SEOA_SERO_ID =p_sero_id;

ELSIF ( v_service_ty = 'D-EDL' OR v_service_ty = 'D-DPLL') THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = 'INSERVICE'
WHERE SOA.SEOA_NAME = 'ACC. BEARER STATUS-A END'
AND SOA.SEOA_SERO_ID =p_sero_id;

UPDATE SERVICE_ORDER_ATTRIBUTES SOA SET SOA.SEOA_DEFAULTVALUE = 'INSERVICE'
WHERE SOA.SEOA_NAME = 'ACC. BEARER STATUS-B END'
AND SOA.SEOA_SERO_ID =p_sero_id;
END IF;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to change Bearer Status.. Please Check attribute Value. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END DATA_PRO_STATUS_CHG;

-- jayan Liyanage 2013/12/11

-- 06-11-2013 Samankula Owitipana

PROCEDURE D_ENTERPRIZE_IPTV_BEA_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
)IS

CURSOR bearer IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, 
service_order_attributes soa 
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID'AND so.sero_id = p_sero_id;

CURSOR so_copyattr (v_new_bearer_id VARCHAR)
IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status 
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')
AND so.sero_stas_abbreviation <> 'CANCELLED'AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci 
WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED' AND ci.cirt_displayname LIKE  v_new_bearer_id||'%'); 

v_so_attr_name     VARCHAR2 (100); 
v_so_attr_val      VARCHAR2 (100); 
v_bearer_id        VARCHAR2 (100);
v_cir_status       VARCHAR2 (100); 
v_new_bearer_id    VARCHAR2 (100); 
v_service_type     VARCHAR2 (100); 
v_service_order    VARCHAR2 (100);
v_new_service_type VARCHAR2 (100);

BEGIN OPEN bearer;FETCH bearer INTO v_bearer_id;

SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id; 
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
OPEN so_copyattr (v_bearer_id);
LOOP FETCH so_copyattr INTO v_so_attr_name, v_so_attr_val, v_cir_status; 
EXIT WHEN so_copyattr%NOTFOUND;


UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_cir_status
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS BEARER STATUS';


IF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE' 
  AND v_so_attr_name = 'ACCESS N/W INTF' THEN 
  
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

ELSIF     v_service_type = 'D-ENT PEO TV' 
AND v_service_order = 'CREATE'AND v_so_attr_name = 'SECTION_HANDLED_BY'

THEN UPDATE service_order_attributes soa 
  SET soa.seoa_defaultvalue = v_so_attr_val 
  WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'SECTION HANDLED BY';

ELSIF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'CPE CLASS'  THEN 

UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS'; 

ELSIF     v_service_type = 'D-ENT PEO TV' 
AND v_service_order = 'CREATE'AND v_so_attr_name = 'CPE TYPE'THEN 

UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE';

ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'
AND v_so_attr_name = 'CPE MODEL' THEN 

UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val 
  WHERE soa.seoa_sero_id = p_sero_id 
  AND soa.seoa_name = 'CPE MODEL';
  
ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'
AND v_so_attr_name = 'NTU MODEL' THEN 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL';

ELSIF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'NTU CLASS'THEN 

UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU CLASS'; 

ELSIF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'CREATE' AND v_so_attr_name = 'NTU TYPE'THEN 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id  AND soa.seoa_name = 'NTU TYPE';

ELSIF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'ADDITIONAL NTU MODEL'  THEN 

UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val  WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 

ELSIF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE'
AND v_so_attr_name = 'NTU ROUTING MODE'THEN 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
 WHERE soa.seoa_sero_id = p_sero_id  AND soa.seoa_name = 'NTU ROUTING MODE'; 
 
 
ELSIF     v_service_type = 'D-ENT PEO TV' AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'ACCESS MEDIUM' THEN 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id  AND soa.seoa_name = 'ACCESS MEDIUM'; 

ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'
AND v_so_attr_name = 'NO OF COPPER PAIRS'  THEN 

UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val 
  WHERE soa.seoa_sero_id = p_sero_id  AND soa.seoa_name = 'NO OF COPPER PAIRS';
  
ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE' 
AND v_so_attr_name = 'ACCESS INTF PORT BW'THEN  

UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
 AND soa.seoa_name = 'ACCESS INTF PORT BW'; 
 
ELSIF     v_service_type = 'D-ENT PEO TV'AND 
 v_service_order = 'CREATE' AND v_so_attr_name = 'DATA RADIO MODEL'THEN
  
 UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'DATA RADIO MODEL';

ELSIF     v_service_type = 'D-ENT PEO TV'
 AND v_service_order = 'CREATE'AND v_so_attr_name = 'CUSTOMER INTF TYPE' THEN 
 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
  WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE';
  
ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'AND v_so_attr_name = 'BACKBONE CORE NO'
THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'BACKBONE CORE NO';

ELSIF     v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'
AND v_so_attr_name = 'ACCESS LINK DISTANCE' THEN 

UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'ACCESS LINK DISTANCE';

ELSIF     v_service_type = 'D-ENT PEO TV' 
AND v_service_order = 'CREATE' AND v_so_attr_name = 'VLAN TAGGED/UNTAGGED ?' THEN 

UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
  AND soa.seoa_name = 'VLAN TAGGED/UNTAGGED ?';
  
END IF;  

END LOOP;
CLOSE so_copyattr;CLOSE bearer;

p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id, 'COMPLETED' );
EXCEPTION WHEN OTHERS THEN p_ret_msg :='Failed to Change D-Ethernet VPN Process function. Please check the conditions:' || ' - Erro is:'|| TO_CHAR (SQLCODE)
|| '-'|| SQLERRM;p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id, 'ERROR'  );
INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);
END D_ENTERPRIZE_IPTV_BEA_ATT_CP;

-- 06-11-2013 Samankula Owitipana

--Samankula Owitipana 2013-11-06

PROCEDURE D_ENTERPRISE_IPTV_CREATE (
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


CURSOR pre_cir (v_old_ids VARCHAR) IS SELECT DISTINCT c.cirt_status FROM circuits c WHERE c.cirt_displayname = v_old_ids;

CURSOR cur_tributer (parent_name VARCHAR2,v_new_cir_id varchar2 ) IS SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
FROM circuits c, circuit_hierarchy ch, circuits ci WHERE c.cirt_name = ch.cirh_parent
AND ch.cirh_child = ci.cirt_name AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')AND (   ci.cirt_status NOT LIKE 'CANCE%'
OR ci.cirt_status NOT LIKE 'PENDING%')AND ci.CIRT_DISPLAYNAME not like replace(v_new_cir_id,'(N)') ||'%' AND c.cirt_displayname = parent_name; 

              
CURSOR cur_Old_tributer (old_parent_name VARCHAR2,v_new_cir_id varchar2 )IS SELECT DISTINCT ci.cirt_displayname, ci.cirt_status
FROM circuits c, circuit_hierarchy ch, circuits ci WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name
AND (   ci.cirt_status LIKE 'INSERVICE%' OR ci.cirt_status LIKE 'PROPOSED%' OR ci.cirt_status LIKE 'SUSPEND%'
OR ci.cirt_status LIKE 'COMMISS%')AND (   ci.cirt_status NOT LIKE 'CANCE%'OR ci.cirt_status NOT LIKE 'PENDING%'
) AND ci.CIRT_DISPLAYNAME not like replace(v_new_cir_id,'(N)') ||'%' AND c.cirt_displayname = old_parent_name;

cursor Cur_a_s( a_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  from circuits ci where ci.cirt_displayname = a_cir;
cursor Cur_b_s( b_cir varchar2)is select ci.cirt_displayname,ci.cirt_status  from circuits ci where ci.cirt_displayname = b_cir;


acc_nw_intr_b             VARCHAR2 (100);
acc_bearer_status         VARCHAR2 (100);
acc_medi_b                VARCHAR2 (100);
acc_fib_b                 VARCHAR2 (100);
back_b_capacity_b         VARCHAR2 (100);
Ntu_Cls_b                 VARCHAR2 (100);
Ntu_model_chg_b           VARCHAR2 (100);
cpe_Cls_b                 VARCHAR2 (100);
cur_cpe_model_b           VARCHAR2 (100);
pre_cpe_model_b           VARCHAR2 (100);
Ser_cteg                  VARCHAR2 (100);
Test_Sr_Al                VARCHAR2 (100);
v_acc_id_b                VARCHAR2 (100);
v_service_order_area_b    VARCHAR2 (100);
v_rtom_code_bb            VARCHAR2 (100);
v_lea_code_bb             VARCHAR2 (100);
v_work_group_b_nw         VARCHAR2 (100);
v_section_hndle           VARCHAR2 (100);
v_service_order           VARCHAR2 (100);
v_service_type            VARCHAR2 (100);
v_work_group_b_os         VARCHAR2 (100);
v_loc_a_cir_dis           VARCHAR2(100);
v_loc_a_cir_Sta           VARCHAR2(100);
v_loc_b_cir_dis           VARCHAR2(100);
v_loc_b_cir_Sta           VARCHAR2(100);
v_work_group_b_mdf  VARCHAR2(100);
v_work_group_b_tx   VARCHAR2(100);
v_work_group_b_cpe  VARCHAR2(100);



BEGIN

 SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type
FROM service_orders so WHERE so.sero_id =  p_sero_id;

SELECT DISTINCT so.sero_ordt_type INTO v_service_order 
FROM service_orders so WHERE so.sero_id =  p_sero_id;

SELECT soa.seoa_defaultvalue INTO v_section_hndle
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'SECTION HANDLED BY';

SELECT soa.seoa_defaultvalue INTO v_service_order_area_b
FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';


SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_bb,v_lea_code_bb FROM areas ar WHERE ar.area_code = v_service_order_area_b AND ar.area_aret_code = 'LEA';

SELECT wg.worg_name INTO v_work_group_b_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC'; 

SELECT wg.worg_name INTO v_work_group_b_mdf FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'MDF'; 

/*SELECT wg.worg_name INTO v_work_group_b_tx FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'TX'; */
                 
SELECT wg.worg_name INTO v_work_group_b_nw FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'ENG-NW' || '%';

SELECT wg.worg_name INTO v_work_group_b_cpe FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'CPE-NC' || '%';



SELECT soa.seoa_defaultvalue INTO acc_nw_intr_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

SELECT soa.seoa_defaultvalue INTO acc_bearer_status FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS BEARER STATUS';

SELECT soa.seoa_defaultvalue INTO acc_medi_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

SELECT soa.seoa_defaultvalue  INTO Ntu_Cls_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU CLASS';

SELECT soa.seoa_defaultvalue INTO Ntu_model_chg_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?';

SELECT soa.seoa_defaultvalue INTO cpe_Cls_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE CLASS';

SELECT soa.seoa_defaultvalue,soa.SEOA_PREV_VALUE INTO cur_cpe_model_b,pre_cpe_model_b  FROM service_order_attributes soa
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'CPE MODEL';



IF    v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_status = 'INSERVICE' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'VERIFY NTU'; 

ELSE 

DELETE service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'VERIFY NTU'; 

END IF;  


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_status = 'COMMISSIONED' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE SHDSL PORT'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE SHDSL PORT'; 

END IF;  


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_status = 'INSERVICE' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ACTIVATE TRIB. PORT'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ACTIVATE TRIB. PORT'; 

END IF;  


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_medi_b = 'FIBER' OR acc_medi_b = 'COPPER-UTP') AND acc_bearer_status = 'COMMISSIONED' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_nw
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'ESTABLISH ACC. LINK'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'ESTABLISH ACC. LINK'; 

END IF;  


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_status = 'INSERVICE' 
AND Ntu_Cls_b = 'SLT' AND Ntu_model_chg_b = 'YES' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b_os
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY NTU'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY NTU'; 

END IF; 


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(acc_nw_intr_b = 'MSAN PORT' OR acc_nw_intr_b = 'DSLAM PORT') AND acc_bearer_status = 'INSERVICE' 
AND Ntu_Cls_b = 'SLT' AND Ntu_model_chg_b = 'NO' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG NTU'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU'; 

END IF; 


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(cur_cpe_model_b <> pre_cpe_model_b) AND acc_bearer_status = 'INSERVICE' 
AND cpe_Cls_b = 'SLT' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'MODIFY CPE'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CPE'; 

END IF;


IF   v_service_type = 'D-ENT PEO TV'AND v_service_order = 'CREATE'  AND 
(cur_cpe_model_b = pre_cpe_model_b) AND acc_bearer_status = 'INSERVICE' 
AND cpe_Cls_b = 'SLT' THEN

UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id =  p_sero_id
AND sit.seit_taskname = 'RECONFIG CPE'; 

ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG CPE'; 

END IF;

p_implementation_tasks.update_task_status_byid ( p_sero_id,
0,
p_seit_id,
'COMPLETED'
);
EXCEPTION
WHEN OTHERS
THEN
p_ret_msg :=
'Failed to Change D-Ethernet VPN Process function. Please check the conditions:'
|| ' - Erro is:'
|| TO_CHAR (SQLCODE)
|| '-'
|| SQLERRM;
p_implementation_tasks.update_task_status_byid ( p_sero_id,
0,
p_seit_id,
'ERROR'
);

INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,
setc_text
)
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
p_ret_msg
);

END D_ENTERPRISE_IPTV_CREATE;

--Samankula Owitipana 2013-11-06

-- 28-11-2013 Samankula Owitipana

PROCEDURE d_enterprize_IPTV_dsp_map (
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
   v_actual_dsp_date   VARCHAR2 (100);
   bearer_id           VARCHAR2 (100);
   v_service_od_id     VARCHAR2 (100);
   v_Cir_Status        VARCHAR2 (100);
   v_service_ord_type  VARCHAR2 (100);
   v_new_bearer_id     VARCHAR2 (100);
   v_new_service       VARCHAR2 (100);
/*
   CURSOR bearer_so (v_bearer_id VARCHAR)
   IS
      SELECT DISTINCT so.sero_id,C.CIRT_STATUS
                 FROM service_orders so, circuits c
                WHERE so.sero_cirt_name = c.cirt_name
                  AND (    c.cirt_status <> 'PENDINGDELETE'
                       AND c.cirt_status <> 'CANCELLED'
                      )
                  AND (     so.sero_stas_abbreviation <> 'CANCELLED'
                      AND so.sero_stas_abbreviation <> 'CLOSED'
                      )
                  AND c.cirt_displayname = v_bearer_id;*/
                  
  CURSOR bearer_so (v_new_bearer_id VARCHAR,v_new_service VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service
                      AND ci.cirt_displayname like replace(v_new_bearer_id,'(N)')||'%');
                  
                  
BEGIN
   SELECT DISTINCT soa.seoa_defaultvalue
              INTO bearer_id
              FROM service_orders so, service_order_attributes soa
             WHERE so.sero_id = soa.seoa_sero_id
               AND soa.seoa_name = 'ACCESS BEARER ID'
               AND so.sero_id = p_sero_id;
              
             
             
             
   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_ord_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_actual_dsp_date
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   OPEN bearer_so (bearer_id,v_service_ord_type);

   FETCH bearer_so
    INTO v_service_od_id,v_Cir_Status;

   CLOSE bearer_so;
   
   
   if v_Cir_Status = 'COMMISSIONED' then
   

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
    WHERE soa.seoa_sero_id = v_service_od_id
      AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
    WHERE sit.seit_taskname = 'ENTER BEARER DSP'
      AND sit.seit_sero_id = v_service_od_id;
      
   end if;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change  Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END d_enterprize_IPTV_dsp_map;

-- 28-11-2013 Samankula Owitipana

--- samankula Owitipana 2013/11/10
--- Edited 29/04/2014 Saman

PROCEDURE D_ENTERPRIZE_IPTV_DELETE (
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



CURSOR cur_tributer (parent_name VARCHAR2,order_Cir  VARCHAR2)IS
SELECT DISTINCT ci.cirt_displayname, ci.cirt_status FROM circuits c, circuit_hierarchy ch, circuits ci
WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name AND (   ci.cirt_status LIKE 'INSERVICE%'
OR ci.cirt_status LIKE 'PROPOSED%' OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')
AND (   ci.cirt_status NOT LIKE 'CANCE%' OR ci.cirt_status NOT LIKE 'PENDING%' )
AND ci.CIRT_DISPLAYNAME <> order_Cir AND c.cirt_displayname = replace(parent_name,'(N)');

CURSOR cur_equi_type IS SELECT DISTINCT e.equp_equt_abbreviation
FROM service_orders so, ports p, equipment e WHERE so.sero_cirt_name = p.port_cirt_name
AND p.port_equp_id = e.equp_id AND so.sero_id = p_sero_id;

   v_service_type         VARCHAR2 (100);
   v_service_order        VARCHAR2 (100);
   v_section_hndle        VARCHAR2 (100);
   v_core_network         VARCHAR2 (100);
   v_acc_nw               VARCHAR2 (100);
   v_access_bear_id       VARCHAR2 (100);
   parent_name            VARCHAR2 (100);
   v_ch_parent            VARCHAR2 (100);
   v_ch_dis               VARCHAR2 (100);
   v_cir_trib_status      VARCHAR2 (100);
   v_acc_medium           VARCHAR2 (100);
   v_media_type           VARCHAR2 (100);

   v_work_group_mdf       VARCHAR2 (100);
   v_ntu_class            VARCHAR2 (100);
   v_cpe_class            VARCHAR2 (100);
   v_service_order_area   VARCHAR2 (100);
   v_rtom_code            VARCHAR2 (100);
   v_lea_code             VARCHAR2 (100);
   v_work_group           VARCHAR2 (100);
   v_work_group_cpe       VARCHAR2 (100);
   v_new_Cir_Name         VARCHAR2 (100); 
   order_Cir              VARCHAR2 (100); 
   v_aggr_1               VARCHAR2 (100); 
   v_aggr_2               VARCHAR2 (100); 
   v_work_group_EN        VARCHAR2 (100); 
   v_work_group_nw     VARCHAR2 (100);
BEGIN



SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so 
WHERE so.sero_id = p_sero_id;

SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so 
WHERE so.sero_id = p_sero_id;

SELECT soa.seoa_defaultvalue INTO v_section_hndle FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SECTION HANDLED BY';

SELECT soa.seoa_defaultvalue INTO v_access_bear_id FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID';
    
SELECT DISTINCT c.cirt_displayname into v_new_Cir_Name FROM service_orders so,circuits c 
where so.sero_cirt_name = c.cirt_name and  so.sero_id = p_sero_id;

SELECT DISTINCT so.sero_area_code INTO v_service_order_area FROM service_orders so 
WHERE so.sero_id = p_sero_id;

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes, ar.area_code INTO v_rtom_code, v_lea_code FROM areas ar
WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

SELECT wg.worg_name INTO v_work_group FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';
SELECT wg.worg_name INTO v_work_group_nw FROM work_groups wg WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'ENG-NW' || '%';


SELECT soa.seoa_defaultvalue INTO v_acc_nw FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

SELECT soa.seoa_defaultvalue INTO v_acc_medium FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

SELECT soa.seoa_defaultvalue INTO v_cpe_class FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';

    
OPEN cur_tributer (v_access_bear_id,v_new_Cir_Name);
FETCH cur_tributer
INTO v_ch_dis, v_cir_trib_status;
CLOSE cur_tributer;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'MEN PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE MEN PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE MEN PORT';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'CEN PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE CEN PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE CEN PORT';


END IF;

IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'MPLS PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE MPLS PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE MPLS PORT';


END IF;

IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'MEN PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE MEN SUB PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE MEN SUB PORT';


END IF;

IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'CEN PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE CEN SUB PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE CEN SUB PORT';


END IF;

IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_nw = 'MPLS PORT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE MPLS SUB PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE MPLS SUB PORT';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND (v_acc_nw = 'MSAN PORT' or v_acc_nw = 'DSLAM PORT') THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. SHDSL PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. SHDSL PORT';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND (v_acc_nw = 'MSAN PORT' or v_acc_nw = 'DSLAM PORT') THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. TRIB PORT';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. TRIB PORT';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_acc_medium = 'FIBER' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'CORP-SSU'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'UNINSTALL FIBER LINK';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'UNINSTALL FIBER LINK';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND (v_acc_medium = 'FIBER' or v_acc_medium = 'COPPER-UTP') THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_work_group_nw
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE ACC LINK';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOVE ACC LINK';


END IF;


IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL AND v_cpe_class = 'SLT' THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'COLLECT CPE';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'COLLECT CPE';


END IF;

IF     v_service_type = 'D-ENT PEO TV'
AND v_service_order = 'DELETE'
AND v_ch_dis IS NULL THEN 

UPDATE service_implementation_tasks sit
SET sit.seit_worg_name = v_section_hndle || '-FO'
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT ACCESS BEARER';


ELSE 

DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT ACCESS BEARER';


END IF;


p_implementation_tasks.update_task_status_byid (p_sero_id,
0,p_seit_id,'COMPLETED');

EXCEPTION
   WHEN OTHERS
   THEN
p_ret_msg :=
'Failed to Change D-Premium  VPN Delete Process function. Please check the conditions:'
|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'ERROR');
INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,
setc_text
)
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
p_ret_msg
);


END D_ENTERPRIZE_IPTV_DELETE;

--- samankula Owitipana 2013/11/10


-- DUILP FERNANDO 2013-11- 06

PROCEDURE NBN_CH_WO_ACTIVITY_WG (
   P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
   P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
   P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
   P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
   P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
   P_RET_CHAR        OUT      VARCHAR2,
   P_RET_NUMBER      OUT      NUMBER,
   P_RET_MSG         OUT      VARCHAR2
)
IS


    CURSOR C_SO_NO IS 
    SELECT SEIT_SERO_ID,SEIT_ID
    FROM SERVICE_IMPLEMENTATION_TASKS
    WHERE SEIT_ID = P_SEIT_ID;
     
    CURSOR C_WO_WG (T_sero_id SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE,
    T_SEIT_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%type)IS 
    SELECT WORO_WORG_NAME,WORO_ID
    FROM WORK_ORDER
    WHERE WORO_SERO_ID=T_sero_id
    and WORO_SEIT_ID=T_SEIT_ID;

    V_WORK_ORDER_WG   WORK_ORDER.WORO_WORG_NAME%TYPE;
    V_SEIT_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE;
    V_SEIT_SERO_ID     SERVICE_ORDERS.SERO_ID%TYPE;
    V_WORO_ID          WORK_ORDER.WORO_ID%TYPE;

BEGIN

OPEN C_SO_NO;

FETCH C_SO_NO INTO V_SEIT_SERO_ID,V_SEIT_ID;

CLOSE  C_SO_NO;


        BEGIN 

            P_DYNAMIC_PROCEDURE.PROCESS_ISSUE_WORK_ORDER (
             P_SERV_ID         ,
             P_SERO_ID         ,
             P_SEIT_ID         ,
             P_IMPT_TASKNAME   ,
             P_WORO_ID         ,
             P_RET_CHAR        ,
             P_RET_NUMBER      ,
             P_RET_MSG         );    
        END ;


OPEN C_WO_WG (V_SEIT_SERO_ID,V_SEIT_ID);

FETCH C_WO_WG INTO V_WORK_ORDER_WG,V_WORO_ID;

CLOSE C_WO_WG ;
    


BEGIN

   UPDATE WORK_ORDER_ACTIVITIES WOA
      SET WOA.WOOA_WORG_NAME = V_WORK_ORDER_WG
    WHERE WOOA_ACTIVITYNAME = 'INSTALL NTU-A END' AND WOOA_WORO_ID = V_WORO_ID;
    
    commit; 
END ;
   /*
   P_IMPLEMENTATION_TASKS.UPDATE_TASK_STATUS_BYID (P_SERO_ID,
                                                   0,
                                                   P_SEIT_ID,
                                                   'COMPLETED'
                                                  );
                                                  
        */                                          
EXCEPTION
   WHEN OTHERS
   THEN
      P_RET_MSG :=
            'Failed to Change CH_WO_ACTIVITY_WG. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      P_IMPLEMENTATION_TASKS.UPDATE_TASK_STATUS_BYID (P_SERO_ID,
                                                      0,
                                                      P_SEIT_ID,
                                                      'ERROR'
                                                     );

      INSERT INTO SERVICE_TASK_COMMENTS
                  (SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
                   SETC_TEXT
                  )
           VALUES (P_SEIT_ID, SETC_ID_SEQ.NEXTVAL, 'CLARITYB', SYSDATE,
                   P_RET_MSG
                  );
END NBN_CH_WO_ACTIVITY_WG;

-- DULIP FERNANDO 2013-11-06

--Indika de silva 03-12-2013

PROCEDURE D_BIL_CREATE_BKP_WF (
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
   v_cir_status           VARCHAR2 (100);
   v_new_bearer_id        VARCHAR2 (100);
   v_section_hndle        VARCHAR2 (100);
   v_service_type         VARCHAR2 (100);
   v_service_order        VARCHAR2 (100);
   v_service_order_area   VARCHAR2 (100);
   v_rtom_code            VARCHAR2 (100);
   v_lea_code             VARCHAR2 (100);
   v_acc_bear_status      VARCHAR2 (100);
   v_core_network         VARCHAR2 (100);
   v_acc_medium           VARCHAR2 (100);
   v_work_group           VARCHAR2 (100);
   v_acc_nw               VARCHAR2 (100);
   v_ntu_class            VARCHAR2 (100);
   v_ntu_model_changed    VARCHAR2 (100);
   v_work_group_cpe       VARCHAR2 (100);
   v_ser_ctg              VARCHAR2 (100);
   v_so_attr_name         VARCHAR2 (100);
   v_so_attr_val          VARCHAR2 (100);
   v_bearer_id            VARCHAR2 (100);
   v_eng_net              VARCHAR2 (100);
   v_cpe_class            VARCHAR2 (100);
   v_cur_cpe_model        VARCHAR2 (100);
   v_pre_cpe_model        VARCHAR2 (100);
   v_net_aggri            VARCHAR2 (100);
BEGIN
   SELECT DISTINCT so.sero_sert_abbreviation
              INTO v_service_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_order
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_area_code
              INTO v_service_order_area
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)
                                                                     AS codes,
          ar.area_code
     INTO v_rtom_code,
          v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

--INSTALL SLT-END-NTU tasks work group
   SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)
                                                                     AS codes,
          ar.area_code
     INTO v_rtom_code,
          v_lea_code
     FROM areas ar
    WHERE ar.area_code = v_service_order_area AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group
     FROM work_groups wg
    WHERE worg_name LIKE
                    v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

   SELECT wg.worg_name
     INTO v_eng_net
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'ENG-NW' || '%';

   SELECT soa.seoa_defaultvalue
     INTO v_section_hndle
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_status
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id
      AND soa.seoa_name = 'ACCESS BEARER STATUS';

---SELECT soa.seoa_defaultvalue INTO v_core_network FROM service_order_attributes soa WHERE

   --soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CORE NETWORK';
   SELECT soa.seoa_defaultvalue
     INTO v_acc_medium
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM';

   SELECT soa.seoa_defaultvalue
     INTO v_ntu_class
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';

   SELECT soa.seoa_defaultvalue
     INTO v_acc_nw
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF';

   SELECT soa.seoa_defaultvalue
     INTO v_ser_ctg
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SERVICE CATEGORY';

   SELECT soa.seoa_defaultvalue
     INTO v_cpe_class
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';

   SELECT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cur_cpe_model, v_pre_cpe_model
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';

   SELECT soa.seoa_defaultvalue
     INTO v_net_aggri
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'AGGREGATE NETWORK';

   SELECT soa.seoa_defaultvalue
     INTO v_ntu_model_changed
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?';

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_medium = 'P2P RADIO'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'INSTALL SLT-END NTU';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'INSTALL SLT-END NTU';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONSTRUCT OSP LINE';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONSTRUCT OSP LINE';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACTIVATE SHDSL PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ACTIVATE SHDSL PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_ser_ctg = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-ACCM'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   ELSIF v_service_type = 'D-BIL' AND v_service_order = 'CREATE-BACKUP'
   THEN
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_section_hndle || '-FO'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACTIVATE ACC BEARER';
   ELSIF v_service_type = 'D-BIL' AND v_service_order = 'CREATE-BACKUP'
   THEN
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ACTIVATE ACC BEARER';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'MEN PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG. MEN PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG. MEN PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'CEN PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG. CEN PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG. CEN PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'MPLS PORT'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG. MPLS PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG. MPLS PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_medium = 'P2P RADIO'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'TX-RADIO-LAB'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'SETUP RADIO LINK';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'SETUP RADIO LINK';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'MEN PORT'
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG. MEN SUB PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG. MEN SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'CEN PORT'
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG. CEN SUB PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG. CEN SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_nw = 'MPLS PORT'
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'CONFIG MPLS SUB PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'CONFIG MPLS SUB PORT';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_acc_medium = 'FIBER'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CORP-SSU'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'COMM. FIBER LINK';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'COMM. FIBER LINK';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_medium = 'FIBER' OR v_acc_medium = 'COPPER-UTP')
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_eng_net
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ESTABLISH ACC. LINK';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ESTABLISH ACC. LINK';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'ACTIVATE TRIB. PORT';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'ACTIVATE TRIB. PORT';
   END IF;

--VERIFY NTU
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'VERIFY NTU';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'VERIFY NTU';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
      AND v_ntu_class = 'SLT'
      AND v_ntu_model_changed = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_cpe
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY NTU';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'MODIFY NTU';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND (v_acc_nw = 'MSAN PORT' OR v_acc_nw = 'DSLAM PORT')
      AND v_acc_bear_status = 'INSERVICE'
      AND v_ntu_class = 'SLT'
      AND v_ntu_model_changed = 'NO'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'RECONFIG NTU';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'RECONFIG NTU';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_cpe_class = 'SLT'
      AND v_cur_cpe_model <> v_pre_cpe_model
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY CPE';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'MODIFY CPE';
   END IF;

--RECONFIG CPE
   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_cpe_class = 'SLT'
      AND v_cur_cpe_model = v_pre_cpe_model
      AND v_acc_bear_status = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE sit.seit_sero_id = p_sero_id
         AND sit.seit_taskname = 'RECONFIG CPE';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'RECONFIG CPE';
   END IF;

   IF     v_service_type = 'D-BIL'
      AND v_service_order = 'CREATE-BACKUP'
      AND v_cpe_class = 'SLT'
      AND v_acc_bear_status = 'COMMISSIONED'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE';
   ELSE
      DELETE      service_implementation_tasks sit
            WHERE sit.seit_sero_id = p_sero_id
              AND sit.seit_taskname = 'INSTALL CPE';
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
            'Failed to D_BIL_CREATE_BKP_WF Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END D_BIL_CREATE_BKP_WF;

--Indika de silva 03-12-2013 

--Dulip Fernando and Indika De Silva 16/04/2013
/*This function will cpoy atttribute values of BIL back to relevent BEARER.Copy attributes to service order attributes table if bearer is in 

COMMISSIONED status.If 

bearer is INSERVICE, copy attributes to services attributes table.
*/

PROCEDURE D_BIL_VPN_BEA_AT_MAP (
p_serv_id       IN services.serv_id%TYPE, 
p_sero_id       IN service_orders.sero_id%TYPE, 
p_seit_id       IN service_implementation_tasks.seit_id%TYPE, 
p_impt_taskname IN implementation_tasks.impt_taskname%TYPE, 
p_woro_id       IN work_order.woro_id%TYPE, 
p_ret_char      OUT VARCHAR2, 
p_ret_number    OUT NUMBER, 
p_ret_msg       OUT VARCHAR2) 
IS 
  CURSOR bearer IS 
    SELECT DISTINCT soa.seoa_defaultvalue 
    FROM   SERVICE_ORDERS so, 
           SERVICE_ORDER_ATTRIBUTES soa 
    WHERE  so.sero_id = soa.seoa_sero_id 
           AND soa.seoa_name = 'ACCESS BEARER ID' 
           AND so.sero_id = p_sero_id; 
  CURSOR so_copyattr ( 
    v_new_bearer_id VARCHAR) IS 
    SELECT DISTINCT soa.seoa_sero_id, 
                    c.cirt_status, 
                    c.cirt_serv_id 
    FROM   SERVICE_ORDERS so, 
           SERVICE_ORDER_ATTRIBUTES soa, 
           CIRCUITS c 
    WHERE  so.sero_id = soa.seoa_sero_id 
           AND so.sero_cirt_name = c.cirt_name 
           AND ( c.cirt_status <> 'CANCELLED' 
                 AND c.cirt_status <> 'PENDINGDELETE' ) 
           AND so.sero_stas_abbreviation <> 'CANCELLED' 
           AND so.sero_id IN (SELECT MAX (s.sero_id) 
                              FROM   SERVICE_ORDERS s, 
                                     CIRCUITS ci 
                              WHERE  s.sero_cirt_name = ci.cirt_name 
                                     AND s.sero_stas_abbreviation <> 'CANCELLED' 
                                     AND ci.cirt_displayname = v_new_bearer_id); 
  CURSOR so_att_mapping IS 
    SELECT DISTINCT soa.seoa_name, 
                    soa.seoa_defaultvalue 
    FROM   SERVICE_ORDERS so, 
           SERVICE_ORDER_ATTRIBUTES soa 
    WHERE  so.sero_id = soa.seoa_sero_id 
           AND so.sero_id = p_sero_id; 
  v_cir_status    VARCHAR2 (100); 
  v_bearer_so_id  VARCHAR2 (100); 
  v_so_attr_name  VARCHAR2 (100); 
  v_so_att_val    VARCHAR2 (100); 
  v_new_bearer_id VARCHAR2 (100); 
  v_bearer_id     VARCHAR2 (100); 
  v_service_type  VARCHAR2 (100); 
  v_service_order VARCHAR2 (100); 
  v_new_service   VARCHAR2 (100); 
  v_cir_id        VARCHAR2 (100); 
BEGIN 
    OPEN bearer; 

    FETCH bearer INTO v_bearer_id; 

    SELECT DISTINCT so.sero_sert_abbreviation 
    INTO   v_service_type 
    FROM   SERVICE_ORDERS so 
    WHERE  so.sero_id = p_sero_id; 

    SELECT DISTINCT so.sero_ordt_type 
    INTO   v_service_order 
    FROM   SERVICE_ORDERS so 
    WHERE  so.sero_id = p_sero_id; 

    OPEN so_copyattr (v_bearer_id); 

    FETCH so_copyattr INTO v_bearer_so_id, v_cir_status, v_cir_id; 

    CLOSE bearer; 

    OPEN so_att_mapping; 

    LOOP 
        FETCH so_att_mapping INTO v_so_attr_name, v_so_att_val; 

        EXIT WHEN so_att_mapping%NOTFOUND; 

        IF v_cir_status = 'COMMISSIONED' THEN 
          
          --CREATE 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU TYPE'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'ACCESS LINK DISTANCE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ACCESS LINK DISTANCE'; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 
           
          --CREATE-BACKUP
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-BACKUP' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU TYPE'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'ACCESS LINK DISTANCE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ACCESS LINK DISTANCE'; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-BACKUP' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 
          
          
          --CREATE-OR 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-OR' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU TYPE'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'ADDITIONAL NTU  MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-OR' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 

          --CREATE-TRANSFER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-TRANSFER' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU TYPE'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          /* 
          ELSIF 
           
          v_service_type = 'D-BIL' AND v_service_order = 'CREATE-TRANSFER' AND v_so_attr_name = 'CPE 
           
          CHANGE?' 
           
          THEN 
           
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val WHERE 
           
          soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = 'CPE CHANGE?'; 
          */ 
          /* 
          ELSIF 
           
          v_service_type = 'D-BIL' AND v_service_order = 'CREATE-TRANSFER' AND v_so_attr_name = 'VLAN 
           
          TAGGED/UNTAGGED ?' 
           
          THEN 
           
          UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_att_val WHERE 
           
          soa.seoa_sero_id = v_bearer_so_id 
          AND soa.seoa_name = 'VLAN TAGGED/UNTAGGED ?'; 
           
          */ 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-TRANSFER' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 

          --MODIFY-SPEED 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-SPEED' 
             AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          END IF; 

          --MODIFY-CPE 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-CPE' 
             AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-CPE' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-CPE' 
                AND v_so_attr_name = 'ADDITIONAL NTU S/N' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU S/N'; 
          END IF; 

          --MODIFY-LOCATION 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-LOCATION' 
             AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU MODEL'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NO OF COPPER PAIRS'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          END IF; 

          --MODIFY-LOCATION 
          --MODIFY-EQUIPMENT 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-EQUIPMENT' 
             AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'CPE SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-EQUIPMENT' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'NTU SERIAL NUMBER'; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-EQUIPMENT' 
                AND v_so_attr_name = 'ADDITIONAL NTU S/N' THEN 
            UPDATE SERVICE_ORDER_ATTRIBUTES soa 
            SET    soa.seoa_defaultvalue = v_so_att_val 
            WHERE  soa.seoa_sero_id = v_bearer_so_id 
                   AND soa.seoa_name = 'ADDITIONAL NTU S/N'; 
          END IF; 
        --MODIFY-EQUIPMENT 
          ELSIF v_cir_status = 'INSERVICE' THEN 
          
          --CREATE FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU TYPE' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 
           
          --CREATE-BACKUP FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-BACKUP' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU TYPE' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-BACKUP' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-BACKUP' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 
          
          
          
          
          --CREATE-OR FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-OR' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU TYPE' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-OR' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-OR' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 

          --CREATE-TRANSFER FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'CREATE-TRANSFER' 
             AND v_so_attr_name = 'NTU TYPE' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU TYPE' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'CREATE-TRANSFER' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 

            IF v_service_type = 'D-BIL' 
               AND v_service_order = 'CREATE-TRANSFER' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 

          --MODIFY-SPEED FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-SPEED' 
             AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-SPEED' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          END IF; 

          --MODIFY-CPE FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-CPE' 
             AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-CPE' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-CPE' 
                AND v_so_attr_name = 'ADDITIONAL NTU S/N' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU S/N' 
                   AND sa.satt_serv_id = v_cir_id; 
          END IF; 

          --MODIFY-EQUIPMENT FOR INSERVICE BEARER 
          IF v_service_type = 'D-BIL' 
             AND v_service_order = 'MODIFY-EQUIPMENT' 
             AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY -EQUIPMENT' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-BIL' 
                AND v_service_order = 'MODIFY-EQUIPMENT' 
                AND v_so_attr_name = 'ADDITIONAL NTU S/N' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU S/N' 
                   AND sa.satt_serv_id = v_cir_id; 
          END IF; 

          --MODIFY-LOCATION FOR INSERVICE BEARER 
          IF v_service_type = 'D-PREMIUM IPVPN' 
             AND v_service_order = 'MODIFY-LOCATION' 
             AND v_so_attr_name = 'NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-PREMIUM IPVPN' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'CPE MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-PREMIUM IPVPN' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'ADDITIONAL NTU MODEL' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'ADDITIONAL NTU MODEL' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-PREMIUM IPVPN' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NO OF COPPER PAIRS' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-PREMIUM IPVPN' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'CPE SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'CPE SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 
          ELSIF v_service_type = 'D-PREMIUM IPVPN' 
                AND v_service_order = 'MODIFY-LOCATION' 
                AND v_so_attr_name = 'NTU SERIAL NUMBER' THEN 
            UPDATE SERVICES_ATTRIBUTES sa 
            SET    sa.satt_defaultvalue = v_so_att_val 
            WHERE  sa.satt_attribute_name = 'NTU SERIAL NUMBER' 
                   AND sa.satt_serv_id = v_cir_id; 

            IF v_service_type = 'D-PREMIUM IPVPN' 
               AND v_service_order = 'MODIFY-LOCATION' 
               AND ( v_cir_status = 'COMMISSIONED' 
                      OR v_cir_status = 'INSERVICE' ) THEN 
              UPDATE SERVICE_ORDER_ATTRIBUTES soa 
              SET    soa.seoa_defaultvalue = v_cir_status 
              WHERE  soa.seoa_name = 'ACCESS BEARER STATUS' 
                     AND soa.seoa_sero_id = p_sero_id; 
            END IF; 
          END IF; 
        END IF; 
    END LOOP; 

    CLOSE so_att_mapping; 

    CLOSE so_copyattr; 

    p_implementation_tasks.UPDATE_TASK_STATUS_BYID (p_sero_id, 0, p_seit_id, 
    'COMPLETED'); 
EXCEPTION 
  WHEN OTHERS THEN 
             p_ret_msg := 'Failed to Change D_BIL_VPN_BEA_AT_MAP Process function. Please check  the conditions:' 
                          || ' - Erro is:' 
                          || TO_CHAR (SQLCODE) 
                          || '-' 
                          || SQLERRM; 

             p_implementation_tasks.UPDATE_TASK_STATUS_BYID (p_sero_id, 0, 
             p_seit_id, 
             'ERROR' 
             ); 

             INSERT INTO SERVICE_TASK_COMMENTS 
                         (setc_seit_id, 
                          setc_id, 
                          setc_userid, 
                          setc_timestamp, 
                          setc_text) 
             VALUES      (p_seit_id, 
                          setc_id_seq.NEXTVAL, 
                          'CLARITYB', 
                          SYSDATE, 
                          p_ret_msg); 
END D_BIL_VPN_BEA_AT_MAP;

PROCEDURE BEARER_DSP_DATE_MOD_SPEED (
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
   v_actual_dsp_date   VARCHAR2 (100);
   bearer_id           VARCHAR2 (100);
   v_service_od_id     VARCHAR2 (100);
   v_Cir_Status        VARCHAR2 (100);
   v_service_ord_type  VARCHAR2 (100);
   v_new_bearer_id     VARCHAR2 (100);
   v_new_service       VARCHAR2 (100);

                  
  CURSOR bearer_so (v_new_bearer_id VARCHAR,v_new_service VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service
                      AND ci.cirt_displayname like replace(v_new_bearer_id,'(N)')||'(N)'||'%');
                  
                  
BEGIN
   SELECT DISTINCT soa.seoa_defaultvalue
              INTO bearer_id
              FROM service_orders so, service_order_attributes soa
             WHERE so.sero_id = soa.seoa_sero_id
               AND soa.seoa_name = 'ACCESS_ID'
               AND so.sero_id = p_sero_id;
              
             
             
             
   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_ord_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_actual_dsp_date
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   OPEN bearer_so (bearer_id,v_service_ord_type);

   FETCH bearer_so
    INTO v_service_od_id,v_Cir_Status;

   CLOSE bearer_so;
   
   
   if v_Cir_Status = 'COMMISSIONED' then
   

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
    WHERE soa.seoa_sero_id = v_service_od_id
      AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
    WHERE sit.seit_taskname = 'ENTER BEARER DSP'
      AND sit.seit_sero_id = v_service_od_id;
      
   end if;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change  Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END BEARER_DSP_DATE_MOD_SPEED;

-- Jayan Liyanage 2014/01/01

-- 16-11-2013 Samankula Owitipana

PROCEDURE SISU_CDMA_SET_BILL_NUMBBER(
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
   
CURSOR num_select_cur  IS
SELECT SOA.SEOA_DEFAULTVALUE FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_CDMA_NUMBER';
--AND    SOA.SEOA_DEFAULTVALUE LIKE '060%';

BEGIN

OPEN num_select_cur;
FETCH num_select_cur INTO v_NUMB_NO;
CLOSE num_select_cur;

update SERVICE_ORDER_ATTRIBUTES SOA
set SOA.SEOA_DEFAULTVALUE = v_NUMB_NO
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SC_BILLING PHONE NUMBER';

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to reserve number. Please check the number:' || v_NUMB_NO || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END SISU_CDMA_SET_BILL_NUMBBER;

-- 16-11-2013 Samankula Owitipana

--- 19-12-2013  Samankula Owitipana

PROCEDURE LTE_FORMAT_MSISDN_NUMBER(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_msisdn_dis_94  varchar2(100);
v_access_dis_lte varchar2(100);
v_cct_id_bb      varchar2(100);
v_cct_id         varchar2(100);
v_service_type   varchar2(100);


BEGIN


select so.SERO_SERT_ABBREVIATION
into v_service_type
from service_orders so
where so.SERO_ID = p_sero_id;

SELECT '94' || substr(trim(SOA.SEOA_DEFAULTVALUE),-9)
INTO v_msisdn_dis_94
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';

SELECT 'LTE' || trim(SOA.SEOA_DEFAULTVALUE)
INTO v_access_dis_lte
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';

SELECT 'BB' || trim(SOA.SEOA_DEFAULTVALUE)
INTO v_cct_id_bb
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';


SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_cct_id
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';


IF v_service_type = 'BB-INTERNET' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_access_dis_lte
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_msisdn_dis_94
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_msisdn_dis_94
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'BB CIRCUIT ID';

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_msisdn_dis_94
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ADSL_CIRCUIT_ID';

ELSIF v_service_type = 'AB-WIRELESS ACCESS' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_access_dis_lte
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_msisdn_dis_94
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';

ELSIF v_service_type = 'V-VOICE' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_access_dis_lte
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_msisdn_dis_94
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';

END IF;


p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed update MSISDN NO:'  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      
     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);
    
END LTE_FORMAT_MSISDN_NUMBER;

--- 19-12-2013  Samankula Owitipana

--- 10-01-2014 Samankula Owitipana

PROCEDURE LTE_UPDATE_AB_WIRELESS_ACCESS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_ab_so_id         varchar2(100);
v_cct_id           varchar2(100);

cursor c_ab_so_id is
select so.SERO_ID
from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%'
and so.SERO_SERT_ABBREVIATION = 'AB-WIRELESS ACCESS'
and so.SERO_STAS_ABBREVIATION = 'PROPOSED';       


BEGIN

    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;

SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_cct_id
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'MSISDN NO';


open c_ab_so_id;
fetch c_ab_so_id into v_ab_so_id;
close c_ab_so_id;


IF v_ab_so_id is not null THEN

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID = v_ab_so_id
and sit.SEIT_TASKNAME = 'WAIT TILL BB SERVICE'
and sit.SEIT_STAS_ABBREVIATION in ('INPROGRESS','ASSIGNED');

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_cct_id
WHERE SOA.SEOA_SERO_ID = v_ab_so_id
AND SOA.SEOA_NAME = 'MSISDN NO';

END IF;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update AB-WIRELESS ACCESS. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END LTE_UPDATE_AB_WIRELESS_ACCESS;

--- 10-01-2014 Samankula Owitipana

--- 13-01-2014 Samankula Owitipana

PROCEDURE LTE_CLOSE_WAIT_BB_PROV (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_ab_so_id         varchar2(100);
v_voice_so_id         varchar2(100);
v_dsp_date           varchar2(100);

cursor c_ab_so_id is
select so.SERO_ID
from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%'
and so.SERO_SERT_ABBREVIATION = 'AB-WIRELESS ACCESS'
and so.SERO_STAS_ABBREVIATION in ('PROPOSED','APPROVED');

cursor c_voice_so_id is
select so.SERO_ID
from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%'
and so.SERO_SERT_ABBREVIATION = 'V-VOICE'
and so.SERO_STAS_ABBREVIATION in ('PROPOSED','APPROVED');        

cursor c_dsp_date is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ACTUAL_DSP_DATE';


BEGIN

    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;

open c_ab_so_id;
fetch c_ab_so_id into v_ab_so_id;
close c_ab_so_id;

open c_voice_so_id;
fetch c_voice_so_id into v_voice_so_id;
close c_voice_so_id;

open c_dsp_date;
fetch c_dsp_date into v_dsp_date  ;
close c_dsp_date;



IF v_ab_so_id is not null THEN

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID = v_ab_so_id
and sit.SEIT_TASKNAME = 'WAIT BB PROVISION'
and sit.SEIT_STAS_ABBREVIATION in ('INPROGRESS','ASSIGNED');

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_dsp_date
WHERE SOA.SEOA_SERO_ID = v_ab_so_id
AND SOA.SEOA_NAME = 'ACTUAL_DSP_DATE';

END IF;


IF v_voice_so_id is not null THEN

update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID = v_voice_so_id
and sit.SEIT_TASKNAME = 'WAIT BB PROVISION'
and sit.SEIT_STAS_ABBREVIATION in ('INPROGRESS','ASSIGNED');

END IF;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update WAIT BB PROVISION task. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END LTE_CLOSE_WAIT_BB_PROV;

--- 13-01-2014 Samankula Owitipana

--- Dinesh Perera 16-01-2014 -----

PROCEDURE CHANGE_ATTRIB_TO_94 (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_user_name      varchar2(100);
v_pass_val         varchar2(100);



BEGIN

    

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_user_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'USER_NAME';


SELECT trim(TO_CHAR('94'||substr(v_user_name,-9)))

INTO v_pass_val
FROM DUAL;

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_pass_val
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'USER_NAME';

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to generate username. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END CHANGE_ATTRIB_TO_94;

--- Dinesh Perera 16-01-2014 -----

--- Dinesh Perera 16-01-2014 -----

PROCEDURE CHANGE_ATTRIB_94_TO_NORM (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_user_name      varchar2(100);
v_pass_val         varchar2(100);



BEGIN

    

SELECT SOA.SEOA_DEFAULTVALUE
INTO v_user_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'USER_NAME';


SELECT trim(TO_CHAR('0'||substr(v_user_name,-9)))

INTO v_pass_val
FROM DUAL;

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_pass_val
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'USER_NAME';

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to generate username. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END CHANGE_ATTRIB_94_TO_NORM;

--- Dinesh Perera 16-01-2014 -----

-- 13-01-2014 Samankula Owitipana
--- 25-01-2014 Edited

PROCEDURE LTE_HASH_ID_GENERATION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_msisdn_no      varchar2(100);
v_imsi_no         varchar2(100);
v_pass_val         varchar2(100);
v_lte_pw_gen       varchar2(100);

cursor c_msisdn_no is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


cursor c_imsi_no is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IMSI NO';

cursor c_lte_pw is
select LP.PWD from ossrpt.LTE_PW LP
WHERE LP.IMSI = v_imsi_no
AND LP.ISDN = v_msisdn_no;


BEGIN

    
open c_msisdn_no;
fetch c_msisdn_no into v_msisdn_no;
close c_msisdn_no;

open c_imsi_no;
fetch c_imsi_no into v_imsi_no;
close c_imsi_no;

SELECT trim(TO_CHAR(substr(v_imsi_no,-3,3)+88,'XXXXXXXX'))
|| TO_CHAR(SUBSTR(v_msisdn_no,6,1)+1)
|| TO_CHAR(SUBSTR(v_msisdn_no,8,1)+1)
|| trim(TO_CHAR(substr(v_msisdn_no,-2,2)+9,'XXXXXXXX'))
|| to_CHAR(nvl(SUBSTR(v_msisdn_no,11,1),'0')+1)
|| to_CHAR(SUBSTR(v_msisdn_no,5,1)+1)
|| to_CHAR(SUBSTR(v_msisdn_no,9,1)+1)
|| to_CHAR(SUBSTR(v_msisdn_no,7,1)+1)
|| to_CHAR(SUBSTR(v_msisdn_no,4,1)+1)
|| to_CHAR(SUBSTR(v_msisdn_no,10,1)+1)
INTO v_pass_val
FROM DUAL;

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_pass_val
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'LTE_HASH_ID';

open c_lte_pw;
fetch c_lte_pw into v_lte_pw_gen;
close c_lte_pw;


IF (v_msisdn_no is null or v_imsi_no is null or v_lte_pw_gen is null or (v_lte_pw_gen <> v_pass_val)) THEN

/*P_dynamic_procedure.Process_ISSUE_WORK_ORDER(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);
        
ELSE*/

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');         

END IF;



EXCEPTION
WHEN OTHERS THEN

----p_ret_msg  := 'Failed to generate or match LTE HASH ID. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

/*INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );*/

END LTE_HASH_ID_GENERATION;

-- 13-01-2014 Samankula Owitipana

-- 21-01-2014 Samankula Owitipana
--- 25-01-2014 Edited 

PROCEDURE LTE_UPDATE_PW_INVENTORY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_msisdn_no      varchar2(100);
v_imsi_no         varchar2(100);
v_pass_val         varchar2(100);
v_lte_pw_gen       varchar2(100);

cursor c_msisdn_no is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


cursor c_imsi_no is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'IMSI NO';


BEGIN

    
open c_msisdn_no;
fetch c_msisdn_no into v_msisdn_no;
close c_msisdn_no;

open c_imsi_no;
fetch c_imsi_no into v_imsi_no;
close c_imsi_no;



UPDATE ossrpt.LTE_PW LP
set lp.STATUS = 'ISSUED'
WHERE LP.IMSI = v_imsi_no
AND LP.ISDN = v_msisdn_no;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');         


EXCEPTION
WHEN OTHERS THEN

----p_ret_msg  := 'Failed to update the lte inventory. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

/*INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );*/

END LTE_UPDATE_PW_INVENTORY;

-- 21-01-2014 Samankula Owitipana

--- Dinesh Perera 03-02-2014

PROCEDURE  PE_DRAW_FIBER_WG_CHG(

      p_serv_id                      IN     Services.serv_id%TYPE,
      p_sero_id                      IN     Service_Orders.sero_id%TYPE,
      p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                      IN     work_order.woro_id%TYPE,
      p_ret_char                     OUT    VARCHAR2,
      p_ret_number                   OUT    NUMBER,
      p_ret_msg                      OUT    VARCHAR2) IS


v_pe_area      VARCHAR2(100) := null;
v_rtom               VARCHAR2(100);


CURSOR seoa_cur IS
SELECT SEOA_DEFAULTVALUE
FROM service_order_attributes
WHERE seoa_sero_id = p_sero_id
AND seoa_name = 'PE AREA';


BEGIN

p_ret_char := '';

OPEN  seoa_cur;
FETCH seoa_cur INTO v_pe_area;
CLOSE seoa_cur;


IF (v_pe_area = 'CEN') OR (v_pe_area  = 'KX') OR (v_pe_area  = 'MD') OR (v_pe_area  = 'HK') OR (v_pe_area  = 'WT') OR (v_pe_area  = 'JL') OR (v_pe_area  = 'RG') OR (v_pe_area  = 'RM') OR (v_pe_area  = 'ND')

THEN 

p_ret_char := 'NET-PROJ-ACC-CABLE';

ELSE   
p_ret_char := v_pe_area || '-MNG-OPMC';
      

END IF;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = p_ret_char
         WHERE SIT.SEIT_SERO_ID = p_sero_id
         AND SEIT_TASKNAME IN ('DRAW FIBER','CONDUCT FIBER PAT');

p_ret_msg := '';

EXCEPTION

WHEN OTHERS THEN
p_ret_msg  := 'Failed to change workgroup:Please check PE AREA ' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
END PE_DRAW_FIBER_WG_CHG;

--- Dinesh Perera 03-02-2014

--- Dinesh Perera 03-02-2014

PROCEDURE  PE_UPLOAD_OSS_WG_CHG(

      p_serv_id                      IN     Services.serv_id%TYPE,
      p_sero_id                      IN     Service_Orders.sero_id%TYPE,
      p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                      IN     work_order.woro_id%TYPE,
      p_ret_char                     OUT    VARCHAR2,
      p_ret_number                   OUT    NUMBER,
      p_ret_msg                      OUT    VARCHAR2) IS


v_pe_area      VARCHAR2(100) := null;
v_rtom               VARCHAR2(100);


CURSOR seoa_cur IS
SELECT SEOA_DEFAULTVALUE
FROM service_order_attributes
WHERE seoa_sero_id = p_sero_id
AND seoa_name = 'PE AREA';


BEGIN

p_ret_char := '';

OPEN  seoa_cur;
FETCH seoa_cur INTO v_pe_area;
CLOSE seoa_cur;


IF (v_pe_area = 'CEN') OR (v_pe_area  = 'KX') OR (v_pe_area  = 'MD') OR (v_pe_area  = 'HK') OR (v_pe_area  = 'WT') OR (v_pe_area  = 'JL') OR (v_pe_area  = 'RG') OR (v_pe_area  = 'RM') OR (v_pe_area  = 'ND')

THEN 

p_ret_char := 'NET-PROJ-ACC-CABLE';

ELSE
       
p_ret_char := v_pe_area || '-ENG-NW';

END IF;

         UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET sit.SEIT_WORG_NAME = p_ret_char
         WHERE SIT.SEIT_SERO_ID = p_sero_id
         AND SEIT_TASKNAME = 'UPLOAD FIBER IN OSS';

p_ret_msg := '';

EXCEPTION

WHEN OTHERS THEN
p_ret_msg  := 'Failed to change workgroup:Please check PE AREA ' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
END PE_UPLOAD_OSS_WG_CHG;

--- Dinesh Perera 03-02-2014

--- Dinesh Perera 2013-11-12
PROCEDURE PLANNED_EVENTS_AUTO_APPROVED
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2) IS

    CURSOR C_PE_query  IS
        
    SELECT  SERO_OEID
    FROM    SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SI
    WHERE   SERO_ID = SEIT_SERO_ID
    AND     SEIT_ID = p_seit_id;
          

    l_PE_OEID          SERVICE_ORDERS.SERO_OEID%TYPE;
    


    BEGIN


         OPEN C_PE_query;
         FETCH C_PE_query 
         INTO l_PE_OEID;
         CLOSE C_PE_query;
         
             IF l_PE_OEID IS NOT NULL
             THEN
                    UPDATE PLANNED_EVENTS 
                    SET PLAE_STATE = 'APPROVED'
                    WHERE PLAE_NUMBER = l_PE_OEID;                    
                    
             END IF;
             
             
            p_ret_char  := 'PLANNED EVENT APPROVED';
            p_ret_msg   := NULL;

            p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); 
            

     EXCEPTION
     WHEN OTHERS THEN
           p_ret_msg  := 'Failed to PLANNED EVENTS ATTRIBUTES:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM ;
           
                   p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

    END PLANNED_EVENTS_AUTO_APPROVED;
    
--- Dinesh Perera 2013-11-12

--- Dinesh Perera 2014-02-06
PROCEDURE PLANNED_EVENTS_AUTO_COMPLETE
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2) IS

    CURSOR C_PE_query  IS
        
    SELECT  SERO_OEID
    FROM    SERVICE_ORDERS SO,SERVICE_IMPLEMENTATION_TASKS SI
    WHERE   SERO_ID = SEIT_SERO_ID
    AND     SEIT_ID = p_seit_id;
          

    l_PE_OEID          SERVICE_ORDERS.SERO_OEID%TYPE;
    


    BEGIN


         OPEN C_PE_query;
         FETCH C_PE_query 
         INTO l_PE_OEID;
         CLOSE C_PE_query;
         
             IF l_PE_OEID IS NOT NULL
             THEN
                    UPDATE PLANNED_EVENTS 
                    SET PLAE_STATE = 'COMPLETED'
                    WHERE PLAE_NUMBER = l_PE_OEID;                    
                    
             END IF;
             
             
            p_ret_char  := 'PLANNED EVENT COMPLETE';
            p_ret_msg   := NULL;

            p_implementation_tasks.update_task_status_byid(p_sero_id, 0, p_seit_id, 'COMPLETED'); 
            

     EXCEPTION
     WHEN OTHERS THEN
           p_ret_msg  := 'Failed to PLANNED EVENTS ATTRIBUTES:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM ;
           
                   p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);

    END PLANNED_EVENTS_AUTO_COMPLETE;
    
--- Dinesh Perera 2014-02-06

-- 06-02-2014 Samankula Owitipana


PROCEDURE PSTN_IDD_PROVISION_Y (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

CURSOR IDD_feature_select_cur  IS
SELECT sof.SOFE_DEFAULTVALUE,sof.SOFE_PREV_VALUE
FROM SERVICE_ORDER_FEATURES sof
WHERE sof.sofe_sero_id= p_sero_id
AND sof.sofe_feature_name = 'SF_IDD';


v_IDDTYPE VARCHAR2(25);
v_NEW VARCHAR2(25);
v_OLD VARCHAR2(25);
v_NEW_SEC VARCHAR2(25);
v_OLD_SEC VARCHAR2(25);

BEGIN



OPEN IDD_feature_select_cur;
FETCH IDD_feature_select_cur INTO v_NEW,v_OLD;
CLOSE IDD_feature_select_cur;


      IF (v_NEW = 'Y' AND ( v_OLD = 'N' or v_OLD is null)) THEN


        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',
        sof.SOFE_PROVISION_TIME = sysdate
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_IDD';
        
      ELSIF (v_NEW = 'N' AND v_OLD = 'Y' ) THEN
      
      
        UPDATE SERVICE_ORDER_FEATURES sof
        SET sof.sofe_provision_status = 'Y',
        sof.SOFE_PROVISION_TIME = sysdate
        WHERE sof.sofe_sero_id= p_sero_id
        AND sof.sofe_feature_name = 'SF_IDD';
        

      END IF;
      

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
    

EXCEPTION
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to Set provision status Y. :' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );


END PSTN_IDD_PROVISION_Y;

-- 06-02-2014 Samankula Owitipana

--- 06-03-2014  Ruwan Ranasinghe 

PROCEDURE UPDATE_ADSL_LINE_PROFILE_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



      CURSOR C_SERV_ID IS
            
            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION,SERO_ID
            FROM SERVICE_ORDERS
            WHERE SERO_ID=p_sero_id;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';


      CURSOR C_GET_CIRCUITNO (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_EQUP_ID
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';
            
      CURSOR C_GET_EQ_DET (T_EQP_ID EQUIPMENT.EQUP_ID%TYPE) IS
      
            SELECT EQ.EQUP_MANR_ABBREVIATION,EQ.EQUP_EQUM_MODEL
            FROM EQUIPMENT EQ
            WHERE EQUP_ID=T_EQP_ID;   

     CURSOR SOFE_LIST_CURR_ADSL(T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE)IS
            SELECT SOF.SOFE_DEFAULTVALUE FROM SERVICE_ORDER_FEATURES SOF
            WHERE SOF.SOFE_SERO_ID = T_SERO_ID
            AND SOF.SOFE_DEFAULTVALUE='Y'
            AND SOF.SOFE_FEATURE_NAME='INTERNET';

     CURSOR SOFE_LIST_CURR_IPTV (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE)IS
            SELECT SOF.SOFE_DEFAULTVALUE FROM SERVICE_ORDER_FEATURES SOF
            WHERE SOF.SOFE_SERO_ID = T_SERO_ID
            AND SOF.SOFE_DEFAULTVALUE='Y'
            AND SOF.SOFE_FEATURE_NAME='IPTV';


            V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
            V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
            V_SERO_ID           SERVICE_ORDERS.SERO_ID%TYPE;
            V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
            V_PORT_EQUP_ID      PORTS.PORT_EQUP_ID%TYPE; 
                
            
            V_EQTYPE            EQUIPMENT.EQUP_MANR_ABBREVIATION%TYPE;
            V_EQMODL            EQUIPMENT.EQUP_EQUM_MODEL%TYPE;
            L_LINEPROFILE       VARCHAR2(20);
            A_LINEPROFILE       VARCHAR2(30);
            L_ADSL_VAL          SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
            L_IPTV_VAL          SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
            L_RETURN_MSG        VARCHAR(2000);
            
                        
  BEGIN

     OPEN C_SERV_ID;    
     FETCH C_SERV_ID    INTO V_CRT_ID,V_SERO_TYPE,V_SERO_ID;
     CLOSE C_SERV_ID; 


     OPEN C_GET_P_NUMBER (V_CRT_ID);       
     FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
     CLOSE C_GET_P_NUMBER;
      

     OPEN C_GET_CIRCUITNO (V_CIRCUIT_ID);       
     FETCH C_GET_CIRCUITNO INTO V_PORT_EQUP_ID;
     CLOSE C_GET_CIRCUITNO; 

     OPEN C_GET_EQ_DET (V_PORT_EQUP_ID);       
     FETCH C_GET_EQ_DET INTO V_EQTYPE,V_EQMODL;
     CLOSE C_GET_EQ_DET; 
     
     L_LINEPROFILE:=NULL;
     L_IPTV_VAL:=NULL;
     L_ADSL_VAL:=NULL;
     A_LINEPROFILE:=NULL;
     
     
    IF V_EQTYPE='ZTE' THEN ---AND V_EQMODL LIKE 'MSAG5200%' THEN 
        A_LINEPROFILE:='ZTE';
    
        /*OPEN SOFE_LIST_CURR_ADSL(V_SERO_ID);       
        FETCH SOFE_LIST_CURR_ADSL INTO L_ADSL_VAL;
        CLOSE SOFE_LIST_CURR_ADSL; 
            
        OPEN SOFE_LIST_CURR_IPTV(V_SERO_ID);       
        FETCH SOFE_LIST_CURR_IPTV INTO L_IPTV_VAL;
        CLOSE SOFE_LIST_CURR_IPTV; 
        
               
            IF L_ADSL_VAL='Y' AND L_IPTV_VAL='Y' THEN 
            L_LINEPROFILE:='IPTV_SLTBB';
            
            ELSIF L_ADSL_VAL='Y' AND L_IPTV_VAL IS NULL THEN
            L_LINEPROFILE:='SLTBB';
            
            ELSIF L_IPTV_VAL='Y' AND L_ADSL_VAL IS NULL THEN
            L_LINEPROFILE:='IPTV';
            
            END IF;*/

    ELSIF V_EQTYPE='HUAWEI' THEN 
    
     A_LINEPROFILE:='HUAWEI'; 
    /*
    
        OPEN SOFE_LIST_CURR_ADSL(V_SERO_ID);       
        FETCH SOFE_LIST_CURR_ADSL INTO L_ADSL_VAL;
        CLOSE SOFE_LIST_CURR_ADSL; 
            
        OPEN SOFE_LIST_CURR_IPTV(V_SERO_ID);       
        FETCH SOFE_LIST_CURR_IPTV INTO L_IPTV_VAL;
        CLOSE SOFE_LIST_CURR_IPTV; 
        
               
            IF L_ADSL_VAL='Y' AND L_IPTV_VAL='Y' THEN 
            L_LINEPROFILE:='IPTV_SLTBB';
            
            ELSIF L_ADSL_VAL='Y' AND L_IPTV_VAL IS NULL THEN
            L_LINEPROFILE:='SLTBB';
            
            ELSIF L_IPTV_VAL='Y' AND L_ADSL_VAL IS NULL THEN
            L_LINEPROFILE:='IPTV';
            
                                
            END IF;
           
    
    ELSIF V_EQTYPE='ZTE' AND V_EQMODL LIKE 'ZXDSL9806H%' THEN
    
     A_LINEPROFILE:='ZTE';*/
    
            
    ELSIF V_EQTYPE='ALCATEL' THEN 
    
     A_LINEPROFILE:='ALCATEL';
     

    END IF;

    IF L_LINEPROFILE IS NOT NULL THEN
    
    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET SOA.SEOA_DEFAULTVALUE = L_LINEPROFILE
    WHERE SOA.SEOA_SERO_ID = V_SERO_ID
    AND SOA.SEOA_NAME = 'LINE_PROFILE';
    
    ELSIF A_LINEPROFILE IS NOT NULL THEN
        
       
       BEGIN
       P_SLT_FUNCTIONS_V2.ADSL_LINE_PROFILE_TO_SPEED(
                      p_serv_id        ,
                      p_sero_id        ,
                      p_seit_id        ,
                      p_impt_taskname  ,
                      p_woro_id        ,
                      p_ret_char       ,
                      p_ret_number     ,
                      p_ret_msg        );
       
       END;
       
   
    ELSE 
    
    UPDATE SERVICE_ORDER_ATTRIBUTES SOA
    SET SOA.SEOA_DEFAULTVALUE = NULL
    WHERE SOA.SEOA_SERO_ID = V_SERO_ID
    AND SOA.SEOA_NAME = 'LINE_PROFILE';
        
     
    END IF;
            p_ret_char := 'OK';
            p_ret_msg := NULL;

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



 EXCEPTION
 WHEN OTHERS THEN


        p_ret_msg  := 'UPDATE_ADSL_LINE_PROFILE_ATTR' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);


END UPDATE_ADSL_LINE_PROFILE_ATTR;

--- 06-03-2014  Ruwan Ranasinghe

-- 11-07-2012 Samankula Owitipana
--- Updated 19-05-2014 Dinesh
PROCEDURE ADSL_SET_NAS_PORTID_ATTRIBUTE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS  
      
                
v_equip_model       VARCHAR2(200);          
v_hu_equip_type    VARCHAR2(200);
v_card_port_id     VARCHAR2(100);
v_zte_shelf           VARCHAR2(100);
v_zte_rack            number;
v_zte_card_slot       number;
v_zte_port           number;
v_PID                VARCHAR2(100);
v_PORT                VARCHAR2(100);
v_EQ_MODEL            VARCHAR2(100);
v_AREA                  VARCHAR2(100);
v_CARD_MODEL        VARCHAR2(100);
v_CARD_NAME            VARCHAR2(100);
v_EQUIP_VERTION        VARCHAR2(100);
v_EQ_AREA            VARCHAR2(100);
v_ADSL_CCT_ID        VARCHAR2(100);
v_card_rack         VARCHAR2(100);
v_card_shelf        VARCHAR2(100);
v_card_slot         VARCHAR2(100);
v_hu_port              VARCHAR2(100);
v_hu_area           VARCHAR2(100);
v_equipment         VARCHAR2(100);



cursor c_zte_port_details is
select to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),to_number(replace(po.PORT_NAME,'DSL-IN-',''))
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and so.SERO_ID = p_sero_id
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA';

cursor c_zte_port_details_v3 is
select to_number(replace(replace(substr(po.PORT_CARD_SLOT,-7,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),to_number(replace(po.PORT_NAME,'DSL-IN-',''))
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and so.SERO_ID = sero_id
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA';

CURSOR c_pid IS
SELECT DISTINCT REPLACE(SUBSTR(REPLACE(po.PORT_CARD_SLOT,'P',''),INSTR(po.PORT_CARD_SLOT,'.')),'.','-') || '-' || REPLACE(po.PORT_NAME,'DSL-IN-',''),
SUBSTR(eq.equp_index,-2) ,trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),eq.EQUP_EQUM_MODEL
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA'
AND po.PORT_CARD_SLOT LIKE 'P%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

CURSOR c_pid2 IS
SELECT DISTINCT '1' || SUBSTR(po.PORT_CARD_SLOT,4) || '-' , REPLACE(po.PORT_NAME,'DSL-IN-',''),
SUBSTR(EQ.EQUP_INDEX ,-2,2),trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),ca.CARD_MODEL,ca.CARD_NAME,
eq.EQUP_EQUM_MODEL
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo,cards ca
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = ca.CARD_EQUP_ID
AND po.PORT_CARD_SLOT = ca.CARD_SLOT
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA'
AND po.PORT_CARD_SLOT LIKE 'Z%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

CURSOR c_msan_combo IS
SELECT DISTINCT to_number(REPLACE(SUBSTR(po.PORT_CARD_SLOT,1,INSTR(po.PORT_CARD_SLOT,'-')-1),'A','')),
to_number(SUBSTR(po.PORT_CARD_SLOT,INSTR(po.PORT_CARD_SLOT,'-')+1,(INSTR(po.PORT_CARD_SLOT,'-',1,2)-1)-(INSTR(po.PORT_CARD_SLOT,'-')))),
to_number(SUBSTR(po.PORT_CARD_SLOT,(INSTR(po.PORT_CARD_SLOT,'-',1,2)+1))),
to_number(REPLACE(po.PORT_NAME,'DSL-IN-','')),
trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),replace(eq.EQUP_EQUM_MODEL,'(IPMB)','')
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo,cards ca
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = ca.CARD_EQUP_ID
AND po.PORT_CARD_SLOT = ca.CARD_SLOT
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA'
AND po.PORT_CARD_SLOT LIKE 'A%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;

CURSOR c_dslam_card IS
SELECT DISTINCT to_number(SUBSTR(po.PORT_CARD_SLOT,INSTR(po.PORT_CARD_SLOT,'.')+1,(INSTR(po.PORT_CARD_SLOT,'.',1,2)-1)-(INSTR(po.PORT_CARD_SLOT,'.')))),
to_number(SUBSTR(po.PORT_CARD_SLOT,INSTR(po.PORT_CARD_SLOT,'.',1,2)+1,(INSTR(po.PORT_CARD_SLOT,'.',1,3)-1)-(INSTR(po.PORT_CARD_SLOT,'.',1,2)))),
to_number(SUBSTR(po.PORT_CARD_SLOT,(INSTR(po.PORT_CARD_SLOT,'.',1,3)+1))),
to_number(REPLACE(po.PORT_NAME,'DSL-IN-','')),
trim(SUBSTR(lo.LOCN_TTNAME,1,INSTR(lo.LOCN_TTNAME,'NODE')-2)),replace(eq.EQUP_EQUM_MODEL,'(IPMB)','')
FROM ports po,PORT_LINKS pl,PORT_LINK_PORTS plp,equipment eq,locations lo,cards ca
WHERE pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_EQUP_ID = ca.CARD_EQUP_ID
AND po.PORT_CARD_SLOT = ca.CARD_SLOT
AND po.PORT_EQUP_ID = eq.EQUP_ID
AND eq.EQUP_LOCN_TTNAME = lo.LOCN_TTNAME
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT <> 'NA'
AND po.PORT_CARD_SLOT LIKE 'P%'
AND pl.PORL_CIRT_NAME = v_ADSL_CCT_ID;


BEGIN 


SELECT upper(soa.seoa_defaultvalue) 
INTO v_equip_model
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'ADSL_EQIP_MODEL';
SELECT upper(soa.seoa_defaultvalue) 
INTO v_CARD_MODEL
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'ADSL_CARD_MODEL';
SELECT so.SERO_CIRT_NAME
INTO v_ADSL_CCT_ID
FROM Service_Orders so,circuits ci
WHERE so.SERO_CIRT_NAME = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id;
/* IF v_equip_model = 'MA5600' or v_equip_model = 'MA5605' THEN
open c_dslam_card;
fetch c_dslam_card into v_card_rack,v_card_shelf,v_card_slot,v_hu_port,v_hu_area,v_equipment;
close c_dslam_card;
UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_hu_area || '_'  || v_equipment || '_'  || v_card_rack || '.' || v_card_shelf ||
 ' atm ' || v_card_rack || '/' || v_card_shelf || '/' || v_card_slot || '/' || v_hu_port  || ':8.35'
WHERE SA.SEOA_NAME = 'SA_NAS_PORT_ID'
AND SA.SEOA_SERO_ID = p_sero_id;

ELSIF v_equip_model like 'UA5000%' THEN
    IF v_CARD_MODEL = 'COMBO' THEN
    open c_msan_combo;
    fetch c_msan_combo into v_card_rack,v_card_shelf,v_card_slot,v_hu_port,v_hu_area,v_equipment;
    close c_msan_combo;
    ELSE
    open c_dslam_card;
    fetch c_dslam_card into v_card_rack,v_card_shelf,v_card_slot,v_hu_port,v_hu_area,v_equipment;
    close c_dslam_card;
    END IF;
UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_hu_area || '_'  || v_equipment || '_'  || v_card_rack || '.' || v_card_shelf ||
 ' atm ' || v_card_shelf || '/' || v_card_slot || '/0/' || v_hu_port  || ':8.35'
WHERE SA.SEOA_NAME = 'SA_NAS_PORT_ID'
AND SA.SEOA_SERO_ID = p_sero_id; */

----Comment & changed ELSIF to IF -------


IF v_equip_model = 'MSAG5200' THEN
OPEN c_zte_port_details;
FETCH c_zte_port_details INTO v_zte_shelf,v_zte_card_slot,v_zte_port;
CLOSE c_zte_port_details;
OPEN c_pid2;
FETCH c_pid2 INTO v_PID,v_PORT,v_EQ_MODEL,v_AREA,v_CARD_MODEL,v_CARD_NAME,v_EQUIP_VERTION;
CLOSE c_pid2;
IF   v_PID is null THEN   
OPEN c_pid;
FETCH c_pid INTO v_PID,v_EQ_MODEL,v_AREA,v_EQUIP_VERTION;
CLOSE c_pid;
END IF;
IF v_EQUIP_VERTION = 'MSAG5200' THEN
v_EQ_AREA := v_AREA || '_MSAG5200_' || v_EQ_MODEL;
END IF;
IF (v_EQ_AREA is not null and v_zte_port is not null) THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_EQ_AREA || ' atm ' || v_zte_shelf || '/' || v_zte_card_slot || '/' || v_zte_port || ':8.35'
WHERE SA.SEOA_NAME = 'SA_NAS_PORT_ID'
AND SA.SEOA_SERO_ID = p_sero_id;
END IF;

ELSIF v_equip_model = 'MSAG5200-ISL' THEN
OPEN c_zte_port_details_v3;
FETCH c_zte_port_details_v3 INTO v_zte_rack,v_zte_shelf,v_zte_card_slot,v_zte_port;
CLOSE c_zte_port_details_v3;
OPEN c_pid2;
FETCH c_pid2 INTO v_PID,v_PORT,v_EQ_MODEL,v_AREA,v_CARD_MODEL,v_CARD_NAME,v_EQUIP_VERTION;
CLOSE c_pid2;
IF   v_PID is null THEN   
OPEN c_pid;
FETCH c_pid INTO v_PID,v_EQ_MODEL,v_AREA,v_EQUIP_VERTION;
CLOSE c_pid;
END IF;
IF v_EQUIP_VERTION = 'MSAG5200-ISL' THEN
v_EQ_AREA := v_AREA || '_MSAG5200_' || (SUBSTR(v_EQ_MODEL,1,8)) ;
END IF;
IF (v_EQ_AREA is not null and v_zte_port is not null) THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_EQ_AREA || ' atm ' || v_zte_rack || '/' || v_zte_shelf || '/' || v_zte_card_slot || '/' || v_zte_port || ':8.35'
WHERE SA.SEOA_NAME = 'SA_NAS_PORT_ID'
AND SA.SEOA_SERO_ID = p_sero_id;
END IF;

ELSIF v_equip_model like 'ZXDSL9806H%' THEN
OPEN c_zte_port_details;
FETCH c_zte_port_details INTO v_zte_shelf,v_zte_card_slot,v_zte_port;
CLOSE c_zte_port_details;
OPEN c_pid2;
FETCH c_pid2 INTO v_PID,v_PORT,v_EQ_MODEL,v_AREA,v_CARD_MODEL,v_CARD_NAME,v_EQUIP_VERTION;
CLOSE c_pid2;
IF   v_PID is null THEN   
OPEN c_pid;
FETCH c_pid INTO v_PID,v_EQ_MODEL,v_AREA,v_EQUIP_VERTION;
CLOSE c_pid;
END IF;
IF v_EQUIP_VERTION like 'ZXDSL9806H%' THEN
v_EQ_AREA := v_AREA || '_ZXDSL9806H_' || v_EQ_MODEL;
END IF;
IF (v_EQ_AREA is not null and v_zte_port is not null) THEN
UPDATE SERVICE_ORDER_ATTRIBUTES SA
SET SA.SEOA_DEFAULTVALUE = v_EQ_AREA || ' atm ' || v_zte_shelf || '/' || v_zte_card_slot || '/' || v_zte_port || ':8.35'
WHERE SA.SEOA_NAME = 'SA_NAS_PORT_ID'
AND SA.SEOA_SERO_ID = p_sero_id;
END IF;
END IF;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
EXCEPTION WHEN OTHERS THEN
p_ret_msg  := 'ADSL SET NAS_PORT_ID ATTRIBUTE FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
/*INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg);*/
END ADSL_SET_NAS_PORTID_ATTRIBUTE;

-- 11-07-2011 Samankula Owitipana 

--- 30-03-2011  Samankula Owitipana


PROCEDURE FAULT_WF_SET_CCT_DATA(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_cr_no VARCHAR2(50);
v_ac_no VARCHAR2(50);
v_cct_id VARCHAR2(50);
v_serv_id VARCHAR2(50);
v_dis_name VARCHAR2(50);     
v_cct_speed VARCHAR2(60);
v_fault_id VARCHAR2(60);

v_pcat VARCHAR2(200);
v_psubcat VARCHAR2(200);

v_attr_name  VARCHAR2(100);
v_attr_value  VARCHAR2(100);

v_fe_iptv VARCHAR2(5);
v_fe_internet VARCHAR2(5);
v_fe_tstv VARCHAR2(5);
v_fe_vod VARCHAR2(5);

CURSOR cct_data_cur  IS
SELECT ci.CIRT_CUSR_ABBREVIATION,ci.CIRT_ACCT_NUMBER,ci.CIRT_NAME,ci.CIRT_SERV_ID,ci.CIRT_DISPLAYNAME,ci.CIRT_SPED_ABBREVIATION,REPLACE(so.SERO_OEID,'FM','')      
FROM SERVICE_ORDERS SO,problems p,problem_links pl,circuits ci
WHERE REPLACE(so.SERO_OEID,'FM','') = p.PROM_NUMBER
AND p.PROM_NUMBER = pl.PROL_PROM_NUMBER
AND pl.PROL_FOREIGNID = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id;

CURSOR fault_data_cur  IS
SELECT p.PROM_PCAT_NAME,p.PROM_PRSC_NAME 
FROM problems p
WHERE p.PROM_NUMBER = v_fault_id;


CURSOR cct_serv_attribute_cur  IS      
SELECT sa.SATT_ATTRIBUTE_NAME,sa.SATT_DEFAULTVALUE 
FROM SERVICES_ATTRIBUTES  sa
WHERE sa.SATT_SERV_ID = v_serv_id;

CURSOR cct_fea_iptv_cur  IS
SELECT sf.SFEA_VALUE
FROM SERVICES_FEATURES sf
WHERE sf.SFEA_FEATURE_NAME = 'IPTV'
AND sf.SFEA_SERV_ID = v_serv_id;

CURSOR cct_fea_internet_cur  IS
SELECT sf.SFEA_VALUE
FROM SERVICES_FEATURES sf
WHERE sf.SFEA_FEATURE_NAME = 'INTERNET'
AND sf.SFEA_SERV_ID = v_serv_id;

CURSOR cct_fea_vod_cur  IS
SELECT sf.SFEA_VALUE
FROM SERVICES_FEATURES sf
WHERE sf.SFEA_FEATURE_NAME = 'VIDEO ON DEMAND'
AND sf.SFEA_SERV_ID = v_serv_id;

CURSOR cct_fea_tstv_cur  IS
SELECT sf.SFEA_VALUE
FROM SERVICES_FEATURES sf
WHERE sf.SFEA_FEATURE_NAME = 'TSTV'
AND sf.SFEA_SERV_ID = v_serv_id;




BEGIN



OPEN cct_data_cur;
FETCH cct_data_cur INTO v_cr_no,v_ac_no,v_cct_id,v_serv_id,v_dis_name,v_cct_speed,v_fault_id;
CLOSE cct_data_cur;

OPEN fault_data_cur;
FETCH fault_data_cur INTO v_pcat,v_psubcat;
CLOSE fault_data_cur;


IF ( v_pcat = 'A07-ACCESS NETWORK' AND v_psubcat = '01-DSLAM CARD / PORT' ) 
OR ( v_pcat = 'C02-CPE' AND v_psubcat = '03-FAULTY. REPLACED WITH NEW PHONE' ) THEN


UPDATE SERVICE_ORDER_ATTRIBUTES soa
SET soa.SEOA_DEFAULTVALUE = v_psubcat
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'FAULT IN';

UPDATE SERVICE_ORDER_ATTRIBUTES soa
SET soa.SEOA_DEFAULTVALUE = v_pcat
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'CAUSE OF FAULT';
        

DELETE FROM SERVICE_IMPLEMENTATION_TASKS sit
WHERE sit.SEIT_SERO_ID = p_sero_id
AND sit.SEIT_TASKNAME = 'CANCEL F.WORK FLOW';


UPDATE service_orders so
SET so.SERO_CUSR_ABBREVIATION = v_cr_no,so.SERO_ACCT_NUMBER = v_ac_no,so.SERO_CIRT_NAME = v_cct_id,so.SERO_SERV_ID = v_serv_id,
so.SERO_ORDT_TYPE = 'DELETE',so.SERO_SPED_ABBREVIATION = v_cct_speed,so.SERO_COMPLETION_DATE = SYSDATE,so.SERO_SERV_DISPLAYNAME = v_serv_id
WHERE so.SERO_ID = p_sero_id;

OPEN cct_serv_attribute_cur;

LOOP

v_attr_name:= NULL;
v_attr_value:= NULL;


FETCH cct_serv_attribute_cur INTO v_attr_name,v_attr_value;
EXIT WHEN cct_serv_attribute_cur%NOTFOUND;

UPDATE SERVICE_ORDER_ATTRIBUTES soa
SET soa.SEOA_DEFAULTVALUE = v_attr_value
WHERE soa.SEOA_NAME = v_attr_name
AND soa.SEOA_SERO_ID = p_sero_id;


END LOOP;

CLOSE cct_serv_attribute_cur;


UPDATE SERVICE_ORDER_ATTRIBUTES soa
SET soa.SEOA_DEFAULTVALUE = NULL
WHERE soa.SEOA_NAME = 'ACTUAL_DSP_DATE'
AND soa.SEOA_SERO_ID = p_sero_id;
---------------------------------------------------------------------------------------------

OPEN cct_fea_iptv_cur;
FETCH cct_fea_iptv_cur INTO v_fe_iptv;
CLOSE cct_fea_iptv_cur;

OPEN cct_fea_internet_cur;
FETCH cct_fea_internet_cur INTO v_fe_internet;
CLOSE cct_fea_internet_cur;

OPEN cct_fea_tstv_cur;
FETCH cct_fea_tstv_cur INTO v_fe_tstv;
CLOSE cct_fea_tstv_cur;

OPEN cct_fea_vod_cur;
FETCH cct_fea_vod_cur INTO v_fe_vod;
CLOSE cct_fea_vod_cur;


IF v_fe_iptv = 'Y' AND v_fe_internet = 'Y' THEN

update service_order_attributes soa
set soa.SEOA_SOFE_ID = null
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_SOFE_ID in
(select sof.SOFE_ID
from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV'));

delete from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV');

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'IPTV', 'SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'TSTV', 'SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL);
 
INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'VIDEO ON DEMAND', 'SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, v_dis_name , 'NON-SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'INTERNET', 'NON-SWITCH', 'N', 'Y', v_dis_name , NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

ELSIF v_fe_internet = 'Y' THEN

update service_order_attributes soa
set soa.SEOA_SOFE_ID = null
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_SOFE_ID in
(select sof.SOFE_ID
from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV'));

delete from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV');

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'IPTV', 'SWITCH', 'N', 'N', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'TSTV', 'SWITCH', 'N', 'N', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL);
 
INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'VIDEO ON DEMAND', 'SWITCH', 'N', 'N', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, v_dis_name , 'NON-SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'INTERNET', 'NON-SWITCH', 'N', 'Y', v_dis_name , NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 


ELSIF v_fe_iptv = 'Y' THEN

update service_order_attributes soa
set soa.SEOA_SOFE_ID = null
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_SOFE_ID in
(select sof.SOFE_ID
from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV'));

delete from service_order_features sof
where sof.SOFE_SERO_ID = p_sero_id
and (sof.SOFE_FEATURE_NAME = 'IPTV' or sof.SOFE_FEATURE_NAME = 'TSTV');

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'IPTV', 'SWITCH', 'N', 'Y', NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 

INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'TSTV', 'SWITCH', 'N', v_fe_tstv, NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL);
 
INSERT INTO SERVICE_ORDER_FEATURES ( SOFE_SERO_ID, SOFE_SERO_REVISION, SOFE_FEATURE_NAME, SOFE_TYPE,
SOFE_DEFAULTVALUE, SOFE_PREV_VALUE, SOFE_PARENT_FEATURE_NAME, SOFE_PROVISION_STATUS,
SOFE_PROVISION_TIME, SOFE_PROVISION_USERNAME, SOFE_ID ) VALUES ( 
p_sero_id, 0, 'VIDEO ON DEMAND', 'SWITCH', 'N', v_fe_vod, NULL, NULL, NULL, NULL, SOFE_ID_SEQ.NEXTVAL); 


END IF;


ELSE

DELETE FROM SERVICE_IMPLEMENTATION_TASKS sit
WHERE sit.SEIT_SERO_ID = p_sero_id
AND (sit.SEIT_TASKNAME <> 'CANCEL F.WORK FLOW' AND sit.SEIT_TASKNAME <> 'CLOSE SERVICE ORDER'
AND sit.SEIT_ID <> p_seit_id);


END IF;



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');



EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed to set the circuit details : - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;


    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');


    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);


END FAULT_WF_SET_CCT_DATA;


--- 30-03-2011  Samankula Owitipana

-- 10-05-2011 Samankula Owitipana
-- FAULT WORKFLOW MDF CARD PORT POSITIONS

PROCEDURE FAULT_WF_SET_ATTRIBUTES (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_mdf_rack VARCHAR2(100);
v_mdf_index VARCHAR2(100);
v_mdf_unit VARCHAR2(100);
v_unit_position VARCHAR2(100);
v_mdf_adsl_position VARCHAR2(100);

v_card VARCHAR2(100);
v_port VARCHAR2(100);



CURSOR c_mdf_details IS  
SELECT fc.FRAC_NAME,fc.FRAC_INDEX,fu.FRAU_NAME,fu.FRAU_POSITION,FA.FRAA_POSITION
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU,FRAME_CONTAINERS fc
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fu.FRAU_FRAC_ID = fc.FRAC_ID
AND fa.FRAA_CIRT_NAME IN
(SELECT ci.CIRT_NAME FROM SERVICE_ORDERS so,CIRCUIT_HIERARCHY ch,circuits ci
WHERE so.SERO_CIRT_NAME = ch.CIRH_CHILD
AND ch.CIRH_PARENT = ci.CIRT_NAME
AND so.SERO_ID = p_sero_id )
AND FU.FRAU_NAME LIKE  '%ADSL%'
AND fu.FRAU_NAME NOT LIKE '%POT%'
AND fa.FRAA_SIDE = 'FRONT';      



CURSOR c_card_port_details IS
SELECT po.PORT_CARD_SLOT,po.PORT_NAME
FROM ports po,port_links pl,port_link_ports plp,SERVICE_ORDERS so
WHERE so.SERO_CIRT_NAME = pl.PORL_CIRT_NAME
AND pl.PORL_ID = plp.POLP_PORL_ID
AND plp.POLP_PORT_ID = po.PORT_ID
AND po.PORT_CARD_SLOT <> 'NA'
and po.PORT_NAME like 'DSL-IN-%'
AND so.SERO_ID = p_sero_id;





BEGIN

OPEN c_mdf_details;
FETCH c_mdf_details INTO v_mdf_rack,v_mdf_index,v_mdf_unit,v_unit_position,v_mdf_adsl_position;
CLOSE c_mdf_details;


OPEN c_card_port_details;
FETCH c_card_port_details INTO v_card,v_port;
CLOSE c_card_port_details;

UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_mdf_rack || '-' || v_mdf_index || ' ' || v_mdf_unit || v_unit_position || ' ' || v_mdf_adsl_position 
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'OLD ADSL MDF POSITION' ;


UPDATE service_order_attributes soa
SET SOA.SEOA_DEFAULTVALUE = v_card || ' ' || v_port
WHERE soa.SEOA_SERO_ID = p_sero_id
AND soa.SEOA_NAME = 'OLD ADSL CARD PORT' ;


     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
                
                

EXCEPTION
WHEN OTHERS THEN


        p_ret_msg  := 'SET MDF CARD PORT POSITIONS FAILED:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

        p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);
          

END FAULT_WF_SET_ATTRIBUTES;

-- 10-05-2011 Samankula Owitipana

-- 06-03-2013 Samankula Owitipana
-- FAULT WORKFLOW ADSL_DELETE_SO

PROCEDURE FAULT_WF_DELETE_ADSL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_adsl_cct_id varchar2(30);
v_bearer_cct_id varchar2(30);
v_pstn_cct_id varchar2(30);
v_adsl_card varchar2(60);
v_adsl_port varchar2(60);
v_adsl_port_id number;
v_adsl_equip_id number;
v_bearer_max_seq number;
v_pstn_seq number;
v_pstn_pl_id number;
v_splitter_port_id number;
v_splitter_equip_id number;
v_pstn_dis_name varchar2(60);

CURSOR c_pstn_xcon_data IS
SELECT pl.PORL_SEQUENCE,pl.PORL_ID
FROM PORT_LINKS PL
WHERE pl.PORL_CIRT_NAME = v_pstn_cct_id
order by pl.PORL_SEQUENCE;
cursor c_adsl_card_port is
select distinct po.PORT_CARD_SLOT,replace(po.PORT_NAME,'DSL-IN-',''),po.PORT_ID,po.PORT_EQUP_ID
from port_links pl,port_link_ports plp,ports po
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_NAME like 'DSL-IN-%'
and pl.PORL_CIRT_NAME = v_adsl_cct_id;
cursor c_bearer_cct is
select ci.CIRT_NAME
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_PARENT = ci.CIRT_NAME
and ch.CIRH_CHILD = v_adsl_cct_id
and ci.CIRT_TYPE = 'BEARER';
CURSOR plp_ex_cur IS
SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT
FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp
WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
AND fu.FRAU_ID = fa.FRAA_FRAU_ID
AND fa.FRAA_ID = plp.POLP_FRAA_ID
AND fc.FRAC_FRAN_NAME = 'MDF'
AND fu.FRAU_NAME LIKE '%EX%'
AND fa.FRAA_SIDE = 'FRONT'
AND fa.FRAA_CIRT_NAME = v_pstn_cct_id;
CURSOR plp_ug_cur IS
SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT
FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp
WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
AND fu.FRAU_ID = fa.FRAA_FRAU_ID
AND fa.FRAA_ID = plp.POLP_FRAA_ID
AND fc.FRAC_FRAN_NAME = 'MDF'
AND fu.FRAU_NAME LIKE '%UG%'
AND fa.FRAA_SIDE = 'FRONT'
AND fa.FRAA_CIRT_NAME = v_pstn_cct_id;
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
CURSOR c_splitter_data IS
select po.PORT_ID,po.PORT_EQUP_ID
from ports po
where po.PORT_CIRT_NAME = v_bearer_cct_id
and po.PORT_CARD_SLOT = 'NA'
and po.PORT_NAME like 'POTS%' ;

BEGIN

select so.SERO_CIRT_NAME 
into v_adsl_cct_id from service_orders so
where so.SERO_ID = p_sero_id;
open c_adsl_card_port;
fetch c_adsl_card_port 
into v_adsl_card,v_adsl_port,v_adsl_port_id,v_adsl_equip_id;
close c_adsl_card_port;
open c_bearer_cct;
fetch c_bearer_cct into v_bearer_cct_id;
close c_bearer_cct;
delete from port_link_ports plp
where plp.POLP_PORT_ID = v_adsl_port_id;
UPDATE PORTS Po
SET po.PORT_CIRT_NAME = NULL,po.PORT_STATUS = 'BADPORT'
WHERE po.PORT_ID = v_adsl_port_id;
IF v_bearer_cct_id is null THEN
SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_dis_name
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';
SELECT ci.CIRT_NAME
INTO v_pstn_cct_id
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_dis_name || '%'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
IF v_adsl_card like 'A%' or v_adsl_card like 'Z%' THEN
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%MDF-EX%');
UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%MDF-EX%');
END IF;
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%');
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%';
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%');
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%';
delete port_links pl
where pl.PORL_ID in
(SELECT pl.PORL_ID
FROM port_links pl,port_link_ports plp
WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
and plp.POLP_PORL_ID is null
AND pl.PORL_CIRT_NAME = v_pstn_cct_id);
ELSIF v_bearer_cct_id is not null THEN
IF v_adsl_card like 'P%' THEN
select ci.CIRT_NAME
into v_pstn_cct_id
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_CHILD = ci.CIRT_NAME
and ch.CIRH_PARENT = v_bearer_cct_id
and ci.CIRT_SERT_ABBREVIATION = 'PSTN';
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_bearer_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_bearer_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%');
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%';
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_bearer_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%';
UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_pstn_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_bearer_cct_id)
AND FU.FRAU_NAME LIKE  '%ADSL%');
delete port_links pl
where pl.PORL_ID in
(SELECT pl.PORL_ID
FROM port_links pl,port_link_ports plp
WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
and plp.POLP_PORL_ID is null
AND pl.PORL_CIRT_NAME = v_pstn_cct_id);
delete port_links pl
where pl.PORL_ID in
(SELECT pl.PORL_ID
FROM port_links pl,port_link_ports plp
WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
and plp.POLP_PORL_ID is null
AND pl.PORL_CIRT_NAME = v_bearer_cct_id);
ELSIF v_adsl_card like 'A%' or v_adsl_card like 'Z%' THEN
select ci.CIRT_NAME
into v_pstn_cct_id
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_CHILD = ci.CIRT_NAME
and ch.CIRH_PARENT = v_bearer_cct_id
and ci.CIRT_SERT_ABBREVIATION = 'PSTN';
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_FRAA_ID IN (SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_bearer_cct_id)
AND FU.FRAU_NAME LIKE  '%MDF-EX%');
UPDATE FRAME_APPEARANCES FA
SET FA.FRAA_CIRT_NAME = NULL
WHERE FA.FRAA_ID IN(
SELECT FA.FRAA_ID
FROM FRAME_APPEARANCES FA,FRAME_UNITS FU
WHERE FA.FRAA_FRAU_ID = FU.FRAU_ID
AND fa.FRAA_CIRT_NAME IN
(v_bearer_cct_id)
AND FU.FRAU_NAME LIKE  '%MDF-EX%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%');
DELETE PORT_LINK_PORTS plp
WHERE plp.POLP_PORT_ID IN (
SELECT P.PORT_ID FROM PORTS P
WHERE p.PORT_CIRT_NAME IN (v_bearer_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%');
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_pstn_cct_id)
AND P.PORT_NAME LIKE 'POTS-IN-%';
UPDATE PORTS P
SET P.PORT_CIRT_NAME = NULL,p.PORT_STATUS = 'BADPORT'
WHERE p.PORT_CIRT_NAME IN (v_bearer_cct_id)
AND P.PORT_NAME LIKE 'POTS-OUT-%';
delete port_links pl
where pl.PORL_ID in
(SELECT pl.PORL_ID
FROM port_links pl,port_link_ports plp
WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
and plp.POLP_PORL_ID is null
AND pl.PORL_CIRT_NAME = v_pstn_cct_id);
delete port_links pl
where pl.PORL_ID in
(SELECT pl.PORL_ID
FROM port_links pl,port_link_ports plp
WHERE pl.PORL_ID = plp.POLP_PORL_ID(+)
and plp.POLP_PORL_ID is null
AND pl.PORL_CIRT_NAME = v_bearer_cct_id);
END IF;END IF;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
EXCEPTION
WHEN OTHERS THEN
p_ret_msg  := 'ADSL REMOVE CCT FAILED' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
          SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
          , p_ret_msg);
          
END FAULT_WF_DELETE_ADSL;

-- 06-03-2013 Samankula Owitipana

-- 09-03-2013 Samankula Owitipana
-- ADSL_CREATE_PSTN_CCT_AUTO_BUILD Version 02
--Circuit validation is added.

PROCEDURE FAULT_WF_CREATE_ADSL_XCON_AUTO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

v_adsl_cct_id varchar2(60);
v_pstn_no  varchar2(60);
v_pstn_cct_id varchar2(60);
v_bearer_cct_id varchar2(60);
v_adsl_card_slot varchar2(60);
v_adsl_port_id number;
v_pots_out_port_id number;
v_pots_out_cace_id number;
v_pots_out_phyc_id number;
v_pots_in_cace_id number;
v_pots_in_phyc_id number;
v_pots_out_cabc_id number;
v_pots_in_cabc_id number;
v_POTS_OUT_FRAA_ID_REAR number;
v_POTS_OUT_FRAU_ID number;
v_POTS_OUT_FRAA_POSITION varchar2(10);
v_POTS_OUT_FRAA_ID_FRONT number;
v_POTS_IN_FRAA_ID_REAR  number;
v_POTS_IN_FRAU_ID  number;
v_POTS_IN_FRAA_POSITION varchar2(10);
v_POTS_IN_FRAA_ID_FRONT number;
v_ug_pl_id number;
v_ug_plp_comport varchar2(5);
v_ug_pl_seq number;
v_ug_plp_fraa_id number;
v_ex_rear_pl_id number;
v_msan_pstn_pl_id number;
v_ex_pl_id number;
v_ex_plp_comport varchar2(5);
v_ex_pl_seq number;
v_ex_plp_fraa_id number;
v_adsl_pot_rear_pl_id number;
v_pots_in_port_id number;

cursor c_bearer_cct is
select ci.CIRT_NAME
from CIRCUIT_HIERARCHY ch,circuits ci
where ch.CIRH_PARENT = ci.CIRT_NAME
and ch.CIRH_CHILD = v_adsl_cct_id
and ci.CIRT_TYPE = 'BEARER';
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
INTO v_adsl_cct_id
FROM Service_Orders so
WHERE so.SERO_ID = p_sero_id;
SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_no
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';
SELECT ci.CIRT_NAME
INTO v_pstn_cct_id
FROM circuits ci
WHERE ci.CIRT_DISPLAYNAME like v_pstn_no || '%'
and (ci.CIRT_STATUS not like 'CA%' and ci.CIRT_STATUS not like 'PE%')
and ci.CIRT_DISPLAYNAME not like '%-COPY%' ;
select distinct po.PORT_CARD_SLOT,po.PORT_ID
into v_adsl_card_slot,v_adsl_port_id
from port_links pl,port_link_ports plp,ports po
where pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_NAME like 'DSL-IN-%'
and pl.PORL_CIRT_NAME = v_adsl_cct_id;
open c_bearer_cct;
fetch c_bearer_cct into v_bearer_cct_id;
close c_bearer_cct;
IF v_bearer_cct_id is not null THEN
IF (v_adsl_card_slot like 'A%' or v_adsl_card_slot like 'Z%') THEN
select po.PORT_ID,po.PORT_CACE_ID,po.PORT_PHYC_ID,cce.CACE_CABC_ID
into v_pots_out_port_id,v_pots_out_cace_id,v_pots_out_phyc_id,v_pots_out_cabc_id
from ports po,PORT_HIERARCHY ph,CABLE_CORE_ENDS cce
where ph.PORH_PARENTID = po.PORT_ID
and po.PORT_PHYC_ID = cce.CACE_PHYC_ID
and po.PORT_CACE_ID = cce.CACE_ID
and po.PORT_NAME like 'POTS-OUT-%'
and ph.PORH_CHILDID = v_adsl_port_id;
select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
into v_POTS_OUT_FRAA_ID_REAR,v_POTS_OUT_FRAU_ID,v_POTS_OUT_FRAA_POSITION
from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
and cce.CACE_ID = fa.FRAA_CACE_ID
and cce.CACE_CABC_ID = v_pots_out_cabc_id
and cce.CACE_PHYC_ID <> v_pots_out_phyc_id
and cce.CACE_ID <> v_pots_out_cace_id;
select fa.FRAA_ID
into v_POTS_OUT_FRAA_ID_FRONT
from FRAME_APPEARANCES fa
where fa.FRAA_FRAU_ID = v_POTS_OUT_FRAU_ID
and fa.FRAA_POSITION = v_POTS_OUT_FRAA_POSITION
and fa.FRAA_SIDE = 'FRONT';
select po.PORT_ID
into v_pots_in_port_id
from ports po,PORT_HIERARCHY ph
where ph.PORH_CHILDID= po.PORT_ID
and po.PORT_NAME like 'POTS-IN-%'
and ph.PORH_PARENTID = v_pots_out_port_id;
SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
INTO v_ug_pl_id,v_ug_plp_comport,v_ug_pl_seq,v_ug_plp_fraa_id
FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
AND fu.FRAU_ID = fa.FRAA_FRAU_ID
AND fa.FRAA_ID = plp.POLP_FRAA_ID
AND plp.POLP_PORL_ID = pl.PORL_ID
AND fc.FRAC_FRAN_NAME = 'MDF'
AND fu.FRAU_NAME LIKE '%UG%'
AND fa.FRAA_SIDE = 'FRONT'
AND pl.PORL_CIRT_NAME = v_bearer_cct_id;
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_ug_pl_id, 'T', v_POTS_OUT_FRAA_ID_FRONT);
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_bearer_cct_id
WHERE fa.FRAA_ID = v_POTS_OUT_FRAA_ID_FRONT;
select PORL_ID_SEQ.nextval into v_ex_rear_pl_id from dual;
INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
VALUES ( v_ex_rear_pl_id, v_bearer_cct_id, v_ug_pl_seq + 10, 'PHYSICAL', NULL, 'Y');                                                      
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_ex_rear_pl_id, 'F', v_POTS_OUT_FRAA_ID_REAR);  
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( v_pots_out_port_id, v_ex_rear_pl_id, 'T', NULL);                         
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_bearer_cct_id
WHERE fa.FRAA_ID = v_POTS_OUT_FRAA_ID_REAR;    
UPDATE PORTS po
SET po.PORT_CIRT_NAME = v_bearer_cct_id
WHERE po.PORT_ID = v_pots_out_port_id;
select distinct pl.PORL_ID 
into v_msan_pstn_pl_id
from port_links pl
where pl.PORL_CIRT_NAME = v_pstn_cct_id;   
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( v_pots_in_port_id, v_msan_pstn_pl_id, 'T', NULL);  
UPDATE PORTS po
SET po.PORT_CIRT_NAME = v_pstn_cct_id
WHERE po.PORT_ID = v_pots_in_port_id;                                                                                                                                 
ELSIF v_adsl_card_slot like 'P%' THEN
select po.PORT_ID,po.PORT_CACE_ID,po.PORT_PHYC_ID,cce.CACE_CABC_ID
into v_pots_out_port_id,v_pots_out_cace_id,v_pots_out_phyc_id,v_pots_out_cabc_id
from ports po,PORT_HIERARCHY ph,CABLE_CORE_ENDS cce
where ph.PORH_PARENTID = po.PORT_ID
and po.PORT_PHYC_ID = cce.CACE_PHYC_ID
and po.PORT_CACE_ID = cce.CACE_ID
and po.PORT_NAME like 'POTS-OUT-%'
and ph.PORH_CHILDID = v_adsl_port_id;
select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
into v_POTS_OUT_FRAA_ID_REAR,v_POTS_OUT_FRAU_ID,v_POTS_OUT_FRAA_POSITION
from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
and cce.CACE_ID = fa.FRAA_CACE_ID
and cce.CACE_CABC_ID = v_pots_out_cabc_id
and cce.CACE_PHYC_ID <> v_pots_out_phyc_id
and cce.CACE_ID <> v_pots_out_cace_id;
select fa.FRAA_ID
into v_POTS_OUT_FRAA_ID_FRONT
from FRAME_APPEARANCES fa
where fa.FRAA_FRAU_ID = v_POTS_OUT_FRAU_ID
and fa.FRAA_POSITION = v_POTS_OUT_FRAA_POSITION
and fa.FRAA_SIDE = 'FRONT';
SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
INTO v_ug_pl_id,v_ug_plp_comport,v_ug_pl_seq,v_ug_plp_fraa_id
FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
AND fu.FRAU_ID = fa.FRAA_FRAU_ID
AND fa.FRAA_ID = plp.POLP_FRAA_ID
AND plp.POLP_PORL_ID = pl.PORL_ID
AND fc.FRAC_FRAN_NAME = 'MDF'
AND fu.FRAU_NAME LIKE '%UG%'
AND fa.FRAA_SIDE = 'FRONT'
AND pl.PORL_CIRT_NAME = v_bearer_cct_id;
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_ug_pl_id, 'T', v_POTS_OUT_FRAA_ID_FRONT);
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_bearer_cct_id
WHERE fa.FRAA_ID = v_POTS_OUT_FRAA_ID_FRONT;
select PORL_ID_SEQ.nextval into v_ex_rear_pl_id from dual;
INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
VALUES ( v_ex_rear_pl_id, v_bearer_cct_id, v_ug_pl_seq + 10, 'PHYSICAL', NULL, 'Y');                                                  
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_ex_rear_pl_id, 'F', v_POTS_OUT_FRAA_ID_REAR);  
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( v_pots_out_port_id, v_ex_rear_pl_id, 'T', NULL);                          
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_bearer_cct_id
WHERE fa.FRAA_ID = v_POTS_OUT_FRAA_ID_REAR;    
UPDATE PORTS po
SET po.PORT_CIRT_NAME = v_bearer_cct_id
WHERE po.PORT_ID = v_pots_out_port_id;
select po.PORT_ID,po.PORT_CACE_ID,po.PORT_PHYC_ID,cce.CACE_CABC_ID
into v_pots_in_port_id,v_pots_in_cace_id,v_pots_in_phyc_id,v_pots_in_cabc_id
from ports po,PORT_HIERARCHY ph,CABLE_CORE_ENDS cce
where ph.PORH_CHILDID= po.PORT_ID
and po.PORT_PHYC_ID = cce.CACE_PHYC_ID
and po.PORT_CACE_ID = cce.CACE_ID
and po.PORT_NAME like 'POTS-IN-%'
and ph.PORH_PARENTID = v_pots_out_port_id;
select fa.FRAA_ID,fa.FRAA_FRAU_ID,fa.FRAA_POSITION
into v_POTS_IN_FRAA_ID_REAR,v_POTS_IN_FRAU_ID,v_POTS_IN_FRAA_POSITION
from CABLE_CORE_ENDS cce,FRAME_APPEARANCES fa
where cce.CACE_PHYC_ID = fa.FRAA_PHYC_ID
and cce.CACE_ID = fa.FRAA_CACE_ID
and cce.CACE_CABC_ID = v_pots_in_cabc_id
and cce.CACE_PHYC_ID <> v_pots_in_phyc_id
and cce.CACE_ID <> v_pots_in_cace_id;
select fa.FRAA_ID
into v_POTS_IN_FRAA_ID_FRONT
from FRAME_APPEARANCES fa
where fa.FRAA_FRAU_ID = v_POTS_IN_FRAU_ID
and fa.FRAA_POSITION = v_POTS_IN_FRAA_POSITION
and fa.FRAA_SIDE = 'FRONT';
SELECT plp.POLP_PORL_ID,plp.POLP_COMMONPORT,pl.PORL_SEQUENCE,plp.POLP_FRAA_ID
INTO v_ex_pl_id,v_ex_plp_comport,v_ex_pl_seq,v_ex_plp_fraa_id
FROM FRAME_CONTAINERS fc,FRAME_UNITS fu,FRAME_APPEARANCES fa,PORT_LINK_PORTS plp,PORT_LINKs pl
WHERE fc.FRAC_ID = fu.FRAU_FRAC_ID
AND fu.FRAU_ID = fa.FRAA_FRAU_ID
AND fa.FRAA_ID = plp.POLP_FRAA_ID
AND plp.POLP_PORL_ID = pl.PORL_ID
AND fc.FRAC_FRAN_NAME = 'MDF'
AND fu.FRAU_NAME LIKE '%EX%'
AND fa.FRAA_SIDE = 'FRONT'
AND pl.PORL_CIRT_NAME = v_pstn_cct_id;
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_ex_pl_id, 'F', v_POTS_IN_FRAA_ID_FRONT);                                                    
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_pstn_cct_id
WHERE fa.FRAA_ID = v_POTS_IN_FRAA_ID_FRONT;                            
select PORL_ID_SEQ.nextval into v_adsl_pot_rear_pl_id from dual;
INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
VALUES ( v_adsl_pot_rear_pl_id, v_pstn_cct_id, v_ex_pl_seq -2, 'PHYSICAL', NULL, 'Y');                                                       
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( NULL, v_adsl_pot_rear_pl_id, 'T', v_POTS_IN_FRAA_ID_REAR);  
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID )
VALUES ( v_pots_in_port_id, v_adsl_pot_rear_pl_id, 'F', NULL);                            
UPDATE FRAME_APPEARANCES fa
SET fa.FRAA_CIRT_NAME = v_pstn_cct_id
WHERE fa.FRAA_ID = v_POTS_IN_FRAA_ID_REAR;    
UPDATE PORTS po
SET po.PORT_CIRT_NAME = v_pstn_cct_id
WHERE po.PORT_ID = v_pots_in_port_id;                            
END IF;

ELSIF v_bearer_cct_id is null THEN
Null;
END IF;
ELSE
p_ret_msg := p_ret_msg || ' Failed to UPDATE ADSL_EQUIP_MODEL.';
END IF;

EXCEPTION
WHEN OTHERS THEN
    p_ret_msg  := 'PSTN CCT ADD CROSS CONNECTIONS FAILED. CHECK SA_PSTN_NUMBER ATTRIBUTE AND PSTN CIRCUIT' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
END FAULT_WF_CREATE_ADSL_XCON_AUTO;

-- 09-03-2013 Samankula Owitipana

--- 27-03-2014 Dinesh Perera

PROCEDURE FTTH_CCT_ID_UPDATE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_cct_id_iptv    varchar2(100);
v_cct_id_ab      varchar2(100); 
v_cct_id_bb      varchar2(100);
v_service_type   varchar2(100);


BEGIN


select so.SERO_SERT_ABBREVIATION
into v_service_type
from service_orders so
where so.SERO_ID = p_sero_id;

SELECT 'IPTV' || trim(SOA.SEOA_DEFAULTVALUE)
INTO v_cct_id_iptv
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'REGISTRATION ID';


SELECT '94' || substr(trim(SOA.SEOA_DEFAULTVALUE),-9)
INTO v_cct_id_bb
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'REGISTRATION ID';


IF v_service_type = 'E-IPTV FTTH' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_cct_id_iptv
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'CIRCUIT ID';


ELSIF v_service_type = 'BB-INTERNET FTTH' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_cct_id_bb
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'ADSL_CIRCUIT_ID';


END IF;


p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed update CIRCUIT ID:'  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      
     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);
    
END FTTH_CCT_ID_UPDATE;

--- 27-03-2014 Dinesh Perera


-- 24-03-2014 Samankula Owitipana

PROCEDURE FTTH_COPY_PSTN_NO_TO_ALL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_bb_so_id         varchar2(100);
v_pstn_no           varchar2(100);
v_pstn_type           varchar2(100);


BEGIN

    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;


SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_type  
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'VOICE TYPE';



IF v_pstn_type = 'PRIMARY' THEN


SELECT trim(SOA.SEOA_DEFAULTVALUE)
INTO v_pstn_no  
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_pstn_no
WHERE SOA.SEOA_SERO_ID in
(select so.SERO_ID from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%')
AND SOA.SEOA_NAME = 'REGISTRATION ID';

END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update SA_PSTN_NUMBER. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END FTTH_COPY_PSTN_NO_TO_ALL;

-- 24-03-2014 Samankula Owitipana


-- 28-02-2014 Samankula Owitipana

PROCEDURE BEARER_SEQ_ATTR_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
v_loc_aend    varchar2(100);
v_loc_bend    varchar2(100);
v_indx         varchar2(10);
v_acc_port_bw varchar2(50);
v_serv_type   varchar2(100);
BEGIN

select lo.LOCN_TTNAME,lo2.LOCN_TTNAME,so.SERO_SERT_ABBREVIATION
into v_loc_aend,v_loc_bend,v_serv_type
from service_orders so,service_orders so2,locations lo,locations lo2
where so.SERO_ID = so2.SERO_ID
and so.SERO_LOCN_ID_AEND = lo.LOCN_ID
and so.SERO_LOCN_ID_BEND = lo2.LOCN_ID
and so.SERO_ID = p_sero_id;

/*SELECT soa.seoa_defaultvalue
INTO v_acc_port_bw
FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS INTF PORT BW';*/
select lpad(nvl(max(substr(replace(ci.CIRT_DISPLAYNAME,'(N)'),-4)),0)+1,4,0) into v_indx from circuits ci
where ci.CIRT_LOCN_AEND = v_loc_aend and ci.CIRT_LOCN_BEND = v_loc_bend 
and (ci.CIRT_STATUS not like 'PEN%' and ci.CIRT_STATUS not like 'CAN%')--and ci.CIRT_DISPLAYNAME like '%' || v_acc_port_bw || '%'
and ci.CIRT_SERT_ABBREVIATION = v_serv_type;
UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_indx
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'SEQ_ID';
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');
EXCEPTION
WHEN OTHERS THEN
      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      p_ret_msg  := 'Failed to set SEQ_ID attribute. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        ,p_ret_msg );
END BEARER_SEQ_ATTR_SET;
-- 28-02-2014 Samankula Owitipana


--- 27-03-2014 Dinesh Perera
---- Edited to cater PRIMARY & SECONDARY VOICE Services ---- Dinesh 02-11-2015 ----
PROCEDURE FTTH_PW_GENERATION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_voice_no      varchar2(100);
v_voice_no_1    varchar2(100);
v_voice_no_2    varchar2(100);
v_pass_val      varchar2(100);
c_number_type   varchar2(100);

CURSOR c_number IS
SELECT SEOA_DEFAULTVALUE
FROM SERVICE_ORDER_ATTRIBUTES
WHERE SEOA_SERO_ID = p_sero_id
AND SEOA_NAME = 'VOICE TYPE';

cursor c_voice_1 is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'REGISTRATION ID';

cursor c_voice_2 is
SELECT trim(SOA.SEOA_DEFAULTVALUE)
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


BEGIN

open c_number;
fetch c_number into c_number_type;
close c_number;

open c_voice_1;
fetch c_voice_1 into v_voice_no_1;
close c_voice_1;

open c_voice_2;
fetch c_voice_2 into v_voice_no_2;
close c_voice_2;

IF c_number_type = 'PRIMARY' THEN
v_voice_no := v_voice_no_1;

ELSIF c_number_type = 'SECONDARY' THEN
v_voice_no := v_voice_no_2;

ELSE 
v_voice_no := v_voice_no_1;

END IF;

SELECT trim(TO_CHAR(SUBSTR(v_voice_no,6,1)+1))
|| TO_CHAR(SUBSTR(v_voice_no,8,1)+1)
|| trim(TO_CHAR(substr(v_voice_no,-2,2)+9,'XXXXXXXX'))
|| to_CHAR(nvl(SUBSTR(v_voice_no,11,1),'0')+1)
|| to_CHAR(SUBSTR(v_voice_no,5,1)+1)
|| to_CHAR(SUBSTR(v_voice_no,9,1)+1)
|| to_CHAR(SUBSTR(v_voice_no,7,1)+1)
|| to_CHAR(SUBSTR(v_voice_no,4,1)+1)
|| to_CHAR(SUBSTR(v_voice_no,10,1)+1)
INTO v_pass_val
FROM DUAL;

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_pass_val
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'VOICE_PASSWORD';

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');         


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to generate or match FTTH PASS WORD. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END FTTH_PW_GENERATION;
---- Edited to cater PRIMARY & SECONDARY VOICE Services ---- Dinesh 02-11-2015 ----
--- 27-03-2014 Dinesh Perera


-- 28-03-2014 Samankula Owitipana
PROCEDURE FTTH_CLOSE_WAIT_VOICE_NUMBER (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS      

v_crm_order_id      varchar2(100);
v_ab_so_id         varchar2(100);
v_voice_so_id         varchar2(100);
v_dsp_date           varchar2(100);


BEGIN

    
SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;


update SERVICE_IMPLEMENTATION_TASKS sit
set sit.SEIT_STAS_ABBREVIATION = 'COMPLETED',sit.SEIT_ACTUAL_END_DATE = sysdate
where sit.SEIT_SERO_ID in
(select so.SERO_ID from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%')
and sit.SEIT_TASKNAME = 'WAIT VOICE REG ID'
and sit.SEIT_STAS_ABBREVIATION in ('INPROGRESS','ASSIGNED');



p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED'); 


EXCEPTION
WHEN OTHERS THEN

p_ret_msg  := 'Failed to update WAIT BB PROVISION task. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, p_ret_msg );

END FTTH_CLOSE_WAIT_VOICE_NUMBER;

-- 28-03-2014 Samankula Owitipana

-- 28-03-2013 Samankula Owitipana
---- 24-08-2015  Edited Dinesh Perera ----
PROCEDURE FTTH_ACCESS_PIPE_ID_ATTR_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS
      
v_cct_id varchar2(100);
v_crm_order_id varchar2(100);


BEGIN

SELECT substr(so.SERO_OEID,1,instr(so.SERO_OEID,'-')-1)
INTO v_crm_order_id
FROM service_orders so
WHERE so.SERO_ID = p_sero_id;

/*select trim(replace(ci.CIRT_DISPLAYNAME,'(N)',''))
into v_cct_id from service_orders so,circuits ci
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and so.SERO_ID = p_sero_id;*/

SELECT trim(replace(ci.CIRT_DISPLAYNAME,'(N)',''))
INTO v_cct_id
FROM SERVICE_ORDERS SO, CIRCUITS CI
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND SO.SERO_OEID LIKE v_crm_order_id || '-%'
AND SO.SERO_SERT_ABBREVIATION = 'AB-FTTH';


UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_cct_id
WHERE soa.seoa_sero_id in
(select so.SERO_ID from service_orders so
where so.SERO_OEID like v_crm_order_id || '-%')
AND soa.seoa_name = 'ACCESS PIPE IDENTIFIER';


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');


EXCEPTION 
WHEN OTHERS THEN

      p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
      
      p_ret_msg  := 'Failed to set ACCESS PIPE IDENTIFIER attribute. - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
        INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        ,p_ret_msg );
        
END FTTH_ACCESS_PIPE_ID_ATTR_SET;
---- 24-08-2015  Edited Dinesh Perera ----
-- 28-03-2013 Samankula Owitipana

---- Edited 31-12-2014 ----
--- 03-04-2014 Samankula Owitipana
PROCEDURE FTTH_INTERNET_CREATION_AUTO (
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


v_display_name  varchar2(100);
v_circuit_id    varchar2(20);
v_bearer_name   varchar2(100);
v_bearer_cct_id varchar2(20);
v_pon_eq_id     varchar2(20);
v_pon_card_slot varchar2(50);
v_pon_port_name varchar2(50);
v_pon_port_id   varchar2(50);
v_serv_port_id   varchar2(50);
v_msan_eq_id     varchar2(20);
v_msan_card_slot varchar2(50);
v_msan_port_name varchar2(50);
v_msan_port_id   varchar2(50);
v_cct_pl_id      varchar2(50);
v_masn_vlan_child_id varchar2(50);
v_error         varchar2(500);

begin


select ci.CIRT_DISPLAYNAME,ci.CIRT_NAME
into v_display_name,v_circuit_id
from service_orders so,circuits ci
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and so.SERO_ID = p_sero_id;

select soa.SEOA_DEFAULTVALUE 
into v_bearer_name
from service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';

select ci.CIRT_NAME
into v_bearer_cct_id
from circuits ci
where ci.CIRT_DISPLAYNAME like v_bearer_name || '%'
and ci.CIRT_SERT_ABBREVIATION = 'AB-FTTH'
and ci.CIRT_STATUS in ('PROPOSED','COMMISSIONED','INSERVICE');

select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
into v_pon_eq_id,v_pon_card_slot,v_pon_port_name,v_pon_port_id
from port_links pl,port_link_ports plp,ports po
where pl.PORL_CIRT_NAME = v_bearer_cct_id
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_NAME = 'PON';
select po.PORT_ID
into v_serv_port_id
from PORT_HIERARCHY ph,ports po
where ph.PORH_PARENTID = v_pon_port_id
and ph.PORH_CHILDID = po.PORT_ID
and po.PORT_NAME = 'LAN 1';

select PORL_ID_SEQ.nextval 
into v_cct_pl_id 
from dual;
INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
VALUES ( v_cct_pl_id , v_circuit_id, '10', 'PHYSICAL', NULL, 'Y');
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
POLP_FRAA_ID ) VALUES ( v_serv_port_id, v_cct_pl_id, 'F', NULL);

select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
into v_msan_eq_id,v_msan_card_slot,v_msan_port_name,v_msan_port_id
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_bearer_cct_id
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and ca.CARD_MODEL like 'GPON%';

select PORT_ID_SEQ.nextval 
into v_masn_vlan_child_id 
from dual;
INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID, PORT_ROOT, PORT_CREATEDBYOBJECTTYPE, PORT_CREATEDBYOBJECTID ) VALUES ( 
v_masn_vlan_child_id, v_msan_eq_id, v_msan_port_name || '.20', v_msan_card_slot, NULL, null, 'SERVICE_SWITCHING_POINT',
 NULL, 'CHILD', NULL, 'INSERVICE'
, 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL); 
INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
 v_msan_port_id, v_masn_vlan_child_id); 
INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
POLP_FRAA_ID, POLP_ALIAS, POLP_NAMING_DOMAIN ) VALUES ( v_masn_vlan_child_id, v_cct_pl_id, 'T', NULL, NULL, NULL);

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

exception  
when others then

P_dynamic_procedure.Process_ISSUE_WORK_ORDER(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);        
v_error := 'Failed to auto create circuit:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, v_error); 
    
end FTTH_INTERNET_CREATION_AUTO;
--- 03-04-2014 Samankula Owitipana
---- Edited 31-12-2014 ----

---- Edited Dinesh 24-02-2016 modify for three IPTV X-connections ----
---- Edited 31-12-2014 ----
--- 03-04-2014 Samankula Owitipana
PROCEDURE FTTH_IPTV_CREATION_AUTO (
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


v_display_name  varchar2(100);
v_circuit_id    varchar2(20);
v_bearer_name   varchar2(100);
v_bearer_cct_id varchar2(20);
v_pon_eq_id     varchar2(20);
v_pon_card_slot varchar2(50);
v_pon_port_name varchar2(50);
v_pon_port_id   varchar2(50);
v_serv_port_id   varchar2(50);
v_msan_eq_id     varchar2(20);
v_msan_card_slot varchar2(50);
v_msan_port_name varchar2(50);
v_msan_port_id   varchar2(50);
v_cct_pl_id      varchar2(50);
v_masn_vlan_child_id varchar2(50);
v_error         varchar2(500);

begin


select SUBSTR(ci.CIRT_DISPLAYNAME,-5,2),ci.CIRT_NAME
into v_display_name,v_circuit_id
from service_orders so,circuits ci
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and so.SERO_ID = p_sero_id;

select soa.SEOA_DEFAULTVALUE 
into v_bearer_name
from service_order_attributes soa
where soa.SEOA_SERO_ID = p_sero_id
and soa.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';  

select ci.CIRT_NAME
into v_bearer_cct_id
from circuits ci
where ci.CIRT_DISPLAYNAME like v_bearer_name || '%'
and ci.CIRT_SERT_ABBREVIATION = 'AB-FTTH'
and ci.CIRT_STATUS in ('PROPOSED','COMMISSIONED','INSERVICE');

    IF v_display_name NOT IN ('_2','_3') THEN  -------- FOR THE FIRST IPTV LINE  ------
    
        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_pon_eq_id,v_pon_card_slot,v_pon_port_name,v_pon_port_id
        from port_links pl,port_link_ports plp,ports po
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_NAME = 'PON';
        select po.PORT_ID
        into v_serv_port_id
        from PORT_HIERARCHY ph,ports po
        where ph.PORH_PARENTID = v_pon_port_id
        and ph.PORH_CHILDID = po.PORT_ID
        and po.PORT_NAME = 'LAN 2';

        select PORL_ID_SEQ.nextval 
        into v_cct_pl_id 
        from dual;
        INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
        VALUES ( v_cct_pl_id , v_circuit_id, '10', 'PHYSICAL', NULL, 'Y');
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_serv_port_id, v_cct_pl_id, 'F', NULL);

        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_msan_eq_id,v_msan_card_slot,v_msan_port_name,v_msan_port_id
        from port_links pl,port_link_ports plp,ports po,cards ca
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_CARD_SLOT = ca.CARD_SLOT
        and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
        and ca.CARD_MODEL like 'GPON%';

        select PORT_ID_SEQ.nextval 
        into v_masn_vlan_child_id 
        from dual;
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        v_masn_vlan_child_id, v_msan_eq_id, v_msan_port_name || '.301', v_msan_card_slot, NULL, null, 
        'SERVICE_SWITCHING_POINT', NULL, 'CHILD', NULL, 'INSERVICE'
        , 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL); 
        INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
         v_msan_port_id, v_masn_vlan_child_id); 
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_masn_vlan_child_id, v_cct_pl_id, 'T', NULL);

    ELSIF v_display_name = '_2' THEN  -------- FOR THE SECOND IPTV LINE  ------
    
        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_pon_eq_id,v_pon_card_slot,v_pon_port_name,v_pon_port_id
        from port_links pl,port_link_ports plp,ports po
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_NAME = 'PON';
        select po.PORT_ID
        into v_serv_port_id
        from PORT_HIERARCHY ph,ports po
        where ph.PORH_PARENTID = v_pon_port_id
        and ph.PORH_CHILDID = po.PORT_ID
        and po.PORT_NAME = 'LAN 3';

        select PORL_ID_SEQ.nextval 
        into v_cct_pl_id 
        from dual;
        INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
        VALUES ( v_cct_pl_id , v_circuit_id, '10', 'PHYSICAL', NULL, 'Y');
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_serv_port_id, v_cct_pl_id, 'F', NULL);

        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_msan_eq_id,v_msan_card_slot,v_msan_port_name,v_msan_port_id
        from port_links pl,port_link_ports plp,ports po,cards ca
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_CARD_SLOT = ca.CARD_SLOT
        and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
        and ca.CARD_MODEL like 'GPON%';

        select PORT_ID_SEQ.nextval 
        into v_masn_vlan_child_id 
        from dual;
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        v_masn_vlan_child_id, v_msan_eq_id, v_msan_port_name || '.302', v_msan_card_slot, NULL, null, 
        'SERVICE_SWITCHING_POINT', NULL, 'CHILD', NULL, 'INSERVICE'
        , 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL); 
        INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
         v_msan_port_id, v_masn_vlan_child_id); 
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_masn_vlan_child_id, v_cct_pl_id, 'T', NULL);
    
    ELSIF v_display_name = '_3' THEN  -------- FOR THE THIRD IPTV LINE  ------
    
        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_pon_eq_id,v_pon_card_slot,v_pon_port_name,v_pon_port_id
        from port_links pl,port_link_ports plp,ports po
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_NAME = 'PON';
        select po.PORT_ID
        into v_serv_port_id
        from PORT_HIERARCHY ph,ports po
        where ph.PORH_PARENTID = v_pon_port_id
        and ph.PORH_CHILDID = po.PORT_ID
        and po.PORT_NAME = 'LAN 4';

        select PORL_ID_SEQ.nextval 
        into v_cct_pl_id 
        from dual;
        INSERT INTO PORT_LINKS ( PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL )
        VALUES ( v_cct_pl_id , v_circuit_id, '10', 'PHYSICAL', NULL, 'Y');
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_serv_port_id, v_cct_pl_id, 'F', NULL);

        select po.PORT_EQUP_ID,po.PORT_CARD_SLOT,po.PORT_NAME,po.PORT_ID
        into v_msan_eq_id,v_msan_card_slot,v_msan_port_name,v_msan_port_id
        from port_links pl,port_link_ports plp,ports po,cards ca
        where pl.PORL_CIRT_NAME = v_bearer_cct_id
        and pl.PORL_ID = plp.POLP_PORL_ID
        and plp.POLP_PORT_ID = po.PORT_ID
        and po.PORT_CARD_SLOT = ca.CARD_SLOT
        and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
        and ca.CARD_MODEL like 'GPON%';

        select PORT_ID_SEQ.nextval 
        into v_masn_vlan_child_id 
        from dual;
        INSERT INTO PORTS ( PORT_ID, PORT_EQUP_ID, PORT_NAME, PORT_CARD_SLOT, PORT_ALARMNAME,
        PORT_CIRT_NAME, PORT_USAGE, PORT_PORC_ABBREVIATION, PORT_RELATION, PORT_LOCN_TTNAME, PORT_STATUS,
        PORT_DISPLAYED, PORT_PHYSICAL, PORT_SPED_ABBREVIATION, PORT_DYNAMIC, PORT_OLD_STATUS, PORT_PHYC_ID,
        PORT_CACE_ID, PORT_NAMEGROUPID, PORT_NUMB_ID ) VALUES ( 
        v_masn_vlan_child_id, v_msan_eq_id, v_msan_port_name || '.303', v_msan_card_slot, NULL, null, 
        'SERVICE_SWITCHING_POINT', NULL, 'CHILD', NULL, 'INSERVICE'
        , 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL); 
        INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( 
         v_msan_port_id, v_masn_vlan_child_id); 
        INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,
        POLP_FRAA_ID ) VALUES ( v_masn_vlan_child_id, v_cct_pl_id, 'T', NULL);
     
    END IF;
       
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

exception  
when others then

P_dynamic_procedure.Process_ISSUE_WORK_ORDER(
        p_serv_id,
        p_sero_id,
        p_seit_id,
        p_impt_taskname,
        p_woro_id,
        p_ret_char,
        p_ret_number,
        p_ret_msg);        
v_error := 'Failed to auto create circuit:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
, v_error); 
    
end FTTH_IPTV_CREATION_AUTO;
--- 03-04-2014 Samankula Owitipana
---- Edited 31-12-2014 ----
---- Edited Dinesh 24-02-2016 ----

---- Dinesh edited to have second VOICE line  16-06-2015-----
---- Edited 31-12-2014 ----
--- 03-04-2014 Samankula Owitipana
PROCEDURE FTTH_VOICE_CREATION_AUTO (
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

V_DISPLAY_NAME          VARCHAR2(100);
V_CIRCUIT_ID            VARCHAR2(20);
V_VOICE_TYPE            VARCHAR2(100);
V_BEARER_NAME           VARCHAR2(100);
V_BEARER_CCT_ID         VARCHAR2(20);
V_PON_EQ_ID             VARCHAR2(20);
V_PON_CARD_SLOT         VARCHAR2(50);
V_PON_PORT_NAME         VARCHAR2(50);
V_PON_PORT_ID           VARCHAR2(50);
V_SERV_PORT_ID          VARCHAR2(50);
V_CCT_PL_ID             VARCHAR2(50);
V_MSAN_EQ_ID            VARCHAR2(20);
V_MSAN_CARD_SLOT        VARCHAR2(50);
V_MSAN_PORT_NAME        VARCHAR2(50);
V_MSAN_PORT_ID          VARCHAR2(50);
V_MASN_VLAN_CHILD_ID    VARCHAR2(50);
V_ERROR                 VARCHAR2(500);

CURSOR GET_DSPLY_NAME (IN_P_SERO_ID VARCHAR2 ) IS
SELECT CI.CIRT_DISPLAYNAME,CI.CIRT_NAME
FROM SERVICE_ORDERS SO,CIRCUITS CI
WHERE SO.SERO_CIRT_NAME = CI.CIRT_NAME
AND SO.SERO_ID = IN_P_SERO_ID;

CURSOR GET_VOICE_TYPE (I_P_SERO_ID VARCHAR2 ) IS
SELECT SOA.SEOA_DEFAULTVALUE
FROM SERVICE_ORDERS SO,SERVICE_ORDER_ATTRIBUTES SOA
WHERE SO.SERO_ID = SOA.SEOA_SERO_ID
AND SEOA_NAME = 'VOICE TYPE'
AND SO.SERO_ID = I_P_SERO_ID;

CURSOR GET_BEARER_NAME (V_P_SERO_ID VARCHAR2 ) IS
SELECT SOA.SEOA_DEFAULTVALUE 
FROM SERVICE_ORDER_ATTRIBUTES SOA
WHERE SOA.SEOA_SERO_ID = V_P_SERO_ID
AND SOA.SEOA_NAME = 'ACCESS PIPE IDENTIFIER';

CURSOR GET_BEARER_ID (V_BEARER_NAME VARCHAR2 ) IS
SELECT CI.CIRT_NAME
FROM CIRCUITS CI
WHERE CI.CIRT_DISPLAYNAME LIKE V_BEARER_NAME || '%'
AND CI.CIRT_SERT_ABBREVIATION = 'AB-FTTH'
AND CI.CIRT_STATUS IN ('PROPOSED','COMMISSIONED','INSERVICE');

CURSOR GET_ORT_INFO ( V_BEARER_CCT_ID VARCHAR2 ) IS
SELECT PO.PORT_EQUP_ID,PO.PORT_CARD_SLOT,PO.PORT_NAME,PO.PORT_ID
FROM PORT_LINKS PL,PORT_LINK_PORTS PLP,PORTS PO
WHERE PL.PORL_CIRT_NAME = V_BEARER_CCT_ID
AND PL.PORL_ID = PLP.POLP_PORL_ID
AND PLP.POLP_PORT_ID = PO.PORT_ID
AND PO.PORT_NAME = 'PON';

CURSOR GET_PORT_ID (V_PON_PORT_ID VARCHAR2, PTO_IN VARCHAR2 ) IS
SELECT PO.PORT_ID
FROM PORT_HIERARCHY PH,PORTS PO
WHERE PH.PORH_PARENTID = V_PON_PORT_ID
AND PH.PORH_CHILDID = PO.PORT_ID
AND PO.PORT_NAME = PTO_IN;

CURSOR GET_SEQ_NXT_VAL IS
SELECT PORL_ID_SEQ.NEXTVAL FROM DUAL;

CURSOR GET_MANS_INFO (V_BEARER_CTT_ID VARCHAR2 ) IS
SELECT PO.PORT_EQUP_ID,PO.PORT_CARD_SLOT,PO.PORT_NAME,PO.PORT_ID
FROM PORT_LINKS PL,PORT_LINK_PORTS PLP,PORTS PO,CARDS CA
WHERE PL.PORL_CIRT_NAME = V_BEARER_CTT_ID
AND PL.PORL_ID = PLP.POLP_PORL_ID
AND PLP.POLP_PORT_ID = PO.PORT_ID
AND PO.PORT_CARD_SLOT = CA.CARD_SLOT
AND PO.PORT_EQUP_ID = CA.CARD_EQUP_ID
AND CA.CARD_MODEL LIKE 'GPON%';

BEGIN

OPEN GET_DSPLY_NAME(P_SERO_ID);
FETCH GET_DSPLY_NAME INTO V_DISPLAY_NAME,V_CIRCUIT_ID;
CLOSE GET_DSPLY_NAME;


OPEN GET_VOICE_TYPE(P_SERO_ID);
FETCH GET_VOICE_TYPE INTO V_VOICE_TYPE;
CLOSE GET_VOICE_TYPE;

OPEN GET_BEARER_NAME(P_SERO_ID);
FETCH GET_BEARER_NAME INTO V_BEARER_NAME;
CLOSE GET_BEARER_NAME;

OPEN GET_BEARER_ID(V_BEARER_NAME);
FETCH GET_BEARER_ID INTO V_BEARER_CCT_ID;
CLOSE GET_BEARER_ID;

OPEN GET_ORT_INFO(V_BEARER_CCT_ID);
FETCH GET_ORT_INFO INTO V_PON_EQ_ID, V_PON_CARD_SLOT, V_PON_PORT_NAME, V_PON_PORT_ID;
CLOSE GET_ORT_INFO;

OPEN GET_SEQ_NXT_VAL;
FETCH GET_SEQ_NXT_VAL INTO V_CCT_PL_ID;
CLOSE GET_SEQ_NXT_VAL;


INSERT INTO PORT_LINKS (PORL_ID, PORL_CIRT_NAME, PORL_SEQUENCE, PORL_LINT_ABBREVIATION,PORL_DETAILS, PORL_EXTERNAL)
VALUES (V_CCT_PL_ID ,V_CIRCUIT_ID, '10', 'PHYSICAL', NULL, 'Y');

OPEN GET_MANS_INFO (V_BEARER_CCT_ID);
FETCH GET_MANS_INFO INTO V_MSAN_EQ_ID,V_MSAN_CARD_SLOT,V_MSAN_PORT_NAME,V_MSAN_PORT_ID;
CLOSE GET_MANS_INFO;

IF V_VOICE_TYPE = 'PRIMARY' THEN

OPEN GET_PORT_ID (V_PON_PORT_ID,'POT 1');
FETCH GET_PORT_ID INTO V_SERV_PORT_ID;
CLOSE GET_PORT_ID;

INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID, POLP_ALIAS, POLP_NAMING_DOMAIN) 
VALUES ( V_SERV_PORT_ID, V_CCT_PL_ID, 'F', NULL, NULL, NULL);


SELECT PORT_ID_SEQ.NEXTVAL  INTO V_MASN_VLAN_CHILD_ID FROM DUAL;

INSERT INTO PORTS 
( PORT_ID,PORT_EQUP_ID,PORT_NAME,PORT_CARD_SLOT,PORT_ALARMNAME,PORT_CIRT_NAME,PORT_USAGE,PORT_PORC_ABBREVIATION,PORT_RELATION, 
PORT_LOCN_TTNAME,PORT_STATUS,PORT_DISPLAYED,PORT_PHYSICAL,PORT_SPED_ABBREVIATION,PORT_DYNAMIC,PORT_OLD_STATUS,PORT_PHYC_ID,
PORT_CACE_ID,PORT_NAMEGROUPID,PORT_NUMB_ID, PORT_ROOT, PORT_CREATEDBYOBJECTTYPE, PORT_CREATEDBYOBJECTID) 
VALUES 
( V_MASN_VLAN_CHILD_ID,V_MSAN_EQ_ID,V_MSAN_PORT_NAME || '.101',V_MSAN_CARD_SLOT,NULL,NULL,'SERVICE_SWITCHING_POINT',NULL, 
'CHILD',NULL,'INSERVICE','Y','Y',NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
 
INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES (  V_MSAN_PORT_ID, V_MASN_VLAN_CHILD_ID); 
 
INSERT INTO PORT_LINK_PORTS 
( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID, POLP_ALIAS, POLP_NAMING_DOMAIN ) 
VALUES ( V_MASN_VLAN_CHILD_ID, V_CCT_PL_ID, 'T', NULL, NULL, NULL);

ELSIF V_VOICE_TYPE = 'SECONDARY' THEN

OPEN GET_PORT_ID (V_PON_PORT_ID,'POT 2');
FETCH GET_PORT_ID INTO V_SERV_PORT_ID;
CLOSE GET_PORT_ID;

INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID, POLP_ALIAS, POLP_NAMING_DOMAIN) 
VALUES ( V_SERV_PORT_ID, V_CCT_PL_ID, 'F', NULL, NULL, NULL);


SELECT PORT_ID_SEQ.NEXTVAL  INTO V_MASN_VLAN_CHILD_ID FROM DUAL;  
 
INSERT INTO PORTS 
( PORT_ID,PORT_EQUP_ID,PORT_NAME,PORT_CARD_SLOT,PORT_ALARMNAME,PORT_CIRT_NAME,PORT_USAGE,PORT_PORC_ABBREVIATION,PORT_RELATION, 
PORT_LOCN_TTNAME,PORT_STATUS,PORT_DISPLAYED,PORT_PHYSICAL,PORT_SPED_ABBREVIATION,PORT_DYNAMIC,PORT_OLD_STATUS,PORT_PHYC_ID,
PORT_CACE_ID,PORT_NAMEGROUPID,PORT_NUMB_ID )
 VALUES 
( V_MASN_VLAN_CHILD_ID,V_MSAN_EQ_ID,V_MSAN_PORT_NAME || '.102',V_MSAN_CARD_SLOT,NULL,NULL,'SERVICE_SWITCHING_POINT',NULL, 
'CHILD',NULL,'INSERVICE','Y','Y',NULL,NULL,NULL,NULL,NULL,NULL,NULL); 

INSERT INTO PORT_HIERARCHY ( PORH_PARENTID, PORH_CHILDID ) VALUES ( V_MSAN_PORT_ID, V_MASN_VLAN_CHILD_ID); 

INSERT INTO PORT_LINK_PORTS ( POLP_PORT_ID, POLP_PORL_ID, POLP_COMMONPORT,POLP_FRAA_ID, POLP_ALIAS, POLP_NAMING_DOMAIN ) 
VALUES ( V_MASN_VLAN_CHILD_ID, V_CCT_PL_ID, 'T', NULL, NULL, NULL);

END IF;

P_IMPLEMENTATION_TASKS.UPDATE_TASK_STATUS_BYID(P_SERO_ID,0, P_SEIT_ID,'COMPLETED');

EXCEPTION WHEN OTHERS THEN
 
P_DYNAMIC_PROCEDURE.PROCESS_ISSUE_WORK_ORDER(
        P_SERV_ID, P_SERO_ID, P_SEIT_ID, P_IMPT_TASKNAME, P_WORO_ID, P_RET_CHAR, P_RET_NUMBER, P_RET_MSG);    
            
V_ERROR := 'Failed to auto create circuit:' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,SETC_TEXT ) 
VALUES ( P_SEIT_ID, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE, V_ERROR); 
    
end FTTH_VOICE_CREATION_AUTO;
-- 03-04-2014 Samankula Owitipana
---- Edited 31-12-2014 ----
---- Dinesh edited to have second VOICE line  16-06-2015-----

--- 26-03-2014 Janaka -----
PROCEDURE SLT_CHK_FET_INTERNET (
      p_serv_id            IN     Services.serv_id%type,
      p_sero_id            IN     Service_Orders.sero_id%type,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%type,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%type,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              out varchar2,
      p_ret_number            OUT number,
      p_ret_msg               OUT Varchar2)   IS

v_isvalid varchar(1);

BEGIN

    SELECT 'Y' into v_isvalid FROM SERVICE_ORDER_FEATURES WHERE SOFE_SERO_ID = p_sero_id
    AND SOFE_FEATURE_NAME = 'INTERNET';

    IF v_isvalid='Y' THEN
    
    p_ret_msg := '';
    
    ELSE 
     p_ret_msg := 'FALSE';
     
    END IF;
    
EXCEPTION
WHEN NO_DATA_FOUND THEN
   p_ret_msg := 'FALSE';
WHEN OTHERS THEN
   p_ret_msg := '';
END SLT_CHK_FET_INTERNET;

--- 26-03-2014 Janaka -----

-- 07-04-2014 Samankula Owitipana

PROCEDURE PSTN_DEL_SAME_NUM_HIERARCHY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_pstn_cct_id    VARCHAR2(25);
v_order_type     VARCHAR2(25);

BEGIN

select so.SERO_ORDT_TYPE,so.SERO_CIRT_NAME
into v_order_type,v_pstn_cct_id
from service_orders so
where so.SERO_ID = p_sero_id;

DELETE FROM CIRCUIT_HIERARCHY ch
WHERE ch.CIRH_PARENT = v_pstn_cct_id
AND ch.CIRH_CHILD = v_pstn_cct_id;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed to delete Circuit hierarchy.' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END PSTN_DEL_SAME_NUM_HIERARCHY;

-- 07-04-2014 Samankula Owitipana

-- Jayan Liyanage  2014/01/07  ACC. INTF PORT BW-A END and ACC. INTF PORT BW-B END added on 08/05/2014 updated on 07/03/2016
PROCEDURE D_EDL_MODFY_SPE_ATT_CP (
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

CURSOR bearer_c IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-B END'AND so.sero_id = p_sero_id;
CURSOR bearer_d IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-A END'AND so.sero_id = p_sero_id;
CURSOR so_copyattr (v_new_bearer_id VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS',
'ADD. NTU MODEL','NTU ROUTING MODE','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL','CUSTOMER INTF TYPE',
'VLAN TAGGED/UNTAGGED ?')AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id);

CURSOR so_copyattr_c (v_new_bearer_id_b VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS',
'ADD. NTU MODEL','NTU ROUTING MODE','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL'
,'CUSTOMER INTF TYPE','VLAN TAGGED/UNTAGGED ?')
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id_b);

v_so_attr_name     VARCHAR2 (100);
v_so_attr_val      VARCHAR2 (100);
v_bearer_id        VARCHAR2 (100);
v_cir_status       VARCHAR2 (100);
v_new_bearer_id    VARCHAR2 (100);
v_service_type     VARCHAR2 (100);
v_service_order    VARCHAR2 (100);
v_new_service_type VARCHAR2 (100);
v_new_bearer_id_b  VARCHAR2 (100);
v_bearer_id_b      VARCHAR2 (100);
v_so_attr_name_c     VARCHAR2 (100);
v_so_attr_val_c      VARCHAR2 (100);
v_cir_status_c      VARCHAR2 (100);
v_acc_lin_type_A      varchar2(100);
v_acc_lin_type_B     varchar2(100);

BEGIN
  
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_A  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_B  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END'AND so.sero_id = p_sero_id;
OPEN bearer_c;FETCH bearer_c INTO v_bearer_id;
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
OPEN so_copyattr (v_bearer_id);LOOP FETCH so_copyattr
INTO v_so_attr_name, v_so_attr_val, v_cir_status; EXIT WHEN so_copyattr%NOTFOUND;

if (v_acc_lin_type_B = 'DAB' or v_acc_lin_type_B = 'CUSTOMER-DAB') THEN
IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
AND v_so_attr_name = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED' 
AND v_so_attr_name = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-B END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-B END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
AND v_so_attr_name = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. INTF PORT BW-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name = 'VLAN TAGGED/UNTAGGED ?'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = '' 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?-B END';  end if; end if; END LOOP; 

--IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
--THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status WHERE soa.seoa_sero_id = p_sero_id
--AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
--END IF;
 CLOSE so_copyattr;CLOSE bearer_c;OPEN bearer_d;FETCH bearer_d INTO v_bearer_id_b;OPEN so_copyattr_c (v_bearer_id_b);LOOP FETCH so_copyattr_c
INTO v_so_attr_name_c, v_so_attr_val_c, v_cir_status_c; EXIT WHEN so_copyattr_c%NOTFOUND;

if (v_acc_lin_type_A = 'DAB' or v_acc_lin_type_A = 'CUSTOMER-DAB') THEN
IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name_c = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED' 
AND v_so_attr_name_c = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name_c = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-A END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name_c = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-A END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'; 

ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
AND v_so_attr_name_c = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACC. INTF PORT BW-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
AND v_so_attr_name_c = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'VLAN TAGGED/UNTAGGED ?'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' 
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = '' 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL CHANGE?-A END'; 
/*ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'ACC. FIBER AVAILABLE?' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER AVAILABLE?-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'ACC. FIBER CORE NO#' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. FIBER CORE NO#-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED' AND v_so_attr_name_c = 'ACC.FIBER PROJ SO #' 
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC.FIBER PROJ SO #-A END'; */
END IF; END IF;

END LOOP; 
--IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-SPEED'
--THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status_c WHERE soa.seoa_sero_id = p_sero_id
--AND soa.seoa_name = 'ACC. BEARER STATUS-A END'; end if;
CLOSE so_copyattr_c;CLOSE bearer_d;

p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'COMPLETED' );EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change D-EDL Copy Attribute  function. Please check the conditions:'|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);


END D_EDL_MODFY_SPE_ATT_CP;


-- Jayan Liyanage  2014/01/07

-- Jayan Liyanage 2014/01/07 Updated on 17/08/2014

PROCEDURE D_EDL_MODIFY_SPEED (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_acc_nw_a               VARCHAR2 (100);
   v_acc_nw_b               VARCHAR2 (100);
   v_acc_bearer_sta_a       VARCHAR2 (100);
   v_acc_bearer_sta_b       VARCHAR2 (100);
   v_acc_int_bw_a_cur       VARCHAR2 (100);
   v_acc_int_bw_a_pre       VARCHAR2 (100);
   v_acc_int_bw_b_cur       VARCHAR2 (100);
   v_acc_int_bw_b_pre       VARCHAR2 (100);
   v_no_copper_pair_a_cur   VARCHAR2 (100);
   v_no_copper_pair_a_pre   VARCHAR2 (100);
   v_no_copper_pair_b_cur   VARCHAR2 (100);
   v_no_copper_pair_b_pre   VARCHAR2 (100);
   agg_nw_a_end             VARCHAR2 (100);
   agg_nw_b_end             VARCHAR2 (100);
   v_service_order_area_a   VARCHAR2 (100);
   v_rtom_code_aa           VARCHAR2 (100);
   v_lea_code_aa            VARCHAR2 (100);
   v_work_group_a_os        VARCHAR2 (100);
   v_work_group_a_nw        VARCHAR2 (100);
   v_work_group_a_cpe       VARCHAR2 (100);
   v_service_order_area_b   VARCHAR2 (100);
   v_rtom_code_bb           VARCHAR2 (100);
   v_lea_code_bb            VARCHAR2 (100);
   v_work_group_b_os        VARCHAR2 (100);
   v_work_group_b_nw        VARCHAR2 (100);
   v_work_group_b_cpe       VARCHAR2 (100);
   v_ntu_cls_a              VARCHAR2 (100);
   v_ntu_cls_b              VARCHAR2 (100);
   v_ntu_mode_a_cur         VARCHAR2 (100);
   v_ntu_mode_a_pre         VARCHAR2 (100);
   v_ntu_mode_b_cur         VARCHAR2 (100);
   v_ntu_mode_b_pre         VARCHAR2 (100);
   v_ntu_ty_a               VARCHAR2 (100);
   v_ntu_ty_b               VARCHAR2 (100);
   v_cpe_cl_a_cur           VARCHAR2 (100);
   v_cpe_cl_a_pre           VARCHAR2 (100);
   v_cpe_cl_b_cur           VARCHAR2 (100);
   v_cpe_cl_b_pre           VARCHAR2 (100);
   v_cpe_mod_a_cur          VARCHAR2 (100);
   v_cpe_mod_a_pre          VARCHAR2 (100);
   v_cpe_mod_b_cur          VARCHAR2 (100);
   v_cpe_mod_b_pre          VARCHAR2 (100);
   v_sec_hand               VARCHAR2 (100);
   v_ser_ctg                VARCHAR2 (100);
   v_acc_po_chg_a           VARCHAR2 (100);
   v_acc_po_chg_b           VARCHAR2 (100);
   v_acc_lin_type_A         VARCHAR2 (100);
   v_acc_lin_type_B         VARCHAR2 (100);
   v_service_type           VARCHAR2 (100);
   v_service_order          VARCHAR2 (100);
   v_tx_wg_b                VARCHAR2 (100);
   v_ser_cteg               VARCHAR2 (100);
BEGIN
   SELECT DISTINCT SO.SERO_SERT_ABBREVIATION, SO.SERO_ORDT_TYPE
     INTO v_service_type, v_service_order
     FROM service_orders SO
    WHERE SO.SERO_ID = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_lin_type_A
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACCESS LINK TYPE-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_lin_type_B
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACCESS LINK TYPE-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_nw_a
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACCESS N/W INTF-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_nw_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACCESS N/W INTF-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_bearer_sta_a
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. BEARER STATUS-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_bearer_sta_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. BEARER STATUS-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_int_bw_a_cur, v_acc_int_bw_a_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. INTF PORT BW-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_acc_int_bw_b_cur, v_acc_int_bw_b_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. INTF PORT BW-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_no_copper_pair_a_cur, v_no_copper_pair_a_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_no_copper_pair_b_cur, v_no_copper_pair_b_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO agg_nw_a_end
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'AGG. NETWORK-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO agg_nw_b_end
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'AGG. NETWORK-B END'
          AND so.sero_id = p_sero_id;

   SELECT soa.seoa_defaultvalue
     INTO v_service_order_area_a
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes_a,
          ar.area_code
     INTO v_rtom_code_aa, v_lea_code_aa
     FROM areas ar
    WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group_a_os
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_a_nw
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'ENG-NW' || '%';

   SELECT wg.worg_name
     INTO v_work_group_a_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'CPE-NC' || '%';

   SELECT soa.seoa_defaultvalue
     INTO v_service_order_area_b
     FROM service_order_attributes soa
    WHERE     soa.seoa_sero_id = p_sero_id
          AND soa.seoa_name = 'EXCHANGE_AREA_CODE';

   SELECT SUBSTR (ar.area_area_code,
                  3,
                  INSTR (ar.area_area_code, '-', 1) + 1)
             AS codes_a,
          ar.area_code
     INTO v_rtom_code_bb, v_lea_code_bb
     FROM areas ar
    WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';

   SELECT wg.worg_name
     INTO v_work_group_b_os
     FROM work_groups wg
    WHERE worg_name LIKE
             v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC' || '%';

   SELECT wg.worg_name
     INTO v_work_group_b_nw
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'ENG-NW' || '%';

   SELECT wg.worg_name
     INTO v_work_group_b_cpe
     FROM work_groups wg
    WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'CPE-NC' || '%';

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ntu_cls_a
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU CLASS-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ntu_cls_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU CLASS-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_ntu_mode_a_cur, v_ntu_mode_a_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU MODEL-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_ntu_mode_b_cur, v_ntu_mode_b_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU MODEL-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ntu_ty_a
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU TYPE-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ntu_ty_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'NTU TYPE-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_cl_a_cur, v_cpe_cl_a_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'CPE CLASS-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_cl_b_cur, v_cpe_cl_b_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'CPE CLASS-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_mod_a_cur, v_cpe_mod_a_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'CPE MODEL-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue, soa.seoa_prev_value
     INTO v_cpe_mod_b_cur, v_cpe_mod_b_pre
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'CPE MODEL-A END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_sec_hand
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'SECTION HANDLED BY'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ser_ctg
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'SERVICE CATEGORY'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_po_chg_a
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. NW PORT CHANGE-A END?'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_acc_po_chg_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'ACC. NW PORT CHANGE-B END?'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_tx_wg_b
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'TX WORK GROUP-B END'
          AND so.sero_id = p_sero_id;

   SELECT DISTINCT soa.seoa_defaultvalue
     INTO v_ser_cteg
     FROM service_orders so, service_order_attributes soa
    WHERE     so.sero_id = soa.seoa_sero_id
          AND soa.seoa_name = 'SERVICE CATEGORY'
          AND so.sero_id = p_sero_id;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'MSAN PORT' OR v_acc_nw_a = 'DSLAM PORT')
      AND v_acc_bearer_sta_a = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_b = 'MSAN PORT' OR v_acc_nw_b = 'DSLAM PORT')
      AND v_acc_bearer_sta_a = 'INSERVICE'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY NTU-B END';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'MLLN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY MLLN PORT-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY MLLN PORT-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'MLLN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY MLLN PORT-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'VERIFY MLLN PORT-B';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'SDH PORT' OR v_acc_nw_a = 'OTN PORT')
      AND (   (v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre)
           OR (v_acc_nw_b = 'SDH PORT' OR v_acc_nw_b = 'OTN PORT'))
      AND v_acc_int_bw_b_cur <> v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'OPR-NETMGT-TX'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE NEW TX PORTS';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RESERVE NEW TX PORTS';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'SDH PORT' OR v_acc_nw_a = 'OTN PORT')
      AND (   (v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre)
           OR (v_acc_nw_b = 'SDH PORT' OR v_acc_nw_b = 'OTN PORT'))
      AND v_acc_int_bw_b_cur <> v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = ''
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'UPDATE TX PATH';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'UPDATE TX PATH';
   END IF;

   IF        v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (   (v_no_copper_pair_a_cur <> v_no_copper_pair_a_pre)
              OR (v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre))
      OR (   (v_no_copper_pair_b_cur <> v_no_copper_pair_b_pre)
          OR (v_acc_int_bw_b_cur <> v_acc_int_bw_b_pre))
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'CORP-SSU'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REDESIGN CIRCUIT';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'REDESIGN CIRCUIT';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'MSAN PORT' OR v_acc_nw_a = 'DSLAM PORT')
      AND v_no_copper_pair_a_cur > v_no_copper_pair_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT.ADD.SHDSL PORT-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT.ADD.SHDSL PORT-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_b = 'MSAN PORT' OR v_acc_nw_b = 'DSLAM PORT')
      AND v_no_copper_pair_b_cur > v_no_copper_pair_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT.ADD.SHDSL PORT-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACT.ADD.SHDSL PORT-B';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'MSAN PORT' OR v_acc_nw_a = 'DSLAM PORT')
      AND v_no_copper_pair_a_cur < v_no_copper_pair_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD SHDSL PO-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD SHDSL PO-A';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_b = 'MSAN PORT' OR v_acc_nw_b = 'DSLAM PORT')
      AND v_no_copper_pair_b_cur < v_no_copper_pair_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD SHDSL PO-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'DEACT ADD SHDSL PO-B';
   END IF;

   IF        v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (agg_nw_b_end = 'MEN' AND v_acc_nw_b <> 'MEN PORT')
      OR (agg_nw_a_end = 'MEN' AND v_acc_nw_a <> 'MEN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN VLAN';
   END IF;

   IF        v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (agg_nw_b_end = 'CEN' AND v_acc_nw_b <> 'CEN PORT')
      OR (agg_nw_a_end = 'CEN' AND v_acc_nw_a <> 'CEN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN VLAN';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN VLAN';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'MEN PORT'
      AND v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE MEN PORT-A ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE MEN PORT-A ND';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'MEN PORT'
      AND v_acc_int_bw_b_cur <> v_acc_int_bw_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE MEN PORT-B ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE MEN PORT-B ND';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'CEN PORT'
      AND v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE CEN PORT-A ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE CEN PORT-A ND';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'CEN PORT'
      AND v_acc_int_bw_b_cur <> v_acc_int_bw_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE CEN PORT-B ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CHANGE CEN PORT-B ND';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'MEN PORT'
      AND v_acc_int_bw_a_cur = v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN PORT-A ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN PORT-A ND';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'MEN PORT'
      AND v_acc_int_bw_b_cur = v_acc_int_bw_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN PORT-B ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MEN PORT-B ND';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'CEN PORT'
      AND v_acc_int_bw_a_cur = v_acc_int_bw_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN PORT-A ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN PORT-A ND';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'CEN PORT'
      AND v_acc_int_bw_b_cur = v_acc_int_bw_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN PORT-B ND';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CEN PORT-B ND';
   END IF;


   IF        v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (    (v_acc_nw_a = 'SDH PORT' OR v_acc_nw_a = 'OTN PORT')
              AND (v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre))
      OR (    (v_acc_nw_b = 'SDH PORT' OR v_acc_nw_b = 'OTN PORT')
          AND (v_acc_int_bw_b_cur <> v_acc_int_bw_b_pre))
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'SFC-TX-DOM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TX LINK';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TX LINK';
   END IF;


   IF        v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (    (v_acc_nw_a = 'SDH PORT' OR v_acc_nw_a = 'OTN PORT')
              AND (v_acc_int_bw_a_cur <> v_acc_int_bw_a_pre))
      OR (    (v_acc_nw_b = 'SDH PORT' OR v_acc_nw_b = 'OTN PORT')
          AND (v_acc_int_bw_b_cur <> v_acc_int_bw_b_pre))
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'SFC-TX-DOM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE NEW TX PATH';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'ACTIVATE NEW TX PATH';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_a = 'MLLN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MLLN PORT-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MLLN PORT-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_nw_b = 'MLLN PORT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MLLN PORT-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY MLLN PORT-B';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_a = 'MSAN PORT' OR v_acc_nw_a = 'MSAN PORT')
      AND v_no_copper_pair_a_cur = v_no_copper_pair_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB PORT-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB PORT-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (v_acc_nw_b = 'MSAN PORT' OR v_acc_nw_b = 'MSAN PORT')
      AND v_no_copper_pair_b_cur = v_no_copper_pair_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-OPR-NM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB PORT-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY TRIB PORT-B';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_no_copper_pair_a_cur > v_no_copper_pair_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_a_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST ADD.OSP LINE-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST ADD.OSP LINE-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_no_copper_pair_b_cur > v_no_copper_pair_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_a_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST ADD.OSP LINE-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONST ADD.OSP LINE-B';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ntu_cls_a = 'SLT'
      AND v_ntu_mode_a_cur <> v_ntu_mode_a_pre
      AND (v_ntu_ty_a = 'SHDSL ROUTER' OR v_ntu_ty_a = 'DSU')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_a_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY NTU-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY NTU-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ntu_cls_b = 'SLT'
      AND v_ntu_mode_b_cur <> v_ntu_mode_b_pre
      AND (v_ntu_ty_b = 'SHDSL ROUTER' OR v_ntu_ty_b = 'DSU')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_a_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY NTU-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY NTU-B END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ntu_cls_a = 'SLT'
      AND v_ntu_mode_a_cur = v_ntu_mode_a_pre
      AND (v_ntu_ty_a = 'SHDSL ROUTER' OR v_ntu_ty_a = 'DSU')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG NTU-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG NTU-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ntu_cls_b = 'SLT'
      AND v_ntu_mode_b_cur = v_ntu_mode_b_pre
      AND (v_ntu_ty_b = 'SHDSL ROUTER' OR v_ntu_ty_b = 'DSU')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG NTU-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG NTU-B END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_a_cur = 'SLT'
      AND v_cpe_mod_a_cur <> v_cpe_mod_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CPE-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CPE-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_b_cur = 'SLT'
      AND v_cpe_mod_b_cur <> v_cpe_mod_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CPE-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY CPE-B END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_a_cur = 'SLT'
      AND v_cpe_cl_a_pre <> 'SLT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_b_cur = 'SLT'
      AND v_cpe_cl_b_pre <> 'SLT'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'INSTALL CPE-B END';
   END IF;


   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_a_cur = 'SLT'
      AND v_cpe_mod_a_cur = v_cpe_mod_a_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE-A END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE-A END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_cpe_cl_b_cur = 'SLT'
      AND v_cpe_mod_b_cur = v_cpe_mod_b_pre
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE-B END';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'RECONFIG CPE-B END';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_po_chg_a = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_a_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY X CONNECT-A';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY X CONNECT-A';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_acc_po_chg_b = 'YES'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_work_group_b_os
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY X CONNECT-B';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'MODIFY X CONNECT-B';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND (   v_acc_nw_a = 'MSAN PORT'
           OR v_acc_nw_a = 'DSLAM PORT'
           OR v_acc_nw_a = 'MLLN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-CPEI'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   ELSIF     v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (v_acc_nw_a = 'MEN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'DS-MEN'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   ELSIF     v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (v_acc_nw_a = 'CEN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = 'IPNET-PROV'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   ELSIF     v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND (v_acc_nw_a = 'SDH PORT' OR v_acc_nw_a = 'OTN PORT')
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_tx_wg_b
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   ELSIF     v_service_type = 'D-EDL'
         AND v_service_order = 'MODIFY-SPEED'
         AND v_ser_ctg = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_sec_hand || -'ACCM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER';
   END IF;

   IF     v_service_type = 'D-EDL'
      AND v_service_order = 'MODIFY-SPEED'
      AND v_ser_cteg = 'TEST'
   THEN
      UPDATE service_implementation_tasks sit
         SET sit.seit_worg_name = v_sec_hand || '-ACCM'
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   ELSE
      DELETE service_implementation_tasks sit
       WHERE     sit.seit_sero_id = p_sero_id
             AND sit.seit_taskname = 'CONFIRM TEST SERVICE';
   END IF;



   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change  Process function. Please check the conditions:'
         || ' - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;
      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_EDL_MODIFY_SPEED;

-- Jayan Liyanage 2014/01/07

-- Jayan Liyanage 2014/01/07


PROCEDURE BEARER_DSP_UPD_4_EDL_MSP (
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
   v_actual_dsp_date          VARCHAR2 (100);
   bearer_id                  VARCHAR2 (100);
   v_service_od_id            VARCHAR2 (100);
   v_Cir_Status               VARCHAR2 (100);
   v_service_ord_type         VARCHAR2 (100);
   v_new_bearer_id            VARCHAR2 (100);
   v_new_service              VARCHAR2 (100);
   v_service_od_id_bend       VARCHAR2 (100);
   v_Cir_Status_bend          VARCHAR2 (100);
   v_acc_li_type_b            VARCHAR2 (100);
   v_acc_li_type_a            VARCHAR2 (100);
   v_acc_id_a                 VARCHAR2 (100);
   v_acc_id_b                 VARCHAR2 (100);
   v_acc_bear_sts_a           VARCHAR2 (100);
   v_acc_bear_sts_b           VARCHAR2 (100);        

                  
  CURSOR bearer_so (v_new_bearer_id VARCHAR,v_new_service VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service
                      AND ci.cirt_displayname like replace( v_new_bearer_id,'(N)')||'(N)'||'%');
  CURSOR bearer_so_bend (v_new_bearer_id_bend VARCHAR,v_new_service_bend VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_sero_id, c.cirt_status
           FROM service_orders so, service_order_attributes soa, circuits c
          WHERE so.sero_id = soa.seoa_sero_id
            AND so.sero_cirt_name = c.cirt_name
            AND (    c.cirt_status <> 'CANCELLED'
                 AND c.cirt_status <> 'PENDINGDELETE'
                )
            AND so.sero_stas_abbreviation <> 'CANCELLED'
            AND so.sero_ordt_type = v_new_service_bend
            AND so.sero_id IN (
                   SELECT MAX (s.sero_id)
                     FROM service_orders s, circuits ci
                    WHERE s.sero_cirt_name = ci.cirt_name
                      AND s.sero_ordt_type = v_new_service_bend
                      AND ci.cirt_displayname like replace(v_new_bearer_id_bend,'(N)')||'(N)'||'%');       
BEGIN

SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_li_type_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';
IF (v_acc_li_type_a = 'DAB'  ) THEN SELECT  distinct soa.seoa_defaultvalue INTO v_acc_id_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';END IF;
IF (v_acc_li_type_b = 'DAB' ) THEN SELECT  distinct soa.seoa_defaultvalue INTO v_acc_id_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';END IF;
SELECT distinct soa.seoa_defaultvalue INTO v_acc_bear_sts_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-A END';
SELECT distinct soa.seoa_defaultvalue INTO v_acc_bear_sts_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
SELECT DISTINCT so.sero_ordt_type INTO v_service_ord_type FROM service_orders so WHERE so.sero_id = p_sero_id;               
SELECT soa.seoa_defaultvalue INTO v_actual_dsp_date  FROM service_order_attributes soa WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACTUAL_DSP_DATE';
if v_acc_id_a is not null then OPEN bearer_so (v_acc_id_a,v_service_ord_type); FETCH bearer_so
 INTO v_service_od_id,v_Cir_Status; CLOSE bearer_so;end if;
   
if v_acc_id_b is not null then OPEN bearer_so_bend (v_acc_id_b,v_service_ord_type); 
 FETCH bearer_so_bend INTO v_service_od_id_bend,v_Cir_Status_bend; CLOSE bearer_so_bend;end if;
   if v_Cir_Status = 'COMMISSIONED' and  v_acc_li_type_a = 'DAB'   and v_acc_bear_sts_a = 'TO BE MODIFIED' then
   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
    WHERE soa.seoa_sero_id = v_service_od_id
      AND soa.seoa_name = 'ACTUAL_DSP_DATE';
   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
    WHERE sit.seit_taskname = 'ENTER BEARER DSP'
      AND sit.seit_sero_id = v_service_od_id;
      
      Delete service_implementation_tasks sit
      where sit.seit_taskname = 'ACT.ACC BEARER-A END'
      and sit.seit_sero_id = p_sero_id;
      
   ELSIF v_Cir_Status <>  'COMMISSIONED' then
   
         Update Service_Implementation_Tasks sit
         set sit.seit_worg_name = 'SFC-SOM-DATA'
         where sit.seit_taskname = 'ACT.ACC BEARER-A END'
         and sit.seit_sero_id = p_sero_id;
      
   END IF;

   IF v_Cir_Status_bend = 'COMMISSIONED' and  v_acc_li_type_b = 'DAB' 
     and v_acc_bear_sts_b = 'TO BE MODIFIED' then
   
   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = v_actual_dsp_date
                          WHERE soa.seoa_sero_id = v_service_od_id_bend
                            AND soa.seoa_name = 'ACTUAL_DSP_DATE';

   UPDATE service_implementation_tasks sit
      SET sit.seit_stas_abbreviation = 'COMPLETED'
                        WHERE sit.seit_taskname = 'ENTER BEARER DSP'
                          AND sit.seit_sero_id = v_service_od_id_bend;
                          
                          
   Delete service_implementation_tasks sit
      where sit.seit_taskname = 'ACT.ACC BEARER-B END'
      and sit.seit_sero_id = p_sero_id;
      
  ELSIF v_Cir_Status <>  'COMMISSIONED' then
   
         Update Service_Implementation_Tasks sit
         set sit.seit_worg_name = 'SFC-SOM-DATA'
         where sit.seit_taskname = 'ACT.ACC BEARER-B END'
         and sit.seit_sero_id = p_sero_id;
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
            'Failed to Change  DSP mapping  function. Please check the conditions:'
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
                   p_ret_msg
                  );
END BEARER_DSP_UPD_4_EDL_MSP;


-- Jayan Liyanage 2014/01/07

--Indika De Silva 04/05/2014
PROCEDURE MSG_PLANNED_MIGRATION_DATE(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2) IS
BEGIN
     p_ret_char := 'Verify PLANNED MIGRATION DATE...!' ;                                      
EXCEPTION WHEN OTHERS THEN 
      p_ret_msg  := 'Notify function Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;                                    
END MSG_PLANNED_MIGRATION_DATE;

--Indika De Silva 04/05/2014


--- Jayan Liyanage 2014/01/24
   PROCEDURE D_EDL_DELETE_CP_ATT (
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

CURSOR bearer_c IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-B END'AND so.sero_id = p_sero_id;

CURSOR bearer_d IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-A END'AND so.sero_id = p_sero_id;

CURSOR so_copyattr (v_new_bearer_id VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS','ADD. NTU MODEL',
'NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL', 
'CUSTOMER INTF TYPE')

AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id);

CURSOR so_copyattr_c (v_new_bearer_id_b VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS','ADD. NTU MODEL',
'NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL', 
'CUSTOMER INTF TYPE')
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGDELETE')AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id_b);

v_so_attr_name          VARCHAR2 (100);
v_so_attr_val           VARCHAR2 (100);
v_bearer_id             VARCHAR2 (100);
v_cir_status            VARCHAR2 (100);
v_new_bearer_id         VARCHAR2 (100);
v_service_type          VARCHAR2 (100);
v_service_order         VARCHAR2 (100);
v_new_service_type      VARCHAR2 (100);
v_new_bearer_id_b       VARCHAR2 (100);
v_bearer_id_b           VARCHAR2 (100);
v_so_attr_name_c        VARCHAR2 (100);
v_so_attr_val_c         VARCHAR2 (100);
v_cir_status_c          VARCHAR2 (100);
v_acc_lin_type_A        varchar2(100);
v_acc_lin_type_B        varchar2(100);

BEGIN
  
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_A  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_B  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END'AND so.sero_id = p_sero_id;
OPEN bearer_c;FETCH bearer_c INTO v_bearer_id;
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
OPEN so_copyattr (v_bearer_id);LOOP FETCH so_copyattr
INTO v_so_attr_name, v_so_attr_val, v_cir_status; EXIT WHEN so_copyattr%NOTFOUND;



if (v_acc_lin_type_B = 'DAB' or v_acc_lin_type_B = 'CUSTOMER-DAB') THEN
IF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-B END'; ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-B END';ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE' 
AND v_so_attr_name = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-B END'; ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-B END'; ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'DELETE' AND v_so_attr_name = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE'
AND v_so_attr_name = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-B END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'DELETE' AND v_so_attr_name = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' 
AND v_so_attr_name = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE' AND v_so_attr_name = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-B END';
 ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END'; end if; end if; END LOOP; 
IF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
END IF;CLOSE so_copyattr;CLOSE bearer_c;OPEN bearer_d;FETCH bearer_d INTO v_bearer_id_b;OPEN so_copyattr_c (v_bearer_id_b);LOOP FETCH so_copyattr_c
INTO v_so_attr_name_c, v_so_attr_val_c, v_cir_status_c; EXIT WHEN so_copyattr_c%NOTFOUND;

if (v_acc_lin_type_A = 'DAB' or v_acc_lin_type_A = 'CUSTOMER-DAB') THEN
IF    v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name_c = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-A END';ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE' 
AND v_so_attr_name_c = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-A END'; ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name_c = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-A END'; ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE'
AND v_so_attr_name_c = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'NTU ROUTING MODE' 
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-A END';ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name_c = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'; ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE' 
AND v_so_attr_name_c = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
AND v_so_attr_name_c = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'DELETE' AND v_so_attr_name_c = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-A END';
END IF; END IF;END LOOP; 
IF     v_service_type = 'D-EDL' AND v_service_order = 'DELETE'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-A END'; end if;
CLOSE so_copyattr_c;CLOSE bearer_d;

p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'COMPLETED' );EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change D-EDL Copy Attribute in Delete SOD  function. Please check the conditions:'|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);


END D_EDL_DELETE_CP_ATT;
   --- Jayan Liyanage 2014/01/24


--- Jayan Liyanage 2014/01/24
PROCEDURE D_EDL_DELETE (
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



CURSOR cur_tributer (parent_name VARCHAR2,order_Cir  VARCHAR2)IS
SELECT DISTINCT ci.cirt_displayname, ci.cirt_status FROM circuits c, circuit_hierarchy ch, circuits ci
WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name AND (   ci.cirt_status LIKE 'INSERVICE%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')
AND (   ci.cirt_status NOT LIKE 'CANCE%' OR ci.cirt_status NOT LIKE 'PENDING%' )
AND ci.CIRT_DISPLAYNAME <> order_Cir AND c.cirt_displayname = replace(parent_name,'(N)');
CURSOR cur_tributer_(parent_name_b VARCHAR2,order_Cir_b  VARCHAR2)IS
SELECT DISTINCT ci.cirt_displayname, ci.cirt_status FROM circuits c, circuit_hierarchy ch, circuits ci
WHERE c.cirt_name = ch.cirh_parent AND ch.cirh_child = ci.cirt_name AND (   ci.cirt_status LIKE 'INSERVICE%'
OR ci.cirt_status LIKE 'SUSPEND%' OR ci.cirt_status LIKE 'COMMISS%')
AND (   ci.cirt_status NOT LIKE 'CANCE%' OR ci.cirt_status NOT LIKE 'PENDING%' )
AND ci.CIRT_DISPLAYNAME <> order_Cir_b AND c.cirt_displayname = replace(parent_name_b,'(N)');
CURSOR cur_equi_type IS SELECT DISTINCT e.equp_equt_abbreviation
FROM service_orders so, ports p, equipment e WHERE so.sero_cirt_name = p.port_cirt_name
AND p.port_equp_id = e.equp_id AND so.sero_id = p_sero_id;

   v_service_type         VARCHAR2 (100);
   v_service_order        VARCHAR2 (100);
   v_section_hndle        VARCHAR2 (100);
   v_core_network         VARCHAR2 (100);
   v_acc_nw               VARCHAR2 (100);
   v_access_bear_id       VARCHAR2 (100);
   parent_name            VARCHAR2 (100);
   v_ch_parent            VARCHAR2 (100);
   v_ch_dis               VARCHAR2 (100);
   v_cir_trib_status      VARCHAR2 (100);
   v_acc_medium           VARCHAR2 (100);
   v_media_type           VARCHAR2 (100);
   v_equip_type           VARCHAR2 (100);
   v_work_group_mdf       VARCHAR2 (100);
   v_ntu_class            VARCHAR2 (100);
   v_cpe_class            VARCHAR2 (100);
   v_service_order_area   VARCHAR2 (100);
   v_rtom_code            VARCHAR2 (100);
   v_lea_code             VARCHAR2 (100);
   v_work_group           VARCHAR2 (100);
   v_work_group_cpe       VARCHAR2 (100);
   v_new_Cir_Name         VARCHAR2 (100); 
   order_Cir              VARCHAR2 (100); 
   v_aggr_1               VARCHAR2 (100); 
   v_aggr_2               VARCHAR2 (100); 
   v_work_group_EN        VARCHAR2 (100); 
   v_work_group_nw     VARCHAR2 (100);
   
   v_acc_nw_a             VARCHAR2(100);
   v_acc_nw_b             VARCHAR2(100);
   v_aggr_nw_a            VARCHAR2(100);
   v_aggr_nw_b            VARCHAR2(100);     
   v_acc_medium_a         VARCHAR2(100);    
   v_acc_medium_b         VARCHAR2(100);   
   v_acc_link_a           VARCHAR2(100); 
   v_acc_link_b           VARCHAR2(100);  
   exc_area_a             VARCHAR2(100);  
   v_rtom_code_a          VARCHAR2(100);
   v_lea_code_a           VARCHAR2(100); 
   exc_area_b             VARCHAR2(100); 
   v_rtom_code_b          VARCHAR2(100);                         
   v_lea_code_b           VARCHAR2(100); 
   v_work_group_b         VARCHAR2(100); 
   v_cpe_cls_a            VARCHAR2(100);
   v_cpe_cls_b            VARCHAR2(100);
   v_ac_bearer_a        VARCHAR2(100);
    v_ac_bearer_b        VARCHAR2(100);
    v_ch_dis_a              VARCHAR2(100);
   v_ch_dis_b               VARCHAR2(100);
   v_cir_trib_status_a  VARCHAR2(100);
    v_cir_trib_status_b  VARCHAR2(100);  
   
BEGIN
   OPEN cur_equi_type;  FETCH cur_equi_type    INTO v_equip_type;
   CLOSE cur_equi_type;

SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue INTO v_section_hndle FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'SECTION HANDLED BY';
SELECT soa.seoa_defaultvalue INTO v_ac_bearer_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID-A END';
SELECT soa.seoa_defaultvalue INTO v_ac_bearer_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS_ID-B END';
SELECT DISTINCT c.cirt_displayname into v_new_Cir_Name FROM service_orders so,circuits c 
where so.sero_cirt_name = c.cirt_name and  so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_area_code INTO v_service_order_area FROM service_orders so 
WHERE so.sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue INTO exc_area_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';
SELECT soa.seoa_defaultvalue INTO exc_area_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes, ar.area_code INTO v_rtom_code_a, v_lea_code_a 
FROM areas ar WHERE ar.area_code = exc_area_a AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group FROM work_groups wg  
WHERE worg_name LIKE v_rtom_code_a || '-' || v_lea_code_a || '%' || 'OSP-NC' || '%';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1) AS codes, ar.area_code INTO v_rtom_code_b, v_lea_code_b 
FROM areas ar WHERE ar.area_code = exc_area_b AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_b FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code_b || '-' || v_lea_code_b || '%' || 'OSP-NC' || '%';

SELECT soa.seoa_defaultvalue INTO v_acc_nw_a FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-A END';
SELECT soa.seoa_defaultvalue INTO v_acc_nw_b FROM service_order_attributes soa
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-B END';
SELECT soa.seoa_defaultvalue INTO v_aggr_nw_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'AGG. NETWORK-A END';
SELECT soa.seoa_defaultvalue INTO v_aggr_nw_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'AGG. NETWORK-B END';
SELECT soa.seoa_defaultvalue INTO v_acc_medium_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END';
SELECT soa.seoa_defaultvalue INTO v_acc_medium_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END';
SELECT soa.seoa_defaultvalue INTO v_acc_link_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END';
SELECT soa.seoa_defaultvalue INTO v_acc_link_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END';
SELECT soa.seoa_defaultvalue INTO v_cpe_cls_a FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-A END';
SELECT soa.seoa_defaultvalue INTO v_cpe_cls_b FROM service_order_attributes soa 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-B END';
OPEN cur_tributer (v_ac_bearer_a,v_new_Cir_Name);FETCH cur_tributer
INTO v_ch_dis_a, v_cir_trib_status_a;CLOSE cur_tributer;
OPEN cur_tributer_ (v_ac_bearer_b,v_new_Cir_Name);FETCH cur_tributer_
INTO v_ch_dis_b, v_cir_trib_status_b;CLOSE cur_tributer_;

IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_nw_a = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. MLLN PORT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. MLLN PORT-A'; END IF; 
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_nw_b = 'MLLN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. MLLN PORT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. MLLN PORT-B'; END IF;
if  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and (v_acc_nw_a = 'SDH PORT' or v_acc_nw_a = 'OTN PORT') or
  (v_acc_nw_b = 'SDH PORT' or v_acc_nw_b = 'OTN PORT') THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'OPR-NETMGT-TX'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RELEASE TX PORTS';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'RELEASE TX PORTS'; END IF;

IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_aggr_nw_a = 'MEN' and v_acc_nw_a <> 'MEN PORT' )  
  or ( v_aggr_nw_b ='MEN' and v_acc_nw_b <> 'MEN PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACTIVATE MEN VLAN';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE MEN VLAN'; END IF;
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_aggr_nw_a = 'CEN' and v_acc_nw_a <> 'CEN PORT' )  
  or ( v_aggr_nw_b ='CEN' and v_acc_nw_b <> 'CEN PORT')  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACTIVATE CEN VLAN';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE CEN VLAN'; END IF;
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' 
       and v_acc_nw_a = 'MEN PORT' AND v_ch_dis_a is null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. MEN PORT-A ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. MEN PORT-A ND'; END IF;
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' 
       and v_acc_nw_b = 'MEN PORT' AND v_ch_dis_b is null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. MEN PORT-B ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. MEN PORT-B ND'; END IF;
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_nw_a = 'CEN PORT' 
  AND v_ch_dis_a is null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. CEN PORT-A ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. CEN PORT-A ND'; END IF;
IF   v_service_type = 'D-EDL' and v_service_order = 'DELETE' 
       and v_acc_nw_b = 'CEN PORT' AND v_ch_dis_b is null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. CEN PORT-B ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACT. CEN PORT-B ND'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_nw_a = 'MEN PORT' 
  AND v_ch_dis_a is not null  THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOV MEN SUB PORT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOV MEN SUB PORT-A'; END IF;
if v_service_type = 'D-EDL' and v_service_order = 'DELETE'  and v_acc_nw_b = 'MEN PORT' AND v_ch_dis_b is not null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOV MEN SUB PORT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOV MEN SUB PORT-B'; END IF;

IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_nw_a = 'CEN PORT' 
  AND v_ch_dis_a is not null  THEN UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOV CEN SUB PORT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOV CEN SUB PORT-A'; END IF;

IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE'  and v_acc_nw_b = 'CEN PORT' AND v_ch_dis_b is not null  THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOV CEN SUB PORT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'REMOV CEN SUB PORT-B'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and (v_acc_nw_a = 'SDH PORT' or v_acc_nw_a = 'OTN PORT') or 
  (v_acc_nw_b = 'SDH PORT' or v_acc_nw_b = 'OTN PORT') then
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'SFC-TX-DOM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACTIVATE TX LINK';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id
AND sit.seit_taskname = 'DEACTIVATE TX LINK'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_nw_a = 'MSAN PORT' or v_acc_nw_a = 'DSLAM PORT' ) AND v_ch_dis_a is null  THEN 
  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. SHDSL PORT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. SHDSL PORT-A'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_nw_b = 'MSAN PORT' or v_acc_nw_b = 'DSLAM PORT' ) AND v_ch_dis_b is null  THEN 
  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. SHDSL PORT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. SHDSL PORT-B'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_nw_a = 'MSAN PORT' or v_acc_nw_a = 'DSLAM PORT' ) AND v_ch_dis_a is not null  THEN 
  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. TRIB. PORT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. TRIB. PORT-A'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_nw_b = 'MSAN PORT' or v_acc_nw_b = 'DSLAM PORT' ) AND v_ch_dis_b is  not null  THEN 
  UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-OPR-NM'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. TRIB. PORT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. TRIB. PORT-B'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_medium_a = 'COPPER' and v_acc_link_a = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE OSP LINE-A ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE OSP LINE-A ND'; END IF;

IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_medium_b = 'COPPER' and v_acc_link_b = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE OSP LINE-B ND';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE OSP LINE-B ND'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and  v_acc_medium_a = 'COPPER' AND v_acc_link_a = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE  X CONNECT-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE  X CONNECT-A'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_acc_medium_b = 'COPPER' and v_acc_link_b = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_b
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE  X CONNECT-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'REMOVE  X CONNECT-B'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_cpe_cls_a = 'SLT' and v_acc_link_a = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'COLLECT CPE-A END';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'COLLECT CPE-A END'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and v_cpe_cls_b = 'SLT' and v_acc_link_b = 'DEDICATED LINE' then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'COLLECT CPE-B END';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'COLLECT CPE-B END'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_link_a = 'DAB' or v_acc_link_a = 'CUSTOMER-DAB') and v_ch_dis_a is null  then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle ||'-FO'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. ACC BEARER-A';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. ACC BEARER-A'; END IF;
IF  v_service_type = 'D-EDL' and v_service_order = 'DELETE' and ( v_acc_link_b = 'DAB' or v_acc_link_b = 'CUSTOMER-DAB') and v_ch_dis_b is null  then
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_section_hndle ||'-FO'
WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. ACC BEARER-B';
ELSE DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'DEACT. ACC BEARER-B'; END IF;



p_implementation_tasks.update_task_status_byid (p_sero_id,
0,p_seit_id,'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
p_ret_msg :=
'Failed to Change D-EDL Delete Process function. Please check the conditions:'
|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'ERROR');
INSERT INTO service_task_comments
(setc_seit_id, setc_id, setc_userid, setc_timestamp,
setc_text
)
VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,
p_ret_msg
);


END D_EDL_DELETE;
--- Jayan Liyanage 2014/01/24

--- Jayan Liyanage 2014/01/24 updated on 07/03/2016

PROCEDURE D_EDL_MODIFY_OTHERS_CP_ATT (
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

CURSOR bearer_c IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-B END'AND so.sero_id = p_sero_id;

CURSOR bearer_d IS SELECT DISTINCT soa.seoa_defaultvalue FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS BEARER ID-A END'AND so.sero_id = p_sero_id;

CURSOR so_copyattr (v_new_bearer_id VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGMODIFY-OTHERS')
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS','ADD. NTU MODEL',
'NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL', 
'CUSTOMER INTF TYPE','VLAN TAGGED/UNTAGGED ?')
AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id);

CURSOR so_copyattr_c (v_new_bearer_id_b VARCHAR)IS SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
FROM service_orders so, service_order_attributes soa, circuits c WHERE so.sero_id = soa.seoa_sero_id
and soa.seoa_name in ('ACCESS N/W INTF','CPE CLASS','CPE TYPE','CPE MODEL','NTU MODEL','NTU TYPE','NTU CLASS','ADD. NTU MODEL',
'NTU ROUTING MODE','ACCESS MEDIUM','NO OF COPPER PAIRS','ACCESS INTF PORT BW','DATA RADIO MODEL', 
'CUSTOMER INTF TYPE','VLAN TAGGED/UNTAGGED ?')
AND so.sero_cirt_name = c.cirt_name AND (    c.cirt_status <> 'CANCELLED'AND c.cirt_status <> 'PENDINGMODIFY-OTHERS')AND so.sero_stas_abbreviation <> 'CANCELLED'
AND so.sero_id IN (SELECT MAX (s.sero_id)FROM service_orders s, circuits ci WHERE s.sero_cirt_name = ci.cirt_name AND s.sero_stas_abbreviation <> 'CANCELLED'
AND ci.cirt_displayname = v_new_bearer_id_b);

v_so_attr_name          VARCHAR2 (100);
v_so_attr_val           VARCHAR2 (100);
v_bearer_id             VARCHAR2 (100);
v_cir_status            VARCHAR2 (100);
v_new_bearer_id         VARCHAR2 (100);
v_service_type          VARCHAR2 (100);
v_service_order         VARCHAR2 (100);
v_new_service_type      VARCHAR2 (100);
v_new_bearer_id_b       VARCHAR2 (100);
v_bearer_id_b           VARCHAR2 (100);
v_so_attr_name_c        VARCHAR2 (100);
v_so_attr_val_c         VARCHAR2 (100);
v_cir_status_c          VARCHAR2 (100);
v_acc_lin_type_A        varchar2(100);
v_acc_lin_type_B        varchar2(100);

BEGIN
  
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_A  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_B  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END'AND so.sero_id = p_sero_id;
  
OPEN bearer_c;FETCH bearer_c INTO v_bearer_id;
SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type FROM service_orders so WHERE so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type INTO v_service_order FROM service_orders so WHERE so.sero_id = p_sero_id;
OPEN so_copyattr (v_bearer_id);LOOP FETCH so_copyattr
INTO v_so_attr_name, v_so_attr_val, v_cir_status; EXIT WHEN so_copyattr%NOTFOUND;

if (v_acc_lin_type_B = 'DAB' ) THEN IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS' 
AND v_so_attr_name = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-B END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-B END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' 
AND v_so_attr_name = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-B END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-B END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-B END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name = 'VLAN TAGGED/UNTAGGED ?' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-B END'; 
end if; end if; END LOOP; 
/*IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-B END';
END IF;*/
CLOSE so_copyattr;CLOSE bearer_c;OPEN bearer_d;FETCH bearer_d INTO v_bearer_id_b;OPEN so_copyattr_c (v_bearer_id_b);LOOP FETCH so_copyattr_c
INTO v_so_attr_name_c, v_so_attr_val_c, v_cir_status_c; EXIT WHEN so_copyattr_c%NOTFOUND;
if (v_acc_lin_type_A = 'DAB' ) THEN IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'ACCESS N/W INTF'
THEN  UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACCESS N/W INTF-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name_c = 'CPE CLASS' THEN  UPDATE service_order_attributes soa  
SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'CPE TYPE'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'CPE TYPE-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS' 
AND v_so_attr_name_c = 'CPE MODEL' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'NTU MODEL'
THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NTU MODEL-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name_c = 'NTU TYPE' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE-A END'; 
ELSIF     v_service_type = 'D-EDL' 
AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'NTU CLASS' THEN UPDATE service_order_attributes soa
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name_c = 'ADD. NTU MODEL' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ADD. NTU MODEL-A END';
ELSIF     v_service_type = 'D-EDL'
AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'NTU ROUTING MODE' THEN UPDATE service_order_attributes soa 
SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'NTU ROUTING MODE-A END';
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name_c = 'ACCESS MEDIUM' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS MEDIUM-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'NO OF COPPER PAIRS' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c WHERE soa.seoa_sero_id = p_sero_id 
AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS' 
AND v_so_attr_name_c = 'ACCESS INTF PORT BW' THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-A END'; 
ELSIF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
AND v_so_attr_name_c = 'DATA RADIO MODEL'THEN UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'DATA RADIO MODEL-A END';
ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'CUSTOMER INTF TYPE' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CUSTOMER INTF TYPE-A END';

ELSIF     v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS' AND v_so_attr_name_c = 'VLAN TAGGED/UNTAGGED ?' THEN 
UPDATE service_order_attributes soa SET soa.seoa_defaultvalue = v_so_attr_val_c 
WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-A END';
END IF; END IF;

END LOOP; 
/*IF     v_service_type = 'D-EDL' AND v_service_order = 'MODIFY-OTHERS'
THEN UPDATE service_order_attributes soa  SET soa.seoa_defaultvalue = v_cir_status_c WHERE soa.seoa_sero_id = p_sero_id
AND soa.seoa_name = 'ACC. BEARER STATUS-A END'; end if;*/
CLOSE so_copyattr_c;CLOSE bearer_d;

p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'COMPLETED' );EXCEPTION WHEN OTHERS THEN p_ret_msg :=
'Failed to Change D-EDL Copy Attribute in Delete SOD  function. Please check the conditions:'|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'ERROR');INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);


END D_EDL_MODIFY_OTHERS_CP_ATT;

--- Jayan Liyanage 2014/01/24

--- Jayan Liyanage 2014/01/24
PROCEDURE D_EDL_MODIFY_OTHERS (
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

v_acc_lin_type_A           varchar2(100);
v_acc_lin_type_B           varchar2(100);
v_acc_nw_a                 varchar2(100);
v_acc_nw_b                 varchar2(100);
v_acc_bearer_sta_a         varchar2(100);
v_acc_bearer_sta_b         varchar2(100);
v_acc_int_bw_a_cur         varchar2(100);
v_acc_int_bw_a_pre         varchar2(100);
v_acc_int_bw_b_cur         varchar2(100);
v_acc_int_bw_b_pre         varchar2(100);
v_no_copper_pair_a_cur     varchar2(100);
v_no_copper_pair_a_pre     varchar2(100);
v_no_copper_pair_b_cur     varchar2(100);
v_no_copper_pair_b_pre     varchar2(100);
agg_nw_a_end               varchar2(100);
agg_nw_b_end               varchar2(100);
v_qos_tem_cur              varchar2(100);
v_qos_tem_pre              varchar2(100);
v_service_order_area_a     varchar2(100);
v_rtom_code_aa             varchar2(100);
v_lea_code_aa               varchar2(100);
v_work_group_a_os       varchar2(100);
v_work_group_a_nw       varchar2(100);
v_work_group_a_cpe      varchar2(100);
v_service_order_area_b  varchar2(100);
v_rtom_code_bb           varchar2(100);
v_lea_code_bb       varchar2(100);
v_work_group_b_os       varchar2(100);
v_work_group_b_nw       varchar2(100);
v_work_group_b_cpe      varchar2(100);
v_tag_a_cur                     varchar2(100);
v_tag_a_pre                 varchar2(100);
v_tag_b_cur                 varchar2(100);
v_ntu_cls_a                  varchar2(100);
v_ntu_cls_b                  varchar2(100);
v_tag_b_pre                 varchar2(100);
v_ntu_mode_a_cur        varchar2(100);
v_ntu_mode_a_pre        varchar2(100);
v_ntu_mode_b_cur        varchar2(100);
v_ntu_mode_b_pre       varchar2(100);
v_ntu_ty_a                   varchar2(100);
v_ntu_ty_b                   varchar2(100);
v_cpe_cl_a_cur             varchar2(100);
v_cpe_cl_a_pre             varchar2(100);
v_cpe_cl_b_cur             varchar2(100);
v_cpe_cl_b_pre             varchar2(100);
v_cpe_mod_a_cur         varchar2(100);
v_cpe_mod_a_pre         varchar2(100);
v_cpe_mod_b_cur         varchar2(100);
v_cpe_mod_b_pre         varchar2(100);
v_sec_hand                  varchar2(100);
v_ser_ctg                     varchar2(100);
v_acc_po_chg_a          varchar2(100);
v_acc_po_chg_b          varchar2(100);
v_service_type              varchar2(100);
v_service_order              varchar2(100);

begin
  
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_A  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_lin_type_B  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS LINK TYPE-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_nw_a  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_nw_b  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS N/W INTF-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_bearer_sta_a  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_bearer_sta_b  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACC. BEARER STATUS-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_acc_int_bw_a_cur,v_acc_int_bw_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_acc_int_bw_b_cur,v_acc_int_bw_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACCESS INTF PORT BW-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_no_copper_pair_a_cur,v_no_copper_pair_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_no_copper_pair_b_cur,v_no_copper_pair_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NO OF COPPER PAIRS-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO agg_nw_a_end  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'AGG. NETWORK-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO agg_nw_b_end  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'AGG. NETWORK-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_qos_tem_cur,v_qos_tem_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'QOS TEMPLATE'AND so.sero_id = p_sero_id;
SELECT soa.seoa_defaultvalue INTO v_service_order_area_a FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE AREA CODE-A END';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_aa,v_lea_code_aa FROM areas ar WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_a_os FROM work_groups wg WHERE worg_name LIKE v_rtom_code_aa || '-' || v_lea_code_aa || '%' || 'OSP-NC' || '%';                  
SELECT wg.worg_name INTO v_work_group_a_nw FROM work_groups wg WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'ENG-NW' || '%';
SELECT wg.worg_name INTO v_work_group_a_cpe FROM work_groups wg WHERE worg_name LIKE v_rtom_code_aa || '-' || '%' || 'CPE-NC' || '%';
SELECT soa.seoa_defaultvalue INTO v_service_order_area_b FROM service_order_attributes soa WHERE soa.seoa_sero_id =  p_sero_id AND soa.seoa_name = 'EXCHANGE_AREA_CODE';
SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code_bb,v_lea_code_bb FROM areas ar WHERE ar.area_code = v_service_order_area_a AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_b_os FROM work_groups wg WHERE worg_name LIKE v_rtom_code_bb || '-' || v_lea_code_bb || '%' || 'OSP-NC' || '%';                  
SELECT wg.worg_name INTO v_work_group_b_nw FROM work_groups wg WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'ENG-NW' || '%';
SELECT wg.worg_name INTO v_work_group_b_cpe FROM work_groups wg WHERE worg_name LIKE v_rtom_code_bb || '-' || '%' || 'CPE-NC' || '%';
SELECT DISTINCT soa.seoa_defaultvalue INTO v_ntu_cls_a  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU CLASS-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_ntu_cls_b  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU CLASS-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_ntu_mode_a_cur,v_ntu_mode_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU MODEL-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_ntu_mode_b_cur,v_ntu_mode_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU MODEL-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_ntu_ty_a  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU TYPE-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_ntu_ty_b  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'NTU TYPE-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_cpe_cl_a_cur,v_cpe_cl_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'CPE CLASS-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_cpe_cl_b_cur,v_cpe_cl_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'CPE CLASS-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_cpe_mod_a_cur,v_cpe_mod_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'CPE MODEL-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_cpe_mod_b_cur,v_cpe_mod_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'CPE MODEL-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_sec_hand  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'SECTION HANDLED BY'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_ser_ctg  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'SERVICE CATEGORY'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_po_chg_a  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACC. NW PORT CHANGE-A END?'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue INTO v_acc_po_chg_b  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'ACC. NW PORT CHANGE-B END?'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_tag_a_cur,v_tag_a_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-A END'AND so.sero_id = p_sero_id;
SELECT DISTINCT soa.seoa_defaultvalue,soa.seoa_prev_value INTO v_tag_b_cur,v_tag_b_pre  FROM service_orders so, service_order_attributes soa
WHERE so.sero_id = soa.seoa_sero_id AND soa.seoa_name = 'VLAN TAG/UNTAG?-B END'AND so.sero_id = p_sero_id;
SELECT DISTINCT so.sero_ordt_type,so.sero_sert_abbreviation INTO v_service_order,v_service_type FROM service_orders so where  so.sero_id = p_sero_id;


IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_qos_tem_cur <> v_qos_tem_pre and ( (agg_nw_a_end = 'MEN' and v_acc_nw_a <> 'MEN PORT') or 
(agg_nw_b_end = 'MEN' and v_acc_int_bw_b_cur <> 'MEN PORT') )   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN VLAN'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN VLAN'; END IF;  
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_qos_tem_cur <> v_qos_tem_pre and ( (agg_nw_a_end = 'CEN' and v_acc_nw_a <> 'CEN PORT') or 
(agg_nw_b_end = 'CEN' and v_acc_nw_b <> 'CEN PORT') )   THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN VLAN'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN VLAN'; END IF;  
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_acc_nw_a = 'MEN PORT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN PORT-A ND'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN PORT-A ND'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_acc_nw_b = 'MEN PORT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN PORT-B ND'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY MEN PORT-B ND'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_acc_nw_a = 'CEN PORT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN PORT-A ND'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN PORT-A ND'; END IF;

IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_acc_nw_b = 'CEN PORT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_b_cur <> v_tag_b_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN PORT-B ND'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY CEN PORT-B ND'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND (v_acc_nw_a = 'MSAN PORT' or v_acc_nw_a = 'DSLAM PORT' )  and  ( (v_qos_tem_cur <> v_qos_tem_pre) 
or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY SHDSL PORT-A'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY SHDSL PORT-A'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND (v_acc_nw_b = 'MSAN PORT' or v_acc_nw_b = 'DSLAM PORT' )  and  ( (v_qos_tem_cur <> v_qos_tem_pre) 
or (v_tag_b_cur <> v_tag_b_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY SHDSL PORT-B'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'MODIFY SHDSL PORT-B'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND (v_acc_nw_a = 'MSAN PORT' or v_acc_nw_a = 'DSLAM PORT' )  and  ( (v_qos_tem_cur <> v_qos_tem_pre) 
or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-A END'; END IF;

IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND (v_acc_nw_b = 'MSAN PORT' or v_acc_nw_b = 'DSLAM PORT' )  and  ( (v_qos_tem_cur <> v_qos_tem_pre) 
or (v_tag_b_cur <> v_tag_b_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-B END'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_cpe_cl_a_cur = 'SLT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_a_cur <> v_tag_a_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG CPE-A END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG CPE-A END'; END IF;

IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  
AND v_cpe_cl_b_cur = 'SLT'  and  ( (v_qos_tem_cur <> v_qos_tem_pre) or (v_tag_b_cur <> v_tag_b_pre) ) THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-B END'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'RECONFIG NTU-B END'; END IF;
IF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  and (
  v_acc_nw_b = 'MSAN PORT' or v_acc_nw_b = 'DSLAM PORT' or v_acc_nw_b = 'MLLN PORT')then
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  and v_acc_nw_b = 'MEN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-MEN' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSIF    v_service_type = 'D-EDL'AND v_service_order = 'MODIFY-OTHERS'  and v_acc_nw_b = 'CEN PORT' THEN
UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'IPNET-PROV' 
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; 
ELSE DELETE      service_implementation_tasks sit
WHERE sit.seit_sero_id =  p_sero_id AND sit.seit_taskname = 'CONFIRM  W/ CUSTOMER'; END IF;



p_implementation_tasks.update_task_status_byid (p_sero_id,
0,
p_seit_id,
'COMPLETED'
);
EXCEPTION
WHEN OTHERS
THEN
p_ret_msg :=
'Failed to Modified Others SOD Process function. Please check the conditions:'
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
p_ret_msg
);


END D_EDL_MODIFY_OTHERS;

--- Jayan Liyanage 2014/01/24

--Samankula Owitipana  26-03-2014 
----completion rule

  PROCEDURE VALUE_VPN_CHK_CCT_XCONN (
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


cursor c_circuit_details is
select plp.POLP_PORT_ID
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_CARD_SLOT <> 'NA'
and (po.PORT_NAME like 'POTS-OUT%' or po.PORT_NAME like 'POTS-IN%')
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

open c_circuit_details;
fetch c_circuit_details into v_po_id;
close c_circuit_details;


IF v_po_id is not null THEN

p_ret_msg := 'Please design a bearer circuit and move POTS-IN and POTS-OUT ports to relevent circuits';

END IF;


ELSE

p_ret_msg := p_ret_msg || ' - CCT set commission error';

END IF;


EXCEPTION
WHEN OTHERS THEN

        p_ret_msg  := 'Failed to check circuit details' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END VALUE_VPN_CHK_CCT_XCONN;

--Samankula Owitipana  26-03-2014

--- 12-05-2014 Dinesh Perera

PROCEDURE IPTV_NEW_ATT_UPDATE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS



v_service_type  varchar2(100);
v_order_type    varchar2(100);
v_service_att   varchar2(100);
v_serv_att_new  varchar2(100);


BEGIN


select so.SERO_SERT_ABBREVIATION
into v_service_type
from service_orders so
where so.SERO_ID = p_sero_id;

select so.SERO_ORDT_TYPE
into v_order_type
from service_orders so
where so.SERO_ID = p_sero_id;

select SOA.SEOA_PREV_VALUE
into v_service_att
from service_order_attributes soa
where SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

select SOA.SEOA_DEFAULTVALUE
into v_serv_att_new
from service_order_attributes soa
where SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';


IF v_service_type = 'ADSL' AND v_service_att IS NULL AND v_order_type = 'CREATE' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = 'NEW'
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

ELSIF v_service_type = 'ADSL' AND v_order_type = 'MODIFY-SERVICE' THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = 'NEW'
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

ELSIF v_service_type = 'ADSL' AND v_service_att = 'NEW' AND v_order_type NOT IN ( 'CREATE' , 'MODIFY-SERVICE' ) THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = 'NEW'
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

ELSIF v_service_type = 'ADSL' AND v_service_att = 'OLD' AND v_order_type NOT IN ( 'CREATE' , 'MODIFY-SERVICE' ) THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = 'OLD'
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

ELSIF v_service_type = 'ADSL' AND v_service_att IS NULL AND v_order_type NOT IN ( 'CREATE' , 'MODIFY-SERVICE' ) THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = 'OLD'
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

ELSIF v_service_type = 'ADSL' AND v_serv_att_new IS NULL AND v_order_type IN ( 'SUSPEND' , 'RESUME' ) THEN

UPDATE SERVICE_ORDER_ATTRIBUTES SOA
SET soa.SEOA_DEFAULTVALUE = v_service_att
WHERE SOA.SEOA_SERO_ID = p_sero_id
AND SOA.SEOA_NAME = 'SA_IPTV_SYSTEM';

END IF;


p_implementation_tasks.update_task_status_byid (p_sero_id,0,p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

      p_ret_msg  := 'Failed update CIRCUIT ATTRIBUTE:'  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;
      
     p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
    SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
    , p_ret_msg);
    
END IPTV_NEW_ATT_UPDATE;

--- 12-05-2014 Dinesh Perera

-- 08-05-2014 Samankula Owitipana

PROCEDURE SET_SO_COMPLETION_DATE_BLANK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS


v_pstn_cct_id    VARCHAR2(25);
v_order_type     VARCHAR2(25);

BEGIN

update service_orders so
set so.SERO_COMPLETION_DATE = null
where so.SERO_ID = p_sero_id;


p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN

    p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
    p_ret_msg  := 'Failed blank completion date.' || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

    INSERT INTO SERVICE_TASK_COMMENTS ( SETC_SEIT_ID, SETC_ID, SETC_USERID, SETC_TIMESTAMP,
        SETC_TEXT ) VALUES ( p_seit_id, SETC_ID_SEQ.NEXTVAL, 'CLARITYB',  SYSDATE
        , p_ret_msg );

END SET_SO_COMPLETION_DATE_BLANK;

-- 08-05-2014 Samankula Owitipana

--Indika de Silva 09/05/2014
PROCEDURE PRE_IPVPN_CREATE_FOX_CP_ATT (
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
   CURSOR bearer
   IS
      SELECT DISTINCT soa.seoa_defaultvalue
                 FROM service_orders so, service_order_attributes soa
                WHERE so.sero_id = soa.seoa_sero_id
                  AND soa.seoa_name = 'ACCESS BEARER ID'
                  AND so.sero_id = p_sero_id;

   CURSOR so_copyattr (v_new_bearer_id VARCHAR)
   IS
      SELECT DISTINCT soa.seoa_name, soa.seoa_defaultvalue, c.cirt_status
                 FROM service_orders so,
                      service_order_attributes soa,
                      circuits c
                WHERE so.sero_id = soa.seoa_sero_id
                  AND so.sero_cirt_name = c.cirt_name
                  AND (    c.cirt_status <> 'CANCELLED'
                       AND c.cirt_status <> 'PENDINGDELETE'
                      )
                  AND so.sero_stas_abbreviation <> 'CANCELLED'
                  AND so.sero_id IN (
                         SELECT MAX (s.sero_id)
                           FROM service_orders s, circuits ci
                          WHERE s.sero_cirt_name = ci.cirt_name
                            AND s.sero_stas_abbreviation <> 'CANCELLED'
                            AND ci.cirt_displayname LIKE v_new_bearer_id ||'%');

   v_so_attr_name       VARCHAR2 (100);
   v_so_attr_val        VARCHAR2 (100);
   v_bearer_id          VARCHAR2 (100);
   v_cir_status         VARCHAR2 (100);
   v_new_bearer_id      VARCHAR2 (100);
   v_service_type       VARCHAR2 (100);
   v_service_order      VARCHAR2 (100);
   v_new_service_type   VARCHAR2 (100);
BEGIN
   OPEN bearer;

   FETCH bearer
    INTO v_bearer_id;

   SELECT DISTINCT so.sero_sert_abbreviation
              INTO v_service_type
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   SELECT DISTINCT so.sero_ordt_type
              INTO v_service_order
              FROM service_orders so
             WHERE so.sero_id = p_sero_id;

   OPEN so_copyattr (v_bearer_id);

   LOOP
      FETCH so_copyattr
       INTO v_so_attr_name, v_so_attr_val, v_cir_status;

      EXIT WHEN so_copyattr%NOTFOUND;

      IF     v_service_type = 'D-PREMIUM IPVPN'
         AND v_service_order = 'CREATE-FOX'
         AND v_so_attr_name = 'ACCESS N/W INTF'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'ACCESS N/W INTF';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'SECTION_HANDLED_BY'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'SECTION HANDLED BY';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'CPE CLASS'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE CLASS';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'CPE TYPE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE TYPE';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'CPE MODEL'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'CPE MODEL';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'NTU MODEL'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU MODEL';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'NTU CLASS'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU CLASS';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'NTU TYPE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'NTU TYPE';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'ADDITIONAL NTU MODEL'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'ADDITIONAL NTU MODEL';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'NTU ROUTING MODE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'NTU ROUTING MODE';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'ACCESS MEDIUM'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'ACCESS MEDIUM';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'NO OF COPPER PAIRS'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'NO OF COPPER PAIRS';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'ACCESS INTF PORT BW'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'ACCESS INTF PORT BW';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'DATA RADIO MODEL'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'DATA RADIO MODEL';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'CUSTOMER INTF TYPE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'CUSTOMER INTF TYPE';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'BACKBONE CORE NO'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'BACKBONE CORE NO';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'ACCESS LINK DISTANCE'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'ACCESS LINK DISTANCE';
      ELSIF     v_service_type = 'D-PREMIUM IPVPN'
            AND v_service_order = 'CREATE-FOX'
            AND v_so_attr_name = 'VLAN TAGGED/UNTAGGED ?'
      THEN
         UPDATE service_order_attributes soa
            SET soa.seoa_defaultvalue = v_so_attr_val
          WHERE soa.seoa_sero_id = p_sero_id
            AND soa.seoa_name = 'VLAN TAGGED/UNTAGGED ?';
      END IF;
  
   END LOOP;

   IF     v_service_type = 'D-PREMIUM IPVPN'
      AND v_service_order = 'CREATE-FOX'
      AND (v_cir_status = 'COMMISSIONED' OR v_cir_status = 'INSERVICE')
   THEN
      UPDATE service_order_attributes soa
         SET soa.seoa_defaultvalue = v_cir_status
       WHERE soa.seoa_name = 'ACCESS BEARER STATUS'
         AND soa.seoa_sero_id = p_sero_id;
   END IF;

   

   CLOSE so_copyattr;

   CLOSE bearer;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to Change D-Ethernet VPN Process function. Please check the conditions:'
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
                   p_ret_msg
                  );
END PRE_IPVPN_CREATE_FOX_CP_ATT;

--Indika de Silva 09/05/2014

--Indika de Silva 14-05-2014

PROCEDURE REMV_SUFFIX_N_FROM_ACC_BEAR_ID (
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
   v_acc_bear_id   VARCHAR2 (100);
BEGIN
   SELECT soa.seoa_defaultvalue
     INTO v_acc_bear_id
     FROM service_order_attributes soa
    WHERE soa.seoa_sero_id = p_sero_id AND soa.seoa_name = 'ACCESS BEARER ID';

   UPDATE service_order_attributes soa
      SET soa.seoa_defaultvalue = replace(v_acc_bear_id,'(N)')
    WHERE soa.seoa_name = 'ACCESS BEARER ID' AND soa.seoa_sero_id = p_sero_id;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED'
                                                  );
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Failed to remove suffix (N) from ACCESS BEARER ID attribute'
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
                   p_ret_msg
                  );
END REMV_SUFFIX_N_FROM_ACC_BEAR_ID;

--Indika de Silva 14-05-2014

-- 09-05-2014 Samankula Owitipana

PROCEDURE D_FOX_WAIT_4DAB (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2)
IS
   v_prod_so          VARCHAR2 (100);
   v_bearer_id        VARCHAR2 (100);
   v_Acces_bear_sts   VARCHAR2 (100);
   v_or_type          VARCHAR2 (100);
   v_ser_type         VARCHAR2 (100);

   CURSOR Cur_Pro
   IS
      SELECT SA.SEOA_DEFAULTVALUE
        FROM SERVICE_ORDER_ATTRIBUTES SA
       WHERE     SA.SEOA_NAME = 'PRODUCT SO NUMBER'
             AND SA.SEOA_SERO_ID = p_sero_id;

BEGIN
   OPEN Cur_Pro;

   FETCH Cur_Pro INTO v_prod_so;

   CLOSE Cur_Pro;


   SELECT DISTINCT c.cirt_displayname
     INTO v_bearer_id
     FROM service_orders so, circuits c
    WHERE so.sero_cirt_name = c.cirt_name AND so.sero_id = p_sero_id;

   SELECT SE.SEOA_DEFAULTVALUE
     INTO v_Acces_bear_sts
     FROM SERVICE_ORDER_ATTRIBUTES SE
    WHERE     SE.SEOA_NAME = 'ACCESS BEARER STATUS'
          AND SE.SEOA_SERO_ID = v_prod_so;

   SELECT so.sero_ordt_type, so.sero_sert_abbreviation
     INTO v_or_type, v_ser_type
     FROM service_orders so
    WHERE so.sero_id = v_prod_so;

   IF v_or_type = 'CREATE-FOX' AND v_Acces_bear_sts = 'NEW'
   THEN
      UPDATE SERVICE_ORDER_ATTRIBUTES SOA
         SET SOA.SEOA_DEFAULTVALUE = v_bearer_id
       WHERE     SOA.SEOA_NAME = 'ACCESS BEARER ID'
             AND SOA.SEOA_SERO_ID = v_prod_so;

      UPDATE SERVICE_IMPLEMENTATION_TASKS SIT
         SET SIT.SEIT_STAS_ABBREVIATION = 'COMPLETED'
       WHERE     SIT.SEIT_TASKNAME = 'WAIT FOR DAB'
             AND SIT.SEIT_SERO_ID = v_prod_so;
   ELSE
      DELETE SERVICE_IMPLEMENTATION_TASKS SIT
       WHERE     SIT.SEIT_TASKNAME = 'WAIT FOR DAB'
             AND SIT.SEIT_SERO_ID = v_prod_so;
   END IF;

   p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                   0,
                                                   p_seit_id,
                                                   'COMPLETED');
EXCEPTION
   WHEN OTHERS
   THEN
      p_ret_msg :=
            'Please check the D-DAB  and Service initiate SOD "WAIT FOR DAB" Task   :  - Erro is:'
         || TO_CHAR (SQLCODE)
         || '-'
         || SQLERRM;

      p_implementation_tasks.update_task_status_byid (p_sero_id,
                                                      0,
                                                      p_seit_id,
                                                      'ERROR');

      INSERT INTO service_task_comments (setc_seit_id,
                                         setc_id,
                                         setc_userid,
                                         setc_timestamp,
                                         setc_text)
           VALUES (p_seit_id,
                   setc_id_seq.NEXTVAL,
                   'CLARITYB',
                   SYSDATE,
                   p_ret_msg);
END D_FOX_WAIT_4DAB;

-- 09-05-2014 Samankula Owitipana

-- 02-05-2014 Sudheera Jayathilaka

PROCEDURE ATTCH_ALL_PRO_TO_NEW_CIRCUIT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2)   IS

SERVICE_ORD_ID      SERVICE_ORDERS.SERO_ID%TYPE := p_sero_id;
NEW_CIRCUIT_NAME    CIRCUITS.CIRT_NAME%TYPE;
COMM_CIR_DISP_NAME  CIRCUITS.CIRT_DISPLAYNAME%TYPE;
OLD_CRT_STAT        CIRCUITS.CIRT_STATUS%TYPE := 'INSERVICE' ;
OLD_CIRCUIT_NAME    CIRCUITS.CIRT_NAME%TYPE;
ENTITY_TPE          VARCHAR2(20) := 'CIRCUITS';
FUNCT_DAT           CLTY_API.CALLSTATUS ;

CURSOR GET_OLD_CIRCUIT (COMM_DISP_NME IN CIRCUITS.CIRT_DISPLAYNAME%TYPE) IS                       
  
SELECT 
    CIRT_NAME,CIRT_STATUS
FROM 
    CIRCUITS 
WHERE 
    CIRT_DISPLAYNAME = COMM_DISP_NME ;

CURSOR PROB_LIST (OLD_CIRT_NUMB IN VARCHAR2) IS 
SELECT 
PROM_NUMBER
FROM 
PROBLEMS P, 
PROBLEM_LINKS PL
WHERE 
    P.PROM_NUMBER = PL.PROL_PROM_NUMBER
AND PL.PROL_FOREIGNID = OLD_CIRT_NUMB
AND PL.PROL_FOREIGNTYPE = 'CIRCUITS';  


BEGIN

SELECT 
    SERO_CIRT_NAME INTO NEW_CIRCUIT_NAME 
FROM 
    SERVICE_ORDERS 
WHERE 
    SERO_ID = SERVICE_ORD_ID;

SELECT 
    SEOA_DEFAULTVALUE INTO COMM_CIR_DISP_NAME 
FROM 
    SERVICE_ORDER_ATTRIBUTES 
WHERE 
    SEOA_SERO_ID = SERVICE_ORD_ID 
AND SEOA_NAME IN ('DATA CIRCUIT ID','CIRCUIT ID','ADSL_CIRCUIT_ID'); 

FOR CICUIT_REC IN GET_OLD_CIRCUIT (COMM_CIR_DISP_NAME)
LOOP
    IF CICUIT_REC.CIRT_NAME <> NEW_CIRCUIT_NAME AND CICUIT_REC.CIRT_STATUS = OLD_CRT_STAT THEN
    OLD_CIRCUIT_NAME := CICUIT_REC.CIRT_NAME ;
    END IF;
END LOOP; 

IF NEW_CIRCUIT_NAME <> OLD_CIRCUIT_NAME THEN

FOR PROBL_REC IN PROB_LIST (OLD_CIRCUIT_NAME)
LOOP
      P_FAULTMGR_API.LINKENTITY(PROBL_REC.PROM_NUMBER,ENTITY_TPE,NEW_CIRCUIT_NAME,FUNCT_DAT);
END LOOP;  

END IF;

p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'COMPLETED');

EXCEPTION
WHEN OTHERS THEN
p_implementation_tasks.update_task_status_byid(p_sero_id,0, p_seit_id,'ERROR');
p_ret_msg  := 'Failed to connect Fault to new circuit. '  || ' - Erro is:' || TO_CHAR(SQLCODE) ||'-'|| SQLERRM;

END ATTCH_ALL_PRO_TO_NEW_CIRCUIT;

-- 02-05-2014 Sudheera Jayathilaka


   --- Jayan Liyanage 2014 /07/02
   
PROCEDURE D_IPVPN_WG_CHANGE_MDIFY_SPD (
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

v_cpe_model_cur    varchar2(100);
v_cpe_model_pre    varchar2(100);
v_dsu_typ_cur      varchar2(100);
v_dsu_typ_pre      varchar2(100);
v_med_typ_cur      varchar2(100);
v_mln_port         varchar2(100);
v_ser_ctg          varchar2(100);
v_sec_handle       varchar2(100);
v_service_type     varchar2(100);
v_service_order    varchar2(100);
v_service_order_area varchar2(100);
v_work_group_os      varchar2(100);
v_work_group_cpe     varchar2(100);
v_rtom_code             varchar2(100);
v_lea_code               varchar2(100);


BEGIN

SELECT DISTINCT so.sero_sert_abbreviation INTO v_service_type
FROM service_orders so WHERE so.sero_id =  p_sero_id;

SELECT DISTINCT so.sero_ordt_type INTO v_service_order 
FROM service_orders so WHERE so.sero_id =  p_sero_id;

SELECT DISTINCT so.sero_area_code INTO v_service_order_area FROM service_orders so WHERE so.sero_id = p_sero_id;

SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE INTO v_cpe_model_cur,v_cpe_model_pre
FROM SERVICE_ORDER_ATTRIBUTES SOA  WHERE SOA.SEOA_NAME = 'CPE_MODEL' AND SOA.SEOA_SERO_ID = p_sero_id;
SELECT SOA.SEOA_DEFAULTVALUE,SOA.SEOA_PREV_VALUE INTO v_dsu_typ_cur,v_dsu_typ_pre
FROM SERVICE_ORDER_ATTRIBUTES SOA  WHERE SOA.SEOA_NAME = 'SA_DSU_TYPE' AND SOA.SEOA_SERO_ID = p_sero_id;
--SELECT SOA.SEOA_DEFAULTVALUE INTO v_med_typ_cur
--FROM SERVICE_ORDER_ATTRIBUTES SOA  WHERE SOA.SEOA_NAME = 'MEDIA TYPE'AND SOA.SEOA_SERO_ID = p_sero_id;
SELECT SOA.SEOA_DEFAULTVALUE INTO v_mln_port FROM SERVICE_ORDER_ATTRIBUTES SOA  
WHERE SOA.SEOA_NAME = 'MLLN PORT CHANGE?' AND SOA.SEOA_SERO_ID = p_sero_id;
SELECT SOA.SEOA_DEFAULTVALUE INTO v_ser_ctg FROM SERVICE_ORDER_ATTRIBUTES SOA  
WHERE SOA.SEOA_NAME = 'SERVICE CATEGORY' AND SOA.SEOA_SERO_ID = p_sero_id;

SELECT SOA.SEOA_DEFAULTVALUE INTO v_sec_handle FROM SERVICE_ORDER_ATTRIBUTES SOA  
WHERE SOA.SEOA_NAME = 'SECTION HANDLED BY'AND SOA.SEOA_SERO_ID = p_sero_id;

SELECT SUBSTR (ar.area_area_code, 3, INSTR (ar.area_area_code, '-', 1) + 1)AS codes_a,ar.area_code 
INTO v_rtom_code,v_lea_code FROM areas ar WHERE ar.area_code = v_service_order_area 
AND ar.area_aret_code = 'LEA';
SELECT wg.worg_name INTO v_work_group_os FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code || '-' || v_lea_code || '%' || 'OSP-NC' || '%';                  
SELECT wg.worg_name INTO v_work_group_cpe FROM work_groups wg 
WHERE worg_name LIKE v_rtom_code || '-' || '%' || 'CPE-NC' || '%';

/*
 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' and 
   v_cpe_model_cur <> v_cpe_model_pre
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY  CPE'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MODIFY  CPE'; END IF;*/

 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' and 
   nvl(v_cpe_model_cur,0) = nvl(v_cpe_model_pre,0)
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RECONFIG  CPE'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'RECONFIG  CPE'; END IF;
  /*
 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' and
    v_dsu_typ_cur <> v_dsu_typ_pre
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_work_group_cpe
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY  DSU'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MODIFY  DSU'; END IF;*/

 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' and nvl(v_dsu_typ_cur,0) = nvl(v_dsu_typ_pre,0)
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'RECONFIGURE DSU'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'RECONFIGURE DSU'; END IF;
/*
 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' and v_med_typ_cur = 'COPPER' and 
   v_mln_port = 'YES'
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = 'DS-CPEI' 
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'MODIFY MDF JUMPER'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'MODIFY MDF JUMPER'; END IF;

 IF     v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED' AND v_ser_ctg = 'TEST' 
THEN
   UPDATE service_implementation_tasks sit SET sit.seit_worg_name = v_sec_handle||'-ACCM'
   WHERE sit.seit_sero_id = p_sero_id AND sit.seit_taskname = 'CONFIRM TEST LINK'; 
     ELSIF v_service_type = 'D-IPVPN' AND v_service_order = 'MODIFY-SPEED'
THEN 
  DELETE      service_implementation_tasks sit WHERE sit.seit_sero_id = p_sero_id 
  AND sit.seit_taskname = 'CONFIRM TEST LINK'; END IF;
*/
p_implementation_tasks.update_task_status_byid (p_sero_id, 0,p_seit_id,'COMPLETED' );
EXCEPTION WHEN OTHERS THEN p_ret_msg := 'Failed to Change D-IPVPN WG change Process function. Please check the conditions:'
|| ' - Erro is:'|| TO_CHAR (SQLCODE)|| '-'|| SQLERRM;
p_implementation_tasks.update_task_status_byid (p_sero_id, 0, p_seit_id, 'ERROR');

INSERT INTO service_task_comments(setc_seit_id, setc_id, setc_userid, setc_timestamp,setc_text
)VALUES (p_seit_id, setc_id_seq.NEXTVAL, 'CLARITYB', SYSDATE,p_ret_msg);


END D_IPVPN_WG_CHANGE_MDIFY_SPD;

-- Jayan Liyanage  2014 /07/02


END P_SLT_FUNCTIONS_V3;
/
