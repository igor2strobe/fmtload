unit fmtlDataSrcParamForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  DB,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TfrmDataSrcParam = class(TForm)
    edCorrID: TEdit;
    edDataSourceName: TEdit;
    edLibraryName: TEdit;
    edDataSouceFilePath: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    rgrpDriverName: TRadioGroup;
    Label4: TLabel;
    pnBottonForm: TPanel;
    cbHide: TCheckBox;
    bbtnOk: TBitBtn;
    bBtnCancel: TBitBtn;
    btEditSrcPath: TButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btEditSrcPathClick(Sender: TObject);
    procedure rgrpDriverNameClick(Sender: TObject);
  private
    FIsNewDataSrc: bool;
    { Private declarations }
  public
    { Public declarations }
    procedure SetData(const aDataSet: TDataSet; const aActiveFlag: integer=1);
    procedure InitNew;
  end;

var
  frmDataSrcParam: TfrmDataSrcParam;
  IsNewDataSrcAgentAction: Boolean = FALSE;

implementation

{$R *.dfm}
uses sys_StrConv, DataModule,
  DataSrcPathForm;

{ TfrmDataSrcParam }

procedure TfrmDataSrcParam.SetData(const aDataSet: TDataSet;
                                   const aActiveFlag: integer=1);
var
  sDrvName: String;
begin
  try
    if (not IsNewDataSrcAgentAction) then
      edCorrID.Text          := aDataSet.fieldByname('UIN_Corr').asString;

    edDataSourceName.Text    := Trim(aDataSet.fieldByname('Corr_Name').asString);
    edLibraryName.Text       := Trim(aDataSet.fieldByname('DLL_entry_point').asString);
    edDataSouceFilePath.Text := Trim(aDataSet.fieldByname('Path_Name').asString);
    sDrvName := Trim(aDataSet.fieldByname('Driver_Name').asString);

    if Length(edLibraryName.Text) =0 then
    begin
      rgrpDriverName.ItemIndex := 0;
      edLibraryName.Hide;
      Label3.Hide;
      end
    else begin
      if SameText('HTML',sDrvName) or (pos('HTML',AnsiUpperCase(sDrvName))=1) then
        rgrpDriverName.ItemIndex := 3
      else
      if SameText('XML',sDrvName) or (pos('XML',AnsiUpperCase(sDrvName))=1) then
        rgrpDriverName.ItemIndex := 2
      else
       rgrpDriverName.ItemIndex := 1
    end;
    FIsNewDataSrc := Length(edCorrID.Text) = 0;
    if aActiveFlag =2 then // deleted datasource
    begin
      if (dm.UserMode and $8=$8) or (dm.UserMode and $10=$10) then
        cbHide.Caption := 'Удалить источник'
      else cbHide.Visible := False;
    end;

  finally
  end;
end;


procedure TfrmDataSrcParam.InitNew;
begin
  edCorrID.Text  := '0';
  edDataSourceName.Text := '';
  edLibraryName.Text    := '';
  edDataSouceFilePath.Text := '';

  rgrpDriverName.ItemIndex := 0;
  Caption := 'Новый источник данных';
  FIsNewDataSrc  := TRUE;
  cbHide.Visible := False;
  rgrpDriverNameClick(Self);
end;


procedure TfrmDataSrcParam.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
var
  IsValidId: bool;
const
  sConfirmDataSrcOff = 'Вы подтверждаете отключение источника данных "%s"?';
  sInvalidDir = 'Указанная папка'#13#10'%s'#13#10'источника %s '#13#10+
                'не существует или недоступна';
begin
  if modalResult =mrOk then
  begin
    edLibraryName.Text       := Trim(edLibraryName.Text);
    edDataSourceName.Text    := Trim(edDataSourceName.Text);
    edDataSouceFilePath.Text := Trim(edDataSouceFilePath.Text);
    edCorrID.Text            := IntToStr( Str2Int(Trim( edCorrID.Text)));
    if Length(edLibraryName.Text) =0 then
      rgrpDriverName.ItemIndex := 0;

    if cbHide.Checked then
      CanClose := MessageDlg(format(sConfirmDataSrcOff,
                     [ansiUpperCase(edDataSourceName.Text)]),
                       mtConfirmation,[mbYes,mbCancel],0) =idYes;
    if not CanClose then exit;

    IsValidID := FIsNewDataSrc or (Str2Int(edCorrID.Text) >0);
{   if Length(edDataSouceFilePath.Text) >0 then
      IsDirectoryOk := DirectoryExists(edDataSouceFilePath.Text)
    else IsDirectoryOk := TRUE;
    if not IsDirectoryOk then
       MessageDlg(format(sInvalidDir,[edDataSouceFilePath.Text,
                                  edDataSourceName.Text]), mtWarning,[mbOk],0);}

    if rgrpDriverName.ItemIndex =0 then
      CanClose := (Length(edDataSourceName.Text) >0) and IsValidID
    else
      CanClose := (Length(edDataSourceName.Text) >0) and IsValidID and
                   (Length(edLibraryName.Text) >4);
  end;
end;


procedure TfrmDataSrcParam.btEditSrcPathClick(Sender: TObject);
begin
  with TfrmDataSrcPath.Create(Self) do
  try
    SetData(edDataSouceFilePath.Text);
    if showModal =mrOk then
    begin
      edDataSouceFilePath.Text := FGetPathStr;

    end;
  finally
    Free;
  end;
end;

procedure TfrmDataSrcParam.rgrpDriverNameClick(Sender: TObject);
begin
  edLibraryName.Enabled := rgrpDriverName.ItemIndex >0;
end;


end.


