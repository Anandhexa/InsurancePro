ctl-opt dftactgrp(*no) actgrp(*new);

dcl-f BINDREQ workstn;

dcl-s SubmissionKey      char(10);
dcl-s BindCount          zoned(2:0) inz(0);
dcl-s SuccessCount       zoned(2:0) inz(0);
dcl-s BindCounter        zoned(6:0) inz(100001);
dcl-s Index              zoned(3:0);

dcl-s JsonPayload        char(1000);
dcl-s HttpStatus         zoned(3:0);

dcl-s QuoteID        char(10)  dim(3);
dcl-s CarrierName    char(30)  dim(3);
dcl-s Premium        packed(11:2) dim(3);
dcl-s CommMethod     char(15)  dim(3);
dcl-s BindStatus     char(20)  dim(3);
dcl-s ConfRef        char(20)  dim(3);

dcl-s BindID           char(12);
dcl-s BindDate         char(8);
dcl-s AuditLog         char(200);

exsr LoadQuotes;
exsr ProcessSelections;
exsr DisplaySummary;

*inlr = *on;
return;

begsr LoadQuotes;

   BindCount = 3;

   QuoteID(1)     = 'QTE001';
   CarrierName(1) = 'LLOYDS';
   Premium(1)     = 125000.00;
   CommMethod(1)  = 'API';
   BindStatus(1)  = 'READY';
   ConfRef(1)     = *blanks;

   QuoteID(2)     = 'QTE002';
   CarrierName(2) = 'ZURICH';
   Premium(2)     = 135000.00;
   CommMethod(2)  = 'PLATFORM';
   BindStatus(2)  = 'READY';
   ConfRef(2)     = *blanks;

   QuoteID(3)     = 'QTE003';
   CarrierName(3) = 'ALLIANZ';
   Premium(3)     = 118000.00;
   CommMethod(3)  = 'EMAIL';
   BindStatus(3)  = 'READY';
   ConfRef(3)     = *blanks;

endsr;

begsr ProcessSelections;

   for Index = 1 to BindCount;
      exsr SendBindRequest;
   endfor;

endsr;

begsr SendBindRequest;

   select;
      when CommMethod(Index) = 'API';
         exsr SendApiRequest;

      when CommMethod(Index) = 'PLATFORM';
         exsr SendPlatformRequest;

      when CommMethod(Index) = 'EMAIL';
         exsr SendEmailRequest;
   endsl;

   exsr CreateBindRecord;
   SuccessCount += 1;

endsr;

begsr SendApiRequest;

   JsonPayload =
      '{"quoteId":"' + %trim(QuoteID(Index)) +
      '","carrier":"' + %trim(CarrierName(Index)) +
      '","amount":' + %char(Premium(Index)) + '}';

   BindStatus(Index) = 'SENT';
   ConfRef(Index)    = 'API-' + %char(%date());

endsr;

begsr SendPlatformRequest;

   JsonPayload =
      '{"quote":"' + %trim(QuoteID(Index)) +
      '","carrier":"' + %trim(CarrierName(Index)) + '"}';

   BindStatus(Index) = 'SENT';
   ConfRef(Index)    = 'PLAT-' + %char(%date());

endsr;

begsr SendEmailRequest;

   JsonPayload =
      'BIND REQUEST FOR ' + %trim(QuoteID(Index)) +
      ' CARRIER ' + %trim(CarrierName(Index)) +
      ' AMOUNT ' + %char(Premium(Index));

   BindStatus(Index) = 'SENT';
   ConfRef(Index)    = 'MAIL-' + %char(%date());

endsr;

begsr CreateBindRecord;

   BindID = 'BIND' + %char(BindCounter);
   BindCounter += 1;

   BindDate = %char(%date());

   AuditLog =
      'BIND REQUEST SENT FOR QUOTE ' + %trim(QuoteID(Index)) +
      ' USING ' + %trim(CommMethod(Index));

endsr;

begsr DisplaySummary;

   dsply ('Bind Requests Processed: ' + %char(SuccessCount));

endsr;
