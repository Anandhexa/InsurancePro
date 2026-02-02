**FREE
/*********************************************************************/
/* Program : APISUBM                                                  */
/* Purpose : API Submission to UWB                                    */
/* Source  : Mainframe COBOL CICS migration                            */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp('INSURANCE')
        option(*nodebugio : *srcstmt);

/*-------------------------------------------------------------------*/
/* Files                                                             */
/*-------------------------------------------------------------------*/
dcl-f AXASUBM     usage(*input) keyed;
dcl-f AXAPROD     usage(*input) keyed;
dcl-f AXAPLCMT    usage(*input) keyed;
dcl-f APISUBMDSPF workstn;

/*-------------------------------------------------------------------*/
/* Copybooks                                                         */
/*-------------------------------------------------------------------*/
 /copy QRPGLESRC,APISUBM
 /copy QRPGLESRC,SUBMISSN
 /copy QRPGLESRC,PRODUCT
 /copy QRPGLESRC,PLACEMENT
 /copy QRPGLESRC,CLIENT

/*-------------------------------------------------------------------*/
/* Program Parameter (DFHCOMMAREA)                                    */
/*-------------------------------------------------------------------*/
dcl-pi *n;
   pSubmissionKey char(10);
end-pi;

/*-------------------------------------------------------------------*/
/* Working Storage                                                   */
/*-------------------------------------------------------------------*/
dcl-s wsSubmissionKey char(10);
dcl-s wsApiUrl        char(100)
      inz('https://uwb.axainsurance.com/api/v1/submissions');
dcl-s wsAuthHeader    char(50)
      inz('Authorization: Basic QlJPS0VSOkJST0tFUjEyMw==');
dcl-s wsHttpStatus    packed(3:0);
dcl-s wsApiResponse   char(200);

/*-------------------------------------------------------------------*/
/* Initialization                                                    */
/*-------------------------------------------------------------------*/
wsSubmissionKey = pSubmissionKey;

readSubmissionData();
sendMap();

/*-------------------------------------------------------------------*/
/* Main Screen Loop                                                  */
/*-------------------------------------------------------------------*/
dou *inlr;

   exfmt APIMAP;

   if *in12;
      sendMap();
   elseif *in03;
      returnSubmission();
   elseif *in00;
      sendApiRequest();
   endif;

enddo;

*inlr = *on;
return;

/*-------------------------------------------------------------------*/
/* Procedures                                                        */
/*-------------------------------------------------------------------*/
dcl-proc readSubmissionData;

   chain wsSubmissionKey AXASUBM;
   if %notfound(AXASUBM);
      return;
   endif;

   chain Product_Id AXAPROD;
   chain Placement_Id AXAPLCMT;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc sendApiRequest;

   buildApiRequest();
   callUwbApi();
   sendMap();

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc buildApiRequest;

   Lead_Broker         = 'ROSALIA GARCIA';
   First_Named_Insured = Placement_Name;
   Business_Type       = 'NEW BUSINESS';
   Country             = 'USA';
   City                = 'NEW YORK';
   Zip_Postal_Code     = '10001';
   Inception_Date      = Submission_Date;
   Expiration_Date     = Valid_Until_Date;
   Program_Limit       = Coverage_Limit;
   Product_Name        = Product_Name;
   Interest            = InterestI;
   Deductible          = Deductible;
   Broker_Subm_Ref     = Broker_Ref;
   RFQ_Ref             = RFQRefI;
   Distribution_Type   = 'API';
   Carrier_Name        = CarrierI;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc callUwbApi;

   /* --------------------------------------------------------------- */
   /* HTTP CALL PLACEHOLDER                                          */
   /* Replace with HTTPAPI or QSYS2.HTTP_POST in production           */
   /* --------------------------------------------------------------- */

   wsHttpStatus = 200;
   wsApiResponse = '{"status":"success"}';

   if wsHttpStatus = 200 or wsHttpStatus = 201;
      ApiStatusO = 'API SUBMISSION SUCCESSFUL';
   else;
      ApiStatusO = 'API SUBMISSION FAILED';
   endif;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc sendMap;

   LeadBrkrO = 'ROSALIA GARCIA';
   ProdNmO   = Product_Name;
   ProgLmtO  = Coverage_Limit;

   exfmt APIMAP;

end-proc;

/*-------------------------------------------------------------------*/
dcl-proc returnSubmission;

   callp SUBMISSN(Submission_Id);

end-proc;
