unit msexcel_auto;

interface

uses
  Windows, SysUtils,
  ComObj, OleCtrls,
  RxMemDS;

const
  sMsExcelApp  = 'Excel.application';

  xpIsExcelVisible: Word  = $0001;
  xpIsDisplayAlerts: Word = $0002;

  xpGetUsedRangeRows: Word= $0010;
  xpGetUsedRangeCols: Word= $0020;
  xpIsGetUsedRange : Word = $0040;

  xpDontCloseExcel:word   = $0080;

  xpIsAddToLog: word      = $0100;


function LoadVarArrayFromMsExcel(const fname: TFileName; var VarArray: Variant;
                                       var RowCount,ColCount: integer;
                                       const Params: Word =$40): integer;

function OpenExcelAsArray(const fname: tfilename;
                           out Cells: Variant; var MsExcel: Variant;
                           out iRows,iCols: integer; const Params: Word =$40): integer;

//function OpenExcelCellsArray(const fname: tfilename; var xlsCells, MsExcel: Variant;
//                              var iRows,iCols: integer; const Params: Word =0): integer;

function  SaveArrayAsExcelRange(const fname: tfilename; var Vals,MsExcel: Variant;
                                const aRow,aCol,zRow,zCol: integer): integer;

procedure CloseExcelInstance(var xObj: Variant);

implementation
uses
  Variants, StrUtils, DB,
  db_rxMDUtils,
  Sys_iStrUtils,Sys_StrConv;


function LoadVarArrayFromMsExcel(const fname: tfilename; var VarArray: Variant;
                                     var RowCount,ColCount: integer;
                                     const Params: Word =$40): integer;
var
  XLS: Variant;
begin
  XLS := CreateOleObject(sMsExcelApp);
  try
    XLS.DisplayAlerts := Params and xpIsDisplayAlerts = xpIsDisplayAlerts;
    XLS.WorkBooks.Open(fname);
    XLS.Visible := Params and xpIsExcelVisible = xpIsExcelVisible;

    if Params and xpIsGetUsedRange = xpIsGetUsedRange then begin
      ColCount := XLS.activeWorkbook.WorkSheets[1].UsedRange.Columns.Count;
      RowCount := XLS.activeWorkbook.WorkSheets[1].UsedRange.Rows.Count;
     end
    else
    if Params and xpGetUsedRangeCols = xpGetUsedRangeCols then
      ColCount := XLS.activeWorkbook.WorkSheets[1].UsedRange.Columns.Count
    else
    if Params and xpGetUsedRangeRows = xpGetUsedRangeRows then
      RowCount := XLS.activeWorkbook.WorkSheets[1].UsedRange.Rows.Count;

    if not varIsEmpty(varArray) then
      VarClear(varArray);
    if (RowCount >0) and (ColCount >0) then begin
      varArray := VarArrayCreate([1,RowCount, 1,ColCount], varVariant);
      varArray := XLS.Range[xls.Cells[1,1], xls.Cells[RowCount, ColCount]].Value;
    end;
  finally
    if Params and xpDontCloseExcel <>xpDontCloseExcel then begin
      XLS.DisplayAlerts := Params and xpIsDisplayAlerts =xpIsDisplayAlerts;
      XLS.ActiveWorkbook.Close;
      XLS.Quit;
      XLS := Unassigned;
    end;
  end;
  result := integer(not VarIsEmpty(varArray));
end;


function OpenExcelAsArray(const fname: tfilename;
                          out Cells: Variant; var MsExcel: Variant;
                          out iRows,iCols: integer; const Params: Word =$40): integer;
begin
  result := -2;

  if VarIsEmpty(MsExcel) then
  begin
    MsExcel := CreateOleObject(sMsExcelApp);
    if not VarIsEmpty(MsExcel) then
    try
      result := 0;
      MsExcel.DisplayAlerts := params and xpIsDisplayAlerts = xpIsDisplayAlerts;
      MsExcel.Visible       := params and xpIsExcelVisible  = xpIsExcelVisible;
      MsExcel.WorkBooks.Open(fname);

      if Params and xpIsGetUsedRange = xpIsGetUsedRange then begin
        iCols := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Columns.Count;
        iRows := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Rows.Count;
       end
      else
      if Params and xpGetUsedRangeCols = xpGetUsedRangeCols then
        iCols := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Columns.Count
      else
      if Params and xpGetUsedRangeRows = xpGetUsedRangeRows then
        iRows := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Rows.Count;

      if (iRows >0) and (iCols >0) then
      try
        Cells := VarArrayCreate([1,iRows,1,iCols], varVariant);
        Cells := MsExcel.Range[MsExcel.Cells[1,1], MsExcel.Cells[iRows,iCols]].Value;
      except
        result := -4;
        exit;
      end;
    finally
      result := integer(not VarIsEmpty(Cells));
    end;
  end;
end;


function SaveArrayAsExcelRange(const fname: tfilename; var Vals,MsExcel: Variant;
                                const aRow,aCol,zRow,zCol: integer): integer;
var
  xSheet: Variant;
