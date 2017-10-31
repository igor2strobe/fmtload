unit previnst;

interface
uses Windows;

var
  InstanceOnLive: boolean; //эта переменная если true то программа уже запущена

function IsAlreadyProcessStarted( processName: pAnsiChar): bool;

implementation

function IsAlreadyProcessStarted;
var
  hMutex: integer;
begin
  InstanceOnLive := FALSE;
  hMutex := CreateMutex(nil, TRUE, processName); // Создаем семафор
  InstanceOnLive := GetLastError <>0; // Ошибка семафор уже создан
  result := InstanceOnLive;
  ReleaseMutex(hMutex);
end;
end.

