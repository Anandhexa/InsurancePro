**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-f AXACLAIMS usage(*update:*output) keyed;
dcl-f AXAPOLICY usage(*input) keyed;
dcl-f CLAIMS workstn;

dcl-s wsClaimKey      char(15);
dcl-s wsClaimCounter  packed(8:0) inz(20000001);
dcl-s wsUpdateFlag    char(1) inz('N');

dcl-s currentDate     char(8);
dcl-s currentTS       timestamp;

dcl-pi *n;
   commArea char(100);
end-pi;


// =========================
// MAIN
// =========================

wsClaimKey = %subst(commArea:1:15);

if %trim(wsClaimKey) <> '';
   chain wsClaimKey AXACLAIMS;
   if %found(AXACLAIMS);
      wsUpdateFlag = 'Y';
   else;
      exsr NewClaim;
   endif;
endif;

exsr SendScreen;

*inlr = *on;
return;


// =========================
// NEW CLAIM
// =========================
begsr NewClaim;

   clear AXACLAIMS;

   POLICYID = %subst(commArea:1:15);

   chain POLICYID AXAPOLICY;
   if %found(AXAPOLICY);

      CLAIMID = 'CLM' + %char(wsClaimCounter);
      wsClaimCounter += 1;

      currentDate = %char(%date():*iso0);
      currentTS   = %timestamp();

      CLAIMNUMBER =
         'CLAIM-' +
         %subst(currentDate:1:8) +
         '-' +
         %char(wsClaimCounter);

      INSUREDNAME  = INSUREDNAME;  // from policy
      CARRIERNAME  = CARRIERNAME;
      CLAIMSTATUS  = 'REPORTED';
      REPORTEDDATE = currentDate;
      CREATEDDATE  = currentDate;
      LASTMODIFIED = currentTS;

   endif;

endsr;


// =========================
// SEND / RECEIVE SCREEN
// =========================
begsr SendScreen;

   CLAIMIDO = CLAIMID;
   CLMNUMO  = CLAIMNUMBER;
   INSNAMEO = INSUREDNAME;
   CLMTYPEO = CLAIMTYPE;
   LOSSDTO  = LOSSDate;
   CLMAMTO  = CLAIMAMOUNT;
   RESERVEO = RESERVEAMOUNT;
   PAIDO    = PAIDAMOUNT;
   OUTSTO   = OUTSTANDINGAMOUNT;
   CLMSTSO  = CLAIMSTATUS;

   exfmt CLAIMMP;

   select;
      when *in01;   // F1
         commArea = CLAIMID;
         call 'CLMINVEST' commArea;

      when *in02;   // F2
         commArea = CLAIMID;
         call 'CLMSETTLE' commArea;

      when *in03;   // F3
         commArea = POLICYID;
         call 'POLICY' commArea;

      when *in12;   // F12 Refresh
         exsr SendScreen;

      other;
         exsr SaveClaim;
   endsl;

endsr;


// =========================
// SAVE CLAIM
// =========================
begsr SaveClaim;

   CLAIMTYPE        = CLMTYPEI;
   LOSSDate         = LOSSDTI;
   LOSSDESCRIPTION  = LOSSDESI;
   CLAIMAMOUNT      = CLMAMTI;
   RESERVEAMOUNT    = RESERVEI;
   ADJUSTERNAME     = ADJNAMEI;

   OUTSTANDINGAMOUNT =
      CLAIMAMOUNT - PAIDAMOUNT;

   if wsUpdateFlag = 'Y';
      update AXACLAIMS;
   else;
      write AXACLAIMS;
   endif;

   exsr SendScreen;

endsr;
