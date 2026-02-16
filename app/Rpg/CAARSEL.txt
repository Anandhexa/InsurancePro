**FREE
ctl-opt dftactgrp(*no) actgrp(*caller) option(*srcstmt);

/* ----------------------------
   Files
-----------------------------*/
dcl-f AXASUBM keyed usage(*input);
dcl-f AXAPROD keyed usage(*input);
dcl-f AXAPLCMT keyed usage(*input);
dcl-f CARRSEL workstn;

/* ----------------------------
   COMMAREA
-----------------------------*/
dcl-pi *n;
   CommArea char(100);
end-pi;

dcl-s WS_Submission_Key char(10);

/* ----------------------------
   Working Storage
-----------------------------*/
dcl-s WS_Selected_Count packed(2:0) inz(0);
dcl-s WS_Success_Count packed(2:0) inz(0);
dcl-s WS_HTTP_Status int(10);
dcl-s WS_API_Response varchar(200);

/* ----------------------------
   Carrier Table (OCCURS)
-----------------------------*/
dcl-ds Carrier dim(3);
   Name char(25);
   Url char(100);
   Auth char(50);
end-ds;

/* Submission Data */
dcl-ds SubmRec likerec(AXASUBM:*all);
dcl-ds ProdRec likerec(AXAPROD:*all);
dcl-ds PlcmRec likerec(AXAPLCMT:*all);

/* API Request DS (from copybook equivalent) */
dcl-ds ApiRequest;
   LeadBroker char(30);
   FirstNamedInsured char(30);
   BusinessType char(20);
   Country char(20);
   City char(20);
   ZipCode char(10);
   InceptionDate char(10);
   ExpirationDate char(10);
   ProgramLimit packed(15:2);
   ProductName char(30);
   Deductible packed(12:2);
   BrokerRef char(20);
   DistributionType char(10);
end-ds;

/* ----------------------------
   Mainline
-----------------------------*/
WS_Submission_Key = %subst(CommArea:1:10);

exsr LoadCarriers;
exsr ReadSubmission;
exsr SendScreen;

*inlr = *on;
return;

/* =====================================================
   Load Carriers
=====================================================*/
begsr LoadCarriers;

Carrier(1).Name = 'LLOYD''S OF LONDON';
Carrier(1).Url  = 'https://api.lloyds.com/v1/submissions';
Carrier(1).Auth = 'Bearer LLOYDS_API_TOKEN_123';

Carrier(2).Name = 'ZURICH INSURANCE';
Carrier(2).Url  = 'https://api.zurich.com/v2/rfq';
Carrier(2).Auth = 'Bearer ZURICH_API_TOKEN_456';

Carrier(3).Name = 'ALLIANZ GROUP';
Carrier(3).Url  = 'https://api.allianz.com/submissions';
Carrier(3).Auth = 'Bearer ALLIANZ_API_TOKEN_789';

endsr;

/* =====================================================
   Read Submission Data
=====================================================*/
begsr ReadSubmission;

chain WS_Submission_Key AXASUBM SubmRec;
if not %found(AXASUBM);
   return;
endif;

chain SubmRec.ProductId AXAPROD ProdRec;
chain SubmRec.PlacementId AXAPLCMT PlcmRec;

endsr;

/* =====================================================
   Display Screen
=====================================================*/
begsr SendScreen;

RFQSTATUS =
   'RFQ SENT TO ' +
   %char(WS_Selected_Count) +
   ' CARRIERS, ' +
   %char(WS_Success_Count) +
   ' SUCCESSFUL';

exfmt CARRMAP;

/* PF3 */
if *in03;
   CommArea = SubmRec.SubmissionId;
   call 'SUBMISSN' CommArea;
   return;
endif;

/* ENTER */
if SEL1 = 'X'; exsr SendCarrier1; endif;
if SEL2 = 'X'; exsr SendCarrier2; endif;
if SEL3 = 'X'; exsr SendCarrier3; endif;

exsr SendScreen;

endsr;

/* =====================================================
   Build API Request
=====================================================*/
begsr BuildApiRequest;

ApiRequest.LeadBroker = 'ROSALIA GARCIA';
ApiRequest.FirstNamedInsured = PlcmRec.PlacementName;
ApiRequest.BusinessType = 'NEW BUSINESS';
ApiRequest.Country = 'USA';
ApiRequest.City = 'NEW YORK';
ApiRequest.ZipCode = '10001';
ApiRequest.InceptionDate = SubmRec.SubmissionDate;
ApiRequest.ExpirationDate = SubmRec.ValidUntilDate;
ApiRequest.ProgramLimit = PlcmRec.CoverageLimit;
ApiRequest.ProductName = ProdRec.ProductName;
ApiRequest.Deductible = ProdRec.Deductible;
ApiRequest.BrokerRef = SubmRec.BrokerRef;
ApiRequest.DistributionType = 'API';

endsr;

/* =====================================================
   Send Carrier Wrappers
=====================================================*/
begsr SendCarrier1; exsr SendCarrier; endsr;
begsr SendCarrier2; exsr SendCarrier; endsr;
begsr SendCarrier3; exsr SendCarrier; endsr;

/* =====================================================
   Send to Carrier
=====================================================*/
dcl-proc SendCarrier;
   dcl-pi *n;
      idx int(10) options(*nopass);
   end-pi;

   dcl-s JsonPayload varchar(1500);

   exsr BuildApiRequest;

   JsonPayload =
      '{ "submissionRequest": {' +
      '"leadBroker":"' + %trim(ApiRequest.LeadBroker) + '",' +
      '"insured":"' + %trim(ApiRequest.FirstNamedInsured) + '"' +
      '}}';

   exec sql
     select HTTP_STATUS_CODE, RESPONSE_MESSAGE
     into :WS_HTTP_Status, :WS_API_Response
     from table(
        QSYS2.HTTP_POST(
          url => :Carrier(idx).Url,
          data => :JsonPayload,
          headers => 'content-type,application/json'
        )
     );

   WS_Selected_Count += 1;

   if WS_HTTP_Status = 200 or WS_HTTP_Status = 201;
      WS_Success_Count += 1;
   endif;

end-proc;
