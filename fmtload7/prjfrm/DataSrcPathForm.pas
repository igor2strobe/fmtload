unit DataSrcPathForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, RXCtrls;

type
  TfrmDataSrcPath = class(TForm)
    Panel1: TPanel;
    Bevel1: TBevel;
    Label1: TLabel;
    btnCancel: TBitBtn;
    Ok: TBitBtn;
    Label2: TLabel;
    edPath: TEdit;
    btEditSrcPath: TButton;
    btnReplace: TBitBtn;
    btnAdd: TBitBtn;
    btnDelete: TBitBtn;
    lstbSrcPaths: TListBox;
    btnDown: TBitBtn;
    btnUp: TBitBtn;
    procedure btEditSrcPathClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure lstbSrcPathsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lstbSrcPathsClick(Sender: TObject);
    procedure edPathChange(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
  private
    { Private declarations }
    FInitDir: String;
    function  IsDirectoryOk(const aDirName: String): bool;
    procedure CheckBtnState;
  public
    { Public declarations }
    procedure SetData(aPath: string);
    function  FGetPathStr: String;
  end;


implementation

{$R *.dfm}

uses Graphics,QGraphics,
 FileCtrl, Sys_iStrUtils;

function TfrmDataSrcPath.IsDirectoryOk(const aDirName: String): bool;
begin
  Result := FALSE;
  if Length(aDirName) <2 then Exit;
  result := SysUtils.DirectoryExists(ExtractFilePath(aDirName));
end;

procedure TfrmDataSrcPath.btEditSrcPathClick(Sender: TObject);
var
  vSelectDir,FDir: string;
begin
  vSelectDir := nvl2s(Length(edPath.Text)=0, FInitDir,ExtractFileDrive(edPath.Text));
  FDir := edPath.Text;
  if SelectDirectory('Directories',vSelectDir,FDir) then
    edPath.Text := FDir;
end;

procedure TfrmDataSrcPath.SetData(aPath: string);
begin
  FInitDir := ExtractFileDrive(Application.ExeName);
  if Length(aPath) <2 then exit;
  try
    lstbSrcPaths.Items.BeginUpdate;
    while Length(aPath) >0 do
      lstbSrcPaths.Items.Add( GrepSepString(aPath));
  finally
    if lstbSrcPaths.Items.Count >0 then
      lstbSrcPaths.ItemIndex := 0;
    lstbSrcPaths.Items.EndUpdate;
  end;
  lstbSrcPathsClick(Self);
end;

procedure TfrmDataSrcPath.btnReplaceClick(Sender: TObject);
begin
  if lstbSrcPaths.ItemIndex >=0 then
    lstbSrcPaths.Items[lstbSrcPaths.ItemIndex] := edPath.Text;
  CheckBtnState;
end;

procedure TfrmDataSrcPath.CheckBtnState;
var
  idx: integer;
begin
  idx := lstbSrcPaths.ItemIndex;
  btnDelete.Enabled := idx >=0;
  if idx >=0 then
  begin
    btnReplace.Enabled := Trim(AnsiLowerCaseFileName(edPath.Text)) <>
                           AnsiLowerCaseFileName(lstbSrcPaths.Items[Idx]);
    btnAdd.Enabled := (Length(edPath.Text) >1) and btnReplace.Enabled;
   end
  else begin
    btnReplace.Enabled := False;
    btnAdd.Enabled     := Length(edPath.Text) >1;
  end;
  lstbSrcPaths.Invalidate;
end;

procedure TfrmDataSrcPath.lstbSrcPathsDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin
   with (Control as TListBox).Canvas do
   begin
     if (not IsDirectoryOk((Control as TListBox).Items[Index])) then
       if (odSelected in State) then Brush.Color := $00FFD2A6
       else Font.Color := clGray;

     FillRect(Rect);
     TextOut(Rect.Left,Rect.Top,(Control as TListBox).Items[index]);
     if odFocused in State then begin
       Brush.Color := lstbSrcPaths.Color;
       DrawFocusRect(Rect);
     end;
   end;
end;

procedure TfrmDataSrcPath.lstbSrcPathsClick(Sender: TObject);
begin
  with lstbSrcPaths do
    edPath.Text := nvl2s(Itemindex >=0, Items[ItemIndex], '');
  CheckBtnState;
end;

procedure TfrmDataSrcPath.edPathChange(Sender: TObject);
begin
  CheckBtnState;
end;

procedure TfrmDataSrcPath.btnAddClick(Sender: TObject);
begin
  lstbSrcPaths.Items.Add(edPath.Text);
  CheckBtnState;
end;

procedure TfrmDataSrcPath.btnDeleteClick(Sender: TObject);
begin
  if lstbSrcPaths.ItemIndex >=0 then
    lstbSrcPaths.Items.Delete(lstbSrcPaths.ItemIndex);
  CheckBtnState;  
end;

procedure TfrmDataSrcPath.btnDownClick(Sender: TObject);
begin
  with lstbSrcPaths do
  if (Items.Count >1) and (ItemIndex <Items.Count-1) then
    Items.Exchange(ItemIndex,ItemIndex+1);
end;

procedure TfrmDataSrcPath.btnUpClick(Sender: TObject);
begin
  with lstbSrcPaths do
  if (Items.Count >1) and (ItemIndex >0) then
    Items.Exchange(ItemIndex,ItemIndex-1);
end;

function TfrmDataSrcPath.FGetPathStr: String;
var
  j: integer;
begin
  SetLength(result,0);
  if lstbSrcPaths.Items.Count >0 then
  begin
    for j := 0 to lstbSrcPaths.Items.Count -1 do
      Result := Result + ';'+ lstbSrcPaths.Items[j];
    Result := Copy(Result, 2, Length(Result));
  end;
end;

end.
