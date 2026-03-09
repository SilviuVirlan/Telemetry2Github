table 50100 "Lock Demo Table"
{
    Caption = 'Lock Demo Table';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(4; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
