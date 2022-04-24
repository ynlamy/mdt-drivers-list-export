program mdtdriverslistexport;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  Dom, XMLRead;

type

  { TMDTDriversListExport }

  TMDTDriversListExport = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteVersion; virtual;
    procedure WriteLicense; virtual;
    procedure WriteHelp; virtual;
    procedure WriteDeploymentShareNotFound; virtual;
    procedure WriteDriverGroupsXMLNotFound; virtual;
    procedure WriteFileAlreadyExists(Filename: String); virtual;
  end;

{ TMDTDriversListExport }

procedure TMDTDriversListExport.DoRun;
var
  ErrorMsg, DeploymentShare, Filename, OS, DriverGroupsXML, DriverName: String;
  XMLDocument: TXMLDocument;
  Child: TDOMNode;
  F: TextFile;
begin
  // check parameters
  ErrorMsg := CheckOptions('d: f: o: hv', 'deploymentshare: filename: os: help version');
  if ErrorMsg <> '' then
  begin
    WriteVersion;
    WriteHelp;
    Terminate;
    Exit;
  end;

  if HasOption('h', 'help') then
  begin
    WriteVersion;
    WriteHelp;
    Terminate;
    Exit;
  end;

  if (HasOption('v', 'version')) then
  begin
    WriteVersion;
    WriteLicense;
    Terminate;
    Exit;
  end;

  // get values in parameters
  DeploymentShare := GetOptionValue('d', 'deploymentshare');
  Filename := GetOptionValue('f', 'filename');
  OS := GetOptionValue('o', 'os');

  // default values
  if DeploymentShare = '' then
    DeploymentShare := 'E:\DeploymentShare';

  if Filename = '' then
    Filename := GetUserDir + '\mdt-drivers-list-export.csv';

  if OS = '' then
    OS := 'Windows 10 x64';

  // verify directory exist
  if DirectoryExists(DeploymentShare) then
  begin
    DriverGroupsXML := DeploymentShare + '\Control\DriverGroups.xml';
    // verify file not exist
    if FileExists(DriverGroupsXML) = false then
    begin
      WriteDriverGroupsXMLNotFound;
      Terminate;
      ExitCode := 2;
      Exit;
    end;
  end
  else
  begin
    WriteDeploymentShareNotFound;
    Terminate;
    ExitCode := 3;
    Exit;
  end;

  // verify file not exist
  if FileExists(Filename) then
  begin
    WriteFileAlreadyExists(ExtractFileName(Filename));
    Terminate;
    ExitCode := 2;
    Exit
  end;

  // drivers list export
  try
    AssignFile(F, Filename);
    Rewrite(F);
    ReadXMLFile(XMLDocument, DriverGroupsXML);
    Child := XMLDocument.DocumentElement.FirstChild; // {00000000-0000-0000-0000-000000000000}
    Child := Child.NextSibling; // {FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF}
    Child := Child.NextSibling;
    while Assigned(Child) do
    begin
      if Child.ChildNodes.Count > 6 then
      begin
        DriverName := AnsiString(Child.ChildNodes.Item[0].TextContent);
        if Copy(DriverName, 1, Length(OS)) = OS then
          writeln(F, StringReplace(Copy(DriverName, Length(OS) + 2), '\', ',', [rfReplaceAll]));
      end;
      Child := Child.NextSibling;
    end;
    writeln('Drivers list export in the file ''' + ExtractFileName(Filename) + '''');
  finally
    XMLDocument.Free;
    CloseFile(F);
  end;

  Terminate;
end;

constructor TMDTDriversListExport.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TMDTDriversListExport.Destroy;
begin
  inherited Destroy;
end;

procedure TMDTDriversListExport.WriteVersion;
begin
  writeln('MDT Drivers List Export 1.0 : Copyright (c) 2022 Yoann LAMY');
  writeln();
end;

procedure TMDTDriversListExport.WriteLicense;
begin
  writeln('You may redistribute copies of the program under the terms of the GNU General Public License v3 : https://github.com/ynlamy/mdt-drivers-list-export.');
  writeln('This program come with ABSOLUTELY NO WARRANTY.');
end;

procedure TMDTDriversListExport.WriteHelp;
begin
  writeln('Usage : ', ExeName, ' [-d <directory>] [-o <osname>] [-f <filename>]');
  writeln();
  writeln('-d, --deploymentshare : Deployment share (default: E:\DeploymentShare)');
  writeln('-f, --filename : Filename to export the drivers list in CSV format (default: %USERPROFILE%\mdt-drivers-list-export.csv)');
  writeln('-o, --os : Operating system name and version (default: Windows 10 x64)');
  writeln('-h, --help : Print this help screen');
  writeln('-v, --version : Print the version of the program and exit');
end;

procedure TMDTDriversListExport.WriteDeploymentShareNotFound;
begin
  writeln('deployment share not found');
end;

procedure TMDTDriversListExport.WriteDriverGroupsXMLNotFound;
begin
  writeln('file ''DriverGroups.xml'' not found');
end;

procedure TMDTDriversListExport.WriteFileAlreadyExists(Filename: String);
begin
  writeln('file ''' + Filename + ''' already exists');
end;

var
  Application: TMDTDriversListExport;

{$R *.res}

begin
  Application := TMDTDriversListExport.Create(nil);
  Application.Run;
  Application.Free;
end.

