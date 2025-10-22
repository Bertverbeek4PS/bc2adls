// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82564 "ADLSE Util"
{
    Access = Internal;

    var
        AlphabetsLowerTxt: Label 'abcdefghijklmnopqrstuvwxyz', Locked = true;
        AlphabetsUpperTxt: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', Locked = true;
        NumeralsTxt: Label '1234567890', Locked = true;
        SpecialCharsTxt: Label '%', Locked = true;
        FieldTypeNotSupportedErr: Label 'The field %1 of type %2 is not supported.', Comment = '%1 = field name, %2 = field type';
        ConcatNameIdTok: Label '%1-%2', Comment = '%1: Name, %2: ID', Locked = true;
        DateTimeExpandedFormatTok: Label '%1, %2 %3 %4 %5:%6:%7 GMT', Comment = '%1: weekday, %2: day, %3: month, %4: year, %5: hour, %6: minute, %7: second', Locked = true;
        QuotedTextTok: Label '"%1"', Comment = '%1: text to be double- quoted', Locked = true;
        CommaPrefixedTok: Label ',%1', Comment = '%1: text to be prefixed', Locked = true;
        CommaSuffixedTok: Label '%1, ', Comment = '%1: text to be suffixed', Locked = true;
        WholeSecondsTok: Label ':%1Z', Comment = '%1: seconds', Locked = true;
        FractionSecondsTok: Label ':%1.%2Z', Comment = '%1: seconds, %2: milliseconds', Locked = true;

    procedure ToText(GuidValue: Guid): Text
    begin
        exit(Format(GuidValue).TrimStart('{').TrimEnd('}'));
    end;

    procedure Concatenate(List: List of [Text]) Result: Text
    var
        Item: Text;
    begin
        foreach Item in List do
            Result += StrSubstNo(CommaSuffixedTok, Item);
        Result := Result.TrimEnd(', ');
    end;

    procedure GetCurrentDateTimeInGMTFormat(): Text
    var
        LocalTimeInUtc: Text;
        Parts: List of [Text];
        YearPart: Text;
        MonthPart: Text;
        DayPart: Text;
        HourPart: Text;
        MinutePart: Text;
        SecondPart: Text;
    begin
        // get the UTC notation of current time
        LocalTimeInUtc := Format(CurrentDateTime(), 0, 9);
        Parts := LocalTimeInUtc.Split('-', 'T', ':', '.', 'Z');
        YearPart := Parts.Get(1);
        MonthPart := Parts.Get(2);
        DayPart := Parts.Get(3);
        HourPart := Parts.Get(4);
        MinutePart := Parts.Get(5);
        SecondPart := Parts.Get(6);
        exit(StrSubstNo(DateTimeExpandedFormatTok,
            GetDayOfWeek(YearPart, MonthPart, DayPart),
            DayPart,
            Get3LetterMonth(MonthPart),
            YearPart,
            HourPart,
            MinutePart,
            SecondPart));
    end;

    local procedure GetDayOfWeek(YearPart: Text; MonthPart: Text; DayPart: Text): Text
    var
        TempDate: Date;
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        Evaluate(Year, YearPart);
        Evaluate(Month, MonthPart);
        Evaluate(Day, DayPart);
        TempDate := System.DMY2Date(Day, Month, Year);
        case Date2DWY(TempDate, 1) of // the week number
            1:
                exit('Mon');
            2:
                exit('Tue');
            3:
                exit('Wed');
            4:
                exit('Thu');
            5:
                exit('Fri');
            6:
                exit('Sat');
            7:
                exit('Sun');
        end;
    end;

    local procedure Get3LetterMonth(MonthPart: Text): Text
    var
        Month: Integer;
    begin
        Evaluate(Month, MonthPart);
        case Month of
            1:
                exit('Jan');
            2:
                exit('Feb');
            3:
                exit('Mar');
            4:
                exit('Apr');
            5:
                exit('May');
            6:
                exit('Jun');
            7:
                exit('Jul');
            8:
                exit('Aug');
            9:
                exit('Sep');
            10:
                exit('Oct');
            11:
                exit('Nov');
            12:
                exit('Dec');
        end;
    end;

    procedure GetUtcEpochWithTimezoneOffset(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        UtcOffset: Duration;
    begin
        TypeHelper.GetUserTimezoneOffset(UtcOffset);
        exit(CreateDateTime(DMY2Date(1, 1, 1900), 0T) + UtcOffset);
    end;

    procedure GetTableCaption(TableID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then
            exit(AllObjWithCaption."Object Caption");
    end;

    procedure GetDataLakeCompliantTableName(TableID: Integer) TableName: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        AllObjWithCaption: Record AllObjWithCaption;
        OrigTableName: Text;
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Use Table Captions" then
            OrigTableName := GetTableCaption(TableID)
        else
            OrigTableName := GetTableName(TableID);
        if ADLSESetup."Use IDs for Duplicates Only" then begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
            AllObjWithCaption.SetFilter("Object ID", '<>%1', TableID);
            if ADLSESetup."Use Table Captions" then
                AllObjWithCaption.SetRange("Object Caption", OrigTableName)
            else
                AllObjWithCaption.SetRange("Object Name", OrigTableName);
            if AllObjWithCaption.IsEmpty() then // there is not a duplicate table caption
                exit(GetDataLakeCompliantName(OrigTableName))
            else
                exit(StrSubstNo(ConcatNameIdTok, GetDataLakeCompliantName(OrigTableName), TableID));
        end else
            exit(StrSubstNo(ConcatNameIdTok, GetDataLakeCompliantName(OrigTableName), TableID));
    end;

    procedure GetDataLakeCompliantFieldName(TableID: Integer; FieldID: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableID);
        FieldRef := RecRef.Field(FieldID);
        exit(GetDataLakeCompliantFieldName(FieldRef));
    end;

    procedure GetDataLakeCompliantFieldName(FieldRef: FieldRef): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        TableFields: Record Field;
        RecRef: RecordRef;
        NameToUse: Text;
    begin
        ADLSESetup.GetSingleton();
        if ADLSESetup."Use Field Captions" then
            NameToUse := FieldRef.Caption()
        else
            NameToUse := FieldRef.Name();
        if ADLSESetup."Use IDs for Duplicates Only" then begin
            RecRef := FieldRef.Record();
            TableFields.SetRange(TableNo, RecRef.Number);
            if ADLSESetup."Use Field Captions" then
                TableFields.SetRange("Field Caption", NameToUse)
            else
                exit(GetDataLakeCompliantName(NameToUse));

            TableFields.SetFilter("No.", '<>%1', FieldRef.Number);
            if TableFields.IsEmpty() then // there is not a duplicate field name/caption
                exit(GetDataLakeCompliantName(NameToUse))
            else
                exit(StrSubstNo(ConcatNameIdTok, GetDataLakeCompliantName(NameToUse), FieldRef.Number));
        end else
            exit(StrSubstNo(ConcatNameIdTok, GetDataLakeCompliantName(NameToUse), FieldRef.Number));
    end;

    procedure GetTableName(TableID: Integer) TableName: Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then
            TableName := AllObjWithCaption."Object Name";
    end;

    procedure GetDataLakeCompliantName(Name: Text) Result: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ResultBuilder: TextBuilder;
        Index: Integer;
        Letter: Text;
        AddToResult: Boolean;
    begin
        ADLSESetup.GetSingleton();
        for Index := 1 to StrLen(Name) do begin
            Letter := CopyStr(Name, Index, 1);
            AddToResult := true;
            if StrPos(AlphabetsLowerTxt, Letter) = 0 then
                if StrPos(AlphabetsUpperTxt, Letter) = 0 then
                    if StrPos(NumeralsTxt, Letter) = 0 then
                        if ADLSESetup."Use IDs for Duplicates Only" then begin
                            if StrPos(SpecialCharsTxt, Letter) = 0 then
                                AddToResult := false;
                        end
                        else
                            AddToResult := false;
            if AddToResult then
                ResultBuilder.Append(Letter);
        end;
        Result := ResultBuilder.ToText();
    end;

    procedure CheckFieldTypeForExport(Field: Record Field)
    begin
        case Field.Type of
            Field.Type::BigInteger,
            Field.Type::Boolean,
            Field.Type::Code,
            Field.Type::Date,
            Field.Type::DateFormula,
            Field.Type::DateTime,
            Field.Type::Decimal,
            Field.Type::Duration,
            Field.Type::Guid,
            Field.Type::Integer,
            Field.Type::Option,
            Field.Type::Text,
            Field.Type::Time:
                exit;
        end;
        Error(FieldTypeNotSupportedErr, Field."Field Caption", Field.Type);
    end;

    procedure ConvertFieldToText(FieldRef: FieldRef): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        case FieldRef.Type of
            FieldRef.Type::BigInteger,
            FieldRef.Type::Date,
            FieldRef.Type::DateFormula,
            FieldRef.Type::Decimal,
            FieldRef.Type::Duration,
            FieldRef.Type::Integer:
                exit(ConvertNumberToText(FieldRef.Value()));
            FieldRef.Type::Time:
                begin
                    TimeValue := FieldRef.Value();
                    exit(ConvertTimeToText(TimeValue));
                end;
            FieldRef.Type::DateTime:
                begin
                    DateTimeValue := FieldRef.Value();
                    if DateTimeValue = 0DT then
                        exit('');
                    exit(ConvertDateTimeToText(DateTimeValue));
                end;
            FieldRef.Type::Option:
                begin
                    ADLSESetup.GetSingleton();
                    if ADLSESetup."Export Enum as Integer" then
                        exit(ConvertOptionFieldToValueText(FieldRef))
                    else
                        exit(FieldRef.GetEnumValueNameFromOrdinalValue(FieldRef.Value()));
                end;
            FieldRef.Type::Boolean:
                exit(Format(FieldRef.Value(), 0, 9));
            FieldRef.Type::Code,
            FieldRef.Type::Guid,
            FieldRef.Type::Text:
                exit(ConvertStringToText(FieldRef.Value()));
            else
                Error(FieldTypeNotSupportedErr, FieldRef.Name(), FieldRef.Type);
        end;
    end;

    procedure ConvertOptionFieldToValueText(FieldRef: FieldRef): Text
    begin
        case FieldRef.Type of
            FieldRef.Type::Option:
                exit(ConvertNumberToText(FieldRef.Value()));
        end;
    end;

    local procedure ConvertStringToText(Val: Text): Text
    var
        Char10, Char13 : Char;
    begin
        Char10 := 10; // Line feed - '\n'
        Char13 := 13; // Carriage return - '\r'

        Val := Val.Replace(Char10, ' '); // remove the Line feed - '\n' character
        Val := Val.Replace(Char13, ' '); // remove the Carriage return - '\r' character
        Val := Val.Replace('\', '\\'); // escape the escape character
        Val := Val.Replace('"', '\"'); // escape the quote character
        exit(StrSubstNo(QuotedTextTok, Val));
    end;

    procedure ConvertNumberToText(Val: Integer): Text
    begin
        exit(Format(Val, 0, 9));
    end;

    local procedure ConvertNumberToText(Variant: Variant): Text
    begin
        exit(Format(Variant, 0, 9));
    end;

    local procedure ConvertTimeToText(Variant: Variant): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        TimeValue: Time;
    begin
        if ADLSESetup.GetStorageType() = ADLSESetup."Storage Type"::"Open Mirroring" then begin
            TimeValue := Variant;
            exit(ConvertStringToText(Format(TimeValue, 0, '<Hours24>:<Minutes,2>:<Seconds,2>')))
        end else
            exit(ConvertNumberToText(Variant));
    end;

    local procedure ConvertDateTimeToText(Val: DateTime) Result: Text
    var
        SecondsText: Text;
        WholeSecondsText: Text;
        MillisecondsText: Text;
        StartIdx: Integer;
        PeriodIdx: Integer;
    begin
        // get default formatted as UTC
        Result := Format(Val, 0, 9); // The default formatting excludes the zeroes for the millseconds to the right.

        // get full seconds part
        StartIdx := Result.LastIndexOf(':') + 1;
        SecondsText := Result.Substring(StartIdx, StrLen(Result) - StartIdx);
        PeriodIdx := SecondsText.LastIndexOf('.');
        if PeriodIdx > 0 then begin
            MillisecondsText := PadStr(SecondsText.Substring(PeriodIdx + 1), 3, '0');
            WholeSecondsText := SecondsText.Substring(1, PeriodIdx - 1);
        end else begin
            MillisecondsText := PadStr(MillisecondsText, 3, '0');
            WholeSecondsText := SecondsText;
        end;
        Result := Result.Replace(StrSubstNo(WholeSecondsTok, SecondsText), StrSubstNo(FractionSecondsTok, WholeSecondsText, MillisecondsText));
    end;

    procedure AddSystemFields(var FieldIdList: List of [Integer])
    var
        RecordRef: RecordRef;
    begin
        FieldIdList.Add(0); // Timestamp field
        FieldIdList.Add(RecordRef.SystemIdNo());
        FieldIdList.Add(RecordRef.SystemCreatedAtNo());
        FieldIdList.Add(RecordRef.SystemCreatedByNo());
        FieldIdList.Add(RecordRef.SystemModifiedAtNo());
        FieldIdList.Add(RecordRef.SystemModifiedByNo());
    end;

    procedure CreateCsvHeader(RecordRef: RecordRef; FieldIdList: List of [Integer]) RecordPayload: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        FieldRef: FieldRef;
        FieldID: Integer;
        FieldsAdded: Integer;
        FieldTextValue: Text;
        Payload: TextBuilder;
        RowMarkerTok: Label '__rowMarker__', Comment = 'Rowmarker must always be the first column for open mirroring', Locked = true;
    begin
        FieldsAdded := 0;
        ADLSESetup.GetSingleton();

        foreach FieldID in FieldIdList do begin
            FieldRef := RecordRef.Field(FieldID);

            FieldTextValue := GetDataLakeCompliantFieldName(FieldRef);
            if FieldsAdded = 0 then
                Payload.Append(FieldTextValue)
            else
                Payload.Append(StrSubstNo(CommaPrefixedTok, FieldTextValue));
            FieldsAdded += 1;
        end;
        if IsTablePerCompany(RecordRef.Number) then
            Payload.Append(StrSubstNo(CommaPrefixedTok, ADLSECDMUtil.GetCompanyFieldName()));

        if ADLSESetup."Delivered DateTime" then
            Payload.Append(StrSubstNo(CommaPrefixedTok, ADLSECDMUtil.GetDeliveredDateTimeFieldName()));

        if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then
            Payload.Append(StrSubstNo(CommaPrefixedTok, RowMarkerTok));

        Payload.AppendLine();
        RecordPayload := Payload.ToText();
    end;

    procedure CreateCsvPayload(RecordRef: RecordRef; FieldIdList: List of [Integer]; AddHeaders: Boolean; Deletes: Boolean) RecordPayload: Text
    var
        ADLSESetup: Record "ADLSE Setup";
        ADLSETableLastTimestamp: Record "ADLSE Table Last Timestamp";
        FieldRef: FieldRef;
        CurrDateTime: DateTime;
        FieldID: Integer;
        FieldsAdded: Integer;
        FieldTextValue: Text;
        Payload: TextBuilder;
    begin
        if AddHeaders then
            Payload.Append(CreateCsvHeader(RecordRef, FieldIdList));

        ADLSESetup.GetSingleton();
        if ADLSESetup."Delivered DateTime" then
            CurrDateTime := CurrentDateTime();

        FieldsAdded := 0;

        foreach FieldID in FieldIdList do begin
            FieldRef := RecordRef.Field(FieldID);

            FieldTextValue := ConvertFieldToText(FieldRef);
            if FieldsAdded = 0 then
                Payload.Append(FieldTextValue)
            else
                Payload.Append(StrSubstNo(CommaPrefixedTok, FieldTextValue));
            FieldsAdded += 1;
        end;
        if IsTablePerCompany(RecordRef.Number) then
            Payload.Append(StrSubstNo(CommaPrefixedTok, ConvertStringToText(CompanyName())));
        if ADLSESetup."Delivered DateTime" then
            Payload.Append(StrSubstNo(CommaPrefixedTok, ConvertDateTimeToText(CurrDateTime)));

        if ADLSESetup."Storage Type" = ADLSESetup."Storage Type"::"Open Mirroring" then
            if Deletes then
                Payload.Append(StrSubstNo(CommaPrefixedTok, '2'))
            else
                Payload.Append(StrSubstNo(CommaPrefixedTok, '4'));
        //https://learn.microsoft.com/en-us/fabric/database/mirrored-database/open-mirroring-landing-zone-format#data-file-and-format-in-the-landing-zone
        // 0- 	Insert
        // 1- 	Update
        // 2- 	Delete
        // 4-   Upsert

        Payload.AppendLine();

        RecordPayload := Payload.ToText();
    end;

    procedure IsTablePerCompany(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.DataPerCompany);
    end;

    procedure CreateFakeRecordForDeletedAction(ADLSEDeletedRecord: Record "ADLSE Deleted Record"; var RecordRef: RecordRef)
    var
        TimestampFieldRef: FieldRef;
        SystemIdFieldRef: FieldRef;
        SystemDateFieldRef: FieldRef;
    begin
        TimestampFieldRef := RecordRef.Field(0);
        TimestampFieldRef.Value(ADLSEDeletedRecord."Deletion Timestamp");
        SystemIdFieldRef := RecordRef.Field(RecordRef.SystemIdNo());
        SystemIdFieldRef.Value(ADLSEDeletedRecord."System ID");

        SystemDateFieldRef := RecordRef.Field(RecordRef.SystemCreatedAtNo());
        SystemDateFieldRef.Value(0DT);
        SystemDateFieldRef := RecordRef.Field(RecordRef.SystemModifiedAtNo());
        SystemDateFieldRef.Value(0DT);
    end;

    procedure GetTextValueForKeyInJson(Object: JsonObject; "Key": Text): Text
    var
        ValueToken: JsonToken;
        JValue: JsonValue;
    begin
        Object.Get("Key", ValueToken);
        JValue := ValueToken.AsValue();
        exit(JValue.AsText());
    end;

    procedure JsonTokenExistsWithValueInArray(Arr: JsonArray; PropertyName: Text; PropertyValue: Text): Boolean
    var
        Token: JsonToken;
        Obj: JsonObject;
        PropertyToken: JsonToken;
    begin
        foreach Token in Arr do begin
            Obj := Token.AsObject();
            if Obj.Get(PropertyName, PropertyToken) then
                if PropertyToken.AsValue().AsText() = PropertyValue then
                    exit(true);
        end;
    end;
}