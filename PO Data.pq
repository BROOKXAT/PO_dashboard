// ============================================================================
// Power Query (M) – table "PO Data"
// Source: DB_DATA2.xlsx / Sheet1
// Requires a text parameter named FilePath = full path to DB_DATA2.xlsx
// ============================================================================
let
    // ---- 1. Load -----------------------------------------------------------
    Source      = Excel.Workbook(File.Contents(FilePath), null, true),
    Sheet       = Source{[Item = "Sheet1", Kind = "Sheet"]}[Data],
    Promoted    = Table.PromoteHeaders(Sheet, [PromoteAllScalars = true]),

    // ---- 2. Keep only real columns (drops the empty 13th column) -----------
    KeptColumns = Table.SelectColumns(
        Promoted,
        {"PO Number", "Supplier", "Material", "PO Value (€)", "Currency", "Ordered Qty",
         "Issue Date", "Expedition Date", "Planned Arrival Date", "Actual Arrival Date",
         "Reception Date", "Status"},
        MissingField.UseNull),

    // ---- 3. Drop empty rows ------------------------------------------------
    NonEmptyRows = Table.SelectRows(
        KeptColumns,
        each [PO Number] <> null and Text.Trim(Text.From([PO Number])) <> ""),

    // ---- 4. Helper functions -----------------------------------------------
    // Excel cells that were stored as real dates were typed dd/mm but read as
    // mm/dd (e.g. 08/01/2026 stored as 1-Aug-2026). They get day/month swapped.
    // Text cells such as "20/01/2026" are parsed as dd/MM/yyyy.
    SwapDayMonthOnExcelDates = true,

    ToDate = (v as any) as nullable date =>
        let
            Swap = (d as date) as date =>
                if SwapDayMonthOnExcelDates and Date.Day(d) <= 12
                then #date(Date.Year(d), Date.Day(d), Date.Month(d))
                else d,
            Result =
                if v = null then null
                else if v is date then Swap(v)
                else if v is datetime then Swap(Date.From(v))
                else if v is number then Swap(Date.From(v))
                else
                    let
                        t       = Text.Trim(Text.From(v)),
                        Formats = {"dd/MM/yyyy", "d/M/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "yyyy-MM-dd", "dd/MM/yy"},
                        Parsed  = List.First(
                                    List.RemoveNulls(
                                        List.Transform(Formats, (f) =>
                                            try Date.FromText(t, [Format = f, Culture = "en-US"]) otherwise null)),
                                    null)
                    in
                        if t = "" then null else Parsed
        in
            Result,

    ToDecimal = (v as any) as nullable number =>
        if v = null then null
        else if v is number then v
        else
            let t = Text.Remove(Text.Trim(Text.From(v)), {" ", "€", "$", Character.FromNumber(160)})
            in  if t = "" then null
                else try Number.FromText(t, "en-US") otherwise try Number.FromText(t, "fr-FR") otherwise null,

    CleanText = (v as any) as nullable text =>
        if v = null then null
        else let t = Text.Clean(Text.Trim(Text.From(v))) in if t = "" then null else t,

    // ---- 5. Cast every column ----------------------------------------------
    TypedText = Table.TransformColumns(
        NonEmptyRows,
        {{"PO Number", CleanText, type text},
         {"Supplier",  CleanText, type text},
         {"Material",  CleanText, type text},
         {"Currency",  each Text.Upper(CleanText(_)), type text},
         {"Status",    CleanText, type text}}),

    TypedNumbers = Table.TransformColumns(
        TypedText,
        {{"PO Value (€)", ToDecimal, type number},                       // Decimal Number
         {"Ordered Qty",  each let n = ToDecimal(_) in if n = null then null else Int64.From(n), Int64.Type}}),

    TypedDates = Table.TransformColumns(
        TypedNumbers,
        {{"Issue Date",           ToDate, type date},
         {"Expedition Date",      ToDate, type date},
         {"Planned Arrival Date", ToDate, type date},
         {"Actual Arrival Date",  ToDate, type date},
         {"Reception Date",       ToDate, type date}}),

    // "PO Value (€)" contains EUR and USD amounts (see Currency), so the € is dropped from the name
    Renamed = Table.RenameColumns(TypedDates, {{"PO Value (€)", "PO Value"}}),

    // ---- 6. Cycle time per PO (null when either date is missing) -----------
    AddedCycleTime = Table.AddColumn(
        Renamed, "Cycle Time (Days)",
        each if [Issue Date] = null or [Reception Date] = null then null
             else Duration.Days([Reception Date] - [Issue Date]),
        Int64.Type)
in
    AddedCycleTime
