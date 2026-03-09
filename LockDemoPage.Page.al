page 50100 "Lock Demo Page"
{
    // Page used to trigger telemetry event RT0012 "Database lock timed out".
    //
    // STEPS TO TRIGGER RT0012:
    //   1. Open this page and click "Seed Data" once to populate the table.
    //   2. Open the page in a second browser tab (same or different user).
    //   3. In Tab 1  → click "Hold Lock (65 s)".  The action locks the table and sleeps.
    //   4. In Tab 2  → click "Try Lock" within ~30 s of step 3.
    //   5. Tab 2 waits for the lock; when the server lock-timeout expires (~30 s),
    //      Business Central emits RT0012 to Application Insights.
    //   6. For row-level lock contention use "Hold Row Lock" + "Try Row Lock" (Entry No. 1).

    Caption = 'Lock Demo - RT0012 Trigger';
    PageType = List;
    SourceTable = "Lock Demo Table";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SeedData)
            {
                Caption = 'Seed Data';
                ToolTip = 'Insert sample rows so lock actions have records to contend on.';
                ApplicationArea = All;
                Image = Refresh;

                trigger OnAction()
                var
                    LockDemoMgt: Codeunit "Lock Demo Mgt.";
                begin
                    LockDemoMgt.EnsureSeedData();
                    CurrPage.Update(false);
                    Message('Seed data created (or already existed).');
                end;
            }

            action(HoldLock)
            {
                // SESSION A action — run this FIRST.
                // Acquires a table-level lock and holds it for 65 seconds.
                // While this sleeps, any competing session that runs "Try Lock"
                // will exceed the BC lock timeout and trigger RT0012.
                Caption = 'Hold Lock (65 s)';
                ToolTip = 'Locks the entire table for 65 seconds (Session A). Run "Try Lock" in a second session during this time to trigger RT0012.';
                ApplicationArea = All;
                Image = Lock;

                trigger OnAction()
                var
                    LockDemoMgt: Codeunit "Lock Demo Mgt.";
                begin
                    Message('Lock acquired. Holding for 65 seconds. Switch to Session B and click "Try Lock" now.');
                    LockDemoMgt.HoldLockForDuration(65000);
                end;
            }

            action(TryLock)
            {
                // SESSION B action — run this while Session A is sleeping inside HoldLock.
                // The session waits until the lock timeout, which triggers RT0012.
                Caption = 'Try Lock';
                ToolTip = 'Attempts to acquire a table-level lock (Session B). If Session A is holding the lock, this triggers RT0012 after the lock-timeout period.';
                ApplicationArea = All;
                Image = Apply;

                trigger OnAction()
                var
                    LockDemoMgt: Codeunit "Lock Demo Mgt.";
                begin
                    LockDemoMgt.TryAcquireLock();
                    Message('Lock acquired successfully (no contention detected).');
                end;
            }

            action(HoldRowLock)
            {
                // Row-level variant — locks only Entry No. 1.
                Caption = 'Hold Row Lock (65 s)';
                ToolTip = 'Locks row Entry No. 1 for 65 seconds. Use "Try Row Lock" in a second session to trigger RT0012 on a single row.';
                ApplicationArea = All;
                Image = Lock;

                trigger OnAction()
                var
                    LockDemoMgt: Codeunit "Lock Demo Mgt.";
                begin
                    Message('Row lock on Entry No. 1 acquired. Holding for 65 seconds.');
                    LockDemoMgt.HoldRowLock(1, 65000);
                end;
            }

            action(TryRowLock)
            {
                // Row-level variant — contends on Entry No. 1.
                Caption = 'Try Row Lock';
                ToolTip = 'Attempts to lock row Entry No. 1. If Session A holds it, RT0012 is emitted after timeout.';
                ApplicationArea = All;
                Image = Apply;

                trigger OnAction()
                var
                    LockDemoMgt: Codeunit "Lock Demo Mgt.";
                begin
                    LockDemoMgt.TryAcquireRowLock(1);
                    Message('Row lock acquired successfully (no contention detected).');
                end;
            }
        }
    }
}
