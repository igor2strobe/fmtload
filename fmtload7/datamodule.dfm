object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Left = 644
  Top = 236
  Height = 507
  Width = 366
  object ApplicationEvents: TApplicationEvents
    OnActivate = ApplicationEventsActivate
    OnDeactivate = ApplicationEventsDeactivate
    Left = 36
    Top = 68
  end
  object mdTemplate: TRxMemoryData
    AutoCalcFields = False
    FieldDefs = <
      item
        Name = 'UIN_Corr_Acnt'
        DataType = ftInteger
      end
      item
        Name = 'Corr_Acnt_Name'
        DataType = ftString
        Size = 64
      end
      item
        Name = 'CH_Curr'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ID_Curr'
        DataType = ftInteger
      end
      item
        Name = 'CA_Doc_Date'
        DataType = ftDate
      end
      item
        Name = 'CA_Document'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'CA_Pay_Date'
        DataType = ftDate
      end
      item
        Name = 'CA_Summ_Debt'
        DataType = ftFloat
      end
      item
        Name = 'CA_Summ_Cred'
        DataType = ftFloat
      end
      item
        Name = 'Pay_Comment'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'Debet_Cli_Name'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'Debet_Cli_Acnt'
        DataType = ftString
        Size = 26
      end
      item
        Name = 'Debet_Cli_Inn'
        DataType = ftString
        Size = 14
      end
      item
        Name = 'Debet_Bank_Name'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'Debet_Bank_Bic'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Debet_Bank_Acnt'
        DataType = ftString
        Size = 24
      end
      item
        Name = 'Credit_Cli_Name'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'Credit_Cli_Acnt'
        DataType = ftString
        Size = 26
      end
      item
        Name = 'Credit_Cli_Inn'
        DataType = ftString
        Size = 14
      end
      item
        Name = 'Credit_Bank_Name'
        DataType = ftString
        Size = 255
      end
      item
        Name = 'Credit_Bank_Bic'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Credit_Bank_Acnt'
        DataType = ftString
        Size = 24
      end
      item
        Name = 'Input_Value'
        DataType = ftFloat
      end
      item
        Name = 'Out_Value'
        DataType = ftFloat
      end
      item
        Name = 'Deb_Cred'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'Stamp'
        DataType = ftFloat
      end
      item
        Name = 'CA_Doc_Org'
        DataType = ftString
        Size = 255
      end>
    Left = 40
    Top = 124
  end
  object OraSession: TOraSession
    Username = 'strobe2011'
    Password = 'smolensk'
    Server = 'logsys'
    LoginPrompt = False
    AfterConnect = OraSessionAfterConnect
    Left = 212
    Top = 36
  end
  object orqryLogon: TOraQuery
    Session = OraSession
    Left = 276
    Top = 84
  end
  object orqryDataSrc: TOraQuery
    Session = OraSession
    Left = 252
    Top = 160
  end
  object dsDataSrc: TDataSource
    DataSet = orqryDataSrc
    OnDataChange = dsDataSrcDataChange
    Left = 228
    Top = 204
  end
  object orqLockAccounts: TOraQuery
    Session = OraSession
    Left = 172
    Top = 104
  end
end
