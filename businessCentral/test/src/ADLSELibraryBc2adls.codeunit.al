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

    procedure InsertTable(): Integer
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RandonInt: Integer;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        RandonInt := LibraryRandom.RandIntInRange(1, AllObjWithCaption.Count());
        AllObjWithCaption.next(RandonInt);
        ADLSETable.Add(AllObjWithCaption."Object ID");
        exit(AllObjWithCaption."Object ID");
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
        Field: Record Field;
    begin
        Field.SetRange(TableNo, ADLSETable."Table ID");
        Field.SetFilter("No.", '<%1', 2000000000); // no system fields
        Field.next(LibraryRandom.RandIntInRange(1, Field.Count()));
        exit(Field."No.");
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

    procedure EnableField(TableId: Integer; FieldId: Integer)
    begin
        ADLSEField.SetRange("Table ID", TableId);
        ADLSEField.SetRange("Field ID", FieldId);
        If ADLSEField.FindFirst() then begin
            ADLSEField."Enabled" := true;
            ADLSEField.Modify();
        end;
    end;

    procedure CleanUp();
    begin
        ADLSETable.DeleteAll(true);
        ADLSESetup.DeleteAll(true);
    end;

    procedure MockCreateExport(TableId: Integer);
    var
        ADLSERun: Record "ADLSE Run";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        ADLSERun.RegisterStarted(TableId);
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableId);
        ADLSERun.RegisterEnded(TableId, false, AllObjWithCaption.TableCaption);
    end;
}