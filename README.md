# Growth Circle — Private Markets Dashboard

An institutional-grade dashboard for surveying private deal commitments across the Growth Circle stack. APEX terminal aesthetic — dark institutional theme, amber accents, IBM Plex typography.

**[→ Open the live dashboard](https://jocelynrenaud-commits.github.io/growth-circle-dashboard/)**

## Quick start

1. **Open the live dashboard** (link above) and bookmark it.
2. **Download the tracker template:** [GC_Investment_Tracker_v5.3.xlsx](releases/GC_Investment_Tracker_v5.3.xlsx)
3. **Open the tracker in Excel**, replace the example deals with your own, save the file locally.
4. **Drag your saved file** onto the dashboard's drop zone.

That's it. Your dashboard renders. Your data stays on your computer.

**Using Google Sheets instead of Excel?** The tracker works in Google Sheets, but the dropdown menus on the Investments tab may not import correctly — Google Sheets doesn't fully preserve Excel's cross-sheet data validation. This is purely cosmetic. The dashboard reads cell values, not dropdown selections, so just type values directly (e.g., "Real Estate" in the Asset Class column) and everything will render correctly when you upload.

## Privacy

Your spreadsheet data **never leaves your computer**. The dashboard runs entirely in your browser — there is no server-side code processing your data. The GitHub Pages server only serves static HTML, CSS, and JavaScript files. Verify yourself: open browser DevTools → Network tab → drag a spreadsheet onto the page → confirm zero outbound requests carrying spreadsheet data.

The only network request the dashboard makes (other than fetching itself on first visit) is a single GET for `version.json` to check if a newer version is available. No analytics, no tracking, no telemetry.

## Updates

The dashboard checks `version.json` on every page load. When you visit the live URL, you always get the latest version — your browser may cache the old version briefly, so a hard reload (Ctrl+Shift+R / Cmd+Shift+R) ensures you have the newest.

If you've downloaded an offline copy of the dashboard, it will show a banner the next time you open it whenever a newer version is released. Click **Reload** to fetch the latest, or **Dismiss** to keep using your local copy.

When the **tracker template** changes (new columns, new sheets), the banner will say so and link to the new download. Your existing data file keeps working — you only need the new template if you want the new columns.

## Offline use

If you'd rather run everything locally without a hosted URL: download the [offline bundle](releases/GC_Private_Markets_Dashboard.zip). It contains the dashboard HTML, the tracker template, and the setup guide as a Word document. Once extracted to a folder, double-click the HTML file. The dashboard works offline after first load (it caches its only external dependency, the spreadsheet-parsing library, automatically).

## What's in this repo
