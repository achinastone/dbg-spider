Unit DebugInfo;

Interface

Uses
  SysUtils, Windows, Classes, Debuger, DebugerTypes, Generics.Collections, Generics.Defaults;

Type
  TFindResult = (slNotFound = 0, slFoundExact, slFoundNotExact, slFoundWithoutLine);

Type
  TSegmentCodeInfo = Class;
  TUnitInfo = Class;
  TFuncInfo = Class;
  TTypeInfo = Class;
  TUnitSourceModuleInfo = class;

  TLineInfo = Class
  public
    LineNo: Integer;
    Address: Pointer;
    SrcSegment: TUnitSourceModuleInfo;
  End;

  TLineInfoList = TObjectList<TLineInfo>;

  TTypeKind = (tkBoolean, tkWordBool, tkLongBool, tkShortInt, tkSmallInt, tkInteger, tkInt64, tkByte, tkWord, tkCardinal, tkUInt64, tkSingle, tkReal48, tkReal, tkExtended, tkCurrency, tkComplex,
    tkPString, tkLString, tkWString, tkChar, tkPointer, tkSubRange, tkArray, tkEnum, tkStructure, tkClass, tkSet, tkVariant, tkProperty, tkFieldList, tkClosure, tkClassRef, tkWideChar, tkProcedure,
    tkArgList, tkMFunction, tkVoid, tkObject, tkDynamicArray);

  TNameId = type Integer;

  TNameInfo = Class(TObject)
  public
    NameId: Integer;
    SymbolInfo: TObject; // ��������� �� TJclTD32SymbolInfo

    function Name: AnsiString; virtual; abstract;
    function ShortName: String; virtual; abstract;
  End;

  TNameIdList = TDictionary<TNameId, TNameInfo>;

  TNameList = Class(TList)
  private
    FNameIdList: TNameIdList;
    FFreeItems: LongBool;
    function GetNameInfoItem(const Index: Integer): TNameInfo;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    procedure CheckNameIdList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear; override;

    function FindByName(Const Name: AnsiString; const SubStr: LongBool = False): TNameInfo;
    function FindByNameId(Const NameId: TNameId): TNameInfo;

    property NameInfoItems[const Index: Integer]: TNameInfo read GetNameInfoItem; default;
    property FreeItems: LongBool read FFreeItems write FFreeItems;
  End;

  TTypeInfo = Class(TNameInfo)
  public
    Kind: TTypeKind;
    BaseType: TTypeInfo;
    DataSize: Integer;
    MinValue: Integer;
    MaxValue: Integer;
    IndexType: TTypeInfo;

    Members: TNameList;
    Elements: TNameList;

    UnitInfo: TUnitInfo;
    TypeInfoIdx: Integer; // Index in UnitInfo.Types

    Constructor Create;
    Destructor Destroy; Override;

    function Name: AnsiString; override;
    function ShortName: String; override;

    function KindAsString: String;
    function TypeOf: String;
    function ElementsToString: String;
  end;

  TEnumInfo = Class(TNameInfo)
  public
    TypeInfo: TTypeInfo;
    OrderValue: Integer;

    function Name: AnsiString; override;
    function ShortName: String; override;
  End;

  TConstInfo = Class(TNameInfo)
  private
    FValue: Variant;
    procedure SetValue(const Value: Variant);
  public
    TypeInfo: TTypeInfo;
    Owner: TSegmentCodeInfo;

    function Name: AnsiString; override;
    function ShortName: String; override;

    function UnitInfo: TUnitInfo;

    function ValueAsString: String;

    property Value: Variant read FValue write SetValue;
  End;

  TRegInfo = Class
  public
    StartOffset: Cardinal;
    EndOffset: Cardinal;
    RegisterIndex: Integer;
  End;

  TVarKind = (vkGlobal, vkStack, vkRegister, vkLink, vkTLS);

  TVarInfo = Class(TNameInfo)
  public
    DataType: TTypeInfo;
    Owner: TSegmentCodeInfo;
    VarKind: TVarKind;
    // IsPointer      : LongBool;
    // ByRef          : LongBool;
    Offset: Integer;
    RegisterRanges: TList;

    Constructor Create;
    Destructor Destroy; Override;

    function UnitInfo: TUnitInfo;

    function Name: AnsiString; override;
    function ShortName: String; override;

    function DataTypeName: String;

    function AsString: String;

    function Value: Variant;
  End;

  TMemberScope = (msPrivate, msProtected, msPublic);

  TStructMember = Class(TNameInfo)
  public
    DataType: TTypeInfo;
    Offset: Integer;
    DataSize: Integer;
    Scope: TMemberScope;
    AliasNameId: TNameId;
    MethodNameId: TNameId;
    Method: TFuncInfo; // read function for properties
    IsDefault: LongBool; // true for default property

    function Alias: AnsiString; // read field for properties
    function MethodName: AnsiString; // read function name for properties

    function Name: AnsiString; override;
    function ShortName: String; override;
  end;

  // .text,.itext,.data,.bss,.tls,.pdata,.idata,.didata,.rdata,.reloc,.rsrc
  TSegmentType = (ustUnknown = 0, ustCode, ustICode, ustData, ustBSS, ustTLS, ustPData, ustIData, ustDIData, ustRData, ustReloc, ustSrc);

  TSegmentClassInfo = class
  public
    Address: Pointer;
    Size: Cardinal;
    SegType: TSegmentType;
    ID: Word;

    function SegTypeName: String;
    class function StrToSegmentType(const Str: String): TSegmentType; static;
  end;

  TUnitSegmentInfo = Class
  public
    UnitInfo: TUnitInfo;
    Address: Pointer;
    Size: Cardinal;
    SegmentClassInfo: TSegmentClassInfo;
  End;

  TUnitSourceModuleInfo = Class(TNameInfo)
  public
    UnitInfo: TUnitInfo;
    Lines: TLineInfoList;
    Address: Pointer;

    Constructor Create;
    Destructor Destroy; Override;

    Procedure Clear; Virtual;

    function Name: AnsiString; Override;
    function ShortName: String; override;

    function FullUnitName: String;
  End;

  TDebugInfo = Class;

  TSegmentCodeInfo = Class(TNameInfo)
  public
    Address: Pointer;
    Size: Cardinal;

    Consts: TNameList;
    Types: TNameList;
    Vars: TNameList;
    Funcs: TNameList;

    Lines: TLineInfoList;

    Constructor Create;
    Destructor Destroy; Override;

    function Name: AnsiString; override;
    function ShortName: String; override;

    Procedure Clear; Virtual;

    function FindTypeByName(const TypeName: AnsiString; const SubStr: LongBool = False): TTypeInfo;
    function FindFuncByName(const FuncName: AnsiString; const SubStr: LongBool = False): TFuncInfo;
    function FindFuncByNameId(const FuncNameId: Integer): TFuncInfo;
    function FindConstByName(const ConstName: AnsiString; const SubStr: LongBool = False): TConstInfo;
    function FindVarByName(const VarName: AnsiString; const SubStr: LongBool = False): TVarInfo;

    function CheckAddress(const Addr: Pointer): Integer;
  End;

  ISegmentCodeInfoComparer = IComparer<TSegmentCodeInfo>;

  TSegmentCodeInfoComparer = class(TInterfacedObject, ISegmentCodeInfoComparer)
  public
    function Compare(const Left, Right: TSegmentCodeInfo): Integer;
  end;

  TSegmentCodeInfoList = Class(TList<TSegmentCodeInfo>)
  private
    FSorted: LongBool;
  public
    constructor Create;
    destructor Destroy; override;

    procedure CheckSorted;
    procedure UpdateSort;

    function FindByAddress(const Address: Pointer): TSegmentCodeInfo;
  End;

  TFuncInfo = Class(TSegmentCodeInfo)
    UnitInfo: TUnitInfo;
    UnitSegment: TUnitSegmentInfo;

    Params: TNameList; // TODO: �������� ��������� �� Vars

    ResultType: TTypeInfo;

    Parent: TFuncInfo;
    ID: TObject;
    ParentID: TObject;

    Constructor Create;
    Destructor Destroy; Override;

    function ShortName: String; override;

    function ParamsAsString: String;
  End;

  TUnitType = (utProject, utSystem, utComponentLib, utExternal, utUnknown);

  TUnitInfo = Class(TSegmentCodeInfo)
  protected
    function GetUnitType: TUnitType;
  public
    Segments: TList;
    SourceSegments: TList;
    UsedUnits: TStringList;
    FuncsByAddr: TSegmentCodeInfoList;

    Constructor Create;
    Destructor Destroy; Override;

    Procedure Clear; Override;

    function ShortName: String; Override;

    function FullUnitName: String;

    function FindSegmentByAddr(const Addr: Pointer; const SegmentID: Word = 0): TUnitSegmentInfo;
    function FindSourceSegmentByNameId(const NameId: TNameId): TUnitSourceModuleInfo;
    function FindSourceSegmentByAddr(const Addr: Pointer): TUnitSourceModuleInfo;

    property UnitType: TUnitType read GetUnitType;
  end;

  TDLLInfo = Class(TSegmentCodeInfo)

  End;

  PAddressInfo = ^RAddressInfo;

  RAddressInfo = record
    Addr: Pointer;
    UnitInfo: TUnitInfo;
    FuncInfo: TFuncInfo;
    LineInfo: TLineInfo;
    FindResult: TFindResult;
  end;

  TAddressInfoList = class(TDictionary<Pointer, PAddressInfo>)
  private
    FLock: TMREWSync;
  protected
    procedure ValueNotify(const Value: PAddressInfo; Action: TCollectionNotification); override;
  public
    constructor Create(ACapacity: Integer = 0);
    destructor Destroy; override;

    property Lock: TMREWSync read FLock;
  end;

  TStackEntry = Class
  Public
    UnitInfo: TUnitInfo;
    FuncInfo: TFuncInfo;
    LineInfo: TLineInfo;
    EIP: Pointer;
    RET: Pointer;
    EBP: Pointer;

    Constructor Create;
    Function GetInfo: String;
    Function UpdateInfo(Const Addr: Pointer = nil): TFindResult;
  End;

  TDebugInfoProgressCallback = procedure(const Action: String; const Progress: Integer) of object;

  TDbgSourceDirListItem = record
    ShortFileName: String;
    FileName: String;
    HashCode : Cardinal;
  end;

  TDbgSourceDirList = class
  private
    FBuckets: array of TDbgSourceDirListItem;
    FCount: Integer;
    FGrowth: Integer;
    FCapacity: Integer;
  protected
    procedure Grow;
    function LinearFind(const HashCode: Cardinal; const ShortFileName: String; var Index : Integer): Boolean;
    function SameItem(const HashCode1, HashCode2: Cardinal; const ShortFileName1, ShortFileName2: String): Boolean;
    function GetItemHashCode(const ShortFileName: String): Integer;
  public
    function Add(const FileName: String): Boolean;
    function Contains(const ShortFileName: String): Boolean;
    function TryGetValue(const ShortFileName: String; out FileName: String): Boolean;
    procedure Clear;

    property Count : Integer read FCount;
  end;

  TDbgSourceList = Array [Low(TUnitType) .. High(TUnitType)] of TDbgSourceDirList;

  TMemoryManagerInfo = class
  public
    VarInfo: TVarInfo;
    GetMem: TFuncInfo;
    FreeMem: TFuncInfo;
    ReallocMem: TFuncInfo;
    AllocMem: TFuncInfo;

    constructor Create;
    procedure Clear;
  end;

  TRTLInfo = class
  public
    vmtClassNameInfo: TConstInfo;

    constructor Create;
    procedure Clear;

    function vmtClassName: Integer;
  end;

  TDebugInfoClass = Class Of TDebugInfo;

  TDebugInfo = Class
  Private
    FDirs: TDbgSourceList;
    FSegments: TStringList;
    FUnits: TStringList; // Sorted by name
    FUnitsByAddr: TSegmentCodeInfoList; // Sorted by Address
    FDbgLog: TDbgLog;
    FMemoryManagerInfo: TMemoryManagerInfo;
    FRTLInfo: TRTLInfo;

    FExeFileName: String;
    FDebugInfoLoaded: LongBool;

    FDebugInfoProgressCallback: TDebugInfoProgressCallback;
    FLastProgressAction: String;
    FLastProgress: Integer;

    function GetDirs(const SourceType: TUnitType): TDbgSourceDirList;
    procedure ClearDirs;
  Protected
    FDebugInfoType: String;
    FUseShortNames: LongBool;

    procedure DoProgress(const Action: String; const Progress: Integer); virtual;
    Function DoReadDebugInfo(Const FileName: String; ALoadDebugInfo: LongBool): LongBool; Virtual; abstract;

    function GetSegmentByID(const ID: Word): TSegmentClassInfo;
    function GetSegmentByType(const SegType: TSegmentType): TSegmentClassInfo;

    function ParseUnitName(UnitInfo: TUnitInfo; const WithExt: LongBool = True): String; virtual;
    function ParseFuncName(FuncInfo: TFuncInfo): String; virtual;
    function ParseTypeName(TypeInfo: TTypeInfo): String; virtual;
    function ParseConstName(ConstInfo: TConstInfo): String; virtual;
    function ParseVarName(VarInfo: TVarInfo): String; virtual;
    function ParseStructMemberName(StructMember: TStructMember): String; virtual;
  Public
    Constructor Create;
    Destructor Destroy; Override;

    Procedure ClearDebugInfo; Virtual;
    Function HasDebugInfo(Const FileName: String): LongBool; Virtual; abstract;
    Function ReadDebugInfo(Const FileName: String): LongBool; Virtual;
    Function GetFileCount: Integer; Virtual;
    Function GetFile(Index: Integer): String; Virtual;
    Function GetTypeInfo(Const TypeName: String): TTypeInfo; Virtual;
    Function GetAddrInfo(Var Addr: Pointer; Const FileName: String; Line: Cardinal): TFindResult; Virtual; abstract;
    Procedure GetCallStackItems(const ThreadID: TThreadId; Const ExceptAddr, ExceptFrame: Pointer; StackItems: TList); Virtual;

    Function GetLineInfo(const Addr: Pointer; Var UnitInfo: TUnitInfo; Var FuncInfo: TFuncInfo; Var LineInfo: TLineInfo; GetPrevLine: LongBool): TFindResult; Virtual; abstract;
    Function GetLineInformation(const Addr: Pointer; Var UnitName: String; Var FuncName: String; Var Line: LongInt; GetPrevLine: LongBool): TFindResult; Virtual;

    procedure UpdateSourceDirs(const SourceType: TUnitType; const SourceDirs: String); virtual;
    procedure AddSourceDir(const SourceDir: TDbgSourceDirList; const Dir: String; const Recursive: LongBool = True); virtual;

    function FullUnitName(const UnitName: String): String;
    function GetUnitType(const UnitName: String): TUnitType;

    Function MakeFuncDbgFullName(Const ClassName, MethodName: AnsiString): AnsiString; Virtual; abstract;
    Function MakeFuncShortName(Const MethodName: AnsiString): AnsiString; Virtual; abstract;
    Function MakeFuncNativeName(Const MethodName: AnsiString): AnsiString; Virtual; abstract;

    Function FuncByName(const FuncName: AnsiString): TFuncInfo;

    Function Evaluate(BriefMode: LongBool; Const Expression: String; Const TimeOut: Cardinal = INFINITE): String; Virtual; abstract;

    Function EvaluateVariable(VarInfo: TVarInfo): Variant; virtual; abstract;
    Function VarValueAsString(const Value: Variant): String; virtual; abstract;

    procedure SetMemoryManagerBreakpoints; Virtual; abstract;
    procedure ResetMemoryManagerBreakpoints; Virtual; abstract;

    Procedure InitDebugHook; Virtual; abstract;

    Function GetNameById(const Idx: TNameId): AnsiString; virtual; abstract;

    Function CheckAddr(Const Addr: Pointer): LongBool; Virtual;
    Function DumpLineInformation(Const Addr: Pointer): String;
    Function GetParamsStr(FuncInfo: TFuncInfo; Const EBP: Pointer; IsTopStack: LongBool): String;

    Function GetClassName(Const ObjectPtr: Pointer): String; Virtual; abstract;
    Function GetExceptionName(ExceptionRecord: PExceptionRecord): String; Virtual;
    Function GetExceptionMessage(ExceptionRecord: PExceptionRecord; const ThreadID: TThreadId): String; Virtual;
    Function GetExceptionAddress(ExceptionRecord: PExceptionRecord): Pointer; Virtual;
    Function GetExceptionFrame(ExceptionRecord: PExceptionRecord): Pointer; Virtual;
    Function CheckDebugException(ExceptionRecord: PExceptionRecord; Var IsTraceException: LongBool): LongBool; Virtual;
    Function CheckSystemFile(Const FileName: String): LongBool; Virtual; abstract;

    Function IsSystemException(Const ExceptionCode: DWORD): LongBool;

    Function CheckDebugOutputMessage(DebugEvent: PDebugEvent): LongBool;
    Function ProcessDebugOutputMessage(Const Msg: WideString; DebugEvent: PDebugEvent): LongBool; Virtual;

    Function IsValidAddr(Const Addr: Pointer): LongBool;
    Function IsValidCodeAddr(Const Addr: Pointer): LongBool;
    Function IsValidStackAddr(Const Addr: Pointer; const ThreadID: TThreadId): LongBool;
    Function IsValidDataAddr(Const Addr: Pointer; const ThreadID: TThreadId): LongBool;

    // Property SourceDirs: String read FSourceDirs;
    Property Dirs[const SourceType: TUnitType]: TDbgSourceDirList Read GetDirs;
    Property Segments: TStringList Read FSegments;
    Property Units: TStringList Read FUnits;
    Property UnitsByAddr: TSegmentCodeInfoList read FUnitsByAddr;

    Property DbgLog: TDbgLog read FDbgLog;

    property DebugInfoLoaded: LongBool read FDebugInfoLoaded;
    property DebugInfoType: String read FDebugInfoType;
    property DebugInfoProgressCallback: TDebugInfoProgressCallback read FDebugInfoProgressCallback write FDebugInfoProgressCallback;
    property UseShortNames: LongBool read FUseShortNames write FUseShortNames;
    property MemoryManagerInfo: TMemoryManagerInfo read FMemoryManagerInfo;
    property RTLInfo: TRTLInfo read FRTLInfo;
  End;

