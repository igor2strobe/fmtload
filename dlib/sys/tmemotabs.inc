{Set Tab Stops for TMemo
 
    Editor: TDBRichEdit;
    private
        Procedure SetMemoTabStop;
 }
       
// ************************************************************************ //
procedure TMainForm.FormCreate(Sender: TObject);
// ************************************************************************ //
begin
    SetMemoTabStop;
end;

// ************************************************************************ //
procedure TMainForm.SetMemoTabStop;
// ************************************************************************ //
// Codes Originally From : http://delphi.about.com/cs/adptips2001/a/bltip1201_2.htm    
// and modified by me to become Tab Per Character not Tab Per Pixels. 

var
   DialogUnitsX : LongInt;
   PixelsX : LongInt;
   i : integer;
   PixelPerCharExt : Extended;
   PixelPerCharInt : Integer; 
   TabArray : array[0..4] of integer;
begin
   Editor.WantTabs := true;
   DialogUnitsX := LoWord(GetDialogBaseUnits) ;

   // must get pixels per characters...
   PixelPerCharExt:=(Editor.Font.Size / 72)*96;
   PixelPerCharInt:=Trunc(PixelPerCharExt);

   PixelsX := PixelPerCharInt*4; // tab. 4 character, just change 4 with anything you like.

   for i := 1 to 5 do begin
    TabArray[i - 1] :=
      ((PixelsX * i ) * 4) div DialogUnitsX;
   end;
   SendMessage(Editor.Handle,
               EM_SETTABSTOPS,
               5,
               LongInt(@TabArray)) ;
   Editor.Refresh;
end;
