**FREE
/*********************************************************************/
/* Program : BINDLOGIC                                                */
/* Purpose : Binding Rules & Capacity Logic                           */
/* Source  : Mainframe COBOL Migration                                */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp('INSURANCE')
        option(*nodebugio : *srcstmt);

/*-------------------------------------------------------------------*/
/* Files                                                             */
/*-------------------------------------------------------------------*/
dcl-f AXABIND      usage(*update) keyed;
dcl-f AXAQUOTE     usage(*input)  keyed;
dcl-f AXABINDRULE  usage(*input)  keyed;

/*-------------------------------------------------------------------*/
/* Copybooks                                                         */
/*-------------------------------------------------------------------*/
 /copy QRPGLESRC,BIND_RULES
 /copy QRPGLESRC,BIND
 /copy QRPGLESRC,QUOTE

/*-------------------------------------------------------------------*/
/* Program Parameter (DFHCOMMAREA)                                    */
/*-------------------------------------------------------------------*/
dcl-pi *n;
   pBindKey char(10);
end-pi;

/*-------------------------------------------------------------------*/
/* Working Storage                                                   */
/*-------------------------------------------------------------------*/
dcl-s wsBindKey        char(10);
dcl-s wsCapacityCheck char(1) inz('N');
dcl-s wsApprovalNeeded char(1) inz('N');

/*-------------------------------------------------------------------*/
/* Main Logic                                                        */
/*-------------------------------------------------------------------*/
wsBindKey = pBindKey;

readBindData();
readBindingRules();
checkBindingCapacity();
determineApprovalRequirements();
updateBindingStatus();

*inlr = *on;
return;

/*-------------------------------------------------------------------*/
/* Procedures                                                        */
/*-------------------------------------------------------------------*/
dcl-proc readBindData;

   chain wsBindKey AXABIND;
   if %notfound(AXABIND);
      return;
   endif;

   chain Quote_Id AXAQUOTE;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc readBindingRules;

   chain Carrier_Name AXABINDRULE;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc checkBindingCapacity;

   if Bind_Amount > Capacity_Limit;

      Bind_Status      = 'CAPACITY-EXCEEDED';
      wsCapacityCheck = 'Y';

   else;

      Capacity_Allocated  = Bind_Amount;
      Used_Capacity      += Bind_Amount;
      Available_Capacity  = Carrier_Capacity - Used_Capacity;

      if Carrier_Capacity > 0;
         Capacity_Pct =
           (Used_Capacity / Carrier_Capacity) * 100;
      else;
         Capacity_Pct = 0;
      endif;

      if Capacity_Pct > 90;
         Capacity_Status = 'CAPACITY-WARNING';
      else;
         Capacity_Status = 'CAPACITY-OK';
      endif;

   endif;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc determineApprovalRequirements;

   if Bind_Amount > Max_Premium
      or Approval_Required = 'Y'
      or wsCapacityCheck = 'Y';

      Approval_Status   = 'APPROVAL-REQUIRED';
      wsApprovalNeeded = 'Y';

   else;

      if Auto_Bind_Flag = 'Y';
         Approval_Status = 'AUTO-APPROVED';
         Bind_Status     = 'APPROVED';
      else;
         Approval_Status = 'MANUAL-REVIEW';
      endif;

   endif;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc updateBindingStatus;

   if wsApprovalNeeded = 'Y';

      Bind_Status = 'PENDING-APPROVAL';

   else;

      if Auto_Bind_Flag = 'Y';
         Bind_Status = 'READY-TO-BIND';
      endif;

   endif;

   /* Commission Calculation */
   Commission_Amount =
      Bind_Amount * Commission_Rate / 100;

   update AXABIND;

end-proc;