const
  // TODO: for MACOS '_text'
  SegmentTypeNames: array [TSegmentType] of String =
    ('', 'text', 'itext', 'data', 'bss', 'tls', 'pdata', 'idata', 'didata', 'rdata', 'reloc', 'rsrc');

var
  gvDebugInfo: TDebugInfo = nil;

Implementation

Uses
  ClassUtils, Variants, IOUtils, Types, System.AnsiStrings;

function IncPointer(Ptr: Pointer; Offset: Integer): Pointer; inline;
begin
  Result := Pointer(Integer(Ptr) + Offset);
end;

// SimpleStringHash and SimpleLowerCaseStringHash are taken from DWScript
// The code is probably under copyright of Eric Grange
function SimpleStringHash(const s : UnicodeString) : Cardinal; inline;
var
  i : Integer;
begin
  // modified FNV-1a using length as seed
  Result:=Length(s);
  for i:=1 to Result do
    Result:=(Result xor Ord(s[i]))*16777619;
end;

function SimpleLowerCaseStringHash(const s : UnicodeString) : Cardinal;

  function Fallback(const s : UnicodeString) : Cardinal;
  begin
    Result:=SimpleStringHash(LowerCase(s));
  end;

var
  i : Integer;
  c : Word;
begin
  // modified FNV-1a using length as seed
  Result:=Length(s);
  for i:=1 to Result do begin
    c:=Ord(s[i]);
    if c>127 then
      Exit(Fallback(s))
    else if c in [Ord('A')..Ord('Z')] then
      c:=c+(Ord('a')-Ord('A'));
    Result:=(Result xor c)*16777619;
  end;