begin
  try
    result := 0;
    if VarIsEmpty(MsExcel) then begin
      MsExcel := CreateOleObject(sMsExcelApp);
      MsExcel.WorkBooks.New;
    end;
    xSheet := MsExcel.ActiveWorkBook.ActiveSheet;
//  MsExcel.DisplayAlerts := FALSE;
    if not VarIsEmpty(Vals) then
    try
      xSheet.Range[MsExcel.Cells[aRow,aCol], MsExcel.Cells[zRow,zCol]] := Vals;
      try
//      MsExcel.ActiveWorkbook.// SaveAs[ FileName :=fname];ыыыыы€
        MsExcel.ActiveWorkbook.SaveAs('"'+fname+'"');
        MsExcel.ActiveWorkbook.Close;
        result := 1;
      except
        result := -2;
      end;
    except
      result := -4;
    end;
  finally
    MsExcel.Quit;
    MsExcel.Application.EnableEvents := TRUE;
    MsExcel := Unassigned;
  end;
end;


{function OpenExcelCellsArray(const fname: tfilename; var xlsCells, MsExcel: Variant;
                              var iRows,iCols: integer; const Params: Word =0): integer;
begin
  MsExcel := CreateOleObject(sMsExcelApp);
  MsExcel.DisplayAlerts := Params and xpIsDisplayAlerts = xpIsDisplayAlerts;
  try
    MsExcel.WorkBooks.Open(fname);
    MsExcel.Visible := Params and xpIsExcelVisible = xpIsExcelVisible;
    iCols := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Columns.Count;
    iRows := MsExcel.activeWorkbook.WorkSheets[1].UsedRange.Rows.Count;
    xlsCells := VarArrayCreate([1,iRows,1,iCols], varVariant);
    xlsCells := MsExcel.Range[MsExcel.Cells[1,1], MsExcel.Cells[iRows,iCols]].Value;
  finally
    result := integer(not VarIsEmpty(xlsCells));
  end;
end;}



function LoadMsExcelIntoMemData(const xlsfname: tfilename;
                                 minRowCount: integer;
                                 var md: TrxMemoryData;
                                 var errMsg: string;
                                 const LoadParams: Word =$0): integer;
var
  CatArray: Variant;
  ColCount, RowCount, r,i, ival, DataRow: integer;
  fval: double;
  sMsg, flname, sval: string;
  ivalues: array[0..1023] of integer;
  scell: array of string;
  IsBeginningTable: bool;
begin
  result := 0;
  errMsg := '';
  if LoadVarArrayFromMsExcel(xlsfname, CatArray, RowCount, ColCount, LoadParams) =0 then
    errmsg := format('MsExcel: %s - прочитано %d строк, %d колонок',
                     [xlsfname, rowCount,ColCount])
  else
  if ColCount <13 then
    errmsg := format('%s: количество колонок накладной(%d) менее определенного',
                     [XLSfname,ColCount])
  else
  begin
   if assigned(md) then
     MemDataReset(md)
   else begin
     md := TrxMemoryData.Create(nil);

   end;

   DataRow := 0;
   for r := 10 to rowCount do
   try
     fillchar(iValues, sizeof(ivalues),0);
     if DataRow >0 then
       SetLength(sCell, colCount);

     for i := 1 to ColCount-1 do begin
       sval := CatArray[r,i];
       if sVal <>'' then begin
         sval := ansiReplaceStr(sval, '  ',' ');
         if pos(' кг)', sval) >0 then
           sval := ansiReplaceStr(sval, ' кг)','кг)');
         if pos(' кг)', sval) >0 then
           sval := ansiReplaceStr(sval, ' шт)','шт)');

         if assigned(sCell) then
           scell[i] := sval;
         ivalues[i] := str2int(sval);

         if i =2 then  //определ€ем блок начала данных по заголовку
          IsBeginningTable := iValues[i] >0
         else
         if IsBeginningTable and (i>3) then
          IsBeginningTable := iValues[i] >0
         else
          IsBeginningTable := FALSE;
       end;
     end;

     if IsBeginningTable then      // нашли title,
       DataRow := succ(r);         // след.считаем с данными

     if (r >= DataRow) and assigned(sCell) and (str2int(sCell[2]) >0) then begin
       md.Insert;
       for i := 1 to ColCount-1 do
        if i< md.FieldDefs.Count then
        begin
          flname := md.FieldDefs[i-1].Name;
          md[ flname] := sCell[i];
        end;
       md.Append;
     end;
     if assigned(sCell) then
       sCell := nil;
   except
     errMsg := format('%s: ошибка в строке %d, колонка %d:  €чейка "%s":%s',
                    [XLSfname, r,i, flname, sVal]);
     if md.State =dsInsert then
       md.Append;
     sCell := nil;
   end;
   if assigned(sCell) then
     sCell := nil;
   VarClear(CatArray);
  end;
  if md.Active then
    result := md.RecordCount;
end;


procedure CloseExcelInstance(var xObj: Variant);
begin
  if (not VarIsEmpty(xObj)) then begin
    xObj.ActiveWorkbook.Close;
    xObj.Quit;
    varClear(xObj);
  end;
end;

end.
