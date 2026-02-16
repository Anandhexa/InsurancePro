**FREE
ctl-opt dftactgrp(*no) actgrp(*caller) option(*srcstmt);

/* ---------------------------
   File Declarations
----------------------------*/
dcl-f AXASUBM keyed usage(*input);
dcl-f AXAPROD keyed usage(*input);
dcl-f AXAPLCMT keyed usage(*input);
dcl-f AXARFQ usage(*output);
dcl-f APICARR workstn;

/* ---------------------------
   Data Structures
----------------------------*/
dcl-ds CommArea len(100);
   SubmissionKey char(10) pos(1);
end-ds;

dcl-s WS_RFQ_ID char(10);
dcl-s WS_HTTP_STATUS int(10);
dcl-s WS_API_RESPONSE varchar(500);
dcl-s WS_JSON_PAYLOAD varchar(1500);
dcl-s WS_API_COUNT packed(2:0) inz(0);
dcl-s WS_SUCCESS_COUNT packed(2:0) inz(0);

/* Carrier Arrays */
dcl-ds Carrier dim(3);
   Name char(40);
   Type char(30);
   Url  char(100);
   Token char(100);
end-ds;

/* ---------------------------
   Main Procedure
----------------------------*/
exsr LoadCarriers;
exsr ReadSubmission;
exsr GenerateRFQ;
exsr SendScreen;

*inlr = *on;
return;

/* =======================================================
   Load API Carrier Data
=======================================================*/
begsr LoadCarriers;

Carrier(1).Name  = 'LLOYD''S SYNDICATE 456';
Carrier(1).Type  = 'INSURANCE MARKET';
Carrier(1).Url   = 'https://api.lloyds.com/v2/rfq';
Carrier(1).Token = 'Bearer LLOYDS_RFQ_TOKEN_456';

Carrier(2).Name  = 'ZURICH API GATEWAY';
Carrier(2).Type  = 'DIRECT INSURER';
Carrier(2).Url   = 'https://api.zurich.com/v3/submissions';
Carrier(2).Token = 'Bearer ZURICH_RFQ_TOKEN_789';

Carrier(3).Name  = 'ALLIANZ DIGITAL HUB';
Carrier(3).Type  = 'REINSURER';
Carrier(3).Url   = 'https://api.allianz.com/v1/rfq';
Carrier(3).Token = 'Bearer ALLIANZ_RFQ_TOKEN_ABC';

endsr;

/* =======================================================
   Read Submission / Product / Placement
=======================================================*/
begsr ReadSubmission;

chain SubmissionKey AXASUBM SubmissionRec;
if not %found(AXASUBM);
   return;
endif;

chain SubmissionRec.ProductId AXAPROD ProductRec;
chain SubmissionRec.PlacementId AXAPLCMT PlacementRec;

endsr;

/* =======================================================
   Generate RFQ ID
=======================================================*/
begsr GenerateRFQ;

WS_RFQ_ID = %subst(%char(%timestamp()):9:6);

endsr;

/* =======================================================
   Display Screen
=======================================================*/
begsr SendScreen;

SUBMID = SubmissionRec.SubmissionId;
RFQID  = WS_RFQ_ID;
PRODNM = ProductRec.ProductName;

APISTS = 'READY TO SUBMIT RFQ';

exfmt APIMAP2;

/* Handle ENTER */
if *in03;
   return;
endif;

if *in12;
   exsr SendScreen;
endif;

/* Process Selected Carriers */
if APISEL1 = 'X';
   exsr SendApiRFQ1;
endif;

if APISEL2 = 'X';
   exsr SendApiRFQ2;
endif;

if APISEL3 = 'X';
   exsr SendApiRFQ3;
endif;

exsr CreateRFQRecord;

endsr;

/* =======================================================
   Build JSON and Send API
=======================================================*/
dcl-proc SendHTTP;
   dcl-pi *n;
      idx int(10);
   end-pi;

   WS_JSON_PAYLOAD =
      '{' +
      '"rfqId":"' + %trim(WS_RFQ_ID) + '",' +
      '"submissionId":"' + %trim(SubmissionRec.SubmissionId) + '",' +
      '"productName":"' + %trim(ProductRec.ProductName) + '",' +
      '"carrierName":"' + %trim(Carrier(idx).Name) + '"' +
      '}';

   WS_API_COUNT += 1;

   if WS_HTTP_STATUS = 200 or WS_HTTP_STATUS = 201;
      WS_SUCCESS_COUNT += 1;
   endif;

end-proc;

/* Carrier wrappers */
begsr SendApiRFQ1; SendHTTP(1); endsr;
begsr SendApiRFQ2; SendHTTP(2); endsr;
begsr SendApiRFQ3; SendHTTP(3); endsr;

/* =======================================================
   Create RFQ Record
=======================================================*/
begsr CreateRFQRecord;

RFQRec.RFQID        = WS_RFQ_ID;
RFQRec.SubmissionId = SubmissionRec.SubmissionId;
RFQRec.CarrierId    = 'CARR001';
RFQRec.Status       = 'SUBMISSION SENT';
RFQRec.CreatedDate  = %date();

write AXARFQ RFQRec;

endsr;