end;


{ TDebugInfo }

Constructor TDebugInfo.Create;
var
  ST: TUnitType;
Begin
  Inherited Create;

  for ST := Low(TUnitType) to High(TUnitType) do
    FDirs[ST] := TDbgSourceDirList.Create;

  FSegments := TStringList.Create;
  FSegments.OwnsObjects := True;

  FUnits := TStringList.Create;
  FUnitsByAddr := TSegmentCodeInfoList.Create;

  FDbgLog := TDbgLog.Create;

  FExeFileName := '';
  FDebugInfoLoaded := False;
  FDebugInfoType := '';

  FDebugInfoProgressCallback := Nil;
  FLastProgressAction := '';
  FLastProgress := 0;

  FUseShortNames := True;

  FMemoryManagerInfo := TMemoryManagerInfo.Create;
  FRTLInfo := TRTLInfo.Create;
End;

Destructor TDebugInfo.Destroy;
var
  ST: TUnitType;
Begin
  ClearDebugInfo;

  FreeAndNil(FUnitsByAddr);
  FreeAndNil(FUnits);

  FreeAndNil(FSegments);

  for ST := Low(TUnitType) to High(TUnitType) do
    FreeAndNil(FDirs[ST]);

  FreeAndNil(FDbgLog);

  FreeAndNil(FMemoryManagerInfo);
  FreeAndNil(FRTLInfo);

  Inherited Destroy;
End;

procedure TDebugInfo.DoProgress(const Action: String; const Progress: Integer);
begin
  if (FLastProgressAction <> Action) or (FLastProgress <> Progress) then
  begin
    FLastProgressAction := Action;
    FLastProgress := Progress;

    if Assigned(FDebugInfoProgressCallback) then
      FDebugInfoProgressCallback(Action, Progress);
  end;
end;

procedure TDebugInfo.AddSourceDir(const SourceDir: TDbgSourceDirList; const Dir: String; const Recursive: LongBool);
const
  _PAS_EXTS: array [0 .. 2] of String = ('*.pas', '*.inc', '*.dpr');
var
  Files: TStringDynArray;
  J, I: Integer;
  FileName: String;
begin
  for J := 0 to High(_PAS_EXTS) do
  begin
    Files := TDirectory.GetFiles(Dir, _PAS_EXTS[J], TSearchOption.soAllDirectories);

    if Length(Files) > 0 then
      for I := 0 to High(Files) do
      begin
        FileName := Files[I];
        SourceDir.Add(FileName);
      end;
  end;
end;

Function TDebugInfo.CheckAddr(Const Addr: Pointer): LongBool;
Var
  UnitInfo: TUnitInfo;
  FuncInfo: TFuncInfo;
  LineInfo: TLineInfo;
Begin
  Result := GetLineInfo(Addr, UnitInfo, FuncInfo, LineInfo, False) <> slNotFound;
End;

Function TDebugInfo.CheckDebugException(ExceptionRecord: PExceptionRecord; Var IsTraceException: LongBool): LongBool;
Begin
  IsTraceException := False;
  Case ExceptionRecord^.ExceptionCode Of
    EXCEPTION_SET_THREAD_NAME, STATUS_NONCONTINUABLE_EXCEPTION:
      Result := True;
  Else
    Result := False;
  End;
End;

Procedure TDebugInfo.ClearDebugInfo;
Begin
  If FDebugInfoLoaded Then
  Begin
    FDebugInfoLoaded := False;

    ClearDirs;

    FUnitsByAddr.Clear;
    ClearStringList(FUnits);

    FDbgLog.ClearLog;

    FMemoryManagerInfo.Clear;
    FRTLInfo.Clear;

    FExeFileName := '';
  End;
End;

procedure TDebugInfo.ClearDirs;
var
  ST: TUnitType;
begin
  for ST := Low(TUnitType) to High(TUnitType) do
    FDirs[ST].Clear;
end;

Function TDebugInfo.ReadDebugInfo(Const FileName: String): LongBool;
Begin
  Result := FDebugInfoLoaded And SameText(FExeFileName, FileName);

  If Not Result Then
  Begin
    Result := DoReadDebugInfo(FileName, True);

    If Result Then
    Begin
      FExeFileName := FileName;
      FDebugInfoLoaded := True;
    End;
  End;
End;

procedure TDebugInfo.UpdateSourceDirs(const SourceType: TUnitType; const SourceDirs: String);
var
  SL: TStringList;
  I: Integer;
  S: String;
begin
  FDirs[SourceType].Clear;

  SL := TStringList.Create;
  try
    SL.Delimiter := ';';
    SL.StrictDelimiter := True;
    SL.Duplicates := dupIgnore;

    SL.DelimitedText := SourceDirs;

    for I := 0 to SL.Count - 1 do
    begin
      S := Trim(SL[I]);
      if (S <> '') then
      begin
        S := ExcludeTrailingPathDelimiter(S);
        if DirectoryExists(S) then
          AddSourceDir(FDirs[SourceType], S, True);
      end;
    end;
  finally
    FreeAndNil(SL);
  end;
end;

