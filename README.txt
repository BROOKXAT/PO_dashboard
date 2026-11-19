PO DASHBOARD v8
1. Close Power BI Desktop. Unzip to a new folder (or replace the old project folder entirely).
2. Open PO_Dashboard.pbip.
3. FilePath is preset to C:\Users\brookxat\Downloads\PO_Tracking_Dummy.xlsx -> just click Refresh.
Sidebar filters (synced on all pages): Order Year, Order Month, Supplier, Material, PO Number.
Page filters: Delivery = Planned / Actual Arrival Month; PO Details = Reception Month, Status.
GR Log page: data from the "GR Log" sheet, not linked to the PO pages. Own filters: Supplier, Material, PO Number, Delivery Status, QC Status. Indicator (measures, like Delivery Tracking) = GR Date - Delivery Date (today if not received): green <= 1 day, orange 2-3, red > 3, blue = not received and not due yet, white = no delivery date.
Batches Expiring This Month (GR Log page): batches whose Expiry Date is in the current month; red = already expired, orange = will expire this month.
Buttons: Ctrl+click in Power BI Desktop (plain click works in the Power BI service).
If the colours don't apply: View > Themes > Browse for themes > PO_Dashboard.Report\StaticResources\RegisteredResources\PfizerTheme.json
