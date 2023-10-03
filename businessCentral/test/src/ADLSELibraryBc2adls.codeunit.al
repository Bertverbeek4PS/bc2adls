codeunit 85561 "ADLSE Library - bc2adls"
{
    trigger OnRun()
    begin

    end;

    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreateAdlseSetup("Storage Type": Enum "ADLSE Storage Type")
    begin
        ADLSESetup.Init();

        if "Storage Type" = "Storage Type"::"Azure Data Lake" then begin
            ADLSESetup."Storage Type" := "Storage Type"::"Azure Data Lake";
            ADLSESetup.Container := 'bc2adls';
            ADLSESetup."Account Name" := 'bc2adls';
        end else begin
            ADLSESetup."Storage Type" := "Storage Type"::"Microsoft Fabric";
            ADLSESetup.Workspace := 'bc2adls';
            ADLSESetup.Lakehouse := 'bc2adls';
        end;
        ADLSESetup.Insert();
    end;

    procedure InsertTables(NoOfTables: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RandonInt: Integer;
        i: Integer;
    begin
        for i := 1 to NoOfTables do begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            RandonInt := LibraryRandom.RandIntInRange(1, AllObjWithCaption.Count());
            AllObjWithCaption.next(RandonInt);
            ADLSETable.Add(AllObjWithCaption."Object ID");
        end;
    end;

    procedure GetRandomTable(): Record "ADLSE Table"
    begin
        ADLSETable.Reset();
        ADLSETable.SetRange(Enabled, true);
        ADLSETable.next(LibraryRandom.RandIntInRange(1, ADLSETable.Count()));
        exit(ADLSETable);
    end;

    procedure GetRandomField(ADLSETable: Record "ADLSE Table"): Integer
    var
        Fld: Record Field;
    begin
        Fld.SetRange(TableNo, ADLSETable."Table ID");
        Fld.SetFilter("No.", '<%1', 2000000000); // no system fields
        Fld.next(LibraryRandom.RandIntInRange(1, Fld.Count()));
        exit(Fld."No.");
    end;

    procedure InsertFields()
    begin
        ADLSETable.Reset();
        ADLSETable.SetRange(Enabled, true);
        if ADLSETable.FindSet() then
            repeat
                ADLSEField.InsertForTable(ADLSETable);
            until ADLSETable.Next() = 0;
    end;

    procedure CleanUp();
    begin
        ADLSETable.DeleteAll(true);
        ADLSESetup.DeleteAll(true);
    end;
}