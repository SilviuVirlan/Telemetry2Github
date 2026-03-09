codeunit 50100 "Lock Demo Mgt."
{
    // This codeunit demonstrates two patterns that trigger telemetry event RT0012
    // "Database lock timed out" (Performance area).
    //
    // HOW TO TRIGGER RT0012:
    //   1. Open the Lock Demo page in two separate browser tabs/sessions.
    //   2. In Tab 1, click "Hold Lock (65 s)" — this locks the table and sleeps for 65 seconds.
    //   3. Within those 65 seconds, click "Try Lock" in Tab 2.
    //   4. Tab 2 will wait for the lock, exceed the server lock-timeout threshold,
    //      and Business Central emits RT0012 to Application Insights.

    procedure EnsureSeedData()
    var
        LockDemoTable: Record "Lock Demo Table";
        i: Integer;
    begin
        if not LockDemoTable.IsEmpty() then
            exit;

        for i := 1 to 5 do begin
            LockDemoTable.Init();
            LockDemoTable."Entry No." := i;
            LockDemoTable.Description := StrSubstNo('Demo record %1', i);
            LockDemoTable.Amount := i * 100;
            LockDemoTable."Created At" := CurrentDateTime();
            LockDemoTable.Insert(true);
        end;
    end;

    // Call this from Session A to hold a lock longer than the lock-timeout threshold.
    // While this runs, any competing session calling TryAcquireLock() will trigger RT0012.
    procedure HoldLockForDuration(SleepMilliseconds: Integer)
    var
        LockDemoTable: Record "Lock Demo Table";
    begin
        // LockTable() acquires an intent-exclusive lock on the entire table.
        // The lock is held for the lifetime of the transaction.
        LockDemoTable.LockTable();
        if LockDemoTable.FindFirst() then begin
            LockDemoTable.Description := StrSubstNo('Locked at %1', Format(CurrentDateTime()));
            LockDemoTable.Modify();
        end;

        // Keep the transaction — and therefore the lock — alive.
        // Default BC lock timeout is ~30 s; sleep longer so a competing session times out.
        Sleep(SleepMilliseconds);

        // Commit releases the lock; the competing session can then proceed.
        Commit();
    end;

    // Call this from Session B while Session A is inside HoldLockForDuration().
    // If Session A still holds the lock when this session times out, RT0012 is emitted.
    procedure TryAcquireLock()
    var
        LockDemoTable: Record "Lock Demo Table";
    begin
        LockDemoTable.LockTable();
        if LockDemoTable.FindFirst() then begin
            LockDemoTable.Description := StrSubstNo('Updated by session at %1', Format(CurrentDateTime()));
            LockDemoTable.Modify();
            Commit();
        end;
    end;

    // Alternative pattern: explicit row-level lock via LOCKTABLE + primary-key filter.
    // Useful for demonstrating row-level versus table-level lock contention.
    procedure HoldRowLock(EntryNo: Integer; SleepMilliseconds: Integer)
    var
        LockDemoTable: Record "Lock Demo Table";
    begin
        LockDemoTable.SetRange("Entry No.", EntryNo);
        LockDemoTable.LockTable();
        if LockDemoTable.FindFirst() then begin
            LockDemoTable.Amount += 1;
            LockDemoTable.Modify();
        end;
        Sleep(SleepMilliseconds);
        Commit();
    end;

    procedure TryAcquireRowLock(EntryNo: Integer)
    var
        LockDemoTable: Record "Lock Demo Table";
    begin
        LockDemoTable.SetRange("Entry No.", EntryNo);
        LockDemoTable.LockTable();
        if LockDemoTable.FindFirst() then begin
            LockDemoTable.Amount -= 1;
            LockDemoTable.Modify();
            Commit();
        end;
    end;
}
