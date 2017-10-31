unit db_RxMDUtils;

interface
uses
 Windows,
 SysUtils,
 RxMemDS;

procedure MemDataReset(var mData: TrxMemoryData);
//
function  GrepSepLineIntoMemData(s: string; var mData: TrxMemoryData;
                                  const IsMemDataCleared, IsLineTrimmed: bool): integer;

//
function  CreateMemoryDataFromCSVFile( var md: TrxMemoryData; sFname,sepCh: string;
                                   var sMsg: string;
                                   const sFieldMask: string='mdField';
                                   const mxFldCount: integer =1024): integer;

function  mdTableStrSupress(var md: TrxMemoryData; const mdFieldName,src,dst: string): integer;

// создать нужно кол-во FieldDefs по шаблону/параметрам
function  ExpandMemDataFields(var md: TrxMemoryData; const iFieldCount, iSize: integer;
                               const sFieldMask: string ='mdField'): bool;


implementation

uses
   strUtils,
   Sys_iStrUtils,Sys_StrConv,
   Classes,db,maxMin;

function SafeConvert(s: string): Variant;
var
  dt: tdatetime;
  fv: double;
  iv: integer;
begin
  dt := 0;
  if (length(s) >5) and
   ((pos('.',s) >0) or (pos(dateseparator,s)>0) or (pos(' ',s)>0)) then
  dt := str2datetime(s);
  if dt <>0 then
    result := dt
  else begin
    fv := str2float(s);
    if fv <>0 then
      result := fv
    else begin
      iv := str2int(s);
      if iv <>0 then
        result := iv
      else
        result := s;
    end;
  end;
end;


function GrepSepLineIntoMemData(s: string; var mData: TrxMemoryData;
                         const IsMemDataCleared, IsLineTrimmed: bool): integer;
var
  i: integer;
  v: string;
begin
  i := 0;
  if IsMemDataCleared then
    MemDataReset(mData);

  try
    mData.Insert;
    while length(s) >0 do begin
      if pos(';',s) >0 then
      begin
        v := copy(s, 1, pos(';',s)-1);
        s := copy(s, pos(';',s)+1, length(s));
       end
      else begin
        v := s;
        s := '';
      end;
      if IsLineTrimmed then
        v := trimleft(v);

      if i >mdata.fields.Count then
        result := -i
      else
      try
        mdata.Fields[i].value := safeConvert(v);
      except
        mdata.Fields[i].value := safeConvert( AnsiReplaceStr(v,',','.'));
      end;
      inc(i);
    end;
    mData.Post;
    result := i;
  except
    if mData.State in [dsInsert,dsEdit] then
      mData.Post;
    result := -i;
  end;
end;


function  CreateMemoryDataFromCSVFile( var md:TrxMemoryData; sFname,sepCh: string;
                            var sMsg: string;
                            const sFieldMask: string='mdField';
                            const mxFldCount: integer =1024): integer;
var
  ilist, lstLength: tstringlist;
  s: string;
  iLen: array of shortint;
  k,i,mlen,mcol,fmtlen: integer;
begin
  result := 0;
  sMsg := '';
  ilist := tstringlist.create;
  try
    ilist.loadfromfile(sfname);
    if ilist.count =0 then
      sMsg := format('Нет данных в "%s"',[sfname])
    else begin
      lstLength := TstringList.Create;
      SetLength( iLen, mxFldCount);
      mLen := 0; mCol := 0;
      for i := 0 to iList.Count-1 do begin //parsing string list
        s := iList[i];
        k := 1;        // первое поле - это RecordNo!
        while length(s) >0 do begin
          iLen[k] := Max(iLen[k], length( GrepSepString( s, sepCh)));
          mLen := Max(mLen, iLen[k]);
          inc(k);
          mCol := Max(mCol, k);
        end;
      end;
      fmtlen := GetNumberLength( IntToStr( mLen));
      iLen[0] := GetNumberLength( IntToStr( k));
      if md.active then md.close;
      with md.FieldDefs do begin
        Clear;
        for k := 0 to mCol do
        with AddFieldDef do begin
          Name := format( sFieldMask +'%'+format('%d.%d',[fmtLen,fmtlen])+'d',[k]);
          DataType := ftString;
          Size := iLen[k]+1;
        end;
      end;
      Finalize( iLen);
      try
        md.Open;
        for i := 0 to iList.Count-1 do begin // adding data from stringlist
          s := iList[i];
          md.Insert;
          md.Fields[0].asString := IntToStr(i);
          k := 1;
          while length(s) >0 do begin
            md.Fields[k].asString := GrepSepString(s, sepCh);
            inc(k);
          end;
          mD.Post;
        end;
      except
       sMsg := format('ошибка заполнения из %s, строка "%s", колонка %d',
                                                         [sfname, iList[i],k]);
      end;
      lstLength.free;
    end;
    if md.Active then
      result := md.recordCount;
  except
    sMsg := format('Ошибка в процессе чтения "%s"',[sfname]);
    ilist.free;
  end;
end;


function mdTableStrSupress(var md: TrxMemoryData; const mdFieldName,src,dst: string): integer;
var i,k: integer;
  vs: string;
  j1,j2: integer;
  fieldMatched: bool;
begin
  result := 0;
  with md do
  if Active and (recordCount >0) then     //fielddefs
  try
//  sortOnFields('');
//  first;
    for k := 0 to md.FieldDefs.Count-1 do begin // first scanning
      fieldMatched := uppercase(fieldDefs[k].Name) =upperCase(mdFieldName);
      if fieldMatched then
        break;
    end;

    if FieldMatched then
    for i:= 0 to RecordCount-1 do
    begin
      vs := fieldByName(mdFieldName).asString;

      if pos(src,vs) >0 then
      try
        vs := ansiReplaceStr(vs,src,dst);
        edit;
        fieldByName('cat_name').asString := vs;
        post;
        inc(result);
      except
        if state =dsEdit then
          cancel;
      end;
    end;
  finally

  end;
end;


procedure MemDataReset(var mData: TrxMemoryData);
begin
  with mData do
  if not Active then
    Open
  else
  if not IsEmpty then
  begin
    Close;
    EmptyTable;
    Open;
  end;
end;


function ExpandMemDataFields(var md: TrxMemoryData; const iFieldCount, iSize: integer;
                               const sFieldMask: string ='mdField'): bool;
var
  i, sizeLen: integer;
begin
  sizeLen := GetNumberLength( IntToStr( iFieldCount));
  if md.active then md.close;
  with md.FieldDefs do begin
    Clear;
    for i := 0 to iFieldCount-1 do
    with AddFieldDef do begin
      Name := format( sFieldMask + '%' + format('%d.%d', [sizeLen, sizelen]) + 'd',[i]);;
      DataType := ftString;
      Size := iSize;
    end;
  end;
 (* with IndexDefs do begin  // Next, describe any indexes
      Clear;
      with AddIndexDef do begin
        Name := ''; // The 1st index has no name because it is a Paradox primary key
        Fields := 'Field1';
        Options := [ixPrimary];
      end;
      with AddIndexDef do begin
        Name := 'Fld2Indx';
        Fields := 'Field2';
        Options := [ixCaseInsensitive];
      end;
    end;
    CreateTable; *) // Call the CreateTable method to create the table
  try
    md.Open;
    result := iFieldCount = md.fieldDefs.Count;
  except end;
end;

end.
