codeunit 85560 "ADLSE Test Field API"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        // [FEATURE] bc2adls API
    end;

    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        ADLSLibrarybc2adls: Codeunit "ADLSE Library - bc2adls";
        Assert: Codeunit Assert;
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    [Test]
    procedure PostFieldToExcistingTable()
    var
        RequestBody: Text;
        Response: Text;
        FieldId: Integer;
    begin
        // [SCENARIO 001] Add a field to an excisting table
        // [GIVEN] Initialized test environment and clean up
        Initialize();
        ADLSLibrarybc2adls.CleanUp();
        // [GIVEN] Setup bc2adls table for Azure Blob Storage
        if not ADLSESetup.Get() then
            ADLSLibrarybc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
        // [GIVEN] Insert one table and fields
        ADLSLibrarybc2adls.InsertTables(1);
        Commit();
        //GIVEN Insert all the fields of the tables
        ADLSETable := ADLSLibrarybc2adls.GetRandomTable();
        FieldId := ADLSLibrarybc2adls.GetRandomField(ADLSETable);
        // [GIVEN] Table Field with type company JSON object
        RequestBody := CreateFieldJSONObject(format(ADLSETable."Table ID"), format(FieldId));

        // [WHEN] Send POST request for contact with type company
        Response := SendPostRequestForField(RequestBody);
        Commit();

        // [THEN] Contact with type company and company number series exists in database
        VerifyFieldIdOfTableIdExistsInDatabase(Response);
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";

    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ADLSE Test Field API");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ADLSE Test Field API");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ADLSE Test Field API");
    end;

    local procedure CreateFieldJSONObject(TableId: Text; FieldId: text) RequestBody: Text
    begin
        RequestBody := LibraryGraphMgt.AddPropertytoJSON(RequestBody, 'tableId', TableId);


        RequestBody := LibraryGraphMgt.AddPropertytoJSON(RequestBody, 'fieldId', FieldId);
    end;

    local procedure SendPostRequestForField(RequestBody: Text) Response: Text;
    var
        TargetUrl: Text;
    begin
        TargetUrl := LibraryGraphMgt.CreateTargetURL('', Page::"ADLSE Field API", 'adlseFields');
        LibraryGraphMgt.PostToWebService(TargetUrl, RequestBody, Response);
    end;

    local procedure VerifyFieldIdOfTableIdExistsInDatabase(JSON: Text)
    var
        tableId: Text;
        FieldId: Text;
    begin
        LibraryGraphMgt.GetPropertyValueFromJSON(JSON, 'tableId', tableId);
        LibraryGraphMgt.GetPropertyValueFromJSON(JSON, 'fieldId', FieldId);
        ADLSEField.Get(tableId, FieldId);

        Assert.AreEqual(tableId, format(ADLSEField."Table ID"), StrSubstNo('Field: %1', ADLSEField.FieldCaption("Table ID")));
        Assert.AreEqual(FieldId, format(ADLSEField."Field ID"), StrSubstNo('Field: %1', ADLSEField.FieldCaption("Field ID")));
    end;
}