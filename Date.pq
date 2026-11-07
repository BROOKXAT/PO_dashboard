// ============================================================================
// Power Query (M) – "Calendar Base" (not loaded). Every calendar table
// (Issue / Planned Arrival / Actual Arrival / Reception) is a reference to it,
// each with its own active relationship to the matching date column.
// Range = all months touched by any date column in 'PO Data'.
// ============================================================================
let
    Src       = #"PO Data",
    AllDates  = List.RemoveNulls(List.Combine({
                    Src[Issue Date], Src[Expedition Date], Src[Planned Arrival Date],
                    Src[Actual Arrival Date], Src[Reception Date]})),
    StartDate = Date.StartOfMonth(List.Min(AllDates)),
    EndDate   = Date.EndOfMonth(List.Max(AllDates)),
    DayList   = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    Calendar  = Table.FromList(DayList, Splitter.SplitByNothing(), type table [Date = date]),
    AddYear      = Table.AddColumn(Calendar,    "Year",         each Date.Year([Date]), Int64.Type),
    AddMonthNo   = Table.AddColumn(AddYear,     "Month Number", each Date.Month([Date]), Int64.Type),
    AddMonth     = Table.AddColumn(AddMonthNo,  "Month",        each Date.ToText([Date], [Format = "MMM yyyy", Culture = "en-US"]), type text),
    AddMonthName = Table.AddColumn(AddMonth,    "Month Name",   each Date.ToText([Date], [Format = "MMM", Culture = "en-US"]), type text),
    AddMonthKey  = Table.AddColumn(AddMonthName,    "Month Key",    each Date.Year([Date]) * 100 + Date.Month([Date]), Int64.Type),
    AddWeekStart = Table.AddColumn(AddMonthKey, "Week Start",   each Date.StartOfWeek([Date], Day.Monday), type date)
in
    AddWeekStart
