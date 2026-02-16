**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// ============================
// Files
// ============================
dcl-f NEWPLCMT  workstn;
dcl-f AXAPLCMT  usage(*update) keyed;

// ============================
// Date working storage
// ============================
dcl-s IncepDate  date;
dcl-s ExpirDate  date;

// ============================
// Placement record (COPY PLACEMENT)
// ============================
dcl-ds Placement qualified;
   PlacementId     char(10);
   PlacementName   char(30);
   PlacementBroker char(20);
   PlacementStatus char(10);
   InceptionDate   char(10);
   ExpiryDate      char(10);
   BusinessType    char(12);
   ClientName      char(30);
   LeadBroker      char(20);
   CaptiveLayer    char(50);
   FirstInsured    char(30);
   FniAddress      char(50);
   City            char(20);
   Country         char(20);
   PostalCode      char(10);
   AddlInsured     char(30);
   AniAddress      char(50);
end-ds;

// ============================
// Initial defaults
// ============================
callp SetDefaults();

// ============================
// Main loop
// ============================
dow *in03 = *off;

   exfmt NEWPLMAP;

   if *in12;               // PF12 = Refresh
      callp SetDefaults();
      iter;
   endif;

   if *in04;               // PF4 = Add product
      call 'PRODUCT';
      iter;
   endif;

   if *in03;               // PF3 = Exit
      call 'BROKPIPE';
      leave;
   endif;

   if *in01;               // ENTER = Save placement
      callp SavePlacement();
      leave;
   endif;

enddo;

*inlr = *on;
return;

// ======================================
// Save placement (ENTER)
// ======================================
dcl-proc SavePlacement;

   // Build placement record
   Placement.PlacementName   = PLCMTNM;
   Placement.ClientName      = CLIENTNM;
   Placement.BusinessType    = BIZTYPE;
   Placement.LeadBroker      = 'ROSALIA GARCIA';
   Placement.PlacementBroker = 'RGARCIA';
   Placement.PlacementStatus = 'NEW';
   Placement.InceptionDate   = INCEPDT;
   Placement.ExpiryDate      = EXPIRDT;
   Placement.CaptiveLayer    = CAPTLYR;
   Placement.FirstInsured    = FSTINSRD;
   Placement.FniAddress      = FNIADDR;
   Placement.City            = CITY;
   Placement.Country         = COUNTRY;
   Placement.PostalCode      = POSTAL;
   Placement.AddlInsured     = ADDINSRD;
   Placement.AniAddress      = ANIADDR;

   // Persist
   write AXAPLCMT Placement;

   // Navigate back to pipeline
   call 'BROKPIPE';

end-proc;

// ======================================
// Set default dates and fields
// ======================================
dcl-proc SetDefaults;

   IncepDate = %date();
   ExpirDate = IncepDate + %days(364);

   INCEPDT  = %char(IncepDate:*ISO0);
   EXPIRDT  = %char(ExpirDate:*ISO0);
   LEADBRKR = 'ROSALIA GARCIA';

end-proc;
