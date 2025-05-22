CREATE OR REPLACE PACKAGE CLARITY_ADMIN.p_employee AS
-- ===========================================================================
-- PACKAGE: $Workfile: p_employee_spec.pso.sql$
-- DEPENDS: clarity_admin (user)
-- VERSION: $Revision: 4$
--
-- Copyright Clarity International Pty Limited 2001
--
-- This file contains a package specification for a single package, and the
-- grants necessary for execution.
--
-- ===========================================================================


  Type EmployeeUserIDType is table of Employees.EMPE_USERID%TYPE index by binary_integer;

  FUNCTION create_user (
    p_empe_userid IN Varchar2,
    p_empe_profile IN Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN boolean;

  FUNCTION drop_user (
    p_empe_userid IN Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN boolean;

  FUNCTION enable_user (
    p_empe_userid IN Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN boolean;

  FUNCTION disable_user (
    p_empe_userid IN Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN boolean;

  FUNCTION grant_access (
    p_empe_userid IN Varchar2,
    p_role     IN Varchar2,
    p_grant    IN    Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN boolean;


   --
   -- Overloaded Function
   --
   Function copyEmployeeDetails(p_fromUser       IN    EMPLOYEES.EMPE_USERID%TYPE,
                                p_toUser         IN    EMPLOYEES.EMPE_USERID%TYPE,
                                p_workGroupFlag  IN    Boolean,
                                p_visibilityFlag IN    Boolean,
                                p_roleFlag       IN    Boolean,
                                p_ret_message    OUT   Varchar2) Return Boolean;


   --
   -- Overloaded Function
   --
   Function copyEmployeeDetails(p_fromUser       IN    EMPLOYEES.EMPE_USERID%TYPE,
                                p_toUsers        IN    EmployeeUserIDType,
                                p_workGroupFlag  IN    Boolean,
                                p_visibilityFlag IN    Boolean,
                                p_roleFlag       IN    Boolean,
                                p_ret_message    OUT   Varchar2) Return Boolean;


  PROCEDURE f_dummy;





FUNCTION jdbc_grant_access (
    p_empe_userid IN Varchar2,
    p_role     IN Varchar2,
    p_grant    IN    Varchar2,
    p_ret_message    OUT   Varchar2
  ) RETURN integer;

FUNCTION jdbc_create_user( p_empe_userid IN VARCHAR2, p_empe_profile IN VARCHAR2, p_ret_message OUT VARCHAR2 )
      RETURN INTEGER;

FUNCTION jdbc_disable_user( p_empe_userid IN VARCHAR2,  p_ret_message OUT VARCHAR2 )
      RETURN INTEGER;

FUNCTION jdbc_enable_user( p_empe_userid IN VARCHAR2,  p_ret_message OUT VARCHAR2 )
      RETURN INTEGER;

FUNCTION encrypt_password( password IN VARCHAR2)
    RETURN VARCHAR2;









END p_employee;
/
