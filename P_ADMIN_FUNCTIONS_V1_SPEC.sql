CREATE OR REPLACE PACKAGE CLARITY_ADMIN.P_ADMIN_FUNCTIONS_V1 AS
/******************************************************************************
   NAME:       P_SLT_FUNCTIONS_V4
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/2/2014      Sasith       1. Created this package.
******************************************************************************/

--- 19-06-2013  Sasith  
 PROCEDURE IPTV_TITANIUM_PKG_OPMC_EMAIL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
  
--- 19-06-2013  Sasith

END P_ADMIN_FUNCTIONS_V1;
/
