**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Copy books (equivalent to COBOL COPY statements)                */
/*----------------------------------------------------------------*/
 /copy rules
 /copy submissn
 /copy product

/*----------------------------------------------------------------*/
/* File declarations                                              */
/*----------------------------------------------------------------*/
dcl-f AXASUBM usage(*update:*input) keyed;
dcl-f AXAPROD usage(*input) keyed;

/*----------------------------------------------------------------*/
/* Entry parameters (DFHCOMMAREA equivalent)                       */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsSubmissionKey char(10);
dcl-s wsRuleCount packed(2:0) inz(0);
dcl-s wsRulesFired packed(2:0) inz(0);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsSubmissionKey = %subst(pCommArea:1:10);

readSubmissionData();
executeBusinessRules();
updateRuleStatus();

return;

/*----------------------------------------------------------------*/
/* Read submission and product                                    */
/*----------------------------------------------------------------*/
dcl-proc readSubmissionData;
   chain wsSubmissionKey AXASUBM;
   if %notfound(AXASUBM);
      return;
   endif;

   chain Product_ID AXAPROD;
end-proc;

/*----------------------------------------------------------------*/
/* Execute business rules                                         */
/*----------------------------------------------------------------*/
dcl-proc executeBusinessRules;
   checkSubmissionCompleteness();
   checkProductLimits();
   checkRegulatoryCompliance();
   checkRiskAssessment();
end-proc;

/*----------------------------------------------------------------*/
/* Rule: submission completeness                                  */
/*----------------------------------------------------------------*/
dcl-proc checkSubmissionCompleteness;
   if Submission_Date = *blanks
      or Valid_Until_Date = *blanks
      or Broker_Ref = *blanks;

      Business_Rule_Status = 'INCOMPLETE';
      wsRulesFired += 1;
   endif;
end-proc;

/*----------------------------------------------------------------*/
/* Rule: product limits                                           */
/*----------------------------------------------------------------*/
dcl-proc checkProductLimits;
   if Coverage_Limit > 10000000;
      Priority_Level = 'HIGH';
      wsRulesFired += 1;

   elseif Coverage_Limit > 1000000;
      Priority_Level = 'MEDIUM';

   else;
      Priority_Level = 'LOW';
   endif;
end-proc;

/*----------------------------------------------------------------*/
/* Rule: regulatory compliance                                    */
/*----------------------------------------------------------------*/
dcl-proc checkRegulatoryCompliance;
   if Product_Type = 'CYBER'
      or Product_Type = 'DIRECTORS';

      Workflow_State = 'REGULATORY-REVIEW';
      Escalation_Flag = 'Y';
      wsRulesFired += 1;
   endif;
end-proc;

/*----------------------------------------------------------------*/
/* Rule: risk assessment                                          */
/*----------------------------------------------------------------*/
dcl-proc checkRiskAssessment;
   if Deductible < (Coverage_Limit * 0.01);
      Workflow_State = 'RISK-REVIEW';
      wsRulesFired += 1;
   endif;
end-proc;

/*----------------------------------------------------------------*/
/* Update rule status and rewrite submission                      */
/*----------------------------------------------------------------*/
dcl-proc updateRuleStatus;
   if wsRulesFired > 0;
      Business_Rule_Status = 'RULES-APPLIED';
   else;
      Business_Rule_Status = 'NO-RULES-FIRED';
   endif;

   Validation_Score = 100 - (wsRulesFired * 10);

   update AXASUBM;
end-proc;
