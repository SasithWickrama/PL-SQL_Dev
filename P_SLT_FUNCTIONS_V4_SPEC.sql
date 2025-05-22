CREATE OR REPLACE PACKAGE GCI_MIG.P_SLT_FUNCTIONS_V4 AS
/******************************************************************************
   NAME:       P_SLT_FUNCTIONS_V4
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/2/2014      011192       1. Created this package.
******************************************************************************/

---- Dinesh Perera  01-09-2014 ------
 PROCEDURE UPD_SYS_DSP_DATE (
      P_SERV_ID                IN     SERVICES.SERV_ID%TYPE,
      P_SERO_ID                IN     SERVICE_ORDERS.SERO_ID%TYPE,
      P_SEIT_ID                IN     SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      P_IMPT_TASKNAME          IN     IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
      P_WORO_ID                IN     WORK_ORDER.WORO_ID%TYPE,
      P_RET_CHAR                  OUT    VARCHAR2,
      P_RET_NUMBER                OUT    NUMBER,
      P_RET_MSG                   OUT    VARCHAR2);
---- Dinesh Perera  01-09-2014 ------

---- Dinesh Perera  02-09-2014 ------
 PROCEDURE UPD_SYS_DSP_DATE_TASK (
      P_SERV_ID                IN     SERVICES.SERV_ID%TYPE,
      P_SERO_ID                IN     SERVICE_ORDERS.SERO_ID%TYPE,
      P_SEIT_ID                IN     SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      P_IMPT_TASKNAME          IN     IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
      P_WORO_ID                IN     WORK_ORDER.WORO_ID%TYPE,
      P_RET_CHAR                  OUT    VARCHAR2,
      P_RET_NUMBER                OUT    NUMBER,
      P_RET_MSG                   OUT    VARCHAR2);
---- Dinesh Perera  02-09-2014 ------

-- Jayan Liyanage 2013/12/24
 PROCEDURE D_SIP_X_CONNE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2013/12/24
 