Function TDebugInfo.DumpLineInformation(Const Addr: Pointer): String;
Var
  UnitName: String;
  FuncName: String;
  Line: Integer;
Begin
  If GetLineInformation(Addr, UnitName, FuncName, Line, False) <> slNotFound Then
    Result := Format('%p: %s@%s(%d)', [Pointer(Addr), UnitName, FuncName, Line])
  Else
    Result := Format('%p: no source info', [Pointer(Addr)]);
End;

function TDebugInfo.FullUnitName(const UnitName: String): String;
const
  _PAS = '.pas';
  _INC = '.inc';
  _DPR = '.dpr';
var
  Res: String;
  ResExt: String;
  ST: TUnitType;
begin
  for ST := Low(TUnitType) to High(TUnitType) do
  begin
    Res := AnsiLowerCase(UnitName);

    ResExt := ExtractFileExt(Res);

    if (Length(ResExt) <> 4) or ((ResExt <> _PAS) and (ResExt <> _INC) and (ResExt <> _DPR)) then
      Res := Res + _PAS;

    if not FDirs[ST].TryGetValue(Res, Result) then
    begin
      if not SameStr(ResExt, _PAS) then
      begin
        Res := ChangeFileExt(Res, _PAS);
        if FDirs[ST].TryGetValue(Res, Result) then
          Exit;
      end;

      if not SameStr(ResExt, _INC) then
      begin
        Res := ChangeFileExt(Res, _INC);
        if FDirs[ST].TryGetValue(Res, Result) then
          Exit;
      end;

      if not SameStr(ResExt, _DPR) then
      begin
        Res := ChangeFileExt(Res, _DPR);
        if FDirs[ST].TryGetValue(Res, Result) then
          Exit;
      end;
    end
    else
      Exit;
  end;

  Result := UnitName;
end;

function TDebugInfo.FuncByName(const FuncName: AnsiString): TFuncInfo;
var
  I: Integer;
begin
  for I := 0 to Units.Count - 1 do
  begin
    Result := TUnitInfo(Units.Objects[I]).FindFuncByName(FuncName);
    if Assigned(Result) then
      Exit;
  end;

  Result := Nil;
end;

Function TDebugInfo.GetFileCount: Integer;
Begin
  Result := FUnits.Count;
End;

function TDebugInfo.GetLineInformation(const Addr: Pointer; var UnitName, FuncName: String; var Line: Integer; GetPrevLine: LongBool): TFindResult;
Var
  UnitInfo: TUnitInfo;
  FuncInfo: TFuncInfo;
  LineInfo: TLineInfo;
Begin
  UnitName := '';
  FuncName := '';
  Line := -1;

  Result := GetLineInfo(Addr, UnitInfo, FuncInfo, LineInfo, GetPrevLine);
  If Result <> slNotFound Then
  Begin
    UnitName := UnitInfo.FullUnitName;
    FuncName := String(FuncInfo.Name);
    If LineInfo <> Nil Then
      Line := LineInfo.LineNo;
  End;
end;

Function TDebugInfo.GetFile(Index: Integer): String;
Begin
  Result := TUnitInfo(FUnits[Index]).FullUnitName;
End;

Function TDebugInfo.GetParamsStr(FuncInfo: TFuncInfo; Const EBP: Pointer; IsTopStack: LongBool): String;
// Var
// I            : Integer;
// ToStringData : TToStringData;
// ParamName    : String;
// ParamValue   : TVarInfo;
// ParamEval    : Variant;
// ParamRes     : String;
Begin
  // Result := '';
  //
  // If (FuncInfo <> Nil) And (FuncInfo.Params.Count > 0) Then
  // Begin
  // ToStringData.DebuggeeControl := DebuggeeControl;
  // ToStringData.DebugInfo       := Self;
  // ToStringData.Mode            := tsmBrief;
  // ToStringData.RecursionLevel  := 0;
  //
  // For I := 0 To FuncInfo.Params.Count - 1 Do
  // Begin
  // ParamName := FuncInfo.Params[I];
  // ParamValue := TVarInfo(FuncInfo.Params.Objects[I]);
  //
  // ParamRes := '???';
  //
  // If (EBP <> 0) And ((ParamValue.VarKind In [vkGlobal, vkStack]) Or (IsTopStack And (ParamValue.VarKind = vkRegister))) Then
  // Begin
  // Try
  // ParamEval := EvaluateVariable(DebuggeeControl, ParamValue, EBP, False);
  // ParamRes  := VariantToString(ParamEval, ToStringData);
  // Except
  // ParamRes := '[error]';
  // End;
  // End;
  //
  // If Result <> '' Then Result := Result + ', ';
  // Result := Result + Format('%s=%s', [ParamName, ParamRes]);
  // End;
  //
  // If Result <> '' Then
  // Result := '(' + Result + ')';
  // End;
End;

function TDebugInfo.GetSegmentByID(const ID: Word): TSegmentClassInfo;
var
  Idx: Integer;
begin
  for Idx := 0 to Segments.Count - 1 do
  begin
    Result := TSegmentClassInfo(Segments.Objects[Idx]);
    if Result.ID = ID then
      Exit;
  end;

  Result := Nil;
end;

function TDebugInfo.GetSegmentByType(const SegType: TSegmentType): TSegmentClassInfo;
var
  Idx: Integer;
begin
  for Idx := 0 to Segments.Count - 1 do
  begin
    Result := TSegmentClassInfo(Segments.Objects[Idx]);
    if Result.SegType = SegType then
      Exit;
  end;

  Result := Nil;
end;

Function TDebugInfo.GetTypeInfo(Const TypeName: String): TTypeInfo;
Var
  UnitInfo: TUnitInfo;
  I: Integer;
Begin
  Result := Nil;
  For I := 0 To Units.Count - 1 Do
  Begin
    UnitInfo := TUnitInfo(Units.Objects[I]);
    Result := UnitInfo.FindTypeByName(AnsiString(TypeName));
    if Result <> Nil then
      Exit;
  End;
End;

function TDebugInfo.GetUnitType(const UnitName: String): TUnitType;
begin
  for Result := Low(TUnitType) to High(TUnitType) do
  begin
    if FDirs[Result].Contains(AnsiLowerCase(UnitName)) then
      Exit;
  end;

  if CheckSystemFile(UnitName) then
  begin
    Result := utSystem;
    Exit;
  end;

  Result := utUnknown;
end;

Function TDebugInfo.GetExceptionName(ExceptionRecord: PExceptionRecord): String;
Begin
  case ExceptionRecord^.ExceptionCode of
    STATUS_ACCESS_VIOLATION:
      Result := 'EACCESS_VIOLATION';
    STATUS_ARRAY_BOUNDS_EXCEEDED:
      Result := 'EARRAY_BOUNDS_EXCEEDED';
    STATUS_FLOAT_DENORMAL_OPERAND:
      Result := 'EFLOAT_DENORMAL_OPERAND';
    STATUS_FLOAT_DIVIDE_BY_ZERO:
      Result := 'EFLOAT_DIVIDE_BY_ZERO';
    STATUS_FLOAT_INEXACT_RESULT:
      Result := 'EFLOAT_INEXACT_RESULT';
    STATUS_FLOAT_INVALID_OPERATION:
      Result := 'EFLOAT_INVALID_OPERATION';
    STATUS_FLOAT_OVERFLOW:
      Result := 'EFLOAT_OVERFLOW';
    STATUS_FLOAT_STACK_CHECK:
      Result := 'EFLOAT_STACK_CHECK';
    STATUS_FLOAT_UNDERFLOW:
      Result := 'EFLOAT_UNDERFLOW';
    STATUS_INTEGER_DIVIDE_BY_ZERO:
      Result := 'EINTEGER_DIVIDE_BY_ZERO';
    STATUS_INTEGER_OVERFLOW:
      Result := 'EINTEGER_OVERFLOW';
    STATUS_PRIVILEGED_INSTRUCTION:
      Result := 'EPRIVILEGED_INSTRUCTION';
    STATUS_STACK_OVERFLOW:
      Result := 'ESTACK_OVERFLOW';
    STATUS_CONTROL_C_EXIT:
      Result := 'ECONTROL_C_EXIT';
  else
    Result := Format('$%x', [ExceptionRecord^.ExceptionCode]);
  end;
End;

Function TDebugInfo.GetExceptionAddress(ExceptionRecord: PExceptionRecord): Pointer;
Begin
  Result := ExceptionRecord^.ExceptionAddress;
