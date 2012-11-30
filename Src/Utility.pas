//-----------------------------------------
// Maciej Czekañski
// maves90@gmail.com
//-----------------------------------------

unit Utility;

//---------------------------------------------------------------
interface
//---------------------------------------------------------------

uses Windows;

// Zapisuje podan¹ wiadomoœæ do pliku oraz na konsoli
procedure Log(msg: string);
// Zwraca aktualny czas w sekundach.
function GetTime: Double;


//---------------------------------------------------------------
implementation
//---------------------------------------------------------------

VAR
	gLogFile : Text;
	gTimerFrequency : Double;

// Inicjalizuje logger
procedure InitLogger;
begin
	Assign(gLogFile, 'log.txt');
	Rewrite(gLogFile);
	WriteLn(gLogFile, 'Log file created');
end;

// Inicjalizuje timer
procedure InitTimer;
VAR
	li: Int64;
begin
	if QueryPerformanceFrequency(li) = false then
	begin
		Log('Cant init timer');
	end
	else
		Log('Timer initialized');
	
	gTimerFrequency := 1.0/li;
end;

function GetTime: Double;
VAR
	li: Int64;
begin
	QueryPerformanceCounter(li);
	GetTime:= li*gTimerFrequency;
end;

procedure Log(msg: string);
begin
	Append(gLogFile);
	WriteLn(gLogFile, msg);
	Close(gLogFile);
	WriteLn(msg);
end;


begin
	InitLogger;
	InitTimer;
end.




