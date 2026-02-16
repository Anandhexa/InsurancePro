ctl-opt dftactgrp(*no) actgrp(*new);

dcl-f APICARR workstn;

dcl-s CarrierRequestId     char(12);
dcl-s CarrierName          char(30) inz('GENERIC CARRIER');
dcl-s RequestPayload       char(1000);
dcl-s ResponsePayload      char(1000);
dcl-s InterfaceStatusCode  int(5);
dcl-s ProcessingStatus     char(15);
dcl-s CarrierReference     char(25);
dcl-s RequestCounter       int(6) inz(700001);

exsr Initialize;
exsr BuildCarrierRequest;
exsr SendCarrierRequest;
exsr EvaluateCarrierResponse;
exsr DisplayResult;

*inlr = *on;
return;

begsr Initialize;

   ProcessingStatus    = 'NEW';
   InterfaceStatusCode = 0;
   RequestPayload      = *blanks;
   ResponsePayload     = *blanks;
   CarrierReference    = *blanks;

endsr;

begsr BuildCarrierRequest;

   CarrierRequestId = 'CAR' + %char(RequestCounter);
   RequestCounter += 1;

   RequestPayload =
      '{ "requestId": "' + CarrierRequestId +
      '", "carrier": "' + CarrierName +
      '", "action": "PROCESS" }';

endsr;

begsr SendCarrierRequest;

   if %len(%trim(RequestPayload)) > 0;

      InterfaceStatusCode = 200;
      ResponsePayload =
         '{ "result": "OK", "carrierRef": "CAR-REF-45678" }';

   else;

      InterfaceStatusCode = 500;
      ResponsePayload =
         '{ "result": "ERROR", "carrierRef": "" }';

   endif;

endsr;

begsr EvaluateCarrierResponse;

   if InterfaceStatusCode = 200;

      ProcessingStatus = 'SUCCESS';
      CarrierReference = 'CAR-' + %char(%timestamp():7:6);

   else;

      ProcessingStatus = 'FAILED';
      CarrierReference = 'N/A';

   endif;

endsr;

begsr DisplayResult;

   dsply ('---------------------------------------');
   dsply ('CARRIER REQUEST ID : ' + CarrierRequestId);
   dsply ('CARRIER NAME       : ' + CarrierName);
   dsply ('STATUS             : ' + ProcessingStatus);
   dsply ('REFERENCE          : ' + CarrierReference);
   dsply ('---------------------------------------');

endsr;