End;

function TDebugInfo.GetExceptionFrame(ExceptionRecord: PExceptionRecord): Pointer;
begin
  Result := Nil;
end;

Function TDebugInfo.GetExceptionMessage(ExceptionRecord: PExceptionRecord; const ThreadID: TThreadId): String;
Begin
  Result := '';
  // Result := Format('Exception "%s($%x)" at $%p, TID = $%x', [
  // GetExceptionName(ExceptionRecord),
  // ExceptionRecord^.ExceptionCode,
  // GetExceptionAddress(ExceptionRecord),
  // ThreadId]);
End;

procedure TDebugInfo.GetCallStackItems(const ThreadID: TThreadId; Const ExceptAddr, ExceptFrame: Pointer; StackItems: TList);

  Function AddStackEntry(Const Addr, EBP: Pointer): TStackEntry;
  var
    LastStackEntry: TStackEntry;
  Begin
    Result := Nil;

    if StackItems.Count > 0 then
    begin
      LastStackEntry := TStackEntry(StackItems[StackItems.Count - 1]);
      if LastStackEntry.EBP = EBP then
        Exit;
    end;

    If IsValidCodeAddr(Addr) Then
    Begin
      Result := TStackEntry.Create;
      Result.UpdateInfo(Addr);
      Result.EBP := EBP;

      StackItems.Add(Result);
    End
  End;

Var
  EIP: Pointer;
  EBP: Pointer;
  ESP: Pointer;
  ESPV: Pointer;
  OpCode: Byte;
  StackEntry: TStackEntry;
  ThData: PThreadData;
Begin
  If (ExceptAddr <> nil) And (ExceptFrame <> nil) Then
  Begin
    EIP := ExceptAddr;
    EBP := ExceptFrame;
    ESP := nil;
  End
  Else
  Begin
    ThData := gvDebuger.UpdateThreadContext(ThreadID);

    if ThData = Nil then
      Exit;

    EIP := Pointer(ThData^.Context.EIP);
    EBP := Pointer(ThData^.Context.EBP);
    ESP := Pointer(ThData^.Context.ESP);
  End;

  StackEntry := AddStackEntry(EIP, EBP);

  If (ESP <> nil) And (StackEntry <> Nil) And (StackEntry.FuncInfo <> Nil) And (StackEntry.LineInfo <> Nil) Then
  Begin
    If (StackEntry.LineInfo = TLineInfo(StackEntry.FuncInfo.Lines[0])) Then
    Begin
      If (EIP = StackEntry.FuncInfo.Address) Then
      Begin
        StackEntry.EBP := nil;
        ESPV := Nil;
        if gvDebuger.ReadData(ESP, @ESPV, SizeOf(ESPV)) then
          AddStackEntry(ESPV, EBP);
      End
      Else
      Begin
        StackEntry.EBP := nil;
        ESPV := Nil;
        if gvDebuger.ReadData(ESP, @ESPV, SizeOf(ESPV)) then
        begin
          // push ebp; move ebp, esp;
          If (ESPV = EBP) Then
          Begin
            gvDebuger.ReadData(Pointer(Cardinal(ESP) + 4), @ESPV, SizeOf(ESPV));
            AddStackEntry(ESPV, EBP);
          End;
        end;
      End;
    End
    Else If (StackEntry.LineInfo = TLineInfo(StackEntry.FuncInfo.Lines[StackEntry.FuncInfo.Lines.Count - 1])) Then
    Begin
      StackEntry.EBP := nil;
      ESPV := Nil;
      OpCode := $00;
      // ret;
      if gvDebuger.ReadData(EIP, @OpCode, SizeOf(Byte)) then
        If OpCode In [$C3, $CB] Then
        Begin
          if gvDebuger.ReadData(ESP, @ESPV, SizeOf(ESPV)) then
            AddStackEntry(ESPV, EBP);
        End;
    End;
  End;

  While IsValidAddr(EBP) Do
  Begin
    if gvDebuger.ReadData(IncPointer(EBP, 4), @EIP, SizeOf(Pointer)) then
    begin
      if gvDebuger.ReadData(EBP, @EBP, SizeOf(Pointer)) then
      begin
        If AddStackEntry(EIP, EBP) = Nil Then
          Break;
      end
      else
        Break;
    end
    else
      Break;
  End;
End;

function TDebugInfo.GetDirs(const SourceType: TUnitType): TDbgSourceDirList;
begin
  Result := FDirs[SourceType];
end;

function TDebugInfo.ParseConstName(ConstInfo: TConstInfo): String;
begin
  Result := String(ConstInfo.Name);
end;

function TDebugInfo.ParseFuncName(FuncInfo: TFuncInfo): String;
begin
  Result := String(FuncInfo.Name);
end;

function TDebugInfo.ParseStructMemberName(StructMember: TStructMember): String;
begin
  Result := String(StructMember.Name);
end;

function TDebugInfo.ParseTypeName(TypeInfo: TTypeInfo): String;
begin
  Result := String(TypeInfo.Name);
end;

function TDebugInfo.ParseUnitName(UnitInfo: TUnitInfo; const WithExt: LongBool = True): String;
begin
  Result := ExtractFileName(UnitInfo.FullUnitName);

  if not WithExt then
    Result := ChangeFileExt(Result, '');
end;

function TDebugInfo.ParseVarName(VarInfo: TVarInfo): String;
begin
  Result := String(VarInfo.Name);
end;

Function TDebugInfo.ProcessDebugOutputMessage(Const Msg: WideString; DebugEvent: PDebugEvent): LongBool;
Begin
  Result := False;

  // IDEAPI_AddToOutputPanel(PWideChar(Msg), False, False);
End;

Function TDebugInfo.CheckDebugOutputMessage(DebugEvent: PDebugEvent): LongBool;
Var
  OutputStringW: WideString;
  OutputStringA: AnsiString;

  isUnicode: LongBool;
  StrAddr: Pointer;
  StrSize: Word;
Begin
  Result := False;

  If DebugEvent^.dwDebugEventCode <> OUTPUT_DEBUG_STRING_EVENT Then
    Exit;

  isUnicode := WordBool(DebugEvent^.DebugString.fUnicode);
  StrAddr := DebugEvent^.DebugString.lpDebugStringData;
  StrSize := DebugEvent^.DebugString.nDebugStringLength - 1;

  if isUnicode then
  begin
    SetLength(OutputStringW, StrSize div SizeOf(WideChar));
    if not gvDebuger.ReadData(StrAddr, @OutputStringW, StrSize) then
      OutputStringW := '';
  end
  else
  begin
    SetLength(OutputStringA, StrSize);
    if not gvDebuger.ReadData(StrAddr, @OutputStringA, StrSize) then
      OutputStringA := '';

    OutputStringW := WideString(OutputStringA);
  end;

  Result := ProcessDebugOutputMessage(OutputStringW, DebugEvent);
End;

Function TDebugInfo.IsSystemException(Const ExceptionCode: DWORD): LongBool;
Begin
  Case ExceptionCode Of
    STATUS_ACCESS_VIOLATION, STATUS_ARRAY_BOUNDS_EXCEEDED, STATUS_FLOAT_DENORMAL_OPERAND, STATUS_FLOAT_DIVIDE_BY_ZERO, STATUS_FLOAT_INEXACT_RESULT, STATUS_FLOAT_INVALID_OPERATION,
      STATUS_FLOAT_OVERFLOW, STATUS_FLOAT_STACK_CHECK, STATUS_FLOAT_UNDERFLOW, STATUS_INTEGER_DIVIDE_BY_ZERO, STATUS_INTEGER_OVERFLOW, STATUS_PRIVILEGED_INSTRUCTION, STATUS_STACK_OVERFLOW,
      STATUS_CONTROL_C_EXIT:
      Result := True;
  Else
    Result := False;
  End;
End;

function TDebugInfo.IsValidAddr(const Addr: Pointer): LongBool;
Begin
  Result := gvDebuger.IsValidAddr(Addr);
end;

function TDebugInfo.IsValidCodeAddr(const Addr: Pointer): LongBool;
Begin
  Result := gvDebuger.IsValidCodeAddr(Addr);
end;

function TDebugInfo.IsValidDataAddr(const Addr: Pointer; const ThreadID: TThreadId): LongBool;
begin
  Result := IsValidAddr(Addr) And Not(IsValidCodeAddr(Addr) Or IsValidStackAddr(Addr, ThreadID));
