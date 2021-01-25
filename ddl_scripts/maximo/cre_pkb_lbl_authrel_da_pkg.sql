CREATE OR REPLACE PACKAGE lbl_authrel_da_pkg
IS

/*****************************************************************************
 PROGRAM NAME           : CRE_PKS_LBL_AUTHREL_DA_PKG

 DATE WRITTEN           : 07-DEC-2012

 AUTHOR                 : PANKAJ BHIDE

 PURPOSE                : PACKAGE SPEC FOR AUTH RELEASE WEB APPLICATION
*****************************************************************************/

TYPE RCDATA
IS REF CURSOR;

TYPE T_RESULSET
IS REF CURSOR;

   --PROCEDURE GET_COMMASEP_LIST
   -- P_TYPE INDICATES WHAT TO SEPARATE (BLDG, ROOM ETC.)
   FUNCTION GET_COMMASEP_LIST
   (
    P_SEQ_LOCATIONS   IN VARCHAR2,
    P_USERID          IN VARCHAR2,
    P_TYPE            IN LBL_AUTH_RELEASE.LOCATION%TYPE
    )

    RETURN VARCHAR2;

    --PROCEDURE COMMA SEPARATED LIST OF
   -- AUTHORIZERS FOR THE GIVEN LOCATION
   FUNCTION GET_COMMASEP_AUTHORIZERS
   (
    P_LOCATIONS LOCATIONS.LOCATION%TYPE
   )
    RETURN VARCHAR2;


   -- GET LBNL BUILDINGS
   PROCEDURE GET_BUILDINGS
   (
    P_RESULTSET OUT RCDATA
   );

   -- GET FLOORS FOR BUILDING
   PROCEDURE GET_FLOORS
   (
    P_BUILDING   IN LBL_AUTH_RELEASE.BUILDING_NUMBER%TYPE,
    P_RESULTSET OUT RCDATA
   );

   -- GET ROOMS FOR BUILDING AND FLOOR
   PROCEDURE GET_ROOMS
   (
    P_BUILDING   IN LBL_AUTH_RELEASE.BUILDING_NUMBER%TYPE,
    P_FLOOR      IN LBL_AUTH_RELEASE.FLOOR_NUMBER%TYPE,
    P_RESULTSET OUT RCDATA
   );

    -- GET LBNL DIVISIONS (ORG_LEVEL_1)
    PROCEDURE GET_DIVISIONS
   (
     P_RESULTSET OUT RCDATA
    );

   -- GET LBNL DIVISIONS (ORG_LEVEL_1) TO WHICH THE GIVEN USER IS
   -- AUTHORIZED
    PROCEDURE GET_USER_DIVISIONS
   (
     P_USERID    IN  PERSON.PERSONID%TYPE,
     P_RESULTSET OUT RCDATA
   );

   -- BASED UPON THE USER, GET LIST OF USERS AUTHORIZRED
   -- TO ACCESS THE APPLICATION
   PROCEDURE GET_USERS
   (
    P_USERID    IN  LBL_WEBAPP_USERS.USERID%TYPE,
    P_RESULTSET OUT RCDATA
   );

   -- GET ROOM DETAILS BASED UPON THE SEARCH CRITERIA
   -- SPECIFIED BY THE USER
   PROCEDURE GET_ROOM_DETAILS
   (
   P_BUILDING   IN LBL_AUTH_RELEASE.BUILDING_NUMBER%TYPE,
   P_FLOOR      IN LBL_AUTH_RELEASE.FLOOR_NUMBER%TYPE,
   P_ROOM       IN LBL_AUTH_RELEASE.ROOM_NUMBER%TYPE,
   P_DIVISION   IN CRAFT.LBL_ORG_LEVEL_1%TYPE,
   P_PERSONID   IN LBL_AUTH_RELEASE.PERSONID%TYPE,
   P_USERLOGIN  IN PERSON.PERSONID%TYPE,
   P_RESULTSET OUT T_RESULSET
   );

    -- FUNCTION TO GET COMBINED VALUE RELEASE REQUIRED FOR
    -- ALL THE ROOMS IN THE SELECTION
    FUNCTION GET_RELREQD_COMBINED
   (
    P_SEQ_LOCATIONS   IN VARCHAR2,
    P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;


    -- FUNCTION TO GET COMBINED VALUE OF ESCORT REQD FOR
    -- ALL THE ROOMS IN THE SELECTION
    FUNCTION GET_ESCORTREQD_COMBINED
   (
    P_SEQ_LOCATIONS   IN VARCHAR2,
    P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;

    -- FUNCTION TO GET COMBINED VALUE OF CONDITIONAL RELEASE FOR
    -- ALL THE ROOMS IN THE SELECTION
    FUNCTION GET_CONDREL_COMBINED
   (
     P_SEQ_LOCATIONS   IN VARCHAR2,
     P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;

     -- FUNCTION TO GET COMBINED VALUE OF CONDITIONAL RELEASE COMMENTS FOR
    -- ALL THE ROOMS IN THE SELECTION
    FUNCTION GET_CONDRELCOMMENT_COMB
   (
     P_SEQ_LOCATIONS   IN VARCHAR2,
     P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;


    -- FUNCTION TO GET COMBINED VALUE OF ROOM TYPE
    -- ALL THE ROOMS IN THE SELECTION
   FUNCTION GET_ROOMTYPE_COMBINED
   (
     P_SEQ_LOCATIONS   IN VARCHAR2,
     P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;

    -- FUNCTION TO FIND OUT COMBINED VALUE OF CURRENT USE
    -- ALL THE ROOMS IN THE SELECTION
   FUNCTION GET_CURRENTUSE_COMBINED
   (
     P_SEQ_LOCATIONS   IN VARCHAR2,
     P_USERID          IN VARCHAR2
   )
    RETURN  VARCHAR2;


    -- PROCEDURE TO GET AUTHORIZER INFORMATION FOR THE
    -- SELECTED ROOMS
   PROCEDURE GET_ROOMS_AUTHINFO
   (
     P_SEQ_LOCATIONS   IN VARCHAR2,
     P_USERID          IN VARCHAR2,
     P_RESULTSET   OUT RCDATA
   ) ;

   -- PROCEDURE TO GET USER TOKEN
   -- IF VALID TOKEN FOUND THEN REFRESH THE LAST USED DATE
   PROCEDURE GET_USER_TOKEN
   (
   P_PERSONID IN   PERSON.PERSONID%TYPE,
   P_TOKENID  OUT  BATCH_MAXIMO.LBL_USER_TOKENS.TOKENID%TYPE
   );


   -- FUNCTION TO FUND WHETHER THE USER IS AUTHORIZED
   -- FOR THE GIVEN DIVISION
   FUNCTION IS_USERAUTH4DIV
   (
     P_USERLOGIN   PERSON.PERSONID%TYPE,
     P_USERID      PERSON.PERSONID%TYPE,
     P_ORG_LEVEL_1 LBL_WEBAPP_USERS.ORG_LEVEL_1%TYPE
    )
    RETURN  VARCHAR2;


   -- FUNCTION TO FIND  WHETHER THE USER RECORD
   -- CAN BE DELETED FROM LBL_WEBAPP_USERS TABLE
   FUNCTION CAN_DELETE_USER
   (
     P_USERLOGIN   PERSON.PERSONID%TYPE,
     P_USERID      PERSON.PERSONID%TYPE,
     P_ORG_LEVEL_1 LBL_WEBAPP_USERS.ORG_LEVEL_1%TYPE
    )
    RETURN  VARCHAR2;


   -- FUNCTION TO FIND WHETHER THE COMBINATION OF
   -- USER AND DIVISION IS UNIQUE IN LBL_WEBAPP_USERS
   -- TABLE
   FUNCTION IS_USER_DIV_UNIQUE
   (
     P_USERID      PERSON.PERSONID%TYPE,
     P_ORG_LEVEL_1 LBL_WEBAPP_USERS.ORG_LEVEL_1%TYPE
    )
    RETURN  VARCHAR2;

   -- FUNCTION TO FIND OUT THE COMPBATION OF LOCATION AND EMPLOYEE
   -- ID IS UNIQUE FOR THE RECORD
   FUNCTION LOC_EMP_UNIQUE
   (
    P_LOCATION IN VARCHAR2,
    P_EMPLOYEE_ID IN VARCHAR2
   )
   RETURN VARCHAR2;

  -- FUNCTION TO FIND WHETHER THE EMPLOYEE STATUS
  -- IS VALID OR NOT
  FUNCTION VALID_EMPLOYEE
  (
    P_EMPLOYEE_ID IN VARCHAR2
  )
   RETURN VARCHAR2;

  -- FUNCTION TO FIND OUT USERS
  -- AUTH PRIVILEDGE (ADMIN OR NON-ADMIN)
  FUNCTION GET_USER_AUTH
  (
      P_EMPLOYEE_ID IN VARCHAR2
  ) RETURN VARCHAR2;

  -- BASED UPON THE FILTER (E.G. LAST NAME) PROVIDED BY THE
  -- USER RETURN LIST OF EMPLOYEES MATCHING THE FILTER
  PROCEDURE FILTER_EMPLOYEES
  (
    P_FILTER IN VARCHAR2,
    P_RESULTSET OUT RCDATA
   )  ;


  -- FUNCTION TO FIND WHETHER LBL_AUTH_RELEASE
  -- ROW ID IS PRIMARY OR NOT
  FUNCTION IS_AUTH_PRIMARY4LOC
  (
    P_LOCATION_ID IN VARCHAR2
  )
   RETURN VARCHAR2;

   -- PROCEDURE TO GET THE INFORMATION ABOUT
   -- SPECIFIED USER ID
   PROCEDURE GET_USER_INFO
   (
       P_USERID      IN VARCHAR2,
       P_USER_INFO   OUT RCDATA
    );

   -- FUNCTION TO FIND OUT DOMAIN DESCRIPTION
   FUNCTION GET_DOMAIN_DESCRIPTION
   (
    P_DOMAINID   IN ALNDOMAIN.DOMAINID%TYPE,
    P_VALUE      IN ALNDOMAIN.VALUE%TYPE
   )
    RETURN  VARCHAR2;

   -- FUNCTION TO FIND OUT WHETHER THE USER
   -- CAN CHANGE THE ROOM RECORD
   FUNCTION CAN_USER_EDIT_ROOM
   (
    P_PERSONID      IN LBL_AUTH_RELEASE.PERSONID%TYPE,
    P_LOCATION      IN LOCATIONS.LOCATION%TYPE
   )
    RETURN  VARCHAR2;

  -- PROCEDURE TO INSERT RECORDS RELATED TO
  -- EMAILS SENT FROM USERS
  PROCEDURE LOG_EMAILS
  (
    P_USERID        IN LBL_AUTH_RELEASE.PERSONID%TYPE,
    P_ADDRESSEDTO   IN WORKORDER.DESCRIPTION%TYPE,
    P_EMAILTEXT     IN BATCH_MAXIMO.LBL_EMAIL_LOG.MESSAGE_TEXT%TYPE,
    P_RECEIVEREMAIL OUT BATCH_MAXIMO.LBL_EMAIL_LOG.RECEIVER%TYPE,
    P_SENDEREMAIL   OUT EMAIL.EMAILADDRESS%TYPE,
    P_SENDERNAME    OUT PERSON.DISPLAYNAME%TYPE,
    P_ENVIRONMENT   OUT VARCHAR2,
    P_ERROR_CODE    OUT VARCHAR2,
    P_ERROR_MSG     OUT VARCHAR2
   )  ;


   -- UTILITY FUNCTION THAT SPLITS THE STRING WITH COMMAS
   FUNCTION SPLITBYCOMMA
   (
     P_INPUT   IN VARCHAR2
    )
   RETURN  VARCHAR2;

   -- PROCEDURE TO RETRIEVE EMPLOYEE RELATED INFORMATION
   PROCEDURE SP_EMPLOYEE_DATA_SEL
   (P_EMPLOYEE_ID IN VARCHAR2,
    --P_RESULTSET OUT PKG_RESULSET.T_RESULSET);
    P_RESULTSET OUT lbl_authrel_da_pkg.T_RESULSET);


  -- GET NEXT SEQUENCE NUMBER FOR INSERTING
  -- RECORD INTO LBL_SELECTED_LOCS TABLE
   FUNCTION GET_SEQ_SELECTED_LOCS
   RETURN  VARCHAR2;

  -- PROCEDURE TO INSERT SELECTED LOCATION
  -- RECORD INTO LBL_SELECTED_LOCS TABLE
   PROCEDURE INS_LBL_SELECTED_LOCS
   (P_EMPLOYEE_ID      IN VARCHAR2,
    P_SEQ_SELECTED_LOC IN VARCHAR2,
    P_LOCATION         IN LOCATIONS.LOCATION%TYPE);


  FUNCTION SHOW_DATABASE
   RETURN  VARCHAR2;


  -- FUNCTION THAT RETURNS EMAIL ADDRESS SAFETYY
  -- COORDINATORS FOR A GIVEN DIVISION. IF THE * IS
  -- PASSED FOR A GIVEN DIVISION, THEN, IT RETURNS
  -- THE EMAIL ADDRESS OF ALL SUPER USERS
   FUNCTION GETEMAIL4SAFETYSTAFF
   (
     P_DIVISION IN VARCHAR2,
     P_APPENV   IN VARCHAR2
    )
   RETURN  VARCHAR2;


  -- FUNCTION THAT RETURNS WHTHER THE TOKEN IS VALID
  -- OR NOT
  FUNCTION ISUSERTOKENVALID
   (
     P_EMPLOYEE_ID IN VARCHAR2,
     P_TOKEN       IN VARCHAR2,
     P_WEBAPP      IN VARCHAR2
    )
   RETURN  VARCHAR2;

  -- *************************************
  -- PROCEDRE TO REFRESH LBL_AUTH_REL ROWS
  -- *************************************
  PROCEDURE REFRESHAUTHRELEASE
  (
    P_PERSONID     IN VARCHAR2,
    P_TOKEN        IN VARCHAR2,
    P_WEBAPP       IN VARCHAR2,
    P_LOCATIONS    IN VARCHAR2,
    P_RELREQD      IN VARCHAR2,
    P_ESCORTREQD   IN VARCHAR2,
    P_CONDRELEASE  IN VARCHAR2,
    P_COMMENTCONDR IN VARCHAR2,
    P_PERSONS      IN VARCHAR2,
    P_RETURN_CODE OUT NUMBER,
    P_RETURN_TEXT OUT VARCHAR2);

 -- *************************************
  -- PROCEDRE TO REFRESH WEBAPPUSERS ROWS
  -- *************************************
  PROCEDURE REFRESHWEBAPPUSERS
  (
    P_PERSONID     IN VARCHAR2,
    P_USERID       IN VARCHAR2,
    P_TOKEN        IN VARCHAR2,
    P_WEBAPP       IN VARCHAR2,
    P_ORG_LEVEL_1  IN VARCHAR2,
    P_ORG_LEVEL_2  IN VARCHAR2,
    P_MODE         IN VARCHAR2,
    P_RETURN_CODE OUT NUMBER,
    P_RETURN_TEXT OUT VARCHAR2);

  ---********************************************
  -- FUNCTION TO CHECK WHETHER
  -- EMPLOYEE IS AUTHORIZED TO RELEASE OR NOT
  --*********************************************
  FUNCTION ISAUTHORIZEDRELEASE
   (
     P_EMPLOYEE_ID IN VARCHAR2
   )
   RETURN  VARCHAR2;

  /* CONSIDERED OBSOLETE TO BE DELETED LATER

   PROCEDURE SP_USER_DELETE
   (
   P_USERUID IN LBL_WEBAPP_USERS.LBL_WEBAPP_USERSID%TYPE,
   P_RETURN_CODE OUT NUMBER,
   P_RETURN_TEXT OUT VARCHAR2);


   PROCEDURE SP_USER_ADD
   (
   P_USERID IN LBL_WEBAPP_USERS.USERID%TYPE,
   P_ORG_LEVEL_1 IN LBL_WEBAPP_USERS.ORG_LEVEL_1%TYPE,
   P_RETURN_CODE OUT NUMBER,
   P_RETURN_TEXT OUT VARCHAR2
   );


   FUNCTION GET_USER_ROLES
    (
        P_USER_ID IN VARCHAR2
    )
    RETURN VARCHAR2;

   PROCEDURE SP_AUTHREL_SINGLESEL
   (
     P_AUTHRELEASEID  IN LBL_AUTH_RELEASE.LBL_AUTH_RELEASEID%TYPE,
     P_RESULTSET    OUT RCDATA
   );

   PROCEDURE SP_AUTHREL_REFRESH
   (
     P_LOCATIONS IN VARCHAR2,
     P_REL_REQD  IN LOCATIONS.LBL_REL_REQD%TYPE,
     P_AUTH_INFO IN VARCHAR2,
     P_USERID    IN VARCHAR2,
     P_RETURN_CODE OUT NUMBER,
     P_RETURN_TEXT OUT VARCHAR2);

     */

  -- ***********************************************
  -- PROCEDRE TO GET WORK ORDERS WHOSE STATUS=WREL
  -- *********************************************
  FUNCTION GETWORKORDERSWREL
  (
    P_PERSONID     IN VARCHAR2
   )
    RETURN  LONGDESCRIPTION.LDTEXT%TYPE;




END LBL_AUTHREL_DA_PKG;
