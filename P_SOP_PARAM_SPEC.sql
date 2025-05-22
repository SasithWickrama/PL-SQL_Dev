CREATE OR REPLACE PACKAGE CPRG.p_sop_param
AS
   FUNCTION get_snb (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_snb_reformated (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to retrieve service order attribute value
   FUNCTION get_attribute_value (
      p_service_order      IN       service_orders.sero_id%TYPE,
      p_service_revision   IN       service_orders.sero_revision%TYPE,
      p_service_name       IN       service_type_attributes.seta_name%TYPE,
      p_attribute_value    OUT      service_order_attributes.seoa_defaultvalue%TYPE,
      p_prev_value         OUT      service_order_attributes.seoa_defaultvalue%TYPE
   )
      RETURN BOOLEAN;

   -- Function to retrieve service order attribute value
   FUNCTION get_feature_value (
      p_service_order      IN       service_orders.sero_id%TYPE,
      p_service_revision   IN       service_orders.sero_revision%TYPE,
      p_service_name       IN       service_type_attributes.seta_name%TYPE,
      p_feature_value      OUT      service_order_features.sofe_defaultvalue%TYPE,
      p_prev_value         OUT      service_order_features.sofe_defaultvalue%TYPE
   )
      RETURN BOOLEAN;

   FUNCTION get_uid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_uidnumber (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_gecos (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_desc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailaddress (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailhost (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailquota (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_shadowexpire (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailuserstatus (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_service (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_password (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_action (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_attribute (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_domain (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_olduid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_newuid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailforwardaddr (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mailforwardattr (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_serialnumber (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_homedir (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_hunt_snb (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_hunt_dev (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_categ (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_old_snb (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_old_snb_reformated (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_reply_desc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_command   IN   sop_commands.sopc_command%TYPE,
      pi_user_id   IN   service_order_features.sofe_feature_name%TYPE
   )
      RETURN VARCHAR2;

   FUNCTION get_rc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_lc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ac (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_snb_neax61e75 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_old_snb_neax61e75 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_17_sc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_pe_a (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_pe_b (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

--
-- Function to get the current date
--
   FUNCTION get_current_date_time (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get Exchange Area (LEA)
   FUNCTION get_lea (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   --Function to get Service Order No
   FUNCTION get_service_order_no (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get Order Type
   FUNCTION get_service_order_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get Swtch Code
   FUNCTION get_switchcode (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get Swtich Type
   FUNCTION get_switchtype (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_snb_city_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_old_snb_city_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get Port Name
   FUNCTION get_portname (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get imsi
   FUNCTION get_imsi (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- Function to get hlr id
   FUNCTION get_hlr_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_sms_objectclass (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_snb_temp_susp (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_login_service (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_uidlevel (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_no_of_users (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_inet_password (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_user_pwd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_emonly_pwd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_internet_pwd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_filtered_pwd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_roaming_pwd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_user_pwd_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_emonly_pwd_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_internet_pwd_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_filtered_pwd_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_roaming_pwd_value (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_mail_message_store (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_action_del (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ldap_uid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------------------------------------------------------------------------------------------
   FUNCTION get_dslam_alias (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_lprofid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_vlan_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_vlan_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_pvcid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_vci (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_svpid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_rx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_tx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_dslam_tsn (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_d (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_lp (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_csc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_icr (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_ocr (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_tfpt (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_ldnset (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_ns (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_nd (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------------------------------------------------------------------------------------------
   FUNCTION get_modify_user_user (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_modify_user_domain (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_modify_user_service (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_modify_user_newuser (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_emailtosms (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_option (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_loc (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----------------------------------------------------------------------------------------------
-- Gihan 23-11-2009 NGN change
   FUNCTION get_ngn_os (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----------------------------------------------------------------------------------------------

   --Function to populate SO_NEW_IMSI- Returns the IMSI
   FUNCTION get_new_imsi (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

--Function to populate SO_NEW_TELNO- Returns the New Telephone Number with City Code
   FUNCTION get_new_snb_city_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

--Function to populate Switch Code from the number
   FUNCTION get_number_area_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   --Function to populate Switch Code from the number
   FUNCTION get_rtpro_switch_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

--Function to populate BTS COde for GSMFW equipments
   FUNCTION get_bts_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   -- added process function for PLDTII-472  development
   FUNCTION get_number_city_code (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_landline_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ne_index (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_port_number (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_logical_port (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_card_shelf (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_card_slot (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ngn_CFTBSD(
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION GET_NGN_LDNEST(
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION TL1CMD_PAYLOAD_CFTBST (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION TL1CMD_PAYLOAD_CFTBET (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION ne_locn_type_index (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION ne_locn (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION ne_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION ne_locn_address (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

   FUNCTION ne_port_name (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2 )  RETURN VARCHAR2;

END p_sop_param;
/
