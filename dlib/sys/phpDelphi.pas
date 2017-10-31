
procedure Explode(var a: array of string; Border, S: string);
var
  S2: string;
  i: Integer;
begin
  i := 0;
  S2 := S + Border;
  repeat
    //setlength(a, i+1);
    try
      a[i] := Copy(S2, 0, Pos(Border, S2) - 1);
    except
    end;
    Delete(S2, 1, Length(a[i] + Border));
    Inc(i);
  until S2 = '';
end;