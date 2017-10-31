unit iConv;
interface
uses
  Windows,Classes,SysUtils;

procedure ConvertFiles(const InFileName,OutFileName:string;const FromCP,ToCP:string);
function iconv2(s, FromCP, ToCP: string): string;

implementation

const
  iconv_lib='libiconv2.dll';
type
  size_t=Cardinal;
  iconv_t=Pointer;
  argptr=iconv_t;

function errno:PInteger; cdecl;external'msvcrt.dll' Name'_errno';
function iconv_open(tocode:PChar;fromcode:PChar):iconv_t; cdecl;external iconv_lib Name'libiconv_open';
function iconv_convert(cd:iconv_t;var inbuf:Pointer;var inbytesleft:size_t;var outbuf:Pointer;var outbytesleft:size_t):size_t; cdecl;external iconv_lib Name'libiconv';
function iconv_close(cd:iconv_t):Integer; cdecl;external iconv_lib Name'libiconv_close';
function iconvctl(cd:iconv_t;request:Integer;argument:argptr):Integer; cdecl;external iconv_lib Name'libiconvctl';
 
const
  E2BIG=7;
  EINVAL=22;
  EILSEQ=84;
  ICONV_TRIVIALP=0;//int *argument
  ICONV_GET_TRANSLITERATE=1;//int *argument
  ICONV_SET_TRANSLITERATE=2;//const int *argument
  ICONV_GET_DISCARD_ILSEQ=3;//Int*argument
  ICONV_SET_DISCARD_ILSEQ=4;//const Int*argument
 
procedure ConvertStreams(cd:iconv_t;InStream,OutStream:TStream);
const
  BufferSize=4096;
var
  inbuf:array[0..BufferSize*2-1] of Char;
  insize,inbufsize,inbufrest:DWORD;
  inptr:Pointer;
  function Convert:Boolean;
  var
    outbuf:array[0..BufferSize-1] of Char;
    outptr:Pointer;
    outsize:DWORD;
    res:Integer;
  begin
    Result:=True;
    outptr:=@outbuf;
    outsize:=SizeOf(outbuf);
    res:=iconv_convert(cd,inptr,insize,outptr,outsize);
    if outptr<>@outbuf then
      OutStream.WriteBuffer(outbuf,PChar(outptr)-@outbuf);
    if res=-1 then begin
      case errno^ of
        EILSEQ:raise Exception.Create('cannot convert');
        EINVAL:begin
            if (inbufsize=0)or(insize>BufferSize) then
              raise Exception.Create('incomplete character or shift sequence')
            else begin
              inbufrest:=insize;
              Move(inptr^,inbuf[BufferSize-insize],insize);
              Result:=False;
            end;
          end;
        E2BIG:;
      else
        raise Exception.Create('unknown error')
      end;
    end;
  end;
begin
  inbufrest:=0;
  while True do begin
    inbufsize:=InStream.Read(inbuf[BufferSize],BufferSize);
    if inbufsize=0 then
      if inbufrest=0 then begin
        inptr:=nil;
        Convert;
        Exit;
      end
      else
        raise Exception.Create('incomplete character or shift sequence')
    else begin
      inptr:=@inbuf[BufferSize-inbufrest];
      insize:=inbufrest+inbufsize;
      inbufrest:=0;
      while (insize>0)and Convert do
        ;
    end;
  end;
end;
 
function iconv2(s, FromCP, ToCP: string): string;
var
  cd:iconv_t;
  Buf:Integer;
  InStream,OutStream:TMemoryStream;
begin
  Result := s;
  cd:=iconv_open(PChar(ToCP),PChar(FromCP));
  if cd=iconv_t(-1) then
    raise Exception.Create('internal error');
  try
    Buf:=1;
    iconvctl(cd,ICONV_SET_DISCARD_ILSEQ,@Buf);
    iconv_convert(cd,Pointer(nil^),size_t(nil^),Pointer(nil^),size_t(nil^));
    InStream:=TMemoryStream.Create;
    try
      OutStream:=TMemoryStream.Create;
      try
        InStream.Write(s[1], length(s));
        InStream.Seek(0, soFromBeginning);
        ConvertStreams(cd,InStream,OutStream);
        SetLength(s, OutStream.Size);
        OutStream.Seek(0, soFromBeginning);
        OutStream.Read(s[1], OutStream.Size);
        Result := s;
      finally
        OutStream.Free;
      end;
    finally
      InStream.Free;
    end;
  finally
    iconv_close(cd);
  end;
end;
 
procedure ConvertFiles(const InFileName,OutFileName:string;const FromCP,ToCP:string);
var
  cd:iconv_t;
  Buf:Integer;
  InStream,OutStream:TFileStream;
begin
  cd:=iconv_open(PChar(ToCP),PChar(FromCP));
  if cd=iconv_t(-1) then
    raise Exception.Create('internal error');
  try
    Buf:=1;
    iconvctl(cd,ICONV_SET_DISCARD_ILSEQ,@Buf);
    iconv_convert(cd,Pointer(nil^),size_t(nil^),Pointer(nil^),size_t(nil^));
    InStream:=TFileStream.Create(InFileName,fmOpenRead);
    try
      OutStream:=TFileStream.Create(OutFileName,fmCreate);
      try
        ConvertStreams(cd,InStream,OutStream);
      finally
        OutStream.Free;
      end;
    finally
      InStream.Free;
    end;
  finally
    iconv_close(cd);
  end;
end;
 
end.