--- Jayan Liyanage  2014 /07/ 01
PROCEDURE NBN_BTL_BLANK_ATTR (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /07/ 01 
PROCEDURE NBN_BTL_CP_ATTR_BEARER (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /07/ 01 
PROCEDURE NBN_D_BTL_CREATE_1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /07/ 01
PROCEDURE NBN_D_BTL_CREATE_2 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2); 
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /07/ 01 
PROCEDURE NBN_D_BTL_CREATE_3 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /07/ 01  
PROCEDURE D_BTL_X_CONNE_WG_CHG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Jayan Liyanage  2014 /09/ 16 
PROCEDURE NBN_D_BTL_CREATE_TX_WG_CHGE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /09/ 16

--- Jayan Liyanage  2014 /07/ 01 
PROCEDURE NBN_BTL_CLOSE_SO (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /07/ 01

--- Indika de Silva 09/10/2014
PROCEDURE ETH_VPN_CREATE_FOX_CP_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Indika de Silva 09/10/2014

--- 07-05-2014 Samankula Owitipana
PROCEDURE PSTN_SEND_SMS_TO_CUSTOMER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
--- 07-05-2014 Samankula Owitipana

--- Jayan Liyanage  2014 /06/ 04  
PROCEDURE D_EP_WIFI (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /06/ 04

--- Jayan Liyanage 2014 / 05 / 23 
PROCEDURE FTTH_MODIFY_LOC  (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2014 / 05 / 23

--- Dinesh Perera 24-10-2014
PROCEDURE MOD_SPEED_TASK_REMOVE (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2);
   
--- Dilupa Alahakoon 2014 / 10 / 27
PROCEDURE D_SCHOOLNET_BACKHAUL_CREATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Dilupa Alahakoon 2014 / 10 / 29  
PROCEDURE D_SCHOOLNET_BACK_CRE_TRANSFER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014 / 09 / 26
PROCEDURE D_ETHERNET_EXT_SER (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2); 

--- Jayan Liyanage 2014 / 09 / 26
PROCEDURE D_ETHERNET_EXT_SER_WAIT4_WIFI (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2);

--- Jayan Liyanage 2014 /10 / 24 
PROCEDURE ASS_ACC_FIB_CMP (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2);

--- Jayan Liyanage 2014 /10 / 24
PROCEDURE ASSIGN_NEW_ACC_FIBE (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2);

--- Jayan Liyanage 2014/11/05
PROCEDURE D_DAB_SATART_FIB_LAY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014 / 10 / 22
PROCEDURE WAIT4_FIBER_FOR_DATA_TSK (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2014 / 12 / 01
PROCEDURE  WAIT_4_FIBER_EXIS_OD1SIDE(
p_serv_id                      IN     Services.serv_id%TYPE,
p_sero_id                      IN     Service_Orders.sero_id%TYPE,
p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id                      IN     work_order.woro_id%TYPE,
p_ret_char                     OUT    VARCHAR2,
p_ret_number                   OUT    NUMBER,
p_ret_msg                      OUT    VARCHAR2);

-- Jayan Liyanage 2014 / 12 / 01
PROCEDURE  WAIT_4_FIBER_EXIS_EDL(
p_serv_id                      IN     Services.serv_id%TYPE,
p_sero_id                      IN     Service_Orders.sero_id%TYPE,
p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id                      IN     work_order.woro_id%TYPE,
p_ret_char                     OUT    VARCHAR2,
p_ret_number                   OUT    NUMBER,
p_ret_msg                      OUT    VARCHAR2);

-- Jayan Liyanage 2014 / 11 / 10
PROCEDURE D_DAB_CH_WO_ACTIVITY_WG (
   P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
   P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
   P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
   P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
   P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
   P_RET_CHAR        OUT      VARCHAR2,
   P_RET_NUMBER      OUT      NUMBER,
   P_RET_MSG         OUT      VARCHAR2 );
 
--- Jayan Liyanage 2014 / 11 / 25
PROCEDURE  BTL_SW_WG_CHNG(
p_serv_id                      IN     Services.serv_id%TYPE,
p_sero_id                      IN     Service_Orders.sero_id%TYPE,
p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id                      IN     work_order.woro_id%TYPE,
p_ret_char                     OUT    VARCHAR2,
p_ret_number                   OUT    NUMBER,
p_ret_msg                      OUT    VARCHAR2);


-- 28-02-2014 Sudheera -----
PROCEDURE UPDATE_ADSL_CANC_ATTR
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
      
--- Jayan Liyanage  2014 / 09 / 22  
 PROCEDURE BTL_PROVISION_FEATURE_CHECK (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 / 09 / 22

--- Jayan Liyanage 2014/08/04
PROCEDURE D_BTL_CH_WO_ACTIVITY_WG (
   P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
   P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
   P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
   P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
   P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
   P_RET_CHAR        OUT      VARCHAR2,
   P_RET_NUMBER      OUT      NUMBER,
   P_RET_MSG         OUT      VARCHAR2);
--- Jayan Liyanage 2014/08/04 

--- Dinesh Perera 2014/12/19 ----
PROCEDURE REMOVE_IP_TASK_CON_FUNCTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ; 
--- Dinesh Perera 2014/12/19 ----

---- Dinesh Perera 2014/12/30 ----
PROCEDURE PROCESS_UPDATE_SW_ATTR (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
---- Dinesh Perera 2014/12/30 ----

---- 23-12-2014 Samankula Owitipana
PROCEDURE FTTH_UPDATE_PKG_NAME (

   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---- 23-12-2014 Samankula Owitipana

---- 02-01-2015 Samankula Owitipana
PROCEDURE FTTH_UPDATE_EQUIP_MANR (

   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---- 02-01-2015 Samankula Owitipana

---- 06-01-2015 Dinesh Perera ----
PROCEDURE FTTH_MANS_NAME_UPDATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---- 06-01-2015 Dinesh Perera ----

-- 06-01-2015 Samankula Owitipana
PROCEDURE FTTH_CLOSE_WAIT_FOR_FAB (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
-- 06-01-2015 Samankula Owitipana

-----Dilupa Alahakoon 2014/12/11
PROCEDURE D_WIFI_BACK_CREATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
-----Dilupa Alahakoon 2014/12/11

-----Dilupa Alahakoon 2014/12/12
PROCEDURE D_WIFI_BACK_XCON (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
-----Dilupa Alahakoon 2014/12/12

-----Dilupa Alahakoon  2014/12/26
PROCEDURE D_WIFI_BK_SPED_TO_UPNDOW_SPED(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;    
-----Dilupa Alahakoon  2014/12/26

--- Dinesh Perera 2015/01/08 ----
PROCEDURE VDSL_TASK_CON_FUNCTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2); 
--- Dinesh Perera 2015/01/08 ----

---Dulip Fernando  2015/02/13
 PROCEDURE FAULT_ATT_UPDATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Dulip Fernando  2015/02/13

--- Jayan Liyanage  2014 /09/ 09
PROCEDURE NBN_D_BTL_CREATE_UPGR_1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /09/ 09

--- Jayan Liyanage  2014 /09/ 09 
PROCEDURE NBN_D_BTL_CREATE_UPGR_2 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /09/ 09

--- Jayan Liyanage  2014 /08/ 07
PROCEDURE NBN_D_BTL_CREATE_UPGRADE_3 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage  2014 /08/ 07

----Dinesh Perera  2015/02/25  -----
 PROCEDURE ONT_SERIAL_NUMBER_CHECK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/02/25  -----

----Dinesh Perera  2015/02/25  -----
 PROCEDURE FTTH_HOLD_CHILD_FOR_PARENT (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/02/25  -----  

----Dinesh Perera  2015/03/02  -----
 PROCEDURE FTTH_CLOSE_INPROG_CHILD (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/03/02  -----  

----Dinesh Perera  2015/03/02  -----
 PROCEDURE FTTH_CLOSE_PARENT_WAIT_FB (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/03/02  ----- 

---- Dinesh Perera 11/03/2015 ----
PROCEDURE CHANGE_VOICE_FEATURES_TO_N (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---- Dinesh Perera 11/03/2015 ----

--- Jayan Liyanage 2015 /03 /10

PROCEDURE INF_SEQ_ID_SET(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2015 /03 /10

--- Jayan Liyanage 2014 / 11 / 12
  
  PROCEDURE D_EDL_CREATE_TRANSF (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2014 / 11 / 12

--- Jayan Liyanage 2014 / 11 18
 
PROCEDURE D_EDL_CREATE_TRS_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);

--- jayan Liyanage 2014 / 11 / 18

--- Jayan Liyanage 2014 / 11 / 12 
  
  PROCEDURE D_EDL_CREATE_TRS_SET_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014 / 11 / 12

--- Jayan Liyanage 2014 / 09 / 10
  
PROCEDURE NBN_D_BTL_CREATE_TRANSF_1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014 / 09 / 10

---- Jayan Liyanage  2014 /08/ 07
  
PROCEDURE NBN_D_BTL_CREATE_TRANSFER_2 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage  2014 /08/ 07

--- Jayan Liyanage 2015 .03. 18
 
PROCEDURE NBN_D_BTL_CREATE_TRANSFER_3 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2015 .03. 18

--- Jayan Liyanage 2015/04/28
 
PROCEDURE INF_ATT_UPDATE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);


--- Jayan Liyanage 2015/04/28

---  Dinesh Perera 2015/05/13
PROCEDURE UPDATE_SO_FEATURE_FLAG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
---  Dinesh Perera 2015/05/13

--- Dulip Fernando  2015/02/13
 PROCEDURE FAULTS_WORK_FLOW_ATT_UPDATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
--- Dulip Fernando  2015/02/13

--- Jayan Liyanage 29/05/2015
PROCEDURE D_DAB_RESERVE_TX (
   P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
   P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
   P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
   P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
   P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
   P_RET_CHAR        OUT      VARCHAR2,
   P_RET_NUMBER      OUT      NUMBER,
   P_RET_MSG         OUT      VARCHAR2);
   
--- Jayan Liyanage 29/05/2015

--- Jayan Liyanage 2014/01/24

PROCEDURE D_EDL_SUS_RESU(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);
--- Jayan Liyanage 2014/01/24

--- Jayan Liyanage 2015/04/28
 PROCEDURE DAB_PUSH_SO_NUMBER (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2015/04/28

----Dulip Fernando  2015/06/11
PROCEDURE WAIT_FOR_LPM_CCT (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
----Dulip Fernando  2015/06/11

---- Dinesh Perera  28-05-2015 ------
 PROCEDURE IPTV_SYS_ATT_UPDATE (
      P_SERV_ID                IN     SERVICES.SERV_ID%TYPE,
      P_SERO_ID                IN     SERVICE_ORDERS.SERO_ID%TYPE,
      P_SEIT_ID                IN     SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      P_IMPT_TASKNAME          IN     IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
      P_WORO_ID                IN     WORK_ORDER.WORO_ID%TYPE,
      P_RET_CHAR                  OUT    VARCHAR2,
      P_RET_NUMBER                OUT    NUMBER,
      P_RET_MSG                   OUT    VARCHAR2);
---- Dinesh Perera  28-05-2015 ------

---- Jayan Liyanage 2015/07/29
PROCEDURE APPROVE_SO_WGCH_TO_RTOM (
      P_SERV_ID                IN     SERVICES.SERV_ID%TYPE,
      P_SERO_ID                IN     SERVICE_ORDERS.SERO_ID%TYPE,
      P_SEIT_ID                IN     SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      P_IMPT_TASKNAME          IN     IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
      P_WORO_ID                IN     WORK_ORDER.WORO_ID%TYPE,
      P_RET_CHAR                  OUT    VARCHAR2,
      P_RET_NUMBER                OUT    NUMBER,
      P_RET_MSG                   OUT    VARCHAR2);
---- Jayan Liyanage 2015/07/29


------Dinesh Perera 07-08-2015 ---- HLR--for FAULT_WF---
PROCEDURE PROCESS_UPDATE_HLR_FLT_ATTR (
        p_serv_id           IN      Services.serv_id%TYPE,
        p_sero_id           IN      Service_Orders.sero_id%TYPE,
        p_seit_id           IN      Service_Implementation_Tasks.seit_id%TYPE,
        p_impt_taskname     IN      Implementation_Tasks.impt_taskname%TYPE,
        p_woro_id           IN      work_order.woro_id%TYPE,
        p_ret_char          OUT     VARCHAR2,
        p_ret_number        OUT     NUMBER,
        p_ret_msg           OUT     VARCHAR2);
------Dinesh Perera 07-08-2015 ---- HLR--for FAULT_WF---

--- 06-06-2014  Samankula Owitipana--Production updated on 28-08-2015 
  PROCEDURE DNR_RENEWAL_EXP_DATE_SET  (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- 06-06-2014  Samankula Owitipana

-- Jayan Liyanage 24/08/2015
PROCEDURE ASSOCIATE_PSTN_NUMBER_TO_FTTH (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2);
-- Jayan Liyanage 24/08/2015

--- Samankula Owitipana 2013/05/16
PROCEDURE D_BDL_CREATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
--- Samankula Owitipana 2013/05/16

--- Jayan Liyanage     24/07/2015
PROCEDURE CENTREX_WG_CHANGE(
p_serv_id                      IN     Services.serv_id%TYPE,
p_sero_id                      IN     Service_Orders.sero_id%TYPE,
p_seit_id                       IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname           IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id                     IN     work_order.woro_id%TYPE,
p_ret_char                     OUT    VARCHAR2,
p_ret_number                OUT    NUMBER,
p_ret_msg                     OUT    VARCHAR2);
--- Jayan Liyanage     24/07/2015

--- Jayan Liyanage  02/09/2015
PROCEDURE D_VALUE_VPN_EXT_SER (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2);
--- Jayan Liyanage  02/09/2015

--- Jayan Liyanage  02/09/2015
PROCEDURE D_VALUE_VPN_EXT_SER_SMART_DIAL (
 p_serv_id IN services.serv_id%TYPE,
 p_sero_id IN service_orders.sero_id%TYPE,
 p_seit_id IN service_implementation_tasks.seit_id%TYPE,
 p_impt_taskname IN implementation_tasks.impt_taskname%TYPE,
 p_woro_id IN work_order.woro_id%TYPE,
 p_ret_char OUT VARCHAR2,
 p_ret_number OUT NUMBER,
 p_ret_msg OUT VARCHAR2);
--- Jayan Liyanage  02/09/2015

---Danushka Fenando 05/10/2015
PROCEDURE SET_PSTN_PROV_STATUS
(
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);     
---Danushka Fenando 05/10/2015  


----Dinesh Perera  2015/10/02  -----
 PROCEDURE FTTH_CLOSE_CHILD_LAST_TASK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/10/02  -----

-- Jayan Liyanage 14/10/2015
PROCEDURE D_PREMI_MODIFY_EQUI_SET_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
-- Jayan Liyanage 14/10/2015

-- Jayan Liyanage 13/10/2015
PROCEDURE D_DAB_MODI_EQP_WG(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
-- Jayan Liyanage 13/10/2015

-- Jayan Liyanage 13/10/2015
PROCEDURE D_DAB_MODIFY_EQ_NOTIFY(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);     
-- Jayan Liyanage 13/10/2015

-- Jayan Liyanage 2015/10/16
PROCEDURE D_ACC_BEARER_STS_CHG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );
-- Jayan Liyanage 2015/10/16

-- Jayan Liayanage 08/10/2015
PROCEDURE D_ETHERNET_VPN_MODIFY_EQUIP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
-- Jayan Liyanage  08/10/2015

------------------------------------------------------------------------------

--- Jayan Liyanage 08/10/2015
PROCEDURE D_ETHER_MODIFY_EQUI_SET_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 08/10/2015

-- Jayan Liyanage 2015/10/23
PROCEDURE D_BIL_MODIFY_EQUI_SET_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );
-- Jayan Liyanage 2015/10/23

--ICT-- 28/10/2015
 PROCEDURE  ICT_SOLU_WGCH_FUNCTION (

      p_serv_id                      IN     Services.serv_id%TYPE,
      p_sero_id                      IN     Service_Orders.sero_id%TYPE,
      p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                      IN     work_order.woro_id%TYPE,
      p_ret_char                     OUT    VARCHAR2,
      p_ret_number                   OUT    NUMBER,
      p_ret_msg                      OUT    VARCHAR2);
--ICT-- 28/10/2015

--- Jayan Liyanage 2015/04/17
PROCEDURE  BTL_SOD_ATR_BK(
p_serv_id                      IN     Services.serv_id%TYPE,
p_sero_id                      IN     Service_Orders.sero_id%TYPE,
p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id                      IN     work_order.woro_id%TYPE,
p_ret_char                     OUT    VARCHAR2,
p_ret_number                   OUT    NUMBER,
p_ret_msg                      OUT    VARCHAR2);
--- Jayan Liyanage 2015/04/17

--- Jayan Liyaange 2015/04/17
 PROCEDURE D_BTL_MODIFY_NUMBER_1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );
--- Jayan Liyanage 2015/04/17

--- Jayan Liyaange 2015/04/17
 PROCEDURE D_BTL_MODIFY_NUMBER (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );
--- Jayan Liyanage 2015/04/17

----Dinesh Perera  2015/11/06  -----
 PROCEDURE FTTH_CLOSE_CHILD_WAIT_FB (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/11/06  -----

---Indika de Silva  2015/02/11
 PROCEDURE D_BIL__FOX_BEA_ATT_CP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Indika de Silva  2015/02/11

 --- 29-09-2013  Samankula Owitipana  
 --update 10/29/2015 Kalana--
 
PROCEDURE PSTN_CREDIT_SUSPEND_RESUME_N2Y (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 29-09-2013  Samankula Owitipana  

--- 29-09-2013  Samankula Owitipana  
 
PROCEDURE PSTN_CREDIT_SUSPEND_RESUME_2N (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 29-09-2013  Samankula Owitipana
--update 10/29/2015 Kalana--


PROCEDURE PSTN_CREDIT_RESUME_N2Y (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 29-09-2013  Samankula Owitipana  

--- 29-09-2013  Samankula Owitipana  
 
PROCEDURE PSTN_CREDIT_RESUME_2N (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
   
-- Samitha Sagara 17112015
PROCEDURE CREDIT_RESPONSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- Samitha Sagara 17112015
   

----Dinesh Perera  2015/11/12  -----
 PROCEDURE UPDATE_DNR_EMAIL_DATA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  2015/11/12  -----

--- Jayan Liyanage 16/09/2015

PROCEDURE D_ENT_WIFI_WG_CHANGE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 16/09/2015

--- 26-11-2015  SUPPORT TEAM
PROCEDURE TASK_DELAY_FIVE_SECONDS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      
--- 26-11-2015  SUPPORT TEAM
--- 26-11-2015  SUPPORT TEAM
PROCEDURE TASK_DELAY_FIVE_MINUTE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);     
--- 26-11-2015  SUPPORT TEAM

--- 26-11-2015  SUPPORT TEAM
PROCEDURE TEST_HCV_CIRT_UPDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);    
--- 26-11-2015  SUPPORT TEAM

--- 30-12-2015  Dhanushka
PROCEDURE PROCESS_UPDATE_MANS_NAME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);    
--- 30-12-2015  Dhanushka

---- Dinesh Perera 15-12-2015 ---- 
PROCEDURE ADSL_BEARER_NAME_MODIFY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
---- Dinesh Perera 15-12-2015 ----

---- Dinesh Perera 05-01-2016 ----
PROCEDURE SOP_PROVISION_STATUS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
---- Dinesh Perera 05-01-2016 ----

---- Ruwan Ranasingha 07-01-2016 ----
PROCEDURE FUNCTION_HOLD_BY_FORCE (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
---- Ruwan Ranasingha 07-01-2016 ----

---Jayan Liyanage 2015 / 05 / 20
PROCEDURE EDL_WO_ACTIVITY_CWG (
   P_SERV_ID         IN       SERVICES.SERV_ID%TYPE,
   P_SERO_ID         IN       SERVICE_ORDERS.SERO_ID%TYPE,
   P_SEIT_ID         IN       SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
   P_IMPT_TASKNAME   IN       IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
   P_WORO_ID         IN       WORK_ORDER.WORO_ID%TYPE,
   P_RET_CHAR        OUT      VARCHAR2,
   P_RET_NUMBER      OUT      NUMBER,
   P_RET_MSG         OUT      VARCHAR2);
---Jayan Liyanage 2015 / 05 / 20

--- Jayan Liyanage 2015 / 05 / 12
PROCEDURE D_EDL_MODIFY_LOCATION (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);  
--- Jayan Liyanage 2015 / 05 / 12

--- Jayan Liyanage 2015 / 05 / 12
PROCEDURE D_EDL_MODIFY_LOC_SET_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2015 / 05 / 12

--- Jayan Liyanage 2015 / 05 / 12
PROCEDURE D_EDL_MODIFY_LOC_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2015 / 05 / 12

---Prabodha Chathuranga  2015/12/10
PROCEDURE D_BTL_NTU_MODCHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Prabodha Chathuranga  2015/12/10

---Prabodha Chathuranga  2015/07/23
PROCEDURE D_BTL_CREATE_ADDTRANSFER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Prabodha Chathuranga  2015/07/23

----Dinesh Perera  19-01-2016  -----
 PROCEDURE UPDATE_M3VPN_EMAIL_DATA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
----Dinesh Perera  19-01-2016  -----

----Jayan Liyanage 05 / 02 / 2016
 PROCEDURE ICT_ATTRIBUTE_UPDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char           OUT VARCHAR2,
      p_ret_number         OUT NUMBER,
      p_ret_msg            OUT VARCHAR2);     
----Jayan Liyanage 05 / 02 / 2016

--- Jayan Liyanage 09 / 02 / 2016
PROCEDURE D_BDL_BANDWIDTH_UPDATE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );
--- Jayan Liyanage 09 / 02 / 2016

--- Jayan Liyanage 2016/01/11
PROCEDURE D_PREMIUM_VPN_MODIFY_FEATURE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2016/01/11

--- Jayan Liyanage 15 / 02 / 2016
 PROCEDURE D_PRE_VPN_NOTIFY(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);     
--- Jayan Liyanage 15 / 02 / 2016

--- Jayan Liyanage 05/11/2015
PROCEDURE FTTH_IPTV_NUMBER_VALIDATE (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Jayan Liyanage 05/11/2015


--- Proboda Chaturanga 12032016
PROCEDURE LTE_UPDATE_CREATE_SIM (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Proboda Chaturanga 12032016

--- Proboda Chaturanga 12032016
PROCEDURE LTE_UPDATE_DEL_SIM (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;

--- Proboda Chaturanga 12032016

--- Proboda Chaturanga 12032016
PROCEDURE LTE_UPDATE_MOD_EQUIP_SIM (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Proboda Chaturanga 12032016

--- Samitha Sagara 20032016
PROCEDURE SLTCC_NEMS_SOFTSWITCH_CHECK (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Samitha Sagara 20032016

--- Samitha Sagara 20032016
PROCEDURE CREDIT_UPDATE_ZTE_MSAN_NODEID (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Samitha Sagara 20032016


--- Samitha Sagara 20032016
PROCEDURE CREDIT_UPDATE_NUMBER_TYPE (
p_serv_id            IN     Services.serv_id%TYPE,
p_sero_id            IN     Service_Orders.sero_id%TYPE,
p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
p_woro_id            IN     work_order.woro_id%TYPE,
p_ret_char              OUT VARCHAR2,
p_ret_number            OUT NUMBER,
p_ret_msg               OUT VARCHAR2) ;
--- Samitha Sagara 20032016



---- Dinesh Perera 2016-03-01 ----
PROCEDURE PLANNED_EVENTS_AUTO_INPROGRESS
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
---- Dinesh Perera 2016-03-01 ----

--Dulip Fernando 05/11/2015
PROCEDURE D_IP_TRK_LIN_ACC_BEA_STA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

--Dulip Fernando 05/11/2015

----- Dulip Fernando  31-08-2015 -----
PROCEDURE D_IP_TRUNK_X_CONN_WG_CHG (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
----- Dulip Fernando  31-08-2015  -----

----- Dulip Fernando  05-08-2015 -----
PROCEDURE D_IP_TR_ACC_BEA_ID_BLANK (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
----- Dulip Fernando  05-08-2015   -----

----- Dulip Fernando  24-08-2015 -----
PROCEDURE D_IP_TR_CP_ATT_BEA_TO_SER (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
----- Dulip Fernando  24-08-2015  -----

----- Dulip Fernando  24-08-2015 -----
PROCEDURE D_IP_TR_CP_ATT_SER_TO_BER (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
----- Dulip Fernando  24-08-2015  -----

----- Dulip Fernando  05-08-2015 -----
PROCEDURE D_IP_TR_WORK_FLOW_01 (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
----- Dulip Fernando  05-08-2015   -----

--- Dulip Fernando  24-08-2015
PROCEDURE D_IP_TR_AGG_NTW_WORK_FLOW1 (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
--- Dulip Fernando  24-08-2015

--- Jayan Liyanage 15 /03/2016
   PROCEDURE I_DNR_SERVICE_DATE_CALC (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 15/03/2016

---- Dinesh Perera 25-04-2016 ----
PROCEDURE PROV_FTTH_IPTV_TASK_LOAD (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2);
---- Dinesh Perera 25-04-2016 ----

--- Prabodha Chathuranga 27/04/2016
PROCEDURE D_WIFI_BCKHAUL_DSP_DELETE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
--- Prabodha Chathuranga 27/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_CREATE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_DELETE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_DELETE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_DELETE_TRANSFER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_MODIFY_EQUIPMENT (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_MODIFY_SPEED (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_RESUME (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_BACK_SUSPEND (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Dilupa Alahakoon  26/04/2016

---Dilupa Alahakoon  26/04/2016
PROCEDURE D_WIFI_MODIFY_LOCATION  (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
---Dilupa Alahakoon  26/04/2016

---kalana Bandara 28/04/2016
PROCEDURE ADDITIONAL_PEOTV_EVENT_UPDATE (
   p_serv_id         IN     services.serv_id%TYPE,
   p_sero_id         IN     service_orders.sero_id%TYPE,
   p_seit_id         IN     service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN     implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2);

---- Dinesh Perera 29-04-2016 ----
PROCEDURE FTTH_PW_GENERATION_MULTI_IPTV (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      
 -- Dhanushka Fernando  05-05-2016
 PROCEDURE MSAN_EQUIP_MODEL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      
  -- Dhanushka Fernando

----Dinesh Perera  29-04-2016  -----
PROCEDURE FTTH_SEC_IPTV_CLOSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      

----Dinesh Perera  29-04-2016  -----
PROCEDURE FTTH_SEC_WAIT_IPTV (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      
---KALANA 15/03/2016
 PROCEDURE MNG_MS_PROV_STATUS
(
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
---KALANA 15/03/2016

PROCEDURE MS_MODIFY_ISP_VLAN2 (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

---21/1/2016 KALANA
PROCEDURE MS_UPDATE_NO_ACTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
---21/1/2016 KALANA
      
END P_SLT_FUNCTIONS_V4;
/
