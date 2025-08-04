// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License. See LICENSE in the project root for license information.
codeunit 82564 "ADLSE Util"
{
    Access = Internal;

    var
        AlphabetsLowerTxt: Label 'abcdefghijklmnopqrstuvwxyz';
        AlphabetsUpperTxt: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        NumeralsTxt: Label '1234567890';
        FieldTypeNotSupportedErr: Label 'The field %1 of type %2 is not supported.', Comment = '%1 = field name, %2 = field type';

    procedure ToText(GuidValue: Guid): Text
    begin
        exit(Format(GuidValue).TrimStart('{').TrimEnd('}'));
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
        exit(StrSubstNo('%1, %2 %3 %4 %5:%6:%7 GMT',
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

    procedure GetTableCaption(TableID: Integer): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        exit(RecRef.Caption());
    end;

    procedure GetDataLakeCompliantTableName(TableID: Integer) TableName: Text
    var
        OrigTableName: Text;
    begin
        OrigTableName := GetTableName(TableID);
        TableName := GetDataLakeCompliantName(OrigTableName);
        exit(StrSubstNo('%1-%2', TableName, TableID));
    end;

    procedure GetDataLakeCompliantFieldName(FieldName: Text; FieldID: Integer): Text
    begin
        exit(StrSubstNo('%1-%2', GetDataLakeCompliantName(FieldName), FieldID));
    end;

    procedure GetTableName(TableID: Integer) TableName: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        TableName := RecRef.Name;
    end;

    procedure GetDataLakeCompliantName(Name: Text) Result: Text
    var
        ResultBuilder: TextBuilder;
        Index: Integer;
        Letter: Text;
        AddToResult: Boolean;
    begin
        for Index := 1 to StrLen(Name) do begin
            Letter := CopyStr(Name, Index, 1);
            AddToResult := true;
            if StrPos(AlphabetsLowerTxt, Letter) = 0 then
                if StrPos(AlphabetsUpperTxt, Letter) = 0 then
                    if StrPos(NumeralsTxt, Letter) = 0 then
                        AddToResult := false;
            if AddToResult then
                ResultBuilder.Append(Letter);
        end;
        Result := ResultBuilder.ToText();
    end;

    procedure CheckFieldTypeForExport(Fld: Record Field)
    begin
        case Fld.Type of
            Fld.Type::BigInteger,
            Fld.Type::Boolean,
            Fld.Type::Code,
            Fld.Type::Date,
            Fld.Type::DateFormula,
            Fld.Type::DateTime,
            Fld.Type::Decimal,
            Fld.Type::Duration,
            Fld.Type::Guid,
            Fld.Type::Integer,
            Fld.Type::Option,
            Fld.Type::Text,
            Fld.Type::Time:
                exit;
        end;
        Error(FieldTypeNotSupportedErr, Fld.FieldName, Fld.Type);
    end;

    procedure ConvertFieldToText(Fld: FieldRef): Text
    var
        DateTimeValue: DateTime;
    begin
        case Fld.Type of
            Fld.Type::BigInteger,
            Fld.Type::Date,
            Fld.Type::DateFormula,
            Fld.Type::Decimal,
            Fld.Type::Duration,
            Fld.Type::Integer,
            Fld.Type::Time:
                exit(ConvertNumberToText(Fld.Value()));
            Fld.Type::DateTime:
                begin
                    DateTimeValue := Fld.Value();
                    if DateTimeValue = 0DT then
                        exit('');
                    exit(ConvertDateTimeToText(DateTimeValue));
                end;
            Fld.Type::Option,
            Fld.Type::Boolean:
                exit(Format(Fld.Value()));
            Fld.Type::Code,
            Fld.Type::Guid,
            Fld.Type::Text:
                exit(ConvertStringToText(Fld.Value()));
            else
                Error(FieldTypeNotSupportedErr, Fld.Name(), Fld.Type);
        end;
    end;

    local procedure ConvertStringToText(Val: Text): Text
    begin
        Val := Val.Replace('\', '\\'); // escape the escape character
        Val := Val.Replace('"', '\"'); // escape the quote character
        exit(StrSubstNo('"%1"', Val));
    end;

    procedure ConvertNumberToText(Val: Integer): Text
    begin
        exit(Format(Val, 0, 9));
    end;

    local procedure ConvertNumberToText(Val: Variant): Text
    begin
        exit(Format(Val, 0, 9));
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
        Result := Result.Replace(StrSubstNo(':%1Z', SecondsText), StrSubstNo(':%1.%2Z', WholeSecondsText, MillisecondsText));
    end;

    procedure GetCDMAttributeDetails(Type: FieldType; var DataFormat: Text; var AppliedTraits: JsonArray)
    begin
        DataFormat := '';
        Clear(AppliedTraits);

        DataFormat := GetCDMDataFormat(Type);
        AppliedTraits := GetCDMAppliedTraits(Type);
    end;

    local procedure GetCDMDataFormat(Type: FieldType): Text
    begin
        // Refer https://docs.microsoft.com/en-us/common-data-model/sdk/list-of-datatypes
        // Refer https://docs.microsoft.com/en-us/common-data-model/1.0om/api-reference/cdm/dataformat
        case Type of
            FieldType::BigInteger:
                exit('Int64');
            FieldType::Date:
                exit('Date');
            FieldType::DateFormula:
                exit(GetCDMDataFormat_String());
            FieldType::DateTime:
                exit('DateTime');
            FieldType::Decimal:
                exit('Decimal');
            FieldType::Duration:
                exit('DateTimeOffset');
            FieldType::Integer:
                exit('Int32');
            FieldType::Option:
                exit(GetCDMDataFormat_String());
            FieldType::Time:
                exit('Time');
            FieldType::Boolean:
                exit('Boolean');
            FieldType::Code:
                exit(GetCDMDataFormat_String());
            FieldType::Guid:
                exit('Guid');
            FieldType::Text:
                exit(GetCDMDataFormat_String());
        end;
    end;

    local procedure GetCDMAppliedTraits(Type: FieldType) AppliedTraits: JsonArray
    begin
        Clear(AppliedTraits);
        // case Type of
        //     FieldType::DateTime:
        //         AppliedTraits.Add(GetDateTimeTrait());
        // end;
    end;

    // local procedure GetDateTimeTrait() Trait: JsonObject
    // var
    //     Arg: JsonObject;
    //     Args: JsonArray;
    // begin
    //     Trait.Add('traitReference', 'is.formatted.dateTime');
    //     Arg.Add('name', 'format');
    //     Arg.Add('value', 'yyyy-MM-ddTHH:mm:ss.fffK');
    //     Args.Add(Arg);
    //     Trait.Add('arguments', Args);
    // end;

    local procedure GetCDMDataFormat_String(): Text
    begin
        exit('String');
    end;

    procedure AddSystemFields(var FieldIdList: List of [Integer])
    var
        RecRef: RecordRef;
    begin
        FieldIdList.Add(0); // Timestamp field
        FieldIdList.Add(RecRef.SystemIdNo());
        FieldIdList.Add(RecRef.SystemCreatedAtNo());
        FieldIdList.Add(RecRef.SystemCreatedByNo());
        FieldIdList.Add(RecRef.SystemModifiedAtNo());
        FieldIdList.Add(RecRef.SystemModifiedByNo());
    end;

    procedure CreateCsvPayload(Rec: RecordRef; FieldIdList: List of [Integer]; AddHeaders: Boolean) RecordPayload: Text
    var
        TableMetadata: Record "Table Metadata";
        ADLSECDMUtil: Codeunit "ADLSE CDM Util";
        Field: FieldRef;
        FieldID: Integer;
        FieldsAdded: Integer;
        FieldTextValue: Text;
        Payload: TextBuilder;
    begin
        if AddHeaders then begin
            foreach FieldID in FieldIdList do begin
                Field := Rec.Field(FieldID);

                FieldTextValue := GetDataLakeCompliantFieldName(Field.Name, Field.Number);
                if FieldsAdded = 0 then
                    Payload.Append(FieldTextValue)
                else
                    Payload.Append(StrSubstNo(',%1', FieldTextValue));
                FieldsAdded += 1;
            end;
            if IsTablePerCompany(Rec.Number) then
                Payload.Append(StrSubstNo(',%1', ADLSECDMUtil.GetCompanyFieldName()));
            Payload.AppendLine();
        end;

        FieldsAdded := 0;
        foreach FieldID in FieldIdList do begin
            Field := Rec.Field(FieldID);

            FieldTextValue := ConvertFieldToText(Field);
            if FieldsAdded = 0 then
                Payload.Append(FieldTextValue)
            else
                Payload.Append(StrSubstNo(',%1', FieldTextValue));
            FieldsAdded += 1;
        end;
        if IsTablePerCompany(Rec.Number) then
            Payload.Append(StrSubstNo(',%1', ConvertStringToText(CompanyName())));
        Payload.AppendLine();

        RecordPayload := Payload.ToText();
    end;

    procedure IsTablePerCompany(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.SetRange(ID, TableID);
        TableMetadata.FindFirst();
        exit(TableMetadata.DataPerCompany);
    end;

    procedure CreateFakeRecordForDeletedAction(ADLSEDeletedRecord: Record "ADLSE Deleted Record"; var Rec: RecordRef)
    var
        TimestampField: FieldRef;
        SystemIdField: FieldRef;
        SystemDateField: FieldRef;
    begin
        TimestampField := Rec.Field(0);
        TimestampField.Value(ADLSEDeletedRecord."Deletion Timestamp");
        SystemIdField := Rec.Field(Rec.SystemIdNo());
        SystemIdField.Value(ADLSEDeletedRecord."System ID");

        SystemDateField := Rec.Field(Rec.SystemCreatedAtNo());
        SystemDateField.Value(0DT);
        SystemDateField := Rec.Field(Rec.SystemModifiedAtNo());
        SystemDateField.Value(0DT);
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