end;

function TDebugInfo.IsValidStackAddr(const Addr: Pointer; const ThreadID: TThreadId): LongBool;
Var
  TIB: Pointer;
  TopStack: Pointer;
  ThreadData: PThreadData;
  ThreadContext: TContext;
  ldtSel: LDT_ENTRY;
Begin
  Result := False;

  ThreadData := gvDebuger.GetThreadData(ThreadID);

  if ThreadData <> nil then
  begin
    ThreadContext := gvDebuger.GetRegisters(ThreadID);
    If GetThreadSelectorEntry(ThreadData^.ThreadHandle, ThreadContext.SegFs, ldtSel) Then
    Begin
      TIB := Pointer((ldtSel.BaseHi shl 24) Or (ldtSel.BaseMid shl 16) Or (ldtSel.BaseLow));
      TopStack := nil;
      if gvDebuger.ReadData(Pointer(Cardinal(TIB) + 4), @TopStack, SizeOf(Pointer)) { fs:[4] } then
        Result := (TopStack <> nil) And (Cardinal(Addr) <= Cardinal(TopStack)) And (Cardinal(Addr) >= (ThreadContext.ESP));
    End;
  end;
end;

{ TFuncInfo }

Constructor TFuncInfo.Create;
Begin
  Inherited;

  UnitSegment := Nil;

  Params := TNameList.Create;
  Params.FreeItems := False;
End;

Destructor TFuncInfo.Destroy;
Begin
  FreeAndNil(Params);

  Inherited;
End;

function TFuncInfo.ParamsAsString: String;
// const
// _Self = 'Self';
// _Result = 'Result';
var
  I: Integer;
  Param: TVarInfo;
  Res: TStringList;
begin
  Result := '';

  Res := TStringList.Create;
  try
    for I := 0 to Params.Count - 1 do
    begin
      Param := TVarInfo(Params[I]);

      // TODO: ���������, ��� ��������� ��������� ������� �� � ����������
      // if (I = 0) and SameText(String(Param.Name), _Self) then
      // Continue;

      // if SameText(String(Param.Name), _Result) then
      // Break;

      Res.Add(Param.AsString);
    end;

    for I := 0 to Res.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + '; ';

      Result := Result + Res[I];
    end;
  finally
    FreeAndNil(Res);
  end;
end;

function TFuncInfo.ShortName: String;
begin
  Result := gvDebugInfo.ParseFuncName(Self);
end;

{ TTypeInfo }

constructor TTypeInfo.Create;
begin
  Inherited;

  NameId := -1;
  Members := Nil;
  Elements := Nil;
end;

destructor TTypeInfo.Destroy;
begin
  FreeAndNil(Members);
  FreeAndNil(Elements);

  Inherited;
end;

function TTypeInfo.ElementsToString: String;
var
  I: Integer;
begin
  Result := '';

  if (Kind = tkEnum) And (Elements <> Nil) then
  begin
    for I := 0 to Elements.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ', ';

      Result := Result + Elements[I].ShortName;
    end;
  end;
end;

function TTypeInfo.KindAsString: String;
begin
  case Kind of
    tkBoolean:
      Result := 'Boolean';
    tkWordBool:
      Result := 'WordBool';
    tkLongBool:
      Result := 'LongBool';
    tkShortInt:
      Result := 'ShortInt';
    tkSmallInt:
      Result := 'SmallInt';
    tkInteger:
      Result := 'Integer';
    tkInt64:
      Result := 'Int64';
    tkByte:
      Result := 'Byte';
    tkWord:
      Result := 'Word';
    tkCardinal:
      Result := 'Cardinal';
    tkUInt64:
      Result := 'UInt64';
    tkSingle:
      Result := 'Single';
    tkReal48:
      Result := 'Real48';
    tkReal:
      Result := 'Real';
    tkExtended:
      Result := 'Extended';
    tkCurrency:
      Result := 'Currency';
    tkComplex:
      Result := 'Complex';
    tkPString:
      Result := 'ShortString';
    tkLString:
      Result := 'String';
    tkWString:
      Result := 'WideString';
    tkChar:
      Result := 'Char';
    tkPointer:
      Result := 'Pointer';
    tkSubRange:
      Result := 'SubRange';
    tkArray:
      Result := 'Array';
    tkEnum:
      Result := '';
    tkStructure:
      Result := 'Record';
    tkClass:
      Result := 'TClass';
    tkSet:
      Result := 'Set';
    tkVariant:
      Result := 'Variant';
    tkProperty:
      Result := 'Property';
    tkFieldList:
      Result := 'FieldList';
    tkClosure:
      Result := 'Closure';
    tkClassRef:
      Result := 'ClassRef';
    tkWideChar:
      Result := 'WideChar';
    tkProcedure:
      Result := 'Procedure';
    tkArgList:
      Result := 'ArgList';
    tkMFunction:
      Result := 'MFunction';
    tkVoid:
      Result := 'Void';
    tkObject:
      Result := 'TObject';
    tkDynamicArray:
      Result := 'DynArray';
  end;
end;

function TTypeInfo.Name: AnsiString;
begin
  Result := '';

  if NameId > 0 then
    Result := gvDebugInfo.GetNameById(NameId)
  else if (Kind = tkObject) and (BaseType <> Nil) then
    Result := BaseType.Name
  else
    Result := AnsiString(KindAsString);
end;

function TTypeInfo.ShortName: String;
begin
  Result := gvDebugInfo.ParseTypeName(Self);
end;

function TTypeInfo.TypeOf: String;
begin
  Result := '';

  if BaseType <> nil then
  begin
    case Kind of
      tkArray, tkSet, tkDynamicArray:
        Result := Format('%s Of %s', [KindAsString, BaseType.ShortName]);
      tkObject, tkClass:
        Result := Format('%s(%s)', [KindAsString, BaseType.ShortName]);
    else
      Result := Format('(%s)', [BaseType.ShortName])
    end;
  end
  else
  begin
    case Kind of
      tkEnum:
        Result := Format('(%s)', [ElementsToString]);
    else
      Result := KindAsString;
    end;
  end;
end;

{ TVarInfo }

function TVarInfo.AsString: String;
begin
  if Assigned(DataType) then
    Result := Format('%s: %s', [ShortName, DataType.ShortName])
  else
    Result := ShortName;
end;

Constructor TVarInfo.Create;
Begin
  inherited;

  // ����� ����������� �� �������������
  // RegisterRanges := TList.Create;
  RegisterRanges := Nil;
End;

function TVarInfo.DataTypeName: String;
begin
  if Assigned(DataType) then
    Result := DataType.ShortName
  else
    Result := '';
end;

Destructor TVarInfo.Destroy;
Begin
  if Assigned(RegisterRanges) then
    FreeList(RegisterRanges);

  inherited;
End;

function TVarInfo.UnitInfo: TUnitInfo;
begin
  Result := Nil;

  if Owner is TFuncInfo then
    Result := TFuncInfo(Owner).UnitInfo
  else if Owner is TUnitInfo then
    Result := TUnitInfo(Owner);
end;

function TVarInfo.Value: Variant;
begin
  Result := gvDebugInfo.EvaluateVariable(Self);
end;

function TVarInfo.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId)
end;

function TVarInfo.ShortName: String;
begin
  Result := gvDebugInfo.ParseVarName(Self)
end;

{ TUnitInfo }

procedure TUnitInfo.Clear;
begin
  ClearList(Segments);
  ClearList(SourceSegments);

  if Assigned(UsedUnits) then
    UsedUnits.Clear;

  Lines.Clear;

  if Assigned(FuncsByAddr) then
    FuncsByAddr.Clear;

  inherited Clear;
end;

constructor TUnitInfo.Create;
begin
  Inherited Create;

  UsedUnits := TStringList.Create;
  Segments := TList.Create;
  SourceSegments := TList.Create;
  FuncsByAddr := TSegmentCodeInfoList.Create;

  Lines.OwnsObjects := True;
end;

destructor TUnitInfo.Destroy;
begin
  Clear;

  FreeAndNil(UsedUnits);
  FreeAndNil(Segments);
  FreeAndNil(SourceSegments);
  FreeAndNil(FuncsByAddr);

  Inherited;
end;

function TUnitInfo.FindSegmentByAddr(const Addr: Pointer; const SegmentID: Word = 0): TUnitSegmentInfo;
var
  Idx: Integer;
