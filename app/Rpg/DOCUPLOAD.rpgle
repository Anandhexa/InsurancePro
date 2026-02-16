**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// =====================
// Files
// =====================
dcl-f DOCUPLOAD workstn;
dcl-f AXASUBM   usage(*input) keyed;
dcl-f AXACLIENT usage(*input) keyed;
dcl-f AXADOC    usage(*update) keyed;

// =====================
// Scalars
// =====================
dcl-s SubmissionKey char(10);
dcl-s DocCounter packed(6:0) inz(100001);
dcl-s UploadCount packed(2:0) inz(0);
dcl-s HttpStatus int(10);
dcl-s JsonPayload varchar(1000);
dcl-s ApiResponse varchar(500);

// =====================
// Document DS (COPY DOCUMENT)
// =====================
dcl-ds Document qualified;
   DocumentId     char(12);
   ClientId       char(8);
   SubmissionId   char(10);
   DocumentType   char(20);
   DocumentName   char(50);
   FilePath       char(60);
   FileSize       packed(9:0);
   UploadDate     char(8);
   UploadedBy     char(30);
   DocumentStatus char(15);
   MimeType       char(30);
end-ds;

// =====================
// Parameter (COMMAREA)
// =====================
dcl-pi *n;
   pSubmissionKey char(10);
end-pi;

SubmissionKey = pSubmissionKey;

// =====================
// Read submission + client
// =====================
chain SubmissionKey AXASUBM;
if not %found;
   *inlr = *on;
   return;
endif;

chain CLIENT_ID AXACLIENT;

// =====================
// Load existing document row
// =====================
DOC1  = 'Policy_Document';
TYPE1 = 'POLICY';
STAT1 = 'UPLOADED';
DATE1 = '2024-01-15';
SIZE1 = '2.5MB';

// =====================
// Main loop
// =====================
dow *in03 = *off;

   CLIENTID = CLIENT_ID;
   SUBMID   = SUBMISSION_ID;

   exfmt DOCMAP;

   if *in03;                     // PF3
      call 'SUBMISSN' (SubmissionKey);
      leave;
   endif;

   if *in02;                     // PF2
      call 'DOCDELETE' (SubmissionKey);
      iter;
   endif;

   if *in04;                     // PF4
      call 'DOCMETA' (SubmissionKey);
      iter;
   endif;

   if *in01;                     // ENTER
      callp UploadDocument();
   endif;

enddo;

*inlr = *on;
return;

// ===================================================
// Upload logic
// ===================================================
dcl-proc UploadDocument;

   // Build ID
   Document.DocumentId = 'DOC' + %char(DocCounter);
   DocCounter += 1;

   Document.ClientId       = CLIENT_ID;
   Document.SubmissionId   = SUBMISSION_ID;
   Document.DocumentType   = DOCTYPE;
   Document.DocumentName   = DOCNAME;
   Document.FilePath       = FILEPATH;
   Document.FileSize       = 2500000;
   Document.UploadDate     = %char(%date():*ISO0);
   Document.UploadedBy     = 'ROSALIA GARCIA';
   Document.DocumentStatus = 'UPLOADING';
   Document.MimeType       = 'application/pdf';

   // Build JSON
   JsonPayload =
   '{' +
   '"documentId":"'   + %trim(Document.DocumentId) + '",' +
   '"clientId":"'     + %trim(Document.ClientId) + '",' +
   '"submissionId":"' + %trim(Document.SubmissionId) + '",' +
   '"documentType":"' + %trim(Document.DocumentType) + '",' +
   '"documentName":"' + %trim(Document.DocumentName) + '",' +
   '"filePath":"'     + %trim(Document.FilePath) + '",' +
   '"fileSize":'      + %char(Document.FileSize) + ',' +
   '"uploadedBy":"'   + %trim(Document.UploadedBy) + '",' +
   '"mimeType":"'     + %trim(Document.MimeType) + '"' +
   '}';

   // HTTP POST
   exec sql
      select HTTP_STATUS_CODE, RESPONSE_MESSAGE
        into :HttpStatus, :ApiResponse
        from table(
           QSYS2.HTTP_POST(
              URL => 'https://docmgmt.axainsurance.com/api/v1/upload',
              DATA => :JsonPayload,
              HEADERS => 'Content-Type,application/json'
           )
        );

   if HttpStatus = 200 or HttpStatus = 201;
      Document.DocumentStatus = 'UPLOADED';
      UploadCount += 1;
   else;
      Document.DocumentStatus = 'FAILED';
   endif;

   write AXADOC Document;

   UPLOADSTS =
      'DOCUMENTS UPLOADED: ' +
      %char(UploadCount) +
      ' STATUS: ' +
      %trim(Document.DocumentStatus);

end-proc;
