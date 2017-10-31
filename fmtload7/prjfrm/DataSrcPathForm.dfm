object frmDataSrcPath: TfrmDataSrcPath
  Left = 520
  Top = 343
  BorderStyle = bsDialog
  Caption = #1055#1072#1087#1082#1080' '#1080#1089#1090#1086#1095#1085#1080#1082#1072' '#1076#1072#1085#1085#1099#1093
  ClientHeight = 321
  ClientWidth = 352
  Color = clBtnFace
  Constraints.MinHeight = 300
  Constraints.MinWidth = 352
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    352
    321)
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 352
    Height = 277
    Align = alTop
    TabOrder = 0
    object Bevel1: TBevel
      Left = 8
      Top = 16
      Width = 333
      Height = 257
      Shape = bsFrame
    end
    object Label1: TLabel
      Left = 16
      Top = 24
      Width = 148
      Height = 13
      Caption = #1055#1072#1087#1082#1080' '#1087#1086' '#1087#1086#1088#1103#1076#1082#1091' '#1087#1088#1086#1089#1084#1086#1090#1088#1072
    end
    object Label2: TLabel
      Left = 16
      Top = 176
      Width = 163
      Height = 13
      Caption = #1074#1099#1076#1077#1083#1077#1085#1099' '#1085#1077#1076#1086#1087#1091#1089#1090#1080#1084#1099#1077' '#1087#1072#1087#1082#1080
    end
    object edPath: TEdit
      Left = 20
      Top = 192
      Width = 245
      Height = 21
      TabOrder = 0
      OnChange = edPathChange
    end
    object btEditSrcPath: TButton
      Left = 267
      Top = 188
      Width = 25
      Height = 25
      Caption = '...'
      TabOrder = 1
      OnClick = btEditSrcPathClick
    end
    object btnReplace: TBitBtn
      Left = 20
      Top = 232
      Width = 75
      Height = 25
      Caption = #1047#1072#1084#1077#1085#1080#1090#1100
      TabOrder = 2
      OnClick = btnReplaceClick
    end
    object btnAdd: TBitBtn
      Left = 102
      Top = 232
      Width = 75
      Height = 25
      Caption = #1044#1086#1073#1072#1074#1080#1090#1100
      TabOrder = 3
      OnClick = btnAddClick
    end
    object btnDelete: TBitBtn
      Left = 184
      Top = 232
      Width = 75
      Height = 25
      Caption = #1059#1076#1072#1083#1080#1090#1100
      TabOrder = 4
      OnClick = btnDeleteClick
    end
    object lstbSrcPaths: TListBox
      Left = 20
      Top = 44
      Width = 241
      Height = 121
      Style = lbOwnerDrawFixed
      ItemHeight = 16
      TabOrder = 5
      OnClick = lstbSrcPathsClick
      OnDrawItem = lstbSrcPathsDrawItem
    end
    object btnDown: TBitBtn
      Left = 264
      Top = 127
      Width = 25
      Height = 25
      TabOrder = 6
      OnClick = btnDownClick
      Glyph.Data = {
        66010000424D6601000000000000760000002800000014000000140000000100
        040000000000F000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        3333333300003333333333333333333300003333333333333333333300003333
        3333337333333333000033333333347733333333000033333333CC4773333333
        00003333333CCCC4773333330000333333CCCCCC47733333000033333CCCCCC4
        4433333300003333333CCCC47333333300003333333CCCC47333333300003333
        333CCCC47333333300003333333CCCC47333333300003333333CCCC473333333
        00003333333CCCC4333333330000333333333333333333330000333333333333
        3333333300003333333333333333333300003333333333333333333300003333
        33333333333333330000}
    end
    object btnUp: TBitBtn
      Left = 264
      Top = 95
      Width = 25
      Height = 25
      TabOrder = 7
      OnClick = btnUpClick
      Glyph.Data = {
        66010000424D6601000000000000760000002800000014000000140000000100
        040000000000F000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        3333333300003333333333333333333300003333333333333333333300003333
        333333333333333300003333333333333333333300003333333CCCC433333333
        00003333333CCCC47333333300003333333CCCC47333333300003333333CCCC4
        7333333300003333333CCCC47333333300003333333CCCC47333333300003333
        3CCCCCC4443333330000333333CCCCCC4773333300003333333CCCC477333333
        000033333333CC47733333330000333333333477333333330000333333333373
        3333333300003333333333333333333300003333333333333333333300003333
        33333333333333330000}
    end
  end
  object btnCancel: TBitBtn
    Left = 268
    Top = 288
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object Ok: TBitBtn
    Left = 184
    Top = 288
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Ok'
    ModalResult = 1
    TabOrder = 2
  end
end