begin
  for Idx := 0 to Segments.Count - 1 do
  begin
    Result := Segments[Idx];

    if (SegmentID <> 0) and Assigned(Result.SegmentClassInfo) and (Result.SegmentClassInfo.ID <> SegmentID) then
      Continue;

    if (Cardinal(Addr) >= Cardinal(Result.Address)) and (Cardinal(Addr) < (Cardinal(Result.Address) + Result.Size)) then
      Exit;
  end;

  Result := Nil;
end;

function TUnitInfo.FindSourceSegmentByAddr(const Addr: Pointer): TUnitSourceModuleInfo;
var
  Idx: Integer;
begin
  for Idx := SourceSegments.Count - 1 downto 0 do
  begin
    Result := SourceSegments[Idx];

    if (Cardinal(Addr) >= Cardinal(Result.Address)) then
      Exit;
  end;

  Result := Nil;
end;

function TUnitInfo.FindSourceSegmentByNameId(const NameId: TNameId): TUnitSourceModuleInfo;
var
  Idx: Integer;
begin
  for Idx := 0 to SourceSegments.Count - 1 do
  begin
    Result := TUnitSourceModuleInfo(SourceSegments[Idx]);
    if Result.NameId = NameId then
      Exit;
  end;

  Result := Nil;
end;

function TUnitInfo.FullUnitName: String;
begin
  Result := gvDebugInfo.FullUnitName(String(Name));
end;

function TUnitInfo.ShortName: String;
begin
  Result := gvDebugInfo.ParseUnitName(Self);
end;

function TUnitInfo.GetUnitType: TUnitType;
begin
  Result := gvDebugInfo.GetUnitType(ShortName);
end;

{ TStackEntry }

constructor TStackEntry.Create;
begin
  Inherited Create;

  UnitInfo := Nil;
  FuncInfo := Nil;
  LineInfo := Nil;
  EIP := Nil;
  RET := Nil;
  EBP := Nil;
end;

function TStackEntry.GetInfo: String;
begin
  Result := Format('[$%p] ', [EIP]);
  If UnitInfo <> Nil Then
  Begin
    // � XE4 ��� ������ ��� � �������� �������
    // If UnitInfo <> Nil Then
    // Result := Result + String(UnitInfo.Name);
    If FuncInfo <> Nil Then
    begin
      Result := Result + FuncInfo.ShortName;
    end;
    If LineInfo <> Nil Then
      Result := Result + Format(' (%d)', [LineInfo.LineNo]);
  End
  Else
    Result := Result + 'no source';
end;

function TStackEntry.UpdateInfo(const Addr: Pointer): TFindResult;
begin
  EIP := Addr;
  Result := gvDebugInfo.GetLineInfo(EIP, UnitInfo, FuncInfo, LineInfo, False);
end;

{ TConstInfo }

function TConstInfo.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId);
end;

procedure TConstInfo.SetValue(const Value: Variant);
begin
  FValue := Value;
end;

function TConstInfo.ShortName: String;
begin
  Result := gvDebugInfo.ParseConstName(Self);
end;

function TConstInfo.UnitInfo: TUnitInfo;
begin
  if Owner is TUnitInfo then
    Result := TUnitInfo(Owner)
  else
  if Owner is TFuncInfo then
    Result := TFuncInfo(Owner).UnitInfo
  else
    Result := Nil;
end;

function TConstInfo.ValueAsString: String;
begin
  Result := gvDebugInfo.VarValueAsString(Value);
end;

{ TSegmentCodeInfo }

function TSegmentCodeInfo.CheckAddress(const Addr: Pointer): Integer;
begin
  if NativeUInt(Addr) < NativeUInt(Address) then
    Result := -1
  else if NativeUInt(Addr) > (NativeUInt(Address) + NativeUInt(Size)) then
    Result := 1
  else
    Result := 0;
end;

procedure TSegmentCodeInfo.Clear;
begin
  Consts.Clear;
  Types.Clear;
  Vars.Clear;
  Funcs.Clear;

  Lines.Clear;
end;

constructor TSegmentCodeInfo.Create;
begin
  inherited;

  Consts := TNameList.Create;
  Types := TNameList.Create;
  Vars := TNameList.Create;
  Funcs := TNameList.Create;

  Lines := TLineInfoList.Create(False);
end;

destructor TSegmentCodeInfo.Destroy;
begin
  Clear;

  FreeAndNil(Consts);
  FreeAndNil(Types);
  FreeAndNil(Vars);
  FreeAndNil(Funcs);

  FreeAndNil(Lines);

  inherited;
end;

function TSegmentCodeInfo.FindConstByName(const ConstName: AnsiString; const SubStr: LongBool = False): TConstInfo;
begin
  Result := TConstInfo(Consts.FindByName(ConstName, SubStr));
end;

function TSegmentCodeInfo.FindFuncByName(const FuncName: AnsiString; const SubStr: LongBool = False): TFuncInfo;
begin
  Result := TFuncInfo(Funcs.FindByName(FuncName, SubStr));
end;

function TSegmentCodeInfo.FindFuncByNameId(const FuncNameId: Integer): TFuncInfo;
begin
  Result := TFuncInfo(Funcs.FindByNameId(FuncNameId));
end;

function TSegmentCodeInfo.FindTypeByName(const TypeName: AnsiString; const SubStr: LongBool = False): TTypeInfo;
begin
  Result := TTypeInfo(Types.FindByName(TypeName, SubStr));
end;

function TSegmentCodeInfo.FindVarByName(const VarName: AnsiString; const SubStr: LongBool = False): TVarInfo;
begin
  Result := TVarInfo(Vars.FindByName(VarName, SubStr));
end;

function TSegmentCodeInfo.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId);
end;

function TSegmentCodeInfo.ShortName: String;
begin
  Result := String(Name);
end;

{ TNameList }

procedure TNameList.CheckNameIdList;
var
  I: Integer;
  NameInfo: TNameInfo;
begin
  if FNameIdList = nil then
  begin
    FNameIdList := TNameIdList.Create(Capacity);

    for I := 0 to Count - 1 do
    begin
      NameInfo := TNameInfo(List[I]);

      FNameIdList.AddOrSetValue(NameInfo.NameId, NameInfo);
    end;
  end;
end;

procedure TNameList.Clear;
var
  I: Integer;
  Obj: TObject;
begin
  if Assigned(FNameIdList) then
    FreeAndNil(FNameIdList);

  if FFreeItems then
  begin
    for I := 0 to Count - 1 do
    begin
      Obj := List[I];
      if Obj <> nil then
      begin
        List[I] := nil;
        FreeAndNil(Obj);
      end;
    end;
  end;

  inherited Clear;
end;

constructor TNameList.Create;
begin
  inherited;

  FNameIdList := Nil;
  FFreeItems := True;
  // Capacity := 16;
end;

destructor TNameList.Destroy;
begin
  Clear;

  inherited;
end;

function TNameList.FindByName(const Name: AnsiString; const SubStr: LongBool = False): TNameInfo;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    Result := TNameInfo(List[I]);
    if (Result.NameId > 0) then
    begin
      if SubStr then
      begin
        if Pos(Name, Result.Name) > 0 then
          Exit;
      end
      else
      begin
        if SameText(Name, Result.Name) then
          Exit;
      end;
    end;
  end;

  Result := Nil;
end;

function TNameList.FindByNameId(const NameId: TNameId): TNameInfo;
begin
  CheckNameIdList;

  if not FNameIdList.TryGetValue(NameId, Result) then
    Result := Nil;
end;

function TNameList.GetNameInfoItem(const Index: Integer): TNameInfo;
begin
  Result := TNameInfo(Items[Index]);
end;

procedure TNameList.Notify(Ptr: Pointer; Action: TListNotification);
var
  NameInfo: TNameInfo;
begin
  if Assigned(FNameIdList) then
  begin
    NameInfo := TNameInfo(Ptr);

    case Action of
      lnAdded:
        FNameIdList.AddOrSetValue(NameInfo.NameId, NameInfo);
      lnDeleted:
        FNameIdList.Remove(NameInfo.NameId);
    end;
  end;
end;

{ TStructMember }

function TStructMember.Alias: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(AliasNameId);
end;

function TStructMember.MethodName: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(MethodNameId);
end;

function TStructMember.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId);
end;

function TStructMember.ShortName: String;
begin
  Result := gvDebugInfo.ParseStructMemberName(Self);
end;

{ TEnumInfo }

