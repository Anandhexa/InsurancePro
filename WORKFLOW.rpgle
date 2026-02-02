**free
ctl-opt dftactgrp(*no) actgrp(*caller);

/*------------------------------------------------------------------*/
/* Files                                                             */
/*------------------------------------------------------------------*/
dcl-f AXASUBM usage(*update) keyed;

/*------------------------------------------------------------------*/
/* Parameters (COMMAREA equivalent)                                  */
/*------------------------------------------------------------------*/
dcl-pi *n;
   pSubmissionKey char(10);
end-pi;

/*------------------------------------------------------------------*/
/* Working Storage                                                   */
/*------------------------------------------------------------------*/
dcl-s CurrentDate date;
dcl-s DueDate     date;

/*------------------------------------------------------------------*/
/* Main Logic                                                        */
/*------------------------------------------------------------------*/

chain pSubmissionKey AXASUBM SubmissionRec;
if not %found(AXASUBM);
   return;
endif;

processWorkflowState();
update AXASUBM SubmissionRec;

return;

/*------------------------------------------------------------------*/
/* Process Workflow State                                            */
/*------------------------------------------------------------------*/
dcl-proc processWorkflowState;

   select;
      when SubmissionRec.WORKFLOW_STATE = 'NEW';
         transitionToReview();

      when SubmissionRec.WORKFLOW_STATE = 'REVIEW';
         transitionToPricing();

      when SubmissionRec.WORKFLOW_STATE = 'PRICING';
         transitionToSubmission();

      when SubmissionRec.WORKFLOW_STATE = 'SUBMISSION-SENT';
         transitionToQuotes();

      when SubmissionRec.WORKFLOW_STATE = 'QUOTES-RECEIVED';
         transitionToBinding();

      other;
         SubmissionRec.WORKFLOW_STATE = 'UNKNOWN-STATE';
   endsl;

end-proc;

/*------------------------------------------------------------------*/
/* Workflow Transitions                                              */
/*------------------------------------------------------------------*/
dcl-proc transitionToReview;
   SubmissionRec.WORKFLOW_STATE = 'REVIEW';
   SubmissionRec.ASSIGNED_USER  = 'UNDERWRITER';
   calculateDueDate();
end-proc;

dcl-proc transitionToPricing;
   SubmissionRec.WORKFLOW_STATE = 'PRICING';
   SubmissionRec.ASSIGNED_USER  = 'PRICING-ANALYST';
   calculateDueDate();
end-proc;

dcl-proc transitionToSubmission;
   SubmissionRec.WORKFLOW_STATE = 'SUBMISSION-READY';
   SubmissionRec.ASSIGNED_USER  = 'BROKER';
   calculateDueDate();
end-proc;

dcl-proc transitionToQuotes;
   SubmissionRec.WORKFLOW_STATE = 'AWAITING-QUOTES';
   SubmissionRec.ASSIGNED_USER  = 'SYSTEM';
   calculateDueDate();
end-proc;

dcl-proc transitionToBinding;
   SubmissionRec.WORKFLOW_STATE = 'BINDING-READY';
   SubmissionRec.ASSIGNED_USER  = 'BROKER';
   calculateDueDate();
end-proc;

/*------------------------------------------------------------------*/
/* SLA Due Date Calculation                                          */
/*------------------------------------------------------------------*/
dcl-proc calculateDueDate;

   CurrentDate = %date();

   select;
      when SubmissionRec.WORKFLOW_STATE = 'REVIEW';
         DueDate = CurrentDate + %days(2);

      when SubmissionRec.WORKFLOW_STATE = 'PRICING';
         DueDate = CurrentDate + %days(1);

      when SubmissionRec.WORKFLOW_STATE = 'SUBMISSION-READY';
         DueDate = CurrentDate + %days(3);

      when SubmissionRec.WORKFLOW_STATE = 'AWAITING-QUOTES';
         DueDate = CurrentDate + %days(7);

      when SubmissionRec.WORKFLOW_STATE = 'BINDING-READY';
         DueDate = CurrentDate + %days(2);

      other;
         DueDate = CurrentDate + %days(5);
   endsl;

   SubmissionRec.SLA_DUE_DATE = DueDate;

end-proc;

