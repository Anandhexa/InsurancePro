**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPOLICY usage(*update) keyed;
dcl-f AXAQUOTE  usage(*input)  keyed;
dcl-f AXASUBM   usage(*input)  keyed;
dcl-f POLICYDSPF workstn;

/*----------------------------------------------------------------*/
/* Copy books (COBOL COPY POLICY / QUOTE / SUBMISSN)               */
/*----------------------------------------------------------------*/
 /copy POLICY
 /copy QUOTE
 /copy SUBMISSN

/*----------------------------------------------------------------*/
/* Entry parameter (DFHCOMMAREA equivalent)                        */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsPolicyKey     char(15);
dcl-s wsPolicyCounter packed(8:0) inz(10000001);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsPolicyKey = %subst(pCommArea:1:15);

if %trim(wsPolicyKey) <> '';
   readPolicy();
else;
   newPolicy();
endif;

sendMap();
return;

/*----------------------------------------------------------------*/
/* Read existing policy                                           */
/*----------------------------------------------------------------*/
dcl-proc readPolicy;

   chain wsPolicyKey AXAPOLICY;

   if not %found(AXAPOLICY);
      newPolicy();
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Create new policy from quote                                   */
/*----------------------------------------------------------------*/
dcl-proc newPolicy;

   clear POLICY_RECORD;

   Quote_ID = %subst(pCommArea:1:10);
   readQuoteData();
   buildPolicyFromQuote();

end-proc;

/*----------------------------------------------------------------*/
/* Read quote and submission                                      */
/*----------------------------------------------------------------*/
dcl-proc readQuoteData;

   chain Quote_ID AXAQUOTE;
   if not %found(AXAQUOTE);
      return;
   endif;

   chain Submission_ID AXASUBM;

end-proc;

/*----------------------------------------------------------------*/
/* Build policy from quote                                        */
/*----------------------------------------------------------------*/
dcl-proc buildPolicyFromQuote;

   Policy_ID =
      'POL' + %char(wsPolicyCounter);

   wsPolicyCounter += 1;

   Policy_Number =
      'AXA-' +
      %char(%date():*ISO0) + '-' +
      %char(wsPolicyCounter);

   Submission_ID     = Submission_ID;
   Quote_ID          = Quote_ID;
   Carrier_Name      = Carrier_Name;
   Total_Premium     = Total_Premium;
   Commission_Rate   = Commission_Rate;
   Commission_Amount = Commission_Amount;
   Policy_Limit      = Limit;
   Deductible        = Attach_Point;

   Policy_Status     = 'ACTIVE';
   Renewal_Flag      = 'N';
   Created_Date      = %char(%date():*ISO0);
   Last_Modified     = %timestamp();

end-proc;

/*----------------------------------------------------------------*/
/* ENTER – Save policy                                            */
/*----------------------------------------------------------------*/
dcl-proc savePolicy;

   /* EXFMT POLICYMP would populate input fields */

   buildPolicyRecord();
   write AXAPOLICY;

   sendMap();

end-proc;

/*----------------------------------------------------------------*/
/* Build policy record from screen                                */
/*----------------------------------------------------------------*/
dcl-proc buildPolicyRecord;

   Insured_Name    = INSNAMEI;
   Policy_Type     = POLTYPEI;
   Inception_Date  = INCEPDTI;
   Expiry_Date     = EXPIRDTI;
   Broker_Name     = BROKERI;

   Last_Modified   = %timestamp();

end-proc;

/*----------------------------------------------------------------*/
/* Send display                                                   */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   POLICYIDO = Policy_ID;
   POLNUMO   = Policy_Number;
   INSNAMEO = Insured_Name;
   POLTYPEO = Policy_Type;
   INCEPDTO = Inception_Date;
   EXPIRDTO = Expiry_Date;
   POLIMITO = Policy_Limit;
   PREMIUMO = Total_Premium;
   POLSTSO  = Policy_Status;

   /* EXFMT POLICYMP */

end-proc;

/*----------------------------------------------------------------*/
/* PF1 – Policy amendments                                       */
/*----------------------------------------------------------------*/
dcl-proc policyAmendments;

   pCommArea = Policy_ID + %subst(pCommArea:16);
   callp POLAMEND(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* PF2 – Policy renewal                                          */
/*----------------------------------------------------------------*/
dcl-proc policyRenewal;

   pCommArea = Policy_ID + %subst(pCommArea:16);
   callp POLRENEW(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Return dashboard                                        */
/*----------------------------------------------------------------*/
dcl-proc returnDashboard;

   callp QUOTEDASH(pCommArea);

end-proc;
