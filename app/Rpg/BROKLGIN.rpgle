ctl-opt dftactgrp(*no) actgrp(*new);

/*--------------------------------------------------------------
** Input / Output Fields
**--------------------------------------------------------------*/
dcl-s UserID          char(10);
dcl-s Password        char(10);
dcl-s LoginStatus     char(10);
dcl-s MessageText     char(50);

/*--------------------------------------------------------------
** Control Flags
**--------------------------------------------------------------*/
dcl-s IsAuthenticated ind inz(*off);

/*==============================================================
** Main Program Flow
**==============================================================*/
exsr LoadInput;
exsr ValidateLogin;
exsr SetLoginResult;
exsr DisplayResult;

*inlr = *on;
return;

/*==============================================================
** Load Login Input
**==============================================================*/
begsr LoadInput;

   UserID   = 'RGARCIA';
   Password = 'BROKER01';

endsr;

/*==============================================================
** Validate Login Credentials
**==============================================================*/
begsr ValidateLogin;

   IsAuthenticated = *off;

   if UserID = 'RGARCIA'
      and Password = 'BROKER01';

      IsAuthenticated = *on;

   endif;

endsr;

/*==============================================================
** Set Login Result
**==============================================================*/
begsr SetLoginResult;

   if IsAuthenticated;
      LoginStatus = 'SUCCESS';
      MessageText = 'LOGIN SUCCESSFUL';
   else;
      LoginStatus = 'FAILED';
      MessageText = 'INVALID USER ID OR PASSWORD';
   endif;

endsr;

/*==============================================================
** Display Result
**==============================================================*/

begsr DisplayResult;

   dsply ('USER ID : ' + UserID);
   dsply ('STATUS  : ' + LoginStatus);
   dsply ('MESSAGE : ' + MessageText);

   if LoginStatus = 'SUCCESS';
      dsply ('NAVIGATE TO BROKER PIPELINE');
   else;
      dsply ('RETURN TO LOGIN SCREEN');
   endif;

endsr;
