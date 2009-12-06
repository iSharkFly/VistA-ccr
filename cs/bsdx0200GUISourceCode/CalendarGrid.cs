﻿namespace IndianHealthService.ClinicalScheduling
{
    using System;
    using System.Collections;
    using System.ComponentModel;
    using System.Drawing;
    using System.Globalization;
    using System.Runtime.CompilerServices;
    using System.Runtime.InteropServices;
    using System.Windows.Forms;
    /// <summary>
    /// This class was regenerated from Calendargrid.dll using Reflector.exe
    /// by Sam Habiel for WorldVista. The original source code is lost.
    /// </summary>
    public class CalendarGrid : Panel
    {
        private Container components;
        private Font fontArial10;
        private Font fontArial8;
        private CGAppointments m_Appointments;
        private Hashtable m_ApptOverlapTable;
        private bool m_bAutoDrag = true;
        private bool m_bDragDropStart;
        private bool m_bDrawWalkIns = true;
        private bool m_bGridEnter;
        private bool m_bInitialUpdate;
        private bool m_bMouseDown;
        private bool m_bScroll;
        private bool m_bScrollDown;
        private bool m_bSelectingRange;
        private int m_cellHeight;
        private int m_cellWidth;
        private int m_col0Width;
        private Hashtable m_ColumnInfoTable;
        private CGCell m_currentCell;
        private DateTime m_dtStart;
        private Font m_fCell;
        private string m_GridBackColor;
        private CGCells m_gridCells;
        private int m_nColumns = 5;
        private int m_nSelectID;
        private int m_nTimeScale = 20;
        private ArrayList m_pAvArray;
        private string m_sDragSource;
        private CGAppointments m_SelectedAppointments;
        private CGRange m_selectedRange;
        private StringFormat m_sf;
        private StringFormat m_sfHour;
        private StringFormat m_sfRight;
        private ArrayList m_sResourcesArray;
        private Timer m_Timer;
        private ToolTip m_toolTip;
        private const int WM_HSCROLL = 0x114;
        private const int WM_VSCROLL = 0x115;

        public event CGAppointmentChangedHandler CGAppointmentAdded;

        public event CGAppointmentChangedHandler CGAppointmentChanged;

        public event CGSelectionChangedHandler CGSelectionChanged;

        public CalendarGrid()
        {
            this.InitializeComponent();
            base.SetStyle(ControlStyles.AllPaintingInWmPaint, true);
            base.SetStyle(ControlStyles.UserPaint, true);
            base.SetStyle(ControlStyles.DoubleBuffer, true);
            this.m_nColumns = 5;
            this.m_gridCells = new CGCells();
            this.m_selectedRange = new CGRange();
            this.m_SelectedAppointments = new CGAppointments();
            this.m_dtStart = new DateTime(0x7d3, 1, 0x1b);
            this.m_ApptOverlapTable = new Hashtable();
            this.m_ColumnInfoTable = new Hashtable();
            this.m_sResourcesArray = new ArrayList();
            base.ResizeRedraw = true;
            this.m_col0Width = 100;
            this.fontArial8 = new Font("Arial", 8f);
            this.fontArial10 = new Font("Arial", 10f);
            this.m_fCell = this.fontArial10;
            this.m_sf = new StringFormat();
            this.m_sfRight = new StringFormat();
            this.m_sfHour = new StringFormat();
            this.m_sf.LineAlignment = StringAlignment.Center;
            this.m_sfRight.LineAlignment = StringAlignment.Center;
            this.m_sfRight.Alignment = StringAlignment.Far;
            this.m_sfHour.LineAlignment = StringAlignment.Center;
            this.m_sfHour.Alignment = StringAlignment.Far;
            this.m_bInitialUpdate = false;
        }

        private Rectangle AdjustRectForOverlap()
        {
            return new Rectangle();
        }

        private void AutoDragStart()
        {
            this.m_bAutoDrag = true;
            this.m_Timer = new Timer();
            this.m_Timer.Interval = 5;
            this.m_Timer.Tick += new EventHandler(this.tickEventHandler);
            this.m_Timer.Start();
        }

        private void AutoDragStop()
        {
            this.m_bAutoDrag = false;
            if (this.m_Timer != null)
            {
                this.m_Timer.Stop();
                this.m_Timer.Dispose();
                this.m_Timer = null;
            }
        }

        private void BuildGridCellsArray(Graphics g)
        {
            try
            {
                SizeF ef = g.MeasureString("Test", this.m_fCell);
                this.m_cellHeight = ((int) ef.Height) + 4;
                int nColumns = this.m_nColumns;
                int num2 = 60 / this.m_nTimeScale;
                int num3 = 0x18 * num2;
                nColumns++;
                num3++;
                this.m_cellWidth = 600 / nColumns;
                if (base.ClientRectangle.Width > 600)
                {
                    this.m_cellWidth = (base.ClientRectangle.Width - this.m_col0Width) / (nColumns - 1);
                }
                if (this.m_nColumns == 1)
                {
                    this.m_cellWidth = base.ClientRectangle.Width - this.m_col0Width;
                }
                g.TranslateTransform((float) base.AutoScrollPosition.X, (float) base.AutoScrollPosition.Y);
                for (int i = num3; i > -1; i--)
                {
                    for (int j = 1; j < nColumns; j++)
                    {
                        int x = 0;
                        if (j == 1)
                        {
                            x = this.m_col0Width;
                        }
                        if (j > 1)
                        {
                            x = this.m_col0Width + (this.m_cellWidth * (j - 1));
                        }
                        Point point = new Point(x, i * this.m_cellHeight);
                        Rectangle r = new Rectangle(point.X, point.Y, this.m_cellWidth, this.m_cellHeight);
                        if (i != 0)
                        {
                            CGCell cell = null;
                            cell = new CGCell(r, i, j);
                            this.m_gridCells.AddCell(cell);
                        }
                    }
                }
            }
            catch (Exception exception)
            {
                string message = exception.Message;
            }
        }

        private void CalendarGrid_DragDrop(object Sender, DragEventArgs e)
        {
            CGAppointment data = (CGAppointment) e.Data.GetData(typeof(CGAppointment));
            Point point = base.PointToClient(new Point(e.X, e.Y));
            int x = point.X - base.AutoScrollPosition.X;
            int y = point.Y - base.AutoScrollPosition.Y;
            Point pt = new Point(x, y);
            foreach (DictionaryEntry entry in this.m_gridCells.CellHashTable)
            {
                CGCell cgCell = (CGCell) entry.Value;
                if (cgCell.CellRectangle.Contains(pt))
                {
                    DateTime timeFromCell = this.GetTimeFromCell(cgCell);
                    string resourceFromColumn = this.GetResourceFromColumn(cgCell.CellColumn);
                    int duration = data.Duration;
                    TimeSpan span = new TimeSpan(0, duration, 0);
                    DateTime time2 = timeFromCell + span;
                    data.Selected = false;
                    this.m_nSelectID = 0;
                    CGAppointmentChangedArgs args = new CGAppointmentChangedArgs();
                    args.Appointment = data;
                    args.StartTime = timeFromCell;
                    args.EndTime = time2;
                    args.Resource = resourceFromColumn;
                    args.OldResource = data.Resource;
                    args.AccessTypeID = data.AccessTypeID;
                    args.Slots = data.Slots;
                    if (this.ApptDragSource == "grid")
                    {
                        this.CGAppointmentChanged(this, args);
                    }
                    else
                    {
                        this.CGAppointmentAdded(this, args);
                    }
                    break;
                }
            }
            this.SetOverlapTable();
            base.Invalidate();
        }

        private void CalendarGrid_DragEnter(object Sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(typeof(CGAppointment)))
            {
                if ((e.KeyState & 8) == 8)
                {
                    e.Effect = DragDropEffects.Copy;
                }
                else
                {
                    e.Effect = DragDropEffects.Move;
                }
            }
            else
            {
                e.Effect = DragDropEffects.None;
            }
        }

        private void CalendarGrid_MouseDown(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Left)
            {
                foreach (DictionaryEntry entry in this.m_gridCells.CellHashTable)
                {
                    CGCell cell = (CGCell) entry.Value;
                    cell.IsSelected = false;
                }
                this.m_selectedRange.Cells.ClearAllCells();
                this.m_bMouseDown = true;
                this.OnLButtonDown(e.X, e.Y, true);
            }
        }

        private void CalendarGrid_MouseMove(object Sender, MouseEventArgs e)
        {
            if (this.m_bMouseDown)
            {
                if ((e.Y >= base.ClientRectangle.Bottom) || (e.Y <= base.ClientRectangle.Top))
                {
                    this.m_bScrollDown = e.Y >= base.ClientRectangle.Bottom;
                }
                if ((e.Y < base.ClientRectangle.Bottom) && (e.Y > base.ClientRectangle.Top))
                {
                    bool bAutoDrag = this.m_bAutoDrag;
                }
                if (this.m_bSelectingRange)
                {
                    this.OnLButtonDown(e.X, e.Y, false);
                }
                if (this.m_nSelectID != 0)
                {
                    if (this.m_bGridEnter)
                    {
                        this.m_bGridEnter = false;
                    }
                    else if (!this.m_bDragDropStart)
                    {
                        CGAppointment data = (CGAppointment) this.m_Appointments.AppointmentTable[this.m_nSelectID];
                        this.ApptDragSource = "grid";
                        base.DoDragDrop(data, DragDropEffects.Move);
                        this.m_bDragDropStart = true;
                    }
                }
            }
            else
            {
                int y = e.Y - base.AutoScrollPosition.Y;
                int x = e.X - base.AutoScrollPosition.X;
                Point pt = new Point(x, y);
                foreach (CGAppointment appointment2 in this.m_Appointments.AppointmentTable.Values)
                {
                    if (appointment2.GridRectangle.Contains(pt))
                    {
                        this.m_toolTip.SetToolTip(this, appointment2.ToString());
                        return;
                    }
                }
                this.m_toolTip.RemoveAll();
            }
        }

        private void CalendarGrid_MouseUp(object Sender, MouseEventArgs e)
        {
            if (this.m_bAutoDrag)
            {
                this.m_bAutoDrag = false;
                this.AutoDragStop();
            }
            this.m_bMouseDown = false;
            if (this.m_bSelectingRange)
            {
                CGSelectionChangedArgs args = new CGSelectionChangedArgs();
                args.StartTime = this.GetTimeFromCell(this.m_selectedRange.StartCell);
                args.EndTime = this.GetTimeFromCell(this.m_selectedRange.EndCell);
                args.Resource = this.GetResourceFromColumn(this.m_selectedRange.StartCell.CellColumn);
                if (args.EndTime < args.StartTime)
                {
                    DateTime startTime = args.StartTime;
                    args.StartTime = args.EndTime;
                    args.EndTime = startTime;
                }
                TimeSpan span = new TimeSpan(0, 0, this.m_nTimeScale, 0, 0);
                args.EndTime += span;
                this.CGSelectionChanged(this, args);
                this.m_bSelectingRange = false;
            }
        }

        private void CalendarGrid_Paint(object sender, PaintEventArgs e)
        {
            if (e.Graphics != null)
            {
                this.DrawGrid(e.Graphics);
                if (!this.m_bInitialUpdate)
                {
                    this.SetAppointmentTypes();
                    base.Invalidate();
                    this.m_bInitialUpdate = true;
                }
            }
        }

        public void CloseGrid()
        {
            foreach (CGAppointment appointment in this.m_Appointments.AppointmentTable.Values)
            {
                appointment.Selected = false;
            }
            this.m_nSelectID = 0;
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && (this.components != null))
            {
                this.components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void DrawAppointments(Graphics g, int col0Width, int cellWidth, int cellHeight)
        {
            if (!base.DesignMode && (this.m_Appointments != null))
            {
                int num = 0;
                int num2 = 0;
                int x = 0;
                ArrayList list = new ArrayList();
                foreach (CGAppointment appointment in this.m_Appointments.AppointmentTable.Values)
                {
                    bool bRet = false;
                    Rectangle rect = this.GetAppointmentRect(appointment, col0Width, cellWidth, cellHeight, out bRet);
                    if (bRet && (!appointment.WalkIn || this.m_bDrawWalkIns))
                    {
                        rect.Inflate(-10, 0);
                        num = (int) this.m_ApptOverlapTable[appointment.m_nKey];
                        num2 = rect.Right - rect.Left;
                        x = num2 / (num + 1);
                        rect.Width = x;
                        if (num > 0)
                        {
                            foreach (object obj2 in list)
                            {
                                Rectangle rectangle2 = (Rectangle) obj2;
                                if (rect.IntersectsWith(rectangle2))
                                {
                                    rect.Offset(x, 0);
                                }
                            }
                        }
                        appointment.GridRectangle = rect;
                        if (appointment.Selected)
                        {
                            Pen pen = new Pen(Brushes.Black, 5f);
                            g.DrawRectangle(pen, rect);
                            pen.Dispose();
                        }
                        else
                        {
                            g.DrawRectangle(Pens.Blue, rect);
                        }
                        string s = appointment.ToString();
                        Rectangle rectangle3 = new Rectangle(rect.X + 1, rect.Y + 1, rect.Width - 1, rect.Height - 1);
                        g.FillRectangle(Brushes.White, rectangle3);
                        Brush black = Brushes.Black;
                        if (appointment.CheckInTime.Ticks > 0L)
                        {
                            black = Brushes.Green;
                            g.FillRectangle(Brushes.LightGreen, rectangle3);
                        }
                        if (appointment.NoShow)
                        {
                            black = Brushes.Red;
                            g.FillRectangle(Brushes.LightPink, rectangle3);
                        }
                        if (appointment.WalkIn)
                        {
                            black = Brushes.Blue;
                            g.FillRectangle(Brushes.LightSteelBlue, rectangle3);
                        }
                        g.DrawString(s, this.fontArial8, black, rectangle3);
                        list.Add(rect);
                    }
                }
            }
        }

        private void DrawGrid(Graphics g)
        {
            try
            {
                Pen pen = new Pen(Color.Black);
                SizeF ef = g.MeasureString("Test", this.m_fCell);
                int num = 10;
                this.m_cellHeight = ((int) ef.Height) + num;
                int nColumns = this.m_nColumns;
                int num3 = 60 / this.m_nTimeScale;
                int num4 = 0x18 * num3;
                nColumns++;
                num4++;
                this.m_cellWidth = 600 / nColumns;
                if (base.ClientRectangle.Width > 600)
                {
                    this.m_cellWidth = (base.ClientRectangle.Width - this.m_col0Width) / (nColumns - 1);
                }
                if (this.m_nColumns == 1)
                {
                    this.m_cellWidth = base.ClientRectangle.Width - this.m_col0Width;
                }
                base.AutoScrollMinSize = new Size(600, this.m_cellHeight * num4);
                g.FillRectangle(Brushes.LightGray, base.ClientRectangle);
                int num5 = 0;
                int num6 = 0;
                bool flag = this.m_gridCells.CellCount == 0;
                g.TranslateTransform((float) base.AutoScrollPosition.X, (float) base.AutoScrollPosition.Y);
                for (int i = 1; i < num4; i++)
                {
                    int x = 0;
                    Point point = new Point(x, i * this.m_cellHeight);
                    Rectangle rectangle2 = new Rectangle(point.X, point.Y, this.m_cellWidth, this.m_cellHeight);
                    Rectangle rect = new Rectangle(0, rectangle2.Y, this.m_col0Width, rectangle2.Height * num3);
                    int height = rect.Height;
                    height = (height > (this.m_col0Width / 4)) ? (this.m_col0Width / 4) : height;
                    if (num5 == 0)
                    {
                        g.FillRectangle(Brushes.LightGray, rect);
                        g.DrawRectangle(pen, rect.X, rect.Y, rect.Width, rect.Height);
                        string str = string.Format("{0}", num6).PadLeft(2, '0');
                        Font font = new Font("Arial", (float) height, FontStyle.Bold, GraphicsUnit.Pixel);
                        Rectangle rectangle3 = new Rectangle(rect.X, rect.Y, rect.Width / 2, rect.Height);
                        g.DrawString(str, font, Brushes.Black, rectangle3, this.m_sfHour);
                        num6++;
                        font.Dispose();
                    }
                    string s = string.Format("{0}", num5);
                    s = ":" + s.PadLeft(2, '0');
                    Rectangle layoutRectangle = new Rectangle(rect.X + ((rect.Width * 2) / 3), rectangle2.Top, rect.Width / 3, rectangle2.Height);
                    g.DrawString(s, this.m_fCell, Brushes.Black, layoutRectangle, this.m_sfRight);
                    Point point2 = new Point(rect.X + ((rect.Width * 2) / 3), rectangle2.Bottom);
                    Point point3 = new Point(rect.Right, rectangle2.Bottom);
                    g.DrawLine(pen, point2, point3);
                    num5 += this.m_nTimeScale;
                    num5 = (num5 >= 60) ? 0 : num5;
                    if ((i == (num4 - 1)) && !this.m_bScroll)
                    {
                        g.TranslateTransform((float) -base.AutoScrollPosition.X, (float) -base.AutoScrollPosition.Y);
                        rect = new Rectangle(0, 0, this.m_col0Width, this.m_cellHeight);
                        g.FillRectangle(Brushes.LightGray, rect);
                        g.DrawRectangle(pen, rect);
                        g.TranslateTransform((float) base.AutoScrollPosition.X, (float) base.AutoScrollPosition.Y);
                    }
                }
                for (int j = num4; j > -1; j--)
                {
                    for (int k = 1; k < nColumns; k++)
                    {
                        int num12 = 0;
                        if (k == 1)
                        {
                            num12 = this.m_col0Width;
                        }
                        if (k > 1)
                        {
                            num12 = this.m_col0Width + (this.m_cellWidth * (k - 1));
                        }
                        Point point4 = new Point(num12, j * this.m_cellHeight);
                        Rectangle r = new Rectangle(point4.X, point4.Y, this.m_cellWidth, this.m_cellHeight);
                        if (j != 0)
                        {
                            CGCell cellFromRowCol = null;
                            if (flag)
                            {
                                cellFromRowCol = new CGCell(r, j, k);
                                this.m_gridCells.AddCell(cellFromRowCol);
                            }
                            else
                            {
                                cellFromRowCol = this.m_gridCells.GetCellFromRowCol(j, k);
                                cellFromRowCol.CellRectangle = r;
                            }
                            if (this.m_sResourcesArray.Count > 0)
                            {
                                if (this.m_selectedRange.CellIsInRange(cellFromRowCol))
                                {
                                    g.FillRectangle(Brushes.Aquamarine, r);
                                }
                                else
                                {
                                    g.FillRectangle(cellFromRowCol.AppointmentTypeColor, r);
                                }
                                g.DrawRectangle(pen, r.X, r.Y, r.Width, r.Height);
                                if (j == 1)
                                {
                                    this.DrawAppointments(g, this.m_col0Width, this.m_cellWidth, this.m_cellHeight);
                                }
                            }
                            continue;
                        }
                        if (!this.m_bScroll)
                        {
                            g.TranslateTransform(0f, (float) -base.AutoScrollPosition.Y);
                            Rectangle rectangle6 = r;
                            g.FillRectangle(Brushes.LightBlue, rectangle6);
                            g.DrawRectangle(pen, rectangle6.X, rectangle6.Y, rectangle6.Width, rectangle6.Height);
                            string str3 = "";
                            if (this.m_sResourcesArray.Count > 1)
                            {
                                foreach (DictionaryEntry entry in this.m_ColumnInfoTable)
                                {
                                    int num13 = (int) entry.Value;
                                    num13++;
                                    if (num13 == k)
                                    {
                                        str3 = entry.Key.ToString();
                                        break;
                                    }
                                }
                            }
                            else
                            {
                                DateTime dtStart = this.m_dtStart;
                                if (k > 1)
                                {
                                    dtStart = dtStart.AddDays((double) (k - 1));
                                }
                                string format = "ddd, MMM d";
                                str3 = dtStart.ToString(format, DateTimeFormatInfo.InvariantInfo);
                            }
                            g.DrawString(str3, this.m_fCell, Brushes.Black, rectangle6, this.m_sf);
                            g.TranslateTransform(0f, (float) base.AutoScrollPosition.Y);
                        }
                    }
                }
                this.m_bScroll = false;
                pen.Dispose();
            }
            catch (Exception)
            {
            }
        }

        public Rectangle GetAppointmentRect(CGAppointment a, int col0Width, int cellWidth, int cellHeight, out bool bRet)
        {
            DateTime startTime = a.StartTime;
            DateTime endTime = a.EndTime;
            string resource = a.Resource;
            int num = 0;
            int num2 = 0;
            int num3 = 0;
            int num4 = 0;
            int num5 = 0;
            Rectangle rectangle = new Rectangle();
            int totalMinutes = (int) startTime.TimeOfDay.TotalMinutes;
            int num7 = (int) endTime.TimeOfDay.TotalMinutes;
            if (this.m_sResourcesArray.Count > 1)
            {
                num5 = (int) this.m_ColumnInfoTable[resource];
                num5++;
            }
            else
            {
                num5 = ((int) (startTime.DayOfWeek - this.m_dtStart.DayOfWeek)) + 1;
            }
            if (num5 < 1)
            {
                bRet = false;
                return rectangle;
            }
            num = col0Width + (cellWidth * (num5 - 1));
            int num8 = totalMinutes + this.m_nTimeScale;
            int num9 = (num7 > 0) ? num7 : 0x5a0;
            num9 -= totalMinutes;
            num2 = (cellHeight * num8) / this.m_nTimeScale;
            num3 = (cellHeight * num9) / this.m_nTimeScale;
            num4 = cellWidth;
            rectangle.X = num;
            rectangle.Y = num2;
            rectangle.Width = num4;
            rectangle.Height = num3;
            bRet = true;
            return rectangle;
        }

        public bool GetCellFromTime(DateTime dDate, ref int nRow, ref int nCol, bool bStartCell, string sResource)
        {
            int num = (dDate.Hour * 60) + dDate.Minute;
            nRow = num / this.m_nTimeScale;
            if (bStartCell)
            {
                nRow++;
            }
            if (this.m_sResourcesArray.Count > 1)
            {
                if (sResource == "")
                {
                    sResource = this.m_sResourcesArray[0].ToString();
                }
                nCol = (int) this.m_ColumnInfoTable[sResource];
                nCol++;
                return true;
            }
            DateTime time = new DateTime(dDate.Year, dDate.Month, dDate.Day);
            TimeSpan span = (TimeSpan) (time - this.StartDate);
            int totalDays = 0;
            totalDays = (int) span.TotalDays;
            nCol = totalDays;
            nCol++;
            return true;
        }

        private string GetResourceFromColumn(int nCol)
        {
            if (this.m_sResourcesArray.Count == 1)
            {
                return this.m_sResourcesArray[0].ToString();
            }
            foreach (DictionaryEntry entry in this.m_ColumnInfoTable)
            {
                int num = (int) entry.Value;
                num++;
                if (num == nCol)
                {
                    return entry.Key.ToString();
                }
            }
            return "";
        }

        public bool GetSelectedTime(out DateTime dStart, out DateTime dEnd, out string sResource)
        {
            if (this.m_selectedRange.Cells.CellCount == 0)
            {
                dEnd = new DateTime();
                dStart = dEnd;
                sResource = "";
                return false;
            }
            CGCell startCell = this.m_selectedRange.StartCell;
            CGCell endCell = this.m_selectedRange.EndCell;
            if (startCell.CellRow > endCell.CellRow)
            {
                CGCell cell3 = startCell;
                startCell = endCell;
                endCell = cell3;
            }
            dStart = this.GetTimeFromCell(startCell);
            dEnd = this.GetTimeFromCell(endCell);
            dEnd = dEnd.AddMinutes((double) this.m_nTimeScale);
            sResource = this.GetResourceFromColumn(startCell.CellColumn);
            return true;
        }

        public bool GetSelectedType(out int nAccessTypeID)
        {
            nAccessTypeID = 0;
            if (this.m_selectedRange.Cells.CellCount == 0)
            {
                return false;
            }
            CGCell startCell = this.m_selectedRange.StartCell;
            CGCell endCell = this.m_selectedRange.EndCell;
            if (startCell.CellRow > endCell.CellRow)
            {
                CGCell cell3 = startCell;
                startCell = endCell;
                endCell = cell3;
            }
            DateTime timeFromCell = this.GetTimeFromCell(startCell);
            DateTime time2 = this.GetTimeFromCell(endCell).AddMinutes((double) this.m_nTimeScale);
            foreach (CGAvailability availability in this.m_pAvArray)
            {
                if (this.TimesOverlap(availability.StartTime, availability.EndTime, timeFromCell, time2))
                {
                    nAccessTypeID = availability.AvailabilityType;
                    break;
                }
            }
            return (nAccessTypeID > 0);
        }

        public DateTime GetTimeFromCell(CGCell cgCell)
        {
            int cellRow = cgCell.CellRow;
            int cellColumn = cgCell.CellColumn;
            DateTime dtStart = this.m_dtStart;
            int num3 = (cellRow - 1) * this.m_nTimeScale;
            int num4 = num3 / 60;
            if (num4 > 0)
            {
                num3 = num3 % (num4 * 60);
            }
            dtStart = dtStart.AddHours((double) num4).AddMinutes((double) num3);
            if (this.m_sResourcesArray.Count == 1)
            {
                dtStart = dtStart.AddDays((double) (cellColumn - 1));
            }
            return dtStart;
        }

        public bool GetTypeFromCell(CGCell cgCell, out int nAccessTypeID)
        {
            nAccessTypeID = 0;
            CGCell cell = cgCell;
            CGCell cell2 = cgCell;
            if (cell.CellRow > cell2.CellRow)
            {
                CGCell cell3 = cell;
                cell = cell2;
                cell2 = cell3;
            }
            DateTime timeFromCell = this.GetTimeFromCell(cell);
            DateTime time2 = this.GetTimeFromCell(cell2).AddMinutes((double) this.m_nTimeScale);
            foreach (CGAvailability availability in this.m_pAvArray)
            {
                if (this.TimesOverlap(availability.StartTime, availability.EndTime, timeFromCell, time2))
                {
                    nAccessTypeID = availability.AvailabilityType;
                    break;
                }
            }
            return (nAccessTypeID > 0);
        }

        private bool HitTest(int X, int Y, ref int nRow, ref int nCol)
        {
            Y -= base.AutoScrollPosition.Y;
            X -= base.AutoScrollPosition.X;
            foreach (DictionaryEntry entry in this.m_gridCells)
            {
                CGCell cell = (CGCell) entry.Value;
                if (cell.CellRectangle.Contains(X, Y))
                {
                    nRow = cell.CellRow;
                    nCol = cell.CellColumn;
                    return true;
                }
            }
            return false;
        }

        public void InitializeCalendarGrid()
        {
            this.AllowDrop = true;
        }

        private void InitializeComponent()
        {
            this.AutoScroll = true;
            base.AutoScrollMinSize = new Size(600, 400);
            this.BackColor = SystemColors.Window;
            base.Paint += new PaintEventHandler(this.CalendarGrid_Paint);
            base.MouseDown += new MouseEventHandler(this.CalendarGrid_MouseDown);
            base.MouseUp += new MouseEventHandler(this.CalendarGrid_MouseUp);
            base.MouseMove += new MouseEventHandler(this.CalendarGrid_MouseMove);
            base.DragEnter += new DragEventHandler(this.CalendarGrid_DragEnter);
            base.DragDrop += new DragEventHandler(this.CalendarGrid_DragDrop);
            this.m_toolTip = new ToolTip();
        }

        private int MinSince80(DateTime d)
        {
            DateTime time = new DateTime(0x7bc, 1, 1, 0, 0, 0);
            TimeSpan span = (TimeSpan) (d - time);
            return (int) span.TotalMinutes;
        }

        private void OnLButtonDown(int X, int Y, bool bStart)
        {
            this.m_bDragDropStart = false;
            this.m_nSelectID = 0;
            if (!this.m_bSelectingRange)
            {
                int y = Y - base.AutoScrollPosition.Y;
                int x = X - base.AutoScrollPosition.X;
                Point pt = new Point(x, y);
                if (Control.ModifierKeys == Keys.Control)
                {
                    this.m_bMouseDown = false;
                    foreach (CGAppointment appointment in this.m_Appointments.AppointmentTable.Values)
                    {
                        if (!appointment.GridRectangle.Contains(pt))
                        {
                            continue;
                        }
                        if (this.m_SelectedAppointments.AppointmentTable.ContainsKey(appointment.AppointmentKey))
                        {
                            this.m_SelectedAppointments.RemoveAppointment(appointment.AppointmentKey);
                            if (this.m_SelectedAppointments.AppointmentTable.Count == 0)
                            {
                                this.m_nSelectID = 0;
                            }
                            else
                            {
                                foreach (CGAppointment appointment2 in this.m_Appointments.AppointmentTable.Values)
                                {
                                    this.m_nSelectID = appointment2.AppointmentKey;
                                }
                            }
                        }
                        else
                        {
                            this.m_SelectedAppointments.AddAppointment(appointment);
                            this.m_nSelectID = appointment.AppointmentKey;
                        }
                        appointment.Selected = !appointment.Selected;
                        break;
                    }
                    base.Invalidate();
                    return;
                }
                foreach (CGAppointment appointment3 in this.m_Appointments.AppointmentTable.Values)
                {
                    if (!appointment3.GridRectangle.Contains(pt))
                    {
                        continue;
                    }
                    this.m_bMouseDown = false;
                    if (appointment3.Selected)
                    {
                        appointment3.Selected = false;
                        this.m_SelectedAppointments.ClearAllAppointments();
                        this.m_nSelectID = 0;
                    }
                    else
                    {
                        foreach (CGAppointment appointment4 in this.m_Appointments.AppointmentTable.Values)
                        {
                            appointment4.Selected = false;
                        }
                        this.m_SelectedAppointments.ClearAllAppointments();
                        this.m_SelectedAppointments.AddAppointment(appointment3);
                        appointment3.Selected = true;
                        this.m_nSelectID = appointment3.AppointmentKey;
                        this.m_bMouseDown = true;
                        this.m_bGridEnter = true;
                    }
                    base.Invalidate();
                    return;
                }
            }
            int nRow = -1;
            int nCol = -1;
            if (this.HitTest(X, Y, ref nRow, ref nCol))
            {
                CGCell cellFromRowCol = this.m_gridCells.GetCellFromRowCol(nRow, nCol);
                if (cellFromRowCol != null)
                {
                    if (bStart)
                    {
                        this.m_currentCell = cellFromRowCol;
                        this.m_selectedRange.StartCell = null;
                        this.m_selectedRange.EndCell = null;
                        this.m_selectedRange.CreateRange(this.m_gridCells, cellFromRowCol, cellFromRowCol);
                        bStart = false;
                        this.m_bMouseDown = true;
                        this.m_bSelectingRange = true;
                    }
                    else if (cellFromRowCol != this.m_currentCell)
                    {
                        if (!this.m_selectedRange.Cells.CellHashTable.ContainsKey(cellFromRowCol.Key))
                        {
                            this.m_selectedRange.AppendCell(this.m_gridCells, cellFromRowCol);
                        }
                        else
                        {
                            bool bUp = cellFromRowCol.CellRow < this.m_currentCell.CellRow;
                            this.m_selectedRange.SubtractCell(this.m_gridCells, cellFromRowCol, bUp);
                        }
                        this.m_currentCell = cellFromRowCol;
                    }
                    cellFromRowCol.IsSelected = true;
                    base.Invalidate();
                }
            }
        }

        public void OnUpdateArrays()
        {
            try
            {
                this.m_gridCells.ClearAllCells();
                this.SetColumnInfo();
                this.SetOverlapTable();
                Graphics g = base.CreateGraphics();
                this.BuildGridCellsArray(g);
                this.SetAppointmentTypes();
            }
            catch (Exception exception)
            {
                string message = exception.Message;
            }
        }

        private void SetAppointmentTypes()
        {
            if (this.m_gridCells.CellCount != 0)
            {
                foreach (DictionaryEntry entry in this.m_gridCells.CellHashTable)
                {
                    CGCell cell = (CGCell) entry.Value;
                    cell.AppointmentTypeColor = (this.m_GridBackColor == "blue") ? Brushes.CornflowerBlue : Brushes.Khaki;
                }
                if ((this.m_pAvArray != null) && (this.m_pAvArray.Count != 0))
                {
                    foreach (CGAvailability availability in this.m_pAvArray)
                    {
                        int nRow = 0;
                        int nCol = 0;
                        int num3 = 0;
                        int num4 = 0;
                        Brush brush = new SolidBrush(Color.FromArgb(availability.Red, availability.Green, availability.Blue));
                        this.GetCellFromTime(availability.StartTime, ref nRow, ref nCol, true, availability.ResourceList);
                        this.GetCellFromTime(availability.EndTime, ref num3, ref num4, false, availability.ResourceList);
                        for (int i = nCol; i <= num4; i++)
                        {
                            for (int j = nRow; (i == num4) && (j <= num3); j++)
                            {
                                string str = "r" + j.ToString() + "c" + i.ToString();
                                CGCell cell2 = (CGCell) this.m_gridCells.CellHashTable[str];
                                if (cell2 != null)
                                {
                                    cell2.AppointmentTypeColor = brush;
                                }
                            }
                        }
                    }
                }
            }
        }

        private void SetColumnInfo()
        {
            this.m_ColumnInfoTable.Clear();
            for (int i = 0; i < this.m_sResourcesArray.Count; i++)
            {
                this.m_ColumnInfoTable.Add(this.m_sResourcesArray[i], i);
            }
            if (this.m_sResourcesArray.Count > 1)
            {
                this.m_nColumns = this.m_sResourcesArray.Count;
            }
        }

        public void SetOverlapTable()
        {
            Hashtable hashtable = new Hashtable();
            int y = 0;
            int num2 = 0;
            int x = 0;
            foreach (CGAppointment appointment in this.m_Appointments.AppointmentTable.Values)
            {
                if (!appointment.WalkIn || this.m_bDrawWalkIns)
                {
                    string resource = appointment.Resource;
                    y = appointment.StartTime.Minute + (60 * appointment.StartTime.Hour);
                    num2 = appointment.EndTime.Minute + (60 * appointment.EndTime.Hour);
                    x = (this.m_sResourcesArray.Count > 1) ? (((int) this.m_ColumnInfoTable[resource]) + 1) : appointment.StartTime.DayOfYear;
                    Rectangle rectangle = new Rectangle(x, y, 1, num2 - y);
                    hashtable.Add(appointment.m_nKey, rectangle);
                }
            }
            this.m_ApptOverlapTable.Clear();
            foreach (int num4 in hashtable.Keys)
            {
                this.m_ApptOverlapTable.Add(num4, 0);
            }
            if (this.m_ApptOverlapTable.Count != 0)
            {
                int num5 = (this.m_sResourcesArray.Count > 1) ? 1 : this.StartDate.DayOfYear;
                int num6 = (this.m_sResourcesArray.Count > 1) ? (this.m_sResourcesArray.Count + 1) : (this.Columns + this.StartDate.DayOfYear);
                for (int i = num5; i < num6; i++)
                {
                    ArrayList list = new ArrayList();
                    for (int j = 1; j < this.Rows; j++)
                    {
                        Rectangle rectangle2 = new Rectangle(i, j * this.m_nTimeScale, 1, this.m_nTimeScale);
                        int num9 = -1;
                        list.Clear();
                        foreach (int num10 in hashtable.Keys)
                        {
                            Rectangle rect = (Rectangle) hashtable[num10];
                            if (rectangle2.IntersectsWith(rect))
                            {
                                num9++;
                                list.Add(num10);
                            }
                        }
                        if (num9 > 0)
                        {
                            foreach (object obj2 in list)
                            {
                                int num11 = (int) obj2;
                                if (((int) this.m_ApptOverlapTable[num11]) < num9)
                                {
                                    this.m_ApptOverlapTable[num11] = num9;
                                }
                            }
                        }
                    }
                }
            }
        }

        private void tickEventHandler(object o, EventArgs e)
        {
            Point point = new Point(base.AutoScrollPosition.X, base.AutoScrollPosition.Y);
            int x = point.X;
            int num = point.Y * -1;
            num = this.m_bScrollDown ? (num + 5) : (num - 5);
            point.Y = num;
            base.AutoScrollPosition = point;
            base.Invalidate();
        }

        private bool TimesOverlap(DateTime dStart1, DateTime dEnd1, DateTime dStart2, DateTime dEnd2)
        {
            long ticks = dEnd1.Ticks - dStart1.Ticks;
            TimeSpan ts = new TimeSpan(ticks);
            ticks = dEnd2.Ticks - dStart2.Ticks;
            new TimeSpan(ticks).Subtract(ts);
            Rectangle rect = new Rectangle();
            Rectangle rectangle2 = new Rectangle();
            rect.X = 0;
            rectangle2.X = 0;
            rect.Width = 1;
            rectangle2.Width = 1;
            rect.Y = this.MinSince80(dStart1);
            rect.Height = this.MinSince80(dEnd1) - rect.Y;
            rectangle2.Y = this.MinSince80(dStart2);
            rectangle2.Height = this.MinSince80(dEnd2) - rectangle2.Y;
            return rectangle2.IntersectsWith(rect);
        }

        protected override void WndProc(ref Message msg)
        {
            try
            {
                if (msg.Msg == 0x115)
                {
                    this.m_bScroll = true;
                    base.Invalidate(false);
                    this.m_bScroll = false;
                }
                if (msg.Msg == 0x114)
                {
                    base.Invalidate(false);
                }
                base.WndProc(ref msg);
            }
            catch (Exception exception)
            {
                MessageBox.Show("CalendarGrid::WndProc:  " + exception.Message + "\nStack: " + exception.StackTrace);
            }
        }

        public CGAppointments Appointments
        {
            get
            {
                return this.m_Appointments;
            }
            set
            {
                this.m_Appointments = value;
            }
        }

        public string ApptDragSource
        {
            get
            {
                return this.m_sDragSource;
            }
            set
            {
                this.m_sDragSource = value;
            }
        }

        public ArrayList AvailabilityArray
        {
            get
            {
                return this.m_pAvArray;
            }
            set
            {
                this.m_pAvArray = value;
            }
        }

        public int CellHeight
        {
            get
            {
                return this.m_cellHeight;
            }
        }

        public ToolTip CGToolTip
        {
            get
            {
                return this.m_toolTip;
            }
        }

        public int Columns
        {
            get
            {
                return this.m_nColumns;
            }
            set
            {
                if ((value > 0) && (value < 11))
                {
                    this.m_nColumns = value;
                    this.m_gridCells.ClearAllCells();
                    this.m_selectedRange.Cells.ClearAllCells();
                    Graphics g = base.CreateGraphics();
                    this.BuildGridCellsArray(g);
                    this.SetAppointmentTypes();
                    base.Invalidate();
                }
            }
        }

        public bool DrawWalkIns
        {
            get
            {
                return this.m_bDrawWalkIns;
            }
            set
            {
                this.m_bDrawWalkIns = value;
            }
        }

        public string GridBackColor
        {
            get
            {
                return this.m_GridBackColor;
            }
            set
            {
                this.m_GridBackColor = value;
            }
        }

        public bool GridEnter
        {
            get
            {
                return this.m_bGridEnter;
            }
            set
            {
                this.m_bGridEnter = value;
            }
        }

        public ArrayList Resources
        {
            get
            {
                return this.m_sResourcesArray;
            }
            set
            {
                this.m_sResourcesArray = value;
            }
        }

        public int Rows
        {
            get
            {
                return (0x5a0 / this.m_nTimeScale);
            }
        }

        public int SelectedAppointment
        {
            get
            {
                return this.m_nSelectID;
            }
            set
            {
                this.m_nSelectID = value;
            }
        }

        public CGAppointments SelectedAppointments
        {
            get
            {
                return this.m_SelectedAppointments;
            }
        }

        public CGRange SelectedRange
        {
            get
            {
                return this.m_selectedRange;
            }
        }

        public DateTime StartDate
        {
            get
            {
                return this.m_dtStart;
            }
            set
            {
                this.m_dtStart = value;
            }
        }

        public int TimeScale
        {
            get
            {
                return this.m_nTimeScale;
            }
            set
            {
                if ((((value == 5) || (value == 10)) || ((value == 15) || (value == 20))) || ((value == 30) || (value == 60)))
                {
                    this.m_nTimeScale = value;
                    this.m_gridCells.ClearAllCells();
                    this.m_selectedRange.Cells.ClearAllCells();
                    Graphics g = base.CreateGraphics();
                    this.BuildGridCellsArray(g);
                    this.SetAppointmentTypes();
                    base.Invalidate();
                }
            }
        }
    }
}