function TEnumInfo.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId);
end;

function TEnumInfo.ShortName: String;
begin
  Result := String(Name);
end;

{ TSegmentCodeInfoList }

procedure TSegmentCodeInfoList.CheckSorted;
begin
  if not FSorted then
  begin
    Sort;
    FSorted := True;
  end;
end;

constructor TSegmentCodeInfoList.Create;
begin
  inherited Create(TSegmentCodeInfoComparer.Create);

  FSorted := False;
end;

destructor TSegmentCodeInfoList.Destroy;
begin

  inherited;
end;

function TSegmentCodeInfoList.FindByAddress(const Address: Pointer): TSegmentCodeInfo;
var
  SearchItem: TSegmentCodeInfo;
  Idx: Integer;
  D: Integer;
begin
  Result := Nil;

  if Count = 0 then
    Exit;

  CheckSorted;

  SearchItem := TSegmentCodeInfo.Create;
  try
    SearchItem.Address := Address;

    BinarySearch(SearchItem, Idx); // !!! ������ ������ Idx +- 1

    if (Idx >= 0) and (Idx < Count) then
      Result := Items[Idx]
    else if Idx = Count then
      Result := Items[Count - 1];

    if (Result <> Nil) then
    begin
      D := Result.CheckAddress(Address);

      if D <> 0 then
      begin
        Inc(Idx, D);

        if (Idx >= 0) and (Idx < Count) then
        begin
          Result := Items[Idx];

          if Result.CheckAddress(Address) <> 0 then
            Result := Nil;
        end
        else
          Result := Nil;
      end;
    end;
  finally
    FreeAndNil(SearchItem);
  end;
end;

procedure TSegmentCodeInfoList.UpdateSort;
begin
  FSorted := False;
  Sort;
  FSorted := True;
end;

{ TSegmentCodeInfoComparer }

function TSegmentCodeInfoComparer.Compare(const Left, Right: TSegmentCodeInfo): Integer;
var
  L, R: NativeInt;
begin
  L := NativeInt(Left.Address);
  R := NativeInt(Right.Address);

  Result := Integer(L - R);
end;

{ TAddressInfoList }

constructor TAddressInfoList.Create(ACapacity: Integer);
begin
  inherited Create(ACapacity);

  FLock := TMREWSync.Create;
end;

destructor TAddressInfoList.Destroy;
begin
  Clear;

  FreeAndNil(FLock);

  inherited;
end;

procedure TAddressInfoList.ValueNotify(const Value: PAddressInfo; Action: TCollectionNotification);
begin
  inherited;

  if Action = cnRemoved then
    FreeMemory(Value);
end;

{ TUnitSourceModuleInfo }

procedure TUnitSourceModuleInfo.Clear;
begin
  Lines.Clear;
end;

constructor TUnitSourceModuleInfo.Create;
begin
  inherited Create;

  Lines := TLineInfoList.Create(False);
end;

destructor TUnitSourceModuleInfo.Destroy;
begin
  Clear;
  FreeAndNil(Lines);

  inherited;
end;

function TUnitSourceModuleInfo.FullUnitName: String;
begin
  Result := gvDebugInfo.FullUnitName(String(Name));
end;

function TUnitSourceModuleInfo.Name: AnsiString;
begin
  Result := gvDebugInfo.GetNameById(NameId);
end;

function TUnitSourceModuleInfo.ShortName: String;
begin
  Result := String(Name);
end;

{ TDbgSourceDirList }

procedure TDbgSourceDirList.Grow;
var
  i, j, n : Integer;
  oldBuckets : array of TDbgSourceDirListItem;
begin
  if FCapacity = 0 then
    FCapacity := 64
  else
    FCapacity := FCapacity * 2;
  FGrowth := (FCapacity * 11) div 16;

  SetLength(oldBuckets, Length(FBuckets));
  for i := 0 to Length(FBuckets) - 1 do
    oldBuckets[i] := FBuckets[i];

  FBuckets := nil;
  SetLength(FBuckets, FCapacity);

  n := FCapacity - 1;
  for i := 0 to High(oldBuckets) do
  begin
    if oldBuckets[i].HashCode = 0 then
      Continue;
    j := (oldBuckets[i].HashCode and (FCapacity - 1));
    while FBuckets[j].HashCode <> 0 do
      j := (j + 1) and n;
    FBuckets[j] := oldBuckets[i];
  end;
end;

function TDbgSourceDirList.LinearFind(const HashCode: Cardinal;
  const ShortFileName: String; var Index: Integer) : Boolean;
begin
  repeat
    if FBuckets[Index].HashCode = 0 then
      Exit(False)
    else
    if SameItem(HashCode, FBuckets[Index].HashCode, ShortFileName, FBuckets[Index].ShortFileName) then
      Exit(True);
    Index := (Index + 1) and (FCapacity - 1);
  until False;
end;

function TDbgSourceDirList.Add(const FileName: String) : Boolean;
var
  Index: Integer;
  HashCode: Integer;
  ShortFileName: String;
begin
  if FCount >= FGrowth then
    Grow;

  ShortFileName := AnsiLowerCase(ExtractFileName(FileName));

  HashCode := GetItemHashCode(ShortFileName);
  Index := (HashCode and (FCapacity - 1));
  if LinearFind(HashCode, ShortFileName, Index) then
    Exit(False);

  FBuckets[Index].ShortFileName := ShortFileName;
  FBuckets[Index].FileName := FileName;
  FBuckets[Index].HashCode := HashCode;
  Inc(FCount);
  Result := True;
end;

function TDbgSourceDirList.Contains(const ShortFileName: String): Boolean;
var
  Index: Integer;
  HashCode: Cardinal;
begin
  if FCount = 0 then
    Exit(False);
  HashCode := GetItemHashCode(ShortFileName);
  Index := HashCode and (FCapacity - 1);
  Result := LinearFind(HashCode, ShortFileName, Index);
end;

procedure TDbgSourceDirList.Clear;
begin
  FCount := 0;
  FCapacity := 0;
  FGrowth := 0;
  FBuckets := nil;
end;

function TDbgSourceDirList.SameItem(const HashCode1, HashCode2: Cardinal;
  const ShortFileName1, ShortFileName2: String): Boolean;
begin
  Result := HashCode1 = HashCode2;
  if Result then
    Result := SameText(ShortFileName1, ShortFileName2);
end;

function TDbgSourceDirList.TryGetValue(const ShortFileName: String;
  out FileName: String): Boolean;
var
  Index: Integer;
  HashCode: Integer;
begin
  if FCount = 0 then
    Exit(False);
  HashCode := GetItemHashCode(ShortFileName);
  Index := (HashCode and (FCapacity - 1));
  Result := LinearFind(HashCode, ShortFileName, Index);
  if Result then
    FileName := FBuckets[Index].FileName;
end;

function TDbgSourceDirList.GetItemHashCode(const ShortFileName: String): Integer;
begin
  Result := SimpleLowerCaseStringHash(ShortFileName);
end;

{ TMemoryManagerInfo }

procedure TMemoryManagerInfo.Clear;
begin
  VarInfo := Nil;
  GetMem := Nil;
  FreeMem := Nil;
  ReallocMem := Nil;
  AllocMem := Nil;
end;

constructor TMemoryManagerInfo.Create;
begin
  inherited;

  Clear;
end;

{ TSegmentClassInfo }

function TSegmentClassInfo.SegTypeName: String;
begin
  Result := SegmentTypeNames[SegType];
end;

class function TSegmentClassInfo.StrToSegmentType(const Str: String): TSegmentType;
var
  SegName: String;
  Idx: Integer;
begin
  if Str <> '' then
  begin
    Idx := 1;
    while (Idx <= Length(Str)) and CharInSet(Str[Idx], ['.', '_']) do
      Inc(Idx);

    SegName := Copy(Str, Idx, MaxInt);

    for Result := ustCode to High(TSegmentType) do
      if SameText(SegName, SegmentTypeNames[Result]) then
        Exit;
  end;

  Result := ustUnknown;
end;

{ TRTLInfo }

procedure TRTLInfo.Clear;
begin
  vmtClassNameInfo := Nil;
end;

constructor TRTLInfo.Create;
begin
  inherited;

  Clear;
end;

function TRTLInfo.vmtClassName: Integer;
begin
  if Assigned(vmtClassNameInfo) then
    Result := Integer(vmtClassNameInfo.Value)
  else
    Result := System.vmtClassName;
end;

End.
