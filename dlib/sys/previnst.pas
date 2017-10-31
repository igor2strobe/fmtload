unit previnst;

interface
uses Windows;

var
  InstanceOnLive: boolean; //��� ���������� ���� true �� ��������� ��� ��������

function IsAlreadyProcessStarted( processName: pAnsiChar): bool;

implementation

function IsAlreadyProcessStarted;
var
  hMutex: integer;
begin
  InstanceOnLive := FALSE;
  hMutex := CreateMutex(nil, TRUE, processName); // ������� �������
  InstanceOnLive := GetLastError <>0; // ������ ������� ��� ������
  result := InstanceOnLive;
  ReleaseMutex(hMutex);
end;
end.

