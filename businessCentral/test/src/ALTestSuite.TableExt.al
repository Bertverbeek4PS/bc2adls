tableextension 85560 "ADLSE AL Test Suite" extends "AL Test Suite"
{
    procedure GetDefaultTestRunner() TestRunnerCodeunitId: Integer;
    begin
        if Evaluate(TestRunnerCodeunitId, Rec.Name) then
            exit(TestRunnerCodeunitId);
    end;
}