codeunit 85560 "ADLSE Test Field API"
{
    Subtype = Test;
    TestPermissions = Disabled;
    trigger OnRun()
    begin
        // [FEATURE] bc2adls API
    end;

    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        LibraryBc2adls: Codeunit "ADLSE Library - bc2adls";
        Assert: Codeunit Assert;
        ADLSESetup: Record "ADLSE Setup";
        ADLSETable: Record "ADLSE Table";
        ADLSEField: Record "ADLSE Field";
        "Storage Type": Enum "ADLSE Storage Type";
        IsInitialized: Boolean;

    // [Test]
    // procedure GetListofAllFields()
    // var
    //     RequestBody: Text;
    //     Response: Text;
    //     FieldId: Integer;
    // begin
    //     // [SCENARIO 001] Get list of all fields
    //     // [GIVEN] Initialized test environment
    //     Initialize();
    //     // [GIVEN] Setup bc2adls table for Azure Blob Storage
    //     if not ADLSESetup.Get() then
    //         LibraryBc2adls.CreateAdlseSetup("Storage Type"::"Azure Data Lake");
    //     // [GIVEN] Insert number of tables
    //     LibraryBc2adls.InsertTables(1);
    //     //GIVEN Insert all the fields of the tables
    //     ADLSETable := LibraryBc2adls.GetRandomTable();
    //     FieldId := LibraryBc2adls.GetRandomField(ADLSETable);
    //     // [GIVEN] Table Field with type company JSON object
    //     RequestBody := CreateFieldJSONObject(format(ADLSETable."Table ID"), format(FieldId));

    //     // [WHEN] Send POST request for contact with type company
    //     Response := SendPostRequestForField(RequestBody);

    //     // [THEN] Contact with type company and company number series exists in database
    //     VerifyFieldIdOfTableIdExistsInDatabase(Response);
    // end;

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

        Assert.AreEqual(tableId, ADLSEField."Table ID", StrSubstNo('Field: %1', ADLSEField.FieldCaption("Table ID")));
        Assert.AreEqual(FieldId, ADLSEField."Field ID", StrSubstNo('Field: %1', ADLSEField.FieldCaption("Field ID")));
    end;
}