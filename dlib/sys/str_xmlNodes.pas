unit str_xmlNodes;

interface
uses Sharemem,Windows, Classes,//
  XMLIntf,
  Dialogs;

function GetXMLNodeNamesList( nodeList: IXMLNodeList): TStringList;
function GetXMLNodeVals( const iNode: IXMLNode; iNames: array of string): string;

function GetXMLNodeStr( const iNode: IXMLNode; sAttr: string): string;
function GetChildNodeStr( xNode: IXMLNode; sAttrs: array of string): string;
function GetChildNode( xNode: IXMLNode; sAttrs: array of string): IXMLNode;

//function SetupDlgString( const dbSrcPath, dbName: string; var dlg: TopenDialog): string;

implementation
uses
  SysUtils;

{function SetupDlgString( const dbSrcPath, dbName: string; var dlg: TopenDialog): string;
var
  vf,vpath: string;
begin
  vpath := dbSrcPath;
  vf := ExtractFileExt(vpath);
  if (vf ='') then
    vf := '*.*'
  else
  if pos('.',vf) =1 then
    vf := '*'+vf;
  result := vf;
  dlg.InitialDir := ExtractFilePath(vpath);
  dlg.filter := format('%s files|%s', [dbName,vf]);
end;}

function GetXMLNode( const iNode: IXMLNode; sAttr: string): IXMLNode;
begin
  result := nil;
  if assigned(iNode) then begin
    if not iNode.HasChildNodes then
      result := iNode
    else
    if iNode.ChildNodes.IndexOf(sAttr) >=0 then
     result := iNode.ChildNodes[sAttr];
  end;
end;


function GetXMLNodeStr( const iNode: IXMLNode; sAttr: string): string;
begin
  if assigned(iNode) and assigned( GetXMLNode( iNode,sAttr)) then
    result := GetXMLNode( iNode,sAttr).Text
  else result := '';
end;

function GetChildNode( xNode: IXMLNode; sAttrs: array of string): IXMLNode;
var
  i,k: integer;
  attr2: array of string;
begin
  result := nil;
  if assigned(xNode) then
  if High(sAttrs) =0 then
    result := GetXMLNode( xNode, sAttrs[0])
  else
  for i:= 0 to High(sAttrs) do begin
    SetLength(Attr2, High(sAttrs));
    for k := 0 to High(Attr2) do Attr2[k] := sAttrs[k+1];

    if xNode.HasChildNodes and (xNode.ChildNodes.IndexOf( sAttrs[i]) >=0) then
      result := GetChildNode( xNode.ChildNodes[ sAttrs[i]], attr2);
    Finalize(Attr2);
  end;
end;


function GetChildNodeStr( xNode: IXMLNode; sAttrs: array of string): string;
var
  i,k: integer;
  sa: string;
  attr2: array of string;
begin
  result := '';
  if assigned(xNode) then
  if High(sAttrs) =0 then
    result := GetXMLNodeStr( xNode, sAttrs[0])
  else
  for i:= 0 to High(sAttrs) do begin
    sa := sAttrs[i];
    SetLength(Attr2, High(sAttrs));
    for k := 0 to High(Attr2) do Attr2[k] := sAttrs[k+1];
    if xNode.ChildNodes.IndexOf( sa)>=0 then
      result := GetChildNodeStr( xNode.ChildNodes[ sa], attr2);

    Finalize(Attr2);
  end;
end;


function GetXMLNodeVals( const iNode: IXMLNode; iNames: array of string): string;
var
  i,k: integer;
  s: string;
  lNode: IXMLNode;
begin
  result := '';
  if assigned(iNode) then
   for i:= 0 to High(iNames) do begin

     if iNode.HasChildNodes then begin
       if iNode.ChildNodes.Count =0 then
         result := iNode.ChildNodes[ iNames[i]].Text
       else
       for k := 0 to iNode.ChildNodes.Count -1 do
         begin
           result := GetXMLNodeVals(iNode.ChildNodes.Get(k), iNames[i]);
           if length(result) >0 then
             exit;
         end;
      end

     else
   //if iNode.NodeName =iNames[i] then
       result := iNode.Text;
   end;
end;

function GetXMLNodeNamesList( nodeList: IXMLNodeList): TStringList;
var
  i: integer;
begin
  if not assigned(NodeList) then
    result := nil
  else begin
    result := TStringList.Create;
    for i := 0 to NodeList.Count-1 do
      result.Add( NodeList[i].NodeName);
  end;
end;


end.
