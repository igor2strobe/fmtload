object frmDataSrcParam: TfrmDataSrcParam
  Left = 317
  Top = 333
  ActiveControl = edDataSourceName
  BorderStyle = bsDialog
  Caption = #1087#1072#1088#1072#1084#1077#1090#1088#1099' '#1080#1089#1090#1086#1095#1085#1080#1082#1072' '#1076#1072#1085#1085#1099#1093
  ClientHeight = 322
  ClientWidth = 374
  Color = clBtnFace
  Constraints.MinHeight = 360
  Constraints.MinWidth = 370
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 220
    Top = 8
    Width = 66
    Height = 13
    Caption = #8470' '#1080#1089#1090#1086#1095#1085#1080#1082#1072
    FocusControl = edCorrID
  end
  object Label2: TLabel
    Left = 12
    Top = 8
    Width = 76
    Height = 13
    Caption = #1053#1072#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077
    FocusControl = edDataSourceName
  end
  object Label3: TLabel
    Left = 12
    Top = 132
    Width = 215
    Height = 13
    Caption = 'DLL-'#1073#1080#1073#1083#1080#1086#1090#1077#1082#1072' '#1086#1073#1088#1072#1073#1086#1090#1095#1080#1082#1072' '#1090#1080#1087#1072' '#1076#1072#1085#1085#1099#1093
    FocusControl = edLibraryName
  end
  object Label4: TLabel
    Left = 12
    Top = 180
    Width = 127
    Height = 13
    Caption = #1055#1072#1087#1082#1080' '#1080#1089#1090#1086#1095#1085#1080#1082#1072' '#1076#1072#1085#1085#1099#1093
    FocusControl = edDataSouceFilePath
  end
  object edCorrID: TEdit
    Left = 220
    Top = 24
    Width = 101
    Height = 21
    ReadOnly = True
    TabOrder = 1
  end
  object edDataSourceName: TEdit
    Left = 12
    Top = 24
    Width = 197
    Height = 21
    TabOrder = 0
  end
  object edLibraryName: TEdit
    Left = 12
    Top = 148
    Width = 217
    Height = 21
    TabOrder = 3
  end
  object edDataSouceFilePath: TEdit
    Left = 12
    Top = 196
    Width = 313
    Height = 21
    TabOrder = 4
  end
  object rgrpDriverName: TRadioGroup
    Left = 12
    Top = 60
    Width = 313
    Height = 61
    Caption = ' '#1090#1080#1087' '#1076#1072#1085#1085#1085#1099#1093' '
    Columns = 2
    Items.Strings = (
      '1CClientBankExchange'
      #1076#1072#1085#1085#1099#1077' '#1074' '#1090#1077#1082#1089#1090'.'#1092#1086#1088#1084#1077
      'XML'
      'MSIE/HTML')
    TabOrder = 2
    TabStop = True
    OnClick = rgrpDriverNameClick
  end
  object pnBottonForm: TPanel
    Left = 0
    Top = 266
    Width = 374
    Height = 56
    Align = alBottom
    TabOrder = 5
    object cbHide: TCheckBox
      Left = 8
      Top = 32
      Width = 201
      Height = 17
      TabStop = False
      Caption = #1086#1090#1082#1083#1102#1095#1080#1090#1100' '#1080#1089#1090#1086#1095#1085#1080#1082
      TabOrder = 0
    end
    object bbtnOk: TBitBtn
      Left = 168
      Top = 8
      Width = 75
      Height = 25
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 1
      NumGlyphs = 2
      Style = bsNew
    end
    object bBtnCancel: TBitBtn
      Left = 260
      Top = 9
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 2
      NumGlyphs = 2
    end
  end
  object btEditSrcPath: TButton
    Left = 332
    Top = 196
    Width = 25
    Height = 25
    Caption = '...'
    TabOrder = 6
    OnClick = btEditSrcPathClick
  end
end
