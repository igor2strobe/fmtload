unit winProcess;

interface
uses Windows;

function WinExecAndWait32(FileName: string; Visibility: Integer): dWord;


implementation


function WinExecAndWait32(FileName: string; Visibility: Integer): dWord;
var
  zAppName: array[0..512] of Char;
  zCurDir: array[0..255] of Char;
  WorkDir: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  StrPCopy(zAppName, FileName);
  GetDir(0, WorkDir);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
 
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess(nil,
           zAppName, { pointer to command line string }
           nil, { pointer to process security attributes }
           nil, { pointer to thread security attributes }
           false, { handle inheritance flag }
           CREATE_NEW_CONSOLE or { creation flags }
           NORMAL_PRIORITY_CLASS,
           nil, { pointer to new environment block }
           nil, { pointer to current directory name }
           StartupInfo, { pointer to STARTUPINFO }
           ProcessInfo) then
    Result := -1 { pointer to PROCESS_INF }
  else
  begin
    WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, Result);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
end;

end;